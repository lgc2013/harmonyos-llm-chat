/**
 * 网络电台服务
 * 基于 Radio Browser API 实现网络电台搜索和获取功能
 *
 * API 文档: https://de1.api.radio-browser.info
 */
import http from '@ohos.net.http';
import { RadioStation } from '../models/RadioStation';
import { RADIO_API_BASE, NETWORK_TIMEOUT_MS } from '../common/Constants';
import { RadioErrorCode } from '../common/ErrorCodes';

/**
 * 国家信息接口
 * 用于获取可用国家列表
 */
export interface CountryInfo {
  /** 国家名称 */
  name: string;
  /** ISO 国家代码 */
  isoCode: string;
  /** 该国家的电台数量 */
  stationCount: number;
}

/**
 * 类型标签信息接口
 * 用于获取可用的电台类型标签
 */
export interface TagInfo {
  /** 标签名称 */
  name: string;
  /** 该标签下的电台数量 */
  stationCount: number;
}

/**
 * Radio Browser API 返回的原始电台数据格式
 */
interface RawRadioStation {
  stationuuid: string;
  name: string;
  url: string;
  url_resolved?: string;
  country: string;
  countrycode: string;
  state?: string;
  language?: string;
  tags: string;
  votes: number;
  clickcount: number;
  clicktrend: number;
  favicon?: string;
  homepage?: string;
  codec?: string;
  bitrate?: number;
  hls: number;
  lastcheckok: number;
  lastchecktime?: string;
}

/**
 * Radio Browser API 返回的原始国家数据格式
 */
interface RawCountry {
  name: string;
  iso_3166_1: string;
  stationcount: number;
}

/**
 * Radio Browser API 返回的原始标签数据格式
 */
interface RawTag {
  name: string;
  stationcount: number;
}

/**
 * 电台服务错误
 */
export class RadioServiceError extends Error {
  code: RadioErrorCode;

  constructor(code: RadioErrorCode, message: string) {
    super(message);
    this.code = code;
    this.name = 'RadioServiceError';
  }
}

/**
 * 网络电台服务类
 * 实现 IRadioService 接口，提供电台搜索和获取功能
 */
class RadioService {
  /** 基础 API URL */
  private readonly baseUrl: string = RADIO_API_BASE;

  /** 请求超时时间（毫秒） */
  private readonly timeout: number = NETWORK_TIMEOUT_MS;

  /** User-Agent 头 */
  private readonly userAgent: string = 'HarmonyOS-MusicPlayer/1.0';

  /**
   * 发送 HTTP GET 请求
   * @param endpoint API 端点路径
   * @returns 响应数据
   */
  private async httpGet<T>(endpoint: string): Promise<T> {
    const httpRequest = http.createHttp();
    const url: string = this.baseUrl + endpoint;

    console.info(`[RadioService] 发起请求: ${url}`);

    const options: http.HttpRequestOptions = {
      method: http.RequestMethod.GET,
      header: {
        'User-Agent': this.userAgent,
        'Accept': 'application/json'
      },
      connectTimeout: this.timeout,
      readTimeout: this.timeout
    };

    try {
      const response = await httpRequest.request(url, options);
      const responseCode = response.responseCode;

      console.info(`[RadioService] 响应状态码: ${responseCode}`);

      if (responseCode !== 200) {
        httpRequest.destroy();
        const errorMsg = `HTTP 请求失败，状态码: ${responseCode}`;
        console.error(`[RadioService] ${errorMsg}`);
        throw new RadioServiceError(
          RadioErrorCode.RADIO_NETWORK_ERROR,
          errorMsg
        );
      }

      const result = response.result as string;
      if (!result) {
        httpRequest.destroy();
        console.error('[RadioService] 响应数据为空');
        throw new RadioServiceError(
          RadioErrorCode.RADIO_NETWORK_ERROR,
          '响应数据为空'
        );
      }

      console.info(`[RadioService] 响应数据长度: ${result.length}`);

      try {
        const data: T = JSON.parse(result) as T;
        httpRequest.destroy();
        console.info(`[RadioService] JSON 解析成功`);
        return data;
      } catch (parseError) {
        httpRequest.destroy();
        console.error(`[RadioService] JSON 解析失败: ${(parseError as Error).message}`);
        throw new RadioServiceError(
          RadioErrorCode.RADIO_NETWORK_ERROR,
          'JSON 解析失败'
        );
      }
    } catch (error) {
      httpRequest.destroy();

      // 如果已经是 RadioServiceError，直接抛出
      if (error instanceof RadioServiceError) {
        throw error;
      }

      // 检查是否为超时错误
      const err = error as Error;
      console.error(`[RadioService] 请求异常: ${err.message}`);

      if (err.message.includes('timeout') || err.message.includes('Timeout')) {
        throw new RadioServiceError(
          RadioErrorCode.RADIO_TIMEOUT,
          '请求超时'
        );
      }

      throw new RadioServiceError(
        RadioErrorCode.RADIO_NETWORK_ERROR,
        `网络错误: ${err.message}`
      );
    }
  }

  /**
   * 将原始电台数据转换为 RadioStation 模型
   * @param raw 原始数据
   * @returns RadioStation 模型
   */
  private mapToRadioStation(raw: RawRadioStation): RadioStation {
    // 解析标签字符串（逗号分隔）
    let tags: string[] = [];
    if (raw.tags && raw.tags.length > 0) {
      tags = raw.tags.split(',').filter((tag: string) => tag.trim().length > 0);
    }

    return {
      id: `radio_${raw.stationuuid}`,
      name: raw.name || 'Unknown Station',
      url: raw.url || '',
      urlResolved: raw.url_resolved,
      country: raw.country || '',
      countryCode: raw.countrycode || '',
      state: raw.state,
      language: raw.language,
      tags: tags,
      votes: raw.votes || 0,
      clickCount: raw.clickcount || 0,
      clickTrend: raw.clicktrend || 0,
      favicon: raw.favicon,
      homepage: raw.homepage,
      codec: raw.codec,
      bitrate: raw.bitrate,
      hls: raw.hls === 1,
      isOnline: raw.lastcheckok === 1,
      lastCheckTime: raw.lastchecktime
    };
  }

  /**
   * 获取热门电台列表
   * @param limit 返回数量，默认 100
   * @returns 电台列表
   */
  async getTopStations(limit: number = 100): Promise<RadioStation[]> {
    const safeLimit: number = Math.max(1, Math.min(limit, 1000));
    const endpoint: string = `/json/stations/topvote/${safeLimit}`;

    const rawData: RawRadioStation[] = await this.httpGet<RawRadioStation[]>(endpoint);

    const stations: RadioStation[] = [];
    for (let i = 0; i < rawData.length; i++) {
      stations.push(this.mapToRadioStation(rawData[i]));
    }

    return stations;
  }

  /**
   * 按国家获取电台
   * @param country 国家名称或代码
   * @param limit 返回数量，默认 50
   * @returns 电台列表
   */
  async getByCountry(country: string, limit: number = 50): Promise<RadioStation[]> {
    if (!country || country.trim().length === 0) {
      return [];
    }

    const safeLimit: number = Math.max(1, Math.min(limit, 1000));
    const encodedCountry: string = encodeURIComponent(country.trim());
    const endpoint: string = `/json/stations/bycountry/${encodedCountry}?limit=${safeLimit}`;

    const rawData: RawRadioStation[] = await this.httpGet<RawRadioStation[]>(endpoint);

    const stations: RadioStation[] = [];
    for (let i = 0; i < rawData.length; i++) {
      stations.push(this.mapToRadioStation(rawData[i]));
    }

    return stations;
  }

  /**
   * 按类型标签获取电台
   * @param tag 类型标签
   * @param limit 返回数量，默认 50
   * @returns 电台列表
   */
  async getByTag(tag: string, limit: number = 50): Promise<RadioStation[]> {
    if (!tag || tag.trim().length === 0) {
      return [];
    }

    const safeLimit: number = Math.max(1, Math.min(limit, 1000));
    const encodedTag: string = encodeURIComponent(tag.trim());
    const endpoint: string = `/json/stations/bytag/${encodedTag}?limit=${safeLimit}`;

    const rawData: RawRadioStation[] = await this.httpGet<RawRadioStation[]>(endpoint);

    const stations: RadioStation[] = [];
    for (let i = 0; i < rawData.length; i++) {
      stations.push(this.mapToRadioStation(rawData[i]));
    }

    return stations;
  }

  /**
   * 搜索电台
   * @param query 搜索关键词
   * @param limit 返回数量，默认 50
   * @returns 电台列表
   */
  async search(query: string, limit: number = 50): Promise<RadioStation[]> {
    if (!query || query.trim().length < 2) {
      return [];
    }

    const safeLimit: number = Math.max(1, Math.min(limit, 1000));
    const encodedQuery: string = encodeURIComponent(query.trim());
    const endpoint: string = `/json/stations/search?name=${encodedQuery}&limit=${safeLimit}`;

    const rawData: RawRadioStation[] = await this.httpGet<RawRadioStation[]>(endpoint);

    const stations: RadioStation[] = [];
    for (let i = 0; i < rawData.length; i++) {
      stations.push(this.mapToRadioStation(rawData[i]));
    }

    return stations;
  }

  /**
   * 获取所有可用国家列表
   * @returns 国家信息列表
   */
  async getCountries(): Promise<CountryInfo[]> {
    const endpoint: string = '/json/countries';
    const rawData: RawCountry[] = await this.httpGet<RawCountry[]>(endpoint);

    const countries: CountryInfo[] = [];
    for (let i = 0; i < rawData.length; i++) {
      const item: RawCountry = rawData[i];
      countries.push({
        name: item.name || '',
        isoCode: item.iso_3166_1 || '',
        stationCount: item.stationcount || 0
      });
    }

    // 按电台数量降序排序
    countries.sort((a: CountryInfo, b: CountryInfo) => b.stationCount - a.stationCount);

    return countries;
  }

  /**
   * 获取所有可用类型标签列表
   * @returns 标签信息列表
   */
  async getTags(): Promise<TagInfo[]> {
    const endpoint: string = '/json/tags';
    const rawData: RawTag[] = await this.httpGet<RawTag[]>(endpoint);

    const tags: TagInfo[] = [];
    for (let i = 0; i < rawData.length; i++) {
      const item: RawTag = rawData[i];
      tags.push({
        name: item.name || '',
        stationCount: item.stationcount || 0
      });
    }

    // 按电台数量降序排序
    tags.sort((a: TagInfo, b: TagInfo) => b.stationCount - a.stationCount);

    return tags;
  }
}

// 导出单例实例
const radioService = new RadioService();
export default radioService;

// 同时导出类以便测试
export { RadioService };
