//
//  AppDelegate.swift
//  click
//
//  Created by Lukas Schmale on 13.06.24.
//
import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    var window: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up the menu bar
        menuBarController = MenuBarController()
        setupWindow()
        Device.startMonitoringDevices()
    }

    func setupWindow() {
        let contentView = NSHostingView(rootView: ContentView())

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false)
        window?.center()
        window?.setFrameAutosaveName("Main Window")
        window?.contentView = contentView
        menuBarController?.window = window
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}



class MenuBarController: NSObject, NSMenuDelegate {
    var statusItem: NSStatusItem?
    var window: NSWindow?
    
    override init() {
        super.init()
        setupMenuBar()
    }

    private func setupMenuBar() {
        // Create the status item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "applelogo", accessibilityDescription: "App Menu")
            button.target = self
            button.action = #selector(toggleWindow)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        // Create the context menu
        let menu = NSMenu()
        menu.delegate = self
        menu.addItem(NSMenuItem(title: "Open App", action: #selector(openApp), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))

        statusItem?.menu = menu
    }

    @objc private func toggleWindow() {
        if let window = window {
            if window.isVisible {
                window.orderOut(nil)
            } else {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    @objc private func openApp() {
        if let window = window {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    // Show the menu on right-click
    func menuNeedsUpdate(_ menu: NSMenu) {
        statusItem?.button?.highlight(false)
    }
}
