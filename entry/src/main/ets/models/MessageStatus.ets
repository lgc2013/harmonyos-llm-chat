/**
 * 消息状态枚举
 * 遵循华为 UX 体验标准
 */
export enum MessageStatus {
  SENDING = 'sending',   // 发送中
  SENT = 'sent',         // 已发送
  FAILED = 'failed'      // 发送失败
}

export default MessageStatus;
