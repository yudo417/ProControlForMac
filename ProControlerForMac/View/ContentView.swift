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
            Button {
                print("a")
            } label: {
                Text("ボタン")
            }
            ShortCut()

        }
        .padding()
        .onReceive(Timer.publish(every: 1/200, on: .main, in: .common).autoconnect()) { _ in
            guard controllerMonitor.isConnected else { return }
            
            let deltaX = controllerMonitor.leftStick.x * 1.5
            let deltaY = -controllerMonitor.leftStick.y * 1.5
            
            cursorController.moveCursor(deltaX: deltaX, deltaY: deltaY)
            cursorController.updateButtonA(isPressed: controllerMonitor.buttonA)
        }
    }
}

#Preview{
    ContentView()
        .environmentObject(ControllerMonitor())
}


