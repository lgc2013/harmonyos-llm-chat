/**
 * PlayerViewModel - 播放器视图模型
 * 负责管理播放器UI状态，连接UI层与PlayerService服务层
 * 使用@State装饰器实现响应式UI绑定
 */

import common from '@ohos.app.ability.common';

import {
  MusicTrack,
  RadioStation,
  PlayMode,
  RepeatMode,
  PlaylistItem,
  PlaylistItemType,
  PlayerState,
  PlayerError
} from '../models/index';

import {
  PlayerService,
  getPlayerService,
  PlayerEventType,
  ProgressData,
  InterruptEventData
} from '../services/index';

import { DEFAULT_VOLUME } from '../common/Constants';

/**
 * 播放器视图模型
 * 管理播放器UI所需的所有状态，提供播放控制方法
 */
export class PlayerViewModel {
  /** 当前播放的曲目（MusicTrack 或 RadioStation） */
  currentTrack: MusicTrack | RadioStation | null = null;

  /** 是否正在播放 */
  isPlaying: boolean = false;

  /** 当前播放位置（毫秒） */
  currentTime: number = 0;

  /** 当前曲目总时长（毫秒） */
  duration: number = 0;

  /** 当前音量（0.0 - 1.0） */
  volume: number = DEFAULT_VOLUME;

  /** 播放模式 */
  playMode: PlayMode = PlayMode.SEQUENCE;

  /** 是否正在加载 */
  isLoading: boolean = false;

  /** 错误信息 */
  errorMessage: string | null = null;

  /** PlayerService 实例 */
  private playerService: PlayerService | null = null;

  /** 是否已初始化 */
  private isInitialized: boolean = false;

  /** 应用上下文 */
  private context: common.UIAbilityContext | null = null;

  /** 状态变更回调 */
  private onStateChangedCallback: (() => void) | null = null;

  /**
   * 初始化视图模型
   * @param context 应用上下文
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this.isInitialized) {
      console.info('[PlayerViewModel] 已初始化，跳过');
      return;
    }

    this.context = context;
    this.isLoading = true;
    this.errorMessage = null;

    try {
      // 获取并初始化 PlayerService 单例
      this.playerService = getPlayerService();
      await this.playerService.initialize(context);

      // 注册事件监听
      this.setupEventListeners();

      // 同步初始状态
      this.syncStateFromService();

      this.isInitialized = true;
      console.info('[PlayerViewModel] 初始化完成');
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `初始化失败: ${err.message}`;
      console.error(`[PlayerViewModel] 初始化失败: ${err.message}`);
      throw new Error((error as Error).message);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 设置事件监听器
   * 监听 PlayerService 的状态变化和进度更新
   */
  private setupEventListeners(): void {
    if (this.playerService === null) {
      return;
    }

    // 监听播放状态变化
    this.playerService.on(PlayerEventType.STATE_CHANGE, (data: PlayerState | ProgressData | PlayerError | InterruptEventData | PlaylistItem | void) => {
      if (data !== null && data !== undefined) {
        const state: PlayerState = data as PlayerState;
        this.handleStateChange(state);
      }
    });

    // 监听播放进度更新
    this.playerService.on(PlayerEventType.PROGRESS, (data: PlayerState | ProgressData | PlayerError | InterruptEventData | PlaylistItem | void) => {
      if (data !== null && data !== undefined) {
        const progressData: ProgressData = data as ProgressData;
        this.handleProgressUpdate(progressData);
      }
    });

    // 监听播放错误
    this.playerService.on(PlayerEventType.ERROR, (data: PlayerState | ProgressData | PlayerError | InterruptEventData | PlaylistItem | void) => {
      if (data !== null && data !== undefined) {
        const error: PlayerError = data as PlayerError;
        this.errorMessage = error.message;
        this.isLoading = false;
      }
    });

    // 监听曲目变化
    this.playerService.on(PlayerEventType.TRACK_CHANGE, (data: PlayerState | ProgressData | PlayerError | InterruptEventData | PlaylistItem | void) => {
      if (data !== null && data !== undefined) {
        const item: PlaylistItem = data as PlaylistItem;
        this.handleTrackChange(item);
      }
    });

    console.info('[PlayerViewModel] 事件监听器设置完成');
  }

  /**
   * 处理播放状态变化
   * @param state 播放器状态
   */
  private handleStateChange(state: PlayerState): void {
    this.isPlaying = state.isPlaying;
    this.volume = state.volume;
    this.playMode = state.playMode;
    this.currentTime = state.currentTime;
    this.duration = state.duration;
    this.isLoading = state.isBuffering;

    // 清除错误信息（如果有新状态说明可能已恢复）
    if (state.error === undefined) {
      this.errorMessage = null;
    }

    console.info(`[PlayerViewModel] 状态更新: isPlaying=${state.isPlaying}, playMode=${state.playMode}`);
  }

  /**
   * 处理播放进度更新
   * @param data 进度数据
   */
  private handleProgressUpdate(data: ProgressData): void {
    this.currentTime = data.currentTime;
    if (data.duration > 0) {
      this.duration = data.duration;
    }
  }

  /**
   * 处理曲目变化
   * @param item 播放列表项
   */
  private handleTrackChange(item: PlaylistItem): void {
    // 注意：这里需要根据 PlaylistItem 的 trackId 从数据源获取完整的 MusicTrack 或 RadioStation
    // 目前简化处理，后续可扩展为从缓存或服务获取完整数据
    console.info(`[PlayerViewModel] 曲目变化: ${item.title}`);
  }

  /**
   * 从 PlayerService 同步状态
   */
  private syncStateFromService(): void {
    if (this.playerService === null) {
      return;
    }

    const state = this.playerService.getState();
    this.isPlaying = state.isPlaying;
    this.volume = state.volume;
    this.playMode = state.playMode;
    this.currentTime = state.currentTime;
    this.duration = state.duration;
    this.isLoading = state.isBuffering;

    const progress = this.playerService.getProgress();
    this.currentTime = progress.currentTime;
    this.duration = progress.duration;

    console.info('[PlayerViewModel] 状态同步完成');
  }

  /**
   * 播放指定曲目
   * @param track 音乐曲目或电台
   */
  async play(track: MusicTrack | RadioStation): Promise<void> {
    if (this.playerService === null) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    this.isLoading = true;
    this.errorMessage = null;
    this.currentTrack = track;

    try {
      // 将 MusicTrack 或 RadioStation 转换为 PlaylistItem
      const playlistItem: PlaylistItem = this.convertToPlaylistItem(track);
      await this.playerService.play(playlistItem);
      console.info(`[PlayerViewModel] 开始播放: ${this.getTrackTitle(track)}`);
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `播放失败: ${err.message}`;
      console.error(`[PlayerViewModel] 播放失败: ${err.message}`);
      throw new Error((error as Error).message);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 暂停播放
   */
  async pause(): Promise<void> {
    if (this.playerService === null) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    this.errorMessage = null;

    try {
      await this.playerService.pause();
      console.info('[PlayerViewModel] 暂停播放');
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `暂停失败: ${err.message}`;
      console.error(`[PlayerViewModel] 暂停失败: ${err.message}`);
      throw new Error((error as Error).message);
    }
  }

  /**
   * 恢复播放
   */
  async resume(): Promise<void> {
    if (this.playerService === null) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    this.isLoading = true;
    this.errorMessage = null;

    try {
      await this.playerService.play();
      console.info('[PlayerViewModel] 恢复播放');
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `恢复播放失败: ${err.message}`;
      console.error(`[PlayerViewModel] 恢复播放失败: ${err.message}`);
      throw new Error((error as Error).message);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 停止播放
   */
  async stop(): Promise<void> {
    if (this.playerService === null) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    this.errorMessage = null;

    try {
      await this.playerService.stop();
      this.currentTrack = null;
      this.currentTime = 0;
      this.duration = 0;
      console.info('[PlayerViewModel] 停止播放');
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `停止失败: ${err.message}`;
      console.error(`[PlayerViewModel] 停止失败: ${err.message}`);
      throw new Error((error as Error).message);
    }
  }

  /**
   * 播放下一首
   */
  async next(): Promise<void> {
    if (this.playerService === null) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    this.isLoading = true;
    this.errorMessage = null;

    try {
      await this.playerService.next();
      console.info('[PlayerViewModel] 播放下一首');
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `播放下一首失败: ${err.message}`;
      console.error(`[PlayerViewModel] 播放下一首失败: ${err.message}`);
      throw new Error((error as Error).message);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 播放上一首
   */
  async previous(): Promise<void> {
    if (this.playerService === null) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    this.isLoading = true;
    this.errorMessage = null;

    try {
      await this.playerService.previous();
      console.info('[PlayerViewModel] 播放上一首');
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `播放上一首失败: ${err.message}`;
      console.error(`[PlayerViewModel] 播放上一首失败: ${err.message}`);
      throw new Error((error as Error).message);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 跳转到指定位置
   * @param position 目标位置（毫秒）
   */
  async seekTo(position: number): Promise<void> {
    if (this.playerService === null) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    // 参数校验：限制在有效范围内
    const clampedPosition = Math.max(0, Math.min(position, this.duration));
    this.errorMessage = null;

    try {
      await this.playerService.seekTo(clampedPosition);
      this.currentTime = clampedPosition;
      console.info(`[PlayerViewModel] 跳转到: ${clampedPosition}ms`);
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `跳转失败: ${err.message}`;
      console.error(`[PlayerViewModel] 跳转失败: ${err.message}`);
      throw new Error((error as Error).message);
    }
  }

  /**
   * 设置音量
   * @param volume 音量值（0.0 - 1.0）
   */
  async setVolume(volume: number): Promise<void> {
    if (this.playerService === null) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    // 参数校验：限制在 0-1 范围内
    const clampedVolume = Math.max(0, Math.min(1, volume));
    this.errorMessage = null;

    try {
      await this.playerService.setVolume(clampedVolume);
      this.volume = clampedVolume;
      console.info(`[PlayerViewModel] 设置音量: ${clampedVolume}`);
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `设置音量失败: ${err.message}`;
      console.error(`[PlayerViewModel] 设置音量失败: ${err.message}`);
      throw new Error((error as Error).message);
    }
  }

  /**
   * 设置播放模式
   * @param mode 播放模式
   */
  setPlayMode(mode: PlayMode): void {
    if (this.playerService === null) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    this.errorMessage = null;

    // 异步设置播放模式，但不阻塞UI
    this.playerService.setPlayMode(mode).then(() => {
      this.playMode = mode;
      console.info(`[PlayerViewModel] 设置播放模式: ${mode}`);
    }).catch((error: Error) => {
      this.errorMessage = `设置播放模式失败: ${error.message}`;
      console.error(`[PlayerViewModel] 设置播放模式失败: ${error.message}`);
    });
  }

  /**
   * 设置循环模式
   * @param mode 循环模式
   */
  async setRepeatMode(mode: RepeatMode): Promise<void> {
    if (this.playerService === null) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    this.errorMessage = null;

    try {
      await this.playerService.setRepeatMode(mode);
      console.info(`[PlayerViewModel] 设置循环模式: ${mode}`);
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `设置循环模式失败: ${err.message}`;
      console.error(`[PlayerViewModel] 设置循环模式失败: ${err.message}`);
      throw new Error((error as Error).message);
    }
  }

  /**
   * 设置播放队列
   * @param items 播放队列项目列表
   * @param startIndex 起始索引
   */
  async setQueue(items: PlaylistItem[], startIndex: number = 0): Promise<void> {
    if (this.playerService === null) {
      this.errorMessage = '播放器未初始化';
      return;
    }

    this.isLoading = true;
    this.errorMessage = null;

    try {
      await this.playerService.setQueue(items, startIndex);
      console.info(`[PlayerViewModel] 设置播放队列: ${items.length} 首`);
    } catch (error) {
      const err = error as Error;
      this.errorMessage = `设置播放队列失败: ${err.message}`;
      console.error(`[PlayerViewModel] 设置播放队列失败: ${err.message}`);
      throw new Error((error as Error).message);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 释放资源
   * 销毁视图模型，释放 PlayerService 资源
   */
  async release(): Promise<void> {
    if (this.playerService === null) {
      return;
    }

    try {
      await this.playerService.destroy();
      this.playerService = null;
      this.isInitialized = false;
      this.currentTrack = null;
      this.isPlaying = false;
      this.currentTime = 0;
      this.duration = 0;
      this.volume = DEFAULT_VOLUME;
      this.playMode = PlayMode.SEQUENCE;
      this.isLoading = false;
      this.errorMessage = null;
      console.info('[PlayerViewModel] 资源释放完成');
    } catch (error) {
      const err = error as Error;
      console.error(`[PlayerViewModel] 资源释放失败: ${err.message}`);
      throw new Error((error as Error).message);
    }
  }

  /**
   * 获取曲目标题
   * @param track 音乐曲目或电台
   * @returns 标题
   */
  private getTrackTitle(track: MusicTrack | RadioStation): string {
    // RadioStation 有 name 属性
    if ((track as RadioStation).name !== undefined) {
      return (track as RadioStation).name;
    }
    // MusicTrack 有 title 属性
    if ((track as MusicTrack).title !== undefined) {
      return (track as MusicTrack).title;
    }
    return '未知曲目';
  }

  /**
   * 将 MusicTrack 或 RadioStation 转换为 PlaylistItem
   * @param track 音乐曲目或电台
   * @returns 播放列表项
   */
  private convertToPlaylistItem(track: MusicTrack | RadioStation): PlaylistItem {
    // 判断是 MusicTrack 还是 RadioStation
    // MusicTrack 有 filePath 属性
    if ((track as MusicTrack).filePath !== undefined) {
      // MusicTrack
      const musicTrack: MusicTrack = track as MusicTrack;
      const itemType: PlaylistItemType = PlaylistItemType.LOCAL_MUSIC;
      const item: PlaylistItem = {
        id: `item_${musicTrack.id}`,
        type: itemType,
        trackId: musicTrack.filePath, // 使用 filePath 作为播放URL
        title: musicTrack.title,
        subtitle: musicTrack.artist,
        thumbnail: musicTrack.albumArt,
        order: 0,
        addedAt: Date.now()
      };
      return item;
    } else {
      // RadioStation
      const radioStation: RadioStation = track as RadioStation;
      const radioItemType: PlaylistItemType = PlaylistItemType.RADIO_STATION;
      const radioItem: PlaylistItem = {
        id: `item_${radioStation.id}`,
        type: radioItemType,
        trackId: radioStation.url, // 电台使用 URL 作为 trackId
        title: radioStation.name,
        subtitle: radioStation.country,
        thumbnail: radioStation.favicon,
        order: 0,
        addedAt: Date.now()
      };
      return radioItem;
    }
  }

  /**
   * 获取播放进度百分比
   * @returns 进度百分比（0-100）
   */
  getProgressPercent(): number {
    if (this.duration <= 0) {
      return 0;
    }
    return (this.currentTime / this.duration) * 100;
  }

  /**
   * 格式化时间显示
   * @param milliseconds 毫秒数
   * @returns 格式化的时间字符串（mm:ss）
   */
  formatTime(milliseconds: number): string {
    const totalSeconds = Math.floor(milliseconds / 1000);
    const minutes = Math.floor(totalSeconds / 60);
    const seconds = totalSeconds % 60;
    return `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;
  }

  /**
   * 获取当前时间显示
   * @returns 格式化的当前时间
   */
  getCurrentTimeDisplay(): string {
    return this.formatTime(this.currentTime);
  }

  /**
   * 获取总时长显示
   * @returns 格式化的总时长
   */
  getDurationDisplay(): string {
    return this.formatTime(this.duration);
  }

  /**
   * 切换播放/暂停
   */
  async togglePlayPause(): Promise<void> {
    if (this.isPlaying) {
      await this.pause();
    } else {
      await this.resume();
    }
  }

  /**
   * 切换播放模式
   * 在顺序、随机、单曲模式之间循环切换
   */
  cyclePlayMode(): void {
    const modes: PlayMode[] = [PlayMode.SEQUENCE, PlayMode.SHUFFLE, PlayMode.SINGLE];
    const currentIndex = modes.indexOf(this.playMode);
    const nextIndex = (currentIndex + 1) % modes.length;
    this.setPlayMode(modes[nextIndex]);
  }

  /**
   * 清除错误信息
   */
  clearError(): void {
    this.errorMessage = null;
  }
}

/**
 * 创建 PlayerViewModel 实例的工厂函数
 * @returns PlayerViewModel 实例
 */
export function createPlayerViewModel(): PlayerViewModel {
  return new PlayerViewModel();
}
