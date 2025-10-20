import SwiftUI
import GameController

class ControllerMonitor: ObservableObject {
    @Published var buttonA: Bool = false
    @Published var leftStick: (x: Float, y: Float) = (0.0, 0.0)
    @Published var isConnected: Bool = false
    
    private var currentController: GCController?
    private let deadzone: Float = 0.1
    
    init() {
        setupControllerNotifications()
        checkExistingControllers()
    }
    
    private func setupControllerNotifications() {
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
    }
    
    private func checkExistingControllers() {
        if let controller = GCController.controllers().first {
            setupController(controller)
        }
    }

    @objc func controllerDidConnect(notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        print("コントローラー接続: \(controller.vendorName ?? "Unknown")")
        DispatchQueue.main.async {
            self.setupController(controller)
        }
    }
    
    @objc func controllerDidDisconnect(notification: Notification) {
        guard let controller = notification.object as? GCController else { return }
        print("コントローラー切断: \(controller.vendorName ?? "Unknown")")
        DispatchQueue.main.async {
            if self.currentController === controller {
                self.isConnected = false
                self.currentController = nil
                self.buttonA = false
                self.leftStick = (0.0, 0.0)
            }
        }
    }
    
    private func setupController(_ controller: GCController) {
        self.currentController = controller
        self.isConnected = true

        //MARK: - extendedGamepadで個々のボタンの定義
        if let gamepad = controller.extendedGamepad {
            gamepad.valueChangedHandler = { [weak self] gamepad, element in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    if element == gamepad.buttonA {
                        self.buttonA = gamepad.buttonA.isPressed
                    }
                    if element == gamepad.leftThumbstick {
                        // デッドゾーン処理
                        let rawX = gamepad.leftThumbstick.xAxis.value
                        let rawY = gamepad.leftThumbstick.yAxis.value
                        
                        let processedX = abs(rawX) > self.deadzone ? rawX : 0.0
                        let processedY = abs(rawY) > self.deadzone ? rawY : 0.0
                        
                        self.leftStick = (processedX, processedY)
                    }
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
