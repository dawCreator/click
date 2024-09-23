//
//  clickApp.swift
//  click
//
//  Created by Lukas Schmale on 12.06.24.
//

import SwiftUI
import AppKit
import ServiceManagement
import os.log


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
    
    // Logger instance for structured logging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AppDelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application did finish launching")

        guard isProcessTrusted() else {
            logger.error("Accessibility permissions are not granted. Exiting application.")
            exit(1)
        }

        // Register for automatic login
        registerForLaunchAtLogin()
        
        // Set up the status item (menu bar icon)
        initializeStatusItem()

        // Set the app's activation policy to accessory (no dock icon)
        NSApplication.shared.setActivationPolicy(.accessory)
        logger.info("Set application activation policy to accessory")

        // Start monitoring devices and gesture recognizer
        Device.startMonitoringDevices()
        GestureRecognizer.SINGLETON.setupEventTap()
        logger.info("Started monitoring devices and gesture recognizer")

        // Ensure devices are updated if initially empty
        if Device.s.isEmpty {
            logger.warning("Device list is empty. Scheduling device update in 10 seconds.")
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) {
                Device.updateDevices(nil)
                self.logger.info("Device update triggered")
            }
        }
    }

    // Method to register for automatic launch at login
    private func registerForLaunchAtLogin() {
        do {
            try SMAppService.mainApp.register()
            logger.info("Successfully registered app for automatic launch at login")
        } catch {
            logger.error("Failed to register app for automatic launch: \(error.localizedDescription)")
        }
    }

    // Method to initialize the status item (menu bar icon)
    private func initializeStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let statusItemButton = statusItem.button {
            statusItemButton.image = NSImage(named: "StatusBarIcon") // Set your icon name here
            statusItemButton.target = self
            statusItemButton.action = #selector(menuButtonToggle)
            statusItemButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
            logger.info("Status item initialized with button actions")
        } else {
            logger.error("Failed to create status item button")
        }

        popOver = NSPopover()
        popOver.behavior = .transient
        popOver.contentViewController = NSHostingController(rootView: MainView.MAIN_VIEW)
        logger.info("Popover initialized with main view")
    }
    
    // Action handler for status item clicks
    @objc func menuButtonToggle(sender: AnyObject) {
        if let event = NSApp.currentEvent {
            if event.type == NSEvent.EventType.rightMouseUp {
                // Right-click action: update devices
                logger.info("Right mouse button clicked on status item. Updating devices.")
                Device.updateDevices(nil)
            } else {
                // Left-click action: toggle popover
                logger.info("Left mouse button clicked on status item. Toggling popover.")
                togglePopover()
            }
        }
    }
    
    // Toggle the popover display
    private func togglePopover() {
        if let button = statusItem.button {
            if popOver.isShown {
                popOver.performClose(nil)
                logger.info("Popover closed")
            } else {
                popOver.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
                logger.info("Popover shown")
            }
        }
    }
    
    // Check if the application should terminate when no windows are open
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
    
    // Check if the application has accessibility permissions
    private func isProcessTrusted() -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if trusted {
            logger.info("Application is trusted for accessibility permissions")
        } else {
            logger.error("Application is not trusted for accessibility permissions")
        }
        return trusted
    }
}
