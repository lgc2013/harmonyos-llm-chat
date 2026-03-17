/**
 * LoadingIndicator 加载指示器组件
 * 遵循华为 UX 体验标准
 */
import { UI_CONFIG } from '../common/constants/Constants';

/**
 * 加载指示器组件
 */
@Component
export struct LoadingIndicator {
  @Prop visible: boolean = false;
  @Prop text: string = '正在思考...';

  build() {
    if (this.visible) {
      Row() {
        LoadingProgress()
          .width(24)
          .height(24)
          .color($r('app.color.loading_indicator'))

        if (this.text.length > 0) {
          Text(this.text)
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
            .margin({ left: 12 })
        }
      }
      .width('100%')
      .height(48)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .opacity(this.visible ? 1 : 0)
      .animation({
        duration: 200,
        curve: Curve.EaseInOut
      })
    }
  }
}
