# MACocr - 快速开始指南

## 🎯 5 分钟上手

### 第一步：打开项目

在终端中运行：
```bash
cd /Users/knsrz/Documents/MACocr
open MACocr.xcodeproj
```

或直接在 Finder 中双击 `MACocr.xcodeproj`

### 第二步：配置签名

1. 在 Xcode 中选择项目文件 `MACocr`
2. 选择 Target → MACocr
3. 进入 "Signing & Capabilities" 标签
4. 勾选 "Automatically manage signing"
5. 选择你的 Team（如果没有，点击 "Add Account" 添加 Apple ID）

### 第三步：运行项目

1. 按 `⌘R` 或点击左上角的运行按钮
2. 首次运行时，系统会提示授予权限：
   - 点击"系统偏好设置"
   - 进入"隐私与安全性"
   - 找到"屏幕录制"
   - 勾选 MACocr
   - 重启应用

### 第四步：配置 API

1. 应用启动后，点击菜单栏的 MACocr 图标
2. 选择"设置..."（或按 `⌘,`）
3. 选择你的 API 提供商（推荐 OpenAI）
4. 填写 API 密钥（从对应平台获取）
5. 点击"测试连接"验证配置
6. 点击"保存"

#### 获取 API 密钥

**OpenAI:**
- 访问 https://platform.openai.com/api-keys
- 登录或注册账号
- 创建新的 API 密钥

**Anthropic:**
- 访问 https://console.anthropic.com/
- 创建 API 密钥

**DeepSeek:**
- 访问 https://platform.deepseek.com/
- 注册并创建 API 密钥

### 第五步：开始使用

1. 按快捷键 `⇧⌘5` 启动截图
2. 框选需要识别的区域
3. 等待 AI 识别（会显示加载动画）
4. 在弹出的窗口中查看识别结果
5. 点击"复制到剪贴板"使用识别的文字

## 📝 使用技巧

### 快捷键
- `⇧⌘5` - 触发截图识别
- `⌘,` - 打开设置
- `⌘Q` - 退出应用

### 最佳实践

1. **截图质量**
   - 确保文字清晰可见
   - 避免过小的文字
   - 尽量保持文字水平

2. **API 配置**
   - OpenAI 的 gpt-4o 效果最好
   - 根据需要调整 max_tokens
   - 自定义提示词可以提高识别准确度

3. **提示词优化**
   - 指定识别语言（如"识别中文"）
   - 说明格式要求（如"保留换行"）
   - 添加特殊要求（如"忽略水印"）

## 🐛 常见问题

### Q1: 运行后菜单栏没有图标？
**A:** 检查应用是否崩溃。查看 Xcode 控制台的错误信息。

### Q2: 截图后没有反应？
**A:** 确保已授予屏幕录制权限，并重启应用。

### Q3: API 调用失败？
**A:** 
- 检查 API 密钥是否正确
- 确认网络连接正常
- 查看 API 额度是否用尽

### Q4: 识别结果不准确？
**A:** 
- 尝试更高质量的截图
- 调整提示词，更明确地说明需求
- 尝试不同的 AI 模型

### Q5: 如何查看日志？
**A:** 在 Xcode 中运行，查看控制台输出的详细日志。

## 🔍 开发调试

如果需要开发或调试：

```bash
# 查看项目结构
tree MACocr

# 在 Xcode 中查看日志
# Window → Devices and Simulators → View Device Logs
```

## 📚 更多资源

- [完整文档](README.md)
- [开发文档](DEVELOPMENT.md)
- [更新日志](CHANGELOG.md)

## 🎉 成功！

现在你已经成功运行了 MACocr！享受便捷的 OCR 体验吧！

有问题？欢迎提交 Issue：
https://github.com/yourusername/MACocr/issues

---

祝使用愉快！🚀
