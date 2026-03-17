/**
 * 日志工具类
 * 遵循华为设计最佳实践
 */
import hilog from '@ohos.hilog';

const DOMAIN = 0x0001;
const TAG = 'LLMChat';

/**
 * 日志工具类
 */
class Logger {
  /**
   * 调试日志
   */
  static debug(message: string, ...args: string[]): void {
    hilog.debug(DOMAIN, TAG, message, ...args);
  }

  /**
   * 信息日志
   */
  static info(message: string, ...args: string[]): void {
    hilog.info(DOMAIN, TAG, message, ...args);
  }

  /**
   * 警告日志
   */
  static warn(message: string, ...args: string[]): void {
    hilog.warn(DOMAIN, TAG, message, ...args);
  }

  /**
   * 错误日志
   */
  static error(message: string, ...args: string[]): void {
    hilog.error(DOMAIN, TAG, message, ...args);
  }

  /**
   * 致命错误日志
   */
  static fatal(message: string, ...args: string[]): void {
    hilog.fatal(DOMAIN, TAG, message, ...args);
  }
}

export default Logger;
