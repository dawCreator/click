//
//  Device.swift
//  click
//
//  Created by Lukas Schmale on 13.06.24.
//

import Foundation
import os.log

final class Device: Hashable {
    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static private(set) var s: Set<Device> = []
    private static var isObservingDeviceChanges = false
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "click", category: "Device")

    private var shouldDeinit = false
    private let id: UInt64
    private let mtDevice: MTDevice
    private var devicePointer: UnsafeMutablePointer<Unmanaged<Device>>?

    @objc static func updateDevices(_ notification: Notification?) {
        guard Thread.isMainThread else {
            DispatchQueue.main.async { updateDevices(notification) }
            return
        }

        for device in Array(s) {
            device.shouldDeinit = true
        }

        let mtDevices: [MTDevice] = MTDeviceCreateList().takeRetainedValue() as Array
        for mtDevice in mtDevices {
            _ = Device(mtDevice: mtDevice)
        }

        // Remove from a snapshot so mutating the set cannot invalidate iteration.
        for device in Array(s) where device.shouldDeinit {
            s.remove(device)
        }
    }

    static func startMonitoringDevices() {
        guard !isObservingDeviceChanges else { return }
        isObservingDeviceChanges = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateDevices(_:)),
            name: Notification.Name("_NSNotificationDevicesChanged"),
            object: nil
        )
        updateDevices(nil)
    }

    static func stopMonitoringDevices() {
        guard isObservingDeviceChanges else { return }
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name("_NSNotificationDevicesChanged"),
            object: nil
        )
        isObservingDeviceChanges = false
        for device in Array(s) {
            s.remove(device)
        }
    }

    static func getID(mtDevice: MTDevice) -> UInt64? {
        var id: UInt64 = 0
        let status = withUnsafeMutablePointer(to: &id) {
            MTDeviceGetDeviceID(mtDevice, $0)
        }
        return status == noErr ? id : nil
    }

    static func getDeviceFrom(mtDevice: MTDevice) -> Device? {
        guard let id = getID(mtDevice: mtDevice) else { return nil }
        return s.first { $0.id == id }
    }

    private init?(mtDevice: MTDevice) {
        guard let id = Device.getID(mtDevice: mtDevice) else { return nil }
        self.mtDevice = mtDevice
        self.id = id

        if let existingDevice = Device.s.first(where: { $0.id == id }) {
            existingDevice.shouldDeinit = false
            return nil
        }

        Device.s.insert(self)
        guard startMonitoringTouches() else {
            Device.s.remove(self)
            return nil
        }
    }

    deinit {
        stopMonitoringTouches()
    }

    private func receiveTouches(_ touches: [MTTouch]) {
        MainView.MAIN_VIEW.observableTouches.update(touches: touches)
        GestureRecognizer.SINGLETON.recognize(mtTouches: touches)
    }

    private let contactFrameCallback: MTFrameCallbackRefconFunction = {
        _, mtTouches, count, _, _, refcon in
        guard let refcon else { return }
        let devicePointer = refcon.assumingMemoryBound(to: Unmanaged<Device>.self)
        let device = devicePointer.pointee.takeUnretainedValue()
        let touches = Array(UnsafeBufferPointer(start: mtTouches, count: count))

        // The private framework may invoke this callback off the main thread.
        // Retain the Device while queued work uses it and keep UI/gesture state serialized.
        DispatchQueue.main.async {
            device.receiveTouches(touches)
        }
    }

    private func startMonitoringTouches() -> Bool {
        let pointer = UnsafeMutablePointer<Unmanaged<Device>>.allocate(capacity: 1)
        pointer.initialize(to: Unmanaged.passUnretained(self))
        devicePointer = pointer
        MTRegisterContactFrameCallbackWithRefcon(mtDevice, contactFrameCallback, pointer)

        let status = MTDeviceStart(mtDevice, 0)
        guard status == noErr else {
            MTUnregisterContactFrameCallback(mtDevice, contactFrameCallback)
            pointer.deinitialize(count: 1)
            pointer.deallocate()
            devicePointer = nil
            Self.logger.error("Could not start multitouch device (status \(status))")
            return false
        }
        return true
    }

    private func stopMonitoringTouches() {
        guard let pointer = devicePointer else { return }
        MTUnregisterContactFrameCallback(mtDevice, contactFrameCallback)
        MTDeviceStop(mtDevice)
        pointer.deinitialize(count: 1)
        pointer.deallocate()
        devicePointer = nil
    }
}
