/**
 * RadioListItem 电台列表项组件
 * 遵循华为 UX 体验标准：
 * - 可点击区域 >= 48vp x 48vp (2.1.4.1)
 * - 文字对比度 > 4.5:1 (2.1.4.2)
 * - 图标最小 8vp (2.1.4.3.2)
 * - 支持深色模式
 */
import { RadioStation } from '../models/RadioStation';

/**
 * 电台列表项组件属性接口
 */
export interface RadioListItemProps {
  /** 电台数据（必填） */
  station: RadioStation;
  /** 是否正在播放（默认 false） */
  isPlaying?: boolean;
  /** 点击事件回调 */
  onClick?: () => void;
  /** 长按事件回调（可选，用于上下文菜单） */
  onLongPress?: () => void;
}

/**
 * 电台列表项组件
 * 用于在电台列表中显示单个电台信息
 * 支持点击播放和长按显示上下文菜单
 */
@Component
export struct RadioListItem {
  /** 电台数据 */
  @Prop station: RadioStation = {} as RadioStation;
  /** 是否正在播放 */
  @Prop isPlaying: boolean = false;
  /** 点击事件回调 */
  onStationClick?: () => void;
  /** 长按事件回调 */
  onStationLongPress?: () => void;

  /**
   * 构建组件UI
   */
  build() {
    Row() {
      // 左侧：电台图标/Logo (48x48vp)
      this.buildLogoSection()

      // 中间：电台名称、国家标签、编解码信息
      this.buildInfoSection()

      // 右侧：播放指示器
      this.buildPlayingIndicator()
    }
    .width('100%')
    .constraintSize({ minHeight: 64 }) // 确保可点击区域 >= 48vp
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .backgroundColor(this.isPlaying ? $r('app.color.card_bg') : Color.Transparent)
    .borderRadius(8)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Start)
    .gesture(
      GestureGroup(GestureMode.Exclusive,
        // 点击手势
        TapGesture()
          .onAction(() => {
            if (this.onStationClick) {
              this.onStationClick();
            }
          }),
        // 长按手势
        LongPressGesture({ repeat: false })
          .onAction(() => {
            if (this.onStationLongPress) {
              this.onStationLongPress();
            }
          })
      )
    )
    .onClick(() => {
      if (this.onStationClick) {
        this.onStationClick();
      }
    })
  }

  /**
   * 构建Logo区域：电台图标或占位图
   */
  @Builder
  buildLogoSection() {
    if (this.station.favicon && this.station.favicon.length > 0) {
      // 显示电台Logo
      Image(this.station.favicon)
        .width(48)
        .height(48)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
        .alt($r('sys.symbol.radio')) // 加载失败时显示默认图标
        .backgroundColor($r('app.color.card_bg'))
    } else {
      // 显示默认电台图标占位
      Row() {
        Image($r('sys.symbol.radio'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.secondary_text'))
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(8)
    }
  }

  /**
   * 构建信息区域：电台名称、国家标签、编解码信息
   */
  @Builder
  buildInfoSection() {
    Column() {
      // 电台名称（粗体，16fp）
      Text(this.station.name)
        .fontSize(16)
        .fontColor($r('app.color.primary_text'))
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Start)

      // 第二行：国家标签和编解码信息
      Row() {
        // 国家标签（Chip样式，可选）
        if (this.station.country && this.station.country.length > 0) {
          Text(this.getCountryDisplayName())
            .fontSize(12)
            .fontColor($r('app.color.primary'))
            .backgroundColor($r('app.color.chip_bg'))
            .padding({ left: 8, right: 8, top: 2, bottom: 2 })
            .borderRadius(4)
            .maxLines(1)
        }

        // 编解码/比特率信息（如 "MP3 128k"）
        if (this.getCodecBitrateInfo().length > 0) {
          Text(this.getCodecBitrateInfo())
            .fontSize(12)
            .fontColor($r('app.color.secondary_text'))
            .margin({ left: this.station.country && this.station.country.length > 0 ? 8 : 0 })
            .maxLines(1)
        }
      }
      .width('100%')
      .margin({ top: 4 })
      .alignItems(VerticalAlign.Center)
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .margin({ left: 12, right: 12 })
  }

  /**
   * 构建播放指示器
   */
  @Builder
  buildPlayingIndicator() {
    if (this.isPlaying) {
      // 显示播放中的波形动画
      this.PlayingIndicator()
    } else if (!this.station.isOnline) {
      // 显示离线状态
      Text('离线')
        .fontSize(12)
        .fontColor($r('app.color.error'))
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .borderRadius(4)
    }
  }

  /**
   * 播放指示器动画组件
   * 显示音频波形动画效果
   */
  @Builder
  PlayingIndicator() {
    Row() {
      // 模拟音频波形的三条竖线
      ForEach([1, 2, 3], (item: number) => {
        Column()
          .width(3)
          .height(this.isPlaying ? 16 + (item % 3) * 8 : 8)
          .backgroundColor($r('app.color.primary'))
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
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * 获取国家显示名称
   * 优先显示国家名称，其次国家代码
   * @returns 国家显示名称
   */
  private getCountryDisplayName(): string {
    if (this.station.country && this.station.country.length > 0) {
      return this.station.country;
    }
    if (this.station.countryCode && this.station.countryCode.length > 0) {
      return this.station.countryCode;
    }
    return '';
  }

  /**
   * 获取编解码/比特率信息
   * 格式：CODEC BITRATEk（如 "MP3 128k"）
   * @returns 编解码信息字符串
   */
  private getCodecBitrateInfo(): string {
    const parts: string[] = [];

    // 添加编解码格式
    if (this.station.codec && this.station.codec.length > 0) {
      parts.push(this.station.codec.toUpperCase());
    }

    // 添加比特率
    if (this.station.bitrate && this.station.bitrate > 0) {
      parts.push(`${this.station.bitrate}k`);
    }

    // 如果是HLS流，标注
    if (this.station.hls) {
      if (parts.length === 0) {
        parts.push('HLS');
      }
    }

    return parts.join(' ');
  }
}

/**
 * 使用示例：
 *
 * ```typescript
 * import { RadioListItem } from './components/RadioListItem';
 * import { RadioStation } from './models/RadioStation';
 *
 * @Entry
 * @Component
 * struct RadioListPage {
 *   @State stations: RadioStation[] = [];
 *   @State currentPlayingId: string = '';
 *
 *   build() {
 *     List() {
 *       ForEach(this.stations, (station: RadioStation) => {
 *         ListItem() {
 *           RadioListItem({
 *             station: station,
 *             isPlaying: this.currentPlayingId === station.id,
 *             onStationClick: () => this.playStation(station),
 *             onStationLongPress: () => this.showContextMenu(station)
 *           })
 *         }
 *       })
 *     }
 *   }
 *
 *   private playStation(station: RadioStation): void {
 *     this.currentPlayingId = station.id;
 *     // 播放逻辑...
 *   }
 *
 *   private showContextMenu(station: RadioStation): void {
 *     // 显示上下文菜单...
 *   }
 * }
 * ```
 */
