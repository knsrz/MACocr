//
//  APIService.swift
//  MACocr
//
//  Created on 2025-10-30.
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case networkError(Error)
    case decodingError
    case apiError(String)
    case rateLimitExceeded
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 API 地址"
        case .invalidResponse:
            return "服务器返回无效响应"
        case .networkError(let error):
            return "网络错误：\(error.localizedDescription)"
        case .decodingError:
            return "数据解析失败"
        case .apiError(let message):
            return "API 错误：\(message)"
        case .rateLimitExceeded:
            return "请求频率超限，请稍后重试"
        case .unauthorized:
            return "API 密钥无效或未授权"
        }
    }
}

class APIService {
    static let shared = APIService()
    
    private let session: URLSession
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    private init() {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 60
        configuration.timeoutIntervalForResource = 300
        self.session = URLSession(configuration: configuration)
    }
    
    func performOCR(imageBase64: String, config: OCRConfiguration) async throws -> String {
        var lastError: Error?
        
        for attempt in 1...maxRetries {
            do {
                return try await executeOCRRequest(imageBase64: imageBase64, config: config)
            } catch APIError.rateLimitExceeded {
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * Double(attempt) * 1_000_000_000))
                    continue
                }
                throw APIError.rateLimitExceeded
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    continue
                }
            }
        }
        
        throw lastError ?? APIError.invalidResponse
    }
    
    private func executeOCRRequest(imageBase64: String, config: OCRConfiguration) async throws -> String {
        guard let url = URL(string: config.endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // 构建请求
        switch config.provider {
        case .openai, .deepseek:
            return try await handleOpenAIStyleRequest(request: &request, imageBase64: imageBase64, config: config)
        case .anthropic:
            return try await handleAnthropicRequest(request: &request, imageBase64: imageBase64, config: config)
        case .baidu:
            return try await handleBaiduRequest(request: &request, imageBase64: imageBase64, config: config)
        case .custom:
            return try await handleOpenAIStyleRequest(request: &request, imageBase64: imageBase64, config: config)
        }
    }
    
    // MARK: - OpenAI Style API (OpenAI, DeepSeek, Custom)
    
    private func handleOpenAIStyleRequest(request: inout URLRequest, imageBase64: String, config: OCRConfiguration) async throws -> String {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        let payload: [String: Any] = [
            "model": config.model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": config.prompt],
                        ["type": "image_url", "image_url": ["url": "data:image/png;base64,\(imageBase64)"]]
                    ]
                ]
            ],
            "max_tokens": config.maxTokens
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response, data: data)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any] else {
            throw APIError.decodingError
        }

        if let contentString = message["content"] as? String {
            return contentString.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if let contentArray = message["content"] as? [[String: Any]] {
            let extractedText = contentArray.compactMap { item -> String? in
                if let text = item["text"] as? String {
                    return text
                }

                if let text = item["content"] as? String {
                    return text
                }

                // 一些服务商会使用 "output_text" 或类似的类型标记
                if let type = item["type"] as? String,
                   type == "output_text",
                   let text = item["text"] as? String ?? item["content"] as? String {
                    return text
                }

                return nil
            }

            if !extractedText.isEmpty {
                return extractedText
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        throw APIError.decodingError
    }
    
    // MARK: - Anthropic API
    
    private func handleAnthropicRequest(request: inout URLRequest, imageBase64: String, config: OCRConfiguration) async throws -> String {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let payload: [String: Any] = [
            "model": config.model,
            "max_tokens": config.maxTokens,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/png",
                                "data": imageBase64
                            ]
                        ],
                        ["type": "text", "text": config.prompt]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response, data: data)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]] else {
            throw APIError.decodingError
        }

        let extractedText = content.compactMap { item -> String? in
            if let text = item["text"] as? String {
                return text
            }
            return nil
        }

        guard !extractedText.isEmpty else {
            throw APIError.decodingError
        }

        return extractedText
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Baidu API
    
    private func handleBaiduRequest(request: inout URLRequest, imageBase64: String, config: OCRConfiguration) async throws -> String {
        // Baidu API 需要在 URL 中添加 access_token
        guard var urlComponents = URLComponents(string: config.endpoint) else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "access_token", value: config.apiKey)]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        request.url = url
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": config.prompt],
                        ["type": "image_url", "image_url": ["url": "data:image/png;base64,\(imageBase64)"]]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response, data: data)
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? String else {
            throw APIError.decodingError
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Test Connection
    
    func testConnection(config: OCRConfiguration) async throws -> String {
        // 使用一个真实生成的有效PNG图片（100x100像素，包含简单蓝色方块）
        // 使用 Python PIL 生成的标准 PNG 格式，确保被所有 API 提供商接受
        // 100x100 = 10000 像素，满足最小尺寸要求
        let testImageBase64 = "iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAIAAAD/gAIDAAABGElEQVR4nO3cwQlCMRBAQSM2YQf2Y532YweWEQ+eBZ+RL+LMPSE89hbYMefc8Zr9tx/wS8QKxArECsQKxArECsQKxArECsQKxArECsQKxArECsQKxArECg4rh8f41DM29favg8kKlibr4XK9rV+yjfPpuHLcZAViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWIFYgViBWNlxbn1Kjy1tF7l3/bum6xArECsQKxArECsQKxArECsQKxArECsQKxArECsQKxArECs4A7r9w/FqL3ZpQAAAABJRU5ErkJggg=="
        
        guard let url = URL(string: config.endpoint) else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 10 // 测试连接使用较短的超时时间
        
        // 构建请求
        switch config.provider {
        case .openai, .deepseek, .custom:
            return try await testOpenAIStyleConnection(request: &request, imageBase64: testImageBase64, config: config)
        case .anthropic:
            return try await testAnthropicConnection(request: &request, imageBase64: testImageBase64, config: config)
        case .baidu:
            return try await testBaiduConnection(request: &request, imageBase64: testImageBase64, config: config)
        }
    }
    
    private func testOpenAIStyleConnection(request: inout URLRequest, imageBase64: String, config: OCRConfiguration) async throws -> String {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        
        let payload: [String: Any] = [
            "model": config.model,
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": "测试"],
                        ["type": "image_url", "image_url": ["url": "data:image/png;base64,\(imageBase64)"]]
                    ]
                ]
            ],
            "max_tokens": 50  // 使用 50 tokens 进行测试（满足最小 16 的要求）
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        
        // validateResponse 会自动处理所有错误情况
        try validateResponse(response, data: data)
        
        // 验证响应格式是否正确（确保有有效的响应结构）
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              !choices.isEmpty else {
            // 如果结构不对，打印响应内容以便调试
            if let dataString = String(data: data, encoding: .utf8) {
                throw APIError.apiError("响应格式无效。响应内容: \(dataString)")
            }
            throw APIError.decodingError
        }
        
        return "连接成功！API 配置有效。"
    }
    
    private func testAnthropicConnection(request: inout URLRequest, imageBase64: String, config: OCRConfiguration) async throws -> String {
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(config.apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        let payload: [String: Any] = [
            "model": config.model,
            "max_tokens": 50,  // 使用 50 tokens 进行测试
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "image",
                            "source": [
                                "type": "base64",
                                "media_type": "image/png",
                                "data": imageBase64
                            ]
                        ],
                        ["type": "text", "text": "测试"]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        
        // validateResponse 会自动处理所有错误情况
        try validateResponse(response, data: data)
        
        // 验证响应格式是否正确
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              !content.isEmpty else {
            if let dataString = String(data: data, encoding: .utf8) {
                throw APIError.apiError("响应格式无效。响应内容: \(dataString)")
            }
            throw APIError.decodingError
        }
        
        return "连接成功！API 配置有效。"
    }
    
    private func testBaiduConnection(request: inout URLRequest, imageBase64: String, config: OCRConfiguration) async throws -> String {
        guard var urlComponents = URLComponents(string: config.endpoint) else {
            throw APIError.invalidURL
        }
        
        urlComponents.queryItems = [URLQueryItem(name: "access_token", value: config.apiKey)]
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        request.url = url
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let payload: [String: Any] = [
            "messages": [
                [
                    "role": "user",
                    "content": [
                        ["type": "text", "text": "测试"],
                        ["type": "image_url", "image_url": ["url": "data:image/png;base64,\(imageBase64)"]]
                    ]
                ]
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        
        // validateResponse 会自动处理所有错误情况
        try validateResponse(response, data: data)
        
        // 百度 API 特殊处理：即使 HTTP 200 也可能有错误
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let errorCode = json["error_code"] as? Int,
           errorCode != 0 {
            let errorMsg = json["error_msg"] as? String ?? "未知错误"
            throw APIError.apiError("百度 API 错误 (\(errorCode)): \(errorMsg)")
        }
        
        return "连接成功！API 配置有效。"
    }
    
    // MARK: - Helper Methods
    
    private func validateResponse(_ response: URLResponse, data: Data? = nil) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw APIError.unauthorized
        case 429:
            throw APIError.rateLimitExceeded
        default:
            // 尝试解析错误响应中的详细信息
            var errorMessage = "HTTP \(httpResponse.statusCode)"
            var errorDetails: [String] = []
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // OpenAI/OpenRouter 风格的错误格式
                if let error = json["error"] as? [String: Any] {
                    if let message = error["message"] as? String {
                        errorMessage = message
                    }
                    // 获取额外的错误详情
                    if let code = error["code"] as? String {
                        errorDetails.append("错误码: \(code)")
                    }
                    if let type = error["type"] as? String {
                        errorDetails.append("类型: \(type)")
                    }
                    // OpenRouter 特定的 metadata
                    if let metadata = error["metadata"] as? [String: Any] {
                        if let providerName = metadata["provider_name"] as? String {
                            errorDetails.append("提供商: \(providerName)")
                        }
                        if let raw = metadata["raw"] as? String {
                            errorDetails.append("原始错误: \(raw)")
                        }
                    }
                }
                // 或者直接在顶层的 error 字段
                else if let error = json["error"] as? String {
                    errorMessage = error
                }
                // 或者 message 字段
                else if let message = json["message"] as? String {
                    errorMessage = message
                }
                
                // 如果有额外的详情，添加到错误消息中
                if !errorDetails.isEmpty {
                    errorMessage += "\n" + errorDetails.joined(separator: "\n")
                }
                
                // 如果还是没有获取到有用信息，尝试将整个 JSON 转换为字符串
                if errorMessage == "HTTP \(httpResponse.statusCode)",
                   let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted),
                   let jsonString = String(data: jsonData, encoding: .utf8) {
                    errorMessage += "\n响应内容: \(jsonString)"
                }
            }
            
            throw APIError.apiError(errorMessage)
        }
    }
}
