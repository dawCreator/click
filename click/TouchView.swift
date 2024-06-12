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
    @ObservedObject var touches = Touches()

    func test(_ touches: [MTTouch]) {
        self.touches.set(touches: touches)
    }

    func extractPositionFrom(_ touch: MTTouch, geometry: GeometryProxy) -> CGPoint {
        let MT_POINT = touch.normalized.position
        let X = CGFloat(MT_POINT.x)*geometry.size.width,
            Y = (1-CGFloat(MT_POINT.y))*geometry.size.height
        return CGPoint(x: X, y: Y)
    }

    var body: some View {
        ZStack {
            GeometryReader { GEOMETRY in
                ForEach(touches.buffer.enumerated().map { $0 }, id: \.0) { index, touch in
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 20, height: 20)
                        .position(extractPositionFrom(touch, geometry: GEOMETRY))
                }
            }
        }
    }
}
