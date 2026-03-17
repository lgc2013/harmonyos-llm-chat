# API 契约：大模型聊天交互功能

**版本**：1.0
**日期**：2026-03-17

## 1. GLM-5 API 契约

### 基础信息

| 项目 | 值 |
|------|-----|
| 基础URL | `https://open.bigmodel.cn/api/paas/v4` |
| 认证方式 | Bearer Token |
| 内容类型 | `application/json` |

### 1.1 聊天补全接口

**端点**：`POST /chat/completions`

**请求头**：
```
Authorization: Bearer {api_key}
Content-Type: application/json
```

**请求体**：
```json
{
  "model": "glm-5",
  "messages": [
    {"role": "user", "content": "你好"}
  ],
  "stream": true,
  "temperature": 0.7,
  "max_tokens": 2000
}
```

**参数说明**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| model | string | 是 | 固定值 `glm-5` |
| messages | array | 是 | 消息历史 |
| stream | boolean | 是 | 是否流式输出，固定 `true` |
| temperature | number | 否 | 随机性 0-1，默认 0.7 |
| max_tokens | number | 否 | 最大输出 token，默认 2000 |

**成功响应（流式）**：
```
data: {"id":"chatcmpl-xxx","choices":[{"index":0,"delta":{"content":"你"},"finish_reason":null}]}

data: {"id":"chatcmpl-xxx","choices":[{"index":0,"delta":{"content":"好"},"finish_reason":null}]}

data: {"id":"chatcmpl-xxx","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}

data: [DONE]
```

**错误响应**：
```json
{
  "error": {
    "message": "Invalid API key",
    "type": "invalid_request_error",
    "code": "invalid_api_key"
  }
}
```

**错误码**：

| HTTP状态码 | 错误类型 | 说明 |
|-----------|----------|------|
| 401 | invalid_api_key | API Key 无效 |
| 429 | rate_limit_exceeded | 请求频率超限 |
| 500 | server_error | 服务器错误 |

---

## 2. 内部服务接口

### 2.1 GLMService

```typescript
interface GLMService {
  /**
   * 发送消息并获取流式响应
   * @param message 用户消息
   * @param onChunk 收到数据块的回调
   * @param onComplete 完成回调
   * @param onError 错误回调
   */
  sendMessage(
    message: string,
    onChunk: (content: string) => void,
    onComplete: () => void,
    onError: (error: Error) => void
  ): void;

  /**
   * 取消当前请求
   */
  cancel(): void;

  /**
   * 检查 API Key 是否有效
   */
  validateApiKey(): Promise<boolean>;
}
```

### 2.2 PreferencesService

```typescript
interface PreferencesService {
  /**
   * 保存 API Key
   */
  saveApiKey(key: string): Promise<void>;

  /**
   * 获取 API Key
   */
  getApiKey(): Promise<string>;

  /**
   * 删除 API Key
   */
  deleteApiKey(): Promise<void>;

  /**
   * 检查是否已配置 API Key
   */
  hasApiKey(): Promise<boolean>;
}
```

### 2.3 ChatViewModel

```typescript
interface ChatViewModel {
  // 状态
  messages: ChatMessage[];
  inputText: string;
  isLoading: boolean;
  error: string | null;

  // 操作
  sendMessage(): void;
  retryMessage(messageId: string): void;
  clearMessages(): void;
  setInputText(text: string): void;
}
```

---

## 3. 组件接口

### 3.1 MessageBubble

```typescript
@Component
struct MessageBubble {
  @Prop message: ChatMessage;    // 消息数据
  @Prop isUser: boolean;         // 是否用户消息
  onRetry?: () => void;          // 重试回调
}
```

### 3.2 ChatInput

```typescript
@Component
struct ChatInput {
  @Link text: string;            // 输入文本（双向绑定）
  disabled: boolean;             // 是否禁用
  maxLength: number;             // 最大长度（默认2000）
  onSend: () => void;            // 发送回调
}
```

### 3.3 LoadingIndicator

```typescript
@Component
struct LoadingIndicator {
  visible: boolean;              // 是否显示
  text?: string;                 // 提示文字
}
```

### 3.4 SettingsPanel

```typescript
@Component
struct SettingsPanel {
  @Link apiKey: string;          // API Key（双向绑定）
  onSave: () => void;            // 保存回调
  onDelete: () => void;          // 删除回调
}
```

---

## 4. 事件契约

### 4.1 消息发送流程

```
用户输入 → setInputText()
    ↓
点击发送 → sendMessage()
    ↓
创建消息 → messages.push({status: SENDING})
    ↓
调用API → GLMService.sendMessage()
    ↓
收到数据块 → onChunk() → 更新消息内容
    ↓
完成 → onComplete() → 更新状态为 SENT
    ↓
或
错误 → onError() → 更新状态为 FAILED
```

### 4.2 重试流程

```
点击重试 → retryMessage(id)
    ↓
找到消息 → messages.find()
    ↓
更新状态 → status = SENDING
    ↓
重新发送 → GLMService.sendMessage()
```
