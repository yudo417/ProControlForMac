import SwiftUI
import GameController





struct ContentView: View {
    @EnvironmentObject var controllerMonitor: ControllerMonitor
    let ccvm = CursorController()
    var Nowposition: CGPoint {
        ccvm.getPosition()
    }

    var body: some View {
        VStack {
            Text("Button A: \(controllerMonitor.buttonA ? "Pressed" : "Released")")
            Text("Left Stick: X = \(controllerMonitor.leftStick.x), Y = \(controllerMonitor.leftStick.y)")
        }

        .onReceive(Timer.publish(every: 1/200, on: .main, in: .common).autoconnect()) { _ in
            let deltaX = controllerMonitor.leftStick.x * 2
            let deltaY = -controllerMonitor.leftStick.y * 2
            ccvm.moveCursor(deltaX: deltaX, deltaY: deltaY)
            ccvm.pressbuttonA(isAPressed: controllerMonitor.buttonA)
//            print("X:"+(deltaX > 0 ? " " : "")+String(format: "%0.8f", deltaX)+" Y:"+(deltaY >= 0 ? " " : "")+String(format: "%0.8f", deltaY) + " "+String(format: "%0.8f", Nowposition.x)+" "+String(format: "%0.8f", Nowposition.y))
        }

//        .onChange(of:[controllerMonitor.leftStick.x,controllerMonitor.leftStick.y,Float(Nowposition.x),Float(Nowposition.y)]){newValue in
//            let deltaX = newValue[0] * 5.0
//            let deltaY = -newValue[1] * 5.0 // Y軸は反転させる（画面座標系に合わせる）
//            ccvm.moveCursor(deltaX: deltaX, deltaY: deltaY)
//            print("X:"+(deltaX > 0 ? " " : "")+String(format: "%0.8f", deltaX)+" Y:"+(deltaY >= 0 ? " " : "")+String(format: "%0.8f", deltaY) + " "+String(format: "%0.8f", Nowposition.x)+" "+String(format: "%0.8f", Nowposition.y))
//
//
//        }
        .padding()
    }
}

#Preview{
    ContentView()
        .environmentObject(ControllerMonitor())
}

class CursorController {
    func getPosition() -> CGPoint{
        guard let event = CGEvent(source: nil) else {
            return .zero
        }
        return event.location
    }

    func moveCursor(deltaX: Float, deltaY: Float) {
        let currentPosition = getPosition()
        let newX = currentPosition.x + CGFloat(deltaX)
        let newY = currentPosition.y + CGFloat(deltaY)

        // CGEventを使ってカーソル位置を更新
        if let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: CGPoint(x: newX, y: newY), mouseButton: .left) {
            moveEvent.post(tap: .cghidEventTap)
        }
    }

    func pressbuttonA(isAPressed:Bool){
        if let buttonAEvent = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: getPosition(), mouseButton: .left){
                buttonAEvent.post(tap: .cghidEventTap)
            }

    }

    func getPositionString() -> String{
        return String(format: "%0.8f", self.getPosition().x)
    }
}
