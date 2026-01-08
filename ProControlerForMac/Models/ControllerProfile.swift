
// コントローラー1個あたりの設定項目や持つ情報
//  コントローラー、プロファイル、ボタン設定の階層構造モデル

import Foundation
import SwiftUI

// MARK: - Controller (Device)

/// 物理的なコントローラーデバイス
struct Controller: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var isConnected: Bool
    var isExpanded: Bool // UI用：セクションの開閉状態
    var profiles: [Profile]
    
    init(id: UUID = UUID(), name: String, isConnected: Bool = false, isExpanded: Bool = true, profiles: [Profile] = []) {
        self.id = id
        self.name = name
        self.isConnected = isConnected
        self.isExpanded = isExpanded
        self.profiles = profiles
    }
    
    enum CodingKeys: String, CodingKey {
        case id, name, isConnected, isExpanded, profiles
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        isConnected = try container.decode(Bool.self, forKey: .isConnected)
        isExpanded = try container.decodeIfPresent(Bool.self, forKey: .isExpanded) ?? true
        profiles = try container.decode([Profile].self, forKey: .profiles)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(isConnected, forKey: .isConnected)
        try container.encode(isExpanded, forKey: .isExpanded)
        try container.encode(profiles, forKey: .profiles)
    }
}

// MARK: - Profile (Usage)

/// 用途別の設定セット（プロファイル）
struct Profile: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var icon: String  // SF Symbols名
    var layers: [Layer]
    
    init(id: UUID = UUID(), name: String, icon: String = "folder.fill", layers: [Layer] = []) {
        self.id = id
        self.name = name
        self.icon = icon
        // レイヤーがない場合はデフォルトレイヤーを作成
        if layers.isEmpty {
            self.layers = [Layer(name: "Default", triggerButtonId: nil)]
        } else {
            self.layers = layers
        }
    }
    
    // MARK: - Migration Support
    // buttonConfigsを持っている古いデータからの移行用
    enum CodingKeys: String, CodingKey {
        case id, name, icon, layers, buttonConfigs
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        icon = try container.decode(String.self, forKey: .icon)
        
        // layersがあればそのまま、なければbuttonConfigsから移行
        if let existingLayers = try? container.decode([Layer].self, forKey: .layers) {
            layers = existingLayers
        } else if let configs = try? container.decode([ButtonConfig].self, forKey: .buttonConfigs) {
            // 古いデータをDefaultレイヤーに移行
            let defaultLayer = Layer(name: "Default", triggerButtonId: nil, buttonConfigs: configs)
            layers = [defaultLayer]
        } else {
            // どちらもない場合（新規など）
            layers = [Layer(name: "Default", triggerButtonId: nil)]
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(icon, forKey: .icon)
        try container.encode(layers, forKey: .layers)
    }
    
    // 後方互換性などのためのヘルパー: 現在のデフォルトレイヤーのボタン設定を返す
    var buttonConfigs: [ButtonConfig] {
        get { layers.first?.buttonConfigs ?? [] }
        set {
            if !layers.isEmpty {
                layers[0].buttonConfigs = newValue
            } else {
                layers = [Layer(name: "Default", buttonConfigs: newValue)]
            }
        }
    }
}

// MARK: - Layer (Mode)

/// 設定レイヤー（モード）
struct Layer: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String // "Default", "Shift (ZR)" など
    var triggerButtonId: String? // nil = 常時（ベース）, "button_ZR" = 押下時のみ（シフト）
    var buttonConfigs: [ButtonConfig]
    var leftStickSensitivity: Double // マウス感度
    var rightStickSensitivity: Double // スクロール感度
    
    init(
        id: UUID = UUID(),
        name: String,
        triggerButtonId: String? = nil,
        buttonConfigs: [ButtonConfig] = [],
        leftStickSensitivity: Double = 10.0,
        rightStickSensitivity: Double = 10.0
    ) {
        self.id = id
        self.name = name
        self.triggerButtonId = triggerButtonId
        self.buttonConfigs = buttonConfigs
        self.leftStickSensitivity = leftStickSensitivity
        self.rightStickSensitivity = rightStickSensitivity
    }
}


// MARK: - ButtonConfig (Item)

enum ButtonActionType: String, Codable, Hashable {
    case keyInput = "キー入力"
    case layerShift = "レイヤー切り替え"
    // 将来的にマウス操作なども追加可能
}

/// 個々のボタン設定（中段でボタンのList）
struct ButtonConfig: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    
    // アクションタイプ
    var actionType: ButtonActionType
    
    // Type: キー入力
    var assignedKey: String?  // 割り当てられたキー（例: "Space", "⌘K"）
    var keyCode: UInt16?  // キーコード
    var modifierFlagsRawValue: UInt?  // 修飾キーのrawValue（Codable用）
    
    /// 修飾キー（NSEvent.ModifierFlags）
    var modifierFlags: NSEvent.ModifierFlags? {
        get {
            guard let rawValue = modifierFlagsRawValue else { return nil }
            return NSEvent.ModifierFlags(rawValue: rawValue)
        }
        set {
            modifierFlagsRawValue = newValue?.rawValue
        }
    }
    var isTurbo: Bool  // 連射設定
    var isLongPress: Bool  // 長押し設定
    var longPressDuration: Double  // 長押し判定時間（秒）
    
    // Type: レイヤー切り替え
    var targetLayerId: UUID? // 切り替え先のレイヤーID
    
    // 元のDetectedButtonへの参照（オプション）
    var detectedButtonId: String?
    
    init(
        id: UUID = UUID(),
        name: String,
        actionType: ButtonActionType = .keyInput,
        assignedKey: String? = nil,
        keyCode: UInt16? = nil,
        modifierFlags: NSEvent.ModifierFlags? = nil,
        isTurbo: Bool = false,
        isLongPress: Bool = false,
        longPressDuration: Double = 0.5,
        targetLayerId: UUID? = nil,
        detectedButtonId: String? = nil
    ) {
        self.id = id
        self.name = name
        self.actionType = actionType
        self.assignedKey = assignedKey
        self.keyCode = keyCode
        self.modifierFlagsRawValue = modifierFlags?.rawValue
        self.isTurbo = isTurbo
        self.isLongPress = isLongPress
        self.longPressDuration = longPressDuration
        self.targetLayerId = targetLayerId
        self.detectedButtonId = detectedButtonId
    }
    
    /// 表示用のキー割り当て文字列
    var displayKey: String {
        switch actionType {
        case .keyInput:
            if let assignedKey = assignedKey {
                return assignedKey
            }
            if let keyCode = keyCode {
                let keyName = KeyCodeConverter.keyCodeToString(keyCode)
                if let mods = modifierFlags {
                    let modString = KeyCodeConverter.modifiersToString(mods)
                    return modString.isEmpty ? keyName : "\(modString) + \(keyName)"
                }
                return keyName
            }
            return "未設定"
            
        case .layerShift:
            return "レイヤー切り替え"
        }
    }
}

// MARK: - Codable Support for NSEvent.ModifierFlags

extension NSEvent.ModifierFlags {
    /// Codable用のヘルパー
    var codableRawValue: UInt {
        return rawValue
    }
    
    init(codableRawValue: UInt) {
        self.init(rawValue: codableRawValue)
    }
}

