/**
 * CountryFilter 国家筛选组件
 * 提供下拉选择器用于国家筛选
 * 遵循华为 UX 体验标准：触摸区域 >= 48vp x 48vp
 * 支持深色模式和热门国家优先排序
 */

/**
 * 热门国家列表
 * 这些国家会在下拉列表中优先显示
 */
const POPULAR_COUNTRIES: string[] = [
  'China',
  'United States',
  'United Kingdom',
  'Germany',
  'France',
  'Japan',
  'South Korea',
  'Australia',
  'Canada',
  'Brazil'
];

/**
 * 国家筛选组件参数接口
 */
export interface CountryFilterParams {
  /** 国家列表 */
  countries: string[];
  /** 当前选中的国家 */
  selectedCountry: string | null;
  /** 占位文本 */
  placeholder?: string;
}

/**
 * 国家筛选组件
 * 支持下拉选择、清除选中、热门国家优先显示
 *
 * @example
 * // 基本用法
 * CountryFilter({
 *   countries: ['China', 'United States', 'Germany'],
 *   selectedCountry: null,
 *   placeholder: '选择国家',
 *   onSelect: (country: string) => { this.selectCountry(country) },
 *   onClear: () => { this.clearCountry() }
 * })
 */
@Component
export struct CountryFilter {
  /** 国家名称列表 */
  @Prop countries: string[] = [];

  /** 当前选中的国家 */
  @Prop selectedCountry: string | null = null;

  /** 占位文本 */
  @Prop placeholder: string = '选择国家';

  /** 下拉菜单是否显示 */
  @State private isDropdownOpen: boolean = false;

  /** 搜索关键词（用于可搜索下拉） */
  @State private searchQuery: string = '';

  /** 选择国家事件回调 */
  onSelect: (country: string) => void = () => {};

  /** 清除选择事件回调 */
  onClear: () => void = () => {};

  /**
   * 获取排序后的国家列表
   * 热门国家优先显示
   * @returns 排序后的国家列表
   */
  private getSortedCountries(): string[] {
    const filteredCountries: string[] = this.getFilteredCountries();

    // 分离热门国家和其他国家
    const popular: string[] = [];
    const others: string[] = [];

    for (const country of filteredCountries) {
      if (POPULAR_COUNTRIES.includes(country)) {
        popular.push(country);
      } else {
        others.push(country);
      }
    }

    // 按 POPULAR_COUNTRIES 的顺序排序热门国家
    popular.sort((a: string, b: string): number => {
      return POPULAR_COUNTRIES.indexOf(a) - POPULAR_COUNTRIES.indexOf(b);
    });

    // 其他国家按字母排序
    others.sort((a: string, b: string): number => a.localeCompare(b));

    // 合并结果
    return [...popular, ...others];
  }

  /**
   * 根据搜索关键词过滤国家列表
   * @returns 过滤后的国家列表
   */
  private getFilteredCountries(): string[] {
    if (!this.searchQuery || this.searchQuery.trim().length === 0) {
      return [...this.countries];
    }

    const query: string = this.searchQuery.trim().toLowerCase();
    return this.countries.filter((country: string): boolean =>
      country.toLowerCase().includes(query)
    );
  }

  /**
   * 切换下拉菜单显示状态
   */
  private toggleDropdown(): void {
    this.isDropdownOpen = !this.isDropdownOpen;
    if (!this.isDropdownOpen) {
      // 关闭时清空搜索词
      this.searchQuery = '';
    }
  }

  /**
   * 选择国家
   * @param country 国家名称
   */
  private selectCountry(country: string): void {
    this.isDropdownOpen = false;
    this.searchQuery = '';
    this.onSelect(country);
  }

  /**
   * 清除选择
   */
  private clearSelection(): void {
    this.isDropdownOpen = false;
    this.searchQuery = '';
    this.onClear();
  }

  build() {
    Column() {
      // 选择器触发区域
      this.SelectorTrigger();

      // 下拉菜单
      if (this.isDropdownOpen) {
        this.DropdownMenu();
      }
    }
    .width('100%')
  }

  /**
   * 选择器触发区域构建器
   * 显示当前选中的国家或占位文本
   */
  @Builder
  SelectorTrigger() {
    Row() {
      // 左侧图标
      SymbolGlyph($r('sys.symbol.globe'))
        .fontSize(20)
        .fontColor([$r('app.color.secondary_text')])

      // 选中国家或占位文本
      if (this.selectedCountry !== null && this.selectedCountry.length > 0) {
        // 选中的国家显示为标签/芯片样式
        this.SelectedCountryChip();
      } else {
        // 占位文本
        Text(this.placeholder)
          .fontSize(16)
          .fontColor([$r('app.color.secondary_text')])
          .layoutWeight(1)
          .margin({ left: 12 })
      }

      // 右侧下拉图标
      SymbolGlyph(this.isDropdownOpen ?
        $r('sys.symbol.chevron_up') :
        $r('sys.symbol.chevron_down'))
        .fontSize(16)
        .fontColor([$r('app.color.secondary_text')])
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor($r('app.color.input_background'))
    .borderRadius(12)
    .onClick(() => {
      this.toggleDropdown();
    })
  }

  /**
   * 选中国家芯片构建器
   * 显示选中的国家名称和清除按钮
   */
  @Builder
  SelectedCountryChip() {
    Row() {
      Text(this.selectedCountry ?? '')
        .fontSize(14)
        .fontColor([$r('app.color.primary_text')])
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })

      // 清除按钮
      Button() {
        SymbolGlyph($r('sys.symbol.xmark_circle_fill'))
          .fontSize(16)
          .fontColor([$r('app.color.secondary_text')])
      }
      .width(24)
      .height(24)
      .backgroundColor(Color.Transparent)
      .padding(0)
      .margin({ left: 8 })
      .onClick((event: ClickEvent) => {
        // 阻止事件冒泡，避免触发选择器
        event.stopPropagation();
        this.clearSelection();
      })
    }
    .layoutWeight(1)
    .height(32)
    .padding({ left: 12, right: 4 })
    .backgroundColor($r('app.color.chip_background'))
    .borderRadius(16)
    .margin({ left: 12 })
  }

  /**
   * 下拉菜单构建器
   * 包含搜索框和国家列表
   */
  @Builder
  DropdownMenu() {
    Column() {
      // 搜索框
      this.SearchInput();

      // 分隔线
      Divider()
        .color($r('app.color.divider'))

      // 国家列表
      if (this.getSortedCountries().length > 0) {
        this.CountryList();
      } else {
        // 空状态
        this.EmptyDropdownState();
      }
    }
    .width('100%')
    .maxHeight(300)
    .backgroundColor($r('app.color.card_background'))
    .borderRadius(12)
    .margin({ top: 8 })
    .shadow({
      radius: 16,
      color: '#1A000000',
      offsetX: 0,
      offsetY: 4
    })
  }

  /**
   * 搜索输入框构建器
   */
  @Builder
  SearchInput() {
    Row() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(16)
        .fontColor([$r('app.color.secondary_text')])

      TextInput({ text: this.searchQuery, placeholder: '搜索国家...' })
        .width('100%')
        .height(40)
        .fontSize(14)
        .fontColor($r('app.color.primary_text'))
        .placeholderColor($r('app.color.secondary_text'))
        .backgroundColor(Color.Transparent)
        .layoutWeight(1)
        .margin({ left: 8 })
        .onChange((value: string) => {
          this.searchQuery = value;
        })
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
  }

  /**
   * 国家列表构建器
   */
  @Builder
  CountryList() {
    List() {
      ForEach(this.getSortedCountries(), (country: string, index: number) => {
        ListItem() {
          this.CountryListItem(country);
        }
      }, (country: string, index: number): string => `${country}_${index}`)
    }
    .width('100%')
    .height(Math.min(this.getSortedCountries().length * 48, 240))
    .divider({
      strokeWidth: 1,
      color: $r('app.color.divider'),
      startMargin: 16,
      endMargin: 16
    })
  }

  /**
   * 国家列表项构建器
   * @param country 国家名称
   */
  @Builder
  CountryListItem(country: string) {
    Row() {
      // 国旗图标（使用地球图标代替）
      SymbolGlyph($r('sys.symbol.globe'))
        .fontSize(18)
        .fontColor([
          country === this.selectedCountry ?
            $r('app.color.primary') :
            $r('app.color.secondary_text')
        ])

      Text(country)
        .fontSize(14)
        .fontColor(
          country === this.selectedCountry ?
            $r('app.color.primary') :
            $r('app.color.primary_text')
        )
        .layoutWeight(1)
        .margin({ left: 12 })

      // 选中指示器
      if (country === this.selectedCountry) {
        SymbolGlyph($r('sys.symbol.checkmark'))
          .fontSize(16)
          .fontColor([$r('app.color.primary')])
      }

      // 热门国家标记
      if (POPULAR_COUNTRIES.includes(country) && country !== this.selectedCountry) {
        Text('热门')
          .fontSize(10)
          .fontColor(Color.White)
          .backgroundColor($r('app.color.primary'))
          .borderRadius(4)
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
      }
    }
    .width('100%')
    .height(48)
    .padding({ left: 16, right: 16 })
    .backgroundColor(
      country === this.selectedCountry ?
        $r('app.color.selected_background') :
        Color.Transparent
    )
    .onClick(() => {
      this.selectCountry(country);
    })
  }

  /**
   * 空状态构建器
   * 当没有匹配的国家时显示
   */
  @Builder
  EmptyDropdownState() {
    Column() {
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(32)
        .fontColor([$r('app.color.secondary_text')])
        .opacity(0.6)
        .margin({ bottom: 8 })

      Text('未找到匹配的国家')
        .fontSize(14)
        .fontColor($r('app.color.secondary_text'))
    }
    .width('100%')
    .height(100)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

/**
 * 便捷方法：创建国家筛选组件
 * @param params 组件参数
 */
export function CountryFilterBuilder(params: CountryFilterParams): void {
  CountryFilter({
    countries: params.countries,
    selectedCountry: params.selectedCountry,
    placeholder: params.placeholder ?? '选择国家'
  });
}
