//
//  clickApp.swift
//  click
//
//  Created by Lukas Schmale on 12.06.24.
//

import SwiftUI
import AppKit

@main
struct click: App {
    @Environment(\.colorScheme) var colorScheme
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MenuBarExtra("", image: colorScheme == .light ? "StatusBarIconLight" : "StatusBarIconDark") {
            MainView.MAIN_VIEW
        }.menuBarExtraStyle(.window)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        Device.startMonitoringDevices()
        GestureRecognizer.GESTURE_RECOGNIZER.setupEventTap()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}



