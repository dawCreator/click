//
//  clickApp.swift
//  click
//
//  Created by Lukas Schmale on 12.06.24.
//

import SwiftUI

@main
struct ClickApp: App {
    private let TOUCH_VIEW = TouchView()

    var body: some Scene {
        WindowGroup {
            TOUCH_VIEW
                .onAppear() {
                    guard let DEVICE = MTDeviceCreateDefault()?.takeRetainedValue() else {
                        // Handle error: unable to create MTDevice
                        return
                    }
                    
                    let TOUCH_VIEW_POINTER = UnsafeMutablePointer<TouchView>.allocate(capacity: 1)
                    TOUCH_VIEW_POINTER.initialize(to: TOUCH_VIEW)
                    MTRegisterContactFrameCallbackWithRefcon(DEVICE, { device, touches, fingers, time, frame, refcon in
                        let TOUCH_VIEW_POINTER = refcon!.assumingMemoryBound(to: TouchView.self),
                            TOUCH_VIEW = TOUCH_VIEW_POINTER.pointee
                        let TOUCHES_BUFFER = UnsafeBufferPointer(start: touches, count: fingers),
                            TOUCHES = Array(TOUCHES_BUFFER)
                        TOUCH_VIEW.test(TOUCHES)
                    }, TOUCH_VIEW_POINTER)
                    MTDeviceStart(DEVICE, 0)
                }
        }
    }
}

