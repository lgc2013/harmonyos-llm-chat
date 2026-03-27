# 快速开始指南：音乐播放器

**创建日期**：2026-03-18
**版本**：1.0

## 概述

本指南帮助开发者快速实现音乐播放器功能，包括本地音乐播放、网络电台、后台播放等核心功能。

---

## 前置条件

### 开发环境
- DevEco Studio 4.0 或更高版本
- HarmonyOS SDK API 10 或更高版本
- Node.js 18 或更高版本

### 设备要求
- HarmonyOS 4.0 或更高版本
- 支持音频播放的设备

---

## 项目结构

```
entry/
├── src/main/
│   ├── ets/
│   │   ├── entryability/
│   │   │   └── EntryAbility.ets        # 应用入口
│   │   ├── pages/
│   │   │   ├── Index.ets               # 主页面
│   │   │   ├── MusicPlayerPage.ets     # 播放器页面
│   │   │   ├── RadioListPage.ets       # 电台列表页面
│   │   │   └── PlaylistPage.ets        # 播放列表页面
│   │   ├── viewmodels/
│   │   │   ├── PlayerViewModel.ets     # 播放器视图模型
│   │   │   ├── RadioViewModel.ets      # 电台视图模型
│   │   │   └── PlaylistViewModel.ets   # 播放列表视图模型
│   │   ├── services/
│   │   │   ├── PlayerService.ets       # 播放服务
│   │   │   ├── RadioService.ets        # 电台服务
│   │   │   └── LocalMusicService.ets   # 本地音乐服务
│   │   ├── models/
│   │   │   ├── MusicTrack.ets          # 音乐曲目模型
│   │   │   ├── RadioStation.ets        # 电台模型
│   │   │   └── Playlist.ets            # 播放列表模型
│   │   └── common/
│   │       ├── Constants.ets           # 常量定义
│   │       └── Utils.ets               # 工具函数
│   ├── module.json5                     # 模块配置
│   └── resources/                       # 资源文件
```

---

## 第一步：配置权限

在 `module.json5` 中添加必要权限：

```json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET",
        "reason": "用于播放网络音乐流"
      },
      {
        "name": "ohos.permission.READ_MEDIA",
        "reason": "用于读取本地音乐文件"
      },
      {
        "name": "ohos.permission.KEEP_BACKGROUND_RUNNING",
        "reason": "用于后台播放音乐"
      }
    ]
  }
}
```

---

## 第二步：实现播放服务

### 2.1 创建 PlayerService

```typescript
// services/PlayerService.ets

import media from '@ohos.multimedia.media';
import avSession from '@ohos.multimedia.avsession';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';

export class PlayerService {
  private avPlayer: media.AVPlayer | null = null;
  private avSession: avSession.AVSession | null = null;
  private isBackgroundTaskStarted: boolean = false;

  // 初始化播放器
  async initialize(): Promise<void> {
    // 1. 创建 AVPlayer
    this.avPlayer = await media.createAVPlayer();

    // 2. 创建 AVSession（后台播放必需）
    this.avSession = await avSession.createAVSession(
      context,
      'MusicPlayer',
      'audio'
    );
    await this.avSession.activate();

    // 3. 设置状态变化回调
    this.setupPlayerCallbacks();
    this.setupSessionCallbacks();
  }

  // 播放音频
  async play(url: string): Promise<void> {
    if (!this.avPlayer) {
      throw new Error('Player not initialized');
    }

    // 开始后台任务
    await this.startBackgroundTask();

    // 设置音频源
    this.avPlayer.url = url;
    await this.avPlayer.play();
  }

  // 暂停播放
  async pause(): Promise<void> {
    if (this.avPlayer) {
      await this.avPlayer.pause();
    }
  }

  // 停止播放
  async stop(): Promise<void> {
    if (this.avPlayer) {
      await this.avPlayer.stop();
    }
    await this.stopBackgroundTask();
  }

  // 开始后台任务
  private async startBackgroundTask(): Promise<void> {
    if (this.isBackgroundTaskStarted) {
      return;
    }

    try {
      await backgroundTaskManager.requestSuspendDelay(
        'MusicPlayer',
        () => {
          // 后台任务结束回调
          this.stopBackgroundTask();
        }
      );
      this.isBackgroundTaskStarted = true;
    } catch (error) {
      console.error('Failed to start background task:', error);
    }
  }

  // 停止后台任务
  private async stopBackgroundTask(): Promise<void> {
    if (!this.isBackgroundTaskStarted) {
      return;
    }

    // 取消后台任务
    this.isBackgroundTaskStarted = false;
  }
}
```

### 2.2 处理音频打断

```typescript
// 在 PlayerService 中添加

import audio from '@ohos.multimedia.audio';

private setupInterruptListener(): void {
  const audioManager = audio.getAudioManager();

  audioManager.on('audioInterrupt', (interruptEvent: audio.InterruptEvent) => {
    switch (interruptEvent.eventType) {
      case audio.InterruptType.INTERRUPT_TYPE_BEGIN:
        // 打断开始，暂停播放
        this.pause();
        break;

      case audio.InterruptType.INTERRUPT_TYPE_END:
        // 打断结束，恢复播放
        if (interruptEvent.hintType === audio.InterruptHint.INTERRUPT_HINT_RESUME) {
          this.resume();
        }
        break;
    }
  });
}
```

---

## 第三步：实现电台服务

### 3.1 创建 RadioService

```typescript
// services/RadioService.ets

import http from '@ohos.net.http';

const RADIO_API_BASE = 'https://de1.api.radio-browser.info';

export class RadioService {
  // 获取热门电台
  async getTopStations(limit: number = 100): Promise<RadioStation[]> {
    const response = await this.request(
      `/json/stations/topvote/${limit}`
    );
    return this.parseStations(response);
  }

  // 按国家搜索
  async getByCountry(country: string): Promise<RadioStation[]> {
    const response = await this.request(
      `/json/stations/bycountry/${encodeURIComponent(country)}`
    );
    return this.parseStations(response);
  }

  // 搜索电台
  async search(query: string): Promise<RadioStation[]> {
    const response = await this.request(
      `/json/stations/search?name=${encodeURIComponent(query)}`
    );
    return this.parseStations(response);
  }

  // HTTP 请求封装
  private async request(endpoint: string): Promise<string> {
    const httpRequest = http.createHttp();

    try {
      const response = await httpRequest.request(
        `${RADIO_API_BASE}${endpoint}`,
        {
          method: http.RequestMethod.GET,
          header: {
            'User-Agent': 'HarmonyOS-MusicPlayer/1.0'
          },
          connectTimeout: 10000,
          readTimeout: 10000
        }
      );

      if (response.responseCode === 200) {
        return response.result as string;
      } else {
        throw new Error(`HTTP ${response.responseCode}`);
      }
    } finally {
      httpRequest.destroy();
    }
  }

  // 解析电台数据
  private parseStations(json: string): RadioStation[] {
    const data = JSON.parse(json);
    return data.map((item: Record<string, Object>) => ({
      id: `radio_${item.stationuuid}`,
      name: item.name,
      url: item.url,
      country: item.country,
      tags: item.tags?.split(',') || [],
      votes: item.votes,
      favicon: item.favicon,
      codec: item.codec,
      bitrate: item.bitrate
    }));
  }
}
```

---

## 第四步：实现播放列表管理

### 4.1 使用 Preferences 存储

```typescript
// services/PlaylistService.ets

import dataPreferences from '@ohos.data.preferences';

const PLAYLISTS_KEY = 'playlists';

export class PlaylistService {
  private preferences: dataPreferences.Preferences | null = null;

  // 初始化
  async initialize(context: Context): Promise<void> {
    this.preferences = await dataPreferences.getPreferences(
      context,
      'music_player'
    );
  }

  // 获取所有播放列表
  async getAll(): Promise<Playlist[]> {
    const json = await this.preferences?.get(PLAYLISTS_KEY, '[]');
    return JSON.parse(json as string);
  }

  // 创建播放列表
  async create(name: string): Promise<Playlist> {
    const playlists = await this.getAll();

    const newPlaylist: Playlist = {
      id: `playlist_${Date.now()}`,
      name,
      items: [],
      totalCount: 0,
      totalDuration: 0,
      createdAt: Date.now(),
      updatedAt: Date.now(),
      isSystem: false
    };

    playlists.push(newPlaylist);
    await this.save(playlists);

    return newPlaylist;
  }

  // 添加项目到列表
  async addItem(playlistId: string, item: PlaylistItem): Promise<void> {
    const playlists = await this.getAll();
    const playlist = playlists.find(p => p.id === playlistId);

    if (!playlist) {
      throw new Error('Playlist not found');
    }

    if (playlist.items.length >= 500) {
      throw new Error('Playlist is full');
    }

    playlist.items.push(item);
    playlist.totalCount = playlist.items.length;
    playlist.updatedAt = Date.now();

    await this.save(playlists);
  }

  // 保存到 Preferences
  private async save(playlists: Playlist[]): Promise<void> {
    await this.preferences?.put(PLAYLISTS_KEY, JSON.stringify(playlists));
    await this.preferences?.flush();
  }
}
```

---

## 第五步：实现 UI 页面

### 5.1 播放器页面

```typescript
// pages/MusicPlayerPage.ets

@Entry
@Component
struct MusicPlayerPage {
  @State isPlaying: boolean = false;
  @State currentTime: number = 0;
  @State duration: number = 0;
  @State volume: number = 0.5;

  private playerService: PlayerService = new PlayerService();

  build() {
    Column() {
      // 封面区域
      Image($r('app.media.default_album'))
        .width(200)
        .height(200)
        .borderRadius(16)

      // 标题信息
      Text('歌曲名称')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)

      Text('艺术家')
        .fontSize(14)
        .fontColor('#666666')

      // 进度条
      Row() {
        Text(this.formatTime(this.currentTime))
        Slider({
          value: this.currentTime,
          min: 0,
          max: this.duration
        })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.playerService.seekTo(value);
          })
        Text(this.formatTime(this.duration))
      }
      .width('100%')
      .padding({ left: 16, right: 16 })

      // 播放控制
      Row() {
        Button('上一首')
          .onClick(() => this.playerService.previous())

        Button(this.isPlaying ? '暂停' : '播放')
          .onClick(() => {
            if (this.isPlaying) {
              this.playerService.pause();
            } else {
              this.playerService.resume();
            }
            this.isPlaying = !this.isPlaying;
          })

        Button('下一首')
          .onClick(() => this.playerService.next())
      }
      .justifyContent(FlexAlign.SpaceEvenly)
      .width('100%')

      // 音量控制
      Row() {
        Text('音量')
        Slider({
          value: this.volume * 100,
          min: 0,
          max: 100
        })
          .layoutWeight(1)
          .onChange((value: number) => {
            this.volume = value / 100;
            this.playerService.setVolume(this.volume);
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  private formatTime(ms: number): string {
    const seconds = Math.floor(ms / 1000);
    const minutes = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${minutes}:${secs.toString().padStart(2, '0')}`;
  }
}
```

---

## 第六步：测试验证

### 6.1 编译项目

```bash
# 使用 /build skill 编译项目
/build
```

### 6.2 运行模拟器

```bash
# 使用 /run-emulator skill 运行模拟器
/run-emulator
```

### 6.3 测试清单

- [ ] 本地音乐播放
- [ ] 网络电台播放
- [ ] 后台播放（锁屏后继续播放）
- [ ] 音频打断（来电暂停）
- [ ] 播放列表管理
- [ ] 进度控制
- [ ] 音量控制

---

## 常见问题

### Q1: 后台播放不工作？
确保：
1. 已注册 AVSession
2. 已申请长时任务权限
3. module.json5 中已添加 KEEP_BACKGROUND_RUNNING 权限

### Q2: 网络电台无法播放？
确保：
1. 设备已连接网络
2. 已添加 INTERNET 权限
3. URL 使用 HTTPS 协议

### Q3: 本地音乐无法读取？
确保：
1. 已添加 READ_MEDIA 权限
2. 用户已授权媒体访问权限

---

## 参考资源

- [音频播放系列开发实践](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-audio-playback-series)
- [基于AVPlayer播放格式化音频](https://developer.huawei.com/consumer/cn/doc/best-practices/bpta-playing-formatted-audio-based-avplayer-arkts)
- [HarmonyOS 开发实践——基于AVPlayer音频后台播放](https://cloud.tencent.com/developer/article/2474687)
- [Radio Browser API](https://de1.api.radio-browser.info)
