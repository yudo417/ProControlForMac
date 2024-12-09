import SwiftUI
import GameController





struct ContentView: View {
    @EnvironmentObject var controllerMonitor: ControllerMonitor

    var body: some View {
        VStack {
            Text("Button A: \(controllerMonitor.buttonA ? "Pressed" : "Released")")
            Text("Left Stick: X = \(controllerMonitor.leftStick.x), Y = \(controllerMonitor.leftStick.y)")
        }
        .padding()
    }
}

#Preview{
    ContentView()
        .environmentObject(ControllerMonitor())
}
