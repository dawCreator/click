//
//  GestureRecognizer.swift
//  click
//
//  Created by Lukas Schmale on 13.06.24.
//
import AppKit
import CoreGraphics
import os.log

final class GestureRecognizer {
    static let SINGLETON = GestureRecognizer()

    private let gestureSynthesizer = GestureSynthesizer()
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "click", category: "GestureRecognizer")
    private var lastSyntheticEventWasPosted = true
    private var recognizedGesture: Gesture? {
        didSet(previousGesture) {
            if recognizedGesture == nil && previousGesture == nil { return }
            if let middleMouseGesture = recognizedGesture as? MiddleMouse,
               middleMouseGesture.TYPE == .otherMouseDown {
                lockFingerInMiddle = true
            }
            lastSyntheticEventWasPosted = gestureSynthesizer.synthesize(
                gesture: recognizedGesture,
                previousGesture: previousGesture
            )
        }
    }

    private var lockFingerInMiddle = false
    private var onlyFingerInMiddle = false
    private var previousPinchDistance: Float?
    private var pendingPinchDelta: Float = 0
    private var eventTap: CFMachPort?
    private var eventTapRunLoopSource: CFRunLoopSource?
    private var hasLoggedEventTapFailure = false

    private let middleMouseEventMapping: [CGEventType: CGEventType] = [
        .leftMouseDown: .otherMouseDown,
        .rightMouseDown: .otherMouseDown,
        .leftMouseUp: .otherMouseUp,
        .rightMouseUp: .otherMouseUp,
        .leftMouseDragged: .otherMouseDragged,
        .rightMouseDragged: .otherMouseDragged
    ]

    func recognize(mtTouches: [MTTouch]) {
        switch mtTouches.count {
        case 2:
            if !lockFingerInMiddle { onlyFingerInMiddle = false }
            let touchOne = mtTouches[0]
            let touchTwo = mtTouches[1]
            let a = touchOne.normalized.position
            let b = touchTwo.normalized.position
            let dx = a.x - b.x
            let dy = a.y - b.y
            let distance = sqrt(dx * dx + dy * dy)

            if let previousPinchDistance {
                let delta = distance - previousPinchDistance
                let minPressure = min(touchOne.zTotal, touchTwo.zTotal)
                if minPressure > 0.4 {
                    pendingPinchDelta += delta
                    if abs(pendingPinchDelta) >= 0.001 {
                        recognizedGesture = Magnification(delta: Double(pendingPinchDelta) * 4)
                        pendingPinchDelta = 0
                    }
                } else {
                    pendingPinchDelta = 0
                    recognizedGesture = nil
                }
            }
            previousPinchDistance = distance

        case 1:
            if !lockFingerInMiddle {
                let x = mtTouches[0].normalized.position.x
                onlyFingerInMiddle = 0.33 < x && x < 0.66
            }
            recognizedGesture = nil
            previousPinchDistance = nil
            pendingPinchDelta = 0

        default:
            if !lockFingerInMiddle { onlyFingerInMiddle = false }
            recognizedGesture = nil
            previousPinchDistance = nil
            pendingPinchDelta = 0
        }
    }

    func stopEventTap() {
        guard let eventTap else { return }
        CGEvent.tapEnable(tap: eventTap, enable: false)
        if let eventTapRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), eventTapRunLoopSource, .commonModes)
        }
        self.eventTap = nil
        eventTapRunLoopSource = nil
    }

    @discardableResult
    func setupEventTap() -> Bool {
        if eventTap != nil { return true }

        let types: [CGEventType] = [
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged
        ]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: { _, type, event, userInfo in
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    guard let userInfo else { return Unmanaged.passUnretained(event) }
                    let recognizer = Unmanaged<GestureRecognizer>.fromOpaque(userInfo).takeUnretainedValue()
                    if let existingTap = recognizer.eventTap {
                        CGEvent.tapEnable(tap: existingTap, enable: true)
                    }
                    return Unmanaged.passUnretained(event)
                }

                guard let userInfo else { return Unmanaged.passUnretained(event) }
                let recognizer = Unmanaged<GestureRecognizer>.fromOpaque(userInfo).takeUnretainedValue()
                guard recognizer.onlyFingerInMiddle,
                      let mappedType = recognizer.middleMouseEventMapping[type] else {
                    return Unmanaged.passUnretained(event)
                }

                if mappedType == .otherMouseUp {
                    recognizer.lockFingerInMiddle = false
                    recognizer.onlyFingerInMiddle = false
                }
                recognizer.recognizedGesture = MiddleMouse(type: mappedType, position: event.location)
                guard recognizer.lastSyntheticEventWasPosted else {
                    return Unmanaged.passUnretained(event)
                }

                // Drop the original click only after successfully posting its replacement.
                return nil
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            if !hasLoggedEventTapFailure {
                logger.error("Could not create the mouse event tap")
                hasLoggedEventTapFailure = true
            }
            return false
        }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        eventTap = tap
        eventTapRunLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        hasLoggedEventTapFailure = false
        return true
    }
}
