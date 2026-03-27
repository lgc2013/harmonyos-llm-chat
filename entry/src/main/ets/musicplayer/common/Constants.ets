/**
 * 音乐播放器常量定义
 * 包含API地址、默认值、限制值、超时时间等常量
 */

/**
 * 网络电台API基础地址
 * 使用 radio-browser.info 公共API
 */
export const RADIO_API_BASE: string = 'https://de1.api.radio-browser.info';

/**
 * 默认音量值
 * 范围: 0.0 - 1.0
 */
export const DEFAULT_VOLUME: number = 0.5;

/**
 * 播放列表最大项数限制
 * 防止播放列表过大导致性能问题
 */
export const MAX_PLAYLIST_ITEMS: number = 500;

/**
 * 播放响应超时时间（毫秒）
 * 等待播放操作完成的最大时间
 */
export const PLAYBACK_RESPONSE_TIMEOUT_MS: number = 500;

/**
 * 跳转容忍时间（毫秒）
 * 跳转操作时允许的时间偏差
 */
export const SEEK_TOLERANCE_MS: number = 1000;

/**
 * 网络请求超时时间（毫秒）
 * HTTP请求的最大等待时间
 */
export const NETWORK_TIMEOUT_MS: number = 30000;

/**
 * 搜索结果数量限制
 * 单次搜索返回的最大结果数
 */
export const SEARCH_RESULT_LIMIT: number = 50;
