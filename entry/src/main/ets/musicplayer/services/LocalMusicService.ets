/**
 * 本地音乐服务
 * 负责扫描、管理和搜索设备本地音乐文件
 *
 * 技术实现：
 * - 使用 PhotoAccessHelper 访问音频媒体文件
 * - 支持格式：MP3、AAC、WAV、FLAC
 * - 按歌曲名排序返回结果
 */

import { photoAccessHelper } from '@kit.MediaLibraryKit';
import { dataSharePredicates } from '@kit.ArkData';
import { MusicTrack, AudioFormat } from '../models/MusicTrack';
import { LibraryErrorCode, createError } from '../common/ErrorCodes';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 日志标签
 */
const LOG_TAG: string = 'LocalMusicService';
const LOG_DOMAIN: number = 0xFF00;

/**
 * 支持的音频文件扩展名
 */
const SUPPORTED_AUDIO_EXTENSIONS: Set<string> = new Set([
  'mp3', 'aac', 'wav', 'flac', 'm4a', 'ogg'
]);

/**
 * 本地音乐服务实现
 * 实现 ILocalMusicLibrary 接口
 */
export class LocalMusicService {
  /** 缓存的音乐列表 */
  private tracks: MusicTrack[] = [];

  /** PhotoAccessHelper 实例 */
  private phAccessHelper: photoAccessHelper.PhotoAccessHelper | null = null;

  /**
   * 初始化 PhotoAccessHelper
   * @returns PhotoAccessHelper 实例
   */
  private async getPhotoAccessHelper(): Promise<photoAccessHelper.PhotoAccessHelper> {
    if (this.phAccessHelper === null) {
      this.phAccessHelper = photoAccessHelper.getPhotoAccessHelper(getContext(this));
    }
    return this.phAccessHelper;
  }

  /**
   * 根据文件扩展名获取音频格式
   * @param extension 文件扩展名
   * @returns 音频格式枚举值
   */
  private getAudioFormat(extension: string): AudioFormat {
    const ext: string = extension.toLowerCase();
    switch (ext) {
      case 'mp3':
        return AudioFormat.MP3;
      case 'aac':
        return AudioFormat.AAC;
      case 'wav':
        return AudioFormat.WAV;
      case 'flac':
        return AudioFormat.FLAC;
      case 'm4a':
        return AudioFormat.M4A;
      case 'ogg':
        return AudioFormat.OGG;
      default:
        return AudioFormat.UNKNOWN;
    }
  }

  /**
   * 生成音乐曲目ID
   * @param filePath 文件路径
   * @returns 唯一ID
   */
  private generateTrackId(filePath: string): string {
    // 使用简单哈希生成ID
    let hash: number = 0;
    for (let i: number = 0; i < filePath.length; i++) {
      const char: number = filePath.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return `local_${Math.abs(hash).toString(16)}`;
  }

  /**
   * 从文件名提取基础名称（不含扩展名）
   * @param fileName 文件名
   * @returns 基础文件名
   */
  private getBaseName(fileName: string): string {
    const lastDot: number = fileName.lastIndexOf('.');
    if (lastDot > 0) {
      return fileName.substring(0, lastDot);
    }
    return fileName;
  }

  /**
   * 扫描本地音乐库
   * @returns 扫描到的音乐曲目列表
   * @throws 权限被拒绝或扫描失败错误
   */
  async scanLibrary(): Promise<MusicTrack[]> {
    hilog.info(LOG_DOMAIN, LOG_TAG, '开始扫描本地音乐库');

    try {
      const phHelper: photoAccessHelper.PhotoAccessHelper = await this.getPhotoAccessHelper();

      // 创建查询谓词，筛选音频文件
      const predicates: dataSharePredicates.DataSharePredicates = new dataSharePredicates.DataSharePredicates();
      predicates.equalTo('media_type', photoAccessHelper.PhotoType.IMAGE);

      // 获取音频文件
      const fetchOptions: photoAccessHelper.FetchOptions = {
        fetchColumns: [
          photoAccessHelper.PhotoKeys.URI,
          photoAccessHelper.PhotoKeys.DISPLAY_NAME,
          photoAccessHelper.PhotoKeys.SIZE,
          photoAccessHelper.PhotoKeys.DATE_ADDED,
          photoAccessHelper.PhotoKeys.DURATION
        ],
        predicates: predicates
      };

      const fetchResult: photoAccessHelper.FetchResult<photoAccessHelper.PhotoAsset> =
        await phHelper.getAssets(fetchOptions);

      hilog.info(LOG_DOMAIN, LOG_TAG, `找到 ${fetchResult.getCount()} 个音频文件`);

      const tracks: MusicTrack[] = [];

      // 遍历所有音频文件
      const assets: photoAccessHelper.PhotoAsset[] = await fetchResult.getAllObjects();

      for (const asset of assets) {
        try {
          const track: MusicTrack | null = await this.parsePhotoAsset(asset);
          if (track !== null) {
            tracks.push(track);
          }
        } catch (error) {
          // 文件解析失败，跳过并记录日志
          const err: Error = error as Error;
          hilog.warn(LOG_DOMAIN, LOG_TAG, `解析文件失败: ${err.message}`);
        }
      }

      // 按歌曲名排序
      tracks.sort((a: MusicTrack, b: MusicTrack): number => {
        return a.title.localeCompare(b.title, 'zh-CN');
      });

      // 更新缓存
      this.tracks = tracks;

      hilog.info(LOG_DOMAIN, LOG_TAG, `扫描完成，共 ${tracks.length} 首有效音乐`);
      return tracks;

    } catch (error) {
      const err: Error = error as Error;
      hilog.error(LOG_DOMAIN, LOG_TAG, `扫描失败: ${err.message}`);

      // 检查是否为权限错误
      const errorInfo = err.message.includes('permission') || err.message.includes('Permission')
        ? createError(LibraryErrorCode.PERMISSION_DENIED)
        : createError(LibraryErrorCode.SCAN_ERROR);

      throw new Error(`[${errorInfo.code}] ${errorInfo.message}`);
    }
  }

  /**
   * 解析 PhotoAsset 为 MusicTrack
   * @param asset 照片/音频资源对象
   * @returns 音乐曲目对象，解析失败返回 null
   */
  private async parsePhotoAsset(asset: photoAccessHelper.PhotoAsset): Promise<MusicTrack | null> {
    const fileName: string = asset.get(photoAccessHelper.PhotoKeys.DISPLAY_NAME) as string;
    const uri: string = asset.get(photoAccessHelper.PhotoKeys.URI) as string;
    const size: number = asset.get(photoAccessHelper.PhotoKeys.SIZE) as number;
    const dateAdded: number = asset.get(photoAccessHelper.PhotoKeys.DATE_ADDED) as number;
    const duration: number = asset.get(photoAccessHelper.PhotoKeys.DURATION) as number;

    // 检查文件扩展名
    const extension: string = this.getFileExtension(fileName);
    if (!SUPPORTED_AUDIO_EXTENSIONS.has(extension)) {
      hilog.debug(LOG_DOMAIN, LOG_TAG, `跳过不支持的格式: ${fileName}`);
      return null;
    }

    // 使用文件名作为标题（实际应用中应解析元数据）
    const title: string = this.getBaseName(fileName);

    const track: MusicTrack = {
      id: this.generateTrackId(uri),
      title: title,
      artist: '未知艺术家',
      album: '未知专辑',
      duration: duration > 0 ? duration : 0,
      filePath: uri,
      fileSize: size,
      format: this.getAudioFormat(extension),
      dateAdded: dateAdded,
      playCount: 0
    };

    return track;
  }

  /**
   * 获取文件扩展名
   * @param fileName 文件名
   * @returns 扩展名（小写）
   */
  private getFileExtension(fileName: string): string {
    const lastDot: number = fileName.lastIndexOf('.');
    if (lastDot > 0 && lastDot < fileName.length - 1) {
      return fileName.substring(lastDot + 1).toLowerCase();
    }
    return '';
  }

  /**
   * 获取所有已扫描的音乐曲目
   * @returns 音乐曲目列表
   */
  async getAllTracks(): Promise<MusicTrack[]> {
    // 如果缓存为空，先执行扫描
    if (this.tracks.length === 0) {
      return await this.scanLibrary();
    }
    return [...this.tracks];
  }

  /**
   * 按艺术家筛选音乐
   * @param artist 艺术家名称
   * @returns 匹配的音乐曲目列表
   */
  async getByArtist(artist: string): Promise<MusicTrack[]> {
    const allTracks: MusicTrack[] = await this.getAllTracks();

    if (artist === null || artist === undefined || artist.trim() === '') {
      return [];
    }

    const searchTerm: string = artist.trim().toLowerCase();
    const results: MusicTrack[] = allTracks.filter((track: MusicTrack): boolean => {
      return track.artist.toLowerCase().includes(searchTerm);
    });

    // 按歌曲名排序
    results.sort((a: MusicTrack, b: MusicTrack): number => {
      return a.title.localeCompare(b.title, 'zh-CN');
    });

    return results;
  }

  /**
   * 按专辑筛选音乐
   * @param album 专辑名称
   * @returns 匹配的音乐曲目列表
   */
  async getByAlbum(album: string): Promise<MusicTrack[]> {
    const allTracks: MusicTrack[] = await this.getAllTracks();

    if (album === null || album === undefined || album.trim() === '') {
      return [];
    }

    const searchTerm: string = album.trim().toLowerCase();
    const results: MusicTrack[] = allTracks.filter((track: MusicTrack): boolean => {
      return track.album.toLowerCase().includes(searchTerm);
    });

    // 按曲目编号排序，没有编号则按歌曲名排序
    results.sort((a: MusicTrack, b: MusicTrack): number => {
      // 优先按曲目编号排序
      if (a.trackNumber !== undefined && b.trackNumber !== undefined) {
        return a.trackNumber - b.trackNumber;
      }
      if (a.trackNumber !== undefined) {
        return -1;
      }
      if (b.trackNumber !== undefined) {
        return 1;
      }
      // 都没有编号则按歌曲名排序
      return a.title.localeCompare(b.title, 'zh-CN');
    });

    return results;
  }

  /**
   * 搜索本地音乐
   * @param query 搜索关键词
   * @returns 匹配的音乐曲目列表
   */
  async search(query: string): Promise<MusicTrack[]> {
    const allTracks: MusicTrack[] = await this.getAllTracks();

    // 空查询返回空数组
    if (query === null || query === undefined || query.trim() === '') {
      return [];
    }

    const searchTerm: string = query.trim().toLowerCase();
    const results: MusicTrack[] = allTracks.filter((track: MusicTrack): boolean => {
      // 搜索标题、艺术家、专辑
      const titleMatch: boolean = track.title.toLowerCase().includes(searchTerm);
      const artistMatch: boolean = track.artist.toLowerCase().includes(searchTerm);
      const albumMatch: boolean = track.album.toLowerCase().includes(searchTerm);

      return titleMatch || artistMatch || albumMatch;
    });

    // 按歌曲名排序
    results.sort((a: MusicTrack, b: MusicTrack): number => {
      return a.title.localeCompare(b.title, 'zh-CN');
    });

    return results;
  }

  /**
   * 清除缓存
   * 用于强制重新扫描
   */
  clearCache(): void {
    this.tracks = [];
    hilog.info(LOG_DOMAIN, LOG_TAG, '已清除本地音乐缓存');
  }

  /**
   * 获取缓存的音乐数量
   * @returns 缓存中的音乐数量
   */
  getCacheCount(): number {
    return this.tracks.length;
  }
}

/**
 * 导出单例实例
 */
export const localMusicService: LocalMusicService = new LocalMusicService();
