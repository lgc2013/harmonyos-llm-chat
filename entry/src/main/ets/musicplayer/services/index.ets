/**
 * 音乐播放器服务层统一导出
 * 提供所有服务的集中访问入口
 */

// PlayerService - 核心播放服务
export {
  PlayerService,
  getPlayerService,
  initializePlayerService,
  PlayerEventType,
  ProgressData,
  InterruptEventData,
  InterruptType,
  PlayerEventCallback
} from './PlayerService';

// 从 models 导出类型
export {
  PlayerState,
  PlaylistItem
} from '../models/index';

// LocalMusicService - 本地音乐服务
export {
  LocalMusicService,
  localMusicService
} from './LocalMusicService';

// RadioService - 网络电台服务
export {
  RadioService,
  RadioServiceError,
  CountryInfo,
  TagInfo
} from './RadioService';
export { default as radioService } from './RadioService';

// PlaylistService - 播放列表服务
export {
  PlaylistService,
  createPlaylistService
} from './PlaylistService';

// NeteaseMusicService - 网易云音乐服务
export {
  NeteaseSong
} from './NeteaseMusicService';
export { default as neteaseMusicService } from './NeteaseMusicService';

// AudioUrlResolver - 音频URL解析服务
export {
  ResolvedUrl
} from './AudioUrlResolver';
export { default as audioUrlResolver } from './AudioUrlResolver';
