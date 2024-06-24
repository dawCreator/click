//
//  GestureSynthesizer.swift
//  click
//
//  Created by Lukas Schmale on 21.06.24.
//

import Foundation
import CoreGraphics
import AppKit

class EventSynthesizer {
    static let SINGLETON: EventSynthesizer = EventSynthesizer()
    static let EVENT_SOURCE: CGEventSource = CGEventSource(stateID: .hidSystemState)!
    private enum EventType {
        case Magnification
    }
    private func getSystemTime() -> UInt64 {
        return UInt64(round(ProcessInfo.processInfo.systemUptime*pow(10,9)))
    }
    private var currentGestureType: EventType?
    public func synthesizeGestureBegin() {
        let EVENT: CGEvent = CGEvent(source: EventSynthesizer.EVENT_SOURCE)!
        EVENT.type = CGEventType(rawValue: 19)! // EventType: Gesture
        EVENT.flags = CGEventFlags(rawValue: 536870912)
        EVENT.timestamp = getSystemTime()
        EVENT.setIntegerValueField(CGEventField(rawValue: 55)!, value: 29) // EventType = Gesture
        EVENT.setIntegerValueField(CGEventField(rawValue: 110)!, value: 61) // SubType = GestureBegin
        EVENT.setIntegerValueField(CGEventField(rawValue: 115)!, value: 5) // SubType = 5 ??
        EVENT.setIntegerValueField(CGEventField(rawValue: 117)!, value: 5) // SubType = 5 ??
        EVENT.post(tap: .cghidEventTap)
    }
    public func synthesizeGestureEnd() {
        let EVENT: CGEvent = CGEvent(source: EventSynthesizer.EVENT_SOURCE)!
        EVENT.type = CGEventType(rawValue: 20)! // EventType: Gesture
        EVENT.flags = CGEventFlags(rawValue: 536870912)
        EVENT.timestamp = getSystemTime()
        EVENT.setIntegerValueField(CGEventField(rawValue: 55)!, value: 29) // GestureType
        EVENT.setIntegerValueField(CGEventField(rawValue: 110)!, value: 62) // SubType  = GestureEnd
        EVENT.setIntegerValueField(CGEventField(rawValue: 115)!, value: 5) // SubType = 5 ??
        EVENT.setIntegerValueField(CGEventField(rawValue: 117)!, value: 5) // SubType = 5 ??
        EVENT.post(tap: .cghidEventTap)
        isFirst = true
    }
    private var isFirst: Bool = true
    public func synthesizeMagnification(magnification: Double) {
        let EVENT: CGEvent = CGEvent(source: EventSynthesizer.EVENT_SOURCE)!
        EVENT.type = CGEventType(rawValue: 30)! // EventType: Gesture
        EVENT.flags = CGEventFlags(rawValue: 536870912)
        EVENT.timestamp = getSystemTime()
        
        EVENT.setIntegerValueField(CGEventField(rawValue: 55)!, value: 29) // Type = Gesture
        EVENT.setIntegerValueField(CGEventField(rawValue: 59)!, value: 256) // ??
        EVENT.setIntegerValueField(CGEventField(rawValue: 101)!, value: 4) // ??
        EVENT.setIntegerValueField(CGEventField(rawValue: 107)!, value: 4) // ??
        EVENT.setIntegerValueField(CGEventField(rawValue: 110)!, value: 8) // SubType = Magnify
        var eventPhase: Int64 = 4
        if isFirst {
            isFirst = false
            eventPhase = 1
        }
        EVENT.setIntegerValueField(CGEventField(rawValue: 132)!, value: eventPhase) // EventPhase!!!
        EVENT.setDoubleValueField(CGEventField(rawValue: 113)!, value: magnification) // Magnification
        EVENT.setDoubleValueField(CGEventField(rawValue: 114)!, value: magnification) // Magnification
        EVENT.setDoubleValueField(CGEventField(rawValue: 116)!, value: magnification) // Magnification
        EVENT.setDoubleValueField(CGEventField(rawValue: 118)!, value: magnification) // Magnification
        
        
        EVENT.post(tap: .cghidEventTap)
    }
    public func synthesizeRotation(rotation: Double) {
        let EVENT: CGEvent = CGEvent(source: EventSynthesizer.EVENT_SOURCE)!
        EVENT.type = CGEventType(rawValue: 18)! // EventType: Rotate
        EVENT.flags = CGEventFlags(rawValue: 536870912)
        EVENT.timestamp = getSystemTime()
        EVENT.setIntegerValueField(CGEventField(rawValue: 55)!, value: 29) // Type = Gesture
        EVENT.setIntegerValueField(CGEventField(rawValue: 59)!, value: 256) // ??
        EVENT.setIntegerValueField(CGEventField(rawValue: 101)!, value: 4) // ??
        EVENT.setIntegerValueField(CGEventField(rawValue: 107)!, value: 1200) // ??
        EVENT.setIntegerValueField(CGEventField(rawValue: 110)!, value: 5) // SubType = Rotate
        EVENT.setDoubleValueField(CGEventField(rawValue: 113)!, value: rotation) // Rotation
        EVENT.setDoubleValueField(CGEventField(rawValue: 114)!, value: rotation) // Rotation
        EVENT.setDoubleValueField(CGEventField(rawValue: 116)!, value: rotation) // Rotation
        EVENT.setDoubleValueField(CGEventField(rawValue: 118)!, value: rotation) // Rotation
        EVENT.post(tap: .cghidEventTap)
    }
    private func testFields(with name: String, isNSEventField: Bool = false, testValue: Int64 = 1, startIndex: UInt32 = 0, endIndex: UInt32 = 1000) {
        var EVENT = CGEvent(source: EventSynthesizer.EVENT_SOURCE)!
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
    private func getPropertyValue<T>(of object: T, propertyName: String) -> Any? {
        let mirror = Mirror(reflecting: object)
        
        for child in mirror.children {
            if let label = child.label, label == propertyName {
                return child.value
            }
        }
        
        return nil
    }
}
