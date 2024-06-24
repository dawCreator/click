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
                let DELAY = 0.001
                let EVENT_SYNTHESIZER: EventSynthesizer = EventSynthesizer.SINGLETON
                EVENT_SYNTHESIZER.synthesizeGestureBegin()
                Thread.sleep(forTimeInterval: DELAY)
                EVENT_SYNTHESIZER.synthesizeMagnification(magnification: DISTANCE_DELTA)
                Thread.sleep(forTimeInterval: DELAY)
                EVENT_SYNTHESIZER.synthesizeMagnification(magnification: DISTANCE_DELTA)
                Thread.sleep(forTimeInterval: DELAY)
                EVENT_SYNTHESIZER.synthesizeMagnification(magnification: DISTANCE_DELTA)
                Thread.sleep(forTimeInterval: DELAY)
                EVENT_SYNTHESIZER.synthesizeGestureEnd()
                Thread.sleep(forTimeInterval: DELAY)
            }
            previousDistance = DISTANCE
        default:
            break
        }
    }
    private var eventTap: CFMachPort?
    func setupEventTap() {
        let eventMask: CGEventMask = ~CGEventMask(0)

        // Use Unmanaged.passRetained to properly manage the memory of the isMiddle pointer
        let IS_MIDDLE_POINTER = UnsafeMutablePointer<GestureRecognizer>.allocate(capacity: 1)
        IS_MIDDLE_POINTER.initialize(to: self)
        // Create the event tap
        eventTap = CGEvent.tapCreate(
           tap: .cghidEventTap,
           place: .headInsertEventTap,
           options: .defaultTap,
           eventsOfInterest: eventMask,
           callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
               func getHumanReadableEventType(eventTypeRawValue: UInt32) -> String {
                   switch eventTypeRawValue {
                   case 0:
                       return "Null"
                   case 1:
                       return "Left Mouse Down"
                   case 2:
                       return "Left Mouse Up"
                   case 3:
                       return "Right Mouse Down"
                   case 4:
                       return "Right Mouse Up"
                   case 5:
                       return "Mouse Moved"
                   case 6:
                       return "Left Mouse Dragged"
                   case 7:
                       return "Right Mouse Dragged"
                   case 8:
                       return "Mouse Entered"
                   case 9:
                       return "Mouse Exited"
                   case 10:
                       return "Key Down"
                   case 11:
                       return "Key Up"
                   case 12:
                       return "Flags Changed"
                   case 13:
                       return "AppKit Defined"
                   case 14:
                       return "System Defined"
                   case 15:
                       return "Application Defined"
                   case 16:
                       return "Periodic"
                   case 17:
                       return "Cursor Update"
                   case 18:
                       return "Rotate"
                   case 19:
                       return "Begin Gesture"
                   case 20:
                       return "End Gesture"
                   case 22:
                       return "Scroll Wheel"
                   case 23:
                       return "Tablet Point"
                   case 24:
                       return "Tablet Proximity"
                   case 25:
                       return "Other Mouse Down"
                   case 26:
                       return "Other Mouse Up"
                   case 27:
                       return "Other Mouse Dragged"
                   case 29:
                       return "Gesture"
                   case 30:
                       return "Magnify"
                   case 31:
                       return "Swipe"
                   case 32:
                       return "Smart Magnify"
                   case 33:
                       return "Quick Look"
                   default:
                       return "Unknown Event Type (\(eventTypeRawValue))"
                   }
               }
               let EVENT_TYPE = getHumanReadableEventType(eventTypeRawValue: type.rawValue)
               if (EVENT_TYPE == "Gesture") {
                   func printGestureEventDetails(nsEvent: NSEvent) {
                       print("Gesture Event Details:")
                       print(nsEvent.type.rawValue)
                       print(nsEvent.phase, "\n")
                   }
                   //printGestureEventDetails(nsEvent: NSEvent(cgEvent: event)!)
               }
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
    @objc func handlePinch() {
        print("hzello")
    }
    private func capturePinchEvents() {
        let gestureRecognizer = NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinch))
    }
}
