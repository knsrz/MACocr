# MACocr - macOS 截图 OCR 工具

<div align="center">
  <img src="https://img.shields.io/badge/platform-macOS-blue.svg" alt="Platform">
  <img src="https://img.shields.io/badge/Swift-5.9-orange.svg" alt="Swift">
  <img src="https://img.shields.io/badge/macOS-13.0+-green.svg" alt="macOS">
  <img src="https://img.shields.io/badge/license-MIT-lightgrey.svg" alt="License">
</div>

## 📖 项目简介

MACocr 是一款专为 macOS 设计的截图 OCR 工具，通过调用第三方大语言模型（LLM）API 实现强大的文字识别功能。本应用不内置 OCR 功能，而是提供灵活的配置界面，让用户自由选择喜欢的 AI 服务提供商。

## ✨ 核心功能

### 1. 截图模块
- 🖼️ **系统级截图**：支持全屏和区域选择截图
- ⌨️ **全局快捷键**：使用 `⇧⌘5` 快速触发截图
- 📋 **自动识别**：截图后自动调用 API 进行文字识别
- 🎯 **菜单栏集成**：快速访问所有功能

### 2. OCR 配置模块
- 🔧 **多提供商支持**：
  - OpenAI (GPT-4o, GPT-4-Vision)
  - Anthropic (Claude 3.5 Sonnet)
  - DeepSeek (deepseek-chat)
  - Baidu (文心一言)
  - 自定义 API 端点
- 🔑 **灵活配置**：API 密钥、端点 URL、模型名称
- 💾 **持久化存储**：配置自动保存到本地
- ✅ **连接测试**：验证 API 配置是否正确

### 3. API 调用模块
- 🔄 **Base64 编码**：自动将截图转换为 Base64 格式
- 🌐 **HTTP 请求**：支持标准 REST API 调用
- 🔁 **重试机制**：自动处理网络错误和限频（429）
- ⚡ **异步处理**：使用 Swift Concurrency 保证流畅体验

### 4. 结果处理模块
- 📝 **结果展示**：在弹窗中显示识别的文字
- ✏️ **文本编辑**：支持直接编辑识别结果
- 📋 **剪贴板操作**：一键复制到系统剪贴板
- 💡 **实时反馈**：显示字符统计和复制状态

## 🚀 快速开始

### 系统要求

- macOS 13.0 或更高版本
- Xcode 15.0 或更高版本
- Swift 5.9 或更高版本

### 安装步骤

1. **克隆项目**
```bash
git clone https://github.com/yourusername/MACocr.git
cd MACocr
```

2. **打开项目**
```bash
open MACocr.xcodeproj
```

3. **配置签名**
   - 在 Xcode 中选择项目
   - 进入 "Signing & Capabilities"
   - 选择你的开发团队

4. **构建运行**
   - 按 `⌘R` 或点击运行按钮
   - 首次运行需要授予屏幕录制权限

### 首次使用配置

1. **打开设置**
   - 点击菜单栏图标
   - 选择 "设置..." 或使用快捷键 `⌘,`

2. **配置 API**
   - 选择 API 提供商（如 OpenAI）
   - 填写 API 密钥
   - 确认端点 URL 和模型名称
   - 点击 "测试连接" 验证配置
   - 点击 "保存"

3. **开始使用**
   - 使用快捷键 `⇧⌘5` 触发截图
   - 或点击菜单栏图标选择 "开始截图识别"
   - 框选需要识别的区域
   - 等待识别完成

## 📝 使用说明

### 快捷键

- `⇧⌘5` - 触发截图识别
- `⌘,` - 打开设置窗口
- `⌘Q` - 退出应用

### API 配置示例

#### OpenAI
```
提供商: OpenAI
API 密钥: sk-...
端点: https://api.openai.com/v1/chat/completions
模型: gpt-4o
```

#### Anthropic Claude
```
提供商: Anthropic
API 密钥: sk-ant-...
端点: https://api.anthropic.com/v1/messages
模型: claude-3-5-sonnet-20241022
```

#### DeepSeek
```
提供商: DeepSeek
API 密钥: sk-...
端点: https://api.deepseek.com/v1/chat/completions
模型: deepseek-chat
```

### 自定义提示词

默认提示词：
```
请提取图片中的所有文字内容，保持原有的格式和排版。
只返回识别出的文字，不要添加任何额外的解释或说明。
```

你可以根据需要修改提示词，例如：
- 指定识别语言
- 要求特定格式输出
- 添加后处理指令

## 🏗️ 项目结构

```
MACocr/
├── MACocr/
│   ├── Core/                      # 核心功能模块
│   │   ├── ScreenshotCapture.swift    # 截图捕获
│   │   ├── ConfigurationManager.swift # 配置管理
│   │   └── APIService.swift            # API 调用
│   ├── Views/                     # 视图组件
│   │   ├── SettingsView.swift         # 设置界面
│   │   ├── ResultWindow.swift         # 结果窗口
│   │   └── LoadingIndicator.swift     # 加载指示器
│   ├── Assets.xcassets/           # 资源文件
│   ├── MACocrApp.swift            # 应用入口
│   ├── AppDelegate.swift          # 应用代理
│   ├── ContentView.swift          # 主视图
│   ├── Info.plist                 # 应用配置
│   └── MACocr.entitlements        # 权限配置
└── MACocr.xcodeproj/              # Xcode 项目文件
```

## 🔧 技术架构

### 技术栈

- **语言**: Swift 5.9
- **UI 框架**: SwiftUI
- **并发**: Swift Concurrency (async/await)
- **网络**: URLSession
- **存储**: UserDefaults
- **架构模式**: MVVM

### 核心技术

1. **截图捕获**
   - 使用 `screencapture` 系统命令
   - Carbon 框架实现全局快捷键
   - NSPasteboard 处理剪贴板

2. **API 调用**
   - URLSession 异步网络请求
   - JSON 序列化/反序列化
   - Base64 图像编码
   - 错误处理和重试机制

3. **界面设计**
   - SwiftUI 声明式 UI
   - 菜单栏集成 (NSStatusItem)
   - 浮动窗口 (NSWindow)
   - 暗色模式支持

## 🔒 权限说明

应用需要以下系统权限：

- **屏幕录制权限**：用于捕获屏幕截图
- **网络访问权限**：用于调用 API 服务
- **AppleEvents 权限**：用于全局快捷键

首次运行时系统会提示授予这些权限。

## ⚙️ 配置说明

### UserDefaults 键

- `OCRConfiguration` - 存储 OCR 配置信息

### 配置文件位置

```
~/Library/Preferences/com.yourcompany.MACocr.plist
```

## 🐛 故障排除

### 截图无法触发
- 检查是否已授予屏幕录制权限
- 系统偏好设置 → 隐私与安全性 → 屏幕录制

### API 调用失败
- 验证 API 密钥是否正确
- 检查网络连接
- 确认 API 端点 URL 是否正确
- 使用 "测试连接" 功能诊断问题

### 快捷键冲突
- 检查是否有其他应用占用 `⇧⌘5`
- 可以通过菜单栏手动触发截图

## 🚢 发布与打包

我们提供了统一的脚本和 CI 流程，帮助你生成可直接用于 GitHub Releases 的 `MACocr.app`：

### 本地构建 Release 版本

```bash
./scripts/build-release.sh
```

脚本会在根目录生成：

- `artifacts/MACocr.app` – Release 模式编译出的应用包
- `artifacts/MACocr-Release.zip` – 适合上传到 GitHub Releases 的压缩包

> 需要在安装了 Xcode 的 macOS 环境中执行该脚本。

### GitHub Actions 自动构建

仓库内置的 [Build macOS Release](.github/workflows/build-macos.yml) 工作流会在以下场景自动运行：

- 推送到 `main` 分支
- 打开或更新 Pull Request
- 通过 `workflow_dispatch` 手动触发
- 发布新的 Release

工作流会使用 `xcodebuild` 在 GitHub 托管的 macOS Runner 上完成编译，并在构建成功后上传以下产物：

- `MACocr.app`
- `MACocr-Release.zip`

你可以在 Actions 结果页面下载它们并直接用于发布。

## 🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

### 开发流程

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

### 代码规范

- 遵循 Swift API 设计指南
- 使用有意义的变量和函数名
- 添加适当的注释
- 保持代码整洁和可读性

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 🙏 致谢

- 感谢所有 LLM API 提供商
- 感谢 Swift 和 SwiftUI 社区
- 感谢所有贡献者

## 📮 联系方式

- 项目主页: [https://github.com/yourusername/MACocr](https://github.com/yourusername/MACocr)
- 问题反馈: [Issues](https://github.com/yourusername/MACocr/issues)

## 🗺️ 路线图

- [ ] 支持更多 LLM 提供商
- [ ] 批量截图识别
- [ ] 历史记录功能
- [ ] 导出识别结果
- [ ] 自定义快捷键
- [ ] 多语言界面支持
- [ ] 自动更新功能

---

<div align="center">
  Made with ❤️ for macOS
</div>
