/**
 * PlaylistPage - 播放列表管理页面
 * 显示所有播放列表，支持创建、编辑、删除操作
 * 遵循华为 UX 体验标准
 */

import common from '@ohos.app.ability.common';
import { PlaylistViewModel } from '../viewmodels/PlaylistViewModel';
import { PlaylistItem } from '../components/PlaylistItem';
import { EmptyState } from '../components/EmptyState';
import { CreatePlaylistDialog } from '../components/CreatePlaylistDialog';
import { Playlist } from '../models/Playlist';

/**
 * 播放列表页面组件
 */
@Entry
@Component
export struct PlaylistPage {
  /** 应用上下文 */
  private context: common.UIAbilityContext | null = null;

  /** 视图模型 */
  private viewModel: PlaylistViewModel = new PlaylistViewModel();

  /** 播放列表数据 */
  @State private playlists: Playlist[] = [];

  /** 是否正在加载 */
  @State private isLoading: boolean = false;

  /** 错误信息 */
  @State private errorMessage: string | null = null;

  /** 是否显示创建对话框 */
  @State private showCreateDialog: boolean = false;

  /** 创建对话框控制器 */
  private createDialogController: CustomDialogController | null = null;

  /**
   * 页面即将显示
   */
  aboutToAppear(): void {
    this.loadPlaylists();
  }

  /**
   * 页面即将消失
   */
  aboutToDisappear(): void {
    // 清理资源
  }

  /**
   * 加载播放列表
   */
  private async loadPlaylists(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = null;

    try {
      await this.viewModel.loadPlaylists();
      this.playlists = this.viewModel.playlists;
    } catch (error) {
      this.errorMessage = '加载播放列表失败';
      console.error('Failed to load playlists:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 显示创建对话框
   */
  private showCreatePlaylistDialog(): void {
    this.createDialogController = new CustomDialogController({
      builder: CreatePlaylistDialog({
        onConfirm: (name: string) => this.createPlaylist(name),
        onCancel: () => {}
      }),
      autoCancel: true,
      alignment: DialogAlignment.Center
    });
    this.createDialogController.open();
  }

  /**
   * 创建播放列表
   */
  private async createPlaylist(name: string): Promise<void> {
    try {
      await this.viewModel.createPlaylist(name);
      await this.loadPlaylists();
    } catch (error) {
      console.error('Failed to create playlist:', error);
    }
  }

  /**
   * 删除播放列表
   */
  private async deletePlaylist(playlistId: string): Promise<void> {
    try {
      await this.viewModel.deletePlaylist(playlistId);
      await this.loadPlaylists();
    } catch (error) {
      console.error('Failed to delete playlist:', error);
    }
  }

  /**
   * 导航到播放列表详情
   */
  private navigateToDetail(playlistId: string): void {
    // TODO: 使用路由导航到 PlaylistDetailPage
    console.info('Navigate to playlist:', playlistId);
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Text('播放列表')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)

        Blank()

        // 创建按钮
        Button() {
          Text('+')
            .fontSize(24)
            .fontColor('#007DFF')
        }
        .width(40)
        .height(40)
        .backgroundColor('#F5F5F5')
        .borderRadius(20)
        .onClick(() => this.showCreatePlaylistDialog())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 12, bottom: 12 })

      // 内容区域
      if (this.isLoading) {
        // 加载状态
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 12 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage) {
        // 错误状态
        EmptyState({
          title: '加载失败',
          description: this.errorMessage,
          actionText: '重试',
          onActionCallback: () => this.loadPlaylists()
        })
      } else if (this.playlists.length === 0) {
        // 空状态
        EmptyState({
          title: '暂无播放列表',
          description: '点击右上角 + 创建你的第一个播放列表',
          actionText: '创建播放列表',
          onActionCallback: () => this.showCreatePlaylistDialog()
        })
      } else {
        // 播放列表
        List() {
          ForEach(this.playlists, (playlist: Playlist) => {
            ListItem() {
              PlaylistItem({
                playlist: playlist,
                onPlaylistClick: () => this.navigateToDetail(playlist.id),
                onPlaylistDelete: () => this.deletePlaylist(playlist.id)
              })
            }
          }, (playlist: Playlist) => playlist.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .divider({ strokeWidth: 1, color: '#F0F0F0', startMargin: 48, endMargin: 0 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
