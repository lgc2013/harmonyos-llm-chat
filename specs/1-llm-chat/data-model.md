# 数据模型：大模型聊天交互功能
+
+**版本**：2.0
+**日期**：2026-03-17
+
+## 设计规范（必须遵循）
+
+| 规范 | 链接 |
+|------|------|
+| 设计最佳实践 | https://developer.huawei.com/consumer/cn/doc/design-guides/practices-overview-0000001746498066 |
+| UX体验标准 | https://developer.huawei.com/consumer/cn/doc/design-guides/ux-guidelines-general-0000001760708152 |
+
+## 1. MessageStatus (枚举)
+
+消息发送状态
+
+```typescript
+export enum MessageStatus {
+  SENDING = 'sending',     // 发送中
+  SENT = 'sent',           // 已发送
+  FAILED = 'failed'        // 发送失败
+}
+```
+
+## 2. MessageRole (枚举)
+
+消息角色
+
+```typescript
+export enum MessageRole {
+  USER = 'user',           // 用户消息
+  ASSISTANT = 'assistant'  // 助手消息（大模型回复）
+}
+```
+
+## 3. ChatMessage (实体)
+
+聊天消息
+
+```typescript
+export interface ChatMessage {
+  id: string;              // 消息唯一标识 (UUID)
+  role: MessageRole;       // 消息角色
+  content: string;         // 消息内容
+  status: MessageStatus;   // 消息状态
+  timestamp: number;       // 时间戳 (毫秒)
+  error?: string;          // 错误信息（可选）
+}
+```
+
+### 字段说明
+
+| 字段 | 类型 | 必填 | 说明 |
+|------|------|------|------|
+| id | string | 是 | UUID 格式，用于列表渲染 key |
+| role | MessageRole | 是 | 区分用户/助手消息 |
+| content | string | 是 | 消息文本内容，最大 2000 字符 |
+| status | MessageStatus | 是 | 用于显示状态图标 |
+| timestamp | number | 是 | 用于消息排序 |
+| error | string | 否 | 发送失败时的错误信息 |
+
+### 验证规则
+- `content` 长度：1-2000 字符
+- `id` 格式：UUID v4
+
+### 状态转换
+
+```
+SENDING ──成功──> SENT
+   │
+   └──失败──> FAILED ──重试──> SENDING
+```
+
+## 4. ChatSession (实体)
+
+聊天会话
+
+```typescript
+export interface ChatSession {
+  id: string;                    // 会话ID
+  messages: ChatMessage[];       // 消息列表
+  createdAt: number;             // 创建时间
+  lastMessageAt: number;         // 最后消息时间
+}
+```
+
+## 5. GLMRequest (请求模型)
+
+GLM-5 API 请求
+
+```typescript
+export interface GLMRequest {
+  model: string;                 // 模型名称：'glm-5'
+  messages: GLMMessage[];        // 消息列表
+  stream: boolean;               // 是否流式输出
+  temperature?: number;          // 温度参数 (0-1)
+  max_tokens?: number;           // 最大 token 数
+}
+
+export interface GLMMessage {
+  role: 'user' | 'assistant' | 'system';
+  content: string;
+}
+```
+
+## 6. GLMResponse (响应模型)
+
+GLM-5 API 响应
+
+```typescript
+export interface GLMStreamResponse {
+  id: string;
+  choices: GLMChoice[];
+}
+
+export interface GLMChoice {
+  index: number;
+  delta: {
+    content: string;
+  };
+  finish_reason?: string;
+}
+```
+
+## 7. UserSettings (配置模型)
+
+用户设置
+
+```typescript
+export interface UserSettings {
+  apiKey: string;                // API Key（加密存储）
+  theme: 'light' | 'dark' | 'auto';  // 主题设置
+}
+```
+
+## 实体关系图
+
+```
+┌─────────────┐
+│ ChatSession │
+├─────────────┤
+│ id          │
+│ messages ───┼───┐
+│ createdAt   │   │
+│ lastMsgAt   │   │
+└─────────────┘   │
+                  │ 1:N
+                  ▼
+            ┌─────────────┐
+            │ ChatMessage │
+            ├─────────────┤
+            │ id          │
+            │ role        │
+            │ content     │
+            │ status      │
+            │ timestamp   │
+            │ error       │
+            └─────────────┘
+```
+
+## 存储设计
+
+### Preferences 存储
+
+| Key | 类型 | 说明 |
+|-----|------|------|
+| `api_key` | string | GLM-5 API Key |
+| `theme` | string | 主题设置 |
+
+### 内存存储
+
+| 数据 | 类型 | 生命周期 |
+|------|------|----------|
+| messages | ChatMessage[] | 会话期间 |
+| isLoading | boolean | 运行时 |
+| inputText | string | 运行时 |
+
+## UX 数据约束
+
+| 数据 | UX要求 | 说明 |
+|------|------|------|
+| 消息内容 | 最大2000字符 | 输入限制 |
+| 消息列表 | 滚动跟手 | 无卡顿（2.1.5.3.2） |
+| 输入框 | 字体≥12vp | UX标准（2.1.4.2） |
