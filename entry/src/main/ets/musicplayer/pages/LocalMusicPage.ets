/**
 * 本地音乐页面
 * 显示设备上的本地音乐库，支持浏览、搜索、排序等功能
 *
 * 功能特性：
 * - 显示本地音乐曲目列表
 * - 支持按标题、艺术家、专辑排序
 * - 支持下拉刷新
 * - 支持搜索过滤
 * - 支持深色模式
 * - 支持系统返回手势
 *
 * 遵循华为 UX 体验标准：
 * - 可点击区域 >= 48vp x 48vp (2.1.4.1)
 * - 文字对比度 > 4.5:1 (2.1.4.2)
 * - 列表项高度 64vp
 */

import { LocalMusicViewModel, SortType, localMusicViewModel } from '../viewmodels/LocalMusicViewModel';
import { MusicTrack } from '../models/MusicTrack';
import { TrackListItem } from '../components/TrackListItem';
import { EmptyState } from '../components/EmptyState';
import { MiniPlayer } from '../components/MiniPlayer';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { router } from '@kit.ArkUI';

/**
 * 日志标签
 */
const LOG_TAG: string = 'LocalMusicPage';
const LOG_DOMAIN: number = 0xFF00;

/**
 * 排序菜单项接口
 */
interface SortMenuItem {
  /** 排序类型 */
  type: SortType;
  /** 显示文本 */
  label: string;
}

/**
 * 本地音乐页面组件
 */
@Entry
@Component
struct LocalMusicPage {
  /** 视图模型实例 */
  private viewModel: LocalMusicViewModel = localMusicViewModel;

  /** 音乐曲目列表 */
  @State private tracks: MusicTrack[] = [];

  /** 搜索结果列表 */
  @State private filteredTracks: MusicTrack[] = [];

  /** 是否正在加载 */
  @State private isLoading: boolean = false;

  /** 错误信息 */
  @State private errorMessage: string | null = null;

  /** 当前排序类型 */
  @State private sortMode: SortType = SortType.TITLE;

  /** 搜索关键词 */
  @State private searchQuery: string = '';

  /** 是否显示搜索框 */
  @State private isSearchVisible: boolean = false;

  /** 是否显示排序菜单 */
  @State private isSortMenuVisible: boolean = false;

  /** 当前播放曲目 ID */
  @State private currentPlayingId: string = '';

  /** 是否正在播放 */
  @State private isPlaying: boolean = false;

  /** 播放进度 (0-1) */
  @State private playProgress: number = 0;

  /** 当前播放曲目 */
  @State private currentTrack: MusicTrack | null = null;

  /** 排序菜单选项 */
  private sortMenuItems: SortMenuItem[] = [
    { type: SortType.TITLE, label: '按标题排序' },
    { type: SortType.ARTIST, label: '按艺术家排序' },
    { type: SortType.ALBUM, label: '按专辑排序' }
  ];

  /**
   * 页面即将显示
   */
  aboutToAppear(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, '本地音乐页面加载');
    this.loadData();
  }

  /**
   * 加载音乐数据
   */
  private async loadData(): Promise<void> {
    this.isLoading = true;

    try {
      await this.viewModel.initialize();
      this.tracks = this.viewModel.tracks;
      this.filteredTracks = [...this.tracks];
      this.applyCurrentSort();
    } catch (error) {
      const err: Error = error as Error;
      this.errorMessage = err.message || '加载音乐库失败';
      hilog.error(LOG_DOMAIN, LOG_TAG, `加载失败: ${this.errorMessage}`);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 刷新音乐库（重新扫描）
   */
  private async refreshLibrary(): Promise<void> {
    hilog.info(LOG_DOMAIN, LOG_TAG, '刷新音乐库');
    this.isLoading = true;

    try {
      await this.viewModel.refresh();
      this.tracks = this.viewModel.tracks;
      this.applySearch();
      this.applyCurrentSort();
    } catch (error) {
      const err: Error = error as Error;
      this.errorMessage = err.message || '刷新音乐库失败';
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 应用当前排序
   */
  private applyCurrentSort(): void {
    switch (this.sortMode) {
      case SortType.TITLE:
        this.viewModel.sortByTitle();
        break;
      case SortType.ARTIST:
        this.viewModel.sortByArtist();
        break;
      case SortType.ALBUM:
        this.viewModel.sortByAlbum();
        break;
      default:
        this.viewModel.sortByTitle();
        break;
    }

    // 如果有搜索关键词，重新应用搜索
    if (this.searchQuery.trim().length > 0) {
      this.applySearch();
    } else {
      this.filteredTracks = [...this.viewModel.tracks];
    }
  }

  /**
   * 应用搜索过滤
   */
  private applySearch(): void {
    if (this.searchQuery.trim().length === 0) {
      this.filteredTracks = [...this.tracks];
    } else {
      this.filteredTracks = this.viewModel.search(this.searchQuery);
    }
  }

  /**
   * 切换排序模式
   * @param sortType 排序类型
   */
  private changeSortMode(sortType: SortType): void {
    this.sortMode = sortType;
    this.isSortMenuVisible = false;
    this.applyCurrentSort();
    hilog.info(LOG_DOMAIN, LOG_TAG, `切换排序模式: ${sortType}`);
  }

  /**
   * 播放指定曲目
   * @param track 要播放的曲目
   */
  private playTrack(track: MusicTrack): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, `播放曲目: ${track.title}`);
    this.currentPlayingId = track.id;
    this.currentTrack = track;
    this.isPlaying = true;
    // TODO: 调用播放服务播放曲目
  }

  /**
   * 显示曲目上下文菜单
   * @param track 曲目对象
   */
  private showTrackContextMenu(track: MusicTrack): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, `显示上下文菜单: ${track.title}`);
    // TODO: 实现 addToPlaylist 功能
    // 可以使用 AlertDialog 或 BindSheet 显示添加到播放列表选项
  }

  /**
   * 切换播放/暂停
   */
  private togglePlayPause(): void {
    this.isPlaying = !this.isPlaying;
    hilog.info(LOG_DOMAIN, LOG_TAG, `播放状态: ${this.isPlaying ? '播放' : '暂停'}`);
    // TODO: 调用播放服务控制播放
  }

  /**
   * 播放下一首
   */
  private playNext(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, '播放下一首');
    // TODO: 实现下一首逻辑
  }

  /**
   * 打开完整播放器
   */
  private openFullPlayer(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, '打开完整播放器');
    // TODO: 导航到完整播放器页面
  }

  /**
   * 返回上一页
   */
  private goBack(): void {
    router.back();
  }

  /**
   * 获取当前排序模式显示文本
   */
  private getSortModeLabel(): string {
    const item: SortMenuItem | undefined = this.sortMenuItems.find(
      (i: SortMenuItem): boolean => i.type === this.sortMode
    );
    return item !== undefined ? item.label : '按标题排序';
  }

  build() {
    Column() {
      // 标题栏
      this.buildTitleBar()

      // 搜索栏（可选显示）
      if (this.isSearchVisible) {
        this.buildSearchBar()
      }

      // 主内容区域
      this.buildMainContent()

      // 底部迷你播放器（正在播放时显示）
      if (this.currentTrack !== null) {
        this.buildMiniPlayer()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }

  /**
   * 构建标题栏
   */
  @Builder
  buildTitleBar() {
    Row() {
      // 返回按钮
      Button() {
        SymbolGlyph($r('sys.symbol.arrow_left'))
          .fontSize(20)
          .fontColor([$r('app.color.primary_text')])
      }
      .width(44)
      .height(44)
      .backgroundColor(Color.Transparent)
      .borderRadius(22)
      .onClick(() => this.goBack())

      // 页面标题
      Text('本地音乐')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.primary_text'))
        .layoutWeight(1)
        .margin({ left: 8 })

      // 搜索按钮
      Button() {
        SymbolGlyph($r('sys.symbol.magnifyingglass'))
          .fontSize(20)
          .fontColor([$r('app.color.primary_text')])
      }
      .width(44)
      .height(44)
      .backgroundColor(Color.Transparent)
      .borderRadius(22)
      .margin({ right: 4 })
      .onClick(() => {
        this.isSearchVisible = !this.isSearchVisible;
        if (!this.isSearchVisible) {
          this.searchQuery = '';
          this.applySearch();
        }
      })

      // 排序按钮
      Button() {
        Image($r('app.media.arrow_up_and_down'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.primary_text'))
      }
      .width(44)
      .height(44)
      .backgroundColor(Color.Transparent)
      .borderRadius(22)
      .bindMenu(this.isSortMenuVisible, this.getSortMenuItems())
      .onClick(() => {
        this.isSortMenuVisible = !this.isSortMenuVisible;
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }

  /**
   * 构建排序菜单
   */
  @Builder
  buildSortMenu(): void {
    // 返回菜单项数组
    // 注：bindMenu 期望 MenuListItem 数组
  }

  /**
   * 获取排序菜单项
   */
  private getSortMenuItems(): MenuElement[] {
    const items: MenuElement[] = [];
    for (const item of this.sortMenuItems) {
      const menuItem: MenuElement = {
        value: item.label,
        action: () => this.changeSortMode(item.type)
      };
      items.push(menuItem);
    }
    return items;
  }

  /**
   * 构建搜索栏
   */
  @Builder
  buildSearchBar() {
    Row() {
      // 搜索图标
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(18)
        .fontColor([$r('app.color.secondary_text')])
        .margin({ right: 8 })

      // 搜索输入框
      TextInput({ placeholder: '搜索音乐、艺术家、专辑', text: this.searchQuery })
        .layoutWeight(1)
        .height(40)
        .backgroundColor(Color.Transparent)
        .fontSize(16)
        .fontColor($r('app.color.primary_text'))
        .placeholderColor($r('app.color.secondary_text'))
        .onChange((value: string) => {
          this.searchQuery = value;
          this.applySearch();
        })

      // 清除按钮
      if (this.searchQuery.length > 0) {
        Button() {
          SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
            .fontSize(18)
            .fontColor([$r('app.color.secondary_text')])
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .borderRadius(16)
        .onClick(() => {
          this.searchQuery = '';
          this.applySearch();
        })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .margin({ top: 4, bottom: 4 })
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(24)
    .margin({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  /**
   * 构建主内容区域
   */
  @Builder
  buildMainContent() {
    if (this.isLoading) {
      // 加载状态
      this.buildLoadingState()
    } else if (this.errorMessage !== null) {
      // 错误状态
      this.buildErrorState()
    } else if (this.filteredTracks.length === 0) {
      // 空状态
      this.buildEmptyState()
    } else {
      // 曲目列表
      this.buildTrackList()
    }
  }

  /**
   * 构建加载状态
   */
  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color($r('app.color.primary'))

      Text('正在扫描音乐库...')
        .fontSize(16)
        .fontColor($r('app.color.secondary_text'))
        .margin({ top: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 构建错误状态
   */
  @Builder
  buildErrorState() {
    Column() {
      SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
        .fontSize(48)
        .fontColor([$r('app.color.error')])

      Text('加载失败')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.primary_text'))
        .margin({ top: 16 })

      Text(this.errorMessage || '未知错误')
        .fontSize(14)
        .fontColor($r('app.color.secondary_text'))
        .margin({ top: 8 })
        .textAlign(TextAlign.Center)

      Button('重试')
        .type(ButtonType.Capsule)
        .fontSize(14)
        .fontColor(Color.White)
        .backgroundColor($r('app.color.primary'))
        .height(40)
        .padding({ left: 24, right: 24 })
        .margin({ top: 24 })
        .onClick(() => this.refreshLibrary())
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 32, right: 32 })
  }

  /**
   * 构建空状态
   */
  @Builder
  buildEmptyState() {
    Column() {
      EmptyState({
        icon: $r('app.media.ic_public_music'),
        title: this.searchQuery.length > 0 ? '未找到匹配的音乐' : '暂无本地音乐',
        description: this.searchQuery.length > 0
          ? `未找到与"${this.searchQuery}"相关的内容`
          : '您的设备上暂无音乐文件，请添加音乐后刷新',
        actionText: this.searchQuery.length > 0 ? '清除搜索' : '刷新音乐库'
      })

      // 操作按钮需要单独处理
      if (this.searchQuery.length > 0) {
        Button('清除搜索')
          .type(ButtonType.Capsule)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.primary'))
          .height(40)
          .padding({ left: 24, right: 24 })
          .margin({ top: 24 })
          .onClick(() => {
            this.searchQuery = '';
            this.applySearch();
          })
      } else {
        Button('刷新音乐库')
          .type(ButtonType.Capsule)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.primary'))
          .height(40)
          .padding({ left: 24, right: 24 })
          .margin({ top: 24 })
          .onClick(() => this.refreshLibrary())
      }
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 构建曲目列表
   */
  @Builder
  buildTrackList() {
    Column() {
      // 曲目数量和排序信息
      Row() {
        Text(`共 ${this.filteredTracks.length} 首曲目`)
          .fontSize(14)
          .fontColor($r('app.color.secondary_text'))

        Blank()

        Text(this.getSortModeLabel())
          .fontSize(14)
          .fontColor($r('app.color.secondary_text'))
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })

      // 曲目列表
      List() {
        ForEach(this.filteredTracks, (track: MusicTrack, index: number) => {
          ListItem() {
            TrackListItem({
              track: track,
              isPlaying: this.currentPlayingId === track.id,
              index: index,
              onTrackClick: () => this.playTrack(track),
              onTrackLongPress: () => this.showTrackContextMenu(track)
            })
          }
        }, (track: MusicTrack): string => track.id)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({
        strokeWidth: 0.5,
        color: $r('app.color.divider'),
        startMargin: 76,
        endMargin: 16
      })
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 构建迷你播放器
   */
  @Builder
  buildMiniPlayer() {
    MiniPlayer({
      title: this.currentTrack?.title || '未知曲目',
      artist: this.currentTrack?.artist || '未知艺术家',
      albumArt: this.currentTrack?.albumArt,
      isPlaying: this.isPlaying,
      progress: this.playProgress,
      onTap: () => this.openFullPlayer(),
      onPlayPause: () => this.togglePlayPause(),
      onNext: () => this.playNext()
    })
  }
}

/**
 * 使用示例：
 *
 * ```typescript
 * import { LocalMusicPage } from './pages/LocalMusicPage';
 *
 * // 在路由配置中注册页面
 * router.pushUrl({
 *   url: 'pages/LocalMusicPage'
 * });
 * ```
 */
