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
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw APIError.decodingError
        }
        
        return content.trimmingCharacters(in: .whitespacesAndNewlines)
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
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw APIError.decodingError
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
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
        // 使用一个足够大的测试图片（50x50像素的白色PNG图片）
        // 满足大多数 API 的最小尺寸要求（如 OpenRouter/Grok 的 512 像素总像素数要求）
        // 50x50 = 2500 像素，远大于 512 像素的最小要求
        let testImageBase64 = """
        iVBORw0KGgoAAAANSUhEUgAAADIAAAAyCAYAAAAeP4ixAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAOxAAADsQBlSsOGwAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAAEISURBVGiB7doxCsJAFATQiWKhpYKVYGHvCTyBR/AU3sAT2HsET2BvY6GVhYKVhYWCCIKFhYWFfxCEQMD9m80uLLwmy5eZ7IeQJEmSJEmSJEmSJEmSJEmSJElS/zXAHJgDI+C4a6MT4AzcgSewBRZAWrvoD9NKgxMw/1HzApyBNbAENkC2X9kvpsCDfHFf5uQW1SBJzZLUrEjNmtQsSc2K1KxJzZLUrEjNmtQsSc2K1KxJzZLUrEjNmtQsSc2K1KxJzZLUrEjNmtQsSc2K1KxJzZLUrEjNmtQsSc2K1KxJzZLUrEjNmtQsSc2K1KxJzZLUrEjNmtQsSc2K1KxJzZLUrEjNmiRJkiRJkiRJkiRJUrd9AXwONfvE8yWJAAAAAElFTkSuQmCC
        """
        
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
            "max_tokens": 10
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        
        let (data, response) = try await session.data(for: request)
        
        try validateResponse(response, data: data)
        
        // 验证响应格式是否正确
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingError
        }
        
        // 检查是否有错误信息
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw APIError.apiError(message)
        }
        
        // 验证响应结构
        guard let choices = json["choices"] as? [[String: Any]],
              !choices.isEmpty else {
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
            "max_tokens": 10,
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
        
        try validateResponse(response, data: data)
        
        // 验证响应格式是否正确
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingError
        }
        
        // 检查是否有错误信息
        if let error = json["error"] as? [String: Any],
           let message = error["message"] as? String {
            throw APIError.apiError(message)
        }
        
        // 验证响应结构
        guard let content = json["content"] as? [[String: Any]],
              !content.isEmpty else {
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
        
        try validateResponse(response, data: data)
        
        // 验证响应格式是否正确
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.decodingError
        }
        
        // 检查是否有错误信息
        if let errorCode = json["error_code"] as? Int,
           errorCode != 0,
           let errorMsg = json["error_msg"] as? String {
            throw APIError.apiError(errorMsg)
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
            
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // OpenAI/OpenRouter 风格的错误格式
                if let error = json["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorMessage = message
                }
                // 或者直接在顶层的 error 字段
                else if let error = json["error"] as? String {
                    errorMessage = error
                }
                // 或者 message 字段
                else if let message = json["message"] as? String {
                    errorMessage = message
                }
            }
            
            throw APIError.apiError(errorMessage)
        }
    }
}
