/**
 * PlayerPage - 全屏播放器页面
 * 提供完整的音乐播放控制界面
 * 遵循华为 UX 体验标准和设计最佳实践
 */

import common from '@ohos.app.ability.common';
import { PlayerViewModel, createPlayerViewModel } from '../viewmodels/PlayerViewModel';
import { AlbumArt } from '../components/AlbumArt';
import { PlayerControls } from '../components/PlayerControls';
import { ProgressBar } from '../components/ProgressBar';
import { VolumeSlider } from '../components/VolumeSlider';
import { PlayModeButton } from '../components/PlayModeButton';
import { BufferingIndicator } from '../components/BufferingIndicator';
import { PlayMode } from '../models/Enums';
import { MusicTrack, RadioStation } from '../models/index';

/**
 * 页面关闭回调类型
 */
export interface PlayerPageCallback {
  /** 页面关闭回调 */
  onClose?: () => void;
  /** 分享回调 */
  onShare?: () => void;
  /** 添加到播放列表回调 */
  onAddToPlaylist?: () => void;
}

/**
 * 全屏播放器页面组件
 * 支持手势滑动关闭、沉浸式状态栏、暗色模式
 */
@Entry
@Component
export struct PlayerPage {
  /** 应用上下文 */
  private context: common.UIAbilityContext | null = null;

  /** 播放器视图模型 */
  private viewModel: PlayerViewModel = createPlayerViewModel();

  /** 页面回调 */
  @Prop callback: PlayerPageCallback = {};

  /** 是否显示更多选项菜单 */
  @State private showMoreMenu: boolean = false;

  /** 手势滑动偏移量 */
  @State private panOffset: number = 0;

  /** 是否正在执行关闭动画 */
  @State private isClosing: boolean = false;

  /** 是否已初始化 */
  @State private isInitialized: boolean = false;

  /** 当前音量 */
  @State private currentVolume: number = 0.5;

  /** 是否静音 */
  @State private isMuted: boolean = false;

  /** 上一次音量（用于静音切换恢复） */
  private lastVolume: number = 0.5;

  /**
   * 组件即将显示
   */
  aboutToAppear(): void {
    this.initPage();
  }

  /**
   * 组件即将消失
   */
  aboutToDisappear(): void {
    // 清理资源
    this.viewModel.release();
  }

  /**
   * 初始化页面
   */
  private async initPage(): Promise<void> {
    try {
      // 获取上下文
      this.context = getContext(this) as common.UIAbilityContext;

      // 初始化视图模型
      await this.viewModel.initialize(this.context);

      // 同步音量状态
      this.currentVolume = this.viewModel.volume;
      this.isInitialized = true;

      console.info('[PlayerPage] 页面初始化完成');
    } catch (error) {
      const err = error as Error;
      console.error(`[PlayerPage] 初始化失败: ${err.message}`);
    }
  }

  /**
   * 获取曲目标题
   * @returns 标题字符串
   */
  private getTrackTitle(): string {
    const track = this.viewModel.currentTrack;
    if (track === null) {
      return '未知曲目';
    }
    const musicTrack = track as MusicTrack;
    const radioStation = track as RadioStation;
    if (musicTrack.title !== undefined) {
      return musicTrack.title || '未知曲目';
    }
    if (radioStation.name !== undefined) {
      return radioStation.name || '未知电台';
    }
    return '未知曲目';
  }

  /**
   * 获取艺术家/副标题
   * @returns 艺术家字符串
   */
  private getTrackArtist(): string {
    const track = this.viewModel.currentTrack;
    if (track === null) {
      return '未知艺术家';
    }
    const musicTrack = track as MusicTrack;
    const radioStation = track as RadioStation;
    if (musicTrack.artist !== undefined) {
      return musicTrack.artist || '未知艺术家';
    }
    if (radioStation.country !== undefined) {
      return radioStation.country || '未知地区';
    }
    return '未知艺术家';
  }

  /**
   * 获取专辑封面URL
   * @returns 图片URL或资源
   */
  private getAlbumArtUrl(): string | Resource | null {
    const track = this.viewModel.currentTrack;
    if (track === null) {
      return null;
    }
    const musicTrack = track as MusicTrack;
    const radioStation = track as RadioStation;
    if (musicTrack.albumArt !== undefined) {
      return musicTrack.albumArt || null;
    }
    if (radioStation.favicon !== undefined) {
      return radioStation.favicon || null;
    }
    return null;
  }

  /**
   * 处理返回按钮点击
   */
  private handleBack(): void {
    this.closePage();
  }

  /**
   * 处理更多选项点击
   */
  private handleMoreOptions(): void {
    this.showMoreMenu = !this.showMoreMenu;
  }

  /**
   * 关闭页面
   */
  private closePage(): void {
    if (this.isClosing) {
      return;
    }

    this.isClosing = true;

    // 执行关闭动画
    animateTo({
      duration: 250,
      curve: Curve.EaseOut,
      onFinish: () => {
        if (this.callback.onClose) {
          this.callback.onClose();
        }
      }
    }, () => {
      this.panOffset = 400;
    });
  }

  /**
   * 处理播放/暂停
   */
  private async handlePlayPause(): Promise<void> {
    try {
      await this.viewModel.togglePlayPause();
    } catch (error) {
      const err = error as Error;
      console.error(`[PlayerPage] 播放/暂停失败: ${err.message}`);
    }
  }

  /**
   * 处理上一首
   */
  private async handlePrevious(): Promise<void> {
    try {
      await this.viewModel.previous();
    } catch (error) {
      const err = error as Error;
      console.error(`[PlayerPage] 上一首失败: ${err.message}`);
    }
  }

  /**
   * 处理下一首
   */
  private async handleNext(): Promise<void> {
    try {
      await this.viewModel.next();
    } catch (error) {
      const err = error as Error;
      console.error(`[PlayerPage] 下一首失败: ${err.message}`);
    }
  }

  /**
   * 处理进度跳转
   * @param position 目标位置（毫秒）
   */
  private async handleSeek(position: number): Promise<void> {
    try {
      await this.viewModel.seekTo(position);
    } catch (error) {
      const err = error as Error;
      console.error(`[PlayerPage] 跳转失败: ${err.message}`);
    }
  }

  /**
   * 处理音量变化
   * @param volume 新音量值（0-1）
   */
  private async handleVolumeChange(volume: number): Promise<void> {
    this.currentVolume = volume;
    if (volume > 0) {
      this.isMuted = false;
    }
    try {
      await this.viewModel.setVolume(volume);
    } catch (error) {
      const err = error as Error;
      console.error(`[PlayerPage] 设置音量失败: ${err.message}`);
    }
  }

  /**
   * 处理静音切换
   */
  private async handleMuteToggle(): Promise<void> {
    if (this.isMuted) {
      // 取消静音，恢复之前的音量
      this.isMuted = false;
      this.currentVolume = this.lastVolume > 0 ? this.lastVolume : 0.5;
    } else {
      // 静音，记录当前音量
      this.lastVolume = this.currentVolume;
      this.isMuted = true;
      this.currentVolume = 0;
    }

    try {
      await this.viewModel.setVolume(this.currentVolume);
    } catch (error) {
      const err = error as Error;
      console.error(`[PlayerPage] 静音切换失败: ${err.message}`);
    }
  }

  /**
   * 处理播放模式变化
   * @param mode 新播放模式
   */
  private handlePlayModeChange(mode: PlayMode): void {
    this.viewModel.setPlayMode(mode);
  }

  /**
   * 处理分享
   */
  private handleShare(): void {
    this.showMoreMenu = false;
    if (this.callback.onShare) {
      this.callback.onShare();
    }
  }

  /**
   * 处理添加到播放列表
   */
  private handleAddToPlaylist(): void {
    this.showMoreMenu = false;
    if (this.callback.onAddToPlaylist) {
      this.callback.onAddToPlaylist();
    }
  }

  /**
   * 处理手势拖动
   * @param offset 拖动偏移量
   */
  private handlePanUpdate(offset: number): void {
    if (offset > 0) {
      this.panOffset = offset;
    }
  }

  /**
   * 处理手势结束
   * @param velocity 滑动速度
   */
  private handlePanEnd(velocity: number): void {
    // 如果滑动距离超过阈值或速度足够快，关闭页面
    const threshold = 200;
    if (this.panOffset > threshold || velocity > 1000) {
      this.closePage();
    } else {
      // 恢复到原位
      animateTo({
        duration: 200,
        curve: Curve.EaseOut
      }, () => {
        this.panOffset = 0;
      });
    }
  }

  build() {
    Stack() {
      // 主内容区域
      Column() {
        // 顶部控制栏
        this.buildTopBar()

        // 主内容区域（可滑动）
        Column() {
          // 专辑封面区域
          this.buildAlbumArtSection()

          // 曲目信息
          this.buildTrackInfo()

          // 进度条
          this.buildProgressSection()

          // 主播放控制
          this.buildMainControls()

          // 次要控制
          this.buildSecondaryControls()
        }
        .layoutWeight(1)
        .width('100%')
        .padding({ left: 24, right: 24 })
        .translate({ y: this.panOffset })
        .gesture(
          PanGesture({ direction: PanDirection.Vertical })
            .onActionUpdate((event: GestureEvent) => {
              if (event.offsetY > 0) {
                this.handlePanUpdate(event.offsetY);
              }
            })
            .onActionEnd((event: GestureEvent) => {
              this.handlePanEnd(event.velocity);
            })
        )

        // 加载指示器
        if (this.viewModel.isLoading) {
          this.buildLoadingOverlay()
        }

        // 错误提示
        if (this.viewModel.errorMessage !== null) {
          this.buildErrorToast()
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_bg'))
      .opacity(1 - this.panOffset / 400)

      // 更多选项菜单
      if (this.showMoreMenu) {
        this.buildMoreMenu()
      }
    }
    .width('100%')
    .height('100%')
  }

  /**
   * 构建顶部控制栏
   */
  @Builder
  buildTopBar() {
    Row() {
      // 返回按钮
      Button() {
        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(24)
          .fontColor([$r('app.color.primary_text')])
      }
      .width(48)
      .height(48)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.handleBack())

      // 标题
      Text('正在播放')
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor($r('app.color.primary_text'))
        .layoutWeight(1)
        .textAlign(TextAlign.Center)

      // 更多选项按钮
      Button() {
        SymbolGlyph($r('sys.symbol.ellipsis_circle'))
          .fontSize(24)
          .fontColor([$r('app.color.primary_text')])
      }
      .width(48)
      .height(48)
      .backgroundColor(Color.Transparent)
      .onClick(() => this.handleMoreOptions())
    }
    .width('100%')
    .height(56)
    .padding({ left: 4, right: 4 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 构建专辑封面区域
   */
  @Builder
  buildAlbumArtSection() {
    Column() {
      AlbumArt({
        imageUrl: this.getAlbumArtUrl(),
        albumSize: 280,
        albumBorderRadius: 16,
        showShadow: true,
        isPlaying: this.viewModel.isPlaying
      })
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .margin({ top: 24, bottom: 32 })
  }

  /**
   * 构建曲目信息区域
   */
  @Builder
  buildTrackInfo() {
    Column() {
      // 曲目标题
      Text(this.getTrackTitle())
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.primary_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)

      // 艺术家
      Text(this.getTrackArtist())
        .fontSize(16)
        .fontWeight(FontWeight.Normal)
        .fontColor($r('app.color.secondary_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ top: 8 })
    }
    .width('100%')
    .margin({ bottom: 24 })
  }

  /**
   * 构建进度条区域
   */
  @Builder
  buildProgressSection() {
    Column() {
      ProgressBar({
        currentTime: this.viewModel.currentTime,
        duration: this.viewModel.duration,
        onSeek: (position: number) => this.handleSeek(position)
      })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 构建主播放控制区域
   */
  @Builder
  buildMainControls() {
    Column() {
      PlayerControls({
        isPlaying: this.viewModel.isPlaying,
        isPreviousEnabled: true,
        isNextEnabled: true,
        onPlayPause: () => this.handlePlayPause(),
        onPrevious: () => this.handlePrevious(),
        onNext: () => this.handleNext()
      })
    }
    .width('100%')
    .margin({ bottom: 16 })
  }

  /**
   * 构建次要控制区域
   */
  @Builder
  buildSecondaryControls() {
    Row() {
      // 播放模式按钮
      PlayModeButton({
        currentMode: this.viewModel.playMode,
        buttonSize: 44,
        iconSize: 22,
        showLabel: false,
        onModeChange: (mode: PlayMode) => this.handlePlayModeChange(mode)
      })

      // 音量控制
      VolumeSlider({
        volume: this.currentVolume,
        isMuted: this.isMuted,
        showPercentageLabel: false,
        onVolumeChange: (volume: number) => this.handleVolumeChange(volume),
        onMuteToggle: () => this.handleMuteToggle()
      })
    }
    .width('100%')
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 构建加载覆盖层
   */
  @Builder
  buildLoadingOverlay() {
    Column() {
      BufferingIndicator({
        indicatorSize: 48,
        text: '加载中...'
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor('rgba(0, 0, 0, 0.3)')
  }

  /**
   * 构建错误提示
   */
  @Builder
  buildErrorToast() {
    Column() {
      Row() {
        SymbolGlyph($r('sys.symbol.exclamationmark_triangle'))
          .fontSize(16)
          .fontColor([Color.White])

        Text(this.viewModel.errorMessage ?? '')
          .fontSize(14)
          .fontColor(Color.White)
          .layoutWeight(1)
          .margin({ left: 8 })

        Button() {
          SymbolGlyph($r('sys.symbol.xmark'))
            .fontSize(14)
            .fontColor([Color.White])
        }
        .width(32)
        .height(32)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.viewModel.clearError())
      }
      .width('90%')
      .padding({ left: 16, right: 8, top: 12, bottom: 12 })
      .backgroundColor($r('app.color.error'))
      .borderRadius(8)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .position({ x: 0, y: 60 })
    .justifyContent(FlexAlign.Center)
  }

  /**
   * 构建更多选项菜单
   */
  @Builder
  buildMoreMenu() {
    Column() {
      // 遮罩层
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.3)')
        .onClick(() => {
          this.showMoreMenu = false;
        })

      // 菜单面板
      Column() {
        // 分享选项
        this.buildMenuItem(
          $r('sys.symbol.share'),
          '分享',
          () => this.handleShare()
        )

        // 分隔线
        Divider()
          .width('100%')
          .height(0.5)
          .color($r('sys.color.ohos_id_color_list_separator'))

        // 添加到播放列表
        this.buildMenuItem(
          $r('sys.symbol.plus'),
          '添加到播放列表',
          () => this.handleAddToPlaylist()
        )
      }
      .width('200')
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(12)
      .shadow({
        radius: 16,
        color: '#1A000000',
        offsetX: 0,
        offsetY: 4
      })
      .position({ x: '60%', y: 60 })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
  }

  /**
   * 构建菜单项
   */
  @Builder
  buildMenuItem(icon: Resource, label: string, onClick: () => void) {
    Row() {
      SymbolGlyph(icon)
        .fontSize(20)
        .fontColor([$r('app.color.primary_text')])

      Text(label)
        .fontSize(16)
        .fontColor($r('app.color.primary_text'))
        .margin({ left: 12 })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .onClick(onClick)
  }
}

/**
 * 使用示例：
 *
 * ```typescript
 * import { PlayerPage, PlayerPageCallback } from './musicplayer/pages/PlayerPage';
 *
 * // 在路由中使用
 * @Entry
 * @Component
 * struct MainPage {
 *   @State showPlayer: boolean = false;
 *
 *   build() {
 *     Stack() {
 *       // 主页面内容...
 *
 *       // 全屏播放器
 *       if (this.showPlayer) {
 *         PlayerPage({
 *           callback: {
 *             onClose: () => {
 *               this.showPlayer = false;
 *             },
 *             onShare: () => {
 *               // 处理分享
 *             },
 *             onAddToPlaylist: () => {
 *               // 添加到播放列表
 *             }
 *           }
 *         })
 *       }
 *     }
 *   }
 * }
 * ```
 */

export default PlayerPage;
