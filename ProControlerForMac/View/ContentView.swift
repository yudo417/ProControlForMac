import SwiftUI
import GameController
import CoreGraphics

// メインアプリケーションの構造体
@main
struct ProControllerMapperApp: App {
    @StateObject private var controllerManager = ControllerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controllerManager)
        }
    }
}

// コントローラー管理クラス
class ControllerManager: ObservableObject {
    @Published var connectedController: GCController?
    @Published var isControllerConnected = false
    @Published var buttonStates: [String: Bool] = [:]
    @Published var leftStickPosition: CGPoint = .zero
    @Published var rightStickPosition: CGPoint = .zero
    @Published var activeProfile: ControllerProfile
    @Published var savedProfiles: [ControllerProfile] = []

    private var mouseMoveTimer: Timer?
    private var scrollTimer: Timer?

    // ZRモード管理
    private var isZRPressed = false
    // ZLモード管理
    private var isZLPressed = false

    init() {
        // デフォルトプロファイルを作成
        activeProfile = ControllerProfile(name: "Default")

        // コントローラー接続/切断の通知を監視
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidDisconnect),
            name: .GCControllerDidDisconnect,
            object: nil
        )

        // 利用可能なコントローラーをスキャン
        startControllerDiscovery()
    }

    func startControllerDiscovery() {
        GCController.startWirelessControllerDiscovery {}
    }

    @objc private func controllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else { return }

        self.connectedController = controller
        self.isControllerConnected = true

        // コントローラーのボタンやスティックのハンドリングを設定
        setupControllerHandlers(controller)
    }

    @objc private func controllerDidDisconnect(_ notification: Notification) {
        self.connectedController = nil
        self.isControllerConnected = false

        // タイマーを停止
        mouseMoveTimer?.invalidate()
        scrollTimer?.invalidate()
    }

    private func setupControllerHandlers(_ controller: GCController) {
        // ExtendedGamepadが利用可能か確認
        guard let gamepad = controller.extendedGamepad else { return }

        // ZRとZLボタンの状態を監視
        gamepad.rightTrigger.valueChangedHandler = { (trigger, value, pressed) in
            self.isZRPressed = pressed
        }

        gamepad.leftTrigger.valueChangedHandler = { (trigger, value, pressed) in
            self.isZLPressed = pressed

            // ZLが押されたら、プロファイルを切り替え
            if pressed {
                self.cycleToNextProfile()
            }
        }

        // Aボタン (マウス左クリック)
        gamepad.buttonA.valueChangedHandler = { (button, value, pressed) in
            self.buttonStates["A"] = pressed

            if self.isZRPressed {
                // ZR + A の特殊動作
                self.executeAction(for: .zrPlusA, isPressed: pressed)
            } else {
                // 通常の A ボタン動作
                self.executeAction(for: .aButton, isPressed: pressed)
            }
        }

        // Bボタン
        gamepad.buttonB.valueChangedHandler = { (button, value, pressed) in
            self.buttonStates["B"] = pressed

            if self.isZRPressed {
                self.executeAction(for: .zrPlusB, isPressed: pressed)
            } else {
                self.executeAction(for: .bButton, isPressed: pressed)
            }
        }

        // Xボタン
        gamepad.buttonX.valueChangedHandler = { (button, value, pressed) in
            self.buttonStates["X"] = pressed

            if self.isZRPressed {
                self.executeAction(for: .zrPlusX, isPressed: pressed)
            } else {
                self.executeAction(for: .xButton, isPressed: pressed)
            }
        }

        // Yボタン
        gamepad.buttonY.valueChangedHandler = { (button, value, pressed) in
            self.buttonStates["Y"] = pressed

            if self.isZRPressed {
                self.executeAction(for: .zrPlusY, isPressed: pressed)
            } else {
                self.executeAction(for: .yButton, isPressed: pressed)
            }
        }

        // 左スティック（マウス移動）
        gamepad.leftThumbstick.valueChangedHandler = { (dpad, xValue, yValue) in
            self.leftStickPosition = CGPoint(x: CGFloat(xValue), y: CGFloat(yValue))

            // スティックが中立位置にあるか
            let isNeutral = abs(xValue) < 0.1 && abs(yValue) < 0.1

            if isNeutral {
                // スティックが中立位置にある場合はタイマーを停止
                self.mouseMoveTimer?.invalidate()
                self.mouseMoveTimer = nil
            } else if self.mouseMoveTimer == nil {
                // スティックが動いていてタイマーがない場合は、タイマーを開始
                self.mouseMoveTimer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true) { _ in
                    if self.isZRPressed {
                        // ZR + 左スティックの特殊動作
                        self.handleZRLeftStick(x: xValue, y: yValue)
                    } else {
                        // 通常の左スティック動作（マウス移動）
                        self.moveMouseWithLeftStick(x: xValue, y: yValue)
                    }
                }
            }
        }

        // 右スティック（スクロール）
        gamepad.rightThumbstick.valueChangedHandler = { (dpad, xValue, yValue) in
            self.rightStickPosition = CGPoint(x: CGFloat(xValue), y: CGFloat(yValue))

            // スティックが中立位置にあるか
            let isNeutral = abs(xValue) < 0.1 && abs(yValue) < 0.1

            if isNeutral {
                // スティックが中立位置にある場合はタイマーを停止
                self.scrollTimer?.invalidate()
                self.scrollTimer = nil
            } else if self.scrollTimer == nil {
                // スティックが動いていてタイマーがない場合は、タイマーを開始
                self.scrollTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                    if self.isZRPressed {
                        // ZR + 右スティックの特殊動作
                        self.handleZRRightStick(x: xValue, y: yValue)
                    } else {
                        // 通常の右スティック動作（スクロール）
                        self.scrollWithRightStick(x: xValue, y: yValue)
                    }
                }
            }
        }
    }

    // プロファイル切り替え機能
    private func cycleToNextProfile() {
        guard !savedProfiles.isEmpty else { return }

        if let currentIndex = savedProfiles.firstIndex(where: { $0.id == activeProfile.id }) {
            let nextIndex = (currentIndex + 1) % savedProfiles.count
            activeProfile = savedProfiles[nextIndex]
        } else {
            activeProfile = savedProfiles[0]
        }
    }

    // アクション実行関数
    private func executeAction(for button: ControllerButton, isPressed: Bool) {
        guard let action = activeProfile.mappings[button] else { return }

        switch action {
        case .mouseLeftClick:
            if isPressed {
                performMouseClick(button: .left, clickCount: 1)
            }
        case .mouseRightClick:
            if isPressed {
                performMouseClick(button: .right, clickCount: 1)
            }
        case .mouseDoubleClick:
            if isPressed {
                performMouseClick(button: .left, clickCount: 2)
            }
        case .keyPress(let keyCode):
            performKeyPress(keyCode: keyCode, isDown: isPressed)
        case .keyCombo(let keyCodes):
            for code in keyCodes {
                performKeyPress(keyCode: code, isDown: isPressed)
            }
        case .none:
            // マッピングなし
            break
        }
    }

    // マウス移動関数
    private func moveMouseWithLeftStick(x: Float, y: Float) {
        let sensitivityFactor = activeProfile.mouseSensitivity
        let deltaX = CGFloat(x) * sensitivityFactor
        let deltaY = CGFloat(-y) * sensitivityFactor  // Y軸は反転

        let currentPosition = getCurrentMousePosition()
        let newPosition = CGPoint(
            x: currentPosition.x + deltaX,
            y: currentPosition.y + deltaY
        )

        setMousePosition(to: newPosition)
    }

    // ZR + 左スティックの特殊処理
    private func handleZRLeftStick(x: Float, y: Float) {
        // 例：精密なマウス移動
        let fineSensitivityFactor = activeProfile.mouseSensitivity * 0.5
        let deltaX = CGFloat(x) * fineSensitivityFactor
        let deltaY = CGFloat(-y) * fineSensitivityFactor

        let currentPosition = getCurrentMousePosition()
        let newPosition = CGPoint(
            x: currentPosition.x + deltaX,
            y: currentPosition.y + deltaY
        )

        setMousePosition(to: newPosition)
    }

    // スクロール関数
    private func scrollWithRightStick(x: Float, y: Float) {
        let scrollFactor = activeProfile.scrollSensitivity
        let deltaX = CGFloat(x) * scrollFactor
        let deltaY = CGFloat(-y) * scrollFactor

        performScroll(deltaX: deltaX, deltaY: deltaY)
    }

    // ZR + 右スティックの特殊処理
    private func handleZRRightStick(x: Float, y: Float) {
        // 例：水平スクロール
        let horizontalScrollFactor = activeProfile.scrollSensitivity * 1.5
        let deltaX = CGFloat(x) * horizontalScrollFactor

        performScroll(deltaX: deltaX, deltaY: 0)
    }

    // プロファイル保存
    func saveCurrentProfile() {
        if let index = savedProfiles.firstIndex(where: { $0.id == activeProfile.id }) {
            savedProfiles[index] = activeProfile
        } else {
            savedProfiles.append(activeProfile)
        }
    }

    // プロファイル作成
    func createNewProfile(name: String) {
        let newProfile = ControllerProfile(name: name)
        savedProfiles.append(newProfile)
        activeProfile = newProfile
    }

    // 以下は低レベルのマウス/キーボード操作関数
    // CGEventを使用してマウスクリックを実行
    private func performMouseClick(button: CGMouseButton, clickCount: Int) {
        let mouseDown = CGEvent(mouseEventSource: nil, mouseType: button == .left ? .leftMouseDown : .rightMouseDown,
                               mouseCursorPosition: getCurrentMousePosition(), mouseButton: button)
        mouseDown?.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
        mouseDown?.post(tap: .cghidEventTap)

        let mouseUp = CGEvent(mouseEventSource: nil, mouseType: button == .left ? .leftMouseUp : .rightMouseUp,
                             mouseCursorPosition: getCurrentMousePosition(), mouseButton: button)
        mouseUp?.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
        mouseUp?.post(tap: .cghidEventTap)
    }

    // 現在のマウス位置を取得
    private func getCurrentMousePosition() -> CGPoint {
        let screenRect = NSScreen.main?.frame ?? .zero
        let screenHeight = screenRect.height

        // 現在のマウス位置を取得 (Quartz Display Servicesを使用)
        var mouseLocation = NSEvent.mouseLocation

        // Y座標系を変換 (Cocoaの座標系はスクリーン下部が原点、CGイベントはスクリーン上部が原点)
        mouseLocation.y = screenHeight - mouseLocation.y

        return mouseLocation
    }

    // マウス位置を設定
    private func setMousePosition(to position: CGPoint) {
        let screenRect = NSScreen.main?.frame ?? .zero
        let screenHeight = screenRect.height

        // 画面の境界内に収める
        let boundedX = min(max(position.x, 0), screenRect.width)
        let boundedY = min(max(position.y, 0), screenHeight)

        // CGEventを使用してマウスを移動
        let moveEvent = CGEvent(source: nil)
        moveEvent?.type = .mouseMoved
        moveEvent?.location = CGPoint(x: boundedX, y: boundedY)
        moveEvent?.post(tap: .cghidEventTap)
    }

    // スクロール動作の実行
    private func performScroll(deltaX: CGFloat, deltaY: CGFloat) {
        let scrollEvent = CGEvent(scrollWheelEvent2Source: nil,
                                 units: .pixel,
                                 wheelCount: 2,
                                 wheel1: Int32(deltaY),
                                 wheel2: Int32(deltaX),
                                 wheel3: 0)
        scrollEvent?.post(tap: .cghidEventTap)
    }

    // キーボードイベントの実行
    private func performKeyPress(keyCode: UInt16, isDown: Bool) {
        let keyEvent = CGEvent(keyboardEventSource: nil,
                              virtualKey: keyCode,
                              keyDown: isDown)
        keyEvent?.post(tap: .cghidEventTap)
    }
}

// コントローラープロファイル構造体
struct ControllerProfile: Identifiable, Codable {
    var id = UUID()
    var name: String
    var mappings: [ControllerButton: ControllerAction] = [:]
    var mouseSensitivity: CGFloat = 10.0
    var scrollSensitivity: CGFloat = 5.0

    init(name: String) {
        self.name = name

        // デフォルトマッピングを設定
        mappings[.aButton] = .mouseLeftClick
        mappings[.bButton] = .mouseRightClick
        mappings[.xButton] = .keyPress(0x31)  // スペースキー
        mappings[.yButton] = .keyPress(0x35)  // ESCキー

        // ZR組み合わせのデフォルトマッピング
        mappings[.zrPlusA] = .mouseDoubleClick
        mappings[.zrPlusB] = .keyPress(0x7D)  // PageDown
        mappings[.zrPlusX] = .keyPress(0x7E)  // 上矢印
        mappings[.zrPlusY] = .keyPress(0x7D)  // 下矢印
    }
}

// コントローラーボタン列挙型
enum ControllerButton: String, Codable,Identifiable {
    case aButton, bButton, xButton, yButton
    case zrPlusA, zrPlusB, zrPlusX, zrPlusY
    // 必要に応じて他のボタンも追加
    var id:String {rawValue}
}

// マッピング可能なアクション列挙型
enum ControllerAction: Codable {
    case none
    case mouseLeftClick
    case mouseRightClick
    case mouseDoubleClick
    case keyPress(UInt16)
    case keyCombo([UInt16])
}

// メインのコンテンツビュー
struct ContentView: View {
    @EnvironmentObject private var controllerManager: ControllerManager
    @State private var isEditingProfile = false
    @State private var newProfileName = ""

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("コントローラーステータス")) {
                    if controllerManager.isControllerConnected {
                        Label("プロコントローラー接続中", systemImage: "gamecontroller.fill")
                            .foregroundColor(.green)
                    } else {
                        Button(action: {
                            controllerManager.startControllerDiscovery()
                        }) {
                            Label("プロコントローラーを検索", systemImage: "bluetooth")
                        }
                    }
                }

                Section(header: Text("アクティブプロファイル")) {
                    Text(controllerManager.activeProfile.name)
                        .font(.headline)

                    HStack {
                        Text("マウス感度")
                        Slider(value: $controllerManager.activeProfile.mouseSensitivity, in: 1...20)
                    }

                    HStack {
                        Text("スクロール感度")
                        Slider(value: $controllerManager.activeProfile.scrollSensitivity, in: 1...20)
                    }

                    NavigationLink(destination: ProfileEditView()) {
                        Text("ボタンマッピングを編集")
                    }
                }

                Section(header: Text("保存済みプロファイル")) {
                    ForEach(controllerManager.savedProfiles) { profile in
                        Button(action: {
                            controllerManager.activeProfile = profile
                        }) {
                            HStack {
                                Text(profile.name)
                                Spacer()
                                if profile.id == controllerManager.activeProfile.id {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Button(action: {
                        isEditingProfile = true
                    }) {
                        Label("新規プロファイル作成", systemImage: "plus")
                    }
                }

                Section(header: Text("コントローラー入力")) {
                    VStack(alignment: .leading) {
                        Text("左スティック: \(String(format: "X: %.2f, Y: %.2f", controllerManager.leftStickPosition.x, controllerManager.leftStickPosition.y))")
                        Text("右スティック: \(String(format: "X: %.2f, Y: %.2f", controllerManager.rightStickPosition.x, controllerManager.rightStickPosition.y))")

                        HStack {
                            ForEach(["A", "B", "X", "Y"], id: \.self) { button in
                                let isPressed = controllerManager.buttonStates[button] ?? false
                                Text(button)
                                    .padding(8)
                                    .background(isPressed ? Color.blue : Color.gray)
                                    .foregroundColor(.white)
                                    .cornerRadius(5)
                            }
                        }
                    }
                }
            }
            .listStyle(SidebarListStyle())
            .navigationTitle("ProCon Mapper")
            .toolbar {
                Button(action: {
                    controllerManager.saveCurrentProfile()
                }) {
                    Text("現在の設定を保存")
                }
            }
            .sheet(isPresented: $isEditingProfile) {
                VStack {
                    Text("新規プロファイル").font(.headline)
                    TextField("プロファイル名", text: $newProfileName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()

                    HStack {
                        Button("キャンセル") {
                            isEditingProfile = false
                            newProfileName = ""
                        }

                        Button("作成") {
                            if !newProfileName.isEmpty {
                                controllerManager.createNewProfile(name: newProfileName)
                                isEditingProfile = false
                                newProfileName = ""
                            }
                        }
                        .disabled(newProfileName.isEmpty)
                    }
                    .padding()
                }
                .frame(width: 300, height: 200)
            }
        }
    }
}

// プロファイル編集ビュー
struct ProfileEditView: View {
    @EnvironmentObject private var controllerManager: ControllerManager
    @State private var selectedButton: ControllerButton?
    @State private var selectedAction: ControllerAction = .none

    // キーコードの辞書（実際のアプリではもっと充実させる）
    let keyCodes: [String: UInt16] = [
        "スペース": 0x31,
        "エンター": 0x24,
        "ESC": 0x35,
        "Tab": 0x30,
        "上矢印": 0x7E,
        "下矢印": 0x7D,
        "左矢印": 0x7B,
        "右矢印": 0x7C,
        "PageUp": 0x74,
        "PageDown": 0x79
    ]

    var body: some View {
        Form {
            Section(header: Text("標準ボタンマッピング")) {
                makeButtonRow(label: "Aボタン", button: .aButton)
                makeButtonRow(label: "Bボタン", button: .bButton)
                makeButtonRow(label: "Xボタン", button: .xButton)
                makeButtonRow(label: "Yボタン", button: .yButton)
            }

            Section(header: Text("ZR組み合わせマッピング")) {
                makeButtonRow(label: "ZR + A", button: .zrPlusA)
                makeButtonRow(label: "ZR + B", button: .zrPlusB)
                makeButtonRow(label: "ZR + X", button: .zrPlusX)
                makeButtonRow(label: "ZR + Y", button: .zrPlusY)
            }
        }
        .navigationTitle("ボタンマッピング編集")
        .sheet(item: $selectedButton) { button in
            ActionSelectionView(button: button, currentAction: controllerManager.activeProfile.mappings[button] ?? .none) { newAction in
                controllerManager.activeProfile.mappings[button] = newAction
                selectedButton = nil
            }
        }
    }

    private func makeButtonRow(label: String, button: ControllerButton) -> some View {
        HStack {
            Text(label)
            Spacer()
            Text(getActionDescription(controllerManager.activeProfile.mappings[button] ?? .none))
                .foregroundColor(.gray)
            Button(action: {
                selectedButton = button
            }) {
                Image(systemName: "pencil")
            }
        }
    }

    private func getActionDescription(_ action: ControllerAction) -> String {
        switch action {
        case .none:
            return "未設定"
        case .mouseLeftClick:
            return "マウス左クリック"
        case .mouseRightClick:
            return "マウス右クリック"
        case .mouseDoubleClick:
            return "ダブルクリック"
        case .keyPress(let keyCode):
            return "キー: \(getKeyName(for: keyCode))"
        case .keyCombo(let keyCodes):
            return "キー組み合わせ: \(keyCodes.map { getKeyName(for: $0) }.joined(separator: "+"))"
        }
    }

    private func getKeyName(for keyCode: UInt16) -> String {
        for (name, code) in keyCodes where code == keyCode {
            return name
        }
        return "キー(\(keyCode))"
    }
}

// アクション選択ビュー
struct ActionSelectionView: View {
    let button: ControllerButton
    let currentAction: ControllerAction
    let onSelect: (ControllerAction) -> Void

    @State private var selectedActionType = 0
    @State private var selectedKeyCode: UInt16 = 0

    // 基本的なキーコードマッピング
    let keyOptions: [(String, UInt16)] = [
        ("スペース", 0x31),
        ("エンター", 0x24),
        ("ESC", 0x35),
        ("Tab", 0x30),
        ("上矢印", 0x7E),
        ("下矢印", 0x7D),
        ("左矢印", 0x7B),
        ("右矢印", 0x7C),
        ("PageUp", 0x74),
        ("PageDown", 0x79)
    ]

    var body: some View {
        VStack {
            Text("\(button.rawValue)のアクション設定")
                .font(.headline)
                .padding()

            Picker("アクションタイプ", selection: $selectedActionType) {
                Text("未設定").tag(0)
                Text("マウス左クリック").tag(1)
                Text("マウス右クリック").tag(2)
                Text("ダブルクリック").tag(3)
                Text("キー押下").tag(4)
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()

            if selectedActionType == 4 {
                // キー選択UI
                Picker("キー選択", selection: $selectedKeyCode) {
                    ForEach(keyOptions, id: \.1) { option in
                        Text(option.0).tag(option.1)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .padding()
            }

            Button("設定を保存") {
                let newAction: ControllerAction
                switch selectedActionType {
                case 0:
                    newAction = .none
                case 1:
                    newAction = .mouseLeftClick
                case 2:
                    newAction = .mouseRightClick
                case 3:
                    newAction = .mouseDoubleClick
                case 4:
                    newAction = .keyPress(selectedKeyCode)
                default:
                    newAction = .none
                }
                onSelect(newAction)
            }
            .padding()

            Button("キャンセル") {
                onSelect(currentAction)
            }
            .padding()
        }
        .frame(width: 400, height: 300)
        .onAppear {
            // 現在のアクションに基づいて初期選択を設定
            switch currentAction {
            case .none:
                selectedActionType = 0
            case .mouseLeftClick:
                selectedActionType = 1
            case .mouseRightClick:
                selectedActionType = 2
            case .mouseDoubleClick:
                selectedActionType = 3
            case .keyPress(let keyCode):
                selectedActionType = 4
                selectedKeyCode = keyCode
            case .keyCombo:
                selectedActionType = 4  // 簡易化のために単一キーとして扱う
            }
        }
    }
}
