/**
 * PlaylistDetailPage - 播放列表详情页面
 * 显示播放列表中的所有曲目
 * 遵循华为 UX 体验标准
 */

import common from '@ohos.app.ability.common';
import router from '@ohos.router';
import { PlaylistViewModel } from '../viewmodels/PlaylistViewModel';
import { TrackListItem } from '../components/TrackListItem';
import { EmptyState } from '../components/EmptyState';
import { Playlist, PlaylistItem as PlaylistItemType } from '../models/Playlist';
import { MusicTrack } from '../models/MusicTrack';

/**
 * 播放列表详情页面参数
 */
interface PlaylistDetailParams {
  playlistId: string;
}

/**
 * 播放列表详情页面组件
 */
@Entry
@Component
export struct PlaylistDetailPage {
  /** 应用上下文 */
  private context: common.UIAbilityContext | null = null;

  /** 视图模型 */
  private viewModel: PlaylistViewModel = new PlaylistViewModel();

  /** 播放列表ID */
  @State private playlistId: string = '';

  /** 播放列表信息 */
  @State private playlist: Playlist | null = null;

  /** 曲目列表 */
  @State private tracks: MusicTrack[] = [];

  /** 是否正在加载 */
  @State private isLoading: boolean = false;

  /** 错误信息 */
  @State private errorMessage: string | null = null;

  /**
   * 页面即将显示
   */
  aboutToAppear(): void {
    // 获取路由参数
    const params = router.getParams() as PlaylistDetailParams;
    if (params && params.playlistId) {
      this.playlistId = params.playlistId;
      this.loadPlaylistDetail();
    }
  }

  /**
   * 加载播放列表详情
   */
  private async loadPlaylistDetail(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = null;

    try {
      const playlistData = await this.viewModel.getPlaylistById(this.playlistId);
      this.playlist = playlistData !== undefined ? playlistData : null;
      // 注意：PlaylistItem 不包含完整的 track 信息
      // 实际应用中需要根据 trackId 从数据源加载完整的 MusicTrack
      // 这里暂时留空，后续可以添加加载逻辑
      this.tracks = [];
    } catch (error) {
      this.errorMessage = '加载播放列表失败';
      console.error('Failed to load playlist detail:', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 播放全部
   */
  private playAll(): void {
    if (this.tracks.length === 0) return;
    // TODO: 调用播放服务播放全部曲目
    console.info('Play all tracks');
  }

  /**
   * 随机播放
   */
  private shufflePlay(): void {
    if (this.tracks.length === 0) return;
    // TODO: 调用播放服务随机播放
    console.info('Shuffle play');
  }

  /**
   * 播放指定曲目
   */
  private playTrack(track: MusicTrack): void {
    // TODO: 调用播放服务播放指定曲目
    console.info('Play track:', track.title);
  }

  /**
   * 从播放列表移除曲目
   */
  private async removeTrack(itemId: string): Promise<void> {
    try {
      await this.viewModel.removeFromPlaylist(this.playlistId, itemId);
      await this.loadPlaylistDetail();
    } catch (error) {
      console.error('Failed to remove track:', error);
    }
  }

  /**
   * 返回上一页
   */
  private goBack(): void {
    router.back();
  }

  /**
   * 格式化时长
   */
  private formatDuration(ms: number): string {
    const totalSeconds = Math.floor(ms / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes}:${seconds.toString().padStart(2, '0')}`;
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        Button() {
          Text('<')
            .fontSize(20)
            .fontColor('#333333')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
        .onClick(() => this.goBack())

        Text(this.playlist?.name || '播放列表')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        // 更多选项
        Button() {
          Text('⋯')
            .fontSize(20)
            .fontColor('#333333')
        }
        .width(40)
        .height(40)
        .backgroundColor(Color.Transparent)
      }
      .width('100%')
      .padding({ left: 8, right: 8 })

      // 播放列表信息
      if (this.playlist) {
        Row() {
          Text(`${this.playlist.totalCount} 首`)
            .fontSize(14)
            .fontColor('#999999')

          Blank()

          Text(`总时长 ${this.formatDuration(this.playlist.totalDuration)}`)
            .fontSize(14)
            .fontColor('#999999')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      }

      // 播放控制按钮
      Row() {
        Button('播放全部')
          .fontSize(14)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .borderRadius(20)
          .onClick(() => this.playAll())

        Blank().width(16)

        Button('随机播放')
          .fontSize(14)
          .fontColor('#007DFF')
          .backgroundColor('#E6F2FF')
          .borderRadius(20)
          .onClick(() => this.shufflePlay())
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 16 })

      // 曲目列表
      if (this.isLoading) {
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
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage) {
        EmptyState({
          title: '加载失败',
          description: this.errorMessage,
          actionText: '重试',
          onActionCallback: () => this.loadPlaylistDetail()
        })
      } else if (this.tracks.length === 0) {
        EmptyState({
          title: '播放列表为空',
          description: '从音乐库添加歌曲到播放列表'
        })
      } else {
        List() {
          ForEach(this.tracks, (track: MusicTrack, index: number) => {
            ListItem() {
              TrackListItem({
                track: track,
                index: index + 1,
                isPlaying: false,
                onTrackClick: () => this.playTrack(track),
                onTrackLongPress: () => {
                  // TODO: 显示上下文菜单
                }
              })
            }
          }, (track: MusicTrack) => track.id)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
        .divider({ strokeWidth: 1, color: '#F0F0F0' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
