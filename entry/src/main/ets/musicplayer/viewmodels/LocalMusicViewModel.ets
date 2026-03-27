/**
 * 本地音乐视图模型
 * 管理本地音乐库状态，提供 UI 层与 LocalMusicService 的交互接口
 *
 * 职责：
 * - 管理本地音乐列表状态
 * - 提供排序、搜索功能
 * - 处理加载和错误状态
 */

import { MusicTrack } from '../models/MusicTrack';
import { LocalMusicService, localMusicService } from '../services/LocalMusicService';
import { LibraryErrorCode, createError, getErrorMessage } from '../common/ErrorCodes';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 日志标签
 */
const LOG_TAG: string = 'LocalMusicViewModel';
const LOG_DOMAIN: number = 0xFF00;

/**
 * 错误对象接口
 */
interface ErrorObject {
  code?: number;
  message?: string;
}

/**
 * 排序类型枚举
 */
export enum SortType {
  /** 按标题排序 */
  TITLE = 'title',
  /** 按艺术家排序 */
  ARTIST = 'artist',
  /** 按专辑排序 */
  ALBUM = 'album'
}

/**
 * 本地音乐视图模型
 * 管理 UI 状态和业务逻辑
 */
export class LocalMusicViewModel {
  /** 音乐曲目列表 */
  private _tracks: MusicTrack[] = [];

  /** 加载状态 */
  private _isLoading: boolean = false;

  /** 错误信息 */
  private _errorMessage: string | null = null;

  /** 上次扫描时间戳 */
  private _lastScanTime: number = 0;

  /** 当前排序类型 */
  private _currentSortType: SortType = SortType.TITLE;

  /** 本地音乐服务实例 */
  private musicService: LocalMusicService;

  /**
   * 构造函数
   * @param service 本地音乐服务实例（可选，默认使用单例）
   */
  constructor(service?: LocalMusicService) {
    this.musicService = service !== undefined ? service : localMusicService;
  }

  /**
   * 获取音乐曲目列表
   */
  get tracks(): MusicTrack[] {
    return this._tracks;
  }

  /**
   * 获取加载状态
   */
  get isLoading(): boolean {
    return this._isLoading;
  }

  /**
   * 获取错误信息
   */
  get errorMessage(): string | null {
    return this._errorMessage;
  }

  /**
   * 获取上次扫描时间
   */
  get lastScanTime(): number {
    return this._lastScanTime;
  }

  /**
   * 获取曲目数量
   */
  get trackCount(): number {
    return this._tracks.length;
  }

  /**
   * 初始化视图模型
   * 加载已缓存的音乐数据
   */
  async initialize(): Promise<void> {
    hilog.info(LOG_DOMAIN, LOG_TAG, '初始化本地音乐视图模型');

    this._isLoading = true;
    this._errorMessage = null;

    try {
      // 尝试获取已缓存的音乐数据
      const cachedTracks: MusicTrack[] = await this.musicService.getAllTracks();

      this._tracks = cachedTracks;
      this._lastScanTime = Date.now();

      hilog.info(LOG_DOMAIN, LOG_TAG, `初始化完成，加载 ${this._tracks.length} 首曲目`);

    } catch (error) {
      const err: ErrorObject = error as ErrorObject;
      this._errorMessage = err.message !== undefined ? err.message : '初始化失败';
      hilog.error(LOG_DOMAIN, LOG_TAG, `初始化失败: ${this._errorMessage}`);
    } finally {
      this._isLoading = false;
    }
  }

  /**
   * 扫描本地音乐库
   * 重新扫描设备上的音乐文件
   */
  async scanMusicLibrary(): Promise<void> {
    hilog.info(LOG_DOMAIN, LOG_TAG, '开始扫描本地音乐库');

    this._isLoading = true;
    this._errorMessage = null;

    try {
      // 清除缓存并重新扫描
      this.musicService.clearCache();
      const scannedTracks: MusicTrack[] = await this.musicService.scanLibrary();

      this._tracks = scannedTracks;
      this._lastScanTime = Date.now();

      // 应用当前排序
      this.applyCurrentSort();

      hilog.info(LOG_DOMAIN, LOG_TAG, `扫描完成，共 ${this._tracks.length} 首曲目`);

    } catch (error) {
      const err: ErrorObject = error as ErrorObject;

      // 检查是否为权限错误
      if (err.code === LibraryErrorCode.PERMISSION_DENIED) {
        this._errorMessage = getErrorMessage(LibraryErrorCode.PERMISSION_DENIED);
      } else if (err.code === LibraryErrorCode.SCAN_ERROR) {
        this._errorMessage = getErrorMessage(LibraryErrorCode.SCAN_ERROR);
      } else {
        this._errorMessage = err.message !== undefined ? err.message : '扫描音乐库失败';
      }

      hilog.error(LOG_DOMAIN, LOG_TAG, `扫描失败: ${this._errorMessage}`);
    } finally {
      this._isLoading = false;
    }
  }

  /**
   * 按标题排序
   */
  sortByTitle(): void {
    hilog.debug(LOG_DOMAIN, LOG_TAG, '按标题排序');
    this._currentSortType = SortType.TITLE;

    this._tracks.sort((a: MusicTrack, b: MusicTrack): number => {
      return a.title.localeCompare(b.title, 'zh-CN');
    });
  }

  /**
   * 按艺术家排序
   */
  sortByArtist(): void {
    hilog.debug(LOG_DOMAIN, LOG_TAG, '按艺术家排序');
    this._currentSortType = SortType.ARTIST;

    this._tracks.sort((a: MusicTrack, b: MusicTrack): number => {
      // 先按艺术家排序，相同艺术家再按标题排序
      const artistCompare: number = a.artist.localeCompare(b.artist, 'zh-CN');
      if (artistCompare !== 0) {
        return artistCompare;
      }
      return a.title.localeCompare(b.title, 'zh-CN');
    });
  }

  /**
   * 按专辑排序
   */
  sortByAlbum(): void {
    hilog.debug(LOG_DOMAIN, LOG_TAG, '按专辑排序');
    this._currentSortType = SortType.ALBUM;

    this._tracks.sort((a: MusicTrack, b: MusicTrack): number => {
      // 先按专辑排序，相同专辑再按曲目编号或标题排序
      const albumCompare: number = a.album.localeCompare(b.album, 'zh-CN');
      if (albumCompare !== 0) {
        return albumCompare;
      }

      // 相同专辑内按曲目编号排序
      if (a.trackNumber !== undefined && b.trackNumber !== undefined) {
        return a.trackNumber - b.trackNumber;
      }
      if (a.trackNumber !== undefined) {
        return -1;
      }
      if (b.trackNumber !== undefined) {
        return 1;
      }

      // 都没有编号则按标题排序
      return a.title.localeCompare(b.title, 'zh-CN');
    });
  }

  /**
   * 搜索本地音乐
   * @param query 搜索关键词
   * @returns 匹配的音乐曲目列表
   */
  search(query: string): MusicTrack[] {
    // 空查询返回所有曲目
    if (query === null || query === undefined || query.trim() === '') {
      return [...this._tracks];
    }

    const searchTerm: string = query.trim().toLowerCase();
    const results: MusicTrack[] = this._tracks.filter((track: MusicTrack): boolean => {
      // 搜索标题、艺术家、专辑
      const titleMatch: boolean = track.title.toLowerCase().includes(searchTerm);
      const artistMatch: boolean = track.artist.toLowerCase().includes(searchTerm);
      const albumMatch: boolean = track.album.toLowerCase().includes(searchTerm);

      return titleMatch || artistMatch || albumMatch;
    });

    hilog.debug(LOG_DOMAIN, LOG_TAG, `搜索 "${query}" 找到 ${results.length} 条结果`);
    return results;
  }

  /**
   * 根据 ID 获取曲目
   * @param id 曲目 ID
   * @returns 曲目对象，未找到返回 undefined
   */
  getTrackById(id: string): MusicTrack | undefined {
    if (id === null || id === undefined || id.trim() === '') {
      return undefined;
    }

    return this._tracks.find((track: MusicTrack): boolean => {
      return track.id === id;
    });
  }

  /**
   * 刷新音乐库
   * 重新扫描并更新数据
   */
  async refresh(): Promise<void> {
    hilog.info(LOG_DOMAIN, LOG_TAG, '刷新本地音乐库');
    await this.scanMusicLibrary();
  }

  /**
   * 清除错误信息
   */
  clearError(): void {
    this._errorMessage = null;
  }

  /**
   * 应用当前排序
   */
  private applyCurrentSort(): void {
    switch (this._currentSortType) {
      case SortType.TITLE:
        this.sortByTitle();
        break;
      case SortType.ARTIST:
        this.sortByArtist();
        break;
      case SortType.ALBUM:
        this.sortByAlbum();
        break;
      default:
        this.sortByTitle();
        break;
    }
  }

  /**
   * 获取指定艺术家的所有曲目
   * @param artist 艺术家名称
   * @returns 匹配的曲目列表
   */
  getTracksByArtist(artist: string): MusicTrack[] {
    if (artist === null || artist === undefined || artist.trim() === '') {
      return [];
    }

    const searchTerm: string = artist.trim().toLowerCase();
    return this._tracks.filter((track: MusicTrack): boolean => {
      return track.artist.toLowerCase() === searchTerm;
    });
  }

  /**
   * 获取指定专辑的所有曲目
   * @param album 专辑名称
   * @returns 匹配的曲目列表
   */
  getTracksByAlbum(album: string): MusicTrack[] {
    if (album === null || album === undefined || album.trim() === '') {
      return [];
    }

    const searchTerm: string = album.trim().toLowerCase();
    return this._tracks.filter((track: MusicTrack): boolean => {
      return track.album.toLowerCase() === searchTerm;
    });
  }

  /**
   * 获取所有唯一艺术家列表
   * @returns 艺术家名称数组
   */
  getAllArtists(): string[] {
    const artistSet: Set<string> = new Set<string>();

    for (const track of this._tracks) {
      if (track.artist !== null && track.artist !== undefined && track.artist.trim() !== '') {
        artistSet.add(track.artist);
      }
    }

    return Array.from(artistSet).sort((a: string, b: string): number => {
      return a.localeCompare(b, 'zh-CN');
    });
  }

  /**
   * 获取所有唯一专辑列表
   * @returns 专辑名称数组
   */
  getAllAlbums(): string[] {
    const albumSet: Set<string> = new Set<string>();

    for (const track of this._tracks) {
      if (track.album !== null && track.album !== undefined && track.album.trim() !== '') {
        albumSet.add(track.album);
      }
    }

    return Array.from(albumSet).sort((a: string, b: string): number => {
      return a.localeCompare(b, 'zh-CN');
    });
  }
}

/**
 * 导出默认视图模型实例
 */
export const localMusicViewModel: LocalMusicViewModel = new LocalMusicViewModel();
