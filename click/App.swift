//
//  clickApp.swift
//  click
//
//  Created by Lukas Schmale on 12.06.24.
//

import SwiftUI
import AppKit
import ServiceManagement

@main
struct click: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
      Settings {
        Text("Settings or main app window")
      }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popOver: NSPopover!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        guard isProcessTrusted() else {
            exit(1)
        }
        
        NSApplication.shared.setActivationPolicy(.accessory)
    // Start App on Launch:
        do {
            try SMAppService.mainApp.register()
        }
        catch {
            print("Failed Start On Launch")
        }
            
        Device.startMonitoringDevices()
        GestureRecognizer.SINGLETON.setupEventTap()
    // TODO: Improve on this:
        if Device.s.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + DispatchTimeInterval.seconds(10)) {
                Device.updateDevices(nil)
            }
        }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusItemButton = statusItem.button {
            statusItemButton.image = NSImage(named: "StatusBarIcon")
            // Set target and action for left click (default click)
            statusItemButton.target = self
            statusItemButton.action = #selector(menuButtonToggle)
            statusItemButton.sendAction(on: [.leftMouseUp, .rightMouseUp]) // register action on right click too
        }
        
        popOver = NSPopover()
        popOver.behavior = .transient
        popOver.contentViewController = NSHostingController(rootView: MainView.MAIN_VIEW)
    }
    @objc func menuButtonToggle(sender: AnyObject){
        if let event = NSApp.currentEvent {
            if event.type == NSEvent.EventType.rightMouseUp {
            // Right button click
                Device.updateDevices(nil)
            } else {
            // Left button click
                if let button = statusItem.button {
                    if popOver.isShown {
                        popOver.performClose(nil)
                    } else {
                        popOver.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                    }
                }
           }
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    private func isProcessTrusted() -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let opts = [promptKey: true] as CFDictionary
        return AXIsProcessTrustedWithOptions(opts)
    }
}



