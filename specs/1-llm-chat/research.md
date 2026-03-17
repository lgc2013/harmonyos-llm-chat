# 技术研究：大模型聊天交互功能

**日期**：2026-03-17
**状态**：已完成

## 1. GLM-5 API 集成

### 决策
使用智谱 AI GLM-5 API 的流式响应接口

### 理由
- GLM-5 支持流式输出（SSE），符合逐字显示需求
- API 文档完善，有官方 SDK 支持
- 国内访问稳定，延迟低

### API 端点
```
POST https://open.bigmodel.cn/api/paas/v4/chat/completions
```

### 请求格式
```json
{
  "model": "glm-5",
  "messages": [
    {"role": "user", "content": "你好"}
  ],
  "stream": true
}
```

### 响应格式（流式）
```
data: {"choices":[{"delta":{"content":"你"}}]}
data: {"choices":[{"delta":{"content":"好"}}]}
data: [DONE]
```

### 认证方式
- Bearer Token 认证
- API Key 存储在用户设置中

## 2. HarmonyOS 网络请求

### 决策
使用 `@ohos/axios` 库处理 HTTP 请求

### 理由
- 与 Axios API 兼容，学习成本低
- 支持 Promise 和 async/await
- 社区活跃，问题易解决

### 替代方案
- `@ohos/http`：原生 HTTP 模块，功能基础
- 直接使用 `http` 模块：需要更多封装

### 流式响应处理
由于 axios 不原生支持 SSE，需要使用原生 `http` 模块处理流式响应：

```typescript
import http from '@ohos.net.http';

let httpRequest = http.createHttp();
httpRequest.on('dataReceive', (data) => {
  // 解析 SSE 数据
});
```

## 3. 本地数据存储

### 决策
使用 `@ohos.data.preferences` 存储 API Key

### 理由
- 轻量级键值存储，适合存储配置
- 数据加密存储，安全性有保障
- HarmonyOS 官方推荐方案

### 替代方案
- `@ohos.data.relationalStore`：关系型数据库，过于复杂
- 文件存储：需要手动管理，不推荐

## 4. 状态管理

### 决策
使用 `@State` 和 `@LocalStorage` 管理应用状态

### 理由
- ArkUI 原生支持，无需额外依赖
- 响应式更新，UI 自动刷新
- 简单场景下足够使用

### 状态设计
```typescript
// 消息列表
@State messages: ChatMessage[] = [];

// 当前输入
@State inputText: string = '';

// 加载状态
@State isLoading: boolean = false;

// API Key（全局）
LocalStorage.prop('apiKey', '');
```

## 5. UI 组件设计

### 决策
自定义组件实现聊天界面

### 组件结构
```
Index (页面)
├── List (消息列表)
│   └── MessageBubble (消息气泡) × N
├── LoadingIndicator (加载指示器)
└── ChatInput (输入区域)
    ├── TextInput
    └── SendButton
```

### 深色模式支持
- 使用系统资源 `$r('app.color.xxx')`
- 监听系统主题变化 `@StorageLink('isDark')`

## 6. 测试策略

### 决策
采用 TDD 开发模式，使用 Hypium 测试框架

### 测试层次
1. **单元测试**：数据模型、工具类
2. **集成测试**：Service 层 API 调用
3. **UI 测试**：组件渲染测试

### Mock 策略
- API 调用使用 Mock 数据
- 本地存储使用测试实例

## 总结

所有技术选型已完成，无未解决的澄清项。可以进入设计阶段。
