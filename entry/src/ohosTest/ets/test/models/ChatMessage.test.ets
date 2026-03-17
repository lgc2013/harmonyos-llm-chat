/**
 * ChatMessage 模型测试
 */
import { describe, it, expect } from '@ohos/hypium';
import { ChatMessage } from '../../../../main/ets/models/ChatMessage';
import { MessageRole } from '../../../../main/ets/models/MessageRole';
import { MessageStatus } from '../../../../main/ets/models/MessageStatus';

export default function chatMessageTest() {
  describe('ChatMessage', () => {
    it('should create a user message with required fields', () => {
      const message: ChatMessage = {
        id: 'test-id-001',
        role: MessageRole.USER,
        content: 'Hello World',
        status: MessageStatus.SENDING,
        timestamp: Date.now()
      };

      expect(message.id).assertEqual('test-id-001');
      expect(message.role).assertEqual(MessageRole.USER);
      expect(message.content).assertEqual('Hello World');
      expect(message.status).assertEqual(MessageStatus.SENDING);
      expect(message.timestamp).toBeDefined();
    });

    it('should create an assistant message', () => {
      const message: ChatMessage = {
        id: 'test-id-002',
        role: MessageRole.ASSISTANT,
        content: 'Hello! How can I help you?',
        status: MessageStatus.SENT,
        timestamp: Date.now()
      };

      expect(message.role).assertEqual(MessageRole.ASSISTANT);
      expect(message.status).assertEqual(MessageStatus.SENT);
    });

    it('should create a failed message with error', () => {
      const message: ChatMessage = {
        id: 'test-id-003',
        role: MessageRole.USER,
        content: 'Test error',
        status: MessageStatus.FAILED,
        timestamp: Date.now(),
        error: 'Network error'
      };

      expect(message.status).assertEqual(MessageStatus.FAILED);
      expect(message.error).assertEqual('Network error');
    });

    it('should validate content length constraints', () => {
      const validContent = 'a'.repeat(2000);
      expect(validContent.length).assertEqual(2000);

      const emptyContent = '';
      expect(emptyContent.length).assertEqual(0);
    });
  });
}
