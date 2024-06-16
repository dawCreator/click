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
    private var isMiddle: Bool = false

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
                let DISTANCE_DELTA = DISTANCE - previousDistance!
                print("Scale: ", DISTANCE_DELTA)
                print(CGEvent.tapIsEnabled(tap: eventTap!))
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
        let IS_MIDDLE_POINTER: UnsafeMutablePointer<Bool> = withUnsafeMutablePointer(to: &isMiddle) { $0 }

        // Create the event tap
        eventTap = CGEvent.tapCreate(
           tap: .cghidEventTap,
           place: .headInsertEventTap,
           options: .defaultTap,
           eventsOfInterest: CGEventMask(eventMask),
           callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
               let IS_MIDDLE = refcon!.assumingMemoryBound(to: Bool.self).pointee
               print(IS_MIDDLE)
               if IS_MIDDLE {
                   // Consume the existing event
                   event.setIntegerValueField(.mouseEventButtonNumber, value: Int64(2)) // Set the event to Middle Click

                   // Send the new event
                   event.post(tap: .cghidEventTap)

                   // Return nil to consume the original event
                   return nil
               }

               // Return the original event if no modification is needed
               return Unmanaged.passRetained(event)
           }, userInfo: UnsafeMutableRawPointer(IS_MIDDLE_POINTER))!

        // Create a run loop source and add it to the current run loop
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap!, enable: true)
        CFRunLoopRun()
        // Run the run loop to keep the event tap active
        //RunLoop.current.run()
    }
}
