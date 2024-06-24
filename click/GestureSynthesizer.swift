//
//  GestureSynthesizer.swift
//  click
//
//  Created by Lukas Schmale on 21.06.24.
//

import Foundation
import CoreGraphics
import AppKit
import Combine

class GestureSynthesizer {
    private let EVENT_SOURCE: CGEventSource = CGEventSource(stateID: .hidSystemState)!
    
    private func beginGesture() {
        print("Start")
        let EVENT: CGEvent = CGEvent(source: EVENT_SOURCE)!
        EVENT.type = CGEventType(rawValue: 19)! // EventType: Gesture
        EVENT.flags = CGEventFlags(rawValue: 536870912)
        EVENT.timestamp = getSystemTime()
        EVENT.setIntegerValueField(CGEventField(rawValue: 55)!, value: 29) // type = Gesture
        EVENT.setIntegerValueField(CGEventField(rawValue: 110)!, value: 61) // SubType = GestureBegin
        EVENT.setIntegerValueField(CGEventField(rawValue: 115)!, value: 5) // SubType = 5 ??
        EVENT.setIntegerValueField(CGEventField(rawValue: 117)!, value: 5) // SubType = 5 ??
        EVENT.post(tap: .cghidEventTap)
    }
    private func endGesture() {
        print("end")
        let EVENT: CGEvent = CGEvent(source: EVENT_SOURCE)!
        EVENT.type = CGEventType(rawValue: 20)! // EventType: Gesture
        EVENT.flags = CGEventFlags(rawValue: 536870912)
        EVENT.timestamp = getSystemTime()
        EVENT.setIntegerValueField(CGEventField(rawValue: 55)!, value: 29) // type = Gesture
        EVENT.setIntegerValueField(CGEventField(rawValue: 110)!, value: 62) // SubType  = GestureEnd
        EVENT.setIntegerValueField(CGEventField(rawValue: 115)!, value: 5) // SubType = 5 ??
        EVENT.setIntegerValueField(CGEventField(rawValue: 117)!, value: 5) // SubType = 5 ??
        EVENT.post(tap: .cghidEventTap)
    }
    private func getSystemTime() -> UInt64 {
        return UInt64(round(ProcessInfo.processInfo.systemUptime*pow(10,9)))
    }
    func synthesize(gesture: Gesture?, previousGesture: Gesture?) {
        var event: CGEvent = CGEvent(source: EVENT_SOURCE)!
        var eventPhase: Int64 = 2 // Phase = Changed
        let GESTURE_TYPE_CHANGED = gesture?.classType() != previousGesture?.classType()
        if GESTURE_TYPE_CHANGED {
            let PREVIOUS_GESTURE_NEEDS_TEAR_DOWN = previousGesture != nil && previousGesture!.NEEDS_GESTURE_FRAME
            if PREVIOUS_GESTURE_NEEDS_TEAR_DOWN {
                event.timestamp = getSystemTime()
                event = previousGesture!.synthesize(event: event)
                event.setIntegerValueField(CGEventField(rawValue: 132)!, value: 4)
                
                event.post(tap: .cghidEventTap)
                endGesture()
            }
            let NEW_GESTURE_NEEDS_BUILD_UP = gesture != nil && gesture!.NEEDS_GESTURE_FRAME
            if NEW_GESTURE_NEEDS_BUILD_UP {
                beginGesture()
                eventPhase = 1 // Phase = Begin
            }
        }
        guard let GESTURE = gesture else {
            return
        }
        event.timestamp = getSystemTime()
        event = GESTURE.synthesize(event: event)
        event.setIntegerValueField(CGEventField(rawValue: 132)!, value: eventPhase)
        
        event.post(tap: .cghidEventTap)
    }
    private func testFields(with name: String, isNSEventField: Bool = false, testValue: Int64 = 1, startIndex: UInt32 = 0, endIndex: UInt32 = 1000) {
        let EVENT = CGEvent(source: EVENT_SOURCE)!
        let PHASE = NSEvent(cgEvent: EVENT)?.phase
        for i: UInt32 in 56...1000 {
            guard let EVENT_FIELD = CGEventField(rawValue: i) else {continue}
            EVENT.setIntegerValueField(EVENT_FIELD, value: 2)
            print(i, NSEvent(cgEvent: EVENT)?.phase)
            if (NSEvent(cgEvent: EVENT)?.phase != PHASE) {
                print(i)
                exit(1)
            }
        }
    }
    
}

protocol Gesture {
    var NEEDS_GESTURE_FRAME: Bool { get }
    
    func synthesize(event: CGEvent) -> CGEvent
}
extension Gesture {
    func classType() -> Gesture.Type {
        return type(of: self)
    }
}
class Magnification: Gesture {
    let NEEDS_GESTURE_FRAME: Bool = true
    
    private var magnification: Double
    init(delta: Double) {
        magnification = delta
    }
    
    func synthesize(event: CGEvent) -> CGEvent {
        event.type = CGEventType(rawValue: 30)! // EventType: Gesture
        event.flags = CGEventFlags(rawValue: 536870912)
        
        event.setIntegerValueField(CGEventField(rawValue: 55)!, value: 29) // Type = Magnify
        event.setIntegerValueField(CGEventField(rawValue: 59)!, value: 256) // ??
        event.setIntegerValueField(CGEventField(rawValue: 101)!, value: 4) // ??
        event.setIntegerValueField(CGEventField(rawValue: 107)!, value: 4) // ??
        event.setIntegerValueField(CGEventField(rawValue: 110)!, value: 8) // SubType = Magnify
        event.setDoubleValueField(CGEventField(rawValue: 113)!, value: magnification) // Magnification
        event.setDoubleValueField(CGEventField(rawValue: 114)!, value: magnification) // Magnification
        event.setDoubleValueField(CGEventField(rawValue: 116)!, value: magnification) // Magnification
        event.setDoubleValueField(CGEventField(rawValue: 118)!, value: magnification) // Magnification
        
        return event
    }
}
class Rotation: Gesture {
    let NEEDS_GESTURE_FRAME: Bool = true
    
    var rotation: Double
    init(delta: Double) {
        rotation = delta
    }
    
    func synthesize(event: CGEvent) -> CGEvent {
        event.type = CGEventType(rawValue: 18)! // EventType: Rotate
        event.flags = CGEventFlags(rawValue: 536870912)
        
        event.setIntegerValueField(CGEventField(rawValue: 55)!, value: 29) // Type = Gesture
        event.setIntegerValueField(CGEventField(rawValue: 59)!, value: 256) // ??
        event.setIntegerValueField(CGEventField(rawValue: 101)!, value: 4) // ??
        event.setIntegerValueField(CGEventField(rawValue: 107)!, value: 1200) // ??
        event.setIntegerValueField(CGEventField(rawValue: 110)!, value: 5) // SubType = Rotate
        event.setDoubleValueField(CGEventField(rawValue: 113)!, value: rotation) // Rotation
        event.setDoubleValueField(CGEventField(rawValue: 114)!, value: rotation) // Rotation
        event.setDoubleValueField(CGEventField(rawValue: 116)!, value: rotation) // Rotation
        event.setDoubleValueField(CGEventField(rawValue: 118)!, value: rotation) // Rotation
        
        return event
    }
}
class MiddleMouse: Gesture {
// Gesture Implementation
    let NEEDS_GESTURE_FRAME: Bool = false
    
    func synthesize(event: CGEvent) -> CGEvent {
        return CGEvent(mouseEventSource: CGEventSource(event: event), mouseType: TYPE, mouseCursorPosition: POSITION, mouseButton: .center)!
    }
// Own
    private let ALLOWED_EVENT_TYPES: Array<CGEventType> = [.otherMouseDown, .otherMouseUp, .otherMouseDragged]
    private let TYPE: CGEventType
    
    private let POSITION: CGPoint
    init?(type: CGEventType, position: CGPoint) {
        guard ALLOWED_EVENT_TYPES.contains(type) else {
            return nil
        }
        TYPE = type
        POSITION = position
    }
    
}
