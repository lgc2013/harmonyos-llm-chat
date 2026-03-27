/**
 * 进度条组件
 * 用于显示和控制音乐播放进度
 * 支持显示当前时间、总时长和缓冲进度
 */

import { formatTime, clamp } from '../common/Utils';

/**
 * 进度条组件属性接口
 */
interface ProgressBarProps {
  currentTime: number;
  duration: number;
  bufferedTime?: number;
  onSeek?: (position: number) => void;
}

/**
 * 进度条组件
 * 显示播放进度，支持拖拽跳转
 */
@Component
export struct ProgressBar {
  /**
   * 当前播放时间（毫秒）
   */
  @Prop currentTime: number = 0;

  /**
   * 总时长（毫秒）
   */
  @Prop duration: number = 0;

  /**
   * 缓冲进度（毫秒），可选
   */
  @Prop bufferedTime: number = 0;

  /**
   * 用户拖拽跳转回调
   * @param position 跳转位置（毫秒）
   */
  onSeek: (position: number) => void = (): void => {};

  /**
   * 内部滑块值（0-100）
   * 用于在拖拽过程中临时存储值
   */
  @State private sliderValue: number = 0;

  /**
   * 是否正在拖拽
   * 拖拽期间不响应外部 currentTime 更新
   */
  @State private isDragging: boolean = false;

  /**
   * 计算进度百分比
   * @returns 进度百分比（0-100）
   */
  private getProgressPercent(): number {
    if (this.duration <= 0) {
      return 0;
    }
    return clamp((this.currentTime / this.duration) * 100, 0, 100);
  }

  /**
   * 计算缓冲百分比
   * @returns 缓冲百分比（0-100）
   */
  private getBufferedPercent(): number {
    if (this.duration <= 0 || this.bufferedTime <= 0) {
      return 0;
    }
    return clamp((this.bufferedTime / this.duration) * 100, 0, 100);
  }

  /**
   * 格式化时间显示
   * @param ms 毫秒数
   * @returns 格式化的时间字符串
   */
  private formatDisplayTime(ms: number): string {
    return formatTime(ms);
  }

  /**
   * 处理滑块值变化
   * @param value 新的滑块值（0-100）
   */
  private handleSliderChange(value: number): void {
    this.sliderValue = value;
  }

  /**
   * 处理滑块拖拽开始
   */
  private handleSliderChangeStart(): void {
    this.isDragging = true;
    this.sliderValue = this.getProgressPercent();
  }

  /**
   * 处理滑块拖拽结束
   * 计算最终位置并触发 onSeek 回调
   */
  private handleSliderChangeEnd(): void {
    this.isDragging = false;

    // 计算跳转位置
    const seekPosition: number = (this.sliderValue / 100) * this.duration;

    // 触发跳转回调
    if (this.onSeek) {
      this.onSeek(Math.round(seekPosition));
    }
  }

  build() {
    Row() {
      // 当前时间显示
      Text(this.formatDisplayTime(this.currentTime))
        .fontSize(12)
        .fontFamily('monospace')
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width('10%')
        .textAlign(TextAlign.Center)

      // 进度滑块
      Stack() {
        // 缓冲进度条（底层）
        if (this.bufferedTime > 0 && this.duration > 0) {
          Progress({
            value: this.getBufferedPercent(),
            total: 100,
            type: ProgressType.Linear
          })
            .width('100%')
            .height(4)
            .color($r('sys.color.ohos_id_color_text_secondary'))
            .opacity(0.3)
        }

        // 主进度滑块
        Slider({
          value: this.isDragging ? this.sliderValue : this.getProgressPercent(),
          min: 0,
          max: 100,
          step: 0.1,
          style: SliderStyle.OutSet
        })
          .width('100%')
          .blockColor($r('sys.color.ohos_id_color_activated'))
          .trackColor($r('sys.color.ohos_id_color_foreground_contrary'))
          .selectedColor($r('sys.color.ohos_id_color_activated'))
          .showSteps(false)
          .showTips(true)
          .blockSize({ width: 24, height: 24 })
          .trackThickness(4)
          .enabled(this.duration > 0)
          .onChange((value: number, mode: SliderChangeMode) => {
            if (mode === SliderChangeMode.Begin) {
              this.handleSliderChangeStart();
            } else if (mode === SliderChangeMode.Moving) {
              this.handleSliderChange(value);
            } else if (mode === SliderChangeMode.End) {
              this.handleSliderChangeEnd();
            }
          })
      }
      .width('80%')
      .alignContent(Alignment.Center)

      // 总时长显示
      Text(this.formatDisplayTime(this.duration))
        .fontSize(12)
        .fontFamily('monospace')
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .width('10%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .height(40)
    .justifyContent(FlexAlign.SpaceBetween)
    .alignItems(VerticalAlign.Center)
    .padding({ left: 8, right: 8 })
  }
}
