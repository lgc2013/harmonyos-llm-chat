/**
 * 网络电台模型
 * 用于表示 Radio Browser API 返回的电台信息
 *
 * 验证规则：
 * - id 格式：radio_${stationuuid}
 * - url 必须是有效的 HTTPS URL
 * - name 不能为空
 */
export interface RadioStation {
  /** 电台唯一标识符，格式：radio_${stationuuid} */
  id: string;

  /** 电台名称 */
  name: string;

  /** 流媒体播放 URL */
  url: string;

  /** 解析后的实际流媒体 URL（可选） */
  urlResolved?: string;

  /** 电台所在国家名称 */
  country: string;

  /** 国家代码，如 US、CN、JP 等 */
  countryCode: string;

  /** 州/省名称（可选） */
  state?: string;

  /** 电台广播语言（可选） */
  language?: string;

  /** 电台标签/类型列表，如 ['pop', 'rock'] */
  tags: string[];

  /** 用户投票数，用于排序推荐 */
  votes: number;

  /** 累计点击次数 */
  clickCount: number;

  /** 点击趋势，正数表示上升，负数表示下降 */
  clickTrend: number;

  /** 电台图标/Logo URL（可选） */
  favicon?: string;

  /** 电台官方网站 URL（可选） */
  homepage?: string;

  /** 音频编码格式，如 MP3、AAC（可选） */
  codec?: string;

  /** 音频比特率，单位：kbps（可选） */
  bitrate?: number;

  /** 是否为 HLS 流媒体 */
  hls?: boolean;

  /** 电台当前是否在线 */
  isOnline: boolean;

  /** 最后一次在线状态检查时间（可选） */
  lastCheckTime?: string;
}
