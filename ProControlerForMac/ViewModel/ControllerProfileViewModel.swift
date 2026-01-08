
import Foundation
import SwiftUI
import Combine
import GameController

class ControllerProfileViewModel: ObservableObject {
    /// すべてのコントローラー
    @Published var controllers: [Controller] = []
    /// 選択中のコントローラーID
    @Published var selectedControllerId: UUID?
    /// 選択中のプロファイルID
    @Published var selectedProfileId: UUID?
    /// 選択中のボタン設定ID
    @Published var selectedButtonConfigId: UUID?
    /// 選択中のレイヤーインデックス
    @Published var selectedLayerIndex: Int = 0

    private let storageKey = "ControllerProfiles"
    private var cancellables = Set<AnyCancellable>()
    /// 選択中のコントローラー
    var selectedController: Controller? {
        guard let id = selectedControllerId else { return nil }
        return controllers.first { $0.id == id }
    }
    /// 選択中のプロファイル
    var selectedProfile: Profile? {
        guard let controller = selectedController,
              let profileId = selectedProfileId else { return nil }
        return controller.profiles.first { $0.id == profileId }
    }
    /// 選択中のボタン設定
    var selectedButtonConfig: ButtonConfig? {
        guard let profile = selectedProfile,
              let buttonId = selectedButtonConfigId,
              selectedLayerIndex < profile.layers.count else { return nil }
        return profile.layers[selectedLayerIndex].buttonConfigs.first { $0.id == buttonId }
    }
    
    // MARK: - Initialization
    
    init() {
        loadData()
        setupDefaultData()
        setupControllerMonitoring()
        
        // 自動保存
        $controllers
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .sink { [weak self] _ in
                self?.saveData()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Controller Management
    
    /// コントローラーを追加
    func addController(name: String) -> Controller {
        let controller = Controller(name: name, isConnected: false)
        controllers.append(controller)
        return controller
    }
    
    /// コントローラーを削除
    func removeController(id: UUID) {
        controllers.removeAll { $0.id == id }
        if selectedControllerId == id {
            selectedControllerId = nil
            selectedProfileId = nil
            selectedButtonConfigId = nil
        }
    }
    
    /// コントローラーの接続状態を更新
    func updateControllerConnection(id: UUID, isConnected: Bool) {
        if let index = controllers.firstIndex(where: { $0.id == id }) {
            controllers[index].isConnected = isConnected
        }
    }

    func renameController(id: UUID, name: String) {
        
    }

    // MARK: - Profile Management
    
    /// プロファイルを追加
    func addProfile(to controllerId: UUID, name: String, icon: String = "folder.fill") -> Profile? {
        guard let controllerIndex = controllers.firstIndex(where: { $0.id == controllerId }) else {
            return nil
        }
        
        // デフォルトボタンの生成
        let defaultButtonConfigs = ButtonDetector.defaultProControllerButtons.map { detectedButton in
            ButtonConfig(
                name: detectedButton.displayName,
                detectedButtonId: detectedButton.id
            )
        }
        
        let defaultLayer = Layer(name: "Default", buttonConfigs: defaultButtonConfigs)
        let profile = Profile(name: name, icon: icon, layers: [defaultLayer])
        
        controllers[controllerIndex].profiles.append(profile)
        return profile
    }

    /// 選択したプロフィールを削除
    func removeProfile(controllerId: UUID, profileId: UUID) {
        guard let controllerIndex = controllers.firstIndex(where: { $0.id == controllerId }) else {
            return
        }
        
        controllers[controllerIndex].profiles.removeAll { $0.id == profileId }
        
        if selectedProfileId == profileId {
            selectedProfileId = nil
            selectedButtonConfigId = nil
        }
    }
    
    /// プロファイルを更新
    func updateProfile(controllerId: UUID, profileId: UUID, name: String? = nil, icon: String? = nil) {
        guard let controllerIndex = controllers.firstIndex(where: { $0.id == controllerId }),
              let profileIndex = controllers[controllerIndex].profiles.firstIndex(where: { $0.id == profileId }) else {
            return
        }
        
        if let name = name {
            controllers[controllerIndex].profiles[profileIndex].name = name
        }
        if let icon = icon {
            controllers[controllerIndex].profiles[profileIndex].icon = icon
        }
    }
    
    // MARK: - Layer Management
    
    /// レイヤーを追加
    func addLayer(to controllerId: UUID, profileId: UUID, name: String) -> Layer? {
        guard let controllerIndex = controllers.firstIndex(where: { $0.id == controllerId }),
              let profileIndex = controllers[controllerIndex].profiles.firstIndex(where: { $0.id == profileId }) else {
            return nil
        }
        
        // デフォルトのボタン設定をコピー（空だと不便なので）
        let defaultButtonConfigs = ButtonDetector.defaultProControllerButtons.map { detectedButton in
            ButtonConfig(
                name: detectedButton.displayName,
                detectedButtonId: detectedButton.id
            )
        }
        
        let layer = Layer(name: name, buttonConfigs: defaultButtonConfigs)
        controllers[controllerIndex].profiles[profileIndex].layers.append(layer)
        return layer
    }
    
    /// レイヤーを削除
    func removeLayer(controllerId: UUID, profileId: UUID, layerIndex: Int) {
        guard let controllerIndex = controllers.firstIndex(where: { $0.id == controllerId }),
              let profileIndex = controllers[controllerIndex].profiles.firstIndex(where: { $0.id == profileId }) else {
            return
        }
        
        // Defaultレイヤー（インデックス0）は削除禁止
        if layerIndex > 0 && layerIndex < controllers[controllerIndex].profiles[profileIndex].layers.count {
            controllers[controllerIndex].profiles[profileIndex].layers.remove(at: layerIndex)
        }
    }

    // MARK: - ButtonConfig Management
    
    /// ボタン設定を追加 (layerIndex指定対応版)
    func addButtonConfig(to controllerId: UUID, profileId: UUID, layerIndex: Int = 0, name: String, detectedButtonId: String? = nil) -> ButtonConfig? {
        guard let controllerIndex = controllers.firstIndex(where: { $0.id == controllerId }),
              let profileIndex = controllers[controllerIndex].profiles.firstIndex(where: { $0.id == profileId }),
              layerIndex < controllers[controllerIndex].profiles[profileIndex].layers.count else {
            return nil
        }
        
        let buttonConfig = ButtonConfig(name: name, detectedButtonId: detectedButtonId)
        controllers[controllerIndex].profiles[profileIndex].layers[layerIndex].buttonConfigs.append(buttonConfig)
        return buttonConfig
    }
    
    /// ボタン設定を削除 (layerIndex指定対応版)
    func removeButtonConfig(controllerId: UUID, profileId: UUID, layerIndex: Int = 0, buttonConfigId: UUID) {
        guard let controllerIndex = controllers.firstIndex(where: { $0.id == controllerId }),
              let profileIndex = controllers[controllerIndex].profiles.firstIndex(where: { $0.id == profileId }),
              layerIndex < controllers[controllerIndex].profiles[profileIndex].layers.count else {
            return
        }
        
        controllers[controllerIndex].profiles[profileIndex].layers[layerIndex].buttonConfigs.removeAll { $0.id == buttonConfigId }
        
        if selectedButtonConfigId == buttonConfigId {
            selectedButtonConfigId = nil
        }
    }
    
    /// ボタン設定を更新 (layerIndex指定対応版)
    func updateButtonConfig(
        controllerId: UUID,
        profileId: UUID,
        layerIndex: Int = 0,
        buttonConfigId: UUID,
        name: String? = nil,
        actionType: ButtonActionType? = nil,
        keyCode: UInt16? = nil,
        modifierFlags: NSEvent.ModifierFlags? = nil,
        isTurbo: Bool? = nil,
        isLongPress: Bool? = nil,
        longPressDuration: Double? = nil,
        targetLayerId: UUID? = nil,
        shouldUpdateTargetLayerId: Bool = false
    ) {
        guard let controllerIndex = controllers.firstIndex(where: { $0.id == controllerId }),
              let profileIndex = controllers[controllerIndex].profiles.firstIndex(where: { $0.id == profileId }),
              layerIndex < controllers[controllerIndex].profiles[profileIndex].layers.count,
              let buttonIndex = controllers[controllerIndex].profiles[profileIndex].layers[layerIndex].buttonConfigs.firstIndex(where: { $0.id == buttonConfigId }) else {
            return
        }
        
        var config = controllers[controllerIndex].profiles[profileIndex].layers[layerIndex].buttonConfigs[buttonIndex]
        
        if let name = name { config.name = name }
        if let actionType = actionType { config.actionType = actionType }
        if let keyCode = keyCode {
            config.keyCode = keyCode
            config.assignedKey = KeyCodeConverter.keyCodeToString(keyCode)
        }
        if let modifierFlags = modifierFlags { config.modifierFlags = modifierFlags }
        if let isTurbo = isTurbo { config.isTurbo = isTurbo }
        if let isLongPress = isLongPress { config.isLongPress = isLongPress }
        if let longPressDuration = longPressDuration { config.longPressDuration = longPressDuration }
        
        // targetLayerIdの更新ロジック（nilクリア対応）
        if shouldUpdateTargetLayerId {
            config.targetLayerId = targetLayerId
        } else if let targetLayerId = targetLayerId {
            config.targetLayerId = targetLayerId
        }
        
        controllers[controllerIndex].profiles[profileIndex].layers[layerIndex].buttonConfigs[buttonIndex] = config
    }
    
    /// ボタン設定をリセット
    func resetButtonConfig(controllerId: UUID, profileId: UUID, layerIndex: Int = 0, buttonConfigId: UUID) {
        guard let controllerIndex = controllers.firstIndex(where: { $0.id == controllerId }),
              let profileIndex = controllers[controllerIndex].profiles.firstIndex(where: { $0.id == profileId }),
              layerIndex < controllers[controllerIndex].profiles[profileIndex].layers.count,
              let buttonIndex = controllers[controllerIndex].profiles[profileIndex].layers[layerIndex].buttonConfigs.firstIndex(where: { $0.id == buttonConfigId }) else {
            return
        }
        
        // 名前とdetectedButtonId以外を初期化
        var config = controllers[controllerIndex].profiles[profileIndex].layers[layerIndex].buttonConfigs[buttonIndex]
        config.actionType = .keyInput
        config.keyCode = nil
        config.assignedKey = nil
        config.modifierFlagsRawValue = nil
        config.isTurbo = false
        config.isLongPress = false
        config.targetLayerId = nil
        
        controllers[controllerIndex].profiles[profileIndex].layers[layerIndex].buttonConfigs[buttonIndex] = config
    }
    
    // MARK: - Input Handling
    
    /// ボタン入力イベントを処理（レイヤー切り替えなど）
    func handleButtonEvent(buttonId: String, isPressed: Bool) {
        guard let profile = selectedProfile else { return }
        
        // 1. 現在のレイヤーでの設定を確認
        if selectedLayerIndex < profile.layers.count {
            if let config = profile.layers[selectedLayerIndex].buttonConfigs.first(where: { $0.detectedButtonId == buttonId }) {
                if config.actionType == .layerShift {
                    if isPressed, let targetId = config.targetLayerId {
                        // ターゲットレイヤーへ切り替え
                        if let targetIndex = profile.layers.firstIndex(where: { $0.id == targetId }) {
                            DispatchQueue.main.async {
                                self.selectedLayerIndex = targetIndex
                            }
                            print("🔄 Layer shift: \(selectedLayerIndex) -> \(targetIndex) (Button: \(buttonId))")
                        }
                    } else if !isPressed {
                        // ボタンを離したらデフォルト(0)に戻す
                        DispatchQueue.main.async {
                            self.selectedLayerIndex = 0
                        }
                        print("🔄 Layer reset to 0 (Button release: \(buttonId))")
                    }
                    return
                }
            }
        }
        
        // 2. 現在レイヤーシフト中(index != 0)で、ボタンが離された場合
        // 現在のレイヤーにそのボタンの設定がなくても、それが「シフトを引き起こしたボタン(レイヤー0の設定)」であれば戻す必要がある
        if !isPressed && selectedLayerIndex != 0 {
            // レイヤー0の設定を確認
            if let baseConfig = profile.layers.first?.buttonConfigs.first(where: { $0.detectedButtonId == buttonId }) {
                if baseConfig.actionType == .layerShift {
                    DispatchQueue.main.async {
                        self.selectedLayerIndex = 0
                    }
                    print("🔄 Layer reset to 0 by base trigger (Button release: \(buttonId))")
                }
            }
        }
    }
    
    // MARK: - Default Data Setup
    
    private func setupDefaultData() {
        // 既にデータがある場合はスキップ
        if !controllers.isEmpty {
            return
        }
        
        // デフォルトコントローラーを作成
        let defaultController = Controller(
            name: "Pro Controller",
            isConnected: false,
            profiles: [
                Profile(
                    name: "Default",
                    icon: "star.fill",
                    layers: [
                        Layer(name: "Default", buttonConfigs: [])
                    ]
                )
            ]
        )
        
        controllers.append(defaultController)
        selectedControllerId = defaultController.id
        selectedProfileId = defaultController.profiles.first?.id
    }
    
    // MARK: - Controller Monitoring
    
    private func setupControllerMonitoring() {
        // コントローラー接続監視
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController else { return }
            self?.handleControllerConnect(controller)
        }
        
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidDisconnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let controller = notification.object as? GCController else { return }
            self?.handleControllerDisconnect(controller)
        }
        
        // 既存のコントローラーをチェック
        if let existingController = GCController.controllers().first {
            handleControllerConnect(existingController)
        }
    }
    
    private func handleControllerConnect(_ controller: GCController) {
        let controllerName = controller.vendorName ?? "Unknown Controller"
        
        // 既存のコントローラーを探す
        if let existingIndex = controllers.firstIndex(where: { $0.name == controllerName }) {
            controllers[existingIndex].isConnected = true
            if selectedControllerId == nil {
                selectedControllerId = controllers[existingIndex].id
            }
        } else {
            // 新しいコントローラーを追加
            let newController = Controller(
                name: controllerName,
                isConnected: true,
                profiles: [
                    Profile(
                        name: "Default",
                        icon: "star.fill",
                        layers: [
                            Layer(name: "Default", buttonConfigs: [])
                        ]
                    )
                ]
            )
            controllers.append(newController)
            if selectedControllerId == nil {
                selectedControllerId = newController.id
                selectedProfileId = newController.profiles.first?.id
            }
        }
    }
    
    private func handleControllerDisconnect(_ controller: GCController) {
        let controllerName = controller.vendorName ?? "Unknown Controller"
        
        if let index = controllers.firstIndex(where: { $0.name == controllerName }) {
            controllers[index].isConnected = false
        }
    }
    
    // MARK: - Persistence
    
    private func saveData() {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(controllers) {
            UserDefaults.standard.set(encoded, forKey: storageKey)
        }
    }
    
    private func loadData() {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return
        }
        
        let decoder = JSONDecoder()
        if let decoded = try? decoder.decode([Controller].self, from: data) {
            controllers = decoded
            
            // 最初のコントローラーとプロファイルを選択
            if let firstController = controllers.first {
                selectedControllerId = firstController.id
                if let firstProfile = firstController.profiles.first {
                    selectedProfileId = firstProfile.id
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

