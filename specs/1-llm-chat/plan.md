# 实施计划：大模型聊天交互功能

+
+**版本**：2.0
+**创建日期**：2026-03-17
+**分支**：1-llm-chat
+
+## 设计规范（必须遵循）
+
+| 规范 | 链接 |
+|------|------|
+| 设计最佳实践 | https://developer.huawei.com/consumer/cn/doc/design-guides/practices-overview-0000001746498066 |
+| UX体验标准 | https://developer.huawei.com/consumer/cn/doc/design-guides/ux-guidelines-general-0000001760708152 |
+
+## 技术上下文
+
+| 项目 | 选择 | 说明 |
+|------|------|------|
+| 开发框架 | HarmonyOS ArkUI | 原生UI框架 |
+| 开发语言 | ArkTS | TypeScript超集 |
+| LLM API | GLM-5 (智谱AI) | 流式响应支持 |
+| 网络库 | @ohos/net.http | 原生HTTP（流式响应） |
+| 状态管理 | @State/@LocalStorage | 响应式状态 |
+| 数据存储 | Preferences | API Key持久化 |
+| 测试框架 | Hypium | HarmonyOS官方测试框架 |
+| UI组件 | 自定义组件 | 聊天气泡、消息列表 |
+
+## 架构设计
+
+```
+entry/src/main/ets/
+├── common/                    # 公共模块
+│   ├── constants/             # 常量定义
+│   │   └── Constants.ets      # API地址、超时配置
+│   └── utils/                 # 工具类
+│       ├── NetworkUtil.ets    # 网络检测
+│       └── Logger.ets         # 日志工具
+│
+├── models/                    # 数据模型
+│   ├── ChatMessage.ets        # 消息模型
+│   ├── MessageStatus.ets      # 消息状态枚举
+│   └── ChatSession.ets        # 会话模型
+│
+├── services/                  # 服务层
+│   ├── GLMService.ets         # GLM-5 API调用
+│   └── PreferencesService.ets # 本地存储服务
+│
+├── viewmodels/                # 视图模型
+│   └── ChatViewModel.ets      # 聊天逻辑控制
+│
+├── components/                # UI组件
+│   ├── MessageBubble.ets      # 消息气泡
+│   ├── ChatInput.ets          # 输入框组件
+│   ├── LoadingIndicator.ets   # 加载指示器
+│   └── SettingsPanel.ets      # 设置面板
+│
+└── pages/                     # 页面
+    ├── Index.ets              # 主聊天页面
+    └── SettingsPage.ets       # 设置页面
+```
+
+## TDD 开发原则
+
+**严格遵循红-绿-重构循环**：
+1. 🔴 **红**：先编写失败的测试用例
+2. 🟢 **绿**：编写最少代码使测试通过
+3. 🔄 **重构**：优化代码结构，保持测试通过
+
+## UX 合规检查清单
+
+> 基于《通用应用 UX 体验标准》
+
+### 基础体验
+
+| 标准编号 | 要求 | 实现方式 |
+|----------|------|----------|
+| 2.1.1.1 | 系统返回 | 使用 Navigation 组件，支持侧边返回 |
+| 2.1.2.1 | 布局基础 | 响应式布局，无错位/截断/变形 |
+| 2.1.2.2 | 挖孔区适配 | 输入框避让挖孔区 |
+
+### 人机交互
+
+| 标准编号 | 要求 | 实现方式 |
+|----------|------|----------|
+| 2.1.3.1 | 避免手势冲突 | 不设计与系统手势冲突的操作 |
+| 2.1.3.2 | 手势时长 | 长按复制 500ms |
+| 2.1.3.3 | 点击热区 | 发送按钮 ≥48vp×48vp |
+
+### 视觉风格
+
+| 标准编号 | 要求 | 实现方式 |
+|----------|------|----------|
+| 2.1.4.1 | 色彩对比度 | 正文与背景 >4.5:1 |
+| 2.1.4.2 | 字体大小 | 正文 ≥12vp，最小 8vp |
+| 2.1.4.3.2 | 界面图标 | 状态图标 ≥8vp |
+
+### 动效
+
+| 标准编号 | 要求 | 实现方式 |
+|----------|------|----------|
+| 2.1.5.1.1 | 层级转场 | 页面使用左右位移转场 |
+| 2.1.5.2.2 | 动效时长 | 转场动效 ≥200ms |
+| 2.1.5.3.2 | 滑动跟手 | List 滑动跟手无卡顿 |
+| 2.1.5.3.3 | 滑动过界 | 滑动到边界有反馈 |
+
+### 系统特性
+
+| 标准编号 | 要求 | 实现方式 |
+|----------|------|----------|
+| 2.2.1 | 导航条适配 | 输入框避让底部导航条 |
+| 2.2.5 | 深色模式 | 支持深色模式，元素清晰 |
+| 2.2.6 | 状态栏 | 沉浸式状态栏设计 |
+
+## 实施阶段
+
+### 阶段 1：基础设施
+
+**目标**：搭建项目基础结构和数据模型
+
+#### 1.1 编写测试用例（红）
+
+| 测试文件 | 测试用例 | UX检查项 |
+|----------|----------|----------|
+| ChatMessage.test.ets | 创建消息、ID生成、内容验证 | - |
+| MessageStatus.test.ets | 状态枚举值、状态转换 | - |
+| PreferencesService.test.ets | 保存/读取/删除API Key | - |
+
+#### 1.2 实现代码（绿）
+
+| 任务 | 文件路径 |
+|------|----------|
+| 创建目录结构 | `entry/src/main/ets/` |
+| 实现 ChatMessage | `entry/src/main/ets/models/ChatMessage.ets` |
+| 实现 MessageStatus | `entry/src/main/ets/models/MessageStatus.ets` |
+| 实现 PreferencesService | `entry/src/main/ets/services/PreferencesService.ets` |
+
+**验收标准**：
+- ✅ 所有测试用例先编写并运行失败（红）
+- ✅ 实现代码后所有测试通过（绿）
+- ✅ 代码覆盖率 ≥ 90%
+
+---
+
+### 阶段 2：网络层
+
+**目标**：实现GLM-5 API调用
+
+#### 2.1 编写测试用例（红）
+
+| 测试文件 | 测试用例 |
+|----------|----------|
+| GLMService.test.ets | 发送消息成功、流式响应解析、超时处理、错误重试、取消请求 |
+| NetworkUtil.test.ets | 网络检测、连接状态 |
+
+#### 2.2 实现代码（绿）
+
+| 任务 | 文件路径 |
+|------|----------|
+| 实现 GLMTypes | `entry/src/main/ets/models/GLMTypes.ets` |
+| 实现 NetworkUtil | `entry/src/main/ets/common/utils/NetworkUtil.ets` |
+| 实现 GLMService | `entry/src/main/ets/services/GLMService.ets` |
+| 实现 StreamParser | `entry/src/main/ets/services/StreamParser.ets` |
+
+**验收标准**：
+- ✅ 所有测试用例先编写并运行失败（红）
+- ✅ 实现代码后所有测试通过（绿）
+- ✅ Mock API 调用测试覆盖 100%
+
+---
+
+### 阶段 3：UI组件
+
+**目标**：实现聊天界面组件（符合UX规范）
+
+#### 3.1 编写测试用例（红）
+
+| 测试文件 | 测试用例 | UX检查项 |
+|----------|----------|----------|
+| MessageBubble.test.ets | 用户/助手消息渲染、状态图标 | 对比度 >4.5:1 |
+| ChatInput.test.ets | 输入绑定、字符限制、发送按钮 | 热区 ≥48vp, 字体 ≥12vp |
+| LoadingIndicator.test.ets | 显示/隐藏、动画效果 | - |
+| SettingsPanel.test.ets | API Key输入、保存/删除 | 输入框避让挖孔区 |
+
+#### 3.2 实现代码（绿）
+
+| 任务 | 文件路径 | UX规范 |
+|------|----------|----------|
+| 实现 LoadingIndicator | `entry/src/main/ets/components/LoadingIndicator.ets` | - |
+| 实现 MessageBubble | `entry/src/main/ets/components/MessageBubble.ets` | 对比度 >4.5:1 |
+| 实现 ChatInput | `entry/src/main/ets/components/ChatInput.ets` | 热区48vp, 字体12vp |
+| 实现 SettingsPanel | `entry/src/main/ets/components/SettingsPanel.ets` | 避让挖孔区 |
+| 配置深色模式资源 | `entry/src/main/resources/` | 2.2.5 |
+
+**验收标准**：
+- ✅ 所有组件测试先编写并运行失败（红）
+- ✅ 实现后所有测试通过（绿）
+- ✅ **通过 UX 合规检查**（对比度、热区、字体大小）
+
+---
+
+### 阶段 4：业务逻辑
+
+**目标**：实现聊天业务逻辑
+
+#### 4.1 编写测试用例（红）
+
+| 测试文件 | 测试用例 |
+|----------|----------|
+| ChatViewModel.test.ets | 发送消息流程、接收响应、状态更新、错误处理、重试逻辑、清空对话 |
+
+#### 4.2 实现代码（绿）
+
+| 任务 | 文件路径 |
+|------|----------|
+| 实现 ChatViewModel | `entry/src/main/ets/viewmodels/ChatViewModel.ets` |
+| 消息发送/接收逻辑 | `entry/src/main/ets/viewmodels/ChatViewModel.ets` |
+| 消息状态管理 | `entry/src/main/ets/viewmodels/ChatViewModel.ets` |
+| 错误状态处理 | `entry/src/main/ets/viewmodels/ChatViewModel.ets` |
+
+**验收标准**：
+- ✅ ViewModel 测试先编写并运行失败（红）
+- ✅ 实现后测试覆盖 100%
+- ✅ 所有状态转换正确
+
+---
+
+### 阶段 5：集成
+
+**目标**：页面集成和端到端测试
+
+#### 5.1 页面实现
+
+| 任务 | 文件路径 | UX规范 |
+|------|----------|----------|
+| 重构 Index.ets | `entry/src/main/ets/pages/Index.ets` | 2.2.1 导航条适配 |
+| 创建 SettingsPage | `entry/src/main/ets/pages/SettingsPage.ets` | 2.1.1.1 系统返回 |
+| 配置页面转场 | - | 2.1.5.1.1 层级转场 |
+
+#### 5.2 集成测试
+
+| 测试文件 | 测试用例 | UX检查项 |
+|----------|----------|----------|
+| ChatFlow.test.ets | 完整对话流程、错误处理 | 滑动跟手 |
+| DarkMode.test.ets | 深色模式切换 | 2.2.5 |
+| UXCompliance.test.ets | UX合规检查 | 全部标准 |
+
+**验收标准**：
+- ✅ 所有集成测试通过
+- ✅ 模拟器运行流畅（无卡顿）
+- ✅ **通过华为 UX 合规检查**
+
+## 鑲证命令
+
+使用项目 skill 进行编译和运行验证：
+
+| Skill | 命令 | 用途 |
+|-------|------|------|
+| `/build` | 编译验证 | 每个阶段完成后 |
+| `/run-emulator` | 模拟器运行 | 阶段5集成测试 |
+
+## 宪法检查
+
+| 检查项 | 状态 | 说明 |
+|--------|------|------|
+| TDD开发 | ✅ | 每个阶段都有测试先行 |
+| 代码规范 | ✅ | 遵循 ArkTS 规范 |
+| 错误处理 | ✅ | 网络错误、超时处理 |
+| 用户体验 | ✅ | 加载状态、错误提示 |
+| 安全性 | ✅ | API Key 本地加密存储 |
+| UX合规 | ✅ | 符合华为UX体验标准 |
+
+## 风险评估
+
+| 风险 | 级别 | 缓解措施 |
+|------|------|----------|
+| GLM-5 API 不稳定 | 高 | 实现重试机制、超时处理 |
+| 流式响应解析复杂 | 中 | 参考 SDK 文档实现 |
+| 模拟器性能限制 | 低 | 优化渲染、避免内存泄漏 |
+| UX合规风险 | 中 | 每个阶段进行UX检查 |
+
+## 依赖项
+
+- [ ] 安装 @ohos/axios 依赖（如需要）
+- [ ] 获取 GLM-5 API Key（用于测试）
+- [ ] 配置网络权限
+
+## 输出文件
+
+- [x] `specs/1-llm-chat/research.md`
+- [x] `specs/1-llm-chat/data-model.md`
+- [x] `specs/1-llm-chat/contracts/api-contracts.md`
+- [x] `specs/1-llm-chat/quickstart.md`
