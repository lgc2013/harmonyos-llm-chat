/**
 * VolumeSlider 音量滑块组件
 * 遵循华为 UX 体验标准
 * - 图标触控区域 >= 48vp x 48vp (2.1.3.3)
 * - 滑块轨道在深色模式下可见 (2.2.1)
 * - 静音状态显示静音图标
 */
import { DEFAULT_VOLUME } from '../common/Constants';

/**
 * 音量滑块组件
 * 用于控制播放器音量，支持静音切换
 */
@Component
export struct VolumeSlider {
  /** 当前音量值，范围 0-1 */
  @Prop volume: number = DEFAULT_VOLUME;

  /** 是否静音（可选） */
  @Prop isMuted: boolean = false;

  /** 是否显示百分比标签（可选） */
  @Prop showPercentageLabel: boolean = false;

  /** 音量变化回调 */
  onVolumeChange?: (volume: number) => void;

  /** 静音切换回调（可选） */
  onMuteToggle?: () => void;

  /**
   * 组件构建
   */
  build() {
    Row() {
      // 音量图标按钮 - 触控区域 48vp x 48vp
      this.VolumeIconButton()

      // 音量滑块
      this.VolumeSliderControl()

      // 百分比标签（可选）
      if (this.showPercentageLabel) {
        this.VolumePercentageLabel()
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 8, right: 16 })
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Start)
  }

  /**
   * 音量图标按钮
   * 点击切换静音状态
   */
  @Builder
  VolumeIconButton() {
    Row() {
      if (this.isMuted || this.volume === 0) {
        // 静音图标
        SymbolGlyph($r('sys.symbol.speaker_slash'))
          .fontSize(24)
          .fontColor([$r('app.color.secondary_text')])
      } else if (this.volume < 0.33) {
        // 低音量图标
        SymbolGlyph($r('sys.symbol.speaker_wave_1'))
          .fontSize(24)
          .fontColor([$r('app.color.primary_text')])
      } else if (this.volume < 0.66) {
        // 中音量图标
        SymbolGlyph($r('sys.symbol.speaker_wave_2'))
          .fontSize(24)
          .fontColor([$r('app.color.primary_text')])
      } else {
        // 高音量图标
        SymbolGlyph($r('sys.symbol.speaker_wave_3'))
          .fontSize(24)
          .fontColor([$r('app.color.primary_text')])
      }
    }
    .width(48)
    .height(48)
    .borderRadius(24)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      if (this.onMuteToggle) {
        this.onMuteToggle();
      }
    })
  }

  /**
   * 音量滑块控件
   * 值范围 0-100，映射到音量 0-1
   */
  @Builder
  VolumeSliderControl() {
    Slider({
      value: this.volume * 100,
      min: 0,
      max: 100,
      step: 1,
      style: SliderStyle.OutSet
    })
      .width('100%')
      .layoutWeight(1)
      .blockColor($r('app.color.primary'))
      .trackColor($r('app.color.slider_track'))
      .selectedColor($r('app.color.primary'))
      .showSteps(false)
      .showTips(true)
      .trackThickness(4)
      .blockSize({ width: 20, height: 20 })
      .onChange((value: number) => {
        // 将滑块值 (0-100) 映射到音量值 (0-1)
        const newVolume: number = value / 100;
        if (this.onVolumeChange) {
          this.onVolumeChange(newVolume);
        }
      })
  }

  /**
   * 音量百分比标签
   */
  @Builder
  VolumePercentageLabel() {
    Text(`${Math.round(this.volume * 100)}%`)
      .fontSize(14)
      .fontColor($r('app.color.secondary_text'))
      .width(48)
      .textAlign(TextAlign.End)
      .margin({ left: 8 })
  }
}
