/**
 * PlayerControls 播放控制组件
 * 提供上一首、播放/暂停、下一首控制按钮
 * 遵循华为 UX 体验标准：按钮触摸区域 >= 48vp x 48vp
 */

/** 控制按钮参数接口 */
interface ControlButtonParams {
  icon: Resource;
  isEnabled: boolean;
  buttonSize: number;
  iconSize: number;
  onClick: () => void;
}

/** 播放暂停按钮参数接口 */
interface PlayPauseButtonParams {
  isPlaying: boolean;
  onClick: () => void;
}

/**
 * 播放控制组件
 * 支持播放/暂停、上一首、下一首操作
 */
@Component
export struct PlayerControls {
  /** 当前是否正在播放 */
  @Prop isPlaying: boolean = false;
  /** 上一首按钮是否可用 */
  @Prop isPreviousEnabled: boolean = true;
  /** 下一首按钮是否可用 */
  @Prop isNextEnabled: boolean = true;
  /** 播放模式（可选，用于显示模式指示器） */
  @Prop playMode?: string;

  /** 播放/暂停事件回调 */
  onPlayPause: () => void = () => {};
  /** 上一首事件回调 */
  onPrevious: () => void = () => {};
  /** 下一首事件回调 */
  onNext: () => void = () => {};

  /**
   * 获取播放模式图标
   * @returns Resource 播放模式图标
   */
  private getPlayModeIcon(): Resource {
    if (!this.playMode) {
      return $r('sys.symbol.list_bullet');
    }
    switch (this.playMode) {
      case 'SHUFFLE':
        return $r('sys.symbol.shuffle');
      case 'REPEAT_ONE':
        return $r('sys.symbol.repeat_1');
      case 'REPEAT_ALL':
        return $r('sys.symbol.repeat');
      case 'SEQUENCE':
      default:
        return $r('sys.symbol.list_bullet');
    }
  }

  build() {
    Column() {
      // 播放模式指示器（可选）
      if (this.playMode) {
        Row() {
          SymbolGlyph(this.getPlayModeIcon())
            .fontSize(16)
            .fontColor([$r('app.color.secondary_text')])
        }
        .height(24)
        .margin({ bottom: 8 })
      }

      // 主控制按钮行
      Row() {
        // 上一首按钮
        this.ControlButton({
          icon: $r('app.media.backward_end'),
          isEnabled: this.isPreviousEnabled,
          buttonSize: 48,
          iconSize: 24,
          onClick: () => {
            if (this.isPreviousEnabled) {
              this.onPrevious();
            }
          }
        })

        // 播放/暂停按钮（更大更突出）
        this.PlayPauseButton({
          isPlaying: this.isPlaying,
          onClick: () => {
            this.onPlayPause();
          }
        })

        // 下一首按钮
        this.ControlButton({
          icon: $r('app.media.forward_end'),
          isEnabled: this.isNextEnabled,
          buttonSize: 48,
          iconSize: 24,
          onClick: () => {
            if (this.isNextEnabled) {
              this.onNext();
            }
          }
        })
      }
      .width('100%')
      .height(80)
      .justifyContent(FlexAlign.SpaceEvenly)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
  }

  /**
   * 通用控制按钮构建器
   */
  @Builder
  ControlButton(params: ControlButtonParams) {
    Button() {
      SymbolGlyph(params.icon)
        .fontSize(params.iconSize)
        .fontColor([params.isEnabled ?
          $r('app.color.primary_text') :
          $r('app.color.disabled_icon')])
    }
    .width(params.buttonSize)
    .height(params.buttonSize)
    .backgroundColor(Color.Transparent)
    .borderRadius(params.buttonSize / 2)
    .enabled(params.isEnabled)
    .opacity(params.isEnabled ? 1 : 0.5)
    .onClick(() => {
      params.onClick();
    })
  }

  /**
   * 播放/暂停按钮构建器
   * 按钮尺寸为 64x64vp，使用主题色突出显示
   */
  @Builder
  PlayPauseButton(params: PlayPauseButtonParams) {
    Button() {
      SymbolGlyph(params.isPlaying ?
        $r('sys.symbol.pause_fill') :
        $r('sys.symbol.play_fill'))
        .fontSize(32)
        .fontColor([$r('app.color.send_icon')])
    }
    .width(64)
    .height(64)
    .backgroundColor($r('app.color.primary'))
    .borderRadius(32)
    .shadow({
      radius: 8,
      color: $r('app.color.primary'),
      offsetX: 0,
      offsetY: 2
    })
    .onClick(() => {
      params.onClick();
    })
  }
}
