/**
 * PreferencesService 测试
 */
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import PreferencesService from '../../../../main/ets/services/PreferencesService';

export default function preferencesServiceTest() {
  describe('PreferencesService', () => {
    const testApiKey = 'test-api-key-12345';

    it('should save API key successfully', async () => {
      await PreferencesService.saveApiKey(testApiKey);
      const savedKey = await PreferencesService.getApiKey();
      expect(savedKey).assertEqual(testApiKey);
    });

    it('should get API key successfully', async () => {
      await PreferencesService.saveApiKey(testApiKey);
      const key = await PreferencesService.getApiKey();
      expect(key).assertEqual(testApiKey);
    });

    it('should return true when API key exists', async () => {
      await PreferencesService.saveApiKey(testApiKey);
      const hasKey = await PreferencesService.hasApiKey();
      expect(hasKey).assertTrue();
    });

    it('should return false when API key does not exist', async () => {
      await PreferencesService.deleteApiKey();
      const hasKey = await PreferencesService.hasApiKey();
      expect(hasKey).assertFalse();
    });

    it('should delete API key successfully', async () => {
      await PreferencesService.saveApiKey(testApiKey);
      await PreferencesService.deleteApiKey();
      const hasKey = await PreferencesService.hasApiKey();
      expect(hasKey).assertFalse();
    });
  });
}
