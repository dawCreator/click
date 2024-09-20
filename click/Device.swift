//
//  Device.swift
//  click
//
//  Created by Lukas Schmale on 13.06.24.
//

class Device: Hashable, ObservableObject {
// Hashable Conformance
    static func == (lhs: Device, rhs: Device) -> Bool {
        return lhs.ID == rhs.ID
    }
    func hash(into hasher: inout Hasher) {
        hasher.combine(ID)
    }
// Store Active Devices
    static private(set) var s: Set<Device> = []
// Track Active Devices:
    private var shouldDeinit: Bool = false
    @objc static func updateDevices(_: Notification?) {
    // Mark Old Devices
        for device in Device.s {
            device.shouldDeinit = true
        }
    // Add New Devices
        let MT_DEVICES = MTDeviceCreateList().takeRetainedValue() as Array
        for mtDevice in MT_DEVICES {
            _ = Device(mtDevice: mtDevice)
        }
    // Delete Old Devices
        for device in Device.s {
            if device.shouldDeinit {
                Device.s.remove(device)
            }
        }
    }
    static func startMonitoringDevices() {
        self.updateDevices(nil)
    // Call self.updateDevices() Whenever Devices Connect/Disconnect:
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateDevices), name: Notification.Name("_NSNotificationDevicesChanged"), object: nil)
    }
    static func stopMonitoringDevices() {
        NotificationCenter.default.removeObserver(self, name: Notification.Name("_NSNotificationDevicesChanged"), object: nil)
        Device.s = []
    }
// Properties
    enum DeviceType {
        case MagicMouse
    }
    private var type: DeviceType
    private let ID: UInt64
    static func getID(mtDevice: MTDevice) -> UInt64 {
        let ID: UInt64 = 0,
            ID_POINTER = UnsafeMutablePointer<UInt64>.allocate(capacity: 1)
        ID_POINTER.initialize(to: ID)
        MTDeviceGetDeviceID(mtDevice, ID_POINTER)
        ID_POINTER.deallocate()
        return ID
    }
    private let MT_DEVICE: MTDevice
    var view: MainView?
// Initializer(s)
    static func getDeviceFrom(mtDevice: MTDevice) -> Device? {
        let ID = Device.getID(mtDevice: mtDevice)
        return Device.s.first { device in
            return device.ID == ID
        }
    }
    private init?(mtDevice: MTDevice) {
        self.MT_DEVICE = mtDevice
    // ID:
        self.ID = Device.getID(mtDevice: mtDevice)
    // Type:
        self.type = .MagicMouse
        if (Device.s.contains(self)) {
            let EXISTING_DEVICE = Device.s.first(where: {device in return device == self})
            EXISTING_DEVICE?.shouldDeinit = false
            return nil
        } else {
            Device.s.insert(self)
        }
        startMonitoringTouches()
    }
    deinit {
        stopMonitoringTouches()
    }
    @Published private var _touches: Array<MTTouch> = []
    public var touches: Array<MTTouch> {
        get {
            return _touches
        }
        set(touches) {
            _touches = touches
            MainView.MAIN_VIEW.observableTouches.update(touches: touches)
            GestureRecognizer.SINGLETON.recognize(mtTouches: touches)
        }
    }
    private let CONTACT_FRAME_CALLBACK: MTFrameCallbackRefconFunction = { mtDevice, mtTouches, fingers, time, frame, device in
        let DEVICE_POINTER = device!.assumingMemoryBound(to: Device.self),
            DEVICE = DEVICE_POINTER.pointee
        let TOUCHES_BUFFER = UnsafeBufferPointer<MTTouch>(start: mtTouches, count: fingers),
            TOUCHES = Array(TOUCHES_BUFFER)
        DEVICE.touches = TOUCHES
    }
    
    private let DEVICE_POINTER = UnsafeMutablePointer<Device>.allocate(capacity: 1)
    private func startMonitoringTouches() {
        DEVICE_POINTER.initialize(to: self)
        MTRegisterContactFrameCallbackWithRefcon(MT_DEVICE, CONTACT_FRAME_CALLBACK, DEVICE_POINTER)
        MTDeviceStart(MT_DEVICE, 0)
    }
    private func stopMonitoringTouches() {
        MTUnregisterContactFrameCallback(MT_DEVICE, CONTACT_FRAME_CALLBACK)
        DEVICE_POINTER.deallocate()
    }
}
