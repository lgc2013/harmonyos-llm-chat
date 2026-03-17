/**
 * Index 主聊天页面
 * 遵循华为 UX 体验标准
 */
import { ChatMessage } from '../models/ChatMessage';
import { MessageStatus } from '../models/MessageStatus';
import ChatViewModel from '../viewmodels/ChatViewModel';
import PreferencesService from '../services/PreferencesService';
import { MessageBubble } from '../components/MessageBubble';
import { ChatInput } from '../components/ChatInput';
import { LoadingIndicator } from '../components/LoadingIndicator';
import { SettingsPanel } from '../components/SettingsPanel';
import { UI_CONFIG } from '../common/constants/Constants';
import Logger from '../common/utils/Logger';

@Entry
@Component
struct Index {
  // 状态
  @State messages: ChatMessage[] = [];
  @State inputText: string = '';
  @State isLoading: boolean = false;
  @State error: string = '';
  @State showSettings: boolean = false;
  @State hasApiKey: boolean = false;

  // 视图模型和滚动控制器
  private viewModel = ChatViewModel;
  private scroller: Scroller = new Scroller();

  aboutToAppear() {
    this.initPage();
  }

  aboutToDisappear() {
    this.viewModel.cancel();
  }

  private async initPage(): Promise<void> {
    try {
      // 初始化视图模型
      await this.viewModel.init();

      // 设置消息变更回调
      this.viewModel.setOnMessagesChanged(() => {
        this.messages = this.viewModel.getMessages();
        this.scrollToBottom();
      });

      // 设置加载状态回调
      this.viewModel.setOnLoadingChanged((loading: boolean) => {
        this.isLoading = loading;
      });

      // 设置错误回调
      this.viewModel.setOnErrorChanged((errorMsg: string | null) => {
        this.error = errorMsg || '';
      });

      // 检查 API Key
      this.hasApiKey = await PreferencesService.hasApiKey();
      if (!this.hasApiKey) {
        this.showSettings = true;
      }

      Logger.info('Index page initialized');
    } catch (error) {
      const err = error as Error;
      Logger.error('Failed to initialize: ' + err.message);
    }
  }

  private scrollToBottom(): void {
    if (this.messages.length > 0) {
      this.scroller.scrollEdge(Edge.Bottom);
    }
  }

  build() {
    Stack({ alignContent: Alignment.TopEnd }) {
      // 主界面
      Column() {
        // 标题栏
        this.buildTitleBar()

        // 消息列表
        this.buildMessageList()

        // 加载指示器
        LoadingIndicator({
          visible: this.isLoading,
          text: '正在思考...'
        })

        // 错误提示
        if (this.error.length > 0) {
          this.buildErrorBanner()
        }

        // 输入区域
        ChatInput({
          text: $inputText,
          disabled: this.isLoading,
          onSend: () => {
            this.sendMessage();
          }
        })
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.page_bg'))

      // 设置面板
      if (this.showSettings) {
        SettingsPanel({
          visible: this.showSettings,
          onSave: async () => {
            this.showSettings = false;
            this.hasApiKey = true;
            this.error = '';
            // 重新加载 API Key 到 ChatViewModel
            await this.viewModel.reloadApiKey();
          },
          onDelete: () => {
            this.hasApiKey = false;
            this.showSettings = true;
          },
          onClose: () => {
            this.showSettings = false;
          }
        })
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildTitleBar() {
    Row() {
      Text('LLM Chat')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.primary_text'))
        .layoutWeight(1)

      // 设置按钮
      Button() {
        Text('⚙')
          .fontSize(20)
          .fontColor($r('app.color.primary_text'))
      }
      .width(48)
      .height(48)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.showSettings = true;
      })
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 8 })
    .backgroundColor($r('app.color.card_bg'))
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildMessageList() {
    List({ scroller: this.scroller }) {
      ForEach(this.messages, (message: ChatMessage) => {
        ListItem() {
          MessageBubble({
            message: message,
            onRetry: message.status === MessageStatus.FAILED
              ? () => {
                  this.viewModel.retryMessage(message.id);
                }
              : undefined
          })
        }
      }, (message: ChatMessage) => message.id)
    }
    .width('100%')
    .layoutWeight(1)
    .edgeEffect(EdgeEffect.Spring)
  }

  @Builder
  buildErrorBanner() {
    Row() {
      Text(this.error)
        .fontSize(14)
        .fontColor(Color.White)
        .layoutWeight(1)

      Button() {
        Text('×')
          .fontSize(18)
          .fontColor(Color.White)
      }
      .width(32)
      .height(32)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        this.error = '';
      })
    }
    .width('100%')
    .padding({ left: 16, right: 8, top: 12, bottom: 12 })
    .backgroundColor($r('app.color.error'))
    .alignItems(VerticalAlign.Center)
  }

  private sendMessage(): void {
    this.viewModel.setInputText(this.inputText);
    this.viewModel.sendMessage();
    this.inputText = '';
  }
}

export default Index;
