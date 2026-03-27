/**
 * AddToPlaylistDialog - 添加到播放列表对话框
 * 允许用户选择播放列表来添加歌曲
 * 遵循华为 UX 体验标准
 */

import { Playlist } from '../models/Playlist';

/**
 * 添加到播放列表对话框组件
 */
@CustomDialog
export struct AddToPlaylistDialog {
  /** 对话框控制器 */
  controller: CustomDialogController;

  /** 可用的播放列表 */
  @Prop playlists: Playlist[] = [];

  /** 确认回调 */
  onConfirm: (playlistId: string) => void = () => {};
  
  /** 创建新播放列表回调 */
  onCreateNew: () => void = () => {};
  
  /** 取消回调 */
  onCancel: () => void = () => {};

  /** 当前选中的播放列表ID */
  @State private selectedId: string = '';

  /**
   * 处理选择播放列表
   */
  private handleSelect(playlistId: string): void {
    this.selectedId = playlistId;
    this.controller.close();
    this.onConfirm(playlistId);
  }

  /**
   * 处理创建新播放列表
   */
  private handleCreateNew(): void {
    this.controller.close();
    this.onCreateNew();
  }

  /**
   * 处理取消
   */
  private handleCancel(): void {
    this.controller.close();
    this.onCancel();
  }

  build() {
    Column() {
      // 标题
      Text('添加到播放列表')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 16 })

      // 新建选项
      Row() {
        Text('+')
          .fontSize(24)
          .fontColor('#007DFF')
          .margin({ right: 12 })

        Text('新建播放列表')
          .fontSize(16)
          .fontColor('#007DFF')
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#F5F5F5')
      .borderRadius(8)
      .onClick(() => this.handleCreateNew())
      .margin({ bottom: 16 })

      // 播放列表列表
      if (this.playlists.length > 0) {
        List() {
          ForEach(this.playlists, (playlist: Playlist) => {
            ListItem() {
              Row() {
                // 播放列表图标
                Text('🎵')
                  .fontSize(24)
                  .margin({ right: 12 })

                // 播放列表信息
                Column() {
                  Text(playlist.name)
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)

                  Text(`${playlist.totalCount} 首`)
                    .fontSize(12)
                    .fontColor('#999999')
                    .margin({ top: 4 })
                }
                .alignItems(HorizontalAlign.Start)
                .layoutWeight(1)

                // 箭头
                Text('>')
                  .fontSize(16)
                  .fontColor('#CCCCCC')
              }
              .width('100%')
              .padding({ top: 12, bottom: 12 })
              .onClick(() => this.handleSelect(playlist.id))
            }
          }, (playlist: Playlist) => playlist.id)
        }
        .width('100%')
        .height(Math.min(this.playlists.length * 60, 300))
        .divider({ strokeWidth: 1, color: '#F0F0F0' })
      } else {
        // 空状态
        Column() {
          Text('暂无播放列表')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 20, bottom: 20 })
        }
        .width('100%')
      }

      // 取消按钮
      Button('取消')
        .fontSize(16)
        .fontColor('#666666')
        .backgroundColor('#F5F5F5')
        .width('100%')
        .margin({ top: 16 })
        .onClick(() => this.handleCancel())
    }
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
    .width('80%')
  }
}
