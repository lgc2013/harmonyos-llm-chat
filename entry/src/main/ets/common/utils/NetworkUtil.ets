/**
 * 网络工具类
 * 遵循华为 UX 体验标准
 */
import connection from '@ohos.net.connection';
import Logger from './Logger';

/**
 * 网络工具类
 */
class NetworkUtil {
  /**
   * 检查网络是否连接
   * @returns 是否有网络连接
   */
  async isNetworkConnected(): Promise<boolean> {
    try {
      const netHandle = await connection.getDefaultNet();
      if (netHandle) {
        const capabilities = await connection.getNetCapabilities(netHandle);
        if (capabilities) {
          return true;
        }
      }
      return false;
    } catch (error) {
      const err = error as Error;
      Logger.error('Network check failed: ' + err.message);
      return false;
    }
  }

  /**
   * 获取网络类型
   * @returns 网络类型字符串
   */
  async getNetworkType(): Promise<string> {
    try {
      const netHandle = await connection.getDefaultNet();
      if (netHandle) {
        const capabilities = await connection.getNetCapabilities(netHandle);
        if (capabilities && capabilities.bearerTypes) {
          if (capabilities.bearerTypes.includes(connection.NetBearType.BEARER_WIFI)) {
            return 'WIFI';
          }
          if (capabilities.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR)) {
            return 'CELLULAR';
          }
        }
      }
      return 'UNKNOWN';
    } catch (error) {
      const err = error as Error;
      Logger.error('Get network type failed: ' + err.message);
      return 'UNKNOWN';
    }
  }
}

export default new NetworkUtil();
