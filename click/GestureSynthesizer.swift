//
//  GestureSynthesizer.swift
//  click
//
//  Created by Lukas Schmale on 21.06.24.
//

import Foundation
import CoreGraphics
import AppKit

private func setCGEventIntegerField(_ rawValue: UInt32, on event: CGEvent, to value: Int64) {
    guard let field = CGEventField(rawValue: rawValue) else { return }
    event.setIntegerValueField(field, value: value)
}

private func setCGEventDoubleField(_ rawValue: UInt32, on event: CGEvent, to value: Double) {
    guard let field = CGEventField(rawValue: rawValue) else { return }
    event.setDoubleValueField(field, value: value)
}

final class GestureSynthesizer {
    private let eventSource = CGEventSource(stateID: .hidSystemState)

    private func makeEvent() -> CGEvent? {
        guard let eventSource else { return nil }
        return CGEvent(source: eventSource)
    }

    private func beginGesture() -> Bool {
        guard let event = makeEvent(), let eventType = CGEventType(rawValue: 19) else { return false }
        event.type = eventType
        event.flags = CGEventFlags(rawValue: 536870912)
        event.timestamp = getSystemTime()
        setCGEventIntegerField(55, on: event, to: 29)
        setCGEventIntegerField(110, on: event, to: 61)
        setCGEventIntegerField(115, on: event, to: 5)
        setCGEventIntegerField(117, on: event, to: 5)
        setCGEventIntegerField(87, on: event, to: 4294970300)
        event.post(tap: .cghidEventTap)
        return true
    }

    private func endGesture() -> Bool {
        guard let event = makeEvent(), let eventType = CGEventType(rawValue: 20) else { return false }
        event.type = eventType
        event.flags = CGEventFlags(rawValue: 536870912)
        event.timestamp = getSystemTime()
        setCGEventIntegerField(55, on: event, to: 29)
        setCGEventIntegerField(110, on: event, to: 62)
        setCGEventIntegerField(115, on: event, to: 5)
        setCGEventIntegerField(117, on: event, to: 5)
        setCGEventIntegerField(87, on: event, to: 4294970300)
        event.post(tap: .cghidEventTap)
        return true
    }

    private func getSystemTime() -> UInt64 {
        UInt64(ProcessInfo.processInfo.systemUptime * 1_000_000_000)
    }

    /// Returns false if the requested synthetic event could not be constructed.
    @discardableResult
    func synthesize(gesture: Gesture?, previousGesture: Gesture?) -> Bool {
        guard var event = makeEvent() else { return false }
        var eventPhase: Int64 = 2 // Changed
        let gestureTypeChanged = gesture?.classType() != previousGesture?.classType()

        if gestureTypeChanged {
            if let previousGesture, previousGesture.NEEDS_GESTURE_FRAME {
                event.timestamp = getSystemTime()
                guard let tearDownEvent = previousGesture.synthesize(event: event) else { return false }
                setCGEventIntegerField(132, on: tearDownEvent, to: 4)
                tearDownEvent.post(tap: .cghidEventTap)
                guard endGesture() else { return false }
            }

            if let gesture, gesture.NEEDS_GESTURE_FRAME {
                guard beginGesture() else { return false }
                eventPhase = 1 // Begin
            }
        }

        guard let gesture else { return true }
        event.timestamp = getSystemTime()
        guard let synthesizedEvent = gesture.synthesize(event: event) else { return false }
        setCGEventIntegerField(132, on: synthesizedEvent, to: eventPhase)
        synthesizedEvent.post(tap: .cghidEventTap)
        return true
    }
}

protocol Gesture {
    var NEEDS_GESTURE_FRAME: Bool { get }
    func synthesize(event: CGEvent) -> CGEvent?
}

extension Gesture {
    func classType() -> Gesture.Type {
        type(of: self)
    }
}

final class Magnification: Gesture {
    let NEEDS_GESTURE_FRAME = true
    private let magnification: Double

    init(delta: Double) {
        magnification = delta
    }

    func synthesize(event: CGEvent) -> CGEvent? {
        guard let eventType = CGEventType(rawValue: 30) else { return nil }
        event.type = eventType
        event.flags = CGEventFlags(rawValue: 536870912)
        setCGEventIntegerField(55, on: event, to: 29)
        setCGEventIntegerField(59, on: event, to: 256)
        setCGEventIntegerField(101, on: event, to: 4)
        setCGEventIntegerField(107, on: event, to: 4)
        setCGEventIntegerField(110, on: event, to: 8)
        setCGEventIntegerField(87, on: event, to: 4294970300)
        setCGEventDoubleField(113, on: event, to: magnification)
        setCGEventDoubleField(114, on: event, to: magnification)
        setCGEventDoubleField(116, on: event, to: magnification)
        setCGEventDoubleField(118, on: event, to: magnification)
        return event
    }
}

final class Rotation: Gesture {
    let NEEDS_GESTURE_FRAME = true
    private let rotation: Double

    init(delta: Double) {
        rotation = delta
    }

    func synthesize(event: CGEvent) -> CGEvent? {
        guard let eventType = CGEventType(rawValue: 18) else { return nil }
        event.type = eventType
        event.flags = CGEventFlags(rawValue: 536870912)
        setCGEventIntegerField(55, on: event, to: 29)
        setCGEventIntegerField(59, on: event, to: 256)
        setCGEventIntegerField(101, on: event, to: 4)
        setCGEventIntegerField(107, on: event, to: 1200)
        setCGEventIntegerField(110, on: event, to: 5)
        setCGEventDoubleField(113, on: event, to: rotation)
        setCGEventDoubleField(114, on: event, to: rotation)
        setCGEventDoubleField(116, on: event, to: rotation)
        setCGEventDoubleField(118, on: event, to: rotation)
        return event
    }
}

final class MouseButtonClick: Gesture {
    let NEEDS_GESTURE_FRAME = false
    let TYPE: CGEventType
    private let button: CGMouseButton
    private let position: CGPoint

    init(type: CGEventType, button: CGMouseButton, position: CGPoint) {
        self.button = button
        TYPE = type
        self.position = position
    }

    func synthesize(event: CGEvent) -> CGEvent? {
        guard let source = CGEventSource(event: event) else { return nil }
        return CGEvent(
            mouseEventSource: source,
            mouseType: TYPE,
            mouseCursorPosition: position,
            mouseButton: button
        )
    }
}
