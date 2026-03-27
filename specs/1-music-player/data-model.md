# 数据模型：音乐播放器

**创建日期**：2026-03-18
**状态**：已完成

## 实体关系图

```
┌─────────────────┐     ┌─────────────────┐
│   MusicTrack    │     │  RadioStation   │
│   (本地音乐)     │     │   (网络电台)     │
└────────┬────────┘     └────────┬────────┘
         │                       │
         │     ┌─────────────────┤
         │     │                 │
         ▼     ▼                 ▼
┌─────────────────────────────────────────┐
│              PlaylistItem               │
│            (播放列表项)                  │
└────────────────┬────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────┐
│               Playlist                  │
│             (播放列表)                   │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│             PlayerState                 │
│           (播放状态)                     │
└─────────────────────────────────────────┘
```

---

## 实体定义

### 1. MusicTrack（本地音乐曲目）

本地音乐文件的信息模型。

```typescript
interface MusicTrack {
  // 唯一标识
  id: string;                    // 基于文件路径生成的唯一 ID

  // 基本信息
  title: string;                 // 歌曲名称
  artist: string;                // 艺术家
  album: string;                 // 专辑名称
  duration: number;              // 时长（毫秒）

  // 文件信息
  filePath: string;              // 本地文件路径
  fileSize: number;              // 文件大小（字节）
  format: AudioFormat;           // 音频格式

  // 元数据
  albumArt?: string;             // 专辑封面 URI
  trackNumber?: number;          // 曲目编号
  year?: number;                 // 发行年份

  // 时间戳
  dateAdded: number;             // 添加时间
  lastPlayed?: number;           // 最后播放时间
  playCount: number;             // 播放次数
}

enum AudioFormat {
  MP3 = 'mp3',
  AAC = 'aac',
  WAV = 'wav',
  FLAC = 'flac',
  M4A = 'm4a',
  OGG = 'ogg',
  UNKNOWN = 'unknown'
}
```

**验证规则**：
- `title` 不能为空，若元数据缺失则使用文件名
- `filePath` 必须是有效的本地文件路径
- `duration` 必须 > 0
- `id` 格式：`local_${filePathHash}`

---

### 2. RadioStation（网络电台）

Radio Browser API 返回的电台信息模型。

```typescript
interface RadioStation {
  // 唯一标识
  id: string;                    // Radio Browser API 的 stationuuid

  // 基本信息
  name: string;                  // 电台名称
  url: string;                   // 流媒体 URL
  urlResolved?: string;          // 解析后的实际 URL

  // 详细信息
  country: string;               // 国家
  countryCode: string;           // 国家代码（如 US, CN）
  state?: string;                // 州/省
  language?: string;             // 语言
  tags: string[];                // 标签（类型）

  // 统计信息
  votes: number;                 // 投票数
  clickCount: number;            // 点击次数
  clickTrend: number;            // 点击趋势

  // 其他信息
  favicon?: string;              // 电台图标 URL
  homepage?: string;             // 电台主页
  codec?: string;                // 编码格式（如 MP3, AAC）
  bitrate?: number;              // 比特率（kbps）
  hls?: boolean;                 // 是否为 HLS 流

  // 状态
  isOnline: boolean;             // 是否在线
  lastCheckTime?: string;        // 最后检查时间
}
```

**验证规则**：
- `id` 格式：`radio_${stationuuid}`
- `url` 必须是有效的 HTTPS URL
- `name` 不能为空

---

### 3. Playlist（播放列表）

用户自定义播放列表。

```typescript
interface Playlist {
  // 唯一标识
  id: string;                    // 自动生成的 UUID

  // 基本信息
  name: string;                  // 播放列表名称
  description?: string;          // 描述
  coverImage?: string;           // 封面图片 URI

  // 内容
  items: PlaylistItem[];         // 播放列表项

  // 统计
  totalCount: number;            // 总曲目数
  totalDuration: number;         // 总时长（毫秒）

  // 时间戳
  createdAt: number;             // 创建时间
  updatedAt: number;             // 更新时间

  // 来源
  isSystem: boolean;             // 是否为系统默认列表
}
```

**验证规则**：
- `name` 不能为空，最大长度 50 字符
- `id` 格式：`playlist_${uuid}`
- `items` 数量限制：0 - 500

---

### 4. PlaylistItem（播放列表项）

播放列表中的单个项目，可以是本地音乐或网络电台。

```typescript
interface PlaylistItem {
  // 唯一标识
  id: string;                    // 列表内唯一 ID

  // 来源类型
  type: PlaylistItemType;

  // 关联内容
  trackId: string;               // MusicTrack.id 或 RadioStation.id

  // 冗余存储（用于快速显示）
  title: string;                 // 标题
  subtitle: string;              // 副标题（艺术家或国家）
  thumbnail?: string;            // 缩略图

  // 排序
  order: number;                 // 在列表中的顺序

  // 时间戳
  addedAt: number;               // 添加时间
}

enum PlaylistItemType {
  LOCAL_MUSIC = 'local_music',
  RADIO_STATION = 'radio_station'
}
```

**验证规则**：
- `id` 格式：`item_${uuid}`
- `order` 从 0 开始递增
- `trackId` 必须引用有效的 MusicTrack 或 RadioStation

---

### 5. PlayerState（播放状态）

当前播放器的状态模型。

```typescript
interface PlayerState {
  // 当前播放内容
  currentTrack: PlaylistItem | null;
  currentIndex: number;          // 当前索引

  // 播放状态
  isPlaying: boolean;
  isBuffering: boolean;
  currentTime: number;           // 当前播放位置（毫秒）
  duration: number;              // 总时长（毫秒）

  // 音量
  volume: number;                // 音量 0-1

  // 播放模式
  playMode: PlayMode;
  shuffle: boolean;              // 是否随机播放
  repeat: RepeatMode;            // 循环模式

  // 播放队列
  queue: PlaylistItem[];
  queueSource: QueueSource;

  // 错误状态
  error?: PlayerError;
}

enum PlayMode {
  SEQUENCE = 'sequence',         // 顺序播放
  SHUFFLE = 'shuffle',           // 随机播放
  SINGLE = 'single'              // 单曲循环
}

enum RepeatMode {
  OFF = 'off',                   // 不循环
  ALL = 'all',                   // 列表循环
  ONE = 'one'                    // 单曲循环
}

enum QueueSource {
  LOCAL_LIBRARY = 'local_library',
  RADIO_LIST = 'radio_list',
  PLAYLIST = 'playlist',
  SEARCH_RESULT = 'search_result'
}

interface PlayerError {
  code: string;
  message: string;
  timestamp: number;
}
```

---

### 6. LibraryState（音乐库状态）

本地音乐库和电台的状态模型。

```typescript
interface LibraryState {
  // 本地音乐
  localTracks: MusicTrack[];
  localLoading: boolean;
  localError?: string;

  // 网络电台
  radioStations: RadioStation[];
  radioLoading: boolean;
  radioError?: string;

  // 搜索
  searchQuery: string;
  searchResults: RadioStation[];
  searchLoading: boolean;

  // 筛选
  selectedCountry?: string;
  selectedTag?: string;
}
```

---

## 状态转换

### 播放器状态转换

```
┌─────────┐   play()   ┌─────────┐   complete  ┌─────────┐
│  IDLE   │ ─────────▶ │PLAYING  │ ─────────▶ │NEXT_ITEM│
└─────────┘            └────┬────┘            └────┬────┘
     ▲                      │                      │
     │                  pause()                    │
     │                      ▼                      │
     │                 ┌─────────┐                 │
     │                 │ PAUSED  │                 │
     │                 └────┬────┘                 │
     │                      │                      │
     │           play() or error                   │
     │                      │                      │
     └──────────────────────┴──────────────────────┘
```

### 音频打断状态转换

```
┌─────────┐   interrupt    ┌─────────┐
│PLAYING  │ ─────────────▶ │INTERRUPT│
└─────────┘                │  (暂停)  │
     ▲                     └────┬────┘
     │                          │
     │                    resume
     │                          │
     └──────────────────────────┘
```

---

## 数据存储

### Preferences 存储

| 键名 | 类型 | 说明 |
|------|------|------|
| `playlists` | string (JSON) | 所有播放列表 |
| `player_volume` | number | 用户设置的音量 |
| `player_mode` | string | 播放模式 |
| `last_queue` | string (JSON) | 上次播放队列 |

### 内存缓存

| 数据 | 说明 |
|------|------|
| `localTracks` | 本地音乐列表（启动时加载） |
| `radioStations` | 电台列表（按需加载） |
| `playerState` | 当前播放状态 |

---

## 数据流向

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   用户操作    │ ──▶ │  ViewModel   │ ──▶ │   AVPlayer   │
└──────────────┘     └──────────────┘     └──────────────┘
                            │
                            ▼
                     ┌──────────────┐
                     │ Preferences  │
                     │   (持久化)    │
                     └──────────────┘
```
