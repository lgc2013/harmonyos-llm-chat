/**
 * 音乐服务（支持英语听力音频）
 *
 * 支持功能：
 * - 搜索歌曲（按关键词）
 * - 获取热门歌曲
 * - 获取歌曲播放URL
 *
 * 默认音频源：
 * - LibriVox 公共领域有声读物（英语短篇故事）
 * - 网易云音乐外链（搜索功能）
 *
 * 注意：默认列表使用 LibriVox 英语听力音频，搜索功能仍使用网易云音乐API
 */
import http from '@ohos.net.http';
import { MusicTrack } from '../models/MusicTrack';
import { AudioFormat } from '../models/MusicTrack';
import { NETWORK_TIMEOUT_MS } from '../common/Constants';

/**
 * 网易云音乐歌曲接口
 */
export interface NeteaseSong {
  id: number;
  name: string;
  artists: NeteaseArtist[];
  album: NeteaseAlbum;
  duration: number;
  /** 直接播放URL（可选） */
  playUrl?: string;
}

/**
 * 网易云音乐艺术家接口
 */
export interface NeteaseArtist {
  id: number;
  name: string;
}

/**
 * 网易云音乐专辑接口
 */
export interface NeteaseAlbum {
  id: number;
  name: string;
  picUrl: string;
}

/**
 * API响应中的艺术家数据
 */
interface ApiArtist {
  id: number;
  name: string;
}

/**
 * API响应中的专辑数据
 */
interface ApiAlbum {
  id: number;
  name: string;
  picUrl: string;
}

/**
 * API响应中的歌曲数据
 */
interface ApiSong {
  id: number;
  name: string;
  ar: ApiArtist[];
  al: ApiAlbum;
  dt: number;
}

/**
 * 推荐歌曲内部数据（用于RecommendSongItem）
 */
interface RecommendSongData {
  id: number;
  name: string;
  ar: ApiArtist[];
  al: ApiAlbum;
  dt: number;
}

/**
 * 推荐歌曲API响应中的歌曲项
 */
interface RecommendSongItem {
  id: number;
  name: string;
  song: RecommendSongData;
}

/**
 * 推荐歌曲API响应
 */
interface RecommendSongsResponse {
  result: RecommendSongItem[];
}

/**
 * 搜索结果数据
 */
interface SearchResultData {
  songs: ApiSong[];
}

/**
 * 搜索结果API响应
 */
interface SearchResponse {
  result: SearchResultData;
}

/**
 * 默认歌曲数据结构
 */
interface DefaultSongData {
  id: number;
  name: string;
  artist: string;
  album: string;
  duration: number;
  url: string;
}

/**
 * 网易云音乐服务类
 */
class NeteaseMusicService {
  private baseUrl: string = 'https://netease-cloud-music-api-five-roan-88.vercel.app';
  private timeout: number = NETWORK_TIMEOUT_MS;

  /**
   * 发送HTTP GET请求
   */
  private async httpGet(endpoint: string): Promise<string> {
    const httpRequest = http.createHttp();
    const url: string = this.baseUrl + endpoint;

    console.info(`[NeteaseMusic] 请求: ${url}`);

    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      header: {
        'User-Agent': 'HarmonyOS-MusicPlayer/1.0',
        'Accept': 'application/json'
      },
      connectTimeout: this.timeout,
      readTimeout: this.timeout
    };

    const response = await httpRequest.request(url, options);
    const responseCode = response.responseCode;

    console.info(`[NeteaseMusic] 响应状态码: ${responseCode}`);

    if (responseCode !== 200) {
      httpRequest.destroy();
      throw new Error('HTTP请求失败: 状态码: ' + responseCode);
    }

    const result = response.result as string;
    if (!result) {
      httpRequest.destroy();
      throw new Error('响应数据为空');
    }

    console.info(`[NeteaseMusic] 响应数据长度: ${result.length}`);
    httpRequest.destroy();
    return result;
  }

  /**
   * 获取热门歌曲
   * 调用网易云音乐推荐新歌API
   * @param limit 返回歌曲数量限制
   */
  async getHotSongs(limit: number = 50): Promise<NeteaseSong[]> {
    console.info(`[NeteaseMusic] 获取热门歌曲, limit: ${limit}`);

    try {
      // 使用推荐新歌API：/personalized/newsong
      const responseText = await this.httpGet('/personalized/newsong?limit=' + limit);
      const response: RecommendSongsResponse = JSON.parse(responseText) as RecommendSongsResponse;

      if (!response.result || response.result.length === 0) {
        console.warn('[NeteaseMusic] API返回空结果，使用默认歌曲');
        return this.getDefaultSongs();
      }

      const songs: NeteaseSong[] = [];
      const results = response.result;

      for (let i = 0; i < results.length; i++) {
        const item = results[i];
        if (item.song) {
          // 推荐歌曲的song字段与ApiSong结构相同
          const songData: ApiSong = {
            id: item.song.id,
            name: item.song.name,
            ar: item.song.ar,
            al: item.song.al,
            dt: item.song.dt
          };
          songs.push(this.parseSong(songData));
        }
      }

      console.info(`[NeteaseMusic] 成功获取 ${songs.length} 首热门歌曲`);
      return songs;
    } catch (error) {
      const err: Error = error as Error;
      console.error(`[NeteaseMusic] 获取热门歌曲失败: ${err.message}`);
      // 失败时返回默认歌曲
      return this.getDefaultSongs();
    }
  }

  /**
   * 搜索歌曲
   * 调用网易云音乐搜索API
   * @param keyword 搜索关键词
   * @param limit 返回结果数量限制
   */
  async searchSongs(keyword: string, limit: number = 30): Promise<NeteaseSong[]> {
    if (!keyword || keyword.trim().length === 0) {
      return [];
    }

    const encodedKeyword = encodeURIComponent(keyword.trim());
    console.info(`[NeteaseMusic] 搜索歌曲: ${keyword}`);

    try {
      // 使用搜索API：/search?keywords=xxx
      const responseText = await this.httpGet('/search?keywords=' + encodedKeyword + '&limit=' + limit);
      const response: SearchResponse = JSON.parse(responseText) as SearchResponse;

      if (!response.result || !response.result.songs || response.result.songs.length === 0) {
        console.warn('[NeteaseMusic] 搜索无结果');
        return [];
      }

      const songs: NeteaseSong[] = [];
      const songList = response.result.songs;

      for (let i = 0; i < songList.length; i++) {
        songs.push(this.parseSong(songList[i]));
      }

      console.info(`[NeteaseMusic] 搜索成功，找到 ${songs.length} 首歌曲`);
      return songs;
    } catch (error) {
      const err: Error = error as Error;
      console.error(`[NeteaseMusic] 搜索失败: ${err.message}`);
      return [];
    }
  }

  /**
   * 解析歌曲数据
   */
  private parseSong(data: ApiSong): NeteaseSong {
    const id: number = data.id;
    const name: string = data.name || '未知歌曲';

    // 解析艺术家
    const artists: NeteaseArtist[] = [];
    const artistList = data.ar;
    if (artistList) {
      for (let i = 0; i < artistList.length; i++) {
        const artistData = artistList[i];
        artists.push({
          id: artistData.id,
          name: artistData.name || '未知艺术家'
        });
      }
    }

    // 解析专辑
    let album: NeteaseAlbum = {
      id: 0,
      name: '未知专辑',
      picUrl: ''
    };
    if (data.al) {
      album = {
        id: data.al.id,
        name: data.al.name || '未知专辑',
        picUrl: data.al.picUrl || ''
      };
    }

    return {
      id: id,
      name: name,
      artists: artists,
      album: album,
      duration: data.dt || 0
    };
  }

  /**
   * 获取歌曲播放URL
   * 使用网易云音乐外链地址
   */
  getSongUrl(songId: number): string {
    return 'https://music.163.com/song/media/outer/url?id=' + songId + '.mp3';
  }

  /**
   * 转换为MusicTrack
   */
  convertToMusicTrack(song: NeteaseSong): MusicTrack {
    const artistNames = song.artists.map(a => a.name).join(', ');

    // 如果有直接播放URL，优先使用，否则使用网易云外链
    const playUrl = song.playUrl || this.getSongUrl(song.id);

    const track: MusicTrack = {
      id: 'netease_' + song.id,
      title: song.name,
      artist: artistNames || '未知艺术家',
      album: song.album?.name || '未知专辑',
      duration: song.duration || 0,
      filePath: playUrl,
      fileSize: 0,
      format: AudioFormat.MP3,
      albumArt: song.album?.picUrl || '',
      dateAdded: Date.now(),
      playCount: 0
    };

    return track;
  }

  /**
   * 获取默认歌曲列表（备用）
   * 使用多个可靠的网络音频源：
   * - SoundHelix: 免费测试音乐（德国服务器，CDN加速）
   * - Pixabay: 免费音乐素材
   *
   * 注意：archive.org 在中国大陆访问可能较慢，暂时替换为其他源
   */
  private getDefaultSongs(): NeteaseSong[] {
    // 使用 SoundHelix 等可靠的测试音频源
    const defaultSongsData: DefaultSongData[] = [
      // SoundHelix 测试音乐 - 免费、稳定、全球CDN加速
      { id: 1001, name: 'Ambient Motivation', artist: 'Lesfm', album: 'Test Music', duration: 180000, url: 'https://cdn.pixabay.com/download/audio/2022/05/27/audio_1808fbf07a.mp3?filename=ambient-motivation-soundplate-main-version-02-58-39969.mp3' },
      { id: 1002, name: 'Good Night', artist: 'FASSounds', album: 'Test Music', duration: 90000, url: 'https://cdn.pixabay.com/download/audio/2022/10/25/audio_946bc3eb81.mp3?filename=good-night-160166.mp3' },
      { id: 1003, name: 'Lofi Study', artist: 'FASSounds', album: 'Test Music', duration: 120000, url: 'https://cdn.pixabay.com/download/audio/2022/05/16/audio_1333dfb51b.mp3?filename=lofi-study-112191.mp3' },
      { id: 1004, name: 'Relaxing', artist: 'SergePavkinMusic', album: 'Test Music', duration: 90000, url: 'https://cdn.pixabay.com/download/audio/2022/11/10/audio_946bcfa63e.mp3?filename=relaxing-145038.mp3' },
      { id: 1005, name: 'Acoustic Breeze', artist: 'Benjamin Tissot', album: 'Test Music', duration: 130000, url: 'https://cdn.pixabay.com/download/audio/2022/03/10/audio_c8c8a73467.mp3?filename=acoustic-breeze-118216.mp3' },
      // SoundHelix 备用 - 非常稳定的测试音乐
      { id: 2001, name: 'Test Track 1', artist: 'SoundHelix', album: 'SoundHelix Test', duration: 220000, url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3' },
      { id: 2002, name: 'Test Track 2', artist: 'SoundHelix', album: 'SoundHelix Test', duration: 360000, url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3' },
      { id: 2003, name: 'Test Track 3', artist: 'SoundHelix', album: 'SoundHelix Test', duration: 300000, url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3' },
      { id: 2004, name: 'Test Track 4', artist: 'SoundHelix', album: 'SoundHelix Test', duration: 280000, url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3' },
      { id: 2005, name: 'Test Track 5', artist: 'SoundHelix', album: 'SoundHelix Test', duration: 340000, url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3' },
      { id: 2006, name: 'Test Track 6', artist: 'SoundHelix', album: 'SoundHelix Test', duration: 320000, url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3' },
      { id: 2007, name: 'Test Track 7', artist: 'SoundHelix', album: 'SoundHelix Test', duration: 380000, url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3' },
      { id: 2008, name: 'Test Track 8', artist: 'SoundHelix', album: 'SoundHelix Test', duration: 260000, url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3' },
    ];

    const defaultSongs: NeteaseSong[] = [];

    for (let i = 0; i < defaultSongsData.length; i++) {
      const songData = defaultSongsData[i];
      defaultSongs.push({
        id: songData.id,
        name: songData.name,
        artists: [{ id: 0, name: songData.artist }],
        album: { id: 0, name: songData.album, picUrl: '' },
        duration: songData.duration,
        playUrl: songData.url
      });
    }

    console.info(`[NeteaseMusic] 创建了 ${defaultSongs.length} 个测试音频（SoundHelix + Pixabay）`);
    return defaultSongs;
  }
}

const neteaseMusicService = new NeteaseMusicService();
export default neteaseMusicService;
