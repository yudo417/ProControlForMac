
import SwiftUI

struct DetailView: View {
    @ObservedObject var profileViewModel: ControllerProfileViewModel
    @ObservedObject var buttonDetector: ButtonDetector

    var selectedButtonConfig: ButtonConfig? {
        profileViewModel.selectedButtonConfig
    }

    var body: some View {
        Group {
            if let buttonConfig = selectedButtonConfig,
               let controllerId = profileViewModel.selectedControllerId,
               let profileId = profileViewModel.selectedProfileId {
                ButtonConfigDetailView(
                    buttonConfig: buttonConfig,
                    controllerId: controllerId,
                    profileId: profileId,
                    profileViewModel: profileViewModel,
                    buttonDetector: buttonDetector
                )
            } else {
                // ボタン未選択時のプレースホルダー
                VStack(spacing: 24) {
                    Image(systemName: "gamecontroller.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)

                    Text("ボタンを選択")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("中央のリストから\nボタンを選択して設定してください")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}

struct ButtonConfigDetailView: View {
    let buttonConfig: ButtonConfig
    let controllerId: UUID
    let profileId: UUID
    @ObservedObject var profileViewModel: ControllerProfileViewModel
    @ObservedObject var buttonDetector: ButtonDetector

    @State private var selectedKeyCode: UInt16?
    @State private var useControl = false
    @State private var useOption = false
    @State private var useShift = false
    @State private var useCommand = false
    @State private var isTurbo = false
    @State private var isLongPress = false
    @State private var longPressDuration = 0.5
    
    // 新機能: アクションタイプとターゲットレイヤー
    @State private var actionType: ButtonActionType = .keyInput
    @State private var targetLayerId: UUID?
    
    var body: some View {
        Form {
            // ヘッダー
            Section {
                VStack(spacing: 12) {
                    Text(buttonConfig.name)
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    if !buttonConfig.displayKey.isEmpty && buttonConfig.displayKey != "未設定" {
                        HStack(spacing: 4) {
                            Text("現在:")
                                .font(.callout)
                                .foregroundColor(.secondary)
                            
                            if actionType == .layerShift {
                                Text(buttonConfig.displayKey)
                                    .font(.headline)
                                    .foregroundColor(.purple)
                            } else {
                                Text(buttonConfig.displayKey)
                                    .font(.title3)
                                    .fontWeight(.medium)
                                    .foregroundColor(.accentColor)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            // 動作モード選択
            Section("動作モード") {
                Picker("種類", selection: $actionType) {
                    Text("キー入力").tag(ButtonActionType.keyInput)
                    Text("レイヤー切り替え").tag(ButtonActionType.layerShift)
                }
                .pickerStyle(.segmented)
            }
            
            if actionType == .keyInput {
                // キー設定
                Section("キー設定") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("キー")
                            .font(.headline)
                        
                        SimpleKeyInput(keyCode: $selectedKeyCode)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.vertical, 4)
                }
                
                // 修飾キー
                Section("修飾キー") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: $useControl) {
                            HStack {
                                Text("⌃")
                                    .font(.title2)
                                Text("Control")
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Toggle(isOn: $useOption) {
                            HStack {
                                Text("⌥")
                                    .font(.title2)
                                Text("Option")
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Toggle(isOn: $useShift) {
                            HStack {
                                Text("⇧")
                                    .font(.title2)
                                Text("Shift")
                            }
                        }
                        .toggleStyle(.switch)
                        
                        Toggle(isOn: $useCommand) {
                            HStack {
                                Text("⌘")
                                    .font(.title2)
                                Text("Command")
                            }
                        }
                        .toggleStyle(.switch)
                    }
                }
                
                // 連射設定
                Section("連射設定") {
                    Toggle(isOn: $isTurbo) {
                        Text("連射を有効にする")
                    }
                    .toggleStyle(.switch)
                }
                
                // 長押し設定
                Section("長押し設定") {
                    Toggle(isOn: $isLongPress) {
                        Text("長押しを有効にする")
                    }
                    .toggleStyle(.switch)
                    
                    if isLongPress {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("長押し判定時間: \(longPressDuration, specifier: "%.2f")秒")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $longPressDuration, in: 0.1...2.0, step: 0.1)
                        }
                        .padding(.top, 8)
                    }
                }
            } else {
                // レイヤー切り替え設定
                Section("切り替え先レイヤー") {
                    if let profile = profileViewModel.selectedProfile {
                        Picker("対象レイヤー", selection: $targetLayerId) {
                            Text("未設定").tag(nil as UUID?)
                            ForEach(profile.layers) { layer in
                                Text(layer.name).tag(layer.id as UUID?)
                            }
                        }
                        
                        Text("ボタンを押している間、選択したレイヤーの設定が有効になります。\n(離すと元のレイヤーに戻ります)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("プロファイル情報を取得できません")
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            // アクションボタン
            Section {
                HStack(spacing: 12) {
                    Button("設定を保存") {
                        saveConfiguration()
                    }
                    .buttonStyle(.borderedProminent)
                    // キー入力モードならキー必須、レイヤーモードならレイヤー必須
                    .disabled(actionType == .keyInput && selectedKeyCode == nil)
                    .disabled(actionType == .layerShift && targetLayerId == nil)
                    .frame(maxWidth: .infinity)
                    
                    Button("クリア") {
                        clearConfiguration()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle(buttonConfig.name)
        .onAppear {
            loadConfiguration()
        }
    }

    private func loadConfiguration() {
        actionType = buttonConfig.actionType
        targetLayerId = buttonConfig.targetLayerId
        
        selectedKeyCode = buttonConfig.keyCode
        isTurbo = buttonConfig.isTurbo
        isLongPress = buttonConfig.isLongPress
        longPressDuration = buttonConfig.longPressDuration

        if let mods = buttonConfig.modifierFlags {
            useControl = mods.contains(.control)
            useOption = mods.contains(.option)
            useShift = mods.contains(.shift)
            useCommand = mods.contains(.command)
        } else {
            useControl = false
            useOption = false
            useShift = false
            useCommand = false
        }
    }

    private func saveConfiguration() {
        // キー入力モードの場合、キーコード必須
        if actionType == .keyInput && selectedKeyCode == nil { return }
        // レイヤーモードの場合、ターゲットレイヤー必須
        if actionType == .layerShift && targetLayerId == nil { return }
        
        var modifiers = NSEvent.ModifierFlags()
        if useControl { modifiers.insert(.control) }
        if useOption { modifiers.insert(.option) }
        if useShift { modifiers.insert(.shift) }
        if useCommand { modifiers.insert(.command) }
        
        let finalModifiers = modifiers.isEmpty ? nil : modifiers
        let currentLayerIndex = profileViewModel.selectedLayerIndex
        
        profileViewModel.updateButtonConfig(
            controllerId: controllerId,
            profileId: profileId,
            layerIndex: currentLayerIndex,
            buttonConfigId: buttonConfig.id,
            actionType: actionType,
            keyCode: actionType == .keyInput ? selectedKeyCode : nil, // レイヤーモードならキーコードはクリア
            modifierFlags: actionType == .keyInput ? finalModifiers : nil,
            isTurbo: actionType == .keyInput ? isTurbo : false,
            isLongPress: actionType == .keyInput ? isLongPress : false,
            longPressDuration: longPressDuration,
            targetLayerId: actionType == .layerShift ? targetLayerId : nil
        )
        
        // ButtonDetectorにもショートカットを登録（キー入力モードの場合のみ）
        if actionType == .keyInput, let detectedButtonId = buttonConfig.detectedButtonId, let code = selectedKeyCode {
            buttonDetector.registerShortcut(
                buttonId: detectedButtonId,
                keyCode: code,
                modifiers: finalModifiers
            )
        } else if let detectedButtonId = buttonConfig.detectedButtonId {
            // レイヤーモードまたは未設定の場合はショートカット登録を解除
            buttonDetector.removeShortcut(buttonId: detectedButtonId)
        }
    }
    
    private func clearConfiguration() {
        let currentLayerIndex = profileViewModel.selectedLayerIndex
        
        actionType = .keyInput
        targetLayerId = nil
        selectedKeyCode = nil
        useControl = false
        useOption = false
        useShift = false
        useCommand = false
        isTurbo = false
        isLongPress = false
        longPressDuration = 0.5
        
        profileViewModel.updateButtonConfig(
            controllerId: controllerId,
            profileId: profileId,
            layerIndex: currentLayerIndex,
            buttonConfigId: buttonConfig.id,
            actionType: .keyInput,
            keyCode: nil,
            modifierFlags: nil,
            isTurbo: false,
            isLongPress: false,
            longPressDuration: 0.5,
            targetLayerId: nil
        )
    }
}
