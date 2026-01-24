
import SwiftUI

struct DetailView: View {
    @ObservedObject var profileViewModel: ControllerProfileViewModel
    @ObservedObject var buttonDetector: ButtonDetector

    var body: some View {
        Group {
            switch profileViewModel.detailSelection {
            case .button(let buttonConfigId):
                if let buttonConfig = profileViewModel.selectedButtonConfig,
                   buttonConfig.id == buttonConfigId,
                   let controllerId = profileViewModel.selectedControllerId,
                   let profileId = profileViewModel.selectedProfileId {
                    ButtonConfigDetailView(
                        buttonConfig: buttonConfig,
                        controllerId: controllerId,
                        profileId: profileId,
                        profileViewModel: profileViewModel,
                        buttonDetector: buttonDetector
                    )
                    .id("\(buttonConfigId)-\(profileViewModel.selectedLayerIndex)")
                } else {
                    placeholderView
                }
                
            case .leftStick:
                if let controllerId = profileViewModel.selectedControllerId,
                   let profileId = profileViewModel.selectedProfileId {
                    StickSensitivityDetailView(
                        isLeftStick: true,
                        controllerId: controllerId,
                        profileId: profileId,
                        profileViewModel: profileViewModel
                    )
                    .id("leftStick-\(profileViewModel.selectedLayerIndex)")
                } else {
                    placeholderView
                }
                
            case .rightStick:
                if let controllerId = profileViewModel.selectedControllerId,
                   let profileId = profileViewModel.selectedProfileId {
                    StickSensitivityDetailView(
                        isLeftStick: false,
                        controllerId: controllerId,
                        profileId: profileId,
                        profileViewModel: profileViewModel
                    )
                    .id("rightStick-\(profileViewModel.selectedLayerIndex)")
                } else {
                    placeholderView
                }
                
            case .none:
                placeholderView
            }
        }
    }
    
    private var placeholderView: some View {
        VStack(spacing: 24) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("ボタンを選択")
                .font(.title2)
                .fontWeight(.semibold)

            Text("中央のリストから\nボタンまたはスティックを選択して設定してください")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    // 新機能: アクションタイプとターゲットレイヤー
    @State private var actionType: ButtonActionType = .keyInput
    @State private var targetLayerId: UUID?
    
    // 保存成功のフィードバック
    @State private var showingSaveAlert = false
    
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
                    Text("左クリック").tag(ButtonActionType.leftClick)
                    Text("右クリック").tag(ButtonActionType.rightClick)
                    Text("レイヤー切り替え").tag(ButtonActionType.layerShift)
                }
            }
            
            switch actionType {
            case .keyInput:
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
                
            case .leftClick:
                // 左クリック設定
                Section("左クリック") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("マウスの左ボタンとして動作します", systemImage: "cursorarrow.click")
                        Label("ボタンを押している間クリック状態が維持されます", systemImage: "hand.tap")
                        Label("ドラッグ操作にも対応", systemImage: "arrow.up.left.and.arrow.down.right")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                
            case .rightClick:
                // 右クリック設定
                Section("右クリック") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("マウスの右ボタンとして動作します", systemImage: "cursorarrow.click.2")
                        Label("コンテキストメニューの表示などに使用", systemImage: "contextualmenu.and.cursorarrow")
                        Label("ボタンを押している間クリック状態が維持されます", systemImage: "hand.tap")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                
            case .layerShift:
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
                    // キー入力モードならキー必須、レイヤーモードならレイヤー必須、クリックは常にOK
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
        .onChange(of: buttonConfig.id) { _ in
            // ボタンが変わったら設定を再読み込み
            loadConfiguration()
        }
        .onChange(of: profileViewModel.selectedLayerIndex) { _ in
            // レイヤーが変わったら設定を再読み込み
            loadConfiguration()
        }
        .alert("保存完了", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("設定を保存しました")
        }
    }

    private func loadConfiguration() {
        actionType = buttonConfig.actionType
        targetLayerId = buttonConfig.targetLayerId
        
        selectedKeyCode = buttonConfig.keyCode

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
        // マウスクリックモードは追加条件なし
        
        var modifiers = NSEvent.ModifierFlags()
        if useControl { modifiers.insert(.control) }
        if useOption { modifiers.insert(.option) }
        if useShift { modifiers.insert(.shift) }
        if useCommand { modifiers.insert(.command) }
        
        let finalModifiers = modifiers.isEmpty ? nil : modifiers
        let currentLayerIndex = profileViewModel.selectedLayerIndex
        
        // 修飾キーを全てオフにする場合（nilに設定する場合）は、shouldUpdateModifierFlagsをtrueにする
        let shouldUpdateModifierFlags = (actionType == .keyInput || actionType == .leftClick || actionType == .rightClick) && modifiers.isEmpty
        
        profileViewModel.updateButtonConfig(
            controllerId: controllerId,
            profileId: profileId,
            layerIndex: currentLayerIndex,
            buttonConfigId: buttonConfig.id,
            actionType: actionType,
            keyCode: actionType == .keyInput ? selectedKeyCode : nil,
            modifierFlags: (actionType == .keyInput || actionType == .leftClick || actionType == .rightClick) ? finalModifiers : nil,
            targetLayerId: actionType == .layerShift ? targetLayerId : nil,
            shouldUpdateModifierFlags: shouldUpdateModifierFlags
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
        
        // 保存成功のフィードバック
        showingSaveAlert = true
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
        
        profileViewModel.updateButtonConfig(
            controllerId: controllerId,
            profileId: profileId,
            layerIndex: currentLayerIndex,
            buttonConfigId: buttonConfig.id,
            actionType: .keyInput,
            keyCode: nil,
            modifierFlags: nil,
            targetLayerId: nil
        )
    }
}

// MARK: - Stick Sensitivity Detail View

struct StickSensitivityDetailView: View {
    let isLeftStick: Bool
    let controllerId: UUID
    let profileId: UUID
    @ObservedObject var profileViewModel: ControllerProfileViewModel
    
    @State private var sensitivity: Double = 10.0
    @State private var showingSaveAlert = false
    
    private var stickName: String {
        isLeftStick ? "左スティック" : "右スティック"
    }
    
    private var stickDescription: String {
        isLeftStick ? "マウスカーソルの移動速度を調整します" : "スクロールの速度を調整します"
    }
    
    private var stickIcon: String {
        isLeftStick ? "l.joystick" : "r.joystick"
    }
    
    var body: some View {
        Form {
            // ヘッダー
            Section {
                VStack(spacing: 12) {
                    Image(systemName: stickIcon)
                        .font(.system(size: 50))
                        .foregroundColor(.accentColor)
                    
                    Text(stickName)
                        .font(.title)
                        .fontWeight(.semibold)
                    
                    Text(stickDescription)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            // 感度設定
            Section("感度設定") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("感度")
                            .font(.headline)
                        Spacer()
                        Text(String(format: "%.1f", sensitivity))
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.accentColor)
                    }
                    
                    Slider(value: $sensitivity, in: 1.0...100.0, step: 1) {
                        Text("感度")
                    } minimumValueLabel: {
                        Text("1")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("100")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("低い")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("高い")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            
            // 説明
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    if isLeftStick {
                        Label("値が大きいほどカーソルが速く動きます", systemImage: "info.circle")
                        Label("細かい操作には低めの値がおすすめ", systemImage: "hand.point.up.left")
                    } else {
                        Label("値が大きいほどスクロールが速くなります", systemImage: "info.circle")
                        Label("Webブラウジングには10〜15程度がおすすめ", systemImage: "safari")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            // 保存ボタン
            Section {
                Button("設定を保存") {
                    saveConfiguration()
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
            }
        }
        .formStyle(.grouped)
        .navigationTitle(stickName)
        .onAppear {
            loadConfiguration()
        }
        .onChange(of: profileViewModel.selectedLayerIndex) { _ in
            // レイヤーが変わったら感度設定を再読み込み
            loadConfiguration()
        }
        .alert("保存完了", isPresented: $showingSaveAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("感度設定を保存しました")
        }
    }
    
    private func loadConfiguration() {
        sensitivity = profileViewModel.currentStickSensitivity(isLeftStick: isLeftStick)
    }
    
    private func saveConfiguration() {
        let currentLayerIndex = profileViewModel.selectedLayerIndex
        profileViewModel.updateStickSensitivity(
            controllerId: controllerId,
            profileId: profileId,
            layerIndex: currentLayerIndex,
            isLeftStick: isLeftStick,
            sensitivity: sensitivity
        )
        
        // 保存成功のフィードバック
        showingSaveAlert = true
    }
}
