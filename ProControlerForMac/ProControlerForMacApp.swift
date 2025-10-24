
import SwiftUI
import AppKit

@main
struct ProControlerForMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var controllerHandler = ControllerMonitor()
    
    init() {
        requestAccessibilityPermission()
    }
    
    var body: some Scene {
        WindowGroup{
            ContentView()
                .environmentObject(controllerHandler)
        }

        Settings{
            ContentView()
                .environmentObject(controllerHandler)
        }
    }
    
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if !trusted {
            print("⚠️ アクセシビリティ権限が必要です")
            print("System Preferences > Security & Privacy > Accessibility から許可してください")
        } else {
            print("✅ アクセシビリティ権限: OK")
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "gamecontroller.fill", accessibilityDescription: "controller")

            button.sendAction(on: [.leftMouseUp,.rightMouseUp])
            button.action = #selector(menuBarClicked)
        }

    }

    func applicationWillTerminate(_ notification: Notification) {

    }

    @objc func menuBarClicked() {
        guard let event = NSApp.currentEvent else {return}
        if  event.type == .rightMouseUp {
            print("rightClicked")
            rightMenuClicked()
        }else if event.type == .leftMouseUp{
            print("leftClicked")
        }
    }

    @objc func rightMenuClicked() {
        let menu = NSMenu()

        menu.addItem(
            withTitle: "構成",
            action: #selector(kousei),
            keyEquivalent: ","
        )

        statusItem?.popUpMenu(menu)
    }

    @objc func kousei(){
        print("a")
    }

    @objc func leftMenuClicked() {

    }
}
