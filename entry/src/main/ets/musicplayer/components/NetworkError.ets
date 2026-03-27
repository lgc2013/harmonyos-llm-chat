/**
 * 网络错误组件
 * 用于在网络请求失败时显示友好的错误提示
 * 支持可选的重试按钮，便于用户重新发起请求
 */

/**
 * 网络错误类型枚举
 */
export enum NetworkErrorType {
  /** 网络连接失败 */
  CONNECTION_FAILED = 'connection_failed',
  /** 请求超时 */
  TIMEOUT = 'timeout',
  /** 服务器错误 */
  SERVER_ERROR = 'server_error',
  /** 未知错误 */
  UNKNOWN = 'unknown'
}

/**
 * 网络错误组件参数接口
 */
export interface NetworkErrorParams {
  /** 错误消息（必填） */
  message: string;
  /** 错误类型（可选，用于显示不同图标） */
  errorType?: NetworkErrorType;
  /** 重试按钮文本（可选，默认为"重试"） */
  retryText?: string;
  /** 重试按钮点击回调（可选，提供时显示重试按钮） */
  onRetry?: () => void;
}

/**
 * 默认错误消息映射
 */
const DEFAULT_MESSAGES: Record<NetworkErrorType, string> = {
  [NetworkErrorType.CONNECTION_FAILED]: '网络连接失败，请检查网络设置',
  [NetworkErrorType.TIMEOUT]: '请求超时，请稍后重试',
  [NetworkErrorType.SERVER_ERROR]: '服务器暂时无法响应，请稍后重试',
  [NetworkErrorType.UNKNOWN]: '发生未知错误，请重试'
};

/**
 * 网络错误组件
 * 当网络请求失败时显示友好的错误提示界面
 *
 * @example
 * // 基本用法 - 网络连接失败
 * NetworkError({
 *   message: '网络连接失败',
 *   errorType: NetworkErrorType.CONNECTION_FAILED
 * })
 *
 * @example
 * // 带重试按钮
 * NetworkError({
 *   message: '请求超时',
 *   errorType: NetworkErrorType.TIMEOUT,
 *   retryText: '重新加载',
 *   onRetry: () => { this.reloadData() }
 * })
 */
@Component
export struct NetworkError {
  /** 错误消息 */
  @Prop message: string = '';

  /** 错误类型 */
  @Prop errorType?: NetworkErrorType;

  /** 重试按钮文本 */
  @Prop retryText: string = '重试';

  /** 重试按钮点击回调 */
  private onRetryCallback?: () => void;

  /**
   * 组件构造方法
   */
  aboutToAppear(): void {
    // 初始化完成
  }

  /**
   * 设置重试回调
   */
  onRetry(callback: () => void): NetworkError {
    this.onRetryCallback = callback;
    return this;
  }

  /**
   * 获取错误图标资源
   */
  private getErrorIcon(): Resource {
    // 使用系统提供的网络断开图标
    return $r('app.media.ohos_ic_public_wifi_off');
  }

  /**
   * 获取显示的错误消息
   */
  private getDisplayMessage(): string {
    if (this.message && this.message.length > 0) {
      return this.message;
    }
    // 根据错误类型返回默认消息
    if (this.errorType) {
      return DEFAULT_MESSAGES[this.errorType] || DEFAULT_MESSAGES[NetworkErrorType.UNKNOWN];
    }
    return DEFAULT_MESSAGES[NetworkErrorType.UNKNOWN];
  }

  build() {
    Column() {
      // 错误图标
      Image(this.getErrorIcon())
        .width(64)
        .height(64)
        .objectFit(ImageFit.Contain)
        .fillColor($r('sys.color.ohos_id_color_text_secondary'))
        .opacity(0.6)
        .margin({ bottom: 16 })

      // 错误标题
      Text('网络异常')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('sys.color.ohos_id_color_text_primary'))
        .textAlign(TextAlign.Center)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 8 })

      // 错误消息（14fp，次要颜色）
      Text(this.getDisplayMessage())
        .fontSize(14)
        .fontColor($r('sys.color.ohos_id_color_text_secondary'))
        .textAlign(TextAlign.Center)
        .maxLines(3)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ bottom: 24 })

      // 重试按钮（仅当提供重试回调时显示）
      if (this.onRetryCallback) {
        Button(this.retryText)
          .type(ButtonType.Capsule)
          .fontSize(14)
          .fontColor(Color.White)
          .backgroundColor($r('sys.color.ohos_id_color_emphasize'))
          .height(40)
          .padding({ left: 24, right: 24 })
          .onClick(() => {
            if (this.onRetryCallback) {
              this.onRetryCallback();
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
 * 便捷方法：创建网络错误组件
 * @param params 组件参数
 */
export function NetworkErrorBuilder(params: NetworkErrorParams): void {
  NetworkError({
    message: params.message,
    errorType: params.errorType,
    retryText: params.retryText || '重试'
  });
}
