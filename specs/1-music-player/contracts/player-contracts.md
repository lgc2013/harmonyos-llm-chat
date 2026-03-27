# 接口契约：音乐播放器

**创建日期**：2026-03-18
**版本**：1.0

## 概述

本文档定义音乐播放器的核心接口契约，包括播放控制、播放列表管理、网络电台和本地音乐库的接口规范。

---

## 1. 播放控制接口 (IPlayerController)

负责音频播放的核心控制。

### 方法

#### 1.1 播放

```typescript
play(item?: PlaylistItem): Promise<void>
```

**描述**：开始播放指定项目，若无参数则恢复当前播放

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| item | PlaylistItem | 否 | 要播放的项目 |

**返回**：Promise\<void>

**异常**：
| 错误码 | 说明 |
|--------|------|
| PLAYER_NO_ITEM | 无可播放项目 |
| PLAYER_SOURCE_ERROR | 音频源无效 |
| PLAYER_NETWORK_ERROR | 网络错误 |

---

#### 1.2 暂停

```typescript
pause(): Promise<void>
```

**描述**：暂停当前播放

**返回**：Promise\<void>

---

#### 1.3 停止

```typescript
stop(): Promise<void>
```

**描述**：停止播放并重置状态

**返回**：Promise\<void>

---

#### 1.4 下一首

```typescript
next(): Promise<void>
```

**描述**：播放下一首

**返回**：Promise\<void>

**异常**：
| 错误码 | 说明 |
|--------|------|
| PLAYER_NO_NEXT | 无下一首 |

---

#### 1.5 上一首

```typescript
previous(): Promise<void>
```

**描述**：播放上一首

**返回**：Promise\<void>

**异常**：
| 错误码 | 说明 |
|--------|------|
| PLAYER_NO_PREVIOUS | 无上一首 |

---

#### 1.6 跳转

```typescript
seekTo(positionMs: number): Promise<void>
```

**描述**：跳转到指定位置

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| positionMs | number | 是 | 目标位置（毫秒） |

**返回**：Promise\<void>

**异常**：
| 错误码 | 说明 |
|--------|------|
| PLAYER_SEEK_ERROR | 跳转失败 |

---

#### 1.7 设置音量

```typescript
setVolume(volume: number): Promise<void>
```

**描述**：设置播放音量

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| volume | number | 是 | 音量值（0.0 - 1.0） |

**返回**：Promise\<void>

**验证**：volume 必须 >= 0 且 <= 1

---

#### 1.8 设置播放模式

```typescript
setPlayMode(mode: PlayMode): Promise<void>
```

**描述**：设置播放模式

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| mode | PlayMode | 是 | 播放模式 |

**返回**：Promise\<void>

---

#### 1.9 设置播放队列

```typescript
setQueue(items: PlaylistItem[], startIndex?: number): Promise<void>
```

**描述**：设置播放队列

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| items | PlaylistItem[] | 是 | 播放队列 |
| startIndex | number | 否 | 起始索引，默认 0 |

**返回**：Promise\<void>

---

### 事件

```typescript
on(event: PlayerEvent, callback: (data: PlayerEventData) => void): void
```

| 事件 | 数据类型 | 说明 |
|------|----------|------|
| stateChange | PlayerState | 播放状态变化 |
| progress | ProgressData | 播放进度更新 |
| error | PlayerError | 播放错误 |
| interrupt | InterruptEvent | 音频打断事件 |
| queueEnd | void | 队列播放完毕 |

---

## 2. 播放列表管理接口 (IPlaylistManager)

负责播放列表的增删改查。

### 方法

#### 2.1 获取所有播放列表

```typescript
getAll(): Promise<Playlist[]>
```

**描述**：获取所有播放列表

**返回**：Promise\<Playlist[]>

---

#### 2.2 获取播放列表

```typescript
getById(id: string): Promise<Playlist | null>
```

**描述**：根据 ID 获取播放列表

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | 是 | 播放列表 ID |

**返回**：Promise\<Playlist | null>

---

#### 2.3 创建播放列表

```typescript
create(name: string): Promise<Playlist>
```

**描述**：创建新播放列表

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | 是 | 列表名称 |

**返回**：Promise\<Playlist>

**验证**：
- name 不能为空
- name 最大长度 50 字符

**异常**：
| 错误码 | 说明 |
|--------|------|
| PLAYLIST_NAME_EMPTY | 名称为空 |
| PLAYLIST_NAME_TOO_LONG | 名称过长 |

---

#### 2.4 更新播放列表

```typescript
update(id: string, data: Partial<Playlist>): Promise<void>
```

**描述**：更新播放列表信息

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | 是 | 播放列表 ID |
| data | Partial\<Playlist\> | 是 | 更新数据 |

**返回**：Promise\<void>

---

#### 2.5 删除播放列表

```typescript
delete(id: string): Promise<void>
```

**描述**：删除播放列表

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| id | string | 是 | 播放列表 ID |

**返回**：Promise\<void>

**异常**：
| 错误码 | 说明 |
|--------|------|
| PLAYLIST_NOT_FOUND | 列表不存在 |
| PLAYLIST_IS_SYSTEM | 系统列表不可删除 |

---

#### 2.6 添加项目到列表

```typescript
addItem(playlistId: string, item: PlaylistItem): Promise<void>
```

**描述**：添加项目到播放列表

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| playlistId | string | 是 | 播放列表 ID |
| item | PlaylistItem | 是 | 要添加的项目 |

**返回**：Promise\<void>

**异常**：
| 错误码 | 说明 |
|--------|------|
| PLAYLIST_NOT_FOUND | 列表不存在 |
| PLAYLIST_FULL | 列表已满（500 项） |
| PLAYLIST_DUPLICATE | 项目已存在 |

---

#### 2.7 从列表移除项目

```typescript
removeItem(playlistId: string, itemId: string): Promise<void>
```

**描述**：从播放列表移除项目

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| playlistId | string | 是 | 播放列表 ID |
| itemId | string | 是 | 项目 ID |

**返回**：Promise\<void>

---

## 3. 网络电台接口 (IRadioService)

负责网络电台的搜索和获取。

### 方法

#### 3.1 获取热门电台

```typescript
getTopStations(limit?: number): Promise<RadioStation[]>
```

**描述**：获取热门电台列表

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| limit | number | 否 | 返回数量，默认 100 |

**返回**：Promise\<RadioStation[]>

**超时**：10000ms

---

#### 3.2 按国家搜索

```typescript
getByCountry(country: string, limit?: number): Promise<RadioStation[]>
```

**描述**：按国家获取电台

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| country | string | 是 | 国家名称或代码 |
| limit | number | 否 | 返回数量，默认 50 |

**返回**：Promise\<RadioStation[]>

---

#### 3.3 按类型搜索

```typescript
getByTag(tag: string, limit?: number): Promise<RadioStation[]>
```

**描述**：按类型标签获取电台

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| tag | string | 是 | 类型标签 |
| limit | number | 否 | 返回数量，默认 50 |

**返回**：Promise\<RadioStation[]>

---

#### 3.4 搜索电台

```typescript
search(query: string, limit?: number): Promise<RadioStation[]>
```

**描述**：搜索电台

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| query | string | 是 | 搜索关键词 |
| limit | number | 否 | 返回数量，默认 50 |

**返回**：Promise\<RadioStation[]>

**验证**：query 最小长度 2 字符

---

#### 3.5 获取可用国家列表

```typescript
getCountries(): Promise<CountryInfo[]>
```

**描述**：获取所有可用国家

**返回**：Promise\<CountryInfo[]>

---

#### 3.6 获取可用类型标签

```typescript
getTags(): Promise<TagInfo[]>
```

**描述**：获取所有可用类型标签

**返回**：Promise\<TagInfo[]>

---

### API 端点映射

| 方法 | HTTP | 端点 |
|------|------|------|
| getTopStations | GET | `/json/stations/topvote/{limit}` |
| getByCountry | GET | `/json/stations/bycountry/{country}` |
| getByTag | GET | `/json/stations/bytag/{tag}` |
| search | GET | `/json/stations/search?name={query}` |
| getCountries | GET | `/json/countries` |
| getTags | GET | `/json/tags` |

**基础 URL**：`https://de1.api.radio-browser.info`

---

## 4. 本地音乐库接口 (ILocalMusicLibrary)

负责本地音乐文件的管理。

### 方法

#### 4.1 扫描本地音乐

```typescript
scanLibrary(): Promise<MusicTrack[]>
```

**描述**：扫描设备本地音乐文件

**返回**：Promise\<MusicTrack[]>

**权限**：需要媒体文件访问权限

**异常**：
| 错误码 | 说明 |
|--------|------|
| PERMISSION_DENIED | 权限被拒绝 |
| SCAN_ERROR | 扫描失败 |

---

#### 4.2 获取所有音乐

```typescript
getAllTracks(): Promise<MusicTrack[]>
```

**描述**：获取所有已扫描的音乐

**返回**：Promise\<MusicTrack[]>

---

#### 4.3 按艺术家筛选

```typescript
getByArtist(artist: string): Promise<MusicTrack[]>
```

**描述**：按艺术家筛选音乐

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| artist | string | 是 | 艺术家名称 |

**返回**：Promise\<MusicTrack[]>

---

#### 4.4 按专辑筛选

```typescript
getByAlbum(album: string): Promise<MusicTrack[]>
```

**描述**：按专辑筛选音乐

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| album | string | 是 | 专辑名称 |

**返回**：Promise\<MusicTrack[]>

---

#### 4.5 搜索

```typescript
search(query: string): Promise<MusicTrack[]>
```

**描述**：搜索本地音乐

**参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| query | string | 是 | 搜索关键词 |

**返回**：Promise\<MusicTrack[]>

---

## 5. 错误码定义

| 模块 | 错误码 | 说明 |
|------|--------|------|
| Player | PLAYER_NO_ITEM | 无可播放项目 |
| Player | PLAYER_SOURCE_ERROR | 音频源无效 |
| Player | PLAYER_NETWORK_ERROR | 网络错误 |
| Player | PLAYER_SEEK_ERROR | 跳转失败 |
| Player | PLAYER_NO_NEXT | 无下一首 |
| Player | PLAYER_NO_PREVIOUS | 无上一首 |
| Playlist | PLAYLIST_NOT_FOUND | 列表不存在 |
| Playlist | PLAYLIST_NAME_EMPTY | 名称为空 |
| Playlist | PLAYLIST_NAME_TOO_LONG | 名称过长 |
| Playlist | PLAYLIST_IS_SYSTEM | 系统列表不可删除 |
| Playlist | PLAYLIST_FULL | 列表已满 |
| Playlist | PLAYLIST_DUPLICATE | 项目已存在 |
| Library | PERMISSION_DENIED | 权限被拒绝 |
| Library | SCAN_ERROR | 扫描失败 |
| Radio | RADIO_NETWORK_ERROR | 网络错误 |
| Radio | RADIO_TIMEOUT | 请求超时 |

---

## 6. 类型定义

```typescript
interface ProgressData {
  currentTime: number;    // 当前位置（毫秒）
  duration: number;       // 总时长（毫秒）
  buffered: number;       // 缓冲进度（0-1）
}

interface InterruptEvent {
  type: InterruptType;
  hint: string;
}

enum InterruptType {
  BEGIN = 'begin',        // 打断开始
  END = 'end'             // 打断结束
}

interface CountryInfo {
  name: string;
  isoCode: string;
  stationCount: number;
}

interface TagInfo {
  name: string;
  stationCount: number;
}
```
