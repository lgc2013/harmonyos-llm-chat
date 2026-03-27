import { PlaylistItem } from './PlaylistItem';

/**
 * 播放模式枚举
 * 定义播放器的播放顺序模式
 */
export enum PlayMode {
  /** 顺序播放 */
  SEQUENCE = 'sequence',
  /** 随机播放 */
  SHUFFLE = 'shuffle',
  /** 单曲播放 */
  SINGLE = 'single',
  /** 列表循环 */
  LOOP = 'loop'
}

/**
 * 循环模式枚举
 * 定义播放器的循环播放行为
 */
export enum RepeatMode {
  /** 不循环 */
  OFF = 'off',
  /** 列表循环 */
  ALL = 'all',
  /** 单曲循环 */
  ONE = 'one'
}

/**
 * 播放队列来源枚举
 * 定义当前播放队列的数据来源
 */
export enum QueueSource {
  /** 本地音乐库 */
  LOCAL_LIBRARY = 'local_library',
  /** 网络电台列表 */
  RADIO_LIST = 'radio_list',
  /** 用户播放列表 */
  PLAYLIST = 'playlist',
  /** 搜索结果 */
  SEARCH_RESULT = 'search_result'
}

/**
 * 播放器错误模型
 * 用于记录播放过程中发生的错误信息
 */
export interface PlayerError {
  /** 错误代码 */
  code: string;

  /** 错误描述信息 */
  message: string;

  /** 错误发生时间戳 */
  timestamp: number;
}

/**
 * 播放器状态模型
 * 用于表示当前播放器的完整状态信息
 */
export interface PlayerState {
  /** 当前播放的曲目项，无播放内容时为 null */
  currentTrack: PlaylistItem | null;

  /** 当前播放曲目在队列中的索引位置 */
  currentIndex: number;

  /** 是否正在播放 */
  isPlaying: boolean;

  /** 是否正在缓冲 */
  isBuffering: boolean;

  /** 当前播放位置，单位：毫秒 */
  currentTime: number;

  /** 当前曲目总时长，单位：毫秒 */
  duration: number;

  /** 当前音量，范围：0.0 - 1.0 */
  volume: number;

  /** 播放模式 */
  playMode: PlayMode;

  /** 是否开启随机播放 */
  shuffle: boolean;

  /** 循环模式 */
  repeat: RepeatMode;

  /** 播放队列列表 */
  queue: PlaylistItem[];

  /** 播放队列的数据来源 */
  queueSource: QueueSource;

  /** 播放错误信息（可选，发生错误时存在） */
  error?: PlayerError;
}
