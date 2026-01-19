//
//  KeyCodeConverter.swift
//  ProControlerForMac
//
//  キーコードと修飾キーを人間が読める文字列に変換
//

import Foundation
import AppKit

/// キーコードと修飾キーの変換ユーティリティ
struct KeyCodeConverter {
    
    /// キーコードを文字列に変換
    static func keyCodeToString(_ keyCode: UInt16) -> String {
        let keyCodeMap: [UInt16: String] = [
            // アルファベット
            0: "A", 1: "S", 2: "D", 3: "F", 4: "H", 5: "G", 6: "Z", 7: "X", 8: "C", 9: "V",
            11: "B", 12: "Q", 13: "W", 14: "E", 15: "R", 16: "Y", 17: "T",
            31: "O", 32: "U", 34: "I", 35: "P", 37: "L", 38: "J", 40: "K",
            45: "N", 46: "M",
            
            // 数字
            18: "1", 19: "2", 20: "3", 21: "4", 22: "6", 23: "5", 25: "9", 26: "7",
            28: "8", 29: "0",
            
            // 記号
            24: "=", 27: "-", 30: "]", 33: "[",
            39: "'", 41: ";", 42: "\\", 43: ",", 44: "/", 47: ".",
            50: "`",
            
            // 特殊キー
            36: "Return", 48: "Tab", 49: "Space", 51: "Delete", 53: "Escape",
            
            // 矢印キー
            123: "←", 124: "→", 125: "↓", 126: "↑",
            
            // ファンクションキー
            122: "F1", 120: "F2", 99: "F3", 118: "F4", 96: "F5", 97: "F6",
            98: "F7", 100: "F8", 101: "F9", 109: "F10", 103: "F11", 111: "F12",
            
            // その他
            71: "Clear", 76: "Enter",
            115: "Home", 116: "Page Up", 117: "Forward Delete",
            119: "End", 121: "Page Down"
        ]
        
        return keyCodeMap[keyCode] ?? "Key(\(keyCode))"
    }
    
    /// 修飾キーを文字列に変換
    /// - Parameter modifiers: 修飾キー
    /// - Returns: 人間が読める文字列（例: "⌘⇧"）
    static func modifiersToString(_ modifiers: NSEvent.ModifierFlags) -> String {
        var result: [String] = []
        
        if modifiers.contains(.control) {
            result.append("⌃")
        }
        if modifiers.contains(.option) {
            result.append("⌥")
        }
        if modifiers.contains(.shift) {
            result.append("⇧")
        }
        if modifiers.contains(.command) {
            result.append("⌘")
        }
        
        return result.joined()
    }
    
    /// キーコードと修飾キーを組み合わせた文字列
    /// - Parameters:
    ///   - keyCode: キーコード
    ///   - modifiers: 修飾キー（オプション）
    /// - Returns: 人間が読める文字列（例: "⌘K" or "K"）
    static func shortcutString(keyCode: UInt16, modifiers: NSEvent.ModifierFlags?) -> String {
        let keyName = keyCodeToString(keyCode)
        
        guard let mods = modifiers else {
            return keyName
        }
        
        let modString = modifiersToString(mods)
        return modString.isEmpty ? keyName : "\(modString)\(keyName)"
    }
}



