//
//  ConfigurationManager.swift
//  MACocr
//
//  Created on 2025-10-30.
//

import Foundation
import Combine

/// API 提供商枚举
enum APIProvider: String, CaseIterable, Codable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case deepseek = "DeepSeek"
    case baidu = "Baidu"
    case custom = "自定义"
    
    var defaultEndpoint: String {
        switch self {
        case .openai:
            return "https://api.openai.com/v1/chat/completions"
        case .anthropic:
            return "https://api.anthropic.com/v1/messages"
        case .deepseek:
            return "https://api.deepseek.com/v1/chat/completions"
        case .baidu:
            return "https://aip.baidubce.com/rpc/2.0/ai_custom/v1/wenxinworkshop/chat/completions"
        case .custom:
            return ""
        }
    }
    
    var defaultModel: String {
        switch self {
        case .openai:
            return "gpt-4o"
        case .anthropic:
            return "claude-3-5-sonnet-20241022"
        case .deepseek:
            return "deepseek-chat"
        case .baidu:
            return "ernie-4.0-turbo-8k"
        case .custom:
            return ""
        }
    }
}

/// OCR 配置模型
struct OCRConfiguration: Codable {
    var provider: APIProvider
    var apiKey: String
    var endpoint: String
    var model: String
    var maxTokens: Int
    var prompt: String
    
    static let defaultPrompt = "请提取图片中的所有文字内容，保持原有的格式和排版。只返回识别出的文字，不要添加任何额外的解释或说明。"
    
    static var `default`: OCRConfiguration {
        OCRConfiguration(
            provider: .openai,
            apiKey: "",
            endpoint: APIProvider.openai.defaultEndpoint,
            model: APIProvider.openai.defaultModel,
            maxTokens: 4096,
            prompt: defaultPrompt
        )
    }
}

/// 配置管理器
class ConfigurationManager: ObservableObject {
    static let shared = ConfigurationManager()
    
    @Published var currentConfig: OCRConfiguration {
        didSet {
            saveConfiguration()
        }
    }
    
    private let configKey = "OCRConfiguration"
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: configKey),
           let config = try? JSONDecoder().decode(OCRConfiguration.self, from: data) {
            self.currentConfig = config
        } else {
            self.currentConfig = .default
        }
    }
    
    func saveConfiguration() {
        if let data = try? JSONEncoder().encode(currentConfig) {
            UserDefaults.standard.set(data, forKey: configKey)
        }
    }
    
    func resetToDefaults() {
        currentConfig = .default
    }
    
    func validateConfiguration() -> Bool {
        guard !currentConfig.apiKey.isEmpty else { return false }
        guard !currentConfig.endpoint.isEmpty else { return false }
        guard !currentConfig.model.isEmpty else { return false }
        return true
    }
}
