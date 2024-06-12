//
//  clickApp.swift
//  click
//
//  Created by Lukas Schmale on 12.06.24.
//

import SwiftUI

@main
struct clickApp: App {
    @State private var touches: [CGPoint] = []

    var body: some Scene {
        WindowGroup {
            TouchView(touches: touches)
                .onAppear() {
                    let device = MTDeviceCreateDefault().takeRetainedValue() as MTDevice
                    MTRegisterContactFrameCallback(device) { device, touches, fingers, time, frame in
                        
                        let touchesBuffer = UnsafeBufferPointer(start: touches, count: fingers)
                        for touch in touchesBuffer {
                            let position = touch.normalized.position
                            let id = touch.fingerID
                            print(id)
                        }
                        
                    }
                    MTDeviceStart(device, 0)
                }
        }
    }
}
