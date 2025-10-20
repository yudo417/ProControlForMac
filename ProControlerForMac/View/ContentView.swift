import SwiftUI
import GameController





struct ContentView: View {
    @EnvironmentObject var controllerMonitor: ControllerMonitor
    @StateObject private var cursorController = CursorController()
    
    var Nowposition: CGPoint {
        cursorController.getPosition()
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(controllerMonitor.isConnected ? "✅ コントローラー接続中" : "❌ コントローラー未接続")
                .font(.title)
            
            Divider()
            
            Text("Button A: \(controllerMonitor.buttonA ? "Pressed" : "Released")")
            Text("Left Stick: X = \(String(format: "%.3f", controllerMonitor.leftStick.x)), Y = \(String(format: "%.3f", controllerMonitor.leftStick.y))")
            Text("Cursor: X = \(String(format: "%.0f", Nowposition.x)), Y = \(String(format: "%.0f", Nowposition.y))")
        }
        .padding()
        .onReceive(Timer.publish(every: 1/200, on: .main, in: .common).autoconnect()) { _ in
            guard controllerMonitor.isConnected else { return }
            
            let deltaX = controllerMonitor.leftStick.x * 3
            let deltaY = -controllerMonitor.leftStick.y * 3
            
            cursorController.moveCursor(deltaX: deltaX, deltaY: deltaY)
            cursorController.updateButtonA(isPressed: controllerMonitor.buttonA)
        }
    }
}

#Preview{
    ContentView()
        .environmentObject(ControllerMonitor())
}

class CursorController: ObservableObject {
    @Published private var currentPosition: CGPoint = .zero
    private var buttonAPressed = false
    
    init() {
        currentPosition = getPosition()
    }
    
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

        // ボタンが押下中の場合は、ドラッグイベントとして送信
        let eventType: CGEventType = buttonAPressed ? .leftMouseDragged : .mouseMoved
        
        if let moveEvent = CGEvent(mouseEventSource: nil, mouseType: eventType, mouseCursorPosition: CGPoint(x: newX, y: newY), mouseButton: .left) {
            moveEvent.post(tap: .cghidEventTap)
        }
    }

    func updateButtonA(isPressed: Bool) {
        // ボタンが押された瞬間
        if isPressed && !buttonAPressed {
            let position = getPosition()
            if let downEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: position, mouseButton: .left) {
                downEvent.post(tap: .cghidEventTap)
            }
            buttonAPressed = true
        }
        // ボタンが離された瞬間
        else if !isPressed && buttonAPressed {
            let position = getPosition()
            if let upEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: position, mouseButton: .left) {
                upEvent.post(tap: .cghidEventTap)
            }
            buttonAPressed = false
        }
    }
}
