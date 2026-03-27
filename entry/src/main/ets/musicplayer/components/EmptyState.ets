/**
 * 空状态组件
 * 用于在列表或内容区域为空时显示友好的提示信息
 * 支持可选的操作按钮，便于用户执行后续操作
 */

/**
 * 空状态组件参数接口
 */
export interface EmptyStateParams {
  /** 图标资源（可选，默认使用应用图标） */
  icon?: Resource;
  /** 标题文本（必填） */
  title: string;
  /** 描述文本（可选） */
  description?: string;
  /** 操作按钮文本（可选，提供时显示操作按钮） */
  actionText?: string;
  /** 操作按钮点击回调（可选） */
  onAction?: () => void;
}

/**
 * 空状态组件
 * 当内容区域无数据时显示友好的提示界面
 *
 * @example
 * // 基本用法
 * EmptyState({
 *   title: '暂无音乐',
 *   description: '您的音乐库为空'
 * })
 *
 * @example
 * // 带操作按钮
 * EmptyState({
 *   title: '暂无播放列表',
 *   description: '创建您的第一个播放列表',
 *   actionText: '创建播放列表',
 *   onActionCallback: () => { this.createPlaylist() }
 * })
 */
@Component
export struct EmptyState {
  /** 图标资源 */
  @Prop icon?: Resource;

  /** 标题文本 */
  @Prop title: string = '';

  /** 描述文本 */
  @Prop description?: string;

  /** 操作按钮文本 */
  @Prop actionText?: string;

  /** 操作按钮点击回调 */
  onActionCallback?: () => void;

  /**
   * 组件构造方法
   * @param params 组件参数
   */
  aboutToAppear(): void {
    // 初始化完成
  }

  build() {
    Column() {
      // 图标
      if (this.icon) {
        Image(this.icon)
          .width(64)
          .height(64)
          .objectFit(ImageFit.Contain)
          .fillColor($r('sys.color.ohos_id_color_text_secondary'))
          .opacity(0.6)
          .margin({ bottom: 16 })
      } else {
        // 默认图标 - 使用自定义空状态图标
        SymbolGlyph($r('sys.symbol.inbox'))
          .fontSize(64)
          .fontColor([$r('sys.color.ohos_id_color_text_secondary')])
          .opacity(0.6)
          .margin({ bottom: 16 })
      }

      // 标题
      Text(this.title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: this.description ? 8 : 16 })

      // 描述（可选）
      if (this.description) {
        Text(this.description)
          .fontSize(14)
          .fontColor($r('sys.color.ohos_id_color_text_secondary'))
          .textAlign(TextAlign.Center)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ bottom: 24 })
      }

      // 操作按钮（可选）
      if (this.actionText && this.actionText.length > 0) {
        Button(this.actionText)
          .type(ButtonType.Capsule)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
          .height(40)
          .padding({ left: 24, right: 24 })
          .onClick(() => {
            if (this.onActionCallback) {
              this.onActionCallback();
            }
          })
      }
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding({ left: 32, right: 32, top: 48, bottom: 48 })
  }
}

/**
 * 便捷方法：创建空状态组件
 * @param params 组件参数
 */
export function EmptyStateBuilder(params: EmptyStateParams): void {
  EmptyState({
    icon: params.icon,
    title: params.title,
    description: params.description,
    actionText: params.actionText
  });
}
