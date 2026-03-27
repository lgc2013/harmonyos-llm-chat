/**
 * 音乐播放器枚举类型定义
 * 包含音频格式、播放列表类型、播放模式、循环模式、队列来源、中断类型等枚举
 */

/**
 * 音频格式枚举
 * 支持的音频文件格式类型
 */
export enum AudioFormat {
  /** MP3 格式 */
  MP3 = 'MP3',
  /** AAC 格式 */
  AAC = 'AAC',
  /** WAV 格式 */
  WAV = 'WAV',
  /** FLAC 无损格式 */
  FLAC = 'FLAC',
  /** M4A 格式 */
  M4A = 'M4A',
  /** OGG 格式 */
  OGG = 'OGG',
  /** 未知格式 */
  UNKNOWN = 'UNKNOWN'
}

/**
 * 播放列表项类型枚举
 * 定义播放列表中项目的来源类型
 */
export enum PlaylistItemType {
  /** 本地音乐 */
  LOCAL_MUSIC = 'LOCAL_MUSIC',
  /** 网络电台 */
  RADIO_STATION = 'RADIO_STATION'
}

/**
 * 播放模式枚举
 * 定义播放顺序的模式
 */
export enum PlayMode {
  /** 顺序播放 */
  SEQUENCE = 'SEQUENCE',
  /** 列表循环 */
  LOOP = 'LOOP',
  /** 单曲循环 */
  SINGLE = 'SINGLE',
  /** 随机播放 */
  SHUFFLE = 'SHUFFLE'
}

/**
 * 播放模式信息接口
 * 包含图标和名称
 */
export interface PlayModeInfo {
  /** 图标名称 */
  icon: string
  /** 模式名称（中文） */
  name: string
}

/**
 * 播放模式映射表
 * 用于获取各模式对应的图标和名称
 */
export const PLAY_MODE_MAP: Record<PlayMode, PlayModeInfo> = {
  [PlayMode.SEQUENCE]: { icon: 'list', name: '顺序播放' },
  [PlayMode.LOOP]: { icon: 'repeat', name: '列表循环' },
  [PlayMode.SINGLE]: { icon: 'repeat-one', name: '单曲循环' },
  [PlayMode.SHUFFLE]: { icon: 'shuffle', name: '随机播放' }
}

/**
 * 循环模式枚举
 * 定义播放完成后的循环行为
 */
export enum RepeatMode {
  /** 不循环 */
  OFF = 'OFF',
  /** 列表循环 */
  ALL = 'ALL',
  /** 单曲循环 */
  ONE = 'ONE'
}

/**
 * 播放队列来源枚举
 * 定义当前播放队列的数据来源
 */
export enum QueueSource {
  /** 本地音乐库 */
  LOCAL_LIBRARY = 'LOCAL_LIBRARY',
  /** 电台列表 */
  RADIO_LIST = 'RADIO_LIST',
  /** 用户播放列表 */
  PLAYLIST = 'PLAYLIST',
  /** 搜索结果 */
  SEARCH_RESULT = 'SEARCH_RESULT'
}

/**
 * 中断类型枚举
 * 定义音频中断事件的类型
 */
export enum InterruptType {
  /** 中断开始 */
  BEGIN = 'BEGIN',
  /** 中断结束 */
  END = 'END'
}
