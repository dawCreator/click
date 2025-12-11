//
//  GestureRecognizer.swift
//  click
//
//  Created by Lukas Schmale on 13.06.24.
//
import AppKit
import CoreGraphics
import Cocoa
import QuartzCore

class GestureRecognizer: ObservableObject {
    static let SINGLETON: GestureRecognizer = GestureRecognizer()
// Gesture Synthesizer
    private let GESTURE_SYNTHESIZER: GestureSynthesizer = GestureSynthesizer()
    private var recognizedGesture: Gesture? {
        didSet(previousGesture) {
            if let middleMouseGesture = recognizedGesture as? MiddleMouse {
                if middleMouseGesture.TYPE == .otherMouseDown {
                    lockFingerInMiddle = true
                }
            }
            GESTURE_SYNTHESIZER.synthesize(gesture: recognizedGesture, previousGesture: previousGesture)
        }
    }
// Privats
    private var lockFingerInMiddle: Bool = false
    private var onlyFingerInMiddle: Bool = false
    
    private var previousPinchDistance: Float?
    
    public func recognize(mtTouches: [MTTouch]) {
        switch mtTouches.count {
        case 2:
            let TOUCH_ONE = mtTouches[0],
                TOUCH_TWO = mtTouches[1]
            let A = TOUCH_ONE.normalized.position,
                B = TOUCH_TWO.normalized.position
            let DX = A.x - B.x,
                DY = A.y - B.y
            let DISTANCE = sqrt(DX*DX + DY*DY)
            if previousPinchDistance != nil {
                let DISTANCE_DELTA: Double = Double(DISTANCE - previousPinchDistance!)
                let MIN_PRESSURE = min(TOUCH_ONE.zTotal, TOUCH_TWO.zTotal)
                if 0.001 < abs(DISTANCE_DELTA) && 0.4 < MIN_PRESSURE{
                    recognizedGesture = Magnification(delta: DISTANCE_DELTA*4)
                }
            }
            previousPinchDistance = DISTANCE
        case 1:
            if !lockFingerInMiddle {
                let ONLY_TOUCH = mtTouches[0],
                    X = ONLY_TOUCH.normalized.position.x
                onlyFingerInMiddle = 0.33 < X && X < 0.66
            }
            fallthrough
        default:
            recognizedGesture = nil
            previousPinchDistance = nil
        }
    }
    private var eventTap: CFMachPort?
    func setupEventTap() {
        // Choose only the mouse events you need, not ALL events
        let types: [CGEventType] = [
            .leftMouseDown, .leftMouseUp, .leftMouseDragged,
            .rightMouseDown, .rightMouseUp, .rightMouseDragged,
            .otherMouseDown, .otherMouseUp, .otherMouseDragged,
            .mouseMoved
        ]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }

        // Prefer listenOnly unless you need to modify events
        let options: CGEventTapOptions = .listenOnly // or .defaultTap if you need to swallow/modify

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,            // less privileged than cghidEventTap
            place: .headInsertEventTap,
            options: options,
            eventsOfInterest: mask,
            callback: { proxy, type, event, userInfo in
                // Handle tap disabled cases
                if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                    if let info = userInfo {
                        let recognizer = Unmanaged<GestureRecognizer>.fromOpaque(info).takeUnretainedValue()
                        if let existingTap = recognizer.eventTap {
                            CGEvent.tapEnable(tap: existingTap, enable: true)
                        }
                    }
                    return Unmanaged.passUnretained(event)
                }

                // Forward events
                if let info = userInfo {
                    let recognizer = Unmanaged<GestureRecognizer>.fromOpaque(info).takeUnretainedValue()

                    if recognizer.onlyFingerInMiddle {
                        let mapping: [CGEventType: CGEventType] = [
                            .leftMouseDown: .otherMouseDown,
                            .rightMouseDown: .otherMouseDown,
                            .leftMouseUp: .otherMouseUp,
                            .rightMouseUp: .otherMouseUp,
                            .leftMouseDragged: .otherMouseDragged,
                            .rightMouseDragged: .otherMouseDragged
                        ]
                        if let mappedType = mapping[event.type] {
                            if mappedType == .otherMouseUp {
                                recognizer.lockFingerInMiddle = false
                            }
                            recognizer.recognizedGesture = MiddleMouse(type: mappedType, position: event.location)
                            // If you truly need to swallow the original event, use .defaultTap and return nil.
                            // With .listenOnly, you must return the event:
                            return Unmanaged.passUnretained(event)
                        }
                    }
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            // Consider logging via your Logger here
            // logger.error("Failed to create CGEvent tap. Check Accessibility permissions and sandbox.")
            return
        }

        self.eventTap = tap

        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        // IMPORTANT: Do not call CFRunLoopRun() here.
        // The app's run loop is already running; adding the source is sufficient.
    }
}
