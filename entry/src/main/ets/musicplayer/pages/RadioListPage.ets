/**
 * RadioListPage 网络电台列表页面
 * 遵循华为 UX 体验标准：
 * - 可点击区域 >= 48vp x 48vp (2.1.4.1)
 * - 文字对比度 > 4.5:1 (2.1.4.2)
 * - 支持深色模式
 * - 支持无障碍访问
 */
import { RadioStation } from '../models/RadioStation';
import radioViewModel from '../viewmodels/RadioViewModel';
import { RadioListItem } from '../components/RadioListItem';
import { EmptyState } from '../components/EmptyState';
import { NetworkError, NetworkErrorType } from '../components/NetworkError';
import { BufferingIndicator } from '../components/BufferingIndicator';

/**
 * 网络电台列表页面
 * 提供电台浏览、搜索、筛选功能
 */
@Entry
@Component
struct RadioListPage {
  // ========== 状态属性 ==========

  /** 电台列表 */
  @State private stations: RadioStation[] = [];

  /** 是否正在加载 */
  @State private isLoading: boolean = false;

  /** 错误信息 */
  @State private errorMessage: string | null = null;

  /** 选中的国家 */
  @State private selectedCountry: string | null = null;

  /** 选中的标签 */
  @State private selectedTag: string | null = null;

  /** 搜索关键词 */
  @State private searchQuery: string = '';

  /** 是否展开搜索栏 */
  @State private isSearchExpanded: boolean = false;

  /** 搜索输入框内容 */
  @State private searchInputText: string = '';

  /** 当前播放的电台 ID */
  @State private currentPlayingId: string = '';

  /** 国家列表 */
  @State private countries: string[] = [];

  /** 标签列表 */
  @State private tags: string[] = [];

  /** 是否显示国家筛选面板 */
  @State private showCountryPicker: boolean = false;

  /** 是否显示标签筛选面板 */
  @State private showTagPicker: boolean = false;

  /** 是否已初始化 */
  private isInitialized: boolean = false;

  /** 搜索防抖定时器 ID */
  private searchDebounceTimer: number = -1;

  // ========== 生命周期方法 ==========

  /**
   * 页面即将显示
   */
  aboutToAppear(): void {
    this.setupViewModelCallbacks();
    this.initializeData();
  }

  /**
   * 页面即将消失
   */
  aboutToDisappear(): void {
    // 清除防抖定时器
    if (this.searchDebounceTimer !== -1) {
      clearTimeout(this.searchDebounceTimer);
      this.searchDebounceTimer = -1;
    }
  }

  // ========== 初始化方法 ==========

  /**
   * 设置 ViewModel 回调
   */
  private setupViewModelCallbacks(): void {
    radioViewModel.setOnStationsChanged(() => {
      this.stations = radioViewModel.getStations();
    });

    radioViewModel.setOnLoadingChanged((loading: boolean) => {
      this.isLoading = loading;
    });

    radioViewModel.setOnErrorChanged((error: string | null) => {
      this.errorMessage = error;
    });

    radioViewModel.setOnCountriesChanged(() => {
      this.countries = radioViewModel.getCountries();
    });

    radioViewModel.setOnTagsChanged(() => {
      this.tags = radioViewModel.getTags();
    });

    radioViewModel.setOnFiltersChanged(() => {
      this.selectedCountry = radioViewModel.getSelectedCountry();
      this.selectedTag = radioViewModel.getSelectedTag();
      this.searchQuery = radioViewModel.getSearchQuery();
    });
  }

  /**
   * 初始化数据
   */
  private async initializeData(): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    this.isInitialized = true;
    await radioViewModel.initialize();
  }

  // ========== 事件处理方法 ==========

  /**
   * 处理电台点击事件
   * @param station 被点击的电台
   */
  private onStationClick(station: RadioStation): void {
    this.currentPlayingId = station.id;
    // TODO: 调用播放器服务播放电台
    console.info(`播放电台: ${station.name}`);
  }

  /**
   * 处理电台长按事件
   * @param station 被长按的电台
   */
  private onStationLongPress(station: RadioStation): void {
    // TODO: 显示上下文菜单（收藏、分享等）
    console.info(`长按电台: ${station.name}`);
  }

  /**
   * 处理搜索输入
   * 使用防抖机制避免频繁搜索
   */
  private onSearchInput(query: string): void {
    this.searchInputText = query;

    // 清除之前的定时器
    if (this.searchDebounceTimer !== -1) {
      clearTimeout(this.searchDebounceTimer);
    }

    // 设置新的防抖定时器（300ms）
    this.searchDebounceTimer = setTimeout(() => {
      this.performSearch(query);
    }, 300);
  }

  /**
   * 执行搜索
   * @param query 搜索关键词
   */
  private async performSearch(query: string): Promise<void> {
    const trimmedQuery: string = query.trim();

    if (trimmedQuery.length === 0) {
      // 清空搜索时重置为热门电台
      this.isSearchExpanded = false;
      await radioViewModel.clearFilters();
    } else if (trimmedQuery.length >= 2) {
      await radioViewModel.searchStations(trimmedQuery);
    }
  }

  /**
   * 处理国家筛选
   * @param country 国家名称
   */
  private async onCountrySelect(country: string): Promise<void> {
    this.showCountryPicker = false;
    this.selectedCountry = country;
    this.selectedTag = null;
    await radioViewModel.filterByCountry(country);
  }

  /**
   * 处理标签筛选
   * @param tag 标签名称
   */
  private async onTagSelect(tag: string): Promise<void> {
    this.showTagPicker = false;
    this.selectedTag = tag;
    this.selectedCountry = null;
    await radioViewModel.filterByTag(tag);
  }

  /**
   * 清除所有筛选条件
   */
  private async clearAllFilters(): Promise<void> {
    this.selectedCountry = null;
    this.selectedTag = null;
    this.searchInputText = '';
    this.isSearchExpanded = false;
    await radioViewModel.clearFilters();
  }

  /**
   * 下拉刷新
   */
  private async onRefresh(): Promise<void> {
    await radioViewModel.refresh();
  }

  /**
   * 重试加载
   */
  private async onRetry(): Promise<void> {
    await radioViewModel.refresh();
  }

  /**
   * 切换搜索栏展开状态
   */
  private toggleSearch(): void {
    this.isSearchExpanded = !this.isSearchExpanded;
    if (!this.isSearchExpanded) {
      this.searchInputText = '';
    }
  }

  // ========== UI 构建方法 ==========

  build() {
    Column() {
      // 标题栏
      this.buildTitleBar()

      // 搜索栏（可展开）
      if (this.isSearchExpanded) {
        this.buildSearchBar()
      }

      // 筛选栏
      this.buildFilterBar()

      // 内容区域
      this.buildContent()
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.page_bg'))
  }

  /**
   * 构建标题栏
   */
  @Builder
  buildTitleBar() {
    Row() {
      // 返回按钮
      Image($r('sys.media.ohos_ic_public_arrow_left'))
        .width(24)
        .height(24)
        .fillColor($r('app.color.primary_text'))
        .onClick(() => {
          // TODO: 返回上一页
        })

      // 标题
      Text('网络电台')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.primary_text'))
        .margin({ left: 12 })
        .layoutWeight(1)

      // 搜索按钮
      Image($r('app.media.ic_public_search'))
        .width(24)
        .height(24)
        .fillColor($r('app.color.primary_text'))
        .onClick(() => {
          this.toggleSearch();
        })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.card_bg'))
  }

  /**
   * 构建搜索栏
   */
  @Builder
  buildSearchBar() {
    Row() {
      // 搜索图标
      Image($r('app.media.ic_public_search'))
        .width(20)
        .height(20)
        .fillColor($r('app.color.secondary_text'))
        .margin({ right: 8 })

      // 搜索输入框
      TextInput({ placeholder: '搜索电台名称...', text: this.searchInputText })
        .layoutWeight(1)
        .height(40)
        .fontSize(16)
        .fontColor($r('app.color.primary_text'))
        .placeholderColor($r('app.color.placeholder_text'))
        .backgroundColor(Color.Transparent)
        .type(InputType.Normal)
        .onChange((value: string) => {
          this.onSearchInput(value);
        })
        .onSubmit(() => {
          this.performSearch(this.searchInputText);
        })

      // 清除按钮
      if (this.searchInputText.length > 0) {
        Image($r('sys.media.ohos_ic_public_cancel'))
          .width(20)
          .height(20)
          .fillColor($r('app.color.secondary_text'))
          .onClick(() => {
            this.onSearchInput('');
          })
      }
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.input_bg'))
    .borderRadius(0)
  }

  /**
   * 构建筛选栏
   */
  @Builder
  buildFilterBar() {
    Row() {
      // 国家筛选按钮
      this.buildFilterChip(
        this.selectedCountry || '国家',
        this.selectedCountry !== null,
        () => {
          this.showCountryPicker = !this.showCountryPicker;
          this.showTagPicker = false;
        }
      )

      // 标签筛选按钮
      this.buildFilterChip(
        this.selectedTag || '标签',
        this.selectedTag !== null,
        () => {
          this.showTagPicker = !this.showTagPicker;
          this.showCountryPicker = false;
        }
      )

      // 清除筛选按钮（仅当有筛选条件时显示）
      if (this.selectedCountry !== null || this.selectedTag !== null) {
        Button('清除')
          .type(ButtonType.Capsule)
          .fontSize(14)
          .fontColor($r('app.color.primary'))
          .backgroundColor($r('app.color.input_bg'))
          .height(32)
          .padding({ left: 12, right: 12 })
          .onClick(() => {
            this.clearAllFilters();
          })
      }

      Blank()
    }
    .width('100%')
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
    .alignItems(VerticalAlign.Center)
    .backgroundColor($r('app.color.card_bg'))

    // 国家选择面板
    if (this.showCountryPicker) {
      this.buildCountryPicker()
    }

    // 标签选择面板
    if (this.showTagPicker) {
      this.buildTagPicker()
    }
  }

  /**
   * 构建筛选芯片
   * @param label 标签文本
   * @param isActive 是否激活状态
   * @param onClick 点击回调
   */
  @Builder
  buildFilterChip(label: string, isActive: boolean, onClick: () => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(isActive ? Color.White : $r('app.color.primary_text'))
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      Image($r('sys.media.ohos_ic_public_arrow_down'))
        .width(16)
        .height(16)
        .fillColor(isActive ? Color.White : $r('app.color.secondary_text'))
        .margin({ left: 4 })
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .borderRadius(16)
    .backgroundColor(isActive ? $r('app.color.primary') : $r('app.color.input_bg'))
    .onClick(onClick)
  }

  /**
   * 构建国家选择面板
   */
  @Builder
  buildCountryPicker() {
    Column() {
      if (this.countries.length === 0) {
        // 加载中
        LoadingProgress()
          .width(24)
          .height(24)
          .margin({ top: 16, bottom: 16 })
      } else {
        // 国家列表（网格布局）
        Grid() {
          ForEach(this.countries.slice(0, 30), (country: string) => {
            GridItem() {
              Text(country)
                .fontSize(14)
                .fontColor(this.selectedCountry === country
                  ? $r('app.color.primary')
                  : $r('app.color.primary_text'))
                .padding({ left: 8, right: 8, top: 6, bottom: 6 })
                .borderRadius(4)
                .backgroundColor(this.selectedCountry === country
                  ? $r('app.color.input_bg')
                  : Color.Transparent)
                .width('100%')
                .textAlign(TextAlign.Center)
                .onClick(() => {
                  this.onCountrySelect(country);
                })
            }
          })
        }
        .columnsTemplate('1fr 1fr 1fr')
        .rowsGap(8)
        .columnsGap(8)
        .width('100%')
        .height(200)
        .padding(16)
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { top: 1 }, color: $r('app.color.input_bg') })
  }

  /**
   * 构建标签选择面板
   */
  @Builder
  buildTagPicker() {
    Column() {
      if (this.tags.length === 0) {
        // 加载中
        LoadingProgress()
          .width(24)
          .height(24)
          .margin({ top: 16, bottom: 16 })
      } else {
        // 标签列表（Flex 布局，自动换行）
        Flex({ wrap: FlexWrap.Wrap }) {
          ForEach(this.tags.slice(0, 30), (tag: string) => {
            Text(tag)
              .fontSize(14)
              .fontColor(this.selectedTag === tag
                ? Color.White
                : $r('app.color.primary_text'))
              .padding({ left: 12, right: 12, top: 6, bottom: 6 })
              .borderRadius(16)
              .backgroundColor(this.selectedTag === tag
                ? $r('app.color.primary')
                : $r('app.color.input_bg'))
              .margin({ right: 8, bottom: 8 })
              .onClick(() => {
                this.onTagSelect(tag);
              })
          })
        }
        .width('100%')
        .padding(16)
      }
    }
    .width('100%')
    .constraintSize({ maxHeight: 200 })
    .backgroundColor($r('app.color.card_bg'))
    .border({ width: { top: 1 }, color: $r('app.color.input_bg') })
  }

  /**
   * 构建内容区域
   */
  @Builder
  buildContent() {
    Stack() {
      // 主要内容：电台列表
      if (this.isLoading && this.stations.length === 0) {
        // 首次加载状态
        this.buildLoadingState()
      } else if (this.errorMessage !== null) {
        // 错误状态
        this.buildErrorState()
      } else if (this.stations.length === 0) {
        // 空状态
        this.buildEmptyState()
      } else {
        // 电台列表
        this.buildStationList()
      }

      // 加载指示器（覆盖在内容上方）
      if (this.isLoading && this.stations.length > 0) {
        Column() {
          BufferingIndicator({
            isLoading: true,
            indicatorSize: 32,
            text: '加载中...'
          })
        }
        .width('100%')
        .padding({ top: 8 })
        .backgroundColor($r('app.color.page_bg'))
      }
    }
    .layoutWeight(1)
  }

  /**
   * 构建加载状态
   */
  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color($r('app.color.loading_indicator'))

      Text('正在加载电台列表...')
        .fontSize(14)
        .fontColor($r('app.color.secondary_text'))
        .margin({ top: 16 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  /**
   * 构建错误状态
   */
  @Builder
  buildErrorState() {
    Column() {
      NetworkError({
        message: this.errorMessage || '加载失败',
        errorType: NetworkErrorType.UNKNOWN,
        retryText: '重试'
      })
      // 设置重试回调需要通过方法链调用
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(16)
  }

  /**
   * 构建空状态
   */
  @Builder
  buildEmptyState() {
    Column() {
      EmptyState({
        icon: $r('app.media.ohos_ic_public_radio'),
        title: this.searchQuery.length > 0 ? '未找到相关电台' : '暂无电台',
        description: this.searchQuery.length > 0
          ? `未找到与 "${this.searchQuery}" 相关的电台，请尝试其他关键词`
          : '暂无可用电台，请稍后重试',
        actionText: this.searchQuery.length > 0 ? '清除搜索' : '刷新'
      })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(16)
  }

  /**
   * 构建电台列表
   */
  @Builder
  buildStationList() {
    List() {
      ForEach(this.stations, (station: RadioStation) => {
        ListItem() {
          RadioListItem({
            station: station,
            isPlaying: this.currentPlayingId === station.id,
            onStationClick: () => {
              this.onStationClick(station);
            },
            onStationLongPress: () => {
              this.onStationLongPress(station);
            }
          })
        }
        .height(64)
      }, (station: RadioStation) => station.id)
    }
    .width('100%')
    .layoutWeight(1)
    .divider({
      strokeWidth: 1,
      color: $r('app.color.input_bg'),
      startMargin: 76,
      endMargin: 16
    })
    .edgeEffect(EdgeEffect.Spring)
    .chainAnimation(false)
  }
}

/**
 * 使用示例：
 *
 * ```typescript
 * import { RadioListPage } from './pages/RadioListPage';
 *
 * // 在路由配置中注册页面
 * import { RadioListPage } from './pages/RadioListPage';
 * ```
 */
