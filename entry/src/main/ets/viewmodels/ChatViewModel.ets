/**
 * ChatViewModel 聊天视图模型
 * 遵循华为 UX 体验标准
 */
import { ChatMessage, createMessage, validateContent, updateMessageContent, updateMessageStatus } from '../models/ChatMessage';
import { MessageRole } from '../models/MessageRole';
import { MessageStatus } from '../models/MessageStatus';
import { GLMMessage } from '../models/GLMTypes';
import GLMService from '../services/GLMService';
import PreferencesService from '../services/PreferencesService';
import NetworkUtil from '../common/utils/NetworkUtil';
import { ERROR_MESSAGES, MESSAGE_CONFIG } from '../common/constants/Constants';
import Logger from '../common/utils/Logger';

/**
 * 状态变更回调类型
 */
type VoidCallback = () => void;
type BooleanCallback = (value: boolean) => void;
type StringCallback = (value: string | null) => void;

/**
 * 聊天视图模型类
 */
class ChatViewModelClass {
  // 状态
  private messagesList: ChatMessage[] = [];
  private inputTextValue: string = '';
  private isLoadingValue: boolean = false;
  private errorValue: string | null = null;
  private apiKeyValue: string = '';
  private isInitialized: boolean = false;

  // 状态变更回调
  private onMessagesChangedCallback?: VoidCallback;
  private onLoadingChangedCallback?: BooleanCallback;
  private onErrorChangedCallback?: StringCallback;

  /**
   * 初始化
   */
  async init(): Promise<void> {
    if (this.isInitialized) {
      Logger.info('ChatViewModel already initialized');
      return;
    }

    try {
      Logger.info('ChatViewModel initializing...');

      // 等待 PreferencesService 初始化完成
      await PreferencesService.waitForInit();
      Logger.info('PreferencesService ready');

      this.apiKeyValue = await PreferencesService.getApiKey();
      Logger.info('API Key loaded, length: ' + this.apiKeyValue.length);

      if (this.apiKeyValue) {
        GLMService.setApiKey(this.apiKeyValue);
        Logger.info('API Key set to GLMService');
      }
      this.isInitialized = true;
      Logger.info('ChatViewModel initialized successfully');
    } catch (error) {
      const err = error as Error;
      Logger.error('Failed to initialize ChatViewModel: ' + err.message);
    }
  }

  /**
   * 获取消息列表
   */
  getMessages(): ChatMessage[] {
    return [...this.messagesList];
  }

  /**
   * 获取输入文本
   */
  getInputText(): string {
    return this.inputTextValue;
  }

  /**
   * 设置输入文本
   */
  setInputText(text: string): void {
    Logger.info('setInputText: ' + text.length + ' chars');
    this.inputTextValue = text;
  }

  /**
   * 是否正在加载
   */
  isLoading(): boolean {
    return this.isLoadingValue;
  }

  /**
   * 获取错误信息
   */
  getError(): string | null {
    return this.errorValue;
  }

  /**
   * 是否有 API Key
   */
  async hasApiKey(): Promise<boolean> {
    try {
      const hasKey = await PreferencesService.hasApiKey();
      Logger.info('hasApiKey: ' + hasKey);
      return hasKey;
    } catch (error) {
      Logger.error('Failed to check hasApiKey');
      return false;
    }
  }

  /**
   * 重新加载 API Key（在用户保存新 Key 后调用）
   */
  async reloadApiKey(): Promise<void> {
    try {
      this.apiKeyValue = await PreferencesService.getApiKey();
      Logger.info('API Key reloaded, length: ' + this.apiKeyValue.length);
      if (this.apiKeyValue) {
        GLMService.setApiKey(this.apiKeyValue);
        Logger.info('API Key set to GLMService');
      }
    } catch (error) {
      Logger.error('Failed to reload API Key');
    }
  }

  /**
   * 发送消息
   */
  async sendMessage(): Promise<void> {
    Logger.info('sendMessage called, inputText: ' + this.inputTextValue.length + ' chars');

    // 验证输入
    if (!validateContent(this.inputTextValue)) {
      const errorMsg = this.inputTextValue.length === 0
        ? ERROR_MESSAGES.EMPTY_MESSAGE
        : ERROR_MESSAGES.MESSAGE_TOO_LONG;
      Logger.error('Validation failed: ' + errorMsg);
      this.setError(errorMsg);
      return;
    }

    // 检查网络
    try {
      const isConnected = await NetworkUtil.isNetworkConnected();
      Logger.info('Network connected: ' + isConnected);
      if (!isConnected) {
        this.setError(ERROR_MESSAGES.NETWORK_ERROR);
        return;
      }
    } catch (error) {
      Logger.error('Network check failed, proceeding anyway');
    }

    // 检查 API Key
    if (!this.apiKeyValue) {
      Logger.error('API Key is empty');
      this.setError(ERROR_MESSAGES.INVALID_API_KEY);
      return;
    }

    // 创建用户消息
    const userMessage = createMessage(MessageRole.USER, this.inputTextValue);
    this.addMessage(userMessage);
    this.setLoading(true);
    this.setError(null);

    const currentInput = this.inputTextValue;
    this.inputTextValue = '';

    // 创建助手消息占位
    const assistantMessage = createMessage(MessageRole.ASSISTANT, '');
    assistantMessage.status = MessageStatus.SENDING;
    this.addMessage(assistantMessage);

    Logger.info('Starting API call...');

    try {
      // 构建历史消息
      const history: GLMMessage[] = this.buildHistory();
      Logger.info('History messages: ' + history.length);

      // 发送请求
      await GLMService.sendMessage(
        currentInput,
        (content: string) => {
          // 流式更新助手消息 - 直接修改对象属性（@Observed 会自动触发 UI 更新）
          Logger.info('onChunk called, content length: ' + content.length);
          const idx = this.messagesList.findIndex(m => m.id === assistantMessage.id);
          if (idx >= 0) {
            updateMessageContent(this.messagesList[idx], content);
            updateMessageStatus(this.messagesList[idx], MessageStatus.SENT);
            this.notifyMessagesChanged();
          }
        },
        () => {
          // 完成
          Logger.info('onComplete called');
          const aIdx = this.messagesList.findIndex(m => m.id === assistantMessage.id);
          const uIdx = this.messagesList.findIndex(m => m.id === userMessage.id);
          if (aIdx >= 0) {
            updateMessageStatus(this.messagesList[aIdx], MessageStatus.SENT);
          }
          if (uIdx >= 0) {
            updateMessageStatus(this.messagesList[uIdx], MessageStatus.SENT);
          }
          this.setLoading(false);
          this.notifyMessagesChanged();
        },
        (error: Error) => {
          // 错误处理
          Logger.error('onError called: ' + error.message);
          const aIdx = this.messagesList.findIndex(m => m.id === assistantMessage.id);
          const uIdx = this.messagesList.findIndex(m => m.id === userMessage.id);
          if (aIdx >= 0) {
            updateMessageStatus(this.messagesList[aIdx], MessageStatus.FAILED, error.message);
          }
          if (uIdx >= 0) {
            updateMessageStatus(this.messagesList[uIdx], MessageStatus.FAILED, error.message);
          }
          this.setLoading(false);
          this.setError(error.message);
          this.notifyMessagesChanged();
        },
        history
      );
    } catch (error) {
      Logger.error('Send message exception');
      this.setLoading(false);
      this.setError(ERROR_MESSAGES.API_ERROR);
      const err = error as Error;
      Logger.error('Exception: ' + err.message);
    }
  }

  /**
   * 构建历史消息
   */
  private buildHistory(): GLMMessage[] {
    const history: GLMMessage[] = [];
    const recentMessages = this.messagesList
      .filter(m => m.status === MessageStatus.SENT)
      .slice(-10);

    for (const msg of recentMessages) {
      const glmMsg: GLMMessage = {
        role: msg.role === MessageRole.USER ? 'user' : 'assistant',
        content: msg.content
      };
      history.push(glmMsg);
    }

    return history;
  }

  /**
   * 重试消息
   */
  async retryMessage(messageId: string): Promise<void> {
    const message = this.messagesList.find(m => m.id === messageId);
    if (!message) {
      return;
    }

    // 重置状态
    message.status = MessageStatus.SENDING;
    message.error = undefined;
    this.notifyMessagesChanged();

    // 重新发送
    this.inputTextValue = message.content;
    await this.sendMessage();
  }

  /**
   * 清空消息
   */
  clearMessages(): void {
    this.messagesList = [];
    this.notifyMessagesChanged();
  }

  /**
   * 取消请求
   */
  cancel(): void {
    GLMService.cancel();
  }

  /**
   * 设置回调
   */
  setOnMessagesChanged(callback: VoidCallback): void {
    this.onMessagesChangedCallback = callback;
  }

  setOnLoadingChanged(callback: BooleanCallback): void {
    this.onLoadingChangedCallback = callback;
  }

  setOnErrorChanged(callback: StringCallback): void {
    this.onErrorChangedCallback = callback;
  }

  // 私有方法
  private addMessage(message: ChatMessage): void {
    this.messagesList.push(message);
    this.notifyMessagesChanged();
  }

  private setLoading(loading: boolean): void {
    this.isLoadingValue = loading;
    if (this.onLoadingChangedCallback) {
      this.onLoadingChangedCallback(loading);
    }
  }

  private setError(error: string | null): void {
    this.errorValue = error;
    if (this.onErrorChangedCallback) {
      this.onErrorChangedCallback(error);
    }
  }

  private notifyMessagesChanged(): void {
    if (this.onMessagesChangedCallback) {
      this.onMessagesChangedCallback();
    }
  }
}

// 导出
export default new ChatViewModelClass();
