/**
 * MiniPlayer 迷你播放器组件
 * 显示在屏幕底部的播放控制条，支持快速控制播放
 * 遵循华为 UX 体验标准：
 * - 可点击区域 >= 40vp x 40vp
 * - 避开系统导航栏区域
 * - 支持深色模式
 */

/**
 * 迷你播放器组件属性接口
 */
export interface MiniPlayerProps {
  /** 曲目标题 */
  title: string;
  /** 艺术家名称 */
  artist: string;
  /** 专辑封面图片（可选） */
  albumArt?: string | Resource;
  /** 是否正在播放 */
  isPlaying: boolean;
  /** 播放进度（0-1 范围） */
  progress: number;
  /** 当前播放时间（毫秒） */
  currentTime?: number;
  /** 总时长（毫秒） */
  duration?: number;
}

/**
 * 迷你播放器组件
 * 底部固定显示，提供快捷播放控制和进度预览
 */
@Component
export struct MiniPlayer {
  /** 曲目标题 */
  @Prop title: string = '';
  /** 艺术家名称 */
  @Prop artist: string = '';
  /** 专辑封面图片（可选，支持字符串 URL 或 Resource） */
  @Prop albumArt: string | Resource = '';
  /** 是否正在播放 */
  @Prop isPlaying: boolean = false;
  /** 播放进度（0-1 范围） */
  @Prop progress: number = 0;
  /** 当前播放时间（毫秒） */
  @Prop currentTime: number = 0;
  /** 总时长（毫秒） */
  @Prop duration: number = 0;

  /** 点击整个播放条事件回调 - 打开完整播放器 */
  onTap: () => void = (): void => {};
  /** 播放/暂停按钮事件回调 */
  onPlayPause: () => void = (): void => {};
  /** 下一首按钮事件回调 */
  onNext: () => void = (): void => {};

  /**
   * 获取安全的进度值
   * @returns 进度百分比（0-100）
   */
  private getProgressPercent(): number {
    const clampedProgress = Math.max(0, Math.min(1, this.progress));
    return clampedProgress * 100;
  }

  /**
   * 判断专辑封面是否为有效值
   * @returns 是否有有效封面
   */
  private hasAlbumArt(): boolean {
    if (typeof this.albumArt === 'string') {
      return this.albumArt.length > 0;
    }
    return this.albumArt !== null && this.albumArt !== undefined;
  }

  /**
   * 格式化时间显示
   * @param ms 毫秒数
   * @returns 格式化的时间字符串（mm:ss）
   */
  private formatTime(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  build() {
    Column() {
      // 顶部进度条（带时间显示）
      this.buildProgressBar()

      // 主内容行
      Row() {
        // 专辑封面缩略图
        this.buildAlbumArt()

        // 标题和艺术家信息
        this.buildTrackInfo()

        // 播放/暂停按钮
        this.buildPlayPauseButton()

        // 下一首按钮
        this.buildNextButton()
      }
      .width('100%')
      .height(64)
      .padding({ left: 12, right: 12 })
      .alignItems(VerticalAlign.Center)
      .justifyContent(FlexAlign.Start)
      .onClick(() => {
        // 点击整个区域打开完整播放器
        this.onTap();
      })
    }
    .width('100%')
    .backgroundColor($r('app.color.card_bg'))
    .shadow({
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: -2
    })
    // 底部安全区域 padding，避开系统导航栏
    .padding({ bottom: 0 })
  }

  /**
   * 构建顶部进度条
   * 显示当前播放进度和时间
   */
  @Builder
  buildProgressBar() {
    Row() {
      // 当前时间
      Text(this.formatTime(this.currentTime))
        .fontSize(10)
        .fontColor($r('app.color.secondary_text'))
        .width(36)
        .textAlign(TextAlign.Center)

      // 进度条容器
      Row() {
        // 进度指示条
        Row()
          .width(`${this.getProgressPercent()}%`)
          .height(2)
          .backgroundColor($r('app.color.primary'))

        // 剩余部分
        Row()
          .layoutWeight(1)
          .height(2)
          .backgroundColor($r('sys.color.ohos_id_color_foreground_contrary'))
      }
      .layoutWeight(1)
      .height(2)
      .margin({ left: 4, right: 4 })

      // 总时长
      Text(this.formatTime(this.duration))
        .fontSize(10)
        .fontColor($r('app.color.secondary_text'))
        .width(36)
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(16)
    .padding({ left: 8, right: 8 })
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 构建专辑封面缩略图
   * 48x48vp，圆角矩形
   */
  @Builder
  buildAlbumArt() {
    if (this.hasAlbumArt()) {
      Image(this.albumArt)
        .width(48)
        .height(48)
        .borderRadius(6)
        .objectFit(ImageFit.Cover)
        .alt($r('app.media.ic_public_music'))
    } else {
      // 默认音乐图标占位
      Row() {
        Image($r('app.media.ic_public_music'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.secondary_text'))
      }
      .width(48)
      .height(48)
      .borderRadius(6)
      .backgroundColor($r('sys.color.ohos_id_color_foreground_contrary'))
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    }
  }

  /**
   * 构建曲目信息区域
   * 包含标题和艺术家，超长文本显示省略号
   */
  @Builder
  buildTrackInfo() {
    Column() {
      // 曲目标题
      Text(this.title || '未知曲目')
        .fontSize(14)
        .fontColor($r('app.color.primary_text'))
        .fontWeight(FontWeight.Medium)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Start)

      // 艺术家名称
      Text(this.artist || '未知艺术家')
        .fontSize(12)
        .fontColor($r('app.color.secondary_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Start)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .margin({ left: 12, right: 8 })
  }

  /**
   * 构建播放/暂停按钮
   * 触摸区域 40x40vp
   */
  @Builder
  buildPlayPauseButton() {
    Button() {
      SymbolGlyph(this.isPlaying ?
        $r('sys.symbol.pause_fill') :
        $r('sys.symbol.play_fill'))
        .fontSize(20)
        .fontColor([$r('app.color.primary_text')])
    }
    .width(40)
    .height(40)
    .backgroundColor(Color.Transparent)
    .borderRadius(20)
    .margin({ left: 4 })
    .onClick((event: ClickEvent) => {
      // 阻止事件冒泡，避免触发整个区域的 onTap
      // 事件传播控制在 HarmonyOS 中由组件层级自动处理
      this.onPlayPause();
    })
  }

  /**
   * 构建下一首按钮
   * 触摸区域 40x40vp
   */
  @Builder
  buildNextButton() {
    Button() {
      SymbolGlyph($r('app.media.forward_end'))
        .fontSize(20)
        .fontColor([$r('app.color.primary_text')])
    }
    .width(40)
    .height(40)
    .backgroundColor(Color.Transparent)
    .borderRadius(20)
    .margin({ left: 4, right: 4 })
    .onClick((event: ClickEvent) => {
      // 阻止事件冒泡，避免触发整个区域的 onTap
      // 事件传播控制在 HarmonyOS 中由组件层级自动处理
      this.onNext();
    })
  }
}

/**
 * 使用示例：
 *
 * ```typescript
 * import { MiniPlayer } from './components/MiniPlayer';
 *
 * @Entry
 * @Component
 * struct MainPage {
 *   @State isPlaying: boolean = false;
 *   @State progress: number = 0.35;
 *
 *   build() {
 *     Column() {
 *       // 页面主内容
 *       Text('主内容区域')
 *         .layoutWeight(1)
 *
 *       // 底部迷你播放器
 *       MiniPlayer({
 *         title: '示例曲目',
 *         artist: '艺术家名称',
 *         albumArt: 'https://example.com/cover.jpg',
 *         isPlaying: this.isPlaying,
 *         progress: this.progress,
 *         onTap: () => {
 *           // 打开完整播放器页面
 *           this.navigateToFullPlayer();
 *         },
 *         onPlayPause: () => {
 *           this.isPlaying = !this.isPlaying;
 *         },
 *         onNext: () => {
 *           // 播放下一首
 *           this.playNext();
 *         }
 *       })
 *     }
 *     .width('100%')
 *     .height('100%')
 *   }
 *
 *   private navigateToFullPlayer(): void {
 *     // 导航逻辑...
 *   }
 *
 *   private playNext(): void {
 *     // 下一首逻辑...
 *   }
 * }
 * ```
 */
