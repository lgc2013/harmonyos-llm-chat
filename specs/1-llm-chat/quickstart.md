# 快速开始：大模型聊天交互功能
+
+## 设计规范（必须遵循）
+
+| 规范 | 链接 |
+|------|------|
+| 设计最佳实践 | https://developer.huawei.com/consumer/cn/doc/design-guides/practices-overview-0000001746498066 |
+| UX体验标准 | https://developer.huawei.com/consumer/cn/doc/design-guides/ux-guidelines-general-0000001760708152 |
+
+## 前置条件
+
+1. **开发环境**
+   - DevEco Studio 已安装
+   - HarmonyOS SDK 已配置
+   - Node.js 环境
+
+2. **API 配置**
+   - 获取 GLM-5 API Key（访问 https://open.bigmodel.cn）
+
+## 安装依赖
+
+> 使用 `/build` skill 自动执行依赖安装和编译
+
+```bash
+# 方式一：使用 skill（推荐）
+/build
+
+# 方式二：手动执行
+"D:\software\Dev-eco\DevEco Studio\tools\ohpm\bin\ohpm.bat" install --all --registry https://ohpm.openharmony.cn/ohpm/ --strict_ssl true
+```
+
+安装额外依赖：
+
+```bash
+"D:\software\Dev-eco\DevEco Studio\tools\ohpm\bin\ohpm.bat" install @ohos/axios
+```
+
+## 配置权限
+
+在 `entry/src/main/module.json5` 中添加网络权限：
+
+```json
+{
+  "module": {
+    "requestPermissions": [
+      {
+        "name": "ohos.permission.INTERNET"
+      }
+    ]
+  }
+}
+```
+
+## 运行项目
+
+> 使用 `/run-emulator` skill 在模拟器上构建运行
+
+```bash
+# 方式一：使用 skill（推荐）
+/run-emulator
+
+# 方式二：手动执行
+"D:\software\Dev-eco\DevEco Studio\tools\node\node.exe" "D:\software\Dev-eco\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
+```
+
+## 开发流程
+
+### 1. TDD 开发模式
+
+每个功能模块按以下顺序开发：
+
+```
+1. 编写测试用例
+2. 运行测试（失败）
+3. 实现功能代码
+4. 运行测试（通过）
+5. 重构优化
+```
+
+### 2. 目录结构
+
+```
+entry/src/main/ets/
+├── common/          # 常量和工具
+├── models/          # 数据模型
+├── services/        # API 服务
+├── viewmodels/      # 视图模型
+├── components/      # UI 组件
+└── pages/           # 页面
+```
+
+### 3. 测试文件位置
+
+```
+entry/src/ohosTest/ets/
+├── test/
+│   ├── models/      # 模型测试
+│   ├── services/    # 服务测试
+│   ├── components/  # 组件测试
+│   └── ux/         # UX 合规测试
+└── uitest/          # UI 测试
+```
+
+## UX 合规检查清单
+
+开发过程中需确保满足以下 UX 要求：
+
+| 类别 | 要求 | 逼 |
+|------|------|------|
+| 点击热区 | 发送按钮 | ≥48vp×48vp（推荐）， ≥40vp×40vp（必须） |
+| 字体大小 | 正文/输入框 | ≥12vp（推荐）， ≥8vp（必须） |
+| 色彩对比度 | 正文与背景 | >4.5:1 |
+| 页面转场 | 全屏转场 | ≥200ms |
+| 长按时长 | 复制消息 | 400-650ms |
+| 滑动体验 | 消息列表 | 跟手无卡顿 |
+
+## API Key 配置
+
+### 方式一：应用内设置（推荐）
+
+1. 运行应用
+2. 点击设置按钮
+3. 输入 API Key
+4. 保存
+
+### 方式二：代码配置（仅开发测试）
+
+```typescript
+// 在 Constants.ets 中
+export const API_KEY = 'your-api-key-here';
+```
+
+**注意**：生产环境必须使用应用内设置，不要硬编码 API Key。
+
+## 常见问题
+
+### Q: 编译失败提示找不到模块？
+
+```bash
+# 清理并重新安装依赖
+"D:\software\Dev-eco\DevEco Studio\tools\ohpm\bin\ohpm.bat" clean
+"D:\software\Dev-eco\DevEco Studio\tools\ohpm\bin\ohpm.bat" install --all --registry https://ohpm.openharmony.cn/ohpm/ --strict_ssl true
+```
+
+### Q: 模拟器无法连接？
+
+```bash
+# 检查 HDC 连接
+hdc list targets
+
+# 重启 HDC 服务
+hdc kill
+hdc start
+```
+
+### Q: API 调用返回 401？
+
+- 检查 API Key 是否正确
+- 确认 API Key 未过期
+- 验证请求头格式
+
+### Q: 流式响应不显示？
+
+- 检查网络权限是否配置
+- 确认 `stream: true` 参数
+- 查看日志中的错误信息
+
+## 相关文档
+
+- [功能规范](./spec.md)
+- [实施计划](./plan.md)
+- [数据模型](./data-model.md)
+- [API 契约](./contracts/api-contracts.md)
+- [技术研究](./research.md)
