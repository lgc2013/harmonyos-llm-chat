/**
 * AlbumArt 专辑封面组件
 * 用于显示音乐专辑封面图片，支持占位符和播放动画
 * 遵循华为 UX 体验标准：
 * - 图片加载失败时提供友好的占位符
 * - 支持暗色模式
 * - 动画效果平滑流畅
 */

/**
 * 专辑封面组件属性接口
 */
export interface AlbumArtProps {
  /** 图片URL、资源或null（无封面时显示占位符） */
  imageUrl: string | Resource | null;
  /** 封面尺寸（默认 200vp） */
  albumSize?: number;
  /** 圆角半径（默认 12vp） */
  albumBorderRadius?: number;
  /** 是否显示阴影（默认 true） */
  showShadow?: boolean;
  /** 是否显示播放动画（默认 false） */
  isPlaying?: boolean;
}

/**
 * 专辑封面组件
 * 可复用的专辑封面显示组件，支持图片加载、占位符和播放动画
 *
 * @example
 * // 基本用法
 * AlbumArt({
 *   imageUrl: 'https://example.com/cover.jpg',
 *   albumSize: 200
 * })
 *
 * @example
 * // 带播放动画
 * AlbumArt({
 *   imageUrl: track.albumArt,
 *   albumSize: 280,
 *   isPlaying: true
 * })
 *
 * @example
 * // 无封面时显示占位符
 * AlbumArt({
 *   imageUrl: null,
 *   albumSize: 120,
 *   showShadow: false
 * })
 */
@Component
export struct AlbumArt {
  /** 图片URL、资源或null */
  @Prop imageUrl: string | Resource | null = null;

  /** 封面尺寸（vp） */
  @Prop albumSize: number = 200;

  /** 圆角半径（vp） */
  @Prop albumBorderRadius: number = 12;

  /** 是否显示阴影 */
  @Prop showShadow: boolean = true;

  /** 是否显示播放动画 */
  @Prop isPlaying: boolean = false;

  /** 内部状态：图片是否加载失败 */
  @State private imageLoadFailed: boolean = false;

  /** 内部状态：用于触发动画的脉冲值 */
  @State private pulseValue: number = 1;

  /** 动画定时器ID */
  private animationTimer: number = -1;

  /**
   * 组件即将显示
   * 启动播放动画定时器
   */
  aboutToAppear(): void {
    if (this.isPlaying) {
      this.startPulseAnimation();
    }
  }

  /**
   * 组件即将消失
   * 清理动画定时器
   */
  aboutToDisappear(): void {
    this.stopPulseAnimation();
  }

  /**
   * 启动脉冲动画
   */
  private startPulseAnimation(): void {
    // 清理已有的定时器
    this.stopPulseAnimation();

    // 使用定时器实现脉冲效果
    this.animationTimer = setInterval(() => {
      animateTo({
        duration: 1000,
        curve: Curve.EaseInOut,
        iterations: 1,
        playMode: PlayMode.Normal
      }, () => {
        this.pulseValue = this.pulseValue === 1 ? 1.03 : 1;
      });
    }, 2000);
  }

  /**
   * 停止脉冲动画
   */
  private stopPulseAnimation(): void {
    if (this.animationTimer !== -1) {
      clearInterval(this.animationTimer);
      this.animationTimer = -1;
    }
  }

  /**
   * 检查是否有有效的图片源
   * @returns 是否有有效图片
   */
  private hasValidImage(): boolean {
    if (this.imageUrl === null || this.imageUrl === undefined) {
      return false;
    }
    if (typeof this.imageUrl === 'string' && this.imageUrl.length === 0) {
      return false;
    }
    return !this.imageLoadFailed;
  }

  /**
   * 获取阴影样式
   * @returns 阴影配置或undefined
   */
  private getShadowStyle(): ShadowOptions | undefined {
    if (!this.showShadow) {
      return undefined;
    }
    return {
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 4
    };
  }

  build() {
    Stack() {
      if (this.hasValidImage()) {
        // 显示专辑封面图片
        this.buildImageContent()
      } else {
        // 显示占位符
        this.buildPlaceholderContent()
      }

      // 播放指示器覆盖层（可选）
      if (this.isPlaying && this.hasValidImage()) {
        this.buildPlayingOverlay()
      }
    }
    .width(this.albumSize)
    .height(this.albumSize)
    .scale({ x: this.isPlaying ? this.pulseValue : 1, y: this.isPlaying ? this.pulseValue : 1 })
    .animation(this.isPlaying ? {
      duration: 500,
      curve: Curve.EaseInOut
    } : undefined)
  }

  /**
   * 构建图片内容
   */
  @Builder
  buildImageContent() {
    Image(this.imageUrl as ResourceStr)
      .width('100%')
      .height('100%')
      .objectFit(ImageFit.Cover)
      .borderRadius(this.albumBorderRadius)
      .shadow(this.getShadowStyle())
      .alt($r('sys.symbol.music_note_list')) // 加载失败时的备用图片
      .onError(() => {
        // 图片加载失败，显示占位符
        this.imageLoadFailed = true;
      })
      .onComplete(() => {
        // 图片加载成功
        this.imageLoadFailed = false;
      })
  }

  /**
   * 构建占位符内容
   * 当没有封面图片时显示音乐图标
   */
  @Builder
  buildPlaceholderContent() {
    Column() {
      // 音乐音符图标
      SymbolGlyph($r('app.media.music_albums'))
        .fontSize(this.albumSize * 0.4) // 图标大小为容器的40%
        .fontColor([$r('app.color.secondary_text')])
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(this.albumBorderRadius)
    .shadow(this.getShadowStyle())
  }

  /**
   * 构建播放中覆盖层
   * 在封面底部显示半透明的播放指示
   */
  @Builder
  buildPlayingOverlay() {
    Column() {
      Blank()

      // 底部播放指示条
      Row() {
        // 音频波形动画指示器
        ForEach([1, 2, 3], (item: number) => {
          Column()
            .width(3)
            .height(8 + (item % 3) * 4)
            .backgroundColor(Color.White)
            .borderRadius(1.5)
            .margin({ left: item === 1 ? 0 : 2 })
            .animation({
              duration: 300,
              curve: Curve.EaseInOut,
              iterations: -1,
              playMode: PlayMode.Alternate
            })
        })
      }
      .padding({ left: 12, right: 12, top: 8, bottom: 8 })
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor('rgba(0, 0, 0, 0.4)')
      .borderRadius({
        bottomLeft: this.albumBorderRadius,
        bottomRight: this.albumBorderRadius
      })
    }
    .width('100%')
    .height('100%')
    .borderRadius(this.albumBorderRadius)
  }
}

/**
 * 使用示例：
 *
 * ```typescript
 * import { AlbumArt } from './components/AlbumArt';
 *
 * @Entry
 * @Component
 * struct PlayerPage {
 *   @State currentTrack: MusicTrack | null = null;
 *   @State isPlaying: boolean = false;
 *
 *   build() {
 *     Column() {
 *       // 大尺寸专辑封面（播放页面）
 *       AlbumArt({
 *         imageUrl: this.currentTrack?.albumArt ?? null,
 *         size: 280,
 *         borderRadius: 16,
 *         showShadow: true,
 *         isPlaying: this.isPlaying
 *       })
 *
 *       // 列表中的小尺寸封面
 *       AlbumArt({
 *         imageUrl: this.currentTrack?.albumArt ?? null,
 *         size: 48,
 *         borderRadius: 4,
 *         showShadow: false
 *       })
 *
 *       // 使用本地资源
 *       AlbumArt({
 *         imageUrl: $r('app.media.default_album'),
 *         size: 120
 *       })
 *     }
 *   }
 * }
 * ```
 */
