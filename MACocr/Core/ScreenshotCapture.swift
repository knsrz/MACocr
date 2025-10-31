//
//  ScreenshotCapture.swift
//  MACocr
//
//  Created on 2025-10-30.
//

import Cocoa
import Carbon
import SwiftUI

class ScreenshotCapture: NSObject, @unchecked Sendable {
    private var eventHandler: EventHandlerRef?
    private var hotKeyID = EventHotKeyID(signature: FourCharCode("ocr ") ?? 0x6F637220, id: 1)
    
    /// 注册全局快捷键 (Shift + Command + 5)
    func registerGlobalHotkey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        
        InstallEventHandler(GetApplicationEventTarget(), { (nextHandler, theEvent, userData) -> OSStatus in
            var hotKeyID = EventHotKeyID()
            GetEventParameter(theEvent,
                            EventParamName(kEventParamDirectObject),
                            EventParamType(typeEventHotKeyID),
                            nil,
                            MemoryLayout<EventHotKeyID>.size,
                            nil,
                            &hotKeyID)
            
            if let capture = Unmanaged<ScreenshotCapture>.fromOpaque(userData!).takeUnretainedValue() as ScreenshotCapture? {
                DispatchQueue.main.async {
                    capture.captureScreenshot()
                }
            }
            
            return noErr
        }, 1, &eventType, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        
        var hotKeyRef: EventHotKeyRef?
        let modifiers = UInt32(shiftKey | cmdKey)
        RegisterEventHotKey(UInt32(kVK_ANSI_5), modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
    
    /// 执行截图
    func captureScreenshot() {
        // 隐藏所有窗口以便截图
        NSApp.hide(nil)
        
        // 延迟一小段时间让窗口完全隐藏
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.performScreenCapture()
        }
    }
    
    private func performScreenCapture() {
        let task = Process()
        task.launchPath = "/usr/sbin/screencapture"
        task.arguments = ["-i", "-c"] // -i: 交互式截图, -c: 复制到剪贴板
        
        task.terminationHandler = { [weak self] process in
            if process.terminationStatus == 0 {
                DispatchQueue.main.async {
                    self?.processScreenshot()
                }
            }
        }
        
        task.launch()
    }
    
    private func processScreenshot() {
        // 从剪贴板获取图像
        let pasteboard = NSPasteboard.general
        
        guard let imageData = pasteboard.data(forType: .tiff),
              let image = NSImage(data: imageData) else {
            showAlert(title: "错误", message: "无法获取截图数据")
            return
        }
        
        // 转换为 PNG 并进行 Base64 编码
        guard let pngData = image.pngData(),
              let base64String = pngData.base64EncodedString() as String? else {
            showAlert(title: "错误", message: "图像转换失败")
            return
        }
        
        // 调用 API 进行 OCR
        performOCR(with: base64String)
    }
    
    private func performOCR(with base64Image: String) {
        let apiService = APIService.shared
        let config = ConfigurationManager.shared.currentConfig
        
        // 显示加载提示
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .ocrStarted, object: nil)
        }
        
        Task {
            do {
                let result = try await apiService.performOCR(
                    imageBase64: base64Image,
                    config: config
                )
                
                DispatchQueue.main.async {
                    self.handleOCRResult(result)
                }
            } catch {
                DispatchQueue.main.async {
                    self.showAlert(title: "OCR 失败", message: error.localizedDescription)
                    NotificationCenter.default.post(name: .ocrCompleted, object: nil)
                }
            }
        }
    }
    
    private func handleOCRResult(_ text: String) {
        // 复制到剪贴板
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // 显示结果窗口
        let resultWindow = ResultWindow(text: text)
        resultWindow.show()
        
        NotificationCenter.default.post(name: .ocrCompleted, object: text)
    }
    
    private func showAlert(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "确定")
        alert.runModal()
    }
}

// MARK: - NSImage Extension
extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapImage.representation(using: .png, properties: [:])
    }
}

// MARK: - Notifications
extension Notification.Name {
    static let ocrStarted = Notification.Name("ocrStarted")
    static let ocrCompleted = Notification.Name("ocrCompleted")
}
