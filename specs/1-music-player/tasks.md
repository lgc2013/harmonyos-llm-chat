# 任务列表：音乐播放器

**创建日期**：2026-03-18
**分支**：1-music-player
**功能规范**：[spec.md](./spec.md)
**实施计划**：[plan.md](./plan.md)
**开发模式**：TDD（测试驱动开发）

---

## TDD 开发模式

本项目严格遵循红-绿-重构循环：

1. 🔴 **红**：先编写失败的测试用例
2. 🟢 **绿**：编写最少代码使测试通过
3. 🔄 **重构**：优化代码结构

每个用户故事阶段都遵循：**测试任务 → 实现任务 → 重构任务**

---

## 用户故事映射

| 故事 | 名称 | 需求 | 优先级 |
|------|------|------|--------|
| US1 | 本地音乐库展示 | 音乐库展示 | P1 |
| US2 | 播放控制 | 播放控制、进度控制、音量控制、播放模式 | P1 |
| US3 | 后台播放 | 后台播放支持、音频打断处理 | P1 |
| US4 | 网络电台 | 网络音乐播放、网络电台浏览 | P1 |
| US5 | 播放列表管理 | 播放列表管理 | P2 |

---

## 阶段 1：项目设置

**目标**：创建项目基础结构和配置

### 任务清单

- [X] T001 创建音乐播放器模块目录结构 `entry/src/main/ets/musicplayer/`
- [X] T002 [P] 创建测试目录结构 `entry/src/ohosTest/ets/musicplayer/`
- [X] T003 [P] 创建数据模型目录 `entry/src/main/ets/musicplayer/models/`
- [X] T004 [P] 创建服务层目录 `entry/src/main/ets/musicplayer/services/`
- [X] T005 [P] 创建视图模型目录 `entry/src/main/ets/musicplayer/viewmodels/`
- [X] T006 [P] 创建页面目录 `entry/src/main/ets/musicplayer/pages/`
- [X] T007 [P] 创建公共组件目录 `entry/src/main/ets/musicplayer/components/`
- [X] T008 [P] 创建工具类目录 `entry/src/main/ets/musicplayer/common/`
- [X] T009 配置 module.json5 添加必要权限 `entry/src/main/module.json5`

### 独立测试标准

- [X] 项目结构创建完成，目录层次正确
- [X] module.json5 包含所有必要权限配置

---

## 阶段 2：基础设施（TDD）

**目标**：实现所有用户故事共享的基础组件

### 🔴 红：测试任务

- [X] T010 [P] 编写 MusicTrack 数据模型测试 `entry/src/ohosTest/ets/musicplayer/models/MusicTrack.test.ets`
- [X] T011 [P] 编写 RadioStation 数据模型测试 `entry/src/ohosTest/ets/musicplayer/models/RadioStation.test.ets`
- [X] T012 [P] 编写 Playlist 数据模型测试 `entry/src/ohosTest/ets/musicplayer/models/Playlist.test.ets`
- [X] T013 [P] 编写 PlaylistItem 数据模型测试 `entry/src/ohosTest/ets/musicplayer/models/PlaylistItem.test.ets`
- [X] T014 [P] 编写 PlayerState 数据模型测试 `entry/src/ohosTest/ets/musicplayer/models/PlayerState.test.ets`
- [X] T015 [P] 编写枚举类型测试 `entry/src/ohosTest/ets/musicplayer/models/Enums.test.ets`
- [X] T016 [P] 编写工具函数测试 `entry/src/ohosTest/ets/musicplayer/common/Utils.test.ets`

### 🟢 绿：实现任务

- [X] T017 [P] 实现 MusicTrack 数据模型 `entry/src/main/ets/musicplayer/models/MusicTrack.ets`
- [X] T018 [P] 实现 RadioStation 数据模型 `entry/src/main/ets/musicplayer/models/RadioStation.ets`
- [X] T019 [P] 实现 Playlist 数据模型 `entry/src/main/ets/musicplayer/models/Playlist.ets`
- [X] T020 [P] 实现 PlaylistItem 数据模型 `entry/src/main/ets/musicplayer/models/PlaylistItem.ets`
- [X] T021 [P] 实现 PlayerState 数据模型 `entry/src/main/ets/musicplayer/models/PlayerState.ets`
- [X] T022 [P] 实现 LibraryState 数据模型 `entry/src/main/ets/musicplayer/models/LibraryState.ets`
- [X] T023 [P] 实现枚举类型定义 `entry/src/main/ets/musicplayer/models/Enums.ets`
- [X] T024 [P] 实现常量定义 `entry/src/main/ets/musicplayer/common/Constants.ets`
- [X] T025 [P] 实现错误码定义 `entry/src/main/ets/musicplayer/common/ErrorCodes.ets`
- [X] T026 [P] 实现工具函数 `entry/src/main/ets/musicplayer/common/Utils.ets`

### 🔄 重构任务

- [X] T027 审查并优化数据模型代码结构

### 独立测试标准

- [ ] 所有测试用例通过
- [ ] 所有数据模型编译通过

---

## 阶段 3：US1 - 本地音乐库展示（TDD）

**用户故事**：作为用户，我希望看到设备中可用的音乐文件列表，显示歌曲名称、艺术家、专辑信息

**验收标准**：用户能够看到所有支持的音频文件，并按歌曲名称排序显示

### 🔴 红：测试任务

- [X] T028 编写 LocalMusicService 扫描测试 `entry/src/ohosTest/ets/musicplayer/services/LocalMusicService.test.ets`
- [X] T029 编写音频元数据提取测试 `entry/src/ohosTest/ets/musicplayer/services/LocalMusicService.test.ets`
- [X] T030 编写排序功能测试 `entry/src/ohosTest/ets/musicplayer/services/LocalMusicService.test.ets`
- [X] T031 编写 LocalMusicViewModel 测试 `entry/src/ohosTest/ets/musicplayer/viewmodels/LocalMusicViewModel.test.ets`
- [X] T031a 编写文件损坏处理测试（边缘情况） `entry/src/ohosTest/ets/musicplayer/services/LocalMusicService.error.test.ets`

### 🟢 绿：实现任务

- [X] T032 [US1] 实现 LocalMusicService 扫描本地音乐 `entry/src/main/ets/musicplayer/services/LocalMusicService.ets`
- [X] T033 [US1] 实现音频元数据提取（标题、艺术家、专辑、时长） `entry/src/main/ets/musicplayer/services/LocalMusicService.ets`
- [X] T034 [US1] 实现按歌曲名排序功能 `entry/src/main/ets/musicplayer/services/LocalMusicService.ets`
- [X] T035 [US1] 实现 LocalMusicViewModel 管理音乐列表状态 `entry/src/main/ets/musicplayer/viewmodels/LocalMusicViewModel.ets`
- [X] T036 [US1] 实现本地音乐列表页面 UI `entry/src/main/ets/musicplayer/pages/LocalMusicPage.ets`
- [X] T037 [US1] [P] 实现音乐列表项组件 `entry/src/main/ets/musicplayer/components/TrackListItem.ets`
- [X] T038 [US1] [P] 实现空状态提示组件 `entry/src/main/ets/musicplayer/components/EmptyState.ets`
- [X] T039 [US1] 集成 LocalMusicPage 到应用导航 `entry/src/main/ets/musicplayer/pages/IndexPage.ets`

### 🔄 重构任务

- [X] T040 优化 LocalMusicService 性能（异步加载）
- [X] T041 优化 UI 组件可复用性

### 独立测试标准

- [ ] 所有测试用例通过
- [ ] 能够扫描并显示本地音乐文件列表
- [ ] 音乐列表按歌曲名称排序
- [ ] 无音乐时显示空状态提示

### TDD 执行流程

```
🔴 T028-T031 (测试) ──> 🟢 T032-T039 (实现) ──> 🔄 T040-T041 (重构)
```

---

## 阶段 4：US2 - 播放控制（TDD）

**用户故事**：作为用户，我希望能够控制播放（播放、暂停、上一首、下一首、进度、音量、播放模式）

**验收标准**：
- 播放控制操作在 500ms 内响应
- 进度跳转误差不超过 1 秒
- 音量变化立即生效

### 🔴 红：测试任务

- [X] T042 编写 PlayerService 初始化测试 `entry/src/ohosTest/ets/musicplayer/services/PlayerService.test.ets`
- [X] T043 编写 play()/pause()/stop() 测试 `entry/src/ohosTest/ets/musicplayer/services/PlayerService.test.ets`
- [X] T044 编写 next()/previous() 测试 `entry/src/ohosTest/ets/musicplayer/services/PlayerService.test.ets`
- [X] T045 编写 seekTo() 进度跳转测试 `entry/src/ohosTest/ets/musicplayer/services/PlayerService.test.ets`
- [X] T046 编写 setVolume() 音量测试 `entry/src/ohosTest/ets/musicplayer/services/PlayerService.test.ets`
- [X] T047 编写 setPlayMode() 播放模式测试 `entry/src/ohosTest/ets/musicplayer/services/PlayerService.test.ets`
- [X] T048 编写播放队列管理测试 `entry/src/ohosTest/ets/musicplayer/services/PlayerService.test.ets`
- [X] T049 编写 PlayerViewModel 测试 `entry/src/ohosTest/ets/musicplayer/viewmodels/PlayerViewModel.test.ets`

### 🟢 绿：实现任务

- [X] T050 [US2] 实现 PlayerService 基础（AVPlayer 初始化） `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T051 [US2] 实现 play() 播放方法 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T052 [US2] 实现 pause() 暂停方法 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T053 [US2] 实现 stop() 停止方法 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T054 [US2] 实现 next() 下一首方法 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T055 [US2] 实现 previous() 上一首方法 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T056 [US2] 实现 seekTo() 进度跳转方法 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T057 [US2] 实现 setVolume() 音量设置方法 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T058 [US2] 实现 setPlayMode() 播放模式设置 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T059 [US2] 实现播放队列管理 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T060 [US2] 实现 PlayerViewModel 管理播放状态 `entry/src/main/ets/musicplayer/viewmodels/PlayerViewModel.ets`
- [X] T061 [US2] 实现播放器主界面 UI `entry/src/main/ets/musicplayer/pages/PlayerPage.ets`
- [X] T062 [US2] [P] 实现播放控制按钮组件 `entry/src/main/ets/musicplayer/components/PlayerControls.ets`
- [X] T063 [US2] [P] 实现进度条组件 `entry/src/main/ets/musicplayer/components/ProgressBar.ets`
- [X] T064 [US2] [P] 实现音量滑块组件 `entry/src/main/ets/musicplayer/components/VolumeSlider.ets`
- [X] T065 [US2] [P] 实现播放模式切换按钮 `entry/src/main/ets/musicplayer/components/PlayModeButton.ets`

### 🔄 重构任务

- [X] T066 优化 PlayerService 响应性能（< 500ms）
- [X] T067 优化进度跳转精度（误差 < 1 秒）

### 独立测试标准

- [ ] 所有测试用例通过
- [ ] 播放/暂停操作响应时间 < 500ms
- [ ] 上一首/下一首正常切换
- [ ] 进度跳转误差 < 1 秒
- [ ] 音量调节立即生效
- [ ] 播放模式切换正常

### TDD 执行流程

```
🔴 T042-T049 (测试) ──> 🟢 T050-T065 (实现) ──> 🔄 T066-T067 (重构)
```

---

## 阶段 5：US3 - 后台播放（TDD）

**用户故事**：作为用户，我希望切换到其他应用或锁屏后，音乐继续播放不中断

**验收标准**：
- 用户切换应用后，音乐继续播放
- 用户锁屏后，音乐继续播放
- 来电/闹钟时正确暂停和恢复

### 🔴 红：测试任务

- [X] T068 编写 AVSession 创建和激活测试 `entry/src/ohosTest/ets/musicplayer/services/PlayerService.background.test.ets`
- [X] T069 编写长时任务申请/取消测试 `entry/src/ohosTest/ets/musicplayer/services/PlayerService.background.test.ets`
- [X] T070 编写 audioInterrupt 事件处理测试 `entry/src/ohosTest/ets/musicplayer/services/PlayerService.background.test.ets`
- [X] T071 编写耳机拔出自动暂停测试 `entry/src/ohosTest/ets/musicplayer/services/PlayerService.background.test.ets`
- [X] T071a 编写蓝牙设备切换处理测试（边缘情况） `entry/src/ohosTest/ets/musicplayer/services/PlayerService.background.test.ets`

### 🟢 绿：实现任务

- [X] T072 [US3] 实现 AVSession 创建和激活 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T073 [US3] 实现 AVSession 元数据设置（当前播放信息） `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T074 [US3] 实现 AVSession 播放控制回调（锁屏控制） `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T075 [US3] 实现长时任务申请 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T076 [US3] 实现长时任务取消 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T077 [US3] 实现 audioInterrupt 事件监听 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T078 [US3] 实现来电/闹钟打断处理逻辑 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T079 [US3] 实现耳机拔出自动暂停 `entry/src/main/ets/musicplayer/services/PlayerService.ets`
- [X] T080 [US3] 实现迷你播放器组件 `entry/src/main/ets/musicplayer/components/MiniPlayer.ets`

### 🔄 重构任务

- [X] T081 优化后台播放稳定性
- [X] T082 优化电量消耗（< 5%/小时）

### 独立测试标准

- [ ] 所有测试用例通过
- [ ] 切换到其他应用后音乐继续播放
- [ ] 锁屏后音乐继续播放
- [ ] 锁屏界面显示播放控制
- [ ] 来电时音乐暂停，挂断后恢复
- [ ] 耳机拔出时自动暂停

### TDD 执行流程

```
🔴 T068-T071 (测试) ──> 🟢 T072-T080 (实现) ──> 🔄 T081-T082 (重构)
```

---

## 阶段 6：US4 - 网络电台（TDD）

**用户故事**：作为用户，我希望能够浏览、搜索和播放网络电台

**验收标准**：
- 用户能够浏览网络电台列表
- 搜索结果在 2 秒内返回
- 点击电台能够播放网络音乐流

### 🔴 红：测试任务

- [X] T083 编写 RadioService HTTP 客户端测试 `entry/src/ohosTest/ets/musicplayer/services/RadioService.test.ets`
- [X] T084 编写 getTopStations() 测试 `entry/src/ohosTest/ets/musicplayer/services/RadioService.test.ets`
- [X] T085 编写 getByCountry()/getByTag() 测试 `entry/src/ohosTest/ets/musicplayer/services/RadioService.test.ets`
- [X] T086 编写 search() 搜索测试 `entry/src/ohosTest/ets/musicplayer/services/RadioService.test.ets`
- [X] T087 编写 RadioViewModel 测试 `entry/src/ohosTest/ets/musicplayer/viewmodels/RadioViewModel.test.ets`
- [X] T088 编写网络错误处理测试 `entry/src/ohosTest/ets/musicplayer/services/RadioService.test.ets`

### 🟢 绿：实现任务

- [X] T089 [US4] 实现 RadioService HTTP 客户端 `entry/src/main/ets/musicplayer/services/RadioService.ets`
- [X] T090 [US4] 实现 getTopStations() 获取热门电台 `entry/src/main/ets/musicplayer/services/RadioService.ets`
- [X] T091 [US4] 实现 getByCountry() 按国家筛选 `entry/src/main/ets/musicplayer/services/RadioService.ets`
- [X] T092 [US4] 实现 getByTag() 按类型筛选 `entry/src/main/ets/musicplayer/services/RadioService.ets`
- [X] T093 [US4] 实现 search() 搜索电台 `entry/src/main/ets/musicplayer/services/RadioService.ets`
- [X] T094 [US4] 实现 getCountries() 获取国家列表 `entry/src/main/ets/musicplayer/services/RadioService.ets`
- [X] T095 [US4] 实现 getTags() 获取类型标签列表 `entry/src/main/ets/musicplayer/services/RadioService.ets`
- [X] T096 [US4] 实现 RadioViewModel 管理电台状态 `entry/src/main/ets/musicplayer/viewmodels/RadioViewModel.ets`
- [X] T097 [US4] 实现电台列表页面 UI `entry/src/main/ets/musicplayer/pages/RadioListPage.ets`
- [X] T098 [US4] [P] 实现电台列表项组件 `entry/src/main/ets/musicplayer/components/RadioListItem.ets`
- [X] T099 [US4] [P] 实现国家筛选组件 `entry/src/main/ets/musicplayer/components/CountryFilter.ets`
- [X] T100 [US4] [P] 实现类型筛选组件 `entry/src/main/ets/musicplayer/components/TagFilter.ets`
- [X] T101 [US4] 实现网络错误提示 `entry/src/main/ets/musicplayer/components/NetworkError.ets`
- [X] T102 [US4] 实现缓冲状态显示 `entry/src/main/ets/musicplayer/components/BufferingIndicator.ets`
- [X] T103 [US4] 集成电台播放与 PlayerService `entry/src/main/ets/musicplayer/services/PlayerService.ets`

### 🔄 重构任务

- [X] T104 优化网络请求性能（搜索 < 2 秒）
- [X] T105 优化网络流媒体缓冲机制

### 独立测试标准

- [ ] 所有测试用例通过
- [ ] 能够获取并显示热门电台列表
- [ ] 按国家筛选正常工作
- [ ] 按类型筛选正常工作
- [ ] 搜索结果在 2 秒内返回
- [ ] 点击电台能够播放
- [ ] 网络错误时显示提示
- [ ] 缓冲时显示加载状态

### TDD 执行流程

```
🔴 T083-T088 (测试) ──> 🟢 T089-T103 (实现) ──> 🔄 T104-T105 (重构)
```

---

## 阶段 7：US5 - 播放列表管理（TDD）

**用户故事**：作为用户，我希望能够创建、编辑、删除自定义播放列表

**验收标准**：
- 用户能够创建新播放列表
- 用户能够将歌曲添加到播放列表
- 用户能够从播放列表移除歌曲
- 用户能够重命名和删除播放列表

### 🔴 红：测试任务

- [X] T106 编写 PlaylistService CRUD 测试 `entry/src/ohosTest/ets/musicplayer/services/PlaylistService.test.ets`
- [X] T107 编写 addItem()/removeItem() 测试 `entry/src/ohosTest/ets/musicplayer/services/PlaylistService.test.ets`
- [X] T108 编写 Preferences 存储测试 `entry/src/ohosTest/ets/musicplayer/services/PlaylistService.test.ets`
- [X] T109 编写 PlaylistViewModel 测试 `entry/src/ohosTest/ets/musicplayer/viewmodels/PlaylistViewModel.test.ets`
- [X] T110 编写播放列表边界测试（最大 500 项） `entry/src/ohosTest/ets/musicplayer/services/PlaylistService.test.ets`

### 🟢 绿：实现任务

- [X] T111 [US5] 实现 PlaylistService Preferences 存储 `entry/src/main/ets/musicplayer/services/PlaylistService.ets`
- [X] T112 [US5] 实现 getAll() 获取所有播放列表 `entry/src/main/ets/musicplayer/services/PlaylistService.ets`
- [X] T113 [US5] 实现 create() 创建播放列表 `entry/src/main/ets/musicplayer/services/PlaylistService.ets`
- [X] T114 [US5] 实现 update() 更新播放列表 `entry/src/main/ets/musicplayer/services/PlaylistService.ets`
- [X] T115 [US5] 实现 delete() 删除播放列表 `entry/src/main/ets/musicplayer/services/PlaylistService.ets`
- [X] T116 [US5] 实现 addItem() 添加项目到列表 `entry/src/main/ets/musicplayer/services/PlaylistService.ets`
- [X] T117 [US5] 实现 removeItem() 从列表移除项目 `entry/src/main/ets/musicplayer/services/PlaylistService.ets`
- [X] T118 [US5] 实现 PlaylistViewModel 管理播放列表状态 `entry/src/main/ets/musicplayer/viewmodels/PlaylistViewModel.ets`
- [X] T119 [US5] 实现播放列表页面 UI `entry/src/main/ets/musicplayer/pages/PlaylistPage.ets`
- [X] T120 [US5] [P] 实现播放列表项组件 `entry/src/main/ets/musicplayer/components/PlaylistItem.ets`
- [X] T121 [US5] [P] 实现创建播放列表对话框 `entry/src/main/ets/musicplayer/components/CreatePlaylistDialog.ets`
- [X] T122 [US5] [P] 实现添加到播放列表对话框 `entry/src/main/ets/musicplayer/components/AddToPlaylistDialog.ets`
- [X] T123 [US5] 实现播放列表详情页面 `entry/src/main/ets/musicplayer/pages/PlaylistDetailPage.ets`
- [X] T124 [US5] 集成播放列表播放与 PlayerService `entry/src/main/ets/musicplayer/services/PlayerService.ets`

### 🔄 重构任务

- [X] T125 优化 PlaylistService 存储性能
- [X] T126 优化大数据量列表渲染

### 独立测试标准

- [ ] 所有测试用例通过
- [ ] 能够创建新播放列表
- [ ] 能够将歌曲添加到播放列表
- [ ] 能够从播放列表移除歌曲
- [ ] 能够重命名播放列表
- [ ] 能够删除播放列表
- [ ] 播放列表数据持久化

### TDD 执行流程

```
🔴 T106-T110 (测试) ──> 🟢 T111-T124 (实现) ──> 🔄 T125-T126 (重构)
```

---

## 阶段 8：UI 集成与优化

**目标**：整合所有页面，优化 UX 体验

### 🔴 红：测试任务

- [X] T127 编写深色模式切换测试 `entry/src/ohosTest/ets/musicplayer/common/Theme.test.ets`
- [X] T128 编写响应式布局测试 `entry/src/ohosTest/ets/musicplayer/common/ResponsiveLayout.test.ets`
- [X] T129 编写搜索功能测试 `entry/src/ohosTest/ets/musicplayer/pages/SearchPage.test.ets`

### 🟢 绿：实现任务

- [X] T130 实现主入口页面（底部导航） `entry/src/main/ets/musicplayer/pages/IndexPage.ets`
- [X] T131 [P] 实现深色模式支持 `entry/src/main/ets/musicplayer/common/Theme.ets`
- [X] T132 [P] 实现页面转场动画 `entry/src/main/ets/musicplayer/common/Transitions.ets`
- [X] T133 [P] 实现响应式布局适配 `entry/src/main/ets/musicplayer/common/ResponsiveLayout.ets`
- [X] T134 实现底部导航条避让 `entry/src/main/ets/musicplayer/pages/IndexPage.ets`
- [X] T135 实现状态栏沉浸式设计 `entry/src/main/ets/musicplayer/pages/IndexPage.ets`
- [X] T136 [P] 实现专辑封面显示组件 `entry/src/main/ets/musicplayer/components/AlbumArt.ets`
- [X] T137 [P] 实现搜索功能（可选需求#2） `entry/src/main/ets/musicplayer/pages/SearchPage.ets`

### 🔄 重构任务

- [X] T138 性能优化（内存 < 100MB）
- [X] T139 UX 优化（动效、交互）
- [X] T140 代码审查和清理

### 独立测试标准

- [ ] 所有测试用例通过
- [ ] 底部导航正常切换页面
- [ ] 深色模式显示正常
- [ ] 页面转场动画流畅
- [ ] 不同屏幕尺寸适配良好
- [ ] 内存占用 < 100MB
- [ ] 符合 UX 体验标准

---

## 依赖关系图

```
阶段1 (设置) ──> 阶段2 (基础设施 TDD)
                      │
                      ├──> 阶段3 (US1 本地音乐 TDD) ──┐
                      │                              │
                      ├──> 阶段4 (US2 播放控制 TDD) ──┼──> 阶段8 (集成优化)
                      │                              │
                      ├──> 阶段5 (US3 后台播放 TDD) ──┤
                      │                              │
                      ├──> 阶段6 (US4 网络电台 TDD) ──┤
                      │                              │
                      └──> 阶段7 (US5 播放列表 TDD) ──┘
```

---

## MVP 范围建议（TDD）

**MVP（最小可行产品）包含**：
- 阶段 1：项目设置
- 阶段 2：基础设施（TDD）
- 阶段 3：US1 本地音乐库展示（TDD）
- 阶段 4：US2 播放控制（TDD）
- 阶段 5：US3 后台播放（TDD）

**后续迭代**：
- 阶段 6：US4 网络电台（TDD）
- 阶段 7：US5 播放列表管理（TDD）
- 阶段 8：UI 集成与优化

---

## 任务统计

| 统计项 | 数量 |
|--------|------|
| **总任务数** | **142** |
| 🔴 测试任务 | 35 |
| 🟢 实现任务 | 92 |
| 🔄 重构任务 | 15 |

### 各阶段任务分布

| 阶段 | 测试 | 实现 | 重构 | 合计 |
|------|------|------|------|------|
| 阶段1 设置 | 0 | 9 | 0 | 9 |
| 阶段2 基础设施 | 7 | 10 | 1 | 18 |
| US1 本地音乐 | 5 | 8 | 2 | 15 |
| US2 播放控制 | 8 | 16 | 2 | 26 |
| US3 后台播放 | 5 | 9 | 2 | 16 |
| US4 网络电台 | 6 | 15 | 2 | 23 |
| US5 播放列表 | 5 | 14 | 2 | 21 |
| 阶段8 集成优化 | 3 | 8 | 3 | 14 |

---

## 测试文件结构

```
entry/src/ohosTest/ets/musicplayer/
├── models/
│   ├── MusicTrack.test.ets
│   ├── RadioStation.test.ets
│   ├── Playlist.test.ets
│   ├── PlaylistItem.test.ets
│   ├── PlayerState.test.ets
│   └── Enums.test.ets
├── services/
│   ├── LocalMusicService.test.ets
│   ├── PlayerService.test.ets
│   ├── PlayerService.background.test.ets
│   ├── RadioService.test.ets
│   └── PlaylistService.test.ets
├── viewmodels/
│   ├── LocalMusicViewModel.test.ets
│   ├── PlayerViewModel.test.ets
│   ├── RadioViewModel.test.ets
│   └── PlaylistViewModel.test.ets
├── common/
│   ├── Utils.test.ets
│   ├── Theme.test.ets
│   └── ResponsiveLayout.test.ets
└── pages/
    └── SearchPage.test.ets
```

---

## 下一步

执行 `/speckit.implement` 开始按 TDD 方式实施任务。

**TDD 执行顺序**：
1. 🔴 先运行测试（预期失败）
2. 🟢 编写最小实现代码
3. 🟢 运行测试（预期通过）
4. 🔄 重构优化
5. 🟢 再次运行测试（确保通过）
