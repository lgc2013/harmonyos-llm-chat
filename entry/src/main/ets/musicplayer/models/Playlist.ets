import { PlaylistItem, PlaylistItemType } from './PlaylistItem';

// 重新导出
export { PlaylistItem, PlaylistItemType };

/**
 * 播放列表项接口（用于播放队列）
 */
export interface PlaylistQueueItem {
  id: string;
  type: PlaylistItemType;
  trackId: string;
  title: string;
  subtitle: string;
  thumbnail?: string;
  order: number;
  addedAt: number;
}

/**
 * 播放列表模型
 * 用于表示用户自定义的播放列表
 *
 * 验证规则：
 * - name 不能为空，最大长度 50 字符
 * - id 格式：playlist_${uuid}
 * - items 数量限制：0 - 500
 */
export interface Playlist {
  /** 播放列表唯一标识符，格式：playlist_${uuid} */
  id: string;

  /** 播放列表名称 */
  name: string;

  /** 播放列表描述（可选） */
  description?: string;

  /** 播放列表封面图片 URI（可选） */
  coverImage?: string;

  /** 播放列表项列表 */
  items: PlaylistItem[];

  /** 播放列表总曲目数 */
  totalCount: number;

  /** 播放列表总时长，单位：毫秒 */
  totalDuration: number;

  /** 播放列表创建时间戳 */
  createdAt: number;

  /** 播放列表最后更新时间戳 */
  updatedAt: number;

  /** 是否为系统默认播放列表（如"我喜欢的音乐"） */
  isSystem: boolean;
}
