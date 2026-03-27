/**
 * 音频URL解析服务
 * 用于解析 music.163.com 等音乐平台的外链URL
 * 获取真实可播放的音频地址
 */
import http from '@ohos.net.http';

/**
 * 解析结果
 */
export interface ResolvedUrl {
  /** 原始URL */
  originalUrl: string;
  /** 解析后的真实URL */
  resolvedUrl: string;
  /** 内容类型 */
  contentType: string;
  /** 是否为有效的音频 */
  isValidAudio: boolean;
  /** 错误信息（如果有） */
  error?: string;
}

/**
 * 重定向检查结果
 */
interface RedirectResult {
  /** 重定向URL */
  redirectUrl: string;
  /** 内容类型 */
  contentType: string;
}

/**
 * 音频URL解析器
 * 处理音乐平台外链URL的重定向和格式验证
 */
class AudioUrlResolver {
  private readonly audioContentTypes: string[] = [
    'audio/mpeg',
    'audio/mp3',
    'audio/x-mpeg',
    'audio/x-mpeg-3',
    'audio/mpeg3',
    'audio/mp4',
    'audio/aac',
    'audio/x-aac',
    'audio/ogg',
    'audio/wav',
    'audio/x-wav',
    'audio/flac',
    'application/octet-stream'
  ];

  private readonly audioExtensions: string[] = [
    '.mp3',
    '.m4a',
    '.aac',
    '.ogg',
    '.wav',
    '.flac',
    '.m3u8'
  ];

  /**
   * 解析音频URL
   * 跟随HTTP重定向获取真实的音频地址
   * 注意：不再从HTML页面提取URL，因为那样会提取到错误的音频
   * @param url 原始URL
   * @param timeoutMs 超时时间（毫秒）
   */
  async resolveAudioUrl(url: string, timeoutMs: number = 10000): Promise<ResolvedUrl> {
    console.info(`[AudioUrlResolver] 开始解析URL: ${url}`);

    const result: ResolvedUrl = {
      originalUrl: url,
      resolvedUrl: url,
      contentType: '',
      isValidAudio: false
    };

    try {
      // 第一步：获取重定向信息（只使用HEAD请求检查重定向）
      const redirectResult = await this.checkRedirect(url, timeoutMs);

      if (redirectResult.redirectUrl && redirectResult.redirectUrl.length > 0) {
        // 有重定向，使用重定向后的URL
        console.info(`[AudioUrlResolver] 重定向到: ${redirectResult.redirectUrl}`);
        result.resolvedUrl = redirectResult.redirectUrl;
        result.contentType = redirectResult.contentType;

        // 验证重定向URL是否为音频
        if (this.hasAudioExtension(redirectResult.redirectUrl) ||
            this.isValidContentType(redirectResult.contentType)) {
          result.isValidAudio = true;
          console.info(`[AudioUrlResolver] 重定向URL是有效音频`);
        } else {
          // 重定向后的URL也不是音频，可能受版权限制
          // 直接使用原始URL，让AVPlayer尝试播放
          console.warn(`[AudioUrlResolver] 重定向URL非音频格式，使用原始URL尝试播放`);
          result.resolvedUrl = url;
          result.isValidAudio = true; // 允许尝试播放
          result.contentType = 'audio/mpeg';
        }
      } else {
        // 没有重定向，检查Content-Type是否为音频
        result.resolvedUrl = url;
        result.contentType = redirectResult.contentType || '';
        console.info(`[AudioUrlResolver] 无重定向，Content-Type: ${result.contentType}`);

        // 检查是否为HTML页面（版权限制的歌曲会返回HTML）
        const lowerContentType = result.contentType.toLowerCase();
        if (lowerContentType.includes('text/html')) {
          // 返回HTML页面，说明歌曲受版权限制无法播放
          result.isValidAudio = false;
          result.error = '该歌曲受版权限制，无法播放';
          console.warn(`[AudioUrlResolver] 检测到HTML内容，歌曲可能受版权限制`);
        } else if (this.isValidContentType(result.contentType)) {
          // Content-Type是有效音频类型
          result.isValidAudio = true;
          console.info(`[AudioUrlResolver] Content-Type验证通过，是有效音频`);
        } else if (this.hasAudioExtension(url)) {
          // URL包含音频扩展名，即使HEAD超时也允许尝试
          result.isValidAudio = true;
          result.contentType = this.guessContentTypeFromUrl(url);
          console.info(`[AudioUrlResolver] URL包含音频扩展名，将尝试播放`);
        } else {
          // 未知类型，尝试播放（可能是application/octet-stream等）
          result.isValidAudio = true;
          console.info(`[AudioUrlResolver] 未知Content-Type，将尝试播放`);
        }
      }

      console.info(`[AudioUrlResolver] 解析完成: ${url} -> ${result.resolvedUrl}, valid: ${result.isValidAudio}`);
    } catch (error) {
      const err = error as Error;
      result.error = err.message;
      // 即使出错，也允许尝试播放原始URL
      result.resolvedUrl = url;
      result.isValidAudio = true;
      console.error(`[AudioUrlResolver] 解析失败: ${err.message}，将使用原始URL尝试播放`);
    }

    return result;
  }

  /**
   * 根据URL扩展名猜测Content-Type
   */
  private guessContentTypeFromUrl(url: string): string {
    const lowerUrl = url.toLowerCase();
    if (lowerUrl.includes('.mp3')) {
      return 'audio/mpeg';
    } else if (lowerUrl.includes('.m4a')) {
      return 'audio/mp4';
    } else if (lowerUrl.includes('.aac')) {
      return 'audio/aac';
    } else if (lowerUrl.includes('.ogg')) {
      return 'audio/ogg';
    } else if (lowerUrl.includes('.wav')) {
      return 'audio/wav';
    } else if (lowerUrl.includes('.flac')) {
      return 'audio/flac';
    } else if (lowerUrl.includes('.m3u8')) {
      return 'application/x-mpegURL';
    }
    return 'audio/mpeg'; // 默认
  }

  /**
   * 检查URL重定向（使用HEAD请求，不下载内容）
   */
  private async checkRedirect(url: string, timeoutMs: number): Promise<RedirectResult> {
    const httpRequest = http.createHttp();

    try {
      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.HEAD, // 使用HEAD方法，只获取头部信息
        header: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': '*/*',
          'Accept-Encoding': 'identity',
          'Accept-Language': 'zh-CN,zh;q=0.9',
          'Referer': 'https://music.163.com/'
        },
        connectTimeout: timeoutMs,
        readTimeout: timeoutMs
      };

      const response = await httpRequest.request(url, options);
      const responseCode = response.responseCode;

      console.info(`[AudioUrlResolver] HEAD请求响应状态码: ${responseCode}`);

      let redirectUrl = '';
      let contentType = '';

      // 解析响应头
      const headerStr = JSON.stringify(response.header);

      // 获取Content-Type
      const contentTypeMatch = headerStr.match(/"Content-Type"\s*:\s*"([^"]+)"/i);
      if (contentTypeMatch && contentTypeMatch[1]) {
        contentType = contentTypeMatch[1];
        console.info(`[AudioUrlResolver] Content-Type: ${contentType}`);
      }

      // 检查重定向 (3xx 状态码)
      if (responseCode >= 300 && responseCode < 400) {
        const locationMatch = headerStr.match(/"Location"\s*:\s*"([^"]+)"/i);
        if (locationMatch && locationMatch[1]) {
          redirectUrl = locationMatch[1];
          console.info(`[AudioUrlResolver] 发现重定向: ${redirectUrl}`);

          // 检测404重定向（版权限制的歌曲会重定向到404页面）
          if (redirectUrl.includes('/404') || redirectUrl.includes('404')) {
            console.warn(`[AudioUrlResolver] 检测到404重定向，歌曲可能受版权限制`);
            httpRequest.destroy();
            const errorResult: RedirectResult = {
              redirectUrl: '',
              contentType: 'text/html' // 标记为无效
            };
            return errorResult;
          }
        }
      }

      httpRequest.destroy();

      const result: RedirectResult = {
        redirectUrl: redirectUrl,
        contentType: contentType
      };
      return result;
    } catch (error) {
      httpRequest.destroy();
      const err = error as Error;
      console.warn(`[AudioUrlResolver] HEAD请求失败: ${err.message}`);
      // HEAD请求失败时，返回空结果但标记为可尝试播放
      // 让调用方决定是否继续
      const emptyResult: RedirectResult = {
        redirectUrl: '',
        contentType: ''
      };
      return emptyResult;
    }
  }

  /**
   * 检查Content-Type是否为有效音频类型
   */
  private isValidContentType(contentType: string): boolean {
    if (!contentType || contentType.length === 0) {
      return false;
    }
    const lowerType = contentType.toLowerCase();
    for (let i = 0; i < this.audioContentTypes.length; i++) {
      if (lowerType.includes(this.audioContentTypes[i].toLowerCase())) {
        return true;
      }
    }
    return false;
  }

  /**
   * 检查URL是否包含音频扩展名
   */
  private hasAudioExtension(url: string): boolean {
    const lowerUrl = url.toLowerCase();
    for (let i = 0; i < this.audioExtensions.length; i++) {
      if (lowerUrl.includes(this.audioExtensions[i])) {
        return true;
      }
    }
    return false;
  }

  /**
   * 构建网易云音乐外链URL
   */
  buildNeteaseUrl(songId: number): string {
    return `https://music.163.com/song/media/outer/url?id=${songId}.mp3`;
  }

  /**
   * 构建网易云音乐高音质外链URL
   * @param songId 歌曲ID
   * @param quality 音质 (standard/higher/exhigh/hires)
   */
  buildNeteaseUrlWithQuality(songId: number, quality: string = 'standard'): string {
    return `https://music.163.com/song/media/outer/url?id=${songId}&br=${quality}.mp3`;
  }
}

const audioUrlResolver = new AudioUrlResolver();
export default audioUrlResolver;
