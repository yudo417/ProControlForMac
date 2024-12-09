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

            print("X:"+(newValue[0] > 0 ? " " : "")+String(format: "%0.8f", newValue[0])+" Y:"+(newValue[1] >= 0 ? " " : "")+String(format: "%0.8f", newValue[1])+String(Nowposition.x)+String(Nowposition.y))
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
}
