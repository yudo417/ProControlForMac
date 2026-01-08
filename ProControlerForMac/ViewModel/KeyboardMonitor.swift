//
//  KeyboardMonitor.swift
//  ProControlerForMac
//
//  複数のショートカットを監視
//

import Foundation
import AppKit
import Combine

/// キーボード監視クラス（複数ショートカット対応）
class KeyboardMonitor: ObservableObject {
    
    // MARK: - Published Properties
    
    /// 検出されたボタン（nilの場合は未検出）
    @Published var detectedButton: ControllerButton? = nil
    
    /// 現在のショートカット設定一覧
    @Published var bindings: [ShortcutBinding] = [] {
        didSet {
            ShortcutStorage.saveBindings(bindings)
        }
    }
    
    // MARK: - Private Properties
    
    /// イベントタップ
    private var eventTap: CFMachPort?
    
    /// RunLoopソース
    private var runLoopSource: CFRunLoopSource?
    
    // MARK: - Initialization
    
    init() {
        loadBindings()
        setupEventTap()
        print("⌨️ KeyboardMonitor初期化完了")
    }
    
    // MARK: - Event Tap Setup
    
    /// イベントタップを設定
    private func setupEventTap() {
        // アクセシビリティ権限をチェック
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as String: false]
        guard AXIsProcessTrustedWithOptions(options as CFDictionary) else {
            print("⚠️ アクセシビリティ権限が必要です")
            return
        }
        
        // イベントマスク（keyDownイベントを監視）
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        
        // コールバック関数をクロージャとして定義
        let callback: CGEventTapCallBack = { proxy, type, event, refcon in
            // refconからselfを取得
            let monitor = Unmanaged<KeyboardMonitor>.fromOpaque(refcon!).takeUnretainedValue()
            return monitor.handleKeyEvent(proxy: proxy, type: type, event: event)
        }
        
        // selfへのポインタ
        let selfPointer = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        
        // イベントタップを作成
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: selfPointer
        ) else {
            print("❌ イベントタップの作成に失敗")
            return
        }
        
        eventTap = tap
        
        // RunLoopソースを作成して追加
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        
        // イベントタップを有効化
        CGEvent.tapEnable(tap: tap, enable: true)
        
        print("✅ キーボード監視開始")
    }
    
    /// キーイベントを処理
    private func handleKeyEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        // イベントが無効化された場合は再度有効化
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap = eventTap {
                CGEvent.tapEnable(tap: tap, enable: true)
            }
            return Unmanaged.passUnretained(event)
        }
        
        // キーコードを取得
        let keyCode = UInt16(event.getIntegerValueField(.keyboardEventKeycode))
        
        // 修飾キーを取得
        let flags = event.flags
        let modifiers = NSEvent.ModifierFlags(rawValue: UInt(flags.rawValue))
        
        // すべてのショートカット設定をチェック
        for binding in bindings where binding.isEnabled {
            if isMatch(keyCode: keyCode, modifiers: modifiers, binding: binding) {
                // 一致したボタンを通知
                DispatchQueue.main.async { [weak self] in
                    print("🔥 ショートカット検出: \(binding.button.displayName) (\(binding.displayString))")
                    self?.detectedButton = binding.button
                    
                    // 0.3秒後にリセット
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        self?.detectedButton = nil
                    }
                }
                
                // イベントを消費（他のアプリに渡さない）
                return nil
            }
        }
        
        // 一致しない場合はイベントを通過させる
        return Unmanaged.passUnretained(event)
    }
    
    /// キーとショートカット設定が一致するか判定
    private func isMatch(keyCode: UInt16, modifiers: NSEvent.ModifierFlags, binding: ShortcutBinding) -> Bool {
        // キーコードが一致しない場合
        if keyCode != binding.keyCode {
            return false
        }
        
        // 修飾キーのチェック
        if let bindingMods = binding.modifierFlags {
            // 重要な修飾キーのみを比較
            let relevantMods: NSEvent.ModifierFlags = [.command, .option, .control, .shift]
            let currentRelevantMods = modifiers.intersection(relevantMods)
            let bindingRelevantMods = bindingMods.intersection(relevantMods)
            
            return currentRelevantMods == bindingRelevantMods
        } else {
            // 修飾キーが設定されていない = 修飾キーなしで押されたかチェック
            let noModifiers = !modifiers.contains(.command) &&
                              !modifiers.contains(.option) &&
                              !modifiers.contains(.control) &&
                              !modifiers.contains(.shift)
            return noModifiers
        }
    }
    
    // MARK: - Public Methods
    
    /// ショートカットを登録
    func registerShortcut(button: ControllerButton, keyCode: UInt16, modifiers: NSEvent.ModifierFlags? = nil, description: String? = nil) {
        let binding = ShortcutBinding(
            button: button,
            keyCode: keyCode,
            modifiers: modifiers,
            description: description
        )
        
        // 既存の設定を削除
        bindings.removeAll { $0.button == button }
        
        // 新しい設定を追加
        bindings.append(binding)
        
        print("✅ ショートカット登録: \(button.displayName) → \(binding.displayString)")
    }
    
    /// ショートカットを削除
    func removeShortcut(for button: ControllerButton) {
        bindings.removeAll { $0.button == button }
        print("🗑️ ショートカット削除: \(button.displayName)")
    }
    
    /// 特定のボタンのショートカットを取得
    func binding(for button: ControllerButton) -> ShortcutBinding? {
        return bindings.first { $0.button == button }
    }
    
    /// すべてのショートカットをクリア
    func clearAll() {
        bindings.removeAll()
        ShortcutStorage.clearAll()
        print("🗑️ すべてのショートカットをクリア")
    }
    
    // MARK: - Persistence
    
    /// 設定を読み込み
    private func loadBindings() {
        bindings = ShortcutStorage.loadBindings()
        print("📂 \(bindings.count)個のショートカットを読み込み")
    }
    
    // MARK: - Cleanup
    
    deinit {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
        }
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
        }
        print("👋 KeyboardMonitor解放")
    }
}
