/**
 * 应用常量定义
 * 遵循华为设计最佳实践
 */

// GLM-5 API 配置接口
export interface GLMApiConfig {
  BASE_URL: string;
  MODEL: string;
  TEMPERATURE: number;
  MAX_TOKENS: number;
  TIMEOUT: number;
}

// 消息配置接口
export interface MessageConfig {
  MAX_CONTENT_LENGTH: number;
  MIN_CONTENT_LENGTH: number;
}

// UI 配置接口（符合 UX 体验标准）
export interface UIConfig {
  MIN_TRANSITION_DURATION: number;
  LONG_PRESS_DURATION: number;
}

// 存储 Keys 接口
export interface StorageKeys {
  API_KEY: string;
  THEME: string;
}

// 错误消息接口
export interface ErrorMessages {
  NETWORK_ERROR: string;
  API_ERROR: string;
  TIMEOUT_ERROR: string;
  INVALID_API_KEY: string;
  EMPTY_MESSAGE: string;
  MESSAGE_TOO_LONG: string;
  API_CONNECTION_ERROR: string;
}

// GLM-5 API 配置 (使用 Anthropic 兼容接口)
export const GLM_API_CONFIG: GLMApiConfig = {
  BASE_URL: 'https://open.bigmodel.cn/api/anthropic',
  MODEL: 'claude-3-5-sonnet-20241022',
  TEMPERATURE: 0.7,
  MAX_TOKENS: 2000,
  TIMEOUT: 30000
};

// 消息配置
export const MESSAGE_CONFIG: MessageConfig = {
  MAX_CONTENT_LENGTH: 2000,
  MIN_CONTENT_LENGTH: 1
};

// UI 配置（符合 UX 体验标准）
export const UI_CONFIG: UIConfig = {
  MIN_TRANSITION_DURATION: 200,
  LONG_PRESS_DURATION: 500
};

// 存储 Keys
export const STORAGE_KEYS: StorageKeys = {
  API_KEY: 'api_key',
  THEME: 'theme'
};

// 错误消息
export const ERROR_MESSAGES: ErrorMessages = {
  NETWORK_ERROR: '网络连接失败，请检查网络设置',
  API_ERROR: 'API 调用失败，请稍后重试',
  TIMEOUT_ERROR: '请求超时，请稍后重试',
  INVALID_API_KEY: 'API Key 无效，请检查配置',
  EMPTY_MESSAGE: '消息内容不能为空',
  MESSAGE_TOO_LONG: '消息长度超过限制（最大 2000 字符）',
  API_CONNECTION_ERROR: 'API 连接失败，请检查网络或重试'
};
