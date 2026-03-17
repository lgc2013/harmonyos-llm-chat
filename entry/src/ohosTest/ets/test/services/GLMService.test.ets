/**
 * GLMService 测试
 */
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import GLMService from '../../../../main/ets/services/GLMService';
import { MessageRole } from '../../../../main/ets/models/MessageRole';

export default function glmServiceTest() {
  describe('GLMService', () => {
    const testApiKey = 'test-api-key-12345';

    beforeEach(async () => {
      // 初始化服务
    });

    it('should initialize with API key', () => {
      GLMService.setApiKey(testApiKey);
      expect(GLMService.getApiKey()).assertEqual(testApiKey);
    });

    it('should validate API key format', () => {
      const isValid = GLMService.validateApiKeyFormat(testApiKey);
      expect(isValid).assertTrue();
    });

    it('should reject empty API key', () => {
      const isValid = GLMService.validateApiKeyFormat('');
      expect(isValid).assertFalse();
    });

    it('should build correct request body', () => {
      const message = 'Hello, how are you?';
      const requestBody = GLMService.buildRequestBody(message);
      expect(requestBody.model).assertEqual('glm-5');
      expect(requestBody.stream).assertTrue();
      expect(requestBody.messages[0].role).assertEqual('user');
      expect(requestBody.messages[0].content).assertEqual(message);
    });

    it('should parse SSE stream data correctly', () => {
      const sseData = 'data: {"choices":[{"delta":{"content":"Hello"}}]}';
      const content = GLMService.parseSSELine(sseData);
      expect(content).assertEqual('Hello');
    });

    it('should handle SSE [DONE] marker', () => {
      const sseData = 'data: [DONE]';
      const content = GLMService.parseSSELine(sseData);
      expect(content).assertNull();
    });

    it('should handle empty SSE line', () => {
      const content = GLMService.parseSSELine('');
      expect(content).assertNull();
    });
  });
}
