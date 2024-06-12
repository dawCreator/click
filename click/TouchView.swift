//
//  TouchView.swift
//  click
//
//  Created by Lukas Schmale on 12.06.24.
//

import SwiftUI

class Touches: ObservableObject {
    @Published private(set) var buffer: [MTTouch] = []

    func set(touches: [MTTouch]) {
        DispatchQueue.main.async {
            self.buffer = touches
        }
    }
}

struct TouchView: View {

    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var touches = Touches()

    func test(_ touches: [MTTouch]) {
        self.touches.set(touches: touches)
        for touch in touches {
            print(touch.angle, touch.majorAxis, touch.minorAxis)
        }
    }

    func extractPositionFrom(_ touch: MTTouch, geometry: GeometryProxy, mouseImagePadding: CGFloat, mouseImageSize: CGFloat, mouseImageRatio: CGFloat) -> CGPoint {
        let TOUCH_POSITION = touch.normalized.position
        let MOUSE_USUABLE_HEIGHT_PERCENTAGE = 0.8
        let MOUSE_IMAGE_WIDTH = mouseImageSize/mouseImageRatio,
            MOUSE_IMAGE_HEIGHT = mouseImageSize*MOUSE_USUABLE_HEIGHT_PERCENTAGE
        let LEFT = geometry.size.width - mouseImagePadding - mouseImageSize/mouseImageRatio,
            BOTTOM = mouseImagePadding
        
        let X = CGFloat(TOUCH_POSITION.x)*MOUSE_IMAGE_WIDTH + LEFT,
            Y = (1-CGFloat(TOUCH_POSITION.y))*MOUSE_IMAGE_HEIGHT + BOTTOM
        return CGPoint(x: X, y: Y)
    }
    
    func extractPressureFrom(touch: MTTouch) -> Double {
        let PRESSURE_BASE = touch.zTotal
        return Double(PRESSURE_BASE) / 2
    }

    var body: some View {
        GeometryReader { WINDOW_BOUNDS in
            ZStack {
                let IMAGE_PADDING: CGFloat = 20,
                    IMAGE_SIZE = min(WINDOW_BOUNDS.size.width, WINDOW_BOUNDS.size.height) - 2*IMAGE_PADDING,
                    IMAGE_RATIO = 1.85
                Image("MagicMouse")
                    .resizable()
                    .frame(width: IMAGE_SIZE, height: IMAGE_SIZE)
                    .position(x: WINDOW_BOUNDS.size.width - IMAGE_SIZE/IMAGE_RATIO/2 - IMAGE_PADDING, y: WINDOW_BOUNDS.size.height/2)
                    .colorMultiply(colorScheme == .dark ? .white : .black)
                
                ForEach(touches.buffer.enumerated().map { $0 }, id: \.0) { index, touch in
                    Circle()
                        .stroke(Color.blue)
                        .fill(Color.blue.opacity(extractPressureFrom(touch: touch)))
                        .frame(width: 20, height: 20)
                        .position(extractPositionFrom(touch, geometry: WINDOW_BOUNDS, mouseImagePadding: IMAGE_PADDING, mouseImageSize: IMAGE_SIZE, mouseImageRatio: IMAGE_RATIO))
                }
            }
        }
    }
}
