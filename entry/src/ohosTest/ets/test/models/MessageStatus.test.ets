/**
 * MessageStatus 枚举测试
 */
import { describe, it, expect } from '@ohos/hypium';
import { MessageStatus } from '../../../../main/ets/models/MessageStatus';

export default function messageStatusTest() {
  describe('MessageStatus', () => {
    it('should have SENDING status', () => {
      expect(MessageStatus.SENDING).assertEqual('sending');
    });

    it('should have SENT status', () => {
      expect(MessageStatus.SENT).assertEqual('sent');
    });

    it('should have FAILED status', () => {
      expect(MessageStatus.FAILED).assertEqual('failed');
    });

    it('should have exactly 3 status values', () => {
      const statusCount = Object.keys(MessageStatus).length;
      expect(statusCount).assertEqual(3);
    });
  });
}
