//
//  ProcessingWindow.swift
//  MACocr
//
//  Created on 2025-10-31.
//

import SwiftUI
import AppKit

class ProcessingWindow: NSWindow {
    private var hostingView: NSHostingView<ProcessingView>?
    private let viewModel = ProcessingViewModel()
    
    override init(
        contentRect: NSRect,
        styleMask: NSWindow.StyleMask,
        backing: NSWindow.BackingStoreType,
        defer flag: Bool
    ) {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 300),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "处理中"
        self.center()
        self.isReleasedWhenClosed = false
        
        let processingView = ProcessingView(viewModel: viewModel)
        let hostingView = NSHostingView(rootView: processingView)
        self.contentView = hostingView
        self.hostingView = hostingView
        
        // 设置窗口层级，确保显示在最前
        self.level = .floating
    }
    
    func show() {
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func updateStatus(_ status: String) {
        viewModel.status = status
    }
    
    func updateProgress(_ progress: Double) {
        viewModel.progress = progress
    }
    
    func showError(_ message: String) {
        viewModel.errorMessage = message
        viewModel.isProcessing = false
    }
    
    func showResult(_ text: String) {
        DispatchQueue.main.async {
            self.close()
            let resultWindow = ResultWindow(text: text)
            resultWindow.show()
        }
    }
}

class ProcessingViewModel: ObservableObject {
    @Published var status: String = "正在准备..."
    @Published var progress: Double = 0.0
    @Published var isProcessing: Bool = true
    @Published var errorMessage: String? = nil
}

struct ProcessingView: View {
    @ObservedObject var viewModel: ProcessingViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            // 图标
            if viewModel.isProcessing {
                Image(systemName: "text.viewfinder")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                    .symbolEffect(.pulse, options: .repeating)
            } else if viewModel.errorMessage != nil {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)
            }
            
            // 状态信息
            VStack(spacing: 12) {
                if viewModel.isProcessing {
                    Text(viewModel.status)
                        .font(.headline)
                    
                    ProgressView(value: viewModel.progress, total: 1.0)
                        .progressViewStyle(.linear)
                        .frame(width: 300)
                    
                    Text("请稍候...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else if let errorMessage = viewModel.errorMessage {
                    Text("处理失败")
                        .font(.headline)
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button("关闭") {
                        NSApp.keyWindow?.close()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            
            if viewModel.isProcessing {
                Button("取消") {
                    NSApp.keyWindow?.close()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(40)
        .frame(width: 500, height: 300)
    }
}

#Preview {
    ProcessingView(viewModel: ProcessingViewModel())
}
