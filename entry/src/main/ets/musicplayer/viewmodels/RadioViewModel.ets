/**
 * RadioViewModel 网络电台视图模型
 * 管理电台状态和业务逻辑
 */
import { RadioStation } from '../models/RadioStation';
import radioService, { CountryInfo, TagInfo, RadioServiceError } from '../services/RadioService';
import { RadioErrorCode } from '../common/ErrorCodes';

/**
 * 状态变更回调类型
 */
type VoidCallback = () => void;
type BooleanCallback = (value: boolean) => void;
type StringCallback = (value: string | null) => void;

/**
 * 网络电台视图模型类
 * 负责管理电台列表、筛选条件和加载状态
 */
class RadioViewModelClass {
  // 状态属性
  private stationsList: RadioStation[] = [];
  private isLoadingValue: boolean = false;
  private errorValue: string | null = null;
  private searchQueryValue: string = '';
  private selectedCountryValue: string | null = null;
  private selectedTagValue: string | null = null;
  private countriesList: string[] = [];
  private tagsList: string[] = [];
  private isInitialized: boolean = false;

  // 状态变更回调
  private onStationsChangedCallback?: VoidCallback;
  private onLoadingChangedCallback?: BooleanCallback;
  private onErrorChangedCallback?: StringCallback;
  private onCountriesChangedCallback?: VoidCallback;
  private onTagsChangedCallback?: VoidCallback;
  private onFiltersChangedCallback?: VoidCallback;

  /**
   * 获取电台列表
   * @returns 电台列表副本
   */
  getStations(): RadioStation[] {
    return [...this.stationsList];
  }

  /**
   * 是否正在加载
   * @returns 加载状态
   */
  isLoading(): boolean {
    return this.isLoadingValue;
  }

  /**
   * 获取错误信息
   * @returns 错误信息或 null
   */
  getError(): string | null {
    return this.errorValue;
  }

  /**
   * 获取搜索关键词
   * @returns 当前搜索关键词
   */
  getSearchQuery(): string {
    return this.searchQueryValue;
  }

  /**
   * 获取选中的国家
   * @returns 国家名称或 null
   */
  getSelectedCountry(): string | null {
    return this.selectedCountryValue;
  }

  /**
   * 获取选中的标签
   * @returns 标签名称或 null
   */
  getSelectedTag(): string | null {
    return this.selectedTagValue;
  }

  /**
   * 获取国家列表
   * @returns 国家名称列表
   */
  getCountries(): string[] {
    return [...this.countriesList];
  }

  /**
   * 获取标签列表
   * @returns 标签名称列表
   */
  getTags(): string[] {
    return [...this.tagsList];
  }

  /**
   * 是否有筛选条件
   * @returns 是否有活跃的筛选条件
   */
  hasActiveFilters(): boolean {
    return this.searchQueryValue.length > 0 ||
           this.selectedCountryValue !== null ||
           this.selectedTagValue !== null;
  }

  /**
   * 初始化视图模型
   * 加载初始数据（国家列表、标签列表、热门电台）
   */
  async initialize(): Promise<void> {
    if (this.isInitialized) {
      console.info('[RadioViewModel] 已经初始化，跳过');
      return;
    }

    console.info('[RadioViewModel] 开始初始化');
    try {
      this.setLoading(true);
      this.setError(null);

      // 并行加载国家、标签和热门电台
      console.info('[RadioViewModel] 并行加载数据...');
      await Promise.all([
        this.loadCountries(),
        this.loadTags(),
        this.loadTopStations(50, true) // skipLoadingState=true，由initialize管理loading状态
      ]);

      this.isInitialized = true;
      console.info('[RadioViewModel] 初始化完成');
    } catch (error) {
      const err = error as Error;
      console.error(`[RadioViewModel] 初始化失败: ${err.message}`);
      this.setError(`初始化失败: ${err.message}`);
    } finally {
      this.setLoading(false);
    }
  }

  /**
   * 加载热门电台
   * @param limit 返回数量，默认 50
   * @param skipLoadingState 是否跳过加载状态更新（内部使用）
   */
  async loadTopStations(limit: number = 50, skipLoadingState: boolean = false): Promise<void> {
    console.info(`[RadioViewModel] 加载热门电台, limit=${limit}`);
    try {
      if (!skipLoadingState) {
        this.setLoading(true);
        this.setError(null);
      }

      const safeLimit: number = Math.max(1, Math.min(limit, 1000));
      const stations: RadioStation[] = await radioService.getTopStations(safeLimit);

      console.info(`[RadioViewModel] 获取到 ${stations.length} 个电台`);
      this.stationsList = stations;
      this.notifyStationsChanged();
    } catch (error) {
      const err = error as Error;
      console.error(`[RadioViewModel] 加载热门电台失败: ${err.message}`);
      this.handleError(error, '加载热门电台失败');
    } finally {
      if (!skipLoadingState) {
        this.setLoading(false);
      }
    }
  }

  /**
   * 搜索电台
   * @param query 搜索关键词
   */
  async searchStations(query: string): Promise<void> {
    const trimmedQuery: string = query.trim();

    // 如果搜索词为空或太短，加载热门电台
    if (trimmedQuery.length < 2) {
      if (trimmedQuery.length === 0) {
        this.searchQueryValue = '';
        await this.loadTopStations(50);
      }
      return;
    }

    try {
      this.setLoading(true);
      this.setError(null);
      this.searchQueryValue = trimmedQuery;

      // 清除其他筛选条件
      this.selectedCountryValue = null;
      this.selectedTagValue = null;
      this.notifyFiltersChanged();

      const stations: RadioStation[] = await radioService.search(trimmedQuery, 50);

      this.stationsList = stations;
      this.notifyStationsChanged();
    } catch (error) {
      this.handleError(error, '搜索电台失败');
    } finally {
      this.setLoading(false);
    }
  }

  /**
   * 按国家筛选电台
   * @param country 国家名称
   */
  async filterByCountry(country: string): Promise<void> {
    if (!country || country.trim().length === 0) {
      return;
    }

    try {
      this.setLoading(true);
      this.setError(null);
      this.selectedCountryValue = country;
      this.selectedTagValue = null;
      this.searchQueryValue = '';
      this.notifyFiltersChanged();

      const stations: RadioStation[] = await radioService.getByCountry(country, 50);

      this.stationsList = stations;
      this.notifyStationsChanged();
    } catch (error) {
      this.handleError(error, '按国家筛选失败');
    } finally {
      this.setLoading(false);
    }
  }

  /**
   * 按标签筛选电台
   * @param tag 标签名称
   */
  async filterByTag(tag: string): Promise<void> {
    if (!tag || tag.trim().length === 0) {
      return;
    }

    try {
      this.setLoading(true);
      this.setError(null);
      this.selectedTagValue = tag;
      this.selectedCountryValue = null;
      this.searchQueryValue = '';
      this.notifyFiltersChanged();

      const stations: RadioStation[] = await radioService.getByTag(tag, 50);

      this.stationsList = stations;
      this.notifyStationsChanged();
    } catch (error) {
      this.handleError(error, '按标签筛选失败');
    } finally {
      this.setLoading(false);
    }
  }

  /**
   * 加载国家列表
   */
  async loadCountries(): Promise<void> {
    try {
      const countries: CountryInfo[] = await radioService.getCountries();

      // 提取国家名称，过滤掉空名称
      const countryNames: string[] = countries
        .filter((c: CountryInfo) => c.name && c.name.length > 0)
        .map((c: CountryInfo) => c.name)
        .slice(0, 100); // 限制数量，避免列表过长

      this.countriesList = countryNames;
      this.notifyCountriesChanged();
    } catch (error) {
      // 国家列表加载失败不阻塞初始化
      console.warn('加载国家列表失败:', (error as Error).message);
    }
  }

  /**
   * 加载标签列表
   */
  async loadTags(): Promise<void> {
    try {
      const tags: TagInfo[] = await radioService.getTags();

      // 提取标签名称，过滤掉空名称和特殊字符
      const tagNames: string[] = tags
        .filter((t: TagInfo) => t.name && t.name.length > 0 && /^[a-zA-Z0-9\s-]+$/.test(t.name))
        .map((t: TagInfo) => t.name)
        .slice(0, 100); // 限制数量，避免列表过长

      this.tagsList = tagNames;
      this.notifyTagsChanged();
    } catch (error) {
      // 标签列表加载失败不阻塞初始化
      console.warn('加载标签列表失败:', (error as Error).message);
    }
  }

  /**
   * 清除所有筛选条件
   * 恢复到热门电台列表
   */
  clearFilters(): void {
    this.searchQueryValue = '';
    this.selectedCountryValue = null;
    this.selectedTagValue = null;
    this.notifyFiltersChanged();

    // 重新加载热门电台
    this.loadTopStations(50);
  }

  /**
   * 刷新当前列表
   * 根据当前筛选条件重新加载数据
   */
  async refresh(): Promise<void> {
    // 根据当前状态决定刷新方式
    if (this.searchQueryValue.length >= 2) {
      await this.searchStations(this.searchQueryValue);
    } else if (this.selectedCountryValue !== null) {
      await this.filterByCountry(this.selectedCountryValue);
    } else if (this.selectedTagValue !== null) {
      await this.filterByTag(this.selectedTagValue);
    } else {
      await this.loadTopStations(50);
    }
  }

  // ========== 回调设置方法 ==========

  /**
   * 设置电台列表变更回调
   */
  setOnStationsChanged(callback: VoidCallback): void {
    this.onStationsChangedCallback = callback;
  }

  /**
   * 设置加载状态变更回调
   */
  setOnLoadingChanged(callback: BooleanCallback): void {
    this.onLoadingChangedCallback = callback;
  }

  /**
   * 设置错误信息变更回调
   */
  setOnErrorChanged(callback: StringCallback): void {
    this.onErrorChangedCallback = callback;
  }

  /**
   * 设置国家列表变更回调
   */
  setOnCountriesChanged(callback: VoidCallback): void {
    this.onCountriesChangedCallback = callback;
  }

  /**
   * 设置标签列表变更回调
   */
  setOnTagsChanged(callback: VoidCallback): void {
    this.onTagsChangedCallback = callback;
  }

  /**
   * 设置筛选条件变更回调
   */
  setOnFiltersChanged(callback: VoidCallback): void {
    this.onFiltersChangedCallback = callback;
  }

  // ========== 私有方法 ==========

  /**
   * 设置加载状态
   * @param loading 加载状态
   */
  private setLoading(loading: boolean): void {
    this.isLoadingValue = loading;
    if (this.onLoadingChangedCallback) {
      this.onLoadingChangedCallback(loading);
    }
  }

  /**
   * 设置错误信息
   * @param error 错误信息
   */
  private setError(error: string | null): void {
    this.errorValue = error;
    if (this.onErrorChangedCallback) {
      this.onErrorChangedCallback(error);
    }
  }

  /**
   * 统一错误处理
   * @param error 错误对象
   * @param defaultMessage 默认错误消息
   */
  private handleError(error: Error | Object, defaultMessage: string): void {
    let errorMessage: string = defaultMessage;

    if (error instanceof RadioServiceError) {
      // 根据错误码设置特定消息
      switch (error.code) {
        case RadioErrorCode.RADIO_TIMEOUT:
          errorMessage = '请求超时，请检查网络连接后重试';
          break;
        case RadioErrorCode.RADIO_NETWORK_ERROR:
          errorMessage = '网络错误，请检查网络连接';
          break;
        default:
          errorMessage = error.message;
      }
    } else if (error instanceof Error) {
      errorMessage = error.message;
    }

    this.setError(errorMessage);
    console.error('RadioViewModel error:', errorMessage);
  }

  /**
   * 通知电台列表变更
   */
  private notifyStationsChanged(): void {
    if (this.onStationsChangedCallback) {
      this.onStationsChangedCallback();
    }
  }

  /**
   * 通知国家列表变更
   */
  private notifyCountriesChanged(): void {
    if (this.onCountriesChangedCallback) {
      this.onCountriesChangedCallback();
    }
  }

  /**
   * 通知标签列表变更
   */
  private notifyTagsChanged(): void {
    if (this.onTagsChangedCallback) {
      this.onTagsChangedCallback();
    }
  }

  /**
   * 通知筛选条件变更
   */
  private notifyFiltersChanged(): void {
    if (this.onFiltersChangedCallback) {
      this.onFiltersChangedCallback();
    }
  }
}

// 导出单例实例
export default new RadioViewModelClass();
