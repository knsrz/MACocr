# MACocr 开发文档

## 开发环境设置

### 必需工具
- Xcode 15.0+
- macOS 13.0+
- Swift 5.9+

### 项目配置

1. 打开 `MACocr.xcodeproj`
2. 设置开发团队（Signing & Capabilities）
3. 配置 Bundle Identifier

## 架构设计

### MVVM 模式

```
View (SwiftUI) → ViewModel → Model → Service
```

### 核心组件

#### 1. ScreenshotCapture
负责截图捕获和快捷键注册

**主要方法：**
- `registerGlobalHotkey()` - 注册全局快捷键
- `captureScreenshot()` - 执行截图
- `performOCR(with:)` - 调用 OCR 服务

#### 2. ConfigurationManager
管理应用配置和持久化

**主要属性：**
- `currentConfig: OCRConfiguration` - 当前配置
- `saveConfiguration()` - 保存配置
- `validateConfiguration()` - 验证配置

#### 3. APIService
处理所有 API 调用

**支持的提供商：**
- OpenAI
- Anthropic
- DeepSeek
- Baidu
- 自定义

**主要方法：**
- `performOCR(imageBase64:config:)` - 执行 OCR
- `handleOpenAIStyleRequest()` - OpenAI 风格 API
- `handleAnthropicRequest()` - Anthropic API
- `handleBaiduRequest()` - Baidu API

## 添加新的 API 提供商

### 步骤

1. **在 ConfigurationManager.swift 中添加枚举值**

```swift
enum APIProvider: String, CaseIterable, Codable {
    case openai = "OpenAI"
    case anthropic = "Anthropic"
    case deepseek = "DeepSeek"
    case baidu = "Baidu"
    case newProvider = "New Provider"  // 新增
    case custom = "自定义"
    
    var defaultEndpoint: String {
        switch self {
        case .newProvider:
            return "https://api.newprovider.com/v1/endpoint"
        // ...
        }
    }
    
    var defaultModel: String {
        switch self {
        case .newProvider:
            return "model-name"
        // ...
        }
    }
}
```

2. **在 APIService.swift 中实现处理方法**

```swift
private func executeOCRRequest(imageBase64: String, config: OCRConfiguration) async throws -> String {
    // ...
    switch config.provider {
    case .newProvider:
        return try await handleNewProviderRequest(request: &request, imageBase64: imageBase64, config: config)
    // ...
    }
}

private func handleNewProviderRequest(request: inout URLRequest, imageBase64: String, config: OCRConfiguration) async throws -> String {
    // 设置请求头
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
    
    // 构建请求体
    let payload: [String: Any] = [
        // 根据提供商的 API 格式构建
    ]
    
    request.httpBody = try JSONSerialization.data(withJSONObject: payload)
    
    // 发送请求
    let (data, response) = try await session.data(for: request)
    
    // 验证响应
    try validateResponse(response)
    
    // 解析响应
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let result = json["result"] as? String else {
        throw APIError.decodingError
    }
    
    return result.trimmingCharacters(in: .whitespacesAndNewlines)
}
```

## 测试

### 单元测试

```bash
⌘U 或 Product → Test
```

### 手动测试清单

- [ ] 截图功能
- [ ] 快捷键触发
- [ ] API 调用
- [ ] 配置保存
- [ ] 结果显示
- [ ] 剪贴板操作
- [ ] 错误处理

## 调试技巧

### 打印 API 请求

在 `APIService.swift` 中添加：

```swift
print("Request URL: \(request.url?.absoluteString ?? "")")
print("Request Headers: \(request.allHTTPHeaderFields ?? [:])")
if let body = request.httpBody, let bodyString = String(data: body, encoding: .utf8) {
    print("Request Body: \(bodyString)")
}
```

### 查看配置

```swift
print(ConfigurationManager.shared.currentConfig)
```

## 发布

### 构建 Release 版本

**方式一：命令行脚本（推荐）**

```bash
./scripts/build-release.sh
```

脚本会在 `artifacts/` 目录生成 `MACocr.app` 与 `MACocr-Release.zip`，方便上传 GitHub Releases。

**方式二：Xcode GUI**

1. 选择 Product → Archive
2. 在 Organizer 中选择 Distribute App
3. 选择发布方式（Developer ID, Mac App Store, etc.）

### CI 构建

- `.github/workflows/build-macos.yml` 会在 Push/PR/Release 时自动构建 Release 版本
- 构建完成后可在 Actions 页面下载 `MACocr.app` 与 `MACocr-Release.zip`

### 代码签名

确保在 Signing & Capabilities 中：
- 启用 Hardened Runtime
- 配置必要的 Entitlements
- 选择正确的证书

## 常见问题

### Q: 为什么截图功能不工作？
A: 检查是否已授予屏幕录制权限（系统偏好设置 → 隐私与安全性 → 屏幕录制）

### Q: 如何调试网络请求？
A: 使用 Charles 或 Proxyman 等工具监控 HTTPS 请求

### Q: 如何自定义快捷键？
A: 修改 `ScreenshotCapture.swift` 中的 `kVK_ANSI_5` 和 modifiers

## 贡献代码

1. 遵循 Swift 编码规范
2. 添加必要的注释
3. 确保代码通过编译
4. 测试所有功能
5. 提交 PR 前 rebase 到最新代码

## 资源链接

- [Swift 官方文档](https://docs.swift.org)
- [SwiftUI 教程](https://developer.apple.com/tutorials/swiftui)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Xcode 帮助](https://developer.apple.com/documentation/xcode)
