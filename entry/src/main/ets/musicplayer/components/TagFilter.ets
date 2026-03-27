/**
 * TagFilter 标签筛选组件
 * 用于水平滚动显示标签列表，支持单选和清除功能
 * 遵循华为 UX 体验标准，支持深色模式
 */

/**
 * 标签筛选组件参数接口
 */
export interface TagFilterParams {
  /** 标签列表 */
  tags: string[];
  /** 当前选中的标签 */
  selectedTag?: string | null;
  /** 是否显示"全部"选项 */
  showAllOption?: boolean;
  /** "全部"选项的文本 */
  allOptionText?: string;
}

/**
 * 标签筛选组件
 * 水平滚动的标签选择器，支持单选和清除
 *
 * @example
 * // 基本用法
 * TagFilter({
 *   tags: ['流行', '摇滚', '古典', '爵士'],
 *   selectedTag: this.selectedTag,
 *   onSelect: (tag: string) => { this.selectedTag = tag; },
 *   onClear: () => { this.selectedTag = null; }
 * })
 *
 * @example
 * // 带"全部"选项
 * TagFilter({
 *   tags: this.genreList,
 *   selectedTag: this.filter,
 *   showAllOption: true,
 *   allOptionText: '全部音乐',
 *   onSelect: (tag: string) => { this.applyFilter(tag); },
 *   onClear: () => { this.clearFilter(); }
 * })
 */
@Component
export struct TagFilter {
  /** 标签列表 */
  @Prop tags: string[] = [];

  /** 当前选中的标签 */
  @Prop selectedTag: string | null = null;

  /** 是否显示"全部"选项 */
  @Prop showAllOption: boolean = true;

  /** "全部"选项的文本 */
  @Prop allOptionText: string = '全部';

  /** 标签选中事件回调 */
  onSelect?: (tag: string) => void;

  /** 清除选择事件回调 */
  onClear?: () => void;

  /** 标签项高度 */
  @Prop itemHeight: number = 36;

  /** 标签项水平内边距 */
  @Prop itemPadding: number = 16;

  /** 标签项圆角半径 */
  @Prop itemBorderRadius: number = 18;

  /** 标签字体大小 */
  @Prop itemFontSize: number = 14;

  /** 列表项间距 */
  @Prop itemSpacing: number = 8;

  /** 组件左侧内边距 */
  @Prop listPaddingLeft: number = 16;

  /** 组件右侧内边距 */
  @Prop listPaddingRight: number = 16;

  /**
   * 检查标签是否选中
   * @param tag 标签名称
   * @returns 是否选中
   */
  private isTagSelected(tag: string): boolean {
    return this.selectedTag === tag;
  }

  /**
   * 检查是否选中了"全部"选项
   * @returns 是否选中"全部"
   */
  private isAllSelected(): boolean {
    return this.selectedTag === null || this.selectedTag === '';
  }

  /**
   * 处理标签点击事件
   * @param tag 标签名称
   */
  private handleTagClick(tag: string): void {
    if (this.onSelect) {
      this.onSelect(tag);
    }
  }

  /**
   * 处理"全部"选项点击事件
   */
  private handleAllClick(): void {
    if (this.onClear) {
      this.onClear();
    }
  }

  /**
   * 构建单个标签项
   * @param tag 标签名称
   * @param isSelected 是否选中
   * @param onClick 点击回调
   */
  @Builder
  private buildTagItem(tag: string, isSelected: boolean, onClick: () => void) {
    Text(tag)
      .fontSize(this.itemFontSize)
      .fontWeight(isSelected ? FontWeight.Medium : FontWeight.Normal)
      .fontColor(isSelected ? Color.White : $r('sys.color.ohos_id_color_text_primary'))
      .height(this.itemHeight)
      .padding({ left: this.itemPadding, right: this.itemPadding })
      .borderRadius(this.itemBorderRadius)
      .backgroundColor(isSelected ?
        $r('sys.color.ohos_id_color_emphasize') :
        $r('sys.color.ohos_id_color_button_normal'))
      .onClick(() => onClick())
      .focusable(true)
      .defaultFocus(isSelected)
  }

  build() {
    // 如果没有标签且不显示"全部"选项，则不渲染
    if (this.tags.length === 0 && !this.showAllOption) {
      return;
    }

    Scroll(Scroller) {
      Row() {
        // "全部"选项
        if (this.showAllOption) {
          Text(this.allOptionText)
            .fontSize(this.itemFontSize)
            .fontWeight(this.isAllSelected() ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.isAllSelected() ? Color.White : $r('sys.color.ohos_id_color_text_primary'))
            .height(this.itemHeight)
            .padding({ left: this.itemPadding, right: this.itemPadding })
            .borderRadius(this.itemBorderRadius)
            .backgroundColor(this.isAllSelected() ?
              $r('sys.color.ohos_id_color_emphasize') :
              $r('sys.color.ohos_id_color_button_normal'))
            .onClick(() => this.handleAllClick())
            .focusable(true)
            .defaultFocus(this.isAllSelected())
            .margin({ right: this.itemSpacing })
        }

        // 标签列表
        ForEach(this.tags, (tag: string, index: number) => {
          Text(tag)
            .fontSize(this.itemFontSize)
            .fontWeight(this.isTagSelected(tag) ? FontWeight.Medium : FontWeight.Normal)
            .fontColor(this.isTagSelected(tag) ? Color.White : $r('sys.color.ohos_id_color_text_primary'))
            .height(this.itemHeight)
            .padding({ left: this.itemPadding, right: this.itemPadding })
            .borderRadius(this.itemBorderRadius)
            .backgroundColor(this.isTagSelected(tag) ?
              $r('sys.color.ohos_id_color_emphasize') :
              $r('sys.color.ohos_id_color_button_normal'))
            .onClick(() => this.handleTagClick(tag))
            .focusable(true)
            .defaultFocus(this.isTagSelected(tag))
            .margin({ right: index === this.tags.length - 1 ? 0 : this.itemSpacing })
        }, (tag: string) => tag)
      }
      .width('100%')
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .width('100%')
    .padding({ left: this.listPaddingLeft, right: this.listPaddingRight })
  }
}

/**
 * 便捷方法：创建标签筛选组件
 * @param params 组件参数
 */
export function TagFilterBuilder(params: TagFilterParams): void {
  TagFilter({
    tags: params.tags,
    selectedTag: params.selectedTag,
    showAllOption: params.showAllOption ?? true,
    allOptionText: params.allOptionText ?? '全部'
  });
}
