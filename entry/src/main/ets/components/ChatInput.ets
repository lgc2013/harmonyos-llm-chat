/**
 * ChatInput 聊天输入组件
 * 遵循华为 UX 体验标准
 * - 发送按钮热区 ≥48vp×48vp (2.1.3.3)
 * - 输入框字体 ≥12vp (2.1.4.2)
 */
import { MESSAGE_CONFIG, ERROR_MESSAGES } from '../common/constants/Constants';

/**
 * 聊天输入组件
 */
@Component
export struct ChatInput {
  @Link text: string;
  @Prop disabled: boolean = false;
  onSend?: () => void;

  build() {
    Column() {
      // 输入区域
      Row() {
        // 文本输入框
        TextInput({
          placeholder: '输入消息...',
          text: this.text
        })
          .type(InputType.Normal)
          .height(48)
          .fontSize(16)
          .placeholderFont({ size: 14 })
          .placeholderColor($r('app.color.placeholder_text'))
          .fontColor($r('app.color.primary_text'))
          .backgroundColor($r('app.color.input_bg'))
          .borderRadius(24)
          .padding({ left: 16, right: 16 })
          .maxLength(MESSAGE_CONFIG.MAX_CONTENT_LENGTH)
          .enabled(!this.disabled)
          .layoutWeight(1)
          .onChange((value: string) => {
            this.text = value;
          })

        // 发送按钮 - 热区 48vp×48vp
        Button() {
          Text('发送')
            .fontSize(16)
            .fontColor(Color.White)
        }
        .width(48)
        .height(48)
        .borderRadius(24)
        .backgroundColor(this.canSend() ? $r('app.color.primary') : $r('app.color.disabled_bg'))
        .margin({ left: 12 })
        .enabled(this.canSend() && !this.disabled)
        .onClick(() => {
          if (this.onSend && this.canSend()) {
            this.onSend();
          }
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 8 })
      .alignItems(VerticalAlign.Center)

      // 字数提示
      if (this.text.length > MESSAGE_CONFIG.MAX_CONTENT_LENGTH * 0.8) {
        Row() {
          Text(`${this.text.length}/${MESSAGE_CONFIG.MAX_CONTENT_LENGTH}`)
            .fontSize(12)
            .fontColor(this.isOverLimit()
              ? $r('app.color.error')
              : $r('app.color.secondary_text'))
        }
        .width('100%')
        .justifyContent(FlexAlign.End)
        .padding({ right: 16 })
      }
    }
    .width('100%')
    .backgroundColor($r('app.color.input_area_bg'))
    .borderRadius({ topLeft: 16, topRight: 16 })
    .padding({ bottom: 16 })
  }

  private canSend(): boolean {
    return this.text.trim().length > 0 && !this.isOverLimit();
  }

  private isOverLimit(): boolean {
    return this.text.length > MESSAGE_CONFIG.MAX_CONTENT_LENGTH;
  }
}
