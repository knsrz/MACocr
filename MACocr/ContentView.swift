//
//  ContentView.swift
//  MACocr
//
//  Created on 2025-10-30.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var configManager: ConfigurationManager
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.viewfinder")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("MACocr")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("macOS 截图 OCR 工具")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 12) {
                Label("使用菜单栏图标快速截图", systemImage: "menubar.rectangle")
                Label("支持全局快捷键 ⇧⌘5", systemImage: "command")
                Label("自动识别文字并复制", systemImage: "doc.on.clipboard")
            }
            .font(.body)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(10)
            
            Spacer()
            
            HStack {
                Button("设置") {
                    showingSettings = true
                }
                .buttonStyle(.bordered)
                
                Button("开始截图") {
                    ScreenshotCapture().captureScreenshot()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(30)
        .frame(width: 400, height: 500)
        .sheet(isPresented: $showingSettings) {
            SettingsView()
                .environmentObject(configManager)
                .interactiveDismissDisabled(false)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ConfigurationManager.shared)
}
