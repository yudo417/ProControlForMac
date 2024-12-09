//
//  ProControlerForMacApp.swift
//  ProControlerForMac
//
//  Created by 林　一貴 on 2024/12/10.
//

import SwiftUI

@main
struct ProControlerForMacApp: App {
    @StateObject private var controllerHandler = ControllerMonitor()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(controllerHandler)
        }
    }
}
