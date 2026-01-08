
import SwiftUI
import AppKit
import GameController

@main
struct ProControlerForMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var controllerHandler = ControllerMonitor()
    
    init() {
        GCController.shouldMonitorBackgroundEvents = true
        requestAccessibilityPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controllerHandler)
//            test()
        }
        Settings {
            ContentView()
                .environmentObject(controllerHandler)
        }

    }
    
    func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: true]
        _ = AXIsProcessTrustedWithOptions(options as CFDictionary)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // ステータスバーアイテムを作成
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        guard let button = statusItem?.button else { return }
        
        // アイコン画像の設定
        if let image = NSImage(systemSymbolName: "gamecontroller.fill", accessibilityDescription: "ProController") {
            image.isTemplate = true
            button.image = image
        } else {
            button.title = "🎮"
        }

        // クリックイベントの設定
        button.action = #selector(menuBarClicked)
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }

    func applicationWillTerminate(_ notification: Notification) {

    }
    
    @objc func menuBarClicked() {
        guard let event = NSApp.currentEvent else { return }
        
        if event.type == .rightMouseUp {
            rightMenuClicked()
        } else if event.type == .leftMouseUp {
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    @objc func rightMenuClicked() {
        let menu = NSMenu()

        menu.addItem(
            withTitle: "構成",
            action: #selector(kousei),
            keyEquivalent: ","
        )
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(
            withTitle: "終了",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )

        statusItem?.popUpMenu(menu)
    }

    //MARK: MenubarMenu

    @objc func kousei(){
        // 設定画面を開く処理
        NSApp.activate(ignoringOtherApps: true)
        // SwiftUIのSettingsシーンを呼び出す
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}
