/**
 * Preferences 本地存储服务
 * 用于持久化 API Key 等用户配置
 * 遵循华为 UX 体验标准
 */
import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { STORAGE_KEYS } from '../common/constants/Constants';
import Logger from '../common/utils/Logger';

const PREFERENCES_NAME = 'llm_chat_preferences';

/**
 * Preferences 服务类
 */
class PreferencesService {
  private preferencesInstance: preferences.Preferences | null = null;
  private initPromise: Promise<void> | null = null;

  /**
   * 初始化 Preferences
   */
  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.preferencesInstance) {
      return; // Already initialized
    }

    if (this.initPromise) {
      return this.initPromise; // Wait for existing init
    }

    this.initPromise = this.doInit(context);
    return this.initPromise;
  }

  private async doInit(context: common.UIAbilityContext): Promise<void> {
    try {
      this.preferencesInstance = await preferences.getPreferences(context, PREFERENCES_NAME);
      Logger.info('PreferencesService initialized');
    } catch (error) {
      const errMsg = 'Failed to initialize PreferencesService: ' + JSON.stringify(error);
      Logger.error(errMsg);
      throw new Error(errMsg);
    }
  }

  /**
   * 等待初始化完成
   */
  async waitForInit(): Promise<void> {
    if (this.preferencesInstance) {
      return;
    }
    if (this.initPromise) {
      return this.initPromise;
    }
    throw new Error('Preferences not initialized');
  }

  /**
   * 确保 Preferences 已初始化（同步检查）
   */
  private ensureInitialized(): void {
    if (!this.preferencesInstance) {
      throw new Error('Preferences not initialized');
    }
  }

  /**
   * 保存 API Key
   */
  async saveApiKey(apiKey: string): Promise<void> {
    this.ensureInitialized();
    try {
      await this.preferencesInstance!.put(STORAGE_KEYS.API_KEY, apiKey);
      await this.preferencesInstance!.flush();
      Logger.info('API Key saved successfully');
    } catch (error) {
      const errMsg = 'Failed to save API Key: ' + JSON.stringify(error);
      Logger.error(errMsg);
      throw new Error(errMsg);
    }
  }

  /**
   * 获取 API Key
   */
  async getApiKey(): Promise<string> {
    this.ensureInitialized();
    try {
      const apiKey = await this.preferencesInstance!.get(STORAGE_KEYS.API_KEY, '') as string;
      return apiKey;
    } catch (error) {
      Logger.error('Failed to get API Key: ' + JSON.stringify(error));
      return '';
    }
  }

  /**
   * 检查是否已配置 API Key
   */
  async hasApiKey(): Promise<boolean> {
    const apiKey = await this.getApiKey();
    return apiKey.length > 0;
  }

  /**
   * 删除 API Key
   */
  async deleteApiKey(): Promise<void> {
    this.ensureInitialized();
    try {
      await this.preferencesInstance!.delete(STORAGE_KEYS.API_KEY);
      await this.preferencesInstance!.flush();
      Logger.info('API Key deleted successfully');
    } catch (error) {
      const errMsg = 'Failed to delete API Key: ' + JSON.stringify(error);
      Logger.error(errMsg);
      throw new Error(errMsg);
    }
  }
}

export default new PreferencesService();
