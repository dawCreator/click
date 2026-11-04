//
//  DeviceView.swift
//  click
//
//  Created by Lukas Schmale on 12.06.24.
//

import SwiftUI

struct MainView: View {
    static public let MAIN_VIEW: MainView = MainView()
    
    @Environment(\.colorScheme) var colorScheme
    class ObservableTouches: ObservableObject {
        @Published private(set) var buffer: [MTTouch] = []
        private var lastPublishedAt: TimeInterval = 0

        func update(touches: [MTTouch]) {
            if Thread.isMainThread {
                publish(touches)
            } else {
                DispatchQueue.main.async {
                    self.publish(touches)
                }
            }
        }

        private func publish(_ touches: [MTTouch]) {
            let now = ProcessInfo.processInfo.systemUptime
            guard touches.isEmpty || now - lastPublishedAt >= 1.0 / 60.0 else { return }
            lastPublishedAt = now
            buffer = touches
        }
    }
    @ObservedObject var observableTouches: ObservableTouches = ObservableTouches()
    
    func extractPositionFrom(_ touch: MTTouch) -> CGPoint {
        let TOUCH_POSITION = touch.normalized.position
        let MOUSE_IMAGE_WIDTH: CGFloat = 300,
            MOUSE_IMAGE_HEIGHT: CGFloat = 440
        let LEFT: CGFloat = 200,
            BOTTOM: CGFloat = 60
        
        let X = CGFloat(TOUCH_POSITION.x)*MOUSE_IMAGE_WIDTH + LEFT,
            Y = (1-CGFloat(TOUCH_POSITION.y))*MOUSE_IMAGE_HEIGHT + BOTTOM
        return CGPoint(x: X, y: Y)
    }
    
    func extractPressureFrom(touch: MTTouch) -> Double {
        let PRESSURE_BASE = touch.zTotal
        return Double(PRESSURE_BASE) / 2
    }

    var body: some View {
        ZStack {
            Image(colorScheme == .dark ? "MagicMouseDark" : "MagicMouseLight")
                .resizable()
                .frame(width: 700, height: 700)
                .offset(x: 10)
            ForEach(observableTouches.buffer.enumerated().map { $0 }, id: \.0) { index, touch in
                Circle()
                    .stroke(Color.blue)
                    .fill(Color.blue.opacity(extractPressureFrom(touch: touch)))
                    .frame(width: 40, height: 40)
                    .position(extractPositionFrom(touch))
            }
        }.frame(minWidth: 370, maxWidth: 370, minHeight: 600, maxHeight: 600)
    }
}
