/**
 * 音乐播放器工具函数
 * 提供通用的工具方法
 */

/**
 * 防抖函数类型定义
 */
export type DebounceFunction = (...args: Object[]) => void;

/**
 * 将毫秒转换为 "mm:ss" 格式的时间字符串
 * @param ms 毫秒数
 * @returns 格式化的时间字符串，如 "03:45"
 */
export function formatTime(ms: number): string {
  // 确保输入为非负数
  const safeMs: number = Math.max(0, ms);
  const totalSeconds: number = Math.floor(safeMs / 1000);
  const minutes: number = Math.floor(totalSeconds / 60);
  const seconds: number = totalSeconds % 60;

  // 使用 padStart 确保两位数格式
  const minutesStr: string = minutes.toString().padStart(2, '0');
  const secondsStr: string = seconds.toString().padStart(2, '0');

  return `${minutesStr}:${secondsStr}`;
}

/**
 * 生成唯一ID
 * @param prefix ID前缀，如 "song"、"playlist" 等
 * @returns 带前缀的唯一ID字符串
 */
export function generateId(prefix: string): string {
  const timestamp: number = Date.now();
  const random: string = Math.random().toString(36).substring(2, 9);
  return `${prefix}_${timestamp}_${random}`;
}

/**
 * 将值限制在指定范围内
 * @param value 要限制的值
 * @param min 最小值
 * @param max 最大值
 * @returns 限制后的值
 */
export function clamp(value: number, min: number, max: number): number {
  // 确保范围有效
  const safeMin: number = Math.min(min, max);
  const safeMax: number = Math.max(min, max);

  return Math.max(safeMin, Math.min(safeMax, value));
}

/**
 * 创建防抖函数
 * @param fn 要防抖的函数
 * @param delay 延迟时间（毫秒）
 * @returns 防抖后的函数
 */
export function debounce(
  fn: (...args: Object[]) => void,
  delay: number
): DebounceFunction {
  let timer: number | undefined = undefined;

  return (...args: Object[]): void => {
    // 清除之前的定时器
    if (timer !== undefined) {
      clearTimeout(timer);
    }

    // 设置新的定时器
    timer = setTimeout((): void => {
      fn(...args);
      timer = undefined;
    }, delay);
  };
}

/**
 * 格式化文件大小
 * @param bytes 字节数
 * @returns 格式化的文件大小字符串
 */
export function formatFileSize(bytes: number): string {
  const safeBytes: number = Math.max(0, bytes);
  const units: string[] = ['B', 'KB', 'MB', 'GB'];
  let index: number = 0;
  let size: number = safeBytes;

  while (size >= 1024 && index < units.length - 1) {
    size /= 1024;
    index++;
  }

  return `${size.toFixed(1)} ${units[index]}`;
}

/**
 * 检查是否为有效的URL
 * @param url 要检查的URL字符串
 * @returns 是否为有效URL
 */
export function isValidUrl(url: string): boolean {
  if (url === null || url === undefined || url.trim() === '') {
    return false;
  }

  // 使用正则表达式验证 URL
  const urlPattern: RegExp = /^(https?:\/\/)?([\da-z.-]+)\.([a-z.]{2,6})([/\w .-]*)*\/?$/i;
  return urlPattern.test(url.trim());
}

/**
 * 深拷贝对象（使用 JSON 序列化实现）
 * @param obj 要拷贝的对象
 * @returns 拷贝后的新对象
 */
export function deepClone<T>(obj: T): T {
  if (obj === null || typeof obj !== 'object') {
    return obj;
  }

  // 使用 JSON 序列化实现深拷贝
  // 注意：此方法不支持函数、undefined、Symbol 等特殊类型
  const json: string = JSON.stringify(obj);
  return JSON.parse(json) as T;
}
