/**
 * 播放列表项类型枚举
 * 定义播放列表项的来源类型
 */
export enum PlaylistItemType {
  /** 本地音乐文件 */
  LOCAL_MUSIC = 'local_music',
  /** 网络电台 */
  RADIO_STATION = 'radio_station'
}

/**
 * 播放列表项模型
 * 用于表示播放列表中的单个项目，可以是本地音乐或网络电台
 *
 * 验证规则：
 * - id 格式：item_${uuid}
 * - order 从 0 开始递增
 * - trackId 必须引用有效的 MusicTrack 或 RadioStation
 */
export interface PlaylistItem {
  /** 播放列表项唯一标识符，格式：item_${uuid} */
  id: string;

  /** 项目来源类型，区分本地音乐和网络电台 */
  type: PlaylistItemType;

  /** 关联的内容 ID，指向 MusicTrack.id 或 RadioStation.id */
  trackId: string;

  /** 标题，用于快速显示（冗余存储） */
  title: string;

  /** 副标题，显示艺术家或国家信息（冗余存储） */
  subtitle: string;

  /** 缩略图/封面图片 URI（可选，冗余存储用于快速显示） */
  thumbnail?: string;

  /** 在播放列表中的排序顺序，从 0 开始递增 */
  order: number;

  /** 添加到播放列表的时间戳 */
  addedAt: number;
}
