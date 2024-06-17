//
//  GestureRecognizer.swift
//  click
//
//  Created by Lukas Schmale on 13.06.24.
//
import AppKit
import CoreGraphics

class GestureRecognizer: ObservableObject {
    static let GESTURE_RECOGNIZER: GestureRecognizer = GestureRecognizer()
    
    private var previousDistance: Float?
    var isMiddle: Bool = false

    public func recognize(mtTouches: [MTTouch]) {
        let FINGER_COUNT = mtTouches.count
        if FINGER_COUNT != 2 {
            previousDistance = nil
        }
        if FINGER_COUNT != 1 {
            isMiddle = false
        }
        switch FINGER_COUNT {
        case 1:
            let ONLY_TOUCH = mtTouches[0],
                POSITION = ONLY_TOUCH.normalized.position,
                X = POSITION.x
            isMiddle = 0.4 < X && X < 0.6
        case 2:
            let TOUCH_ONE = mtTouches[0],
                TOUCH_TWO = mtTouches[1]
            let A = TOUCH_ONE.normalized.position,
                B = TOUCH_TWO.normalized.position
            let DX = A.x - B.x,
                DY = A.y - B.y
            let DISTANCE = sqrt(DX*DX + DY*DY)
            if previousDistance != nil {
                let DISTANCE_DELTA: Double = Double(DISTANCE - previousDistance!)
                /*
                let PINCH_EVENT = CGEvent(source: nil)!
                let base: Double = 1000 // magic
                let value = Int64(min(max(-1, Float(DISTANCE_DELTA / base)), 1).bitPattern)
                PINCH_EVENT.type = CGEventType.gesture
                PINCH_EVENT[NSEvent.gestureType] = NSEvent.GestureType.zoom.rawValue
                PINCH_EVENT[NSEvent.gestureSwipeDirection] = value
                PINCH_EVENT[NSEvent.gestureZoomDirection] = value
                PINCH_EVENT[NSEvent.gesturePhase] = Int64(phase.rawValue)
                e.post(tap: .cghidEventTap)
                 */
            }
            previousDistance = DISTANCE
        default:
            break
        }
    }
    private var eventTap: CFMachPort?
    func setupEventTap() {
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) |
                        (1 << CGEventType.leftMouseUp.rawValue) |
                        (1 << CGEventType.rightMouseDown.rawValue) |
                        (1 << CGEventType.rightMouseUp.rawValue)

        // Use Unmanaged.passRetained to properly manage the memory of the isMiddle pointer
        let IS_MIDDLE_POINTER = UnsafeMutablePointer<GestureRecognizer>.allocate(capacity: 1)
        IS_MIDDLE_POINTER.initialize(to: self)
        // Create the event tap
        eventTap = CGEvent.tapCreate(
           tap: .cghidEventTap,
           place: .headInsertEventTap,
           options: .defaultTap,
           eventsOfInterest: CGEventMask(eventMask),
           callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
               let GESTURE_RECOGNIZER = refcon!.assumingMemoryBound(to: GestureRecognizer.self).pointee
               if (type == .tapDisabledByTimeout) {
                   CGEvent.tapEnable(tap: GESTURE_RECOGNIZER.eventTap!, enable: true)
               }
               else if GESTURE_RECOGNIZER.isMiddle {
                   var midEventType: CGEventType
                   switch type {
                   case .leftMouseDown:
                       midEventType = .otherMouseDown
                   case .rightMouseDown:
                       midEventType = .otherMouseDown
                   case .leftMouseUp:
                       midEventType = .otherMouseUp
                   case .rightMouseUp:
                       midEventType = .otherMouseUp
                   case .leftMouseDragged:
                       midEventType = .otherMouseDragged
                   case .rightMouseDragged:
                       midEventType = .otherMouseDragged
                   default:
                       return Unmanaged.passUnretained(event)
                   }
                   let MID_EVENT = CGEvent(mouseEventSource: CGEventSource(event: event), mouseType: midEventType, mouseCursorPosition: event.location, mouseButton: .center)
                   MID_EVENT?.post(tap: .cghidEventTap)
                   return nil
               }
               // Return the original event if no modification is needed
               return Unmanaged.passUnretained(event)
           }, userInfo: IS_MIDDLE_POINTER)!

        // Create a run loop source and add it to the current run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap!, enable: true)
        CFRunLoopRun()
        // Run the run loop to keep the event tap active
        //RunLoop.current.run()
    }
}
