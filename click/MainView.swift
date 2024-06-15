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
        public func update(touches: [MTTouch]) {
            DispatchQueue.main.async {
                self.buffer = touches
            }
        }
    }
    @ObservedObject var observableTouches: ObservableTouches = ObservableTouches()
    
    func extractPositionFrom(_ touch: MTTouch) -> CGPoint {
        let TOUCH_POSITION = touch.normalized.position
        let MOUSE_IMAGE_WIDTH: CGFloat = 180,
            MOUSE_IMAGE_HEIGHT: CGFloat = 290
        let LEFT: CGFloat = 60,
            BOTTOM: CGFloat = 30
        
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
            
            ForEach(observableTouches.buffer.enumerated().map { $0 }, id: \.0) { index, touch in
                Circle()
                    .stroke(Color.blue)
                    .fill(Color.blue.opacity(extractPressureFrom(touch: touch)))
                    .frame(width: 20, height: 20)
                    .position(extractPositionFrom(touch))
            }
        }.frame(minWidth: 300, maxWidth: 300)
    }
}
