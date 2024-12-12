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
        .onChange(of:[controllerMonitor.leftStick.x,controllerMonitor.leftStick.y]){newValue in
            defer{
                CGWarpMouseCursorPosition(CGPoint(x:(Nowposition.x) + CGFloat((newValue[0])),y:Nowposition.y + CGFloat(newValue[1])))
            }
            print("X:"+(newValue[0] > 0 ? " " : "")+String(format: "%0.8f", newValue[0])+" Y:"+(newValue[1] >= 0 ? " " : "")+String(format: "%0.8f", newValue[1]) + " "+String(format: "%0.8f", Nowposition.x)+" "+String(format: "%0.8f", Nowposition.y))
        }
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

    func getPositionString() -> String{
        return String(format: "%0.8f", self.getPosition().x)
    }
}
