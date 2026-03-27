import { MusicTrack } from './MusicTrack';
import { RadioStation } from './RadioStation';

/**
 * 音乐库状态模型
 * 用于管理本地音乐库和网络电台的状态信息
 */
export interface LibraryState {
  // ========== 本地音乐相关状态 ==========

  /** 本地音乐曲目列表 */
  localTracks: MusicTrack[];

  /** 本地音乐是否正在加载 */
  localLoading: boolean;

  /** 本地音乐加载错误信息（可选） */
  localError?: string;

  // ========== 网络电台相关状态 ==========

  /** 网络电台列表 */
  radioStations: RadioStation[];

  /** 网络电台是否正在加载 */
  radioLoading: boolean;

  /** 网络电台加载错误信息（可选） */
  radioError?: string;

  // ========== 搜索相关状态 ==========

  /** 当前搜索关键词 */
  searchQuery: string;

  /** 搜索结果列表 */
  searchResults: RadioStation[];

  /** 搜索是否正在进行 */
  searchLoading: boolean;

  // ========== 筛选相关状态 ==========

  /** 当前选中的国家筛选条件（可选） */
  selectedCountry?: string;

  /** 当前选中的标签/类型筛选条件（可选） */
  selectedTag?: string;
}
