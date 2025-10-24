import SwiftUI
import GameController
import AppKit

class ControllerMonitor: ObservableObject {
    @Published var buttonA: Bool = false
    @Published var leftStick: (x: Float, y: Float) = (0.0, 0.0)
    @Published var isConnected: Bool = false
    
    private var currentController: GCController?
    private let deadzone: Float = 0.1
    private let cursorController = CursorController()
    private var updateTimer: Timer?
    
    init() {
        setupControllerNotifications()
        checkExistingControllers()
        startBackgroundUpdates()
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
    
    // MARK: - バックグラウンド入力処理
    private func startBackgroundUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1/200, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            let deltaX = self.leftStick.x * 3
            let deltaY = -self.leftStick.y * 3
            
            self.cursorController.moveCursor(deltaX: deltaX, deltaY: deltaY)
            self.cursorController.updateButtonA(isPressed: self.buttonA)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        updateTimer?.invalidate()
    }
}

// MARK: - バックグラウンド用のカーソル制御
class CursorController :ObservableObject {
    private var buttonAPressed = false
    
    func getPosition() -> CGPoint {
        guard let event = CGEvent(source: nil) else {
            return .zero
        }
        return event.location
    }

    func moveCursor(deltaX: Float, deltaY: Float) {
        let currentPosition = getPosition()
        let newX = currentPosition.x + CGFloat(deltaX) * 3
        let newY = currentPosition.y + CGFloat(deltaY) * 3

        let eventType: CGEventType = buttonAPressed ? .leftMouseDragged : .mouseMoved
        
        if let moveEvent = CGEvent(mouseEventSource: nil, mouseType: eventType, mouseCursorPosition: CGPoint(x: newX, y: newY), mouseButton: .left) {
            moveEvent.post(tap: .cghidEventTap)
        }
    }

    func updateButtonA(isPressed: Bool) {
        if isPressed && !buttonAPressed {
            let position = getPosition()
            if let downEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left) {
                downEvent.post(tap: .cghidEventTap)
            }
            buttonAPressed = true
        }
        else if !isPressed && buttonAPressed {
            let position = getPosition()
            if let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: position, mouseButton: .left) {
                upEvent.post(tap: .cghidEventTap)
            }
            buttonAPressed = false
        }
    }
}
