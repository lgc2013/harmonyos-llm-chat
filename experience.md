# 开发经验总结

## 2026-03-26 Hvigor 依赖包配置问题修复

### 错误现象
```
Error: Cannot find module '@ohos/hvigor-ohos-plugin'
Error: 00617101 Fetch Pkg Info Failed - "@ohos/hvigor@6.22.3" not found
```

### 错误原因
1. `@ohos/hvigor` 和 `@ohos/hvigor-ohos-plugin` 是 DevEco Studio 内置包，不在 ohpm 公共仓库中
2. 项目的 `oh_modules/@ohos` 目录为空，依赖包未安装
3. 使用 `ohpm install` 会尝试从公共仓库下载，但找不到这些包

### 解决方案
从 DevEco Studio 安装目录复制依赖包到项目的 `oh_modules` 和 `node_modules` 目录：

```bash
# DevEco Studio 内置包位置
D:\software\Dev-eco\DevEco Studio\tools\hvigor\hvigor
D:\software\Dev-eco\DevEco Studio\tools\hvigor\hvigor-ohos-plugin

# 复制到项目目录
# 1. node_modules/@ohos/ (Node.js 模块解析需要)
# 2. oh_modules/@ohos/ (HarmonyOS 构建需要)

# PowerShell 复制命令
powershell -Command "New-Item -ItemType Directory -Path '项目目录\node_modules\@ohos\hvigor-ohos-plugin' -Force; Copy-Item -Path 'D:\software\Dev-eco\DevEco Studio\tools\hvigor\hvigor-ohos-plugin\*' -Destination '项目目录\node_modules\@ohos\hvigor-ohos-plugin' -Recurse -Force"
```

### 关键要点
- 符号链接（junction）在某些情况下 Node.js 无法正确解析，需要使用实际文件复制
- hvigor 同时检查 `node_modules` 和 `oh_modules` 两个目录
- 修改依赖后需要重启 hvigor daemon: `node hvigor/hvigor-wrapper.js --stop-daemon`

---

## 2026-03-23 英语听力音频源集成

### 需求背景
用户希望将音乐播放器的音源从中文流行音乐切换为英语听力练习音频。

### 调研结果
经过调研，找到以下英语听力音频资源：

1. **LibriVox** (https://librivox.org/)
   - 免费公共领域有声读物
   - 托管在 archive.org，提供直接 MP3 下载
   - URL 格式：`https://archive.org/download/[identifier]/[filename].mp3`

2. **BBC Learning English**
   - 6 Minute English 等节目
   - 需要 RSS 订阅或官方 App 下载
   - 直接 MP3 URL 不易获取

3. **VOA Learning English**
   - 慢速英语新闻
   - 第三方网站提供 MP3 下载

4. **British Council LearnEnglish**
   - 在线播放为主
   - 直接 MP3 URL 不可用

### 解决方案
使用 LibriVox 公共领域有声读物作为英语听力音频源：

**Short Story Collection 001** (stories_001_librivox):
- The Black Cat (Edgar Allan Poe)
- The Telltale Heart (Edgar Allan Poe)
- The Pit and the Pendulum (Edgar Allan Poe)
- Pigs Is Pigs (Ellis Parker Butler)
- Taming The Bicycle (Mark Twain)

**Short Story Collection Vol. 103** (ssc_103_2209_librivox):
- Cat in the Rain (Ernest Hemingway)
- The Sisters (James Joyce)
- The Box of Robbers (L. Frank Baum)

### 关键代码位置
- `NeteaseMusicService.ets` - getDefaultSongs() 方法

### 参考资源
- [LibriVox Official Site](https://librivox.org/)
- [LibriVox Short Story Collection 001](https://archive.org/details/stories_001_librivox)
- [LibriVox Short Story Collection Vol. 103](https://archive.org/details/ssc_103_2209_librivox)

---

## 2026-03-20 网络音乐源集成经验

### 问题现象
- 网易云音乐外链播放时，歌曲名称与实际播放内容不匹配
- 大部分歌曲返回 404 或 HTML 页面（版权限制）
- 需要寻找可靠的免费音乐源

### 根本原因
1. music.163.com 外链机制：
   - 无版权限制的歌曲：302 重定向到真实音频地址
   - 有版权限制的歌曲：302 重定向到 404 页面或返回 HTML

2. AudioUrlResolver 使用 HEAD 请求检测重定向：
   - 检测 Location 头中是否包含 404
   - 检测 Content-Type 是否为 text/html

### 解决方案
混合使用多个音乐源，确保可靠性：

1. **网易云音乐可播放歌曲**（经测试验证）
   - 晴天 (id=28793269)
   - 七里香 (id=28391863)
   - 光年之外 (id=1386742309)

2. **SoundHelix 免费音乐**（无版权限制，100% 可用）
   - 网址：https://www.soundhelix.com/
   - 提供 15 首示例电子音乐

3. **Pixabay Music 免费音乐**（部分可用）
   - 网址：https://pixabay.com/music/
   - 需要测试具体 URL 是否返回 200

### 测试验证方法
```bash
# 测试 URL 可用性（HEAD 请求）
curl -sI "https://music.163.com/song/media/outer/url?id=xxx.mp3" | head -5
curl -sI "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3" | head -5
```

### 关键代码位置
- `NeteaseMusicService.ets` - getDefaultSongs() 方法
- `AudioUrlResolver.ets` - checkRedirect() 方法

---

# 开发经验总结

## 2026-03-19 Hvigor 构建错误修复

### 错误现象
```
hvigor ERROR: 00302013 Script Error
Error Message: The root node is not yet available for build. At file: hvigorfile.ts or hvigorconfig.ts
```

### 错误原因
项目根目录下存在 `node_modules/@ohos/hvigor` 目录，与 DevEco Studio 自带的 hvigor 版本冲突。

堆栈跟踪显示错误来源：
```
D:\01-design-agent\harmonyos\MyApplication\node_modules\@ohos\hvigor\...
```

### 解决方案
1. 删除项目根目录下的 `node_modules` 文件夹
2. 清理 `.hvigor/cache` 缓存目录
3. 重新运行构建命令

### 参考文档
- [编译构建报错：The root node is not yet available for build](https://developer.huawei.com/consumer/cn/doc/architecture-guides/office-v1_2-ts_68-0000002409950566)

---

## 2026-03-19 SDK 版本配置错误修复

### 错误现象
```
Invalid value of compileSdkVersion, compatibleSdkVersion, or targetSdkVersion (if set).
```

### 错误原因
`build-profile.json5` 中 `targetSdkVersion` 设置为 `"1"`，不是有效的 HarmonyOS SDK 版本格式。

### 解决方案
将 `targetSdkVersion` 修改为正确格式：
```json5
"targetSdkVersion": "6.0.2(22)",
"compatibleSdkVersion": "6.0.2(22)"
```

### 参考文档
- [工程级build-profile.json5文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-hvigor-build-profile-app)

---

## 2026-03-19 JSON5 文件语法问题

### 错误现象
构建时报语法相关错误。

### 错误原因
`entry/build-profile.json5` 中存在多余的逗号（trailing comma）。

### 解决方案
移除数组最后一个元素后的逗号：
```json5
// 错误
"targets": [
  { "name": "default" },
  { "name": "ohosTest", }  // 多余逗号
]

// 正确
"targets": [
  { "name": "default" },
  { "name": "ohosTest" }
]
```
