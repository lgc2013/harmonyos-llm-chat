/**
 * 聊天消息模型
 * 遵循华为 UX 体验标准
 */
import { MessageRole } from './MessageRole';
import { MessageStatus } from './MessageStatus';
import { MESSAGE_CONFIG } from '../common/constants/Constants';

/**
 * 聊天消息类 - 使用 @Observed 支持深度响应式更新
 */
@Observed
export class ChatMessage {
  /** 消息唯一标识 (UUID) */
  id: string = '';
  /** 消息角色 */
  role: MessageRole = MessageRole.USER;
  /** 消息内容 (1-2000字符) */
  content: string = '';
  /** 消息状态 */
  status: MessageStatus = MessageStatus.SENDING;
  /** 时间戳 (毫秒) */
  timestamp: number = 0;
  /** 错误信息（可选） */
  error?: string;

  constructor(
    id: string,
    role: MessageRole,
    content: string,
    status: MessageStatus,
    timestamp: number,
    err?: string
  ) {
    this.id = id;
    this.role = role;
    this.content = content;
    this.status = status;
    this.timestamp = timestamp;
    if (err !== undefined) {
      this.error = err;
    }
  }
}

/**
 * 创建新消息的工厂函数
 */
export function createMessage(
  role: MessageRole,
  content: string,
  id?: string
): ChatMessage {
  return new ChatMessage(
    id || generateUUID(),
    role,
    content,
    MessageStatus.SENDING,
    Date.now()
  );
}

/**
 * 生成 UUID v4
 */
export function generateUUID(): string {
  const chars: string = '0123456789abcdef';
  let result: string = '';

  for (let i = 0; i < 36; i++) {
    if (i === 8 || i === 13 || i === 18 || i === 23) {
      result += '-';
    } else if (i === 14) {
      result += '4';
    } else if (i === 19) {
      result += chars.charAt(Math.floor(Math.random() * 4) + 8);
    } else {
      result += chars.charAt(Math.floor(Math.random() * 16));
    }
  }

  return result;
}

/**
 * 验证消息内容
 * @param content 消息内容
 * @returns 是否有效
 */
export function validateContent(content: string): boolean {
  const trimmed: string = content.trim();
  return trimmed.length >= MESSAGE_CONFIG.MIN_CONTENT_LENGTH &&
         trimmed.length <= MESSAGE_CONFIG.MAX_CONTENT_LENGTH;
}

/**
 * 更新消息内容（直接修改对象属性，配合 @Observed 使用）
 */
export function updateMessageContent(message: ChatMessage, newContent: string): void {
  message.content = newContent;
}

/**
 * 更新消息状态（直接修改对象属性，配合 @Observed 使用）
 */
export function updateMessageStatus(message: ChatMessage, newStatus: MessageStatus, errorMsg?: string): void {
  message.status = newStatus;
  if (errorMsg !== undefined) {
    message.error = errorMsg;
  }
}

export default ChatMessage;
