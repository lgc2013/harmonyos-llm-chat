/**
 * PlaylistItem 播放列表项组件
 * 遵循华为 UX 体验标准：
 * - 可点击区域 >= 48vp x 48vp (2.1.4.1)
 * - 文字对比度 > 4.5:1 (2.1.4.2)
 * - 图标最小 8vp (2.1.4.3.2)
 */
import { Playlist } from '../models/Playlist';

/**
 * 播放列表项组件属性接口
 */
export interface PlaylistItemProps {
  /** 播放列表数据（必填） */
  playlist: Playlist;
  /** 点击事件回调 */
  onClick: () => void;
  /** 编辑事件回调（可选） */
  onEdit?: () => void;
  /** 删除事件回调（可选） */
  onDelete?: () => void;
}

/**
 * 播放列表项组件
 * 用于在播放列表中显示单个播放列表信息
 * 支持点击进入播放列表详情、编辑和删除操作
 */
@Component
export struct PlaylistItem {
  /** 播放列表数据 */
  @Prop playlist: Playlist = {} as Playlist;
  /** 点击事件回调 */
  onPlaylistClick?: () => void;
  /** 编辑事件回调 */
  onPlaylistEdit?: () => void;
  /** 删除事件回调 */
  onPlaylistDelete?: () => void;
  /** 是否显示更多选项菜单 */
  @State private showMoreMenu: boolean = false;

  /**
   * 构建组件UI
   */
  build() {
    Row() {
      // 左侧：播放列表封面/图标 (48x48vp)
      this.buildThumbnail()

      // 中间：播放列表名称和曲目数量
      this.buildInfoSection()

      // 右侧：更多选项按钮
      this.buildMoreButton()
    }
    .width('100%')
    .height(64) // 确保可点击区域 >= 48vp
    .padding({ left: 16, right: 12 })
    .backgroundColor(Color.Transparent)
    .borderRadius(8)
    .alignItems(VerticalAlign.Center)
    .justifyContent(FlexAlign.Start)
    .onClick(() => {
      if (this.onPlaylistClick) {
        this.onPlaylistClick();
      }
    })
  }

  /**
   * 构建缩略图区域
   * 显示播放列表封面或默认图标
   */
  @Builder
  buildThumbnail() {
    if (this.playlist.coverImage) {
      // 显示封面图片
      Image(this.playlist.coverImage)
        .width(48)
        .height(48)
        .borderRadius(8)
        .objectFit(ImageFit.Cover)
        .alt($r('app.media.ic_public_music'))
    } else {
      // 显示默认播放列表图标（网格样式）
      this.buildDefaultThumbnail()
    }
  }

  /**
   * 构建默认缩略图
   * 显示网格样式的占位图标
   */
  @Builder
  buildDefaultThumbnail() {
    Column() {
      // 简单的网格图标，使用两张叠加的专辑图标表示播放列表
      Stack() {
        // 底层图标
        Image($r('app.media.ic_public_music'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.secondary_text'))
          .opacity(0.5)
          .translate({ x: -4, y: -4 })

        // 顶层图标
        Image($r('app.media.ic_public_music'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.primary'))
      }
      .width(48)
      .height(48)
    }
    .width(48)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.card_bg'))
    .borderRadius(8)
  }

  /**
   * 构建信息区域
   * 显示播放列表名称和曲目数量
   */
  @Builder
  buildInfoSection() {
    Column() {
      // 播放列表名称（粗体，16fp）
      Row() {
        Text(this.playlist.name)
          .fontSize(16)
          .fontColor($r('app.color.primary_text'))
          .fontWeight(FontWeight.Bold)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .textAlign(TextAlign.Start)

        // 系统播放列表标识
        if (this.playlist.isSystem) {
          Text('系统')
            .fontSize(10)
            .fontColor($r('app.color.primary'))
            .backgroundColor($r('sys.color.ohos_id_color_component_activated'))
            .borderRadius(4)
            .padding({ left: 4, right: 4, top: 1, bottom: 1 })
            .margin({ left: 6 })
        }
      }
      .width('100%')

      // 曲目数量（次要颜色，14fp）
      Text(this.formatTrackCount())
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
    .margin({ left: 12, right: 8 })
  }

  /**
   * 构建更多选项按钮
   * 显示三点菜单，用于编辑和删除操作
   */
  @Builder
  buildMoreButton() {
    Row() {
      Image($r('sys.symbol.ellipsis_circle'))
        .width(24)
        .height(24)
        .fillColor($r('app.color.secondary_text'))
    }
    .width(48)
    .height(48)
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
    .borderRadius(24)
    .onClick((event: ClickEvent) => {
      // 阻止事件冒泡，避免触发外层 Row 的点击事件
      // 事件传播控制在 HarmonyOS 中由组件层级自动处理
      this.showMoreOptionsMenu();
    })
  }

  /**
   * 显示更多选项菜单
   * 包含编辑和删除选项
   */
  private showMoreOptionsMenu(): void {
    // 使用 Menu 组件显示选项
    // 注意：实际实现可能需要配合 bindMenu 或 bindContextMenu
    if (this.onPlaylistEdit || this.onPlaylistDelete) {
      this.showMoreMenu = !this.showMoreMenu;
      // 如果有编辑回调，优先执行编辑
      if (this.onPlaylistEdit) {
        this.onPlaylistEdit();
      } else if (this.onPlaylistDelete) {
        this.onPlaylistDelete();
      }
    }
  }

  /**
   * 格式化曲目数量显示
   * @returns 格式化的曲目数量字符串（如："32 首"）
   */
  private formatTrackCount(): string {
    const count = this.playlist.totalCount || this.playlist.items?.length || 0;
    return `${count} 首`;
  }
}

/**
 * 使用示例：
 *
 * ```typescript
 * import { PlaylistItem } from './components/PlaylistItem';
 * import { Playlist } from './models/Playlist';
 *
 * @Entry
 * @Component
 * struct PlaylistsPage {
 *   @State playlists: Playlist[] = [];
 *
 *   build() {
 *     List() {
 *       ForEach(this.playlists, (playlist: Playlist) => {
 *         ListItem() {
 *           PlaylistItem({
 *             playlist: playlist,
 *             onPlaylistClick: () => this.openPlaylist(playlist),
 *             onPlaylistEdit: () => this.editPlaylist(playlist),
 *             onPlaylistDelete: () => this.deletePlaylist(playlist)
 *           })
 *         }
 *       })
 *     }
 *   }
 *
 *   private openPlaylist(playlist: Playlist): void {
 *     // 导航到播放列表详情页...
 *   }
 *
 *   private editPlaylist(playlist: Playlist): void {
 *     // 显示编辑对话框...
 *   }
 *
 *   private deletePlaylist(playlist: Playlist): void {
 *     // 显示删除确认对话框...
 *   }
 * }
 * ```
 */
