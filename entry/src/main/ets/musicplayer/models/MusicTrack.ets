/**
 * 音频格式枚举
 * 定义支持的音频文件格式类型
 */
export enum AudioFormat {
  /** MP3 格式 */
  MP3 = 'mp3',
  /** AAC 格式 */
  AAC = 'aac',
  /** WAV 格式 */
  WAV = 'wav',
  /** FLAC 无损格式 */
  FLAC = 'flac',
  /** M4A 格式 */
  M4A = 'm4a',
  /** OGG 格式 */
  OGG = 'ogg',
  /** 未知格式 */
  UNKNOWN = 'unknown'
}

/**
 * 本地音乐曲目模型
 * 用于表示本地存储的音乐文件信息
 *
 * 验证规则：
 * - title 不能为空，若元数据缺失则使用文件名
 * - filePath 必须是有效的本地文件路径
 * - duration 必须 > 0
 * - id 格式：local_${filePathHash}
 */
export interface MusicTrack {
  /** 基于文件路径生成的唯一标识符，格式：local_${filePathHash} */
  id: string;

  /** 歌曲名称 */
  title: string;

  /** 艺术家/歌手名称 */
  artist: string;

  /** 专辑名称 */
  album: string;

  /** 歌曲时长，单位：毫秒 */
  duration: number;

  /** 本地文件存储路径 */
  filePath: string;

  /** 文件大小，单位：字节 */
  fileSize: number;

  /** 音频格式类型 */
  format: AudioFormat;

  /** 专辑封面图片 URI（可选） */
  albumArt?: string;

  /** 曲目在专辑中的编号（可选） */
  trackNumber?: number;

  /** 发行年份（可选） */
  year?: number;

  /** 添加到音乐库的时间戳 */
  dateAdded: number;

  /** 最后一次播放的时间戳（可选） */
  lastPlayed?: number;

  /** 累计播放次数 */
  playCount: number;
}
