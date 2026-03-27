/**
 * PlayModeButton 播放模式切换按钮组件
 * 用于循环切换播放模式：顺序播放 → 列表循环 → 单曲循环 → 随机播放
 * 遵循华为 UX 体验标准
 */
import { PlayMode } from '../models/PlayerState';
import { PLAY_MODE_MAP } from '../models/Enums';

/**
 * 播放模式切换按钮组件
 * 支持点击循环切换播放模式
 */
@Component
export struct PlayModeButton {
  /** 当前播放模式 */
  @Prop currentMode: PlayMode = PlayMode.SEQUENCE;

  /** 模式切换事件回调 */
  onModeChange?: (mode: PlayMode) => void;

  /** 按钮大小 */
  @Prop buttonSize: number = 48;

  /** 图标大小 */
  @Prop iconSize: number = 24;

  /** 是否显示模式名称提示 */
  @Prop showLabel: boolean = false;

  /** 播放模式循环顺序 */
  private readonly modeOrder: PlayMode[] = [
    PlayMode.SEQUENCE,
    PlayMode.LOOP,
    PlayMode.SINGLE,
    PlayMode.SHUFFLE
  ];

  /**
   * 获取下一个播放模式
   * @returns 下一个播放模式
   */
  private getNextMode(): PlayMode {
    const currentIndex = this.modeOrder.indexOf(this.currentMode);
    const nextIndex = (currentIndex + 1) % this.modeOrder.length;
    return this.modeOrder[nextIndex];
  }

  /**
   * 处理按钮点击事件
   */
  private handleButtonClick(): void {
    const nextMode = this.getNextMode();
    if (this.onModeChange) {
      this.onModeChange(nextMode);
    }
  }

  /**
   * 获取当前模式的图标
   * @returns 图标名称
   */
  private getCurrentIcon(): string {
    return PLAY_MODE_MAP[this.currentMode]?.icon ?? 'list';
  }

  /**
   * 获取当前模式的名称
   * @returns 模式名称（中文）
   */
  private getCurrentModeName(): string {
    return PLAY_MODE_MAP[this.currentMode]?.name ?? '顺序播放';
  }

  build() {
    Row() {
      // 播放模式按钮
      Button({ type: ButtonType.Circle }) {
        Image($r(`app.media.${this.getCurrentIcon()}`))
          .width(this.iconSize)
          .height(this.iconSize)
          .fillColor($r('app.color.primary_icon'))
          .objectFit(ImageFit.Contain)
      }
      .width(this.buttonSize)
      .height(this.buttonSize)
      .backgroundColor($r('app.color.button_background'))
      .onClick(() => this.handleButtonClick())
      .gesture(
        LongPressGesture({ repeat: false })
          .onAction(() => {
            // 长按可以用于显示提示（可选功能）
          })
      )

      // 可选的模式名称标签
      if (this.showLabel) {
        Text(this.getCurrentModeName())
          .fontSize(12)
          .fontColor($r('app.color.secondary_text'))
          .margin({ left: 8 })
      }
    }
    .alignItems(VerticalAlign.Center)
  }
}
