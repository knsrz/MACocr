//
//  LoadingIndicator.swift
//  MACocr
//
//  Created on 2025-10-30.
//

import SwiftUI

struct LoadingIndicatorView: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle())
            
            Text("正在识别文字...")
                .font(.headline)
            
            Text("请稍候")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(radius: 10)
        )
    }
}

class LoadingWindow: NSWindow {
    private var hostingView: NSHostingView<LoadingIndicatorView>?
    
    init() {
        let contentRect = NSRect(x: 0, y: 0, width: 200, height: 150)
        
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = .clear
        self.center()
        self.level = .floating
        self.isReleasedWhenClosed = false
        
        let loadingView = LoadingIndicatorView()
        let hostingView = NSHostingView(rootView: loadingView)
        hostingView.layer?.backgroundColor = .clear
        self.contentView = hostingView
        self.hostingView = hostingView
    }
    
    func show() {
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hide() {
        self.orderOut(nil)
    }
}

#Preview {
    LoadingIndicatorView()
}
