//
//  ResultWindow.swift
//  MACocr
//
//  Created on 2025-10-30.
//

import SwiftUI
import AppKit

class ResultWindow: NSWindow {
    private var hostingView: NSHostingView<ResultView>?
    
    init(text: String) {
        let contentRect = NSRect(x: 0, y: 0, width: 600, height: 400)
        
        super.init(
            contentRect: contentRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        self.title = "OCR 识别结果"
        self.center()
        self.isReleasedWhenClosed = false
        
        let resultView = ResultView(text: text, window: self)
        let hostingView = NSHostingView(rootView: resultView)
        self.contentView = hostingView
        self.hostingView = hostingView
        
        // 设置窗口层级，确保显示在最前
        self.level = .floating
    }
    
    func show() {
        self.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}

struct ResultView: View {
    let text: String
    weak var window: NSWindow?
    @State private var editedText: String
    @State private var showingCopiedAlert = false
    
    init(text: String, window: NSWindow?) {
        self.text = text
        self.window = window
        _editedText = State(initialValue: text)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Image(systemName: "text.viewfinder")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("识别结果")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if showingCopiedAlert {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("已复制")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .transition(.opacity)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 文本编辑区域
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("识别的文字内容：")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(editedText.count) 字符")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                TextEditor(text: $editedText)
                    .font(.body)
                    .border(Color.gray.opacity(0.3), width: 1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .padding()
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("清空") {
                    editedText = ""
                }
                .buttonStyle(.bordered)
                
                Button("重置") {
                    editedText = text
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("复制到剪贴板") {
                    copyToClipboard()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
                
                Button("关闭") {
                    window?.close()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(minWidth: 400, minHeight: 300)
    }
    
    private func copyToClipboard() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(editedText, forType: .string)
        
        withAnimation {
            showingCopiedAlert = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showingCopiedAlert = false
            }
        }
    }
}

#Preview {
    ResultView(text: "这是一段示例文本\n用于预览识别结果窗口", window: nil)
}
