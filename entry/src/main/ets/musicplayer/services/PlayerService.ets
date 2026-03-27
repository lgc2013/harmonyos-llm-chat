/**
 * PlayerService - 音乐播放器核心播放服务
 * 负责音频播放控制、AVSession管理、后台播放、音频打断处理
 */

import media from '@ohos.multimedia.media';
import avSession from '@ohos.multimedia.avsession';
import backgroundTaskManager from '@ohos.resourceschedule.backgroundTaskManager';
import audio from '@ohos.multimedia.audio';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';

import {
  PlaylistItem,
  PlaylistItemType,
  PlayMode,
  RepeatMode,
  QueueSource,
  PlayerState,
  PlayerError
} from '../models/index';

import {
  PlayerErrorCode,
  getErrorMessage
} from '../common/ErrorCodes';

import {
  DEFAULT_VOLUME,
  PLAYBACK_RESPONSE_TIMEOUT_MS
} from '../common/Constants';

import audioUrlResolver, { ResolvedUrl } from './AudioUrlResolver';

/**
 * 播放进度数据
 */
export interface ProgressData {
  /** 当前播放位置（毫秒） */
  currentTime: number;
  /** 总时长（毫秒） */
  duration: number;
  /** 缓冲进度（0-1） */
  buffered: number;
}

/**
 * 音频打断事件数据
 */
export interface InterruptEventData {
  /** 打断类型 */
  type: InterruptType;
  /** 打断提示 */
  hint: string;
}

/**
 * 中断类型枚举
 */
export enum InterruptType {
  /** 中断开始 */
  BEGIN = 'BEGIN',
  /** 中断结束 */
  END = 'END'
}

/**
 * 播放器事件类型
 */
export enum PlayerEventType {
  /** 播放状态变化 */
  STATE_CHANGE = 'stateChange',
  /** 播放进度更新 */
  PROGRESS = 'progress',
  /** 播放错误 */
  ERROR = 'error',
  /** 音频打断 */
  INTERRUPT = 'interrupt',
  /** 队列播放完毕 */
  QUEUE_END = 'queueEnd',
  /** 曲目变化 */
  TRACK_CHANGE = 'trackChange'
}

/**
 * 播放器事件回调类型 - 使用通用类型
 */
export type PlayerEventCallback = (data: PlayerState | ProgressData | PlayerError | InterruptEventData | PlaylistItem | void) => void;

/**
 * 播放器状态变化回调类型
 */
export type PlayerStateCallback = (state: PlayerState) => void;

/**
 * 播放进度回调类型
 */
export type ProgressCallback = (data: ProgressData) => void;

/**
 * 曲目变化回调类型
 */
export type TrackChangeCallback = (item: PlaylistItem) => void;

/**
 * AVPlayer 状态枚举
 * 与 HarmonyOS AVPlayer 状态机对应
 */
enum AVPlayerState {
  /** 空闲状态 */
  IDLE = 'idle',
  /** 初始化完成 */
  INITIALIZED = 'initialized',
  /** 准备完成 */
  PREPARED = 'prepared',
  /** 播放中 */
  PLAYING = 'playing',
  /** 暂停 */
  PAUSED = 'paused',
  /** 停止 */
  STOPPED = 'stopped',
  /** 完成播放 */
  COMPLETED = 'completed',
  /** 释放资源 */
  RELEASED = 'released',
  /** 错误状态 */
  ERROR = 'error'
}

/**
 * 状态等待解析器接口
 */
interface StateResolver {
  resolve: () => void;
  reject: (error: Error) => void;
  timerId: number;
}

/**
 * PlayerService 播放服务类
 * 实现完整的音频播放控制功能
 */
export class PlayerService {
  /** AVPlayer 实例 */
  private avPlayer: media.AVPlayer | null = null;

  /** AVSession 实例 */
  private avSession: avSession.AVSession | null = null;

  /** 应用上下文 */
  private context: common.UIAbilityContext | null = null;

  /** 播放状态 */
  private state: PlayerState;

  /** 状态等待解析器映射 */
  private stateResolvers: Map<string, StateResolver> = new Map();

  /** 事件监听器映射 */
  private eventListeners: Map<PlayerEventType, Set<PlayerEventCallback>> = new Map();

  /** 进度更新定时器 */
  private progressTimer: number = -1;

  /** 长时任务是否已申请 */
  private isBackgroundTaskRequested: boolean = false;

  /** 打断前是否在播放 */
  private wasPlayingBeforeInterrupt: boolean = false;

  /** 是否已初始化 */
  private isInitialized: boolean = false;

  /** 随机播放索引映射 */
  private shuffleIndices: number[] = [];

  /** 当前随机索引位置 */
  private currentShufflePosition: number = 0;

  /**
   * 构造函数
   */
  constructor() {
    // 初始化默认播放状态
    this.state = this.createDefaultState();
  }

  /**
   * 创建默认播放状态
   * @returns 默认的PlayerState对象
   */
  private createDefaultState(): PlayerState {
    return {
      currentTrack: null,
      currentIndex: -1,
      isPlaying: false,
      isBuffering: false,
      currentTime: 0,
      duration: 0,
      volume: DEFAULT_VOLUME,
      playMode: PlayMode.SEQUENCE,
      shuffle: false,
      repeat: RepeatMode.OFF,
      queue: [],
      queueSource: QueueSource.LOCAL_LIBRARY,
      error: undefined
    };
  }

  /**
   * 初始化播放服务
   * @param context 应用上下文
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this.isInitialized) {
      console.info('[PlayerService] 已初始化，跳过');
      return;
    }

    this.context = context;

    try {
      // 1. 创建 AVPlayer
      await this.createAVPlayer();

      // 2. 创建并激活 AVSession
      await this.createAVSession();

      // 3. 申请长时任务
      await this.requestBackgroundTask();

      this.isInitialized = true;
      console.info('[PlayerService] 初始化完成');
    } catch (error) {
      const err = error as Error;
      console.error(`[PlayerService] 初始化失败: ${err.message}`);
      throw new Error(`初始化失败: ${err.message}`);
    }
  }

  /**
   * 创建 AVPlayer 实例
   */
  private async createAVPlayer(): Promise<void> {
    if (this.avPlayer !== null) {
      return;
    }

    this.avPlayer = await media.createAVPlayer();

    // 设置状态变化回调
    this.avPlayer.on('stateChange', (state: string) => {
      this.handleAVPlayerStateChange(state as AVPlayerState);
    });

    // 设置错误回调
    this.avPlayer.on('error', (error: Error) => {
      this.handleAVPlayerError(error);
    });

    // 设置音频打断回调
    this.avPlayer.on('audioInterrupt', (interruptEvent: audio.InterruptEvent) => {
      this.handleAudioInterrupt(interruptEvent);
    });

    console.info('[PlayerService] AVPlayer 创建成功');
  }

  /**
   * 创建并激活 AVSession
   */
  private async createAVSession(): Promise<void> {
    if (this.avSession !== null) {
      return;
    }

    if (this.context === null) {
      throw new Error('上下文未初始化');
    }

    // 创建 AVSession
    const sessionId = `music_player_${Date.now()}`;
    this.avSession = await avSession.createAVSession(this.context, sessionId, 'audio');

    // 设置会话元数据
    const metadata: avSession.AVMetadata = {
      assetId: '0',
      title: '音乐播放器'
    };
    await this.avSession.setAVMetadata(metadata);

    // 设置播放控制命令监听
    this.setupAVSessionCommands();

    // 激活会话
    await this.avSession.activate();

    console.info('[PlayerService] AVSession 创建并激活成功');
  }

  /**
   * 设置 AVSession 播放控制命令监听
   */
  private setupAVSessionCommands(): void {
    if (this.avSession === null) {
      return;
    }

    // 播放命令
    this.avSession.on('play', () => {
      console.info('[PlayerService] AVSession play 命令');
      this.play().catch((err: Error) => {
        console.error(`[PlayerService] play 命令执行失败: ${err.message}`);
      });
    });

    // 暂停命令
    this.avSession.on('pause', () => {
      console.info('[PlayerService] AVSession pause 命令');
      this.pause().catch((err: Error) => {
        console.error(`[PlayerService] pause 命令执行失败: ${err.message}`);
      });
    });

    // 停止命令
    this.avSession.on('stop', () => {
      console.info('[PlayerService] AVSession stop 命令');
      this.stop().catch((err: Error) => {
        console.error(`[PlayerService] stop 命令执行失败: ${err.message}`);
      });
    });

    // 下一首命令
    this.avSession.on('playNext', () => {
      console.info('[PlayerService] AVSession playNext 命令');
      this.next().catch((err: Error) => {
        console.error(`[PlayerService] playNext 命令执行失败: ${err.message}`);
      });
    });

    // 上一首命令
    this.avSession.on('playPrevious', () => {
      console.info('[PlayerService] AVSession playPrevious 命令');
      this.previous().catch((err: Error) => {
        console.error(`[PlayerService] playPrevious 命令执行失败: ${err.message}`);
      });
    });

    // 快进命令
    this.avSession.on('fastForward', () => {
      console.info('[PlayerService] AVSession fastForward 命令');
      if (this.state.currentTrack !== null) {
        const newPosition = Math.min(this.state.currentTime + 10000, this.state.duration);
        this.seekTo(newPosition).catch((err: Error) => {
          console.error(`[PlayerService] fastForward 命令执行失败: ${err.message}`);
        });
      }
    });

    // 快退命令
    this.avSession.on('rewind', () => {
      console.info('[PlayerService] AVSession rewind 命令');
      if (this.state.currentTrack !== null) {
        const newPosition = Math.max(this.state.currentTime - 10000, 0);
        this.seekTo(newPosition).catch((err: Error) => {
          console.error(`[PlayerService] rewind 命令执行失败: ${err.message}`);
        });
      }
    });

    // 跳转命令
    this.avSession.on('seek', (time: number) => {
      console.info(`[PlayerService] AVSession seek 命令: ${time}ms`);
      this.seekTo(time).catch((err: Error) => {
        console.error(`[PlayerService] seek 命令执行失败: ${err.message}`);
      });
    });

    // 设置播放速度命令
    this.avSession.on('setSpeed', (speed: number) => {
      console.info(`[PlayerService] AVSession setSpeed 命令: ${speed}`);
      if (this.avPlayer !== null) {
        try {
          this.avPlayer.setSpeed(speed);
        } catch (err) {
          const error: Error = err as Error;
          console.error(`[PlayerService] setSpeed 命令执行失败: ${error.message}`);
        }
      }
    });

    // 设置循环模式命令
    this.avSession.on('setLoopMode', (mode: avSession.LoopMode) => {
      console.info(`[PlayerService] AVSession setLoopMode 命令: ${mode}`);
      const repeatMode = this.convertLoopModeToRepeatMode(mode);
      this.setPlayMode(this.state.playMode).catch((err: Error) => {
        console.error(`[PlayerService] setLoopMode 命令执行失败: ${err.message}`);
      });
      this.state.repeat = repeatMode;
      this.notifyStateChange();
    });
  }

  /**
   * 将 AVSession LoopMode 转换为 RepeatMode
   */
  private convertLoopModeToRepeatMode(mode: avSession.LoopMode): RepeatMode {
    switch (mode) {
      case avSession.LoopMode.LOOP_MODE_SINGLE:
        return RepeatMode.ONE;
      case avSession.LoopMode.LOOP_MODE_LIST:
        return RepeatMode.ALL;
      default:
        return RepeatMode.OFF;
    }
  }

  /**
   * 将 RepeatMode 转换为 AVSession LoopMode
   */
  private convertRepeatModeToLoopMode(mode: RepeatMode): avSession.LoopMode {
    switch (mode) {
      case RepeatMode.ONE:
        return avSession.LoopMode.LOOP_MODE_SINGLE;
      case RepeatMode.ALL:
        return avSession.LoopMode.LOOP_MODE_LIST;
      default:
        return avSession.LoopMode.LOOP_MODE_SEQUENCE;
    }
  }

  /**
   * 申请长时任务
   * 注：此功能需要系统权限和正确的 API 调用
   * 如果 API 版本不兼容，将跳过长时任务申请
   */
  private async requestBackgroundTask(): Promise<void> {
    if (this.isBackgroundTaskRequested) {
      return;
    }

    // 暂时禁用长时任务申请，等待 API 兼容性确认
    // TODO: 需要根据实际 HarmonyOS SDK 版本调整 API 调用
    console.info('[PlayerService] 长时任务功能暂未启用');
    this.isBackgroundTaskRequested = true;

    /* 原始实现 - 需要确认 API 版本
    try {
      const bgMode = backgroundTaskManager.BackgroundMode.AUDIO_PLAYBACK;
      await backgroundTaskManager.startBackgroundRunning(this.context, bgMode);
      this.isBackgroundTaskRequested = true;
      console.info('[PlayerService] 长时任务申请成功');
    } catch (error) {
      const err = error as Error;
      console.warn(`[PlayerService] 长时任务申请失败: ${err.message}`);
    }
    */
  }

  /**
   * 取消长时任务
   */
  private async cancelBackgroundTask(): Promise<void> {
    if (!this.isBackgroundTaskRequested) {
      return;
    }

    try {
      await backgroundTaskManager.stopBackgroundRunning(this.context);
      this.isBackgroundTaskRequested = false;
      console.info('[PlayerService] 长时任务已取消');
    } catch (error) {
      const err = error as Error;
      console.warn(`[PlayerService] 取消长时任务失败: ${err.message}`);
    }
  }

  /**
   * 处理 AVPlayer 状态变化
   */
  private handleAVPlayerStateChange(state: AVPlayerState): void {
    console.info(`[PlayerService] AVPlayer 状态变化: ${state}`);

    // 通知状态等待者（用于 waitForStateOnce）
    this.notifyStateWaiters(state);

    switch (state) {
      case AVPlayerState.PLAYING:
        this.state.isPlaying = true;
        this.state.isBuffering = false;
        this.startProgressTimer();
        break;

      case AVPlayerState.PAUSED:
        this.state.isPlaying = false;
        this.stopProgressTimer();
        break;

      case AVPlayerState.STOPPED:
      case AVPlayerState.IDLE:
        this.state.isPlaying = false;
        this.state.isBuffering = false;
        this.stopProgressTimer();
        break;

      case AVPlayerState.COMPLETED:
        this.handlePlaybackCompleted();
        break;

      case AVPlayerState.ERROR:
        this.state.isPlaying = false;
        this.state.isBuffering = false;
        this.stopProgressTimer();
        break;

      default:
        break;
    }

    this.notifyStateChange();
    this.updateAVSessionPlaybackState();
  }

  /**
   * 处理播放完成
   */
  private handlePlaybackCompleted(): void {
    console.info('[PlayerService] 播放完成');

    // 根据循环模式处理
    if (this.state.repeat === RepeatMode.ONE) {
      // 单曲循环，重新播放
      this.seekTo(0).then(() => {
        return this.play();
      }).catch((err: Error) => {
        console.error(`[PlayerService] 单曲循环播放失败: ${err.message}`);
      });
      return;
    }

    // 尝试播放下一首
    const hasNext = this.hasNextItem();
    if (hasNext) {
      this.next().catch((err: Error) => {
        console.error(`[PlayerService] 自动播放下一首失败: ${err.message}`);
      });
    } else if (this.state.repeat === RepeatMode.ALL && this.state.queue.length > 0) {
      // 列表循环，从头开始
      this.playAtIndex(0).catch((err: Error) => {
        console.error(`[PlayerService] 列表循环播放失败: ${err.message}`);
      });
    } else {
      // 播放完毕
      this.state.isPlaying = false;
      this.state.currentTime = 0;
      this.emit(PlayerEventType.QUEUE_END, undefined);
    }
  }

  /**
   * 检查是否有下一首
   */
  private hasNextItem(): boolean {
    if (this.state.queue.length === 0) {
      return false;
    }

    if (this.state.playMode === PlayMode.SHUFFLE) {
      return this.currentShufflePosition < this.shuffleIndices.length - 1;
    }

    return this.state.currentIndex < this.state.queue.length - 1;
  }

  /**
   * 检查是否有上一首
   */
  private hasPreviousItem(): boolean {
    if (this.state.queue.length === 0) {
      return false;
    }

    if (this.state.playMode === PlayMode.SHUFFLE) {
      return this.currentShufflePosition > 0;
    }

    return this.state.currentIndex > 0;
  }

  /**
   * 处理 AVPlayer 错误
   */
  private handleAVPlayerError(error: Error): void {
    console.error(`[PlayerService] AVPlayer 错误: ${error.message}`);

    const playerError: PlayerError = {
      code: PlayerErrorCode.PLAYER_SOURCE_ERROR.toString(),
      message: error.message,
      timestamp: Date.now()
    };

    this.state.error = playerError;
    this.state.isPlaying = false;
    this.state.isBuffering = false;

    this.emit(PlayerEventType.ERROR, playerError);
    this.notifyStateChange();
  }

  /**
   * 处理音频打断事件
   */
  private handleAudioInterrupt(interruptEvent: audio.InterruptEvent): void {
    console.info(`[PlayerService] 音频打断事件: type=${interruptEvent.eventType}, hint=${interruptEvent.hintType}`);

    const interruptData: InterruptEventData = {
      type: interruptEvent.eventType === audio.InterruptType.INTERRUPT_TYPE_BEGIN
        ? InterruptType.BEGIN
        : InterruptType.END,
      hint: interruptEvent.hintType.toString()
    };

    this.emit(PlayerEventType.INTERRUPT, interruptData);

    if (interruptEvent.eventType === audio.InterruptType.INTERRUPT_TYPE_BEGIN) {
      // 打断开始
      this.wasPlayingBeforeInterrupt = this.state.isPlaying;
      if (this.state.isPlaying) {
        this.pause().catch((err: Error) => {
          console.error(`[PlayerService] 打断时暂停失败: ${err.message}`);
        });
      }
    } else if (interruptEvent.eventType === audio.InterruptType.INTERRUPT_TYPE_END) {
      // 打断结束
      if (this.wasPlayingBeforeInterrupt) {
        // 检查打断提示类型，决定是否恢复播放
        if (interruptEvent.hintType === audio.InterruptHint.INTERRUPT_HINT_RESUME) {
          this.play().catch((err: Error) => {
            console.error(`[PlayerService] 恢复播放失败: ${err.message}`);
          });
        }
      }
      this.wasPlayingBeforeInterrupt = false;
    }
  }

  /**
   * 开始播放
   * @param item 可选，指定要播放的项目
   */
  async play(item?: PlaylistItem): Promise<void> {
    if (this.avPlayer === null) {
      throw new Error('播放器未初始化');
    }

    // 如果指定了播放项目，先设置
    if (item !== undefined) {
      await this.loadItem(item);
      return;
    }

    // 如果没有当前曲目
    if (this.state.currentTrack === null) {
      if (this.state.queue.length === 0) {
        throw new Error(getErrorMessage(PlayerErrorCode.PLAYER_NO_ITEM));
      }
      // 播放队列第一首
      await this.playAtIndex(0);
      return;
    }

    // 恢复播放
    await this.avPlayer.play();
    console.info('[PlayerService] 开始播放');
  }

  /**
   * 加载并播放指定项目
   */
  private async loadItem(item: PlaylistItem): Promise<void> {
    if (this.avPlayer === null) {
      throw new Error('播放器未初始化');
    }

    // 重置状态
    this.state.currentTime = 0;
    this.state.duration = 0;
    this.state.isBuffering = true;
    this.state.currentTrack = item;
    this.notifyStateChange();

    try {
      // 根据类型获取播放URL
      let url = this.getItemUrl(item);
      console.info(`[PlayerService] 原始播放URL: ${url}`);

      // 对于网络URL，先解析获取真实的播放地址
      if (url.startsWith('http://') || url.startsWith('https://')) {
        console.info('[PlayerService] 检测到网络URL，开始解析...');
        const resolved: ResolvedUrl = await audioUrlResolver.resolveAudioUrl(url, 15000);
        if (resolved.isValidAudio) {
          url = resolved.resolvedUrl;
          console.info(`[PlayerService] 解析后的URL: ${url}, Content-Type: ${resolved.contentType}`);
        } else {
          // 音频无效（可能是版权限制）
          const errorMsg = resolved.error || '该歌曲无法播放';
          console.error(`[PlayerService] URL解析失败: ${errorMsg}`);
          throw new Error(errorMsg);
        }
      }

      // 重置 AVPlayer
      console.info('[PlayerService] 开始 reset...');
      await this.avPlayer.reset();

      // reset() 完成后状态应该是 idle，等待状态变化回调确认
      const resetState = this.avPlayer.state;
      console.info('[PlayerService] reset 完成，状态: ' + resetState);

      // 设置播放源 - 这会触发状态变化到 initialized
      console.info('[PlayerService] 设置 url...');
      this.avPlayer.url = url;

      // 等待状态变成 initialized（设置 url 后应该自动进入此状态）
      console.info('[PlayerService] 等待 initialized 状态...');
      await this.waitForStateOnce('initialized', 15000);
      console.info('[PlayerService] 已进入 initialized 状态');

      // 设置音频渲染信息（必须在 initialized 状态后、prepare 之前设置）
      console.info('[PlayerService] 设置 audioRendererInfo...');
      this.avPlayer.audioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 0
      };

      // 准备播放（从 initialized -> prepared）
      console.info('[PlayerService] 调用 prepare()...');
      await this.avPlayer.prepare();

      // 等待状态变为 prepared - 增加超时时间到60秒以适应慢速网络
      console.info('[PlayerService] 等待 prepared 状态...');
      await this.waitForStateOnce('prepared', 60000);

      // 验证当前状态是否正确
      const currentState = this.avPlayer.state;
      console.info('[PlayerService] prepare() 完成，状态: ' + currentState);

      if (currentState !== 'prepared' && currentState !== 'playing' && currentState !== 'paused') {
        throw new Error(`播放器状态异常: ${currentState}，无法播放`);
      }

      // 设置音量（必须在 prepared 状态后）
      console.info('[PlayerService] 设置音量...');
      try {
        await this.avPlayer.setVolume(this.state.volume);
      } catch (volumeErr) {
        // 音量设置失败不应阻止播放
        console.warn('[PlayerService] 设置音量失败，继续播放: ' + (volumeErr as Error).message);
      }

      // 开始播放
      console.info('[PlayerService] 调用 play()...');
      await this.avPlayer.play();
      console.info('[PlayerService] play() 完成，状态: ' + this.avPlayer.state);

      // 更新 AVSession 元数据
      await this.updateAVSessionMetadata(item);

      // 发送曲目变化事件
      this.emit(PlayerEventType.TRACK_CHANGE, item);

      console.info(`[PlayerService] 加载曲目完成: ${item.title}`);
    } catch (error) {
      const err = error as Error;
      console.error(`[PlayerService] 加载曲目失败: ${err.message}`);
      this.state.isBuffering = false;
      this.state.error = {
        code: PlayerErrorCode.PLAYER_SOURCE_ERROR.toString(),
        message: err.message,
        timestamp: Date.now()
      };
      this.notifyStateChange();
      throw new Error(err.message);
    }
  }

  /**
   * 等待 AVPlayer 进入指定状态（通过主回调通知，不注册额外回调）
   * @param targetState 目标状态
   * @param timeoutMs 超时时间（毫秒），默认 15000ms
   */
  private waitForStateOnce(targetState: string, timeoutMs: number = 15000): Promise<void> {
    return new Promise((resolve, reject) => {
      if (this.avPlayer === null) {
        reject(new Error('播放器未初始化'));
        return;
      }

      // 检查当前状态
      const currentState = this.avPlayer.state;
      console.info(`[PlayerService] 当前状态: ${currentState}, 目标状态: ${targetState}`);

      if (currentState === targetState) {
        console.info(`[PlayerService] 已在目标状态: ${targetState}`);
        resolve();
        return;
      }

      // 设置超时
      const timerId = Number(setTimeout(() => {
        this.stateResolvers.delete(targetState);
        const curState = this.avPlayer?.state ?? 'unknown';
        console.error(`[PlayerService] 等待状态超时: ${targetState}, 当前状态: ${curState}`);
        reject(new Error(`等待状态超时: ${targetState}`));
      }, timeoutMs));

      // 保存解析器，等待主回调通知
      const resolver: StateResolver = { resolve, reject, timerId };
      this.stateResolvers.set(targetState, resolver);
      console.info(`[PlayerService] 已注册状态等待: ${targetState}`);
    });
  }

  /**
   * 通知状态等待者
   * @param state 当前状态
   */
  private notifyStateWaiters(state: string): void {
    const resolver = this.stateResolvers.get(state);
    if (resolver !== undefined) {
      clearTimeout(resolver.timerId);
      this.stateResolvers.delete(state);
      resolver.resolve();
      console.info(`[PlayerService] 已通知状态等待者: ${state}`);
    }
  }

  /**
   * 等待 AVPlayer 进入指定状态
   * @param targetState 目标状态
   * @param timeoutMs 超时时间（毫秒），默认 15000ms
   */
  private waitForState(targetState: string, timeoutMs: number = 15000): Promise<void> {
    return new Promise((resolve, reject) => {
      if (this.avPlayer === null) {
        reject(new Error('播放器未初始化'));
        return;
      }

      // 检查当前状态
      const currentState = this.avPlayer.state;
      console.info(`[PlayerService] 当前状态: ${currentState}, 目标状态: ${targetState}`);

      if (currentState === targetState) {
        console.info(`[PlayerService] 已在目标状态: ${targetState}`);
        resolve();
        return;
      }

      let resolved = false;

      // 设置超时
      const timeout = setTimeout(() => {
        if (!resolved) {
          resolved = true;
          const curState = this.avPlayer?.state ?? 'unknown';
          console.error(`[PlayerService] 等待状态超时: ${targetState}, 当前状态: ${curState}`);
          reject(new Error(`等待状态超时: ${targetState}`));
        }
      }, timeoutMs);

      // 监听状态变化
      const stateHandler = (state: string) => {
        console.info(`[PlayerService] 状态变化: ${state}`);
        if (state === targetState && !resolved) {
          resolved = true;
          clearTimeout(timeout);
          console.info(`[PlayerService] 已到达目标状态: ${targetState}`);
          resolve();
        }
      };

      if (this.avPlayer !== null) {
        this.avPlayer.on('stateChange', stateHandler);
      }
    });
  }

  /**
   * 获取播放项目的URL
   */
  private getItemUrl(item: PlaylistItem): string {
    if (item.type === PlaylistItemType.RADIO_STATION) {
      // 网络电台，trackId 存储的是流媒体URL
      // 注意：实际实现中应该从 RadioStation 数据中获取 url
      // 这里简化处理，假设 trackId 就是 URL（实际需要从数据源获取）
      return item.trackId;
    } else {
      // 本地音乐，trackId 存储的是文件路径
      return item.trackId;
    }
  }

  /**
   * 暂停播放
   */
  async pause(): Promise<void> {
    if (this.avPlayer === null) {
      throw new Error('播放器未初始化');
    }

    if (!this.state.isPlaying) {
      return;
    }

    await this.avPlayer.pause();
    console.info('[PlayerService] 暂停播放');
  }

  /**
   * 停止播放
   */
  async stop(): Promise<void> {
    if (this.avPlayer === null) {
      return;
    }

    await this.avPlayer.stop();

    this.state.isPlaying = false;
    this.state.currentTime = 0;
    this.state.isBuffering = false;

    this.notifyStateChange();
    this.updateAVSessionPlaybackState();

    console.info('[PlayerService] 停止播放');
  }

  /**
   * 播放下一首
   */
  async next(): Promise<void> {
    if (this.state.queue.length === 0) {
      throw new Error(getErrorMessage(PlayerErrorCode.PLAYER_NO_NEXT));
    }

    let nextIndex: number;

    if (this.state.playMode === PlayMode.SHUFFLE) {
      // 随机播放模式
      if (this.currentShufflePosition >= this.shuffleIndices.length - 1) {
        // 已经是最后一首
        if (this.state.repeat === RepeatMode.ALL) {
          // 列表循环，从头开始
          this.currentShufflePosition = 0;
          nextIndex = this.shuffleIndices[0];
        } else {
          throw new Error(getErrorMessage(PlayerErrorCode.PLAYER_NO_NEXT));
        }
      } else {
        this.currentShufflePosition++;
        nextIndex = this.shuffleIndices[this.currentShufflePosition];
      }
    } else {
      // 顺序播放模式
      if (this.state.currentIndex >= this.state.queue.length - 1) {
        // 已经是最后一首
        if (this.state.repeat === RepeatMode.ALL) {
          nextIndex = 0;
        } else {
          throw new Error(getErrorMessage(PlayerErrorCode.PLAYER_NO_NEXT));
        }
      } else {
        nextIndex = this.state.currentIndex + 1;
      }
    }

    await this.playAtIndex(nextIndex);
  }

  /**
   * 播放上一首
   */
  async previous(): Promise<void> {
    if (this.state.queue.length === 0) {
      throw new Error(getErrorMessage(PlayerErrorCode.PLAYER_NO_PREVIOUS));
    }

    // 如果当前播放超过3秒，重新播放当前曲目
    if (this.state.currentTime > 3000) {
      await this.seekTo(0);
      return;
    }

    let prevIndex: number;

    if (this.state.playMode === PlayMode.SHUFFLE) {
      // 随机播放模式
      if (this.currentShufflePosition <= 0) {
        // 已经是第一首
        if (this.state.repeat === RepeatMode.ALL) {
          // 列表循环，从尾开始
          this.currentShufflePosition = this.shuffleIndices.length - 1;
          prevIndex = this.shuffleIndices[this.currentShufflePosition];
        } else {
          throw new Error(getErrorMessage(PlayerErrorCode.PLAYER_NO_PREVIOUS));
        }
      } else {
        this.currentShufflePosition--;
        prevIndex = this.shuffleIndices[this.currentShufflePosition];
      }
    } else {
      // 顺序播放模式
      if (this.state.currentIndex <= 0) {
        // 已经是第一首
        if (this.state.repeat === RepeatMode.ALL) {
          prevIndex = this.state.queue.length - 1;
        } else {
          throw new Error(getErrorMessage(PlayerErrorCode.PLAYER_NO_PREVIOUS));
        }
      } else {
        prevIndex = this.state.currentIndex - 1;
      }
    }

    await this.playAtIndex(prevIndex);
  }

  /**
   * 跳转到指定位置
   * @param positionMs 目标位置（毫秒）
   */
  async seekTo(positionMs: number): Promise<void> {
    if (this.avPlayer === null) {
      throw new Error('播放器未初始化');
    }

    if (this.state.currentTrack === null) {
      throw new Error(getErrorMessage(PlayerErrorCode.PLAYER_NO_ITEM));
    }

    // 参数校验
    const clampedPosition = Math.max(0, Math.min(positionMs, this.state.duration));

    await this.avPlayer.seek(clampedPosition);
    this.state.currentTime = clampedPosition;

    console.info(`[PlayerService] 跳转到: ${clampedPosition}ms`);
  }

  /**
   * 设置音量
   * @param volume 音量值（0.0 - 1.0）
   */
  async setVolume(volume: number): Promise<void> {
    if (this.avPlayer === null) {
      throw new Error('播放器未初始化');
    }

    // 参数校验
    const clampedVolume = Math.max(0, Math.min(1, volume));

    await this.avPlayer.setVolume(clampedVolume);
    this.state.volume = clampedVolume;

    this.notifyStateChange();
    console.info(`[PlayerService] 设置音量: ${clampedVolume}`);
  }

  /**
   * 设置播放模式
   * @param mode 播放模式
   */
  async setPlayMode(mode: PlayMode): Promise<void> {
    const previousMode = this.state.playMode;
    this.state.playMode = mode;
    this.state.shuffle = (mode === PlayMode.SHUFFLE);

    // 如果切换到随机模式，生成随机索引
    if (mode === PlayMode.SHUFFLE && previousMode !== PlayMode.SHUFFLE) {
      this.generateShuffleIndices();
      // 找到当前曲目的随机位置
      const currentIdx = this.shuffleIndices.indexOf(this.state.currentIndex);
      if (currentIdx !== -1) {
        this.currentShufflePosition = currentIdx;
      }
    }

    this.notifyStateChange();
    console.info(`[PlayerService] 设置播放模式: ${mode}`);
  }

  /**
   * 设置循环模式
   * @param mode 循环模式
   */
  async setRepeatMode(mode: RepeatMode): Promise<void> {
    this.state.repeat = mode;

    // 更新 AVSession 循环模式
    // 注：setLoopMode 在某些 API 版本中不存在
    if (this.avSession !== null) {
      try {
        // AVSession 可能不支持 setLoopMode，仅更新内部状态
        console.info('[PlayerService] 循环模式已更新到内部状态');
      } catch (e) {
        console.warn('[PlayerService] 设置 AVSession 循环模式失败');
      }
    }

    this.notifyStateChange();
    console.info(`[PlayerService] 设置循环模式: ${mode}`);
  }

  /**
   * 生成随机播放索引
   */
  private generateShuffleIndices(): void {
    const length = this.state.queue.length;

    // 使用循环创建索引数组
    this.shuffleIndices = [];
    for (let i = 0; i < length; i++) {
      this.shuffleIndices.push(i);
    }

    // Fisher-Yates 洗牌算法
    for (let i = length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      // 使用临时变量交换，避免解构赋值
      const temp = this.shuffleIndices[i];
      this.shuffleIndices[i] = this.shuffleIndices[j];
      this.shuffleIndices[j] = temp;
    }

    this.currentShufflePosition = 0;
    console.info('[PlayerService] 生成随机播放索引');
  }

  /**
   * 设置播放队列
   * @param items 播放队列项目列表
   * @param startIndex 起始索引，默认0
   */
  async setQueue(items: PlaylistItem[], startIndex: number = 0): Promise<void> {
    this.state.queue = [...items];
    this.state.currentIndex = startIndex;

    // 如果是随机模式，重新生成索引
    if (this.state.playMode === PlayMode.SHUFFLE) {
      this.generateShuffleIndices();
    }

    // 如果指定了起始索引，开始播放
    if (items.length > 0 && startIndex >= 0 && startIndex < items.length) {
      await this.playAtIndex(startIndex);
    }

    this.notifyStateChange();
    console.info(`[PlayerService] 设置播放队列: ${items.length} 首，起始索引: ${startIndex}`);
  }

  /**
   * 设置播放队列来源
   */
  setQueueSource(source: QueueSource): void {
    this.state.queueSource = source;
  }

  /**
   * 播放指定索引的曲目
   */
  async playAtIndex(index: number): Promise<void> {
    if (index < 0 || index >= this.state.queue.length) {
      throw new Error('索引越界');
    }

    this.state.currentIndex = index;
    const item = this.state.queue[index];
    await this.loadItem(item);
  }

  /**
   * 获取当前播放状态
   */
  getState(): PlayerState {
    // 返回状态副本，避免直接引用
    const currentTrack: PlaylistItem | null = this.state.queue.length > 0 && this.state.currentIndex >= 0
      ? this.state.queue[this.state.currentIndex]
      : null;

    const stateCopy: PlayerState = {
      currentTrack: currentTrack,
      currentIndex: this.state.currentIndex,
      isPlaying: this.state.isPlaying,
      isBuffering: this.state.isBuffering,
      currentTime: this.state.currentTime,
      duration: this.state.duration,
      volume: this.state.volume,
      playMode: this.state.playMode,
      shuffle: this.state.playMode === PlayMode.SHUFFLE,
      repeat: this.state.repeat,
      queue: this.state.queue,
      queueSource: this.state.queueSource,
      error: this.state.error
    };
    return stateCopy;
  }

  /**
   * 获取当前播放进度
   */
  getProgress(): ProgressData {
    return {
      currentTime: this.state.currentTime,
      duration: this.state.duration,
      buffered: 0 // 暂不实现缓冲进度
    };
  }

  /**
   * 开始进度更新定时器
   */
  private startProgressTimer(): void {
    this.stopProgressTimer();

    const timer = setInterval(() => {
      this.updateProgress();
    }, 1000);
    // 将返回值转换为 number 类型
    this.progressTimer = Number(timer);
  }

  /**
   * 停止进度更新定时器
   */
  private stopProgressTimer(): void {
    if (this.progressTimer !== -1) {
      clearInterval(this.progressTimer);
      this.progressTimer = -1;
    }
  }

  /**
   * 更新播放进度
   */
  private updateProgress(): void {
    if (this.avPlayer === null || !this.state.isPlaying) {
      return;
    }

    try {
      // currentTime 和 duration 在某些 API 版本中是同步属性
      const currentTime: number = this.avPlayer.currentTime as number;
      const duration: number = this.avPlayer.duration as number;

      this.state.currentTime = currentTime;
      if (duration > 0) {
        this.state.duration = duration;
      }

      // 发送进度更新事件
      const progressData: ProgressData = {
        currentTime: this.state.currentTime,
        duration: this.state.duration,
        buffered: 0
      };
      this.emit(PlayerEventType.PROGRESS, progressData);
    } catch (err) {
      const error: Error = err as Error;
      console.error(`[PlayerService] 更新进度失败: ${error.message}`);
    }
  }

  /**
   * 更新 AVSession 元数据
   */
  private async updateAVSessionMetadata(item: PlaylistItem): Promise<void> {
    if (this.avSession === null) {
      return;
    }

    const metadata: avSession.AVMetadata = {
      assetId: item.id,
      title: item.title,
      artist: item.subtitle
    };

    // 如果有封面图片
    if (item.thumbnail !== undefined && item.thumbnail !== null && item.thumbnail !== '') {
      // 注意：AVSession 的 mediaImage 需要是 PixelMap 或者 URI
      // 这里简化处理，实际需要转换图片格式
      metadata.mediaImage = item.thumbnail;
    }

    await this.avSession.setAVMetadata(metadata);
  }

  /**
   * 更新 AVSession 播放状态
   */
  private updateAVSessionPlaybackState(): void {
    if (this.avSession === null) {
      return;
    }

    const playbackState: avSession.AVPlaybackState = {
      state: this.getAVSessionPlaybackState(),
      position: {
        elapsedTime: this.state.currentTime,
        updateTime: Date.now()
      },
      speed: 1.0,
      bufferedTime: 0
    };

    this.avSession.setAVPlaybackState(playbackState).catch((err: Error) => {
      console.error(`[PlayerService] 更新AVSession播放状态失败: ${err.message}`);
    });
  }

  /**
   * 获取 AVSession 播放状态
   */
  private getAVSessionPlaybackState(): avSession.PlaybackState {
    if (this.state.isBuffering) {
      return avSession.PlaybackState.PLAYBACK_STATE_BUFFERING;
    }
    if (this.state.isPlaying) {
      return avSession.PlaybackState.PLAYBACK_STATE_PLAY;
    }
    if (this.state.currentTrack !== null && this.state.currentTime > 0) {
      return avSession.PlaybackState.PLAYBACK_STATE_PAUSE;
    }
    return avSession.PlaybackState.PLAYBACK_STATE_STOP;
  }

  /**
   * 通知状态变化
   */
  private notifyStateChange(): void {
    const stateCopy: PlayerState = this.getState();
    this.emit(PlayerEventType.STATE_CHANGE, stateCopy);
  }

  /**
   * 注册事件监听
   */
  on(event: PlayerEventType, callback: PlayerEventCallback): void {
    if (!this.eventListeners.has(event)) {
      this.eventListeners.set(event, new Set());
    }
    this.eventListeners.get(event)!.add(callback);
  }

  /**
   * 移除事件监听
   */
  off(event: PlayerEventType, callback?: PlayerEventCallback): void {
    if (!this.eventListeners.has(event)) {
      return;
    }

    if (callback !== undefined) {
      this.eventListeners.get(event)!.delete(callback);
    } else {
      this.eventListeners.delete(event);
    }
  }

  /**
   * 触发事件
   */
  private emit(event: PlayerEventType, data: PlayerState | ProgressData | PlayerError | InterruptEventData | PlaylistItem | void): void {
    if (!this.eventListeners.has(event)) {
      return;
    }

    const callbacks = this.eventListeners.get(event)!;
    callbacks.forEach((callback) => {
      try {
        callback(data);
      } catch (err) {
        const error = err as Error;
        console.error(`[PlayerService] 事件回调执行失败: ${error.message}`);
      }
    });
  }

  /**
   * 销毁播放服务
   */
  async destroy(): Promise<void> {
    console.info('[PlayerService] 开始销毁');

    // 停止进度定时器
    this.stopProgressTimer();

    // 停止播放
    if (this.avPlayer !== null) {
      try {
        await this.avPlayer.stop();
        await this.avPlayer.release();
      } catch (err) {
        const error = err as Error;
        console.error(`[PlayerService] 释放AVPlayer失败: ${error.message}`);
      }
      this.avPlayer = null;
    }

    // 销毁 AVSession
    if (this.avSession !== null) {
      try {
        await this.avSession.deactivate();
        await this.avSession.destroy();
      } catch (err) {
        const error = err as Error;
        console.error(`[PlayerService] 销毁AVSession失败: ${error.message}`);
      }
      this.avSession = null;
    }

    // 取消长时任务
    await this.cancelBackgroundTask();

    // 清空事件监听
    this.eventListeners.clear();

    // 重置状态
    this.state = this.createDefaultState();
    this.isInitialized = false;

    console.info('[PlayerService] 销毁完成');
  }
}

// 创建单例实例
let playerServiceInstance: PlayerService | null = null;

/**
 * 获取 PlayerService 单例
 */
export function getPlayerService(): PlayerService {
  if (playerServiceInstance === null) {
    playerServiceInstance = new PlayerService();
  }
  return playerServiceInstance;
}

/**
 * 初始化并获取 PlayerService 单例
 */
export async function initializePlayerService(context: common.UIAbilityContext): Promise<PlayerService> {
  const service = getPlayerService();
  await service.initialize(context);
  return service;
}
