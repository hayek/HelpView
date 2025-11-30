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
    #if os(macOS) || os(visionOS)
    @Environment(\.openWindow) private var openWindow
    #endif

    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        #if os(macOS) || os(visionOS)
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
        #endif
    }
}
