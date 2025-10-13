//
//  HelpViewExampleApp.swift
//  HelpViewExample
//
//  Created by Amir hayek on 08/10/2025.
//

import SwiftUI
import HelpView

@main
struct HelpViewExampleApp: App {
    @Environment(\.openWindow) private var openWindow

    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        Window("HelpViewExample Help", id: "help") {
            NavigationStack {
                HelpContentView(named: "app_help")
            }
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("HelpViewExample Help") {
                    openWindow(id: "help")
                }
                .keyboardShortcut("?", modifiers: .command)
            }
        }
        .defaultSize(width: 600, height: 700)
    }
}
