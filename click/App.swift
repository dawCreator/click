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
    private var accessibilityPollingTimer: Timer?
    private var isMonitoring = false
    
    // Logger instance for structured logging
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AppDelegate")

    func applicationDidFinishLaunching(_ notification: Notification) {
        logger.info("Application did finish launching")

        // macOS presents the accessibility prompt asynchronously. Keep the app
        // alive while the user grants access, then start monitoring automatically.
        _ = isProcessTrusted()

        // Register for automatic login
        registerForLaunchAtLogin()
        
        // Set up the status item (menu bar icon)
        initializeStatusItem()

        // Set the app's activation policy to accessory (no dock icon)
        NSApplication.shared.setActivationPolicy(.accessory)
        logger.info("Set application activation policy to accessory")

        // Wait for accessibility permission before starting device monitoring.
        accessibilityPollingTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.startMonitoringWhenTrusted()
        }
        startMonitoringWhenTrusted()
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

    // Method to initialize the status item
    private func initializeStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let statusItemButton = statusItem.button {
            let image = NSImage(named: "MagicMouseIcon")
            image?.size = CGSize(width: 18, height: 18)
            statusItemButton.image = image
            statusItemButton.target = self
            statusItemButton.action = #selector(menuButtonToggle)
            statusItemButton.sendAction(on: [.leftMouseUp, .rightMouseUp])
            logger.info("Status item initialized with button actions")
        } else {
            logger.error("Failed to create status item button")
        }

        popOver = NSPopover()
        popOver.contentViewController = NSHostingController(rootView: MainView.MAIN_VIEW)
        popOver.behavior = .transient
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
    
    // Request accessibility access and optionally show the macOS prompt.
    private func isProcessTrusted() -> Bool {
        let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options = [promptKey: true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        if trusted {
            logger.info("Application is trusted for accessibility permissions")
        } else {
            logger.info("Waiting for accessibility permission")
        }
        return trusted
    }

    private func startMonitoringWhenTrusted() {
        guard !isMonitoring, AXIsProcessTrusted() else { return }

        guard GestureRecognizer.SINGLETON.setupEventTap() else {
            logger.error("Could not start monitoring because the mouse event tap failed")
            return
        }

        Device.startMonitoringDevices()
        isMonitoring = true
        accessibilityPollingTimer?.invalidate()
        accessibilityPollingTimer = nil
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
}
