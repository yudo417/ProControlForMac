import SwiftUI
import GameController

class ControllerMonitor: ObservableObject {
    @Published var buttonA: Bool = false
    @Published var leftStick: (x: Float, y: Float) = (0.0, 0.0)

    init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(controllerDidConnect),
            name: .GCControllerDidConnect,
            object: nil
        )
//        GCController.startWirelessControllerDiscovery()
    }

    @objc func controllerDidConnect(notification: Notification) {
        let _ = print("connected")
        guard let controller = notification.object as? GCController else { return }
        if let gamepad = controller.extendedGamepad {
            gamepad.valueChangedHandler = { [weak self] gamepad, element in
                guard let self = self else { return }
                
                if element == gamepad.buttonA {
                    self.buttonA = gamepad.buttonA.isPressed
                }
                if element == gamepad.leftThumbstick {
                    self.leftStick = (gamepad.leftThumbstick.xAxis.value, gamepad.leftThumbstick.yAxis.value)
                }
            }
        }
    }
}
