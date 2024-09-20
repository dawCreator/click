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
        let ALL_EVENTS_MASK: CGEventMask = ~CGEventMask(0)

        let SELF_POINTER = UnsafeMutablePointer<GestureRecognizer>.allocate(capacity: 1)
        SELF_POINTER.initialize(to: self)
        
        eventTap = CGEvent.tapCreate(
           tap: .cghidEventTap, // Lowest Level Event Tap
           place: .headInsertEventTap, // Insert First => Gets Events First
           options: .defaultTap, // Can Read & Write Events
           eventsOfInterest: ALL_EVENTS_MASK,
           callback: { (proxy, type, event, self) -> Unmanaged<CGEvent>? in
               let GESTURE_RECOGNIZER = self!.assumingMemoryBound(to: GestureRecognizer.self).pointee
               if (type == .tapDisabledByTimeout) {
                   CGEvent.tapEnable(tap: GESTURE_RECOGNIZER.eventTap!, enable: true)
               } else if GESTURE_RECOGNIZER.onlyFingerInMiddle {
                   let MAPPING: [CGEventType: CGEventType] = [
                           .leftMouseDown: .otherMouseDown,
                           .rightMouseDown: .otherMouseDown,
                           .leftMouseUp: .otherMouseUp,
                           .rightMouseUp: .otherMouseUp,
                           .leftMouseDragged: .otherMouseDragged,
                           .rightMouseDragged: .otherMouseDragged
                       ]
                   guard let EVENT_TYPE = MAPPING[event.type] else {
                       return Unmanaged.passUnretained(event)
                   }
                   if EVENT_TYPE == .otherMouseUp {
                       GESTURE_RECOGNIZER.lockFingerInMiddle = false
                   }
                   GESTURE_RECOGNIZER.recognizedGesture = MiddleMouse(type: EVENT_TYPE, position: event.location)
                   return nil
               }
            // Return the original event if no modification is needed
               return Unmanaged.passUnretained(event)
           }, userInfo: SELF_POINTER)!

    // Create a run loop source and add it to the current run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap!, enable: true)
        CFRunLoopRun()
    }
}
