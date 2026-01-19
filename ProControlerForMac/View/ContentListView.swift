
import SwiftUI

struct ContentListView: View {
    @ObservedObject var profileViewModel: ControllerProfileViewModel
    @ObservedObject var buttonDetector: ButtonDetector
    @State private var showingAddButton = false
    @State private var showingDeleteAlert = false
    
    var selectedProfile: Profile? {
        profileViewModel.selectedProfile
    }
    
    var body: some View {
        Group {
            if let profile = selectedProfile {
                VStack(spacing: 0) {
                    layerPickerHeader(profile: profile) // レイヤー
                    Divider()
                    layerContentList(profile: profile) // リスト
                }
                .navigationTitle(profile.name)
                .toolbar {
                    ToolbarItem(placement: .automatic) {
                        Button {
                            showingAddButton = true
                        } label: {
                            Label("ボタンを追加", systemImage: "plus.circle")
                        }
                    }
                }
                .sheet(isPresented: $showingAddButton) {
                    AddButtonConfigSheet(
                        profileViewModel: profileViewModel,
                        buttonDetector: buttonDetector,
                        isPresented: $showingAddButton
                    )
                }
            } else {
                // プロファイル未選択時のプレースホルダー
                VStack(spacing: 24) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                    
                    Text("ファイルを選択")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("左側のサイドバーから\nファイルを選択してください")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .navigationTitle("")
            }
        }
    }
    
    @ViewBuilder
    private func layerPickerHeader(profile: Profile) -> some View {
        HStack {
            Picker("Layer", selection: $profileViewModel.selectedLayerIndex) {
                ForEach(0..<profile.layers.count, id: \.self) { index in
                    Text(profile.layers[index].name).tag(index)
                }
            }
            .pickerStyle(.segmented)
            .padding(.leading)
            
            // レイヤー追加ボタン
            Button(action: {
                if let controllerId = profileViewModel.selectedControllerId {
                    _ = profileViewModel.addLayer(
                        to: controllerId,
                        profileId: profile.id,
                        name: "Layer \(profile.layers.count)"
                    )
                }
            }) {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("新規レイヤーを追加")
            
            // レイヤー削除ボタン
            Button(action: {
                showingDeleteAlert = true
            }) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .disabled(profileViewModel.selectedLayerIndex == 0) // Defaultは削除不可
            .padding(.trailing)
            .help("現在のレイヤーを削除")
        }
        .padding(.vertical, 8)
        .background(Material.bar)
        .alert("レイヤーを削除", isPresented: $showingDeleteAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("削除", role: .destructive) {
                if let controllerId = profileViewModel.selectedControllerId {
                    let indexToRemove = profileViewModel.selectedLayerIndex
                    // 削除前にインデックスをDefault(0)に戻す
                    profileViewModel.selectedLayerIndex = 0
                    
                    profileViewModel.removeLayer(
                        controllerId: controllerId,
                        profileId: profile.id,
                        layerIndex: indexToRemove
                    )
                }
            }
        } message: {
            Text("現在のレイヤーを削除してもよろしいですか？この操作は取り消せません。")
        }
    }
    
    @ViewBuilder
    private func layerContentList(profile: Profile) -> some View {
        if profileViewModel.selectedLayerIndex < profile.layers.count {
            let currentLayer = profile.layers[profileViewModel.selectedLayerIndex]
            
            HStack{
                VStack(spacing:15) {
                    Text("Lスティック")
//                    Spacer()
                    Image(systemName: "l.joystick")
                        .resizable()
                        .frame(width: 20, height: 20)
//                    Text(String(format: "%.1f", currentLayer.leftStickSensitivity))
//                        .foregroundColor(.secondary)
                }
                .frame(maxWidth:.infinity,maxHeight:.infinity)
                .padding(.vertical, 4)
                .backgroundStyle(
                    profileViewModel.detailSelection == .leftStick
                    ? Color.accentColor
                    : Color.clear
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    profileViewModel.selectedButtonConfigId = nil
                    profileViewModel.detailSelection = .leftStick
                }

                Divider()
                // 右スティック
                VStack(spacing:15) {
                    Text("Rスティック")
//                    Spacer()
//                    Text(String(format: "%.1f", currentLayer.rightStickSensitivity))
//                        .foregroundColor(.secondary)
                    Image(systemName: "r.joystick")
                        .resizable()
                        .frame(width: 20, height: 20)
                }
                .frame(maxWidth:.infinity,maxHeight:.infinity)                .padding(.vertical, 4)
                .listRowBackground(
                    profileViewModel.detailSelection == .rightStick
                    ? Color.accentColor
                    : Color.clear
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    profileViewModel.selectedButtonConfigId = nil
                    profileViewModel.detailSelection = .rightStick
                }
            }
            .frame(height: 100)

            List(selection: $profileViewModel.selectedButtonConfigId) {
                // スティック感度セクション
                Section("スティック感度") {
                    // 左スティック
                }
                
                // ボタン設定セクション
                let groupedButtons = Dictionary(grouping: currentLayer.buttonConfigs) { button in
                    getCategory(for: button)
                }
                
                ForEach(Array(groupedButtons.keys.sorted()), id: \.self) { category in
                    Section(category) {
                        ForEach(groupedButtons[category] ?? []) { buttonConfig in
                            ButtonConfigRow(
                                buttonConfig: buttonConfig,
                                isSelected: profileViewModel.selectedButtonConfigId == buttonConfig.id
                            )
                            .tag(buttonConfig.id)
                        }
                    }
                }
            }
            .listStyle(.bordered)
            .onChange(of: profileViewModel.selectedButtonConfigId) { newValue in
                if let buttonId = newValue {
                    profileViewModel.detailSelection = .button(buttonId)
                }
            }
        } else {
            // レイヤー削除などでインデックスが範囲外になった場合のフォールバック
            Text("レイヤーが選択されていません")
                .onAppear { profileViewModel.selectedLayerIndex = 0 }
        }
    }

    private func getCategory(for buttonConfig: ButtonConfig) -> String {
        // DetectedButtonのカテゴリを使用、または名前から推測
        if let detectedButtonId = buttonConfig.detectedButtonId,
           let detectedButton = buttonDetector.registeredButtons.first(where: { $0.id == detectedButtonId }) {
            return detectedButton.category
        }

        // 名前から推測
        let name = buttonConfig.name.lowercased()
        if name.contains("a") || name.contains("b") || name.contains("x") || name.contains("y") {
            return "アクションボタン"
        } else if name.contains("dpad") || name.contains("十字") {
            return "D-Pad"
        } else if name.contains("shoulder") || name.contains("trigger") || name.contains("l") || name.contains("r") {
            return "バンパー/トリガー"
        } else if name.contains("stick") || name.contains("スティック") {
            return "スティックボタン"
        } else if name.contains("menu") || name.contains("home") || name.contains("option") {
            return "メニュー"
        }

        return "その他"
    }
}

struct ButtonConfigRow: View {
    let buttonConfig: ButtonConfig
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            Text(buttonConfig.name)
                .font(.body)

            Spacer()

            Text(buttonConfig.displayKey)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                .cornerRadius(6)
        }
        .padding(.vertical, 4)
    }
}
