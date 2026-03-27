/**
 * CreatePlaylistDialog - 创建播放列表对话框
 * 允许用户输入新播放列表名称
 * 遵循华为 UX 体验标准
 */

/**
 * 创建播放列表对话框组件
 */
@CustomDialog
export struct CreatePlaylistDialog {
  /** 对话框控制器 */
  controller: CustomDialogController;

  /** 确认回调 */
  onConfirm: (name: string) => void = () => {};
  
  /** 取消回调 */
  onCancel: () => void = () => {};

  /** 输入的播放列表名称 */
  @State private playlistName: string = '';
  
  /** 错误提示 */
  @State private errorMessage: string = '';
  
  /** 最大名称长度 */
  private readonly MAX_NAME_LENGTH: number = 50;

  /**
   * 验证输入
   */
  private validateInput(): boolean {
    const trimmedName = this.playlistName.trim();
    
    if (trimmedName.length === 0) {
      this.errorMessage = '播放列表名称不能为空';
      return false;
    }
    
    if (trimmedName.length > this.MAX_NAME_LENGTH) {
      this.errorMessage = '名称不能超过50个字符';
      return false;
    }
    
    this.errorMessage = '';
    return true;
  }

  /**
   * 处理确认操作
   */
  private handleConfirm(): void {
    if (this.validateInput()) {
      this.controller.close();
      this.onConfirm(this.playlistName.trim());
    }
  }

  /**
   * 处理取消操作
   */
  private handleCancel(): void {
    this.controller.close();
    this.onCancel();
  }

  build() {
    Column() {
      // 标题
      Text('新建播放列表')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: 20 })

      // 输入框
      TextInput({ placeholder: '输入播放列表名称', text: this.playlistName })
        .fontSize(16)
        .maxLength(this.MAX_NAME_LENGTH)
        .onChange((value: string) => {
          this.playlistName = value;
          if (this.errorMessage) {
            this.validateInput();
          }
        })
        .onSubmit(() => {
          this.handleConfirm();
        })
        .width('100%')
        .margin({ bottom: 8 })

      // 字符计数
      Row() {
        Text(`${this.playlistName.length}/${this.MAX_NAME_LENGTH}`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .margin({ bottom: 8 })

      // 错误提示
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(12)
          .fontColor('#FF0000')
          .margin({ bottom: 16 })
      }

      // 按钮行
      Row() {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .onClick(() => this.handleCancel())
          .layoutWeight(1)

        Blank().width(16)

        Button('确定')
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor('#007DFF')
          .enabled(this.playlistName.trim().length > 0)
          .onClick(() => this.handleConfirm())
          .layoutWeight(1)
      }
      .width('100%')
    }
    .padding(24)
    .backgroundColor('#FFFFFF')
    .borderRadius(16)
  }
}
