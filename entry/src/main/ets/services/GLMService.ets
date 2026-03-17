/**
 * GLM Service - Anthropic API 兼容接口
 * 遵循华为 UX 体验标准
 */
import http from '@ohos.net.http';
import { AnthropicRequest, AnthropicMessage, AnthropicResponse, AnthropicContentBlock } from '../models/GLMTypes';
import { GLM_API_CONFIG, ERROR_MESSAGES } from '../common/constants/Constants';
import Logger from '../common/utils/Logger';

/**
 * 流式响应回调类型
 */
export type OnChunkCallback = (content: string) => void;
export type OnCompleteCallback = () => void;
export type OnErrorCallback = (error: Error) => void;

/**
 * API 错误响应接口
 */
interface ApiErrorResponse {
  error?: ApiErrorDetail;
  msg?: string;
  message?: string;
}

/**
 * API 错误详情接口
 */
interface ApiErrorDetail {
  message: string;
  type?: string;
}

/**
 * GLM 服务类
 */
class GLMService {
  private apiKey: string = '';
  private isCancelled: boolean = false;

  /**
   * 设置 API Key
   */
  setApiKey(key: string): void {
    this.apiKey = key;
    Logger.info('API Key set, length: ' + key.length);
  }

  /**
   * 获取 API Key
   */
  getApiKey(): string {
    return this.apiKey;
  }

  /**
   * 验证 API Key 格式
   */
  validateApiKeyFormat(key: string): boolean {
    if (!key || key.trim().length === 0) {
      return false;
    }
    return key.length >= 20;
  }

  /**
   * 发送消息并获取响应
   */
  async sendMessage(
    message: string,
    onChunk: OnChunkCallback,
    onComplete: OnCompleteCallback,
    onError: OnErrorCallback,
    history: AnthropicMessage[] = []
  ): Promise<void> {
    this.isCancelled = false;
    Logger.info('sendMessage called, message: ' + message.length + ' chars, history: ' + history.length + ' msgs');

    if (!this.apiKey) {
      Logger.error('API Key is empty');
      onError(new Error(ERROR_MESSAGES.INVALID_API_KEY));
      return;
    }

    try {
      const httpRequest = http.createHttp();
      const url = GLM_API_CONFIG.BASE_URL + '/v1/messages';

      // 构建消息数组
      const messages: AnthropicMessage[] = [];
      for (let i = 0; i < history.length; i++) {
        messages.push(history[i]);
      }
      messages.push({ role: 'user', content: message });

      const requestBody: AnthropicRequest = {
        model: GLM_API_CONFIG.MODEL,
        max_tokens: GLM_API_CONFIG.MAX_TOKENS,
        messages: messages,
        stream: false,
        temperature: GLM_API_CONFIG.TEMPERATURE
      };

      const requestBodyStr = JSON.stringify(requestBody);
      Logger.info('Request URL: ' + url);
      Logger.info('Request body: ' + requestBodyStr.length + ' bytes');

      const headers: Record<string, string> = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + this.apiKey,
        'anthropic-version': '2023-06-01'
      };

      const options: http.HttpRequestOptions = {
        method: http.RequestMethod.POST,
        header: headers,
        connectTimeout: 60000,
        readTimeout: 60000,
        extraData: requestBodyStr
      };

      Logger.info('Sending HTTP request to: ' + url);
      const response = await httpRequest.request(url, options);

      if (this.isCancelled) {
        Logger.info('Request was cancelled');
        httpRequest.destroy();
        return;
      }

      const responseCode = response.responseCode;
      const result = response.result as string;

      Logger.info('API Response Code: ' + responseCode);
      Logger.info('Response length: ' + (result ? result.length : 0));

      if (responseCode === 200) {
        try {
          const responseObj: AnthropicResponse = JSON.parse(result) as AnthropicResponse;
          Logger.info('Response id: ' + responseObj.id);

          if (responseObj.content && responseObj.content.length > 0) {
            let content = '';
            for (let i = 0; i < responseObj.content.length; i++) {
              const block: AnthropicContentBlock = responseObj.content[i];
              if (block.type === 'text' && block.text) {
                content = block.text;
                break;
              }
            }

            if (content.length > 0) {
              Logger.info('Extracted content: ' + content.length + ' chars');
              Logger.info('Content preview: ' + content.substring(0, Math.min(100, content.length)));
              onChunk(content);
              onComplete();
            } else {
              Logger.error('No text content found in response');
              onError(new Error('响应中没有文本内容'));
            }
          } else {
            Logger.error('Response has no content blocks');
            onError(new Error('响应格式错误'));
          }
        } catch (parseError) {
          const err = parseError as Error;
          Logger.error('Parse error: ' + err.message);
          Logger.error('Response content: ' + result.substring(0, 500));
          onError(new Error('解析响应失败: ' + err.message));
        }
      } else if (responseCode === 401) {
        Logger.error('401 Unauthorized - Invalid API Key');
        onError(new Error(ERROR_MESSAGES.INVALID_API_KEY));
      } else {
        Logger.error('HTTP Error ' + responseCode);
        let errorMsg = ERROR_MESSAGES.API_ERROR;

        try {
          const errorObj: ApiErrorResponse = JSON.parse(result) as ApiErrorResponse;
          if (errorObj.error !== undefined && errorObj.error !== null && errorObj.error.message !== undefined) {
            errorMsg = errorObj.error.message;
          } else if (errorObj.msg !== undefined && errorObj.msg !== null) {
            errorMsg = errorObj.msg;
          } else if (errorObj.message !== undefined && errorObj.message !== null) {
            errorMsg = errorObj.message;
          }
        } catch (e) {
          // Use default error message
        }

        onError(new Error(errorMsg + ' (HTTP ' + responseCode + ')'));
      }

      httpRequest.destroy();
    } catch (error) {
      if (this.isCancelled) {
        return;
      }
      const err = error as Error;
      Logger.error('Send message exception: ' + err.message);
      Logger.error('Stack: ' + err.stack);
      onError(new Error(ERROR_MESSAGES.API_CONNECTION_ERROR + ': ' + err.message));
    }
  }

  /**
   * 取消当前请求
   */
  cancel(): void {
    this.isCancelled = true;
    Logger.info('Request cancelled');
  }
}

export default new GLMService();
