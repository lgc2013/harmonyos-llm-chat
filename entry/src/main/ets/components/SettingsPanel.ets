/**
 * SettingsPanel 设置面板组件
 * 遵循华为 UX 体验标准
 */
import { UI_CONFIG, ERROR_MESSAGES, STORAGE_KEYS } from '../common/constants/Constants';
import PreferencesService from '../services/PreferencesService';
import GLMService from '../services/GLMService';
import Logger from '../common/utils/Logger';

/**
 * 设置面板组件
 */
@Component
export struct SettingsPanel {
  @Prop visible: boolean = false;
  @State inputApiKey: string = '';
  @State isSaving: boolean = false;
  @State showSuccess: boolean = false;
  @State errorMessage: string = '';
  onSave?: () => void;
  onDelete?: () => void;
  onClose?: () => void;

  build() {
    if (this.visible) {
      Column() {
        // 标题栏
        Row() {
          Button() {
            Text('←')
              .fontSize(24)
              .fontColor($r('app.color.primary_text'))
          }
          .width(48)
          .height(48)
          .backgroundColor(Color.Transparent)
          .onClick(() => {
            if (this.onClose) {
              this.onClose();
            }
          })

          Text('设置')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor($r('app.color.primary_text'))
            .margin({ left: 8 })
            .layoutWeight(1)
        }
        .width('100%')
        .height(56)
        .padding({ left: 8, right: 16 })
        .alignItems(VerticalAlign.Center)

        // API Key 输入区域
        Column() {
          Text('GLM-5 API Key')
            .fontSize(14)
            .fontColor($r('app.color.secondary_text'))
            .width('100%')

          TextInput({
            placeholder: '请输入您的 API Key'
          })
            .type(InputType.Password)
            .width('100%')
            .height(48)
            .fontSize(16)
            .placeholderFont({ size: 14 })
            .margin({ top: 8 })
            .onChange((value: string) => {
              this.inputApiKey = value;
              this.errorMessage = '';
            })

          // 错误提示
          if (this.errorMessage.length > 0) {
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor($r('app.color.error'))
              .margin({ top: 8 })
              .width('100%')
          }

          // 成功提示
          if (this.showSuccess) {
            Text('API Key 保存成功！')
              .fontSize(12)
              .fontColor($r('app.color.success'))
              .margin({ top: 8 })
              .width('100%')
          }

          // 说明文字
          Text('API Key 将安全存储在您的设备上，不会上传到服务器。')
            .fontSize(12)
            .fontColor($r('app.color.secondary_text'))
            .margin({ top: 16 })
            .width('100%')

          // 获取 API Key 链接
          Text('如何获取 API Key？')
            .fontSize(14)
            .fontColor($r('app.color.link'))
            .margin({ top: 8 })
            .onClick(() => {
              Logger.info('Open API Key guide');
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.card_bg'))
        .borderRadius(12)
        .margin({ top: 16, left: 16, right: 16 })

        // 操作按钮
        Column() {
          // 保存按钮
          Button() {
            Text('保存')
              .fontSize(16)
              .fontColor(Color.White)
          }
          .width('100%')
          .height(48)
          .backgroundColor($r('app.color.primary'))
          .borderRadius(24)
          .enabled(!this.isSaving && this.inputApiKey.trim().length > 0)
          .onClick(async () => {
            await this.saveApiKey();
          })

          // 删除按钮
          Button() {
            Text('删除 API Key')
              .fontSize(16)
              .fontColor($r('app.color.error'))
          }
          .width('100%')
          .height(48)
          .backgroundColor(Color.Transparent)
          .borderRadius(24)
          .margin({ top: 12 })
          .onClick(async () => {
            await this.deleteApiKey();
          })
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 24 })

        Blank()
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_bg'))
      .transition(TransitionEffect.OPACITY.animation({
        duration: UI_CONFIG.MIN_TRANSITION_DURATION,
        curve: Curve.EaseInOut
      }))
    }
  }

  private async saveApiKey(): Promise<void> {
    const trimmedKey = this.inputApiKey.trim();

    if (trimmedKey.length === 0) {
      this.errorMessage = 'API Key 不能为空';
      return;
    }

    this.isSaving = true;
    this.errorMessage = '';
    this.showSuccess = false;

    try {
      await PreferencesService.saveApiKey(trimmedKey);
      GLMService.setApiKey(trimmedKey);
      this.showSuccess = true;

      if (this.onSave) {
        this.onSave();
      }

      Logger.info('API Key saved successfully');

      setTimeout(() => {
        this.showSuccess = false;
      }, 3000);
    } catch (error) {
      const err = error as Error;
      this.errorMessage = '保存失败：' + err.message;
      Logger.error('Failed to save API Key: ' + err.message);
    } finally {
      this.isSaving = false;
    }
  }

  private async deleteApiKey(): Promise<void> {
    try {
      await PreferencesService.deleteApiKey();
      this.inputApiKey = '';
      GLMService.setApiKey('');

      if (this.onDelete) {
        this.onDelete();
      }

      Logger.info('API Key deleted successfully');
    } catch (error) {
      const err = error as Error;
      this.errorMessage = '删除失败：' + err.message;
      Logger.error('Failed to delete API Key: ' + err.message);
    }
  }
}
