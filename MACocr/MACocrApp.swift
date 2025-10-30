//
//  MACocrApp.swift
//  MACocr
//
//  Created on 2025-10-30.
//

import SwiftUI

@main
struct MACocrApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var configManager = ConfigurationManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(configManager)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("关于 MACocr") {
                    NSApplication.shared.orderFrontStandardAboutPanel(
                        options: [
                            NSApplication.AboutPanelOptionKey.credits: NSAttributedString(
                                string: "macOS 截图 OCR 工具",
                                attributes: [NSAttributedString.Key.font: NSFont.systemFont(ofSize: 11)]
                            ),
                            NSApplication.AboutPanelOptionKey.applicationVersion: "1.0.0"
                        ]
                    )
                }
            }
        }
        
        Settings {
            SettingsView()
                .environmentObject(configManager)
        }
    }
}
