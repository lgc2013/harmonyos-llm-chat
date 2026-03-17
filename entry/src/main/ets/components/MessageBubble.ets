/**
 * MessageBubble 消息气泡组件
 * 遵循华为 UX 体验标准
 * - 色彩对比度 > 4.5:1 (2.1.4.1)
 * - 图标最小 8vp (2.1.4.3.2)
 */
import { ChatMessage } from '../models/ChatMessage';
import { MessageRole } from '../models/MessageRole';
import { MessageStatus } from '../models/MessageStatus';
import { UI_CONFIG } from '../common/constants/Constants';

/**
 * 消息气泡组件 - 使用 @ObjectLink 实现深度响应式更新
 */
@Component
export struct MessageBubble {
  @ObjectLink message: ChatMessage;
  onRetry?: () => void;

  build() {
    Row() {
      if (this.message.role === MessageRole.USER) {
        this.UserBubble()
      } else {
        this.AssistantBubble()
      }
    }
    .width('100%')
    .justifyContent(this.message.role === MessageRole.USER ? FlexAlign.End : FlexAlign.Start)
    .padding({ left: 16, right: 16, top: 8, bottom: 8 })
  }

  @Builder
  UserBubble() {
    Column() {
      // 消息内容
      Text(this.message.content)
        .fontSize(16)
        .fontColor(Color.White)
        .maxLines(100)
        .textOverflow({ overflow: TextOverflow.Clip })
        .padding(12)

      // 状态指示器
      Row() {
        if (this.message.status === MessageStatus.SENDING) {
          LoadingProgress()
            .width(16)
            .height(16)
            .color(Color.White)
        } else if (this.message.status === MessageStatus.FAILED) {
          Text('!')
            .fontSize(12)
            .fontColor(Color.White)
            .fontWeight(FontWeight.Bold)

          if (this.onRetry) {
            Text('重试')
              .fontSize(12)
              .fontColor(Color.White)
              .margin({ left: 4 })
              .onClick(() => {
                if (this.onRetry) {
                  this.onRetry();
                }
              })
          }
        }

        // 时间戳
        Text(this.formatTime(this.message.timestamp))
          .fontSize(10)
          .fontColor(Color.White)
          .opacity(0.7)
          .margin({ left: 8 })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .margin({ top: 4 })
    }
    .constraintSize({ maxWidth: '80%' })
    .backgroundColor($r('app.color.user_bubble_bg'))
    .borderRadius({
      topLeft: 16,
      topRight: 4,
      bottomLeft: 16,
      bottomRight: 16
    })
    .alignItems(HorizontalAlign.End)
  }

  @Builder
  AssistantBubble() {
    Column() {
      // 助手标识
      Row() {
        Text('GLM-5')
          .fontSize(12)
          .fontColor($r('app.color.secondary_text'))
          .fontWeight(FontWeight.Medium)
      }
      .width('100%')
      .margin({ bottom: 8 })

      // 消息内容
      Text(this.message.content)
        .fontSize(16)
        .fontColor($r('app.color.primary_text'))
        .maxLines(100)
        .textOverflow({ overflow: TextOverflow.Clip })

      // 状态和时间
      Row() {
        if (this.message.status === MessageStatus.FAILED && this.onRetry) {
          Text('重试')
            .fontSize(12)
            .fontColor($r('app.color.error'))
            .onClick(() => {
              if (this.onRetry) {
                this.onRetry();
              }
            })
        }

        Blank()

        Text(this.formatTime(this.message.timestamp))
          .fontSize(10)
          .fontColor($r('app.color.secondary_text'))
      }
      .width('100%')
      .margin({ top: 4 })
    }
    .constraintSize({ maxWidth: '80%' })
    .backgroundColor($r('app.color.assistant_bubble_bg'))
    .borderRadius({
      topLeft: 4,
      topRight: 16,
      bottomLeft: 16,
      bottomRight: 16
    })
    .padding(12)
    .alignItems(HorizontalAlign.Start)
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const hours = date.getHours().toString().padStart(2, '0');
    const minutes = date.getMinutes().toString().padStart(2, '0');
    return `${hours}:${minutes}`;
  }
}
