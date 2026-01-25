import SwiftUI
import GameController
import AppKit

class ControllerMonitor: ObservableObject {
    @Published var leftStick: (x: Float, y: Float) = (0.0, 0.0)
    @Published var rightStick: (x: Float, y: Float) = (0.0, 0.0)
    @Published var isConnected: Bool = false
    
    private var currentController: GCController?
    private let deadzone: Float = 0.1
    private let cursorController = CursorController()
    private var updateTimer: Timer?
    
    // ProfileViewModelへの参照（感度設定を取得するため）
    weak var profileViewModel: ControllerProfileViewModel?
    
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
                    // 左スティックの状態を更新（デッドゾーン処理）
                    let rawLeftX = gamepad.leftThumbstick.xAxis.value
                    let rawLeftY = gamepad.leftThumbstick.yAxis.value
                    
                    let processedLeftX = abs(rawLeftX) > self.deadzone ? rawLeftX : 0.0
                    let processedLeftY = abs(rawLeftY) > self.deadzone ? rawLeftY : 0.0
                    
                    self.leftStick = (processedLeftX, processedLeftY)
                    
                    // 右スティックの状態を更新（デッドゾーン処理）
                    let rawRightX = gamepad.rightThumbstick.xAxis.value
                    let rawRightY = gamepad.rightThumbstick.yAxis.value
                    
                    let processedRightX = abs(rawRightX) > self.deadzone ? rawRightX : 0.0
                    let processedRightY = abs(rawRightY) > self.deadzone ? rawRightY : 0.0
                    
                    self.rightStick = (processedRightX, processedRightY)
                    
                    // 感度設定を取得（デフォルトは10.0）
                    let leftSensitivity = self.profileViewModel?.currentStickSensitivity(isLeftStick: true) ?? 10.0
                    let rightSensitivity = self.profileViewModel?.currentStickSensitivity(isLeftStick: false) ?? 10.0
                    
                    // 左スティック：カーソル移動
                    let deltaX = processedLeftX * Float(leftSensitivity)
                    let deltaY = -processedLeftY * Float(leftSensitivity)
                    self.cursorController.moveCursor(deltaX: deltaX, deltaY: deltaY)
                    
                    // 右スティック：スクロール
                    // 方向設定を取得
                    let scrollDirection = self.profileViewModel?.currentRightStickScrollDirection() ?? (verticalInverted: false, horizontalInverted: false)
                    let verticalInverted = scrollDirection.verticalInverted
                    let horizontalInverted = scrollDirection.horizontalInverted
                    
                    // 方向設定に応じて符号を調整
                    var scrollX = processedRightX * Float(rightSensitivity) * 2.0
                    var scrollY = -processedRightY * Float(rightSensitivity) * 1.5
                    
                    if horizontalInverted {
                        scrollX = -scrollX
                    }
                    if verticalInverted {
                        scrollY = -scrollY
                    }
                    
                    self.cursorController.scrollWheel(deltaX: scrollX, deltaY: scrollY)
                }
            } else {
                // コントローラーが接続されていない
                if self.isConnected {
                    DispatchQueue.main.async {
                        self.isConnected = false
                        self.currentController = nil
                        self.leftStick = (0.0, 0.0)
                        self.rightStick = (0.0, 0.0)
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
    func getPosition() -> CGPoint {
        guard let event = CGEvent(source: nil) else {
            return .zero
        }
        return event.location
    }

    func moveCursor(deltaX: Float, deltaY: Float) {
        // デルタがゼロの場合は何もしない（不要なイベント送信を削減）
        guard deltaX != 0 || deltaY != 0 else { return }
        
        let currentPosition = getPosition()
        let newX = currentPosition.x + CGFloat(deltaX)
        let newY = currentPosition.y + CGFloat(deltaY)
        
        if let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: newX, y: newY), mouseButton: .left) {
            moveEvent.post(tap: .cghidEventTap)
        }
    }
    
    func scrollWheel(deltaX: Float, deltaY: Float) {
        // デルタがゼロの場合は何もしない
        guard deltaX != 0 || deltaY != 0 else { return }
        
        let position = getPosition()
        
        if let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: Int32(deltaY), wheel2: Int32(deltaX), wheel3: 0) {
            scrollEvent.post(tap: .cghidEventTap)
        }
    }
}
