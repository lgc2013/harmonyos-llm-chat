/**
 * TrackListItem 曲目列表项组件
 * 遵循华为 UX 体验标准：
 * - 可点击区域 >= 48vp x 48vp (2.1.4.1)
 * - 文字对比度 > 4.5:1 (2.1.4.2)
 * - 图标最小 8vp (2.1.4.3.2)
 */
import { MusicTrack } from '../models/MusicTrack';
import { formatTime } from '../common/Utils';

/**
 * 曲目列表项组件属性接口
 */
export interface TrackListItemProps {
  /** 音乐曲目数据（必填） */
  track: MusicTrack;
  /** 是否正在播放（默认 false） */
  isPlaying?: boolean;
  /** 曲目索引编号（可选，用于显示序号） */
  index?: number;
  /** 点击事件回调 */
  onClick?: () => void;
  /** 长按事件回调（可选，用于上下文菜单） */
  onLongPress?: () => void;
}

/**
 * 曲目列表项组件
 * 用于在音乐列表中显示单个曲目信息
 * 支持点击播放和长按显示上下文菜单
 */
@Component
export struct TrackListItem {
  /** 音乐曲目数据 */
  @Prop track: MusicTrack = {} as MusicTrack;
  /** 是否正在播放 */
  @Prop isPlaying: boolean = false;
  /** 曲目索引编号 */
  @Prop index: number = -1;
  /** 点击事件回调 */
  onTrackClick?: () => void;
  /** 长按事件回调 */
  onTrackLongPress?: () => void;

  /**
   * 构建组件UI
   */
  build() {
    Row() {
      // 左侧：曲目编号或专辑封面缩略图 (48x48vp)
      this.buildLeftSection()

      // 中间：标题和艺术家信息
      this.buildCenterSection()

      // 右侧：时长和播放指示器
      this.buildRightSection()
    }
    .width('100%')
    .height(64) // 确保可点击区域 >= 48vp
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.isPlaying ? $r('app.color.card_bg') : Color.Transparent)
    .borderRadius(8)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Start)
    .gesture(
      GestureGroup(GestureMode.Exclusive,
        // 点击手势
        TapGesture()
          .onAction(() => {
            if (this.onTrackClick) {
              this.onTrackClick();
            }
          }),
        // 长按手势
        LongPressGesture({ repeat: false })
          .onAction(() => {
            if (this.onTrackLongPress) {
              this.onTrackLongPress();
            }
          })
      )
    )
    .onClick(() => {
      if (this.onTrackClick) {
        this.onTrackClick();
      }
    })
  }

  /**
   * 构建左侧区域：曲目编号或专辑封面
   */
  @Builder
  buildLeftSection() {
    if (this.index >= 0 && !this.isPlaying) {
      // 显示曲目编号
      Row() {
        Text(`${this.index + 1}`)
          .fontSize(16)
          .fontColor($r('app.color.secondary_text'))
          .textAlign(TextAlign.Center)
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    } else if (this.isPlaying) {
      // 显示播放指示器动画
      Row() {
        this.PlayingIndicator()
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
    } else if (this.track.albumArt) {
      // 显示专辑封面缩略图
      Image(this.track.albumArt)
        .width(48)
        .height(48)
        .borderRadius(4)
        .objectFit(ImageFit.Cover)
        .alt($r('app.media.ic_public_music')) // 加载失败时显示默认图标
    } else {
      // 显示默认音乐图标
      Row() {
        Image($r('app.media.ic_public_music'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.secondary_text'))
      }
      .width(48)
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .backgroundColor($r('app.color.card_bg'))
      .borderRadius(4)
    }
  }

  /**
   * 构建中间区域：标题和艺术家
   */
  @Builder
  buildCenterSection() {
    Column() {
      // 曲目标题（粗体，16fp）
      Text(this.track.title)
        .fontSize(16)
        .fontColor($r('app.color.primary_text'))
        .fontWeight(FontWeight.Bold)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Start)

      // 艺术家名称（次要颜色，14fp）
      Text(this.track.artist || '未知艺术家')
        .fontSize(14)
        .fontColor($r('app.color.secondary_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .textAlign(TextAlign.Start)
        .margin({ top: 2 })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .margin({ left: 12, right: 12 })
  }

  /**
   * 构建右侧区域：时长和播放指示
   */
  @Builder
  buildRightSection() {
    Row() {
      // 时长（14fp）
      Text(this.formatDuration(this.track.duration))
        .fontSize(14)
        .fontColor($r('app.color.secondary_text'))
        .textAlign(TextAlign.End)

      // 如果正在播放，显示小扬声器图标
      if (this.isPlaying) {
        Image($r('sys.symbol.waveform'))
          .width(16)
          .height(16)
          .fillColor($r('app.color.primary'))
          .margin({ left: 8 })
      }
    }
    .alignItems(VerticalAlign.Center)
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
   * 格式化时长为 mm:ss 格式
   * @param durationMs 时长（毫秒）
   * @returns 格式化的时间字符串
   */
  private formatDuration(durationMs: number): string {
    // 使用 Utils 中的 formatTime 函数
    return formatTime(durationMs);
  }
}

/**
 * 使用示例：
 *
 * ```typescript
 * import { TrackListItem } from './components/TrackListItem';
 * import { MusicTrack } from './models/MusicTrack';
 *
 * @Entry
 * @Component
 * struct PlayListPage {
 *   @State tracks: MusicTrack[] = [];
 *   @State currentPlayingId: string = '';
 *
 *   build() {
 *     List() {
 *       ForEach(this.tracks, (track: MusicTrack, index: number) => {
 *         ListItem() {
 *           TrackListItem({
 *             track: track,
 *             isPlaying: this.currentPlayingId === track.id,
 *             index: index,
 *             onTrackClick: () => this.playTrack(track),
 *             onTrackLongPress: () => this.showContextMenu(track)
 *           })
 *         }
 *       })
 *     }
 *   }
 *
 *   private playTrack(track: MusicTrack): void {
 *     this.currentPlayingId = track.id;
 *     // 播放逻辑...
 *   }
 *
 *   private showContextMenu(track: MusicTrack): void {
 *     // 显示上下文菜单...
 *   }
 * }
 * ```
 */
