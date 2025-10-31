//
//  SettingsView.swift
//  MACocr
//
//  Created on 2025-10-30.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var configManager: ConfigurationManager
    @State private var config: OCRConfiguration
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var shouldDismissAfterAlert = false
    
    init() {
        _config = State(initialValue: ConfigurationManager.shared.currentConfig)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text("设置")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("关闭设置")
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // 设置内容
            Form {
                Section {
                    Picker("API 提供商", selection: $config.provider) {
                        ForEach(APIProvider.allCases, id: \.self) { provider in
                            Text(provider.rawValue).tag(provider)
                        }
                    }
                    .onChange(of: config.provider) { newProvider in
                        config.endpoint = newProvider.defaultEndpoint
                        config.model = newProvider.defaultModel
                    }
                } header: {
                    Text("API 配置")
                        .font(.headline)
                }
                
                Section {
                    SecureField("API 密钥", text: $config.apiKey)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("API 端点", text: $config.endpoint)
                        .textFieldStyle(.roundedBorder)
                    
                    TextField("模型名称", text: $config.model)
                        .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Text("最大 Token 数")
                        Spacer()
                        TextField("", value: $config.maxTokens, format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 100)
                    }
                } header: {
                    Text("详细配置")
                        .font(.headline)
                }
                
                Section {
                    Text("自定义提示词")
                        .font(.headline)
                    
                    TextEditor(text: $config.prompt)
                        .frame(height: 100)
                        .font(.body)
                        .border(Color.gray.opacity(0.3), width: 1)
                    
                    Button("重置为默认提示词") {
                        config.prompt = OCRConfiguration.defaultPrompt
                    }
                    .buttonStyle(.bordered)
                } header: {
                    Text("OCR 提示")
                        .font(.headline)
                }
            }
            .formStyle(.grouped)
            .padding()
            
            Divider()
            
            // 底部按钮
            HStack {
                Button("取消") {
                    dismiss()
                }
                .buttonStyle(.bordered)
                .keyboardShortcut(.cancelAction)
                
                Button("重置所有设置") {
                    config = .default
                }
                .buttonStyle(.bordered)
                
                Spacer()
                
                Button("测试连接") {
                    testConfiguration()
                }
                .buttonStyle(.bordered)
                
                Button("保存") {
                    saveConfiguration()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
        .alert("提示", isPresented: $showingAlert) {
            Button("确定", role: .cancel) {
                if shouldDismissAfterAlert {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func saveConfiguration() {
        guard !config.apiKey.isEmpty else {
            alertMessage = "请填写 API 密钥"
            shouldDismissAfterAlert = false
            showingAlert = true
            return
        }
        
        guard !config.endpoint.isEmpty else {
            alertMessage = "请填写 API 端点"
            shouldDismissAfterAlert = false
            showingAlert = true
            return
        }
        
        guard !config.model.isEmpty else {
            alertMessage = "请填写模型名称"
            shouldDismissAfterAlert = false
            showingAlert = true
            return
        }
        
        configManager.currentConfig = config
        alertMessage = "配置已保存"
        shouldDismissAfterAlert = true
        showingAlert = true
    }
    
    private func testConfiguration() {
        // 验证必填字段
        if config.apiKey.isEmpty {
            alertMessage = "请先填写 API 密钥"
            showingAlert = true
            return
        }
        
        if config.endpoint.isEmpty {
            alertMessage = "请先填写 API 端点"
            showingAlert = true
            return
        }
        
        if config.model.isEmpty {
            alertMessage = "请先填写模型名称"
            showingAlert = true
            return
        }
        
        Task {
            do {
                // 调用实际的 API 测试
                let result = try await APIService.shared.testConnection(config: config)
                await MainActor.run {
                    alertMessage = result
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "连接测试失败：\(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ConfigurationManager.shared)
}
