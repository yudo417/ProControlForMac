//
//  ThreeColumnContentView.swift
//  ProControlerForMac
//
//  3カラム構成のメインView（NavigationSplitView）
//

import SwiftUI
import GameController
import AppKit

struct ContentView: View {
    @EnvironmentObject var controllerMonitor: ControllerMonitor
    @StateObject private var buttonDetector = ButtonDetector()
    @StateObject private var profileViewModel = ControllerProfileViewModel()
    
    // ナビゲーション状態
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    @State private var hasInitializedButtons = false
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // 第1カラム: サイドバー（コントローラーとプロファイル選択）
            SidebarView(
                profileViewModel: profileViewModel
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 250, max: 300)
        } content: {
            // 第2カラム: コンテンツ（ボタン一覧）
            ContentListView(
                profileViewModel: profileViewModel,
                buttonDetector: buttonDetector
            )
            .navigationSplitViewColumnWidth(min: 250, ideal: 300, max: 400)
        } detail: {
            // 第3カラム: 詳細設定（ボタン詳細）
            DetailView(
                profileViewModel: profileViewModel,
                buttonDetector: buttonDetector
            )
        }
        .onAppear {
            // ControllerMonitorにProfileViewModelへの参照を設定（感度設定を使用するため）
            controllerMonitor.profileViewModel = profileViewModel
            
            // ButtonDetectorとProfileViewModelの連携（レイヤー切り替えなど）
            buttonDetector.onButtonEvent = { [weak profileViewModel] buttonId, isPressed in
                profileViewModel?.handleButtonEvent(buttonId: buttonId, isPressed: isPressed)
            }
            
            // 既存のButtonDetectorのボタンをデフォルトプロファイルに追加
            if !hasInitializedButtons {
                initializeButtonsFromDetector()
                hasInitializedButtons = true
            }
            
            // 初回ショートカット同期
            updateShortcuts()
        }
        .onChange(of: profileViewModel.selectedLayerIndex) { _ in
            updateShortcuts()
        }
    }
    
    /// 現在のレイヤー設定に基づいてButtonDetectorのショートカットを更新
    private func updateShortcuts() {
        guard let profile = profileViewModel.selectedProfile else { return }
        
        // 1. ベース設定（Defaultレイヤー）
        var configMap: [String: ButtonConfig] = [:]
        if let defaultLayer = profile.layers.first {
            for config in defaultLayer.buttonConfigs {
                if let id = config.detectedButtonId {
                    configMap[id] = config
                }
            }
        }
        
        // 2. 現在のレイヤーで上書き（レイヤー0以外の場合）
        let layerIndex = profileViewModel.selectedLayerIndex
        if layerIndex != 0 && layerIndex < profile.layers.count {
            let currentLayer = profile.layers[layerIndex]
            for config in currentLayer.buttonConfigs {
                if let id = config.detectedButtonId {
                    // 設定が存在すれば上書き（keyCodeがnilでも上書き＝無効化）
                    configMap[id] = config
                }
            }
        }
        
        // 3. 有効なショートカットを抽出して適用
        var shortcutsToRegister: [(String, UInt16, NSEvent.ModifierFlags?)] = []
        
        for (_, config) in configMap {
            // レイヤーシフトボタンではなく、かつキーコードが設定されている場合のみ登録
            if config.actionType == .keyInput, let keyCode = config.keyCode {
                shortcutsToRegister.append((
                    config.detectedButtonId ?? "",
                    keyCode,
                    config.modifierFlags
                ))
            }
        }
        
        buttonDetector.updateAllShortcuts(configs: shortcutsToRegister)
    }
    
    private func initializeButtonsFromDetector() {
        guard let controllerId = profileViewModel.selectedControllerId,
              let profileId = profileViewModel.selectedProfileId else {
            return
        }
        
        let existingButtonIds = Set(profileViewModel.selectedProfile?.buttonConfigs.compactMap { $0.detectedButtonId } ?? [])
        
        // ButtonDetectorに登録されているボタンで、まだプロファイルに追加されていないものを追加
        for detectedButton in buttonDetector.registeredButtons {
            if !existingButtonIds.contains(detectedButton.id) {
                profileViewModel.addButtonConfig(
                    to: controllerId,
                    profileId: profileId,
                    name: detectedButton.displayName,
                    detectedButtonId: detectedButton.id
                )
            }
        }
    }
}
//

struct AddButtonConfigSheet: View {
    @ObservedObject var profileViewModel: ControllerProfileViewModel
    @ObservedObject var buttonDetector: ButtonDetector
    @Binding var isPresented: Bool
    
    @State private var selectedButtonId: String?
    @State private var buttonName: String = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("ボタンを追加")
                .font(.title2)
                .fontWeight(.semibold)
            
            if buttonDetector.registeredButtons.isEmpty {
                Text("登録されているボタンがありません")
                    .foregroundColor(.secondary)
            } else {
                List(selection: $selectedButtonId) {
                    ForEach(buttonDetector.registeredButtons) { button in
                        HStack {
                            Image(systemName: button.icon)
                            Text(button.displayName)
                        }
                        .tag(button.id)
                    }
                }
                .frame(height: 300)
                
                TextField("ボタン名（オプション）", text: $buttonName)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack(spacing: 12) {
                Button("キャンセル") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                
                Button("追加") {
                    if let buttonId = selectedButtonId,
                       let controllerId = profileViewModel.selectedControllerId,
                       let profileId = profileViewModel.selectedProfileId {
                        let name = buttonName.isEmpty ? buttonDetector.registeredButtons.first(where: { $0.id == buttonId })?.displayName ?? "New Button" : buttonName
                        profileViewModel.addButtonConfig(
                            to: controllerId,
                            profileId: profileId,
                            layerIndex: profileViewModel.selectedLayerIndex,
                            name: name,
                            detectedButtonId: buttonId
                        )
                        isPresented = false
                        buttonName = ""
                        selectedButtonId = nil
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedButtonId == nil)
            }
        }
        .padding()
        .frame(width: 500, height: 500)
    }
}


#Preview {
    ContentView()
        .environmentObject(ControllerMonitor())
        .frame(minWidth: 1000, minHeight: 700)
}

