# 研究文档：音乐播放器

**创建日期**：2026-03-18
**状态**：已完成

## 研究概述

本文档记录音乐播放器功能的技术研究，包括关键技术决策、最佳实践和替代方案评估。

---

## 1. 音频播放核心：AVPlayer

### 决策
使用 HarmonyOS AVPlayer 作为音频播放核心组件。

### 理由
- 官方推荐的格式化音频播放方案
- 支持本地文件和网络流媒体
- 提供完整的播放控制能力（播放、暂停、跳转、倍速等）
- 与 AVSession 无缝集成

### 参考文档
- [基于AVPlayer播放格式化音频（ArkTS）](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-playing-formatted-audio-based-avplayer-arkts)
- [使用AVPlayer播放音频](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/using-avplayer-for-playback)

### 考虑的替代方案
| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| AudioRenderer | 底层控制更强 | 需要自己处理音频解码 | 不适合，复杂度高 |
| OHAudio (NDK) | C++ 层性能好 | 开发复杂度高 | 不适合，ArkTS 已足够 |
| SoundPool | 适合短音频 | 不适合长音乐播放 | 不适合 |

---

## 2. 后台播放：AVSession + 长时任务

### 决策
使用 AVSession Kit + BackgroundTasks Kit 实现后台播放。

### 理由
- **必须注册 AVSession**：否则播放会被系统暂停
- **必须申请长时任务**：否则应用会被冻结
- 支持锁屏控制中心集成

### 实现要点
```
1. 创建 AVPlayer 及回调函数
2. 创建 AVSession 接入播控中心
3. 申请长时任务权限（backgroundTaskManager）
4. 处理播放状态同步
```

### 参考文档
- [HarmonyOS 开发实践——基于AVPlayer音频后台播放](https://cloud.tencent.com/developer/article/2474687)
- [BackgroundTasks Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/background-task-overview)

### 考虑的替代方案
无替代方案，这是实现后台播放的唯一合规方式。

---

## 3. 音频焦点管理

### 决策
监听 audioInterrupt 事件，正确处理音频焦点抢占。

### 理由
- 来电、闹钟、其他应用会抢占音频焦点
- 不正确处理会导致用户体验问题
- HarmonyOS 要求应用正确响应音频打断事件

### 实现要点
| 场景 | 处理方式 |
|------|----------|
| 来电/闹钟打断 | 监听 audioInterrupt，打断开始时暂停播放 |
| 临时失去焦点 | 降低音量或短暂暂停 |
| 永久失去焦点 | 完全暂停播放，释放资源 |
| 恢复焦点 | 恢复播放状态和音量 |

### 参考文档
- [音频焦点管理最佳实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-audio-focus-management)
- [PC音频控制最佳实践](https://developer.huawei.com/consumer/cn/forum/topic/0204185797396322004)

---

## 4. 网络音乐：Radio Browser API

### 决策
集成 Radio Browser API 作为网络音乐源。

### 理由
- 免费开源，无需 API Key
- 提供 90,000+ 全球电台流媒体
- RESTful API，易于集成
- 支持按国家、类型、热门度筛选

### API 端点
```
服务器：https://de1.api.radio-browser.info

主要接口：
- GET /json/stations/search        # 搜索电台
- GET /json/stations/bycountry/{name}  # 按国家筛选
- GET /json/stations/bytag/{tag}   # 按类型筛选
- GET /json/stations/topvote/100   # 热门电台
```

### 已验证
- API 可访问（HTTP 200）
- 流媒体 URL 返回有效音频（Content-Type: audio/mpeg）
- 示例音频已下载验证（MPEG ADTS, layer III, 128 kbps, 44.1 kHz）

### 考虑的替代方案
| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| Spotify API | 内容丰富 | 需要 API Key，有使用限制 | 不适合 |
| SoundCloud API | 内容丰富 | 需要 API Key | 不适合 |
| 自建服务器 | 完全控制 | 维护成本高 | 不适合 |

---

## 5. 本地文件访问

### 决策
使用 HarmonyOS 文件系统访问能力 + 用户授权。

### 理由
- 需要用户授予媒体文件访问权限
- 使用 FilePicker 或 PhotoAccessHelper 获取文件
- 支持常见音频格式：MP3、AAC、WAV、FLAC

### 实现要点
```
1. 使用 PhotoAccessHelper 访问音频文件
2. 或使用 FilePicker 让用户选择文件
3. 获取文件 URI 后传递给 AVPlayer
```

### 参考文档
- [文件管理开发指导](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/file-management)

---

## 6. 播放列表存储

### 决策
使用 Preferences 进行本地持久化存储。

### 理由
- 播放列表数据量小，不需要复杂数据库
- Preferences API 简单易用
- 支持异步读写

### 考虑的替代方案
| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| RDB (关系数据库) | 功能强大 | 对于播放列表过于复杂 | 不适合 |
| Distributed KV | 支持多设备同步 | 当前需求不需要 | 不适合 |
| 文件存储 | 简单 | 需要自己管理序列化 | 不适合 |

---

## 7. UI 框架

### 决策
使用 ArkUI (ArkTS) 构建用户界面。

### 理由
- HarmonyOS 官方推荐
- 声明式 UI，开发效率高
- 与 AVPlayer/AVSession 良好集成

### 关键组件
- List：音乐列表、电台列表
- Slider：进度条、音量控制
- Image：专辑封面、电台图标
- Toggle：播放/暂停、播放模式切换

---

## 技术栈总结

| 层次 | 技术选择 |
|------|----------|
| UI 层 | ArkUI (ArkTS) |
| 播放核心 | AVPlayer |
| 后台播放 | AVSession Kit + BackgroundTasks Kit |
| 音频焦点 | audioInterrupt 事件监听 |
| 网络请求 | HTTP 客户端（Radio Browser API） |
| 本地存储 | Preferences |
| 文件访问 | PhotoAccessHelper / FilePicker |

---

## 风险与缓解

| 风险 | 缓解措施 |
|------|----------|
| 网络流媒体不稳定 | 实现缓冲机制，显示加载状态 |
| 后台播放权限被拒绝 | 引导用户手动开启权限 |
| 音频格式不兼容 | 优先支持主流格式，不支持的给出提示 |
| API 服务不可用 | 实现降级策略，优先本地音乐 |

---

## 参考链接

- [音频播放系列开发实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-audio-playback-series)
- [HarmonyOS 开发实践——基于AVPlayer音频后台播放](https://cloud.tencent.com/developer/article/2474687)
- [音频焦点管理最佳实践](https://developer.huawei.com/consumer/cn/forum/topic/0204185797396322004)
- [Radio Browser API](https://de1.api.radio-browser.info)
