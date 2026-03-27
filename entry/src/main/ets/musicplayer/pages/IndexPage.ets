/**
 * IndexPage 主页面
 * 音乐播放器主入口页面，包含底部标签导航和迷你播放器
 *
 * 遵循华为 UX 体验标准：
 * - 避让底部导航条（安全区域适配）
 * - 状态栏沉浸式设计
 * - 支持深色模式
 * - 平滑的标签切换动画
 */

import { MiniPlayer } from '../components/MiniPlayer';
import { PlayerViewModel, createPlayerViewModel } from '../viewmodels/PlayerViewModel';
import { LocalMusicViewModel, localMusicViewModel } from '../viewmodels/LocalMusicViewModel';
import radioViewModel from '../viewmodels/RadioViewModel';
import { PlaylistViewModel, createPlaylistViewModel } from '../viewmodels/PlaylistViewModel';
import { MusicTrack } from '../models/MusicTrack';
import { RadioStation } from '../models/RadioStation';
import { Playlist } from '../models/Playlist';
import neteaseMusicService, { NeteaseSong } from '../services/NeteaseMusicService';
import {
  getPlayerService,
  PlayerEventType,
  ProgressData,
  PlayerState,
  PlaylistItem
} from '../services/index';
import common from '@ohos.app.ability.common';

/**
 * 标签页项目接口
 */
interface TabItem {
  /** 标签名称 */
  name: string;
  /** 未选中图标 */
  icon: Resource;
  /** 选中图标 */
  activeIcon: Resource;
}

/**
 * 标签页索引枚举
 */
enum TabIndex {
  /** 本地音乐 */
  LOCAL_MUSIC = 0,
  /** 网易云音乐 */
  NETEASE_MUSIC = 1,
  /** 播放列表 */
  PLAYLIST = 2
}

/**
 * 标签页配置常量
 */
const TAB_ITEMS: TabItem[] = [
  {
    name: '本地音乐',
    icon: $r('sys.symbol.play_circle'),
    activeIcon: $r('sys.symbol.play_circle_fill')
  },
  {
    name: '网易云',
    icon: $r('sys.symbol.play_circle'),
    activeIcon: $r('sys.symbol.play_circle_fill')
  },
  {
    name: '播放列表',
    icon: $r('sys.symbol.list_bullet'),
    activeIcon: $r('sys.symbol.list_bullet')
  }
];

/**
 * 底部导航栏高度（不含安全区域）
 */
const TAB_BAR_HEIGHT: number = 56;

/**
 * 迷你播放器高度
 */
const MINI_PLAYER_HEIGHT: number = 66;

/**
 * 主页面组件
 * 包含标签导航和迷你播放器
 */
@Entry
@Component
struct IndexPage {
  /** 当前选中的标签索引 */
  @State private currentTabIndex: number = TabIndex.LOCAL_MUSIC;

  /** 是否显示迷你播放器 */
  @State private showMiniPlayer: boolean = false;

  /** 当前播放曲目标题 */
  @State private currentTrackTitle: string = '';

  /** 当前播放曲目艺术家 */
  @State private currentTrackArtist: string = '';

  /** 当前播放曲目封面 */
  @State private currentTrackAlbumArt: string | Resource = '';

  /** 是否正在播放 */
  @State private isPlaying: boolean = false;

  /** 播放进度（0-1） */
  @State private playProgress: number = 0;

  /** 当前播放时间（毫秒） */
  @State private currentTime: number = 0;

  /** 总时长（毫秒） */
  @State private duration: number = 0;

  /** 网络电台列表 */
  @State private radioStations: RadioStation[] = [];

  /** 网络电台是否正在加载 */
  @State private radioIsLoading: boolean = false;

  /** 网络电台错误信息 */
  @State private radioError: string | null = null;

  /** 电台状态版本号（用于强制UI刷新） */
  @State private radioStateVersion: number = 0;

  /** 网易云音乐歌曲列表 */
  @State private neteaseSongs: NeteaseSong[] = [];

  /** 网易云音乐是否正在加载 */
  @State private neteaseIsLoading: boolean = false;

  /** 网易云音乐错误信息 */
  @State private neteaseError: string | null = null;

  /** 网易云状态版本号 */
  @State private neteaseStateVersion: number = 0;

  /** 搜索关键词 */
  @State private searchKeyword: string = '';

  /** 播放器视图模型 */
  private playerViewModel: PlayerViewModel = createPlayerViewModel();

  /** 本地音乐视图模型 */
  private localMusicVM: LocalMusicViewModel = localMusicViewModel;

  /** 播放列表视图模型 */
  private playlistVM: PlaylistViewModel = createPlaylistViewModel();

  /** 应用上下文 */
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  /** 是否已初始化 */
  private isInitialized: boolean = false;

  /**
   * 页面即将显示时调用
   */
  aboutToAppear(): void {
    this.initializeViewModels();
  }

  /**
   * 页面即将消失时调用
   */
  aboutToDisappear(): void {
    // 清理资源（保留播放器状态）
    console.info('[IndexPage] 页面即将消失');
  }

  /**
   * 初始化所有视图模型
   */
  private async initializeViewModels(): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      // 初始化播放器视图模型
      await this.playerViewModel.initialize(this.context);
      this.setupPlayerCallbacks();

      // 初始化本地音乐视图模型
      await this.localMusicVM.initialize();

      // 初始化播放列表视图模型
      await this.playlistVM.initialize(this.context);

      // 加载网易云音乐热门歌曲
      await this.loadNeteaseHotSongs();

      this.isInitialized = true;
      console.info('[IndexPage] 所有视图模型初始化完成');
    } catch (error) {
      console.error(`[IndexPage] 初始化失败: ${(error as Error).message}`);
    }
  }

  /**
   * 设置网络电台回调
   */
  private setupRadioCallbacks(): void {
    radioViewModel.setOnStationsChanged(() => {
      this.radioStations = radioViewModel.getStations();
      this.radioStateVersion++; // 强制UI刷新
      console.info(`[IndexPage] 电台列表更新: ${this.radioStations.length} 个, version=${this.radioStateVersion}`);
    });

    radioViewModel.setOnLoadingChanged((loading: boolean) => {
      this.radioIsLoading = loading;
      this.radioStateVersion++; // 强制UI刷新
      console.info(`[IndexPage] 加载状态更新: ${loading}, version=${this.radioStateVersion}`);
    });

    radioViewModel.setOnErrorChanged((error: string | null) => {
      this.radioError = error;
      this.radioStateVersion++; // 强制UI刷新
      console.info(`[IndexPage] 错误状态更新: ${error}, version=${this.radioStateVersion}`);
    });
  }

  /**
   * 设置播放器回调
   * 监听 PlayerService 的状态变化和进度更新
   */
  private setupPlayerCallbacks(): void {
    // 获取 PlayerService 单例
    const playerService = getPlayerService();

    // 监听播放状态变化
    playerService.on(PlayerEventType.STATE_CHANGE, (data) => {
      if (data !== null && data !== undefined) {
        const state = data as PlayerState;
        this.isPlaying = state.isPlaying;
        this.currentTime = state.currentTime;
        this.duration = state.duration;
        this.playProgress = state.duration > 0 ? state.currentTime / state.duration : 0;
        console.info(`[IndexPage] 播放状态更新: isPlaying=${state.isPlaying}, progress=${this.playProgress.toFixed(2)}`);
      }
    });

    // 监听播放进度更新
    playerService.on(PlayerEventType.PROGRESS, (data) => {
      if (data !== null && data !== undefined) {
        const progressData = data as ProgressData;
        this.currentTime = progressData.currentTime;
        if (progressData.duration > 0) {
          this.duration = progressData.duration;
          this.playProgress = progressData.currentTime / progressData.duration;
        }
      }
    });

    // 监听曲目变化
    playerService.on(PlayerEventType.TRACK_CHANGE, (data) => {
      if (data !== null && data !== undefined) {
        const item = data as PlaylistItem;
        this.currentTrackTitle = item.title;
        this.currentTrackArtist = item.subtitle || '未知艺术家';
        this.currentTrackAlbumArt = item.thumbnail || '';
        this.showMiniPlayer = true;
        console.info(`[IndexPage] 曲目变化: ${item.title}`);
      }
    });

    console.info('[IndexPage] 播放器回调设置完成');
  }

  /**
   * 切换播放/暂停
   */
  private async onPlayPause(): Promise<void> {
    try {
      await this.playerViewModel.togglePlayPause();
    } catch (error) {
      console.error(`[IndexPage] 切换播放失败: ${(error as Error).message}`);
    }
  }

  /**
   * 播放下一首
   */
  private async onNext(): Promise<void> {
    try {
      await this.playerViewModel.next();
    } catch (error) {
      console.error(`[IndexPage] 播放下一首失败: ${(error as Error).message}`);
    }
  }

  /**
   * 打开完整播放器页面
   */
  private openFullPlayer(): void {
    // TODO: 导航到完整播放器页面
    console.info('[IndexPage] 打开完整播放器');
  }

  /**
   * 构建主内容区域
   * 根据当前标签显示对应页面内容
   */
  @Builder
  buildContent() {
    // 内容区域使用 Stack 实现页面缓存
    Stack({ alignContent: Alignment.TopStart }) {
      // 本地音乐页面
      if (this.currentTabIndex === TabIndex.LOCAL_MUSIC) {
        this.buildLocalMusicContent();
      }

      // 网易云音乐页面
      if (this.currentTabIndex === TabIndex.NETEASE_MUSIC) {
        this.buildRadioContent();
      }

      // 播放列表页面
      if (this.currentTabIndex === TabIndex.PLAYLIST) {
        this.buildPlaylistContent();
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 构建本地音乐内容
   */
  @Builder
  buildLocalMusicContent() {
    Column() {
      // 页面标题
      Row() {
        Text('本地音乐')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary_text'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // 曲目数量统计
      Row() {
        Text(`${this.localMusicVM.trackCount} 首曲目`)
          .fontSize(14)
          .fontColor($r('app.color.secondary_text'))
      }
      .width('100%')
      .padding({ left: 16, bottom: 8 })

      // 内容列表
      if (this.localMusicVM.isLoading) {
        // 加载中状态
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color($r('app.color.primary'))
          Text('正在扫描音乐库...')
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.localMusicVM.errorMessage !== null) {
        // 错误状态
        Column() {
          SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
            .fontSize(48)
            .fontColor([$r('app.color.error')])
          Text(this.localMusicVM.errorMessage)
            .fontSize(14)
            .fontColor($r('app.color.error'))
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)
          Button('重试')
            .margin({ top: 16 })
            .onClick(() => {
              this.localMusicVM.refresh();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding(16)
      } else if (this.localMusicVM.trackCount === 0) {
        // 空状态
        Column() {
          SymbolGlyph($r('sys.symbol.play_circle'))
            .fontSize(64)
            .fontColor([$r('app.color.secondary_text')])
          Text('暂无本地音乐')
            .fontSize(16)
            .fontColor($r('app.color.secondary_text'))
            .margin({ top: 16 })
          Text('点击下方按钮扫描设备上的音乐文件')
            .fontSize(14)
            .fontColor($r('app.color.placeholder_text'))
            .margin({ top: 8 })
          Button('扫描音乐')
            .margin({ top: 24 })
            .onClick(() => {
              this.localMusicVM.scanMusicLibrary();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding(16)
      } else {
        // 曲目列表
        List() {
          ForEach(this.localMusicVM.tracks, (track: MusicTrack) => {
            ListItem() {
              this.buildTrackItem(track.title, track.artist, track.albumArt);
            }
          }, (track: MusicTrack) => track.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 8, right: 8 })
        .divider({
          strokeWidth: 0.5,
          color: $r('sys.color.ohos_id_color_list_separator'),
          startMargin: 72,
          endMargin: 16
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  /**
   * 构建网络电台内容
   */
  @Builder
  buildRadioContent() {
    Column() {
      // 页面标题
      Row() {
        Text('网易云音乐')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary_text'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // 搜索框
      Row() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(18)
          .fontColor([$r('app.color.placeholder_text')])

        TextInput({ placeholder: '搜索歌曲...', text: this.searchKeyword })
          .layoutWeight(1)
          .height(36)
          .backgroundColor(Color.Transparent)
          .margin({ left: 8 })
          .onChange((value: string) => {
            this.searchKeyword = value;
          })
          .onSubmit(() => {
            this.searchNeteaseMusic();
          })
      }
      .width('100%')
      .height(44)
      .padding({ left: 12, right: 12 })
      .margin({ left: 16, right: 16, bottom: 8 })
      .backgroundColor($r('app.color.input_bg'))
      .borderRadius(22)

      // 歌曲列表
      if (this.neteaseIsLoading && this.neteaseSongs.length === 0) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color($r('app.color.primary'))
          Text('正在加载歌曲...')
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.neteaseError !== null && this.neteaseSongs.length === 0) {
        Column() {
          SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
            .fontSize(48)
            .fontColor([$r('app.color.error')])
          Text(this.neteaseError ?? '加载失败')
            .fontSize(14)
            .fontColor($r('app.color.error'))
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)
          Button('重试')
            .margin({ top: 16 })
            .onClick(() => {
              this.loadNeteaseHotSongs();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding(16)
      } else if (this.neteaseSongs.length === 0) {
        Column() {
          SymbolGlyph($r('sys.symbol.play_circle'))
            .fontSize(64)
            .fontColor([$r('app.color.secondary_text')])
          Text('暂无歌曲数据')
            .fontSize(16)
            .fontColor($r('app.color.secondary_text'))
            .margin({ top: 16 })
          Button('加载热门歌曲')
            .margin({ top: 16 })
            .onClick(() => {
              this.loadNeteaseHotSongs();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.neteaseSongs, (song: NeteaseSong) => {
            ListItem() {
              this.buildNeteaseSongItem(song);
            }
            .onClick(() => {
              console.info(`[IndexPage] 点击歌曲: ${song.name}`);
              this.playNeteaseSong(song);
            })
          }, (song: NeteaseSong) => `netease_${song.id}`)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 8, right: 8 })
        .divider({
          strokeWidth: 0.5,
          color: $r('sys.color.ohos_id_color_list_separator'),
          startMargin: 72,
          endMargin: 16
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  /**
   * 构建网易云音乐歌曲项
   */
  @Builder
  buildNeteaseSongItem(song: NeteaseSong) {
    Row() {
      // 封面图片
      if (song.album?.picUrl) {
        Image(song.album.picUrl)
          .width(48)
          .height(48)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
          .alt($r('app.media.ic_public_music'))
      } else {
        Row() {
          SymbolGlyph($r('sys.symbol.play_circle'))
            .fontSize(24)
            .fontColor([$r('app.color.secondary_text')])
        }
        .width(48)
        .height(48)
        .borderRadius(6)
        .backgroundColor($r('sys.color.ohos_id_color_foreground_contrary'))
        .justifyContent(FlexAlign.Center)
      }

      // 歌曲信息
      Column() {
        Text(song.name)
          .fontSize(16)
          .fontColor($r('app.color.primary_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(song.artists?.map(a => a.name).join(', ') || '未知艺术家')
          .fontSize(14)
          .fontColor($r('app.color.secondary_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12, right: 8 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(64)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 加载网易云音乐热门歌曲
   */
  private async loadNeteaseHotSongs(): Promise<void> {
    console.info('[IndexPage] 开始加载网易云音乐热门歌曲');
    this.neteaseIsLoading = true;
    this.neteaseError = null;
    this.neteaseStateVersion++;

    try {
      const songs = await neteaseMusicService.getHotSongs(50);
      this.neteaseSongs = songs;
      console.info(`[IndexPage] 加载了 ${songs.length} 首热门歌曲`);
    } catch (error) {
      const err = error as Error;
      console.error(`[IndexPage] 加载热门歌曲失败: ${err.message}`);
      this.neteaseError = `加载失败: ${err.message}`;
    } finally {
      this.neteaseIsLoading = false;
      this.neteaseStateVersion++;
    }
  }

  /**
   * 搜索网易云音乐歌曲
   */
  private async searchNeteaseMusic(): Promise<void> {
    if (!this.searchKeyword || this.searchKeyword.trim().length === 0) {
      // 如果搜索词为空，加载热门歌曲
      await this.loadNeteaseHotSongs();
      return;
    }

    console.info(`[IndexPage] 搜索歌曲: ${this.searchKeyword}`);
    this.neteaseIsLoading = true;
    this.neteaseError = null;
    this.neteaseStateVersion++;

    try {
      const songs = await neteaseMusicService.searchSongs(this.searchKeyword, 30);
      this.neteaseSongs = songs;
      console.info(`[IndexPage] 搜索到 ${songs.length} 首歌曲`);
    } catch (error) {
      const err = error as Error;
      console.error(`[IndexPage] 搜索失败: ${err.message}`);
      this.neteaseError = `搜索失败: ${err.message}`;
    } finally {
      this.neteaseIsLoading = false;
      this.neteaseStateVersion++;
    }
  }

  /**
   * 播放网易云音乐歌曲
   */
  private playNeteaseSong(song: NeteaseSong): void {
    console.info(`[IndexPage] 开始播放歌曲: ${song.name}`);

    // 转换为MusicTrack并播放
    const track = neteaseMusicService.convertToMusicTrack(song);
    this.playerViewModel.play(track);

    // 更新迷你播放器状态
    this.currentTrackTitle = song.name;
    this.currentTrackArtist = song.artists?.map(a => a.name).join(', ') || '未知艺术家';
    this.currentTrackAlbumArt = song.album?.picUrl || '';
    this.isPlaying = true;
    this.showMiniPlayer = true;
  }

  /**
   * 构建播放列表内容
   */
  @Builder
  buildPlaylistContent() {
    Column() {
      // 页面标题和新建按钮
      Row() {
        Text('播放列表')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary_text'))

        Blank()

        Button() {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(20)
            .fontColor([$r('app.color.primary')])
        }
        .width(36)
        .height(36)
        .backgroundColor(Color.Transparent)
        .borderRadius(18)
        .onClick(() => {
          // TODO: 显示新建播放列表对话框
          console.info('[IndexPage] 新建播放列表');
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // 播放列表
      if (this.playlistVM.isLoading) {
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color($r('app.color.primary'))
          Text('正在加载播放列表...')
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
            .margin({ top: 12 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.playlistVM.errorMessage !== null) {
        Column() {
          SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
            .fontSize(48)
            .fontColor([$r('app.color.error')])
          Text(this.playlistVM.errorMessage)
            .fontSize(14)
            .fontColor($r('app.color.error'))
            .margin({ top: 12 })
            .textAlign(TextAlign.Center)
          Button('重试')
            .margin({ top: 16 })
            .onClick(() => {
              this.playlistVM.loadPlaylists();
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding(16)
      } else if (!this.playlistVM.hasPlaylists()) {
        Column() {
          SymbolGlyph($r('sys.symbol.list_bullet'))
            .fontSize(64)
            .fontColor([$r('app.color.secondary_text')])
          Text('暂无播放列表')
            .fontSize(16)
            .fontColor($r('app.color.secondary_text'))
            .margin({ top: 16 })
          Text('点击右上角 + 按钮创建新播放列表')
            .fontSize(14)
            .fontColor($r('app.color.placeholder_text'))
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .padding(16)
      } else {
        List() {
          ForEach(this.playlistVM.playlists, (playlist: Playlist) => {
            ListItem() {
              this.buildPlaylistItem(playlist.name, playlist.totalCount);
            }
          }, (playlist: Playlist) => playlist.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 8, right: 8 })
        .divider({
          strokeWidth: 0.5,
          color: $r('sys.color.ohos_id_color_list_separator'),
          startMargin: 72,
          endMargin: 16
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  /**
   * 构建曲目列表项
   */
  @Builder
  buildTrackItem(title: string, artist: string, albumArt?: string) {
    Row() {
      // 专辑封面
      if (albumArt !== undefined && albumArt.length > 0) {
        Image(albumArt)
          .width(48)
          .height(48)
          .borderRadius(6)
          .objectFit(ImageFit.Cover)
      } else {
        Row() {
          SymbolGlyph($r('sys.symbol.play_circle'))
            .fontSize(24)
            .fontColor([$r('app.color.secondary_text')])
        }
        .width(48)
        .height(48)
        .borderRadius(6)
        .backgroundColor($r('sys.color.ohos_id_color_foreground_contrary'))
        .justifyContent(FlexAlign.Center)
      }

      // 曲目信息
      Column() {
        Text(title)
          .fontSize(16)
          .fontColor($r('app.color.primary_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(artist)
          .fontSize(14)
          .fontColor($r('app.color.secondary_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12, right: 8 })
      .justifyContent(FlexAlign.Center)

      // 更多操作按钮
      Button() {
        SymbolGlyph($r('sys.symbol.ellipsis_circle'))
          .fontSize(20)
          .fontColor([$r('app.color.secondary_text')])
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .borderRadius(20)
      .onClick(() => {
        // TODO: 显示更多操作菜单
      })
    }
    .width('100%')
    .height(64)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 播放网络电台
   */
  private playRadioStation(station: RadioStation): void {
    console.info(`[IndexPage] 开始播放电台: ${station.name}, URL: ${station.urlResolved ?? station.url}`);

    // 使用 PlayerViewModel 的 play 方法播放电台
    this.playerViewModel.play(station);

    // 更新迷你播放器状态
    this.currentTrackTitle = station.name;
    this.currentTrackArtist = station.country ?? '网络电台';
    this.currentTrackAlbumArt = station.favicon ?? '';
    this.isPlaying = true;
    this.showMiniPlayer = true;
  }

  /**
   * 构建电台列表项
   */
  @Builder
  buildRadioItem(name: string, country: string, favicon: string) {
    Row() {
      // 电台图标
      if (favicon.length > 0) {
        Image(favicon)
          .width(48)
          .height(48)
          .borderRadius(24)
          .objectFit(ImageFit.Cover)
          .alt($r('app.media.ic_public_music'))
      } else {
        Row() {
          SymbolGlyph($r('sys.symbol.radio'))
            .fontSize(24)
            .fontColor([$r('app.color.secondary_text')])
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor($r('sys.color.ohos_id_color_foreground_contrary'))
        .justifyContent(FlexAlign.Center)
      }

      // 电台信息
      Column() {
        Text(name)
          .fontSize(16)
          .fontColor($r('app.color.primary_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (country.length > 0) {
          Text(country)
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 2 })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12, right: 8 })
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height(64)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 构建播放列表项
   */
  @Builder
  buildPlaylistItem(name: string, trackCount: number) {
    Row() {
      // 播放列表图标
      Row() {
        SymbolGlyph($r('sys.symbol.list_bullet'))
          .fontSize(24)
          .fontColor([$r('app.color.primary')])
      }
      .width(48)
      .height(48)
      .borderRadius(6)
      .backgroundColor($r('sys.color.ohos_id_color_component_activated'))
      .justifyContent(FlexAlign.Center)

      // 播放列表信息
      Column() {
        Text(name)
          .fontSize(16)
          .fontColor($r('app.color.primary_text'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${trackCount} 首曲目`)
          .fontSize(14)
          .fontColor($r('app.color.secondary_text'))
          .margin({ top: 2 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12, right: 8 })
      .justifyContent(FlexAlign.Center)

      // 更多操作按钮
      Button() {
        SymbolGlyph($r('sys.symbol.ellipsis_circle'))
          .fontSize(20)
          .fontColor([$r('app.color.secondary_text')])
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .borderRadius(20)
      .onClick(() => {
        // TODO: 显示更多操作菜单
      })
    }
    .width('100%')
    .height(64)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 构建底部标签栏
   */
  @Builder
  buildTabBar() {
    Row() {
      ForEach(TAB_ITEMS, (item: TabItem, index: number) => {
        this.buildTabItem(item, index);
      }, (item: TabItem) => item.name)
    }
    .width('100%')
    .height(TAB_BAR_HEIGHT)
    .backgroundColor($r('app.color.card_bg'))
    .justifyContent(FlexAlign.SpaceEvenly)
    .shadow({
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: -2
    })
  }

  /**
   * 构建单个标签项
   */
  @Builder
  buildTabItem(item: TabItem, index: number) {
    Column() {
      SymbolGlyph(this.currentTabIndex === index ? item.activeIcon : item.icon)
        .fontSize(24)
        .fontColor([
          this.currentTabIndex === index ?
            $r('app.color.primary') :
            $r('app.color.secondary_text')
        ])

      Text(item.name)
        .fontSize(12)
        .fontColor(
          this.currentTabIndex === index ?
            $r('app.color.primary') :
            $r('app.color.secondary_text')
        )
        .margin({ top: 4 })
    }
    .width(80)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .onClick(() => {
      this.currentTabIndex = index;
    })
  }

  /**
   * 构建迷你播放器区域
   */
  @Builder
  buildMiniPlayer() {
    if (this.showMiniPlayer) {
      MiniPlayer({
        title: this.currentTrackTitle,
        artist: this.currentTrackArtist,
        albumArt: this.currentTrackAlbumArt,
        isPlaying: this.isPlaying,
        progress: this.playProgress,
        currentTime: this.currentTime,
        duration: this.duration,
        onTap: () => {
          this.openFullPlayer();
        },
        onPlayPause: () => {
          this.onPlayPause();
        },
        onNext: () => {
          this.onNext();
        }
      })
    }
  }

  build() {
    Column() {
      // 主内容区域
      this.buildContent()

      // 迷你播放器（显示在内容区域上方）
      this.buildMiniPlayer()

      // 底部标签栏
      this.buildTabBar()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
    // 沉浸式状态栏适配
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP])
  }
}

/**
 * 使用示例：
 *
 * 本页面作为音乐播放器的主入口，包含三个标签页：
 * - 本地音乐：显示设备上的本地音乐文件
 * - 网络电台：显示网络电台列表
 * - 播放列表：显示用户创建的播放列表
 *
 * 页面底部显示迷你播放器，当有音乐播放时自动显示。
 *
 * 路由配置示例：
 * ```json
 * {
 *   "pages": [
 *     {
 *       "name": "musicplayer/pages/IndexPage",
 *       "window": {
 *         "designWidth": 720,
 *         "autoDesignWidth": true
 *       }
 *     }
 *   ]
 * }
 * ```
 */
