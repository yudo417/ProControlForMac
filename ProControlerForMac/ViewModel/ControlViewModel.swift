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
        startBackgroundUpdates()
    }
    
    // MARK: - バックグラウンド入力処理
    private func startBackgroundUpdates() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1/200, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // 常にGCController.controllers()から取得（通知ベースではない）
            if let controller = GCController.controllers().first {
                if self.currentController !== controller {
                    self.currentController = controller
                    self.isConnected = true
                }
                
                guard let gamepad = controller.extendedGamepad else { return }
                
                // ポーリングで値を取得（valueChangedHandlerの代わり）
                DispatchQueue.main.async {
                    // Aボタンの状態を更新
                    self.buttonA = gamepad.buttonA.isPressed
                    
                    // 左スティックの状態を更新（デッドゾーン処理）
                    let rawX = gamepad.leftThumbstick.xAxis.value
                    let rawY = gamepad.leftThumbstick.yAxis.value
                    
                    let processedX = abs(rawX) > self.deadzone ? rawX : 0.0
                    let processedY = abs(rawY) > self.deadzone ? rawY : 0.0
                    
                    self.leftStick = (processedX, processedY)
                    
                    // カーソル移動
                    let deltaX = processedX * 3
                    let deltaY = -processedY * 3
                    
                    self.cursorController.moveCursor(deltaX: deltaX, deltaY: deltaY)
                    self.cursorController.updateButtonA(isPressed: self.buttonA)
                }
            } else {
                // コントローラーが接続されていない
                if self.isConnected {
                    DispatchQueue.main.async {
                        self.isConnected = false
                        self.currentController = nil
                        self.buttonA = false
                        self.leftStick = (0.0, 0.0)
                    }
                }
            }
        }
    }
    
    deinit {
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
