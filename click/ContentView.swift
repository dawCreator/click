//
//  ContentView.swift
//  click
//
//  Created by Lukas Schmale on 12.06.24.
//

import SwiftUI

struct TouchView: View {
    let touches: [CGPoint]

    var body: some View {
        ZStack {
            ForEach(touches.enumerated().map { $0 }, id: \.0) { index, point in
                Circle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 20)
                    .position(point)
            }
        }
    }
}


#Preview {
    TouchView(touches: [
        CGPoint(x: 100, y: 100),
        CGPoint(x: 200, y: 200),
        CGPoint(x: 300, y: 300)
    ])
}
