# HarmonyOS ArkTS 开发注意事项与 Skills

## 一、环境与工具

### 1.1 常用工具路径
```bash
# hdc 工具（用于设备通信）
<D:\software\Dev-eco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe>

# hvigor 构建工具
<D:\software\Dev-eco\DevEco Studio\tools\hvigor\bin\hvigorw.bat>

# 编译命令
cd D:/01-design-agent/harmonyos/MyApplication
hvigorw.bat --mode module -p module=entry@default -p product=default assembleHap --no-daemon

# 安装应用
hdc.exe install -r <path/to/app.hap>

# 启动应用
hdc.exe shell aa start -a EntryAbility -b com.example.myapplication

# 卸载应用
hdc.exe uninstall com.example.myapplication
```

### 1.2 日志查看
```bash
# 实时日志
hdc.exe shell hilog -x | grep "LLMChat"

# 离线日志位置（压缩的gz文件）
<Emulator>/<设备名>/Log/hilog_tmp_<时间戳>/hilog.*.gz

# 解压查看
zcat hilog.xxx.gz | grep "关键词"
```

### 1.3 截图命令
```bash
# 正确：使用 .jpeg 扩展名
hdc.exe shell "snapshot_display -f /data/local/tmp/test.jpeg"
hdc.exe file recv /data/local/tmp/test.jpeg ./local.jpeg

# 错误：.pcap 扩展名不被接受
```

---

## 二、ArkTS 语法限制

### 2.1 禁止使用对象字面量作为类型声明
```typescript
// ❌ 错误：Object literals cannot be used as type declarations
const response: { id: string; content: string[] } = JSON.parse(result);

// ✅ 正确：使用显式接口
interface ApiResponse {
  id: string;
  content: string[];
}
const response: ApiResponse = JSON.parse(result) as ApiResponse;
```

### 2.2 禁止使用 any/unknown 类型
```typescript
// ❌ 错误
const errorObj = JSON.parse(result);

// ✅ 正确
const errorObj: ApiErrorResponse = JSON.parse(result) as ApiErrorResponse;
```

### 2.3 禁止使用对象展开语法
```typescript
// ❌ 错误：arkts-no-spread
const newObj = { ...oldObj, content: newContent };

// ✅ 正确：显式创建新对象或使用辅助函数
function updateMessage(message: ChatMessage, newContent: string): ChatMessage {
  return new ChatMessage(
    message.id,
    message.role,
    newContent,
    message.status,
    message.timestamp
  );
}
```

### 2.4 禁止在接口中使用展开
```typescript
// ❌ 错误
interface NewObj extends OldObj {
  extra: string;
}
```

---

## 三、响应式状态管理

### 3.1 @Prop vs @ObjectLink 的关键区别

| 装饰器 | 特点 | 使用场景 |
|--------|------|----------|
| `@Prop` | 单向数据流，创建本地副本 | 简单值，不需要更新 |
| `@ObjectLink` | 双向绑定，响应对象属性变化 | 需要深度响应式的对象 |
| `@State` | 组件内状态，触发UI刷新 | 本地状态管理 |
| `@Link` | 双向绑定到父组件状态 | 需要同步更新的值 |

### 3.2 深度响应式更新的正确实现

```typescript
// ❌ 错误：@Prop 不会响应对象属性变化
@Component
struct MessageBubble {
  @Prop message: ChatMessage;  // 修改 message.content 不会触发更新
}

// ✅ 正确：使用 @Observed + @ObjectLink
@Observed
class ChatMessage {
  id: string = '';
  content: string = '';
  status: MessageStatus = MessageStatus.SENDING;
  // ...
}

@Component
struct MessageBubble {
  @ObjectLink message: ChatMessage;  // 属性变化会触发更新
}
```

### 3.3 父子组件通信

```typescript
// 父组件传递 @Observed 对象
ForEach(this.messages, (message: ChatMessage) => {
  MessageBubble({ message: message })  // 直接传递对象引用
}, (message: ChatMessage) => message.id)

// 子组件接收
@Component
struct MessageBubble {
  @ObjectLink message: ChatMessage;  // 使用 @ObjectLink
}
```

---

## 四、服务层设计

### 4.1 PreferencesService 异步初始化

```typescript
// ❌ 错误：直接调用可能未初始化
const apiKey = await PreferencesService.getApiKey();

// ✅ 正确：等待初始化完成
class PreferencesService {
  private initPromise: Promise<void> | null = null;

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.preferencesInstance) return;
    if (this.initPromise) return this.initPromise;
    this.initPromise = this.doInit(context);
    return this.initPromise;
  }

  async waitForInit(): Promise<void> {
    if (this.preferencesInstance) return;
    if (this.initPromise) return this.initPromise;
    throw new Error('Preferences not initialized');
  }
}

// 在 EntryAbility 中初始化
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    PreferencesService.init(this.context);  // 尽早初始化
  }
}
```

### 4.2 ViewModel 状态同步

```typescript
// 问题：用户保存设置后，ViewModel 的本地状态未更新
class ChatViewModel {
  private apiKeyValue: string = '';

  // ❌ 只在 init() 时加载一次
  async init(): Promise<void> {
    this.apiKeyValue = await PreferencesService.getApiKey();
  }
}

// ✅ 添加重新加载方法
class ChatViewModel {
  async reloadApiKey(): Promise<void> {
    this.apiKeyValue = await PreferencesService.getApiKey();
    if (this.apiKeyValue) {
      GLMService.setApiKey(this.apiKeyValue);
    }
  }
}

// 在设置保存后调用
SettingsPanel({
  onSave: async () => {
    await this.viewModel.reloadApiKey();  // 同步状态
  }
})
```

---

## 五、HTTP API 调用

### 5.1 使用 @ohos.net.http

```typescript
import http from '@ohos.net.http';

async sendMessage(message: string): Promise<void> {
  const httpRequest = http.createHttp();

  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ' + this.apiKey,
    'anthropic-version': '2023-06-01'  // Anthropic API 必需
  };

  const options: http.HttpRequestOptions = {
    method: http.RequestMethod.POST,
    header: headers,
    connectTimeout: 60000,
    readTimeout: 60000,
    extraData: JSON.stringify(requestBody)
  };

  const response = await httpRequest.request(url, options);

  // 记得销毁请求
  httpRequest.destroy();
}
```

### 5.2 API 端点配置

```typescript
// 智谱 AI Anthropic 兼容接口
const GLM_API_CONFIG = {
  BASE_URL: 'https://open.bigmodel.cn/api/anthropic',
  MODEL: 'claude-3-5-sonnet-20241022',
  ENDPOINT: '/v1/messages'
};

// 完整 URL
const url = GLM_API_CONFIG.BASE_URL + '/v1/messages';
```

---

## 六、模拟器测试技巧

### 6.1 查看 API 调用结果
```bash
# 搜索关键日志
hdc.exe shell hilog -x | grep -E "(API Response|onChunk|onComplete|Error)"
```

### 6.2 验证 UI 状态
```bash
# 截图并传输到本地
hdc.exe shell "snapshot_display -f /data/local/tmp/screen.jpeg"
hdc.exe file recv /data/local/tmp/screen.jpeg ./screen.jpeg
```

### 6.3 清除应用数据
```bash
# 方法1：卸载重装（完全清除）
hdc.exe uninstall com.example.myapplication
hdc.exe install app.hap

# 方法2：清除数据目录（保留应用）
hdc.exe shell "rm -rf /data/app/el2/100/base/com.example.myapplication/haps/entry/files/*"
```

---

## 七、常见错误排查

### 7.1 "Preferences not initialized"
**原因**：PreferencesService 未在 Ability 中初始化
**解决**：在 EntryAbility.onCreate() 中调用 `PreferencesService.init(this.context)`

### 7.2 "API Key is empty"
**原因**：ViewModel 的本地 apiKeyValue 未同步
**解决**：添加 reloadApiKey() 方法并在保存后调用

### 7.3 UI 不更新但日志显示成功
**原因**：@Prop 不支持深度响应式
**解决**：使用 @Observed + @ObjectLink

### 7.4 "arkts-no-spread" 编译错误
**原因**：ArkTS 不支持对象展开语法
**解决**：显式创建新对象或使用构造函数

### 7.5 "AceAutoFill libhint2type" 错误
**原因**：模拟器系统层面的问题，与应用无关
**解决**：忽略，不影响应用功能

---

## 八、项目结构最佳实践

```
entry/src/main/ets/
├── common/
│   ├── constants/
│   │   └── Constants.ets      # 常量定义
│   └── utils/
│       ├── Logger.ets         # 日志工具
│       └── NetworkUtil.ets    # 网络检测
├── components/
│   ├── MessageBubble.ets      # 消息气泡组件
│   ├── ChatInput.ets          # 输入组件
│   └── SettingsPanel.ets      # 设置面板
├── models/
│   ├── ChatMessage.ets        # @Observed 消息类
│   ├── MessageRole.ets        # 角色枚举
│   └── MessageStatus.ets      # 状态枚举
├── services/
│   ├── GLMService.ets         # API 服务
│   └── PreferencesService.ets # 本地存储
├── viewmodels/
│   └── ChatViewModel.ets      # 视图模型
├── pages/
│   └── Index.ets              # 主页面
└── entryability/
    └── EntryAbility.ets       # 应用入口
```

---

## 九、调试清单

开发完成后，按以下清单验证：

- [ ] PreferencesService 在 EntryAbility 中初始化
- [ ] ViewModel 调用 waitForInit() 确保服务就绪
- [ ] 使用 @Observed/@ObjectLink 实现深度响应式
- [ ] API Key 保存后调用 reloadApiKey()
- [ ] 所有 JSON.parse() 都有显式类型转换
- [ ] HTTP 请求后调用 httpRequest.destroy()
- [ ] 设置面板使用 @Prop 接收 visible 状态
- [ ] 日志输出包含关键状态信息
