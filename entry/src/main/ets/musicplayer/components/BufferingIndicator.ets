/**
 * 缓冲指示器组件
 * 用于显示音乐播放时的加载/缓冲状态
 * 支持淡入淡出动画和可选文本标签
 */

/**
 * 缓冲指示器组件参数接口
 */
export interface BufferingIndicatorParams {
  /** 是否正在加载 */
  isLoading: boolean;
  /** 指示器尺寸（vp） */
  size?: number;
  /** 加载提示文本（可选） */
  text?: string;
}

/**
 * 缓冲指示器组件
 * 在音乐缓冲时显示加载动画
 *
 * @example
 * // 基本用法
 * BufferingIndicator({
 *   isLoading: this.isBuffering
 * })
 *
 * @example
 * // 带文本和自定义尺寸
 * BufferingIndicator({
 *   isLoading: this.isBuffering,
 *   size: 36,
 *   text: '缓冲中...'
 * })
 */
@Component
export struct BufferingIndicator {
  /** 是否正在加载 */
  @Prop @Watch('onLoadingChanged') isLoading: boolean = false;

  /** 指示器尺寸（vp） */
  @Prop indicatorSize: number = 48;

  /** 加载提示文本（可选） */
  @Prop text: string = '缓冲中...';

  /** 内部状态：用于动画的可见性 */
  @State private visibleOpacity: number = 0;

  /**
   * 监听 isLoading 变化，触发动画
   */
  private onLoadingChanged(): void {
    this.visibleOpacity = this.isLoading ? 1 : 0;
  }

  /**
   * 组件即将显示
   */
  aboutToAppear(): void {
    this.visibleOpacity = this.isLoading ? 1 : 0;
  }

  build() {
    if (this.isLoading || this.visibleOpacity > 0) {
      Column() {
        // 圆形进度指示器
        LoadingProgress()
          .width(this.indicatorSize)
          .height(this.indicatorSize)
          .color($r('sys.color.ohos_id_color_activated'))

        // 可选文本标签
        if (this.text && this.text.length > 0) {
          Text(this.text)
            .fontSize(14)
            .fontColor($r('sys.color.ohos_id_color_text_secondary'))
            .textAlign(TextAlign.Center)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .margin({ top: 12 })
        }
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .padding({ top: 16, bottom: 16 })
      .opacity(this.visibleOpacity)
      .animation({
        duration: 300,
        curve: Curve.EaseInOut
      })
      .accessibilityGroup(true)
      .accessibilityText(this.isLoading ? '正在加载' : '')
      .accessibilityLevel('important')
    } else {
      // 不渲染任何内容
      Row()
        .width(0)
        .height(0)
    }
  }
}

/**
 * 便捷方法：创建缓冲指示器组件
 * @param params 组件参数
 */
export function BufferingIndicatorBuilder(params: BufferingIndicatorParams): void {
  BufferingIndicator({
    isLoading: params.isLoading,
    indicatorSize: params.size ?? 48,
    text: params.text ?? '缓冲中...'
  });
}

/**
 * 内联缓冲指示器组件
 * 用于在播放控制区域内显示小型缓冲状态
 */
@Component
export struct InlineBufferingIndicator {
  /** 是否正在加载 */
  @Prop isLoading: boolean = false;

  /** 指示器尺寸（vp），默认较小 */
  @Prop indicatorSize: number = 24;

  build() {
    if (this.isLoading) {
      LoadingProgress()
        .width(this.indicatorSize)
        .height(this.indicatorSize)
        .color($r('sys.color.ohos_id_color_activated'))
        .accessibilityText('正在缓冲')
        .accessibilityLevel('auto')
    }
  }
}
