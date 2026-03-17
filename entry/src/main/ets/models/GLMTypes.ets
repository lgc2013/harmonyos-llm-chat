/**
 * Anthropic API 类型定义
 * 使用智谱 AI 代理接口
 */

/**
 * Anthropic 消息
 */
export interface AnthropicMessage {
  role: 'user' | 'assistant';
  content: string;
}

/**
 * Anthropic 请求
 */
export interface AnthropicRequest {
  model: string;
  max_tokens: number;
  messages: AnthropicMessage[];
  stream?: boolean;
  temperature?: number;
}

/**
 * Anthropic 响应内容块
 */
export interface AnthropicContentBlock {
  type: string;
  text: string;
}

/**
 * Anthropic 响应
 */
export interface AnthropicResponse {
  id: string;
  type: string;
  role: string;
  model: string;
  content: AnthropicContentBlock[];
  stop_reason: string | null;
  stop_sequence: string | null;
}

// 兼容旧类型名称
export type GLMMessage = AnthropicMessage;
export type GLMRequest = AnthropicRequest;
export type GLMResponse = AnthropicResponse;
