/**
 * SearchPage - 音乐搜索页面
 * 提供本地音乐库和网络音乐的搜索功能
 *
 * 功能特性：
 * - 支持本地搜索和网络搜索切换
 * - 实时搜索（输入时自动搜索）
 * - 按标题、艺术家、专辑搜索
 * - 点击搜索结果播放音乐
 * - 清空搜索按钮
 * - 深色模式支持
 *
 * UX 体验标准：
 * - 页面加载时自动聚焦输入框
 * - 输入即搜索，无需等待
 * - 空状态友好提示
 * - 可点击区域 >= 48vp x 48vp
 */

import { MusicTrack } from '../models/MusicTrack';
import { LocalMusicViewModel, localMusicViewModel } from '../viewmodels/LocalMusicViewModel';
import { TrackListItem } from '../components/TrackListItem';
import { EmptyState } from '../components/EmptyState';
import { getPlayerService, PlayerService } from '../services/PlayerService';
import { PlaylistItem, PlaylistItemType } from '../models/index';
import { neteaseMusicService, NeteaseSong } from '../services/index';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 日志标签
 */
const LOG_TAG: string = 'SearchPage';
const LOG_DOMAIN: number = 0xFF00;

/**
 * 搜索防抖延迟时间（毫秒）
 */
const SEARCH_DEBOUNCE_DELAY: number = 300;

/**
 * 最大搜索历史记录数
 */
const MAX_RECENT_SEARCHES: number = 10;

/**
 * 搜索类型枚举
 */
enum SearchType {
  /** 本地音乐搜索 */
  LOCAL = 'local',
  /** 网络音乐搜索（网易云音乐） */
  ONLINE = 'online'
}

/**
 * 搜索页面组件
 * 提供音乐搜索功能
 */
@Entry
@Component
struct SearchPage {
  /** 搜索输入框内容 */
  @State searchText: string = '';

  /** 搜索结果列表 */
  @State searchResults: MusicTrack[] = [];

  /** 是否正在搜索 */
  @State isSearching: boolean = false;

  /** 是否已执行过搜索 */
  @State hasSearched: boolean = false;

  /** 最近搜索记录 */
  @State recentSearches: string[] = [];

  /** 当前搜索类型 */
  @State searchType: SearchType = SearchType.ONLINE;

  /** 本地音乐视图模型 */
  private viewModel: LocalMusicViewModel = localMusicViewModel;

  /** 播放服务 */
  private playerService: PlayerService = getPlayerService();

  /** 搜索防抖定时器 */
  private searchTimer: number = -1;

  /** 搜索输入框控制器 */
  private searchInputController: TextInputController = new TextInputController();

  /**
   * 页面即将显示
   */
  aboutToAppear(): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, '搜索页面加载');

    // 加载最近搜索记录
    this.loadRecentSearches();

    // 初始化视图模型
    this.initializeViewModel();

    // 延迟聚焦输入框，确保页面渲染完成
    setTimeout(() => {
      // 设置光标位置
      this.searchInputController.caretPosition(this.searchText.length);
    }, 100);
  }

  /**
   * 页面即将消失
   */
  aboutToDisappear(): void {
    // 清除搜索定时器
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
      this.searchTimer = -1;
    }
    hilog.info(LOG_DOMAIN, LOG_TAG, '搜索页面卸载');
  }

  /**
   * 初始化视图模型
   */
  private async initializeViewModel(): Promise<void> {
    try {
      await this.viewModel.initialize();
      hilog.info(LOG_DOMAIN, LOG_TAG, `视图模型初始化完成，共 ${this.viewModel.trackCount} 首曲目`);
    } catch (error) {
      const err: Error = error as Error;
      hilog.error(LOG_DOMAIN, LOG_TAG, `视图模型初始化失败: ${err.message}`);
    }
  }

  /**
   * 加载最近搜索记录
   * 注：实际应用中应从持久化存储加载
   */
  private loadRecentSearches(): void {
    // 从本地存储加载最近搜索记录
    // 这里暂时使用空数组，实际实现应使用 Preferences
    this.recentSearches = [];
  }

  /**
   * 保存搜索记录
   * @param query 搜索关键词
   */
  private saveRecentSearch(query: string): void {
    if (query === null || query === undefined || query.trim() === '') {
      return;
    }

    const trimmedQuery: string = query.trim();

    // 移除重复项
    const index: number = this.recentSearches.indexOf(trimmedQuery);
    if (index !== -1) {
      this.recentSearches.splice(index, 1);
    }

    // 添加到开头
    this.recentSearches.unshift(trimmedQuery);

    // 限制数量
    if (this.recentSearches.length > MAX_RECENT_SEARCHES) {
      this.recentSearches = this.recentSearches.slice(0, MAX_RECENT_SEARCHES);
    }

    // 注：实际应用中应保存到持久化存储（Preferences）
    hilog.debug(LOG_DOMAIN, LOG_TAG, `保存搜索记录: ${trimmedQuery}`);
  }

  /**
   * 执行搜索
   * @param query 搜索关键词
   */
  private performSearch(query: string): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, `执行搜索: "${query}", 类型: ${this.searchType}`);

    this.isSearching = true;
    this.hasSearched = true;

    if (this.searchType === SearchType.ONLINE) {
      // 网络搜索（异步）
      this.performOnlineSearch(query);
    } else {
      // 本地搜索（同步）
      this.performLocalSearch(query);
    }
  }

  /**
   * 执行本地搜索
   * @param query 搜索关键词
   */
  private performLocalSearch(query: string): void {
    try {
      const results: MusicTrack[] = this.viewModel.search(query);
      this.searchResults = results;

      if (query !== null && query !== undefined && query.trim() !== '') {
        this.saveRecentSearch(query);
      }

      hilog.info(LOG_DOMAIN, LOG_TAG, `本地搜索完成，找到 ${results.length} 条结果`);
    } catch (error) {
      const err: Error = error as Error;
      hilog.error(LOG_DOMAIN, LOG_TAG, `本地搜索失败: ${err.message}`);
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  /**
   * 执行网络搜索（网易云音乐）
   * @param query 搜索关键词
   */
  private async performOnlineSearch(query: string): Promise<void> {
    try {
      const neteaseSongs: NeteaseSong[] = await neteaseMusicService.searchSongs(query, 50);

      // 转换为 MusicTrack 格式
      const tracks: MusicTrack[] = [];
      for (let i = 0; i < neteaseSongs.length; i++) {
        tracks.push(neteaseMusicService.convertToMusicTrack(neteaseSongs[i]));
      }

      this.searchResults = tracks;

      if (query !== null && query !== undefined && query.trim() !== '') {
        this.saveRecentSearch(query);
      }

      hilog.info(LOG_DOMAIN, LOG_TAG, `网络搜索完成，找到 ${tracks.length} 条结果`);
    } catch (error) {
      const err: Error = error as Error;
      hilog.error(LOG_DOMAIN, LOG_TAG, `网络搜索失败: ${err.message}`);
      this.searchResults = [];
    } finally {
      this.isSearching = false;
    }
  }

  /**
   * 处理搜索输入变化
   * 实现实时搜索（带防抖）
   */
  private onSearchInputChange(value: string): void {
    this.searchText = value;

    // 清除之前的定时器
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
    }

    // 设置新的防抖定时器
    const timerId: number = setTimeout(() => {
      this.performSearch(value);
      this.searchTimer = -1;
    }, SEARCH_DEBOUNCE_DELAY);
    this.searchTimer = Number(timerId);
  }

  /**
   * 清空搜索
   */
  private clearSearch(): void {
    this.searchText = '';
    this.searchResults = [];
    this.hasSearched = false;

    // 清除防抖定时器
    if (this.searchTimer !== -1) {
      clearTimeout(this.searchTimer);
      this.searchTimer = -1;
    }

    hilog.debug(LOG_DOMAIN, LOG_TAG, '清空搜索');
  }

  /**
   * 点击最近搜索项
   * @param query 搜索关键词
   */
  private onRecentSearchClick(query: string): void {
    this.searchText = query;
    this.performSearch(query);
  }

  /**
   * 清空最近搜索记录
   */
  private clearRecentSearches(): void {
    this.recentSearches = [];
    hilog.debug(LOG_DOMAIN, LOG_TAG, '清空最近搜索记录');
  }

  /**
   * 点击搜索结果项
   * 播放选中的曲目
   * @param track 音乐曲目
   */
  private onTrackClick(track: MusicTrack): void {
    hilog.info(LOG_DOMAIN, LOG_TAG, `点击曲目: ${track.title}`);

    // 创建播放列表项
    // 对于网络音乐：filePath 是播放 URL
    // 对于本地音乐：filePath 是本地文件路径
    const isOnline: boolean = track.id.startsWith('netease_');
    const playlistItem: PlaylistItem = {
      id: `item_${track.id}`,
      type: PlaylistItemType.LOCAL_MUSIC, // 网络音乐也使用 LOCAL_MUSIC 类型
      trackId: track.filePath, // 使用 filePath 作为 trackId，这是实际的播放 URL
      title: track.title,
      subtitle: track.artist,
      thumbnail: track.albumArt,
      order: 0,
      addedAt: Date.now()
    };

    // 播放曲目
    this.playerService.play(playlistItem).catch((error: Error) => {
      hilog.error(LOG_DOMAIN, LOG_TAG, `播放失败: ${error.message}`);
    });
  }

  /**
   * 构建页面UI
   */
  build() {
    Column() {
      // 搜索栏
      this.buildSearchBar()

      // 搜索类型切换
      this.buildSearchTypeSelector()

      // 内容区域
      if (this.hasSearched) {
        // 已搜索，显示结果或空状态
        if (this.isSearching) {
          // 搜索中
          this.buildLoadingState()
        } else if (this.searchResults.length > 0) {
          // 显示搜索结果
          this.buildSearchResults()
        } else {
          // 无结果
          this.buildEmptyResultState()
        }
      } else {
        // 未搜索，显示最近搜索或初始状态
        if (this.recentSearches.length > 0) {
          this.buildRecentSearches()
        } else {
          this.buildInitialState()
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('sys.color.ohos_id_color_background'))
  }

  /**
   * 构建搜索栏
   */
  @Builder
  buildSearchBar() {
    Row() {
      // 返回按钮
      Image($r('app.media.ic_public_arrow_left'))
        .width(24)
        .height(24)
        .fillColor($r('app.color.primary_text'))
        .onClick(() => {
          // 返回上一页
          this.goBack();
        })
        .margin({ right: 12 })

      // 搜索输入框
      Row() {
        // 搜索图标
        Image($r('app.media.ic_public_search'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.secondary_text'))
          .margin({ left: 12, right: 8 })

        // 输入框
        TextInput({ placeholder: '搜索歌曲、歌手、专辑', text: this.searchText, controller: this.searchInputController })
          .layoutWeight(1)
          .height(40)
          .backgroundColor(Color.Transparent)
          .placeholderColor($r('app.color.secondary_text'))
          .placeholderFont({ size: 16 })
          .fontColor($r('app.color.primary_text'))
          .fontSize(16)
          .caretColor($r('app.color.primary'))
          .onChange((value: string) => {
            this.onSearchInputChange(value);
          })
          .onSubmit(() => {
            // 提交搜索（回车键）
            if (this.searchTimer !== -1) {
              clearTimeout(this.searchTimer);
              this.searchTimer = -1;
            }
            this.performSearch(this.searchText);
          })

        // 清空按钮（有内容时显示）
        if (this.searchText.length > 0) {
          Image($r('app.media.ic_public_cancel'))
            .width(20)
            .height(20)
            .fillColor($r('app.color.secondary_text'))
            .margin({ right: 12 })
            .onClick(() => {
              this.clearSearch();
            })
        }
      }
      .layoutWeight(1)
      .height(40)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(20)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 12, bottom: 12 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 构建搜索类型选择器
   */
  @Builder
  buildSearchTypeSelector() {
    Row() {
      // 网络音乐按钮
      Button(this.searchType === SearchType.ONLINE ? '🎵 网络音乐' : '网络音乐')
        .fontSize(14)
        .fontColor(this.searchType === SearchType.ONLINE ? Color.White : $r('app.color.primary_text'))
        .backgroundColor(this.searchType === SearchType.ONLINE ? $r('app.color.primary') : $r('app.color.card_bg'))
        .borderRadius(16)
        .height(32)
        .padding({ left: 16, right: 16 })
        .onClick(() => {
          if (this.searchType !== SearchType.ONLINE) {
            this.searchType = SearchType.ONLINE;
            // 切换类型后重新搜索
            if (this.searchText.trim().length > 0) {
              this.performSearch(this.searchText);
            }
          }
        })

      // 本地音乐按钮
      Button(this.searchType === SearchType.LOCAL ? '📱 本地音乐' : '本地音乐')
        .fontSize(14)
        .fontColor(this.searchType === SearchType.LOCAL ? Color.White : $r('app.color.primary_text'))
        .backgroundColor(this.searchType === SearchType.LOCAL ? $r('app.color.primary') : $r('app.color.card_bg'))
        .borderRadius(16)
        .height(32)
        .padding({ left: 16, right: 16 })
        .margin({ left: 12 })
        .onClick(() => {
          if (this.searchType !== SearchType.LOCAL) {
            this.searchType = SearchType.LOCAL;
            // 切换类型后重新搜索
            if (this.searchText.trim().length > 0) {
              this.performSearch(this.searchText);
            }
          }
        })
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 4, bottom: 8 })
    .justifyContent(FlexAlign.Start)
  }

  /**
   * 构建搜索结果列表
   */
  @Builder
  buildSearchResults() {
    Column() {
      // 结果计数
      Row() {
        Text(`找到 ${this.searchResults.length} 首歌曲`)
          .fontSize(14)
          .fontColor($r('app.color.secondary_text'))
          .margin({ left: 16, top: 8, bottom: 8 })
      }
      .width('100%')

      // 结果列表
      List() {
        ForEach(this.searchResults, (track: MusicTrack, index: number) => {
          ListItem() {
            TrackListItem({
              track: track,
              index: index,
              onTrackClick: () => {
                this.onTrackClick(track);
              }
            })
          }
        }, (track: MusicTrack) => track.id)
      }
      .width('100%')
      .layoutWeight(1)
      .divider({
        strokeWidth: 0.5,
        color: $r('app.color.divider'),
        startMargin: 76,
        endMargin: 16
      })
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 构建最近搜索
   */
  @Builder
  buildRecentSearches() {
    Column() {
      // 标题栏
      Row() {
        Text('最近搜索')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor($r('app.color.primary_text'))

        Blank()

        Text('清空')
          .fontSize(14)
          .fontColor($r('app.color.primary'))
          .onClick(() => {
            this.clearRecentSearches();
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 16, bottom: 12 })

      // 搜索标签列表
      Flex({ wrap: FlexWrap.Wrap }) {
        ForEach(this.recentSearches, (query: string) => {
          Text(query)
            .fontSize(14)
            .fontColor($r('app.color.primary_text'))
            .backgroundColor($r('app.color.card_bg'))
            .borderRadius(16)
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .margin({ left: 8, bottom: 8 })
            .onClick(() => {
              this.onRecentSearchClick(query);
            })
        }, (query: string) => query)
      }
      .width('100%')
      .padding({ left: 8, right: 16 })
    }
    .width('100%')
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
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
        .margin({ bottom: 16 })

      Text('正在搜索...')
        .fontSize(16)
        .fontColor($r('app.color.secondary_text'))
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 构建空结果状态
   */
  @Builder
  buildEmptyResultState() {
    Column() {
      EmptyState({
        icon: $r('app.media.ic_public_search'),
        title: '未找到相关内容',
        description: `没有找到与"${this.searchText}"相关的歌曲`
      })
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 构建初始状态
   */
  @Builder
  buildInitialState() {
    Column() {
      if (this.searchType === SearchType.ONLINE) {
        EmptyState({
          icon: $r('app.media.ic_public_music'),
          title: '搜索网络音乐',
          description: '输入歌曲名、歌手或专辑，从网易云音乐搜索海量音乐'
        })
      } else {
        EmptyState({
          icon: $r('app.media.ic_public_music'),
          title: '搜索本地音乐',
          description: '输入歌曲名、歌手或专辑进行搜索'
        })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * 返回上一页
   */
  private goBack(): void {
    // 获取 UI 上下文并执行路由返回
    // 实际应用中应使用 router.back()
    hilog.info(LOG_DOMAIN, LOG_TAG, '返回上一页');
  }
}

/**
 * 使用示例：
 *
 * ```typescript
 * import { SearchPage } from './pages/SearchPage';
 *
 * // 在路由配置中注册
 * router.pushUrl({
 *   url: 'pages/SearchPage'
 * });
 * ```
 */
