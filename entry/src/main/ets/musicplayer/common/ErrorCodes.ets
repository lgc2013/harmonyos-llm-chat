/**
 * 音乐播放器错误码定义
 * 用于统一管理应用中的错误码和错误信息
 */

/**
 * 播放器错误码
 */
export enum PlayerErrorCode {
  /** 无播放项目 */
  PLAYER_NO_ITEM = 1001,
  /** 音源错误 */
  PLAYER_SOURCE_ERROR = 1002,
  /** 网络错误 */
  PLAYER_NETWORK_ERROR = 1003,
  /** 跳转错误 */
  PLAYER_SEEK_ERROR = 1004,
  /** 无下一首 */
  PLAYER_NO_NEXT = 1005,
  /** 无上一首 */
  PLAYER_NO_PREVIOUS = 1006
}

/**
 * 播放列表错误码
 */
export enum PlaylistErrorCode {
  /** 播放列表未找到 */
  PLAYLIST_NOT_FOUND = 2001,
  /** 播放列表名称为空 */
  PLAYLIST_NAME_EMPTY = 2002,
  /** 播放列表名称过长 */
  PLAYLIST_NAME_TOO_LONG = 2003,
  /** 系统播放列表不可修改 */
  PLAYLIST_IS_SYSTEM = 2004,
  /** 播放列表已满 */
  PLAYLIST_FULL = 2005,
  /** 重复添加 */
  PLAYLIST_DUPLICATE = 2006
}

/**
 * 媒体库错误码
 */
export enum LibraryErrorCode {
  /** 权限被拒绝 */
  PERMISSION_DENIED = 3001,
  /** 扫描错误 */
  SCAN_ERROR = 3002
}

/**
 * 电台错误码
 */
export enum RadioErrorCode {
  /** 电台网络错误 */
  RADIO_NETWORK_ERROR = 4001,
  /** 电台超时 */
  RADIO_TIMEOUT = 4002
}

/**
 * 错误码类型联合
 */
export type MusicPlayerErrorCode =
  | PlayerErrorCode
  | PlaylistErrorCode
  | LibraryErrorCode
  | RadioErrorCode;

/**
 * 错误信息映射
 */
const ERROR_MESSAGES: Map<number, string> = new Map<number, string>([
  // 播放器错误
  [1001, '当前没有可播放的项目'],
  [1002, '播放源加载失败'],
  [1003, '网络连接失败，请检查网络'],
  [1004, '播放位置跳转失败'],
  [1005, '没有下一首歌曲'],
  [1006, '没有上一首歌曲'],

  // 播放列表错误
  [2001, '播放列表不存在'],
  [2002, '播放列表名称不能为空'],
  [2003, '播放列表名称过长'],
  [2004, '系统播放列表不可修改'],
  [2005, '播放列表已满'],
  [2006, '歌曲已存在于播放列表中'],

  // 媒体库错误
  [3001, '没有访问媒体库的权限'],
  [3002, '扫描媒体文件失败'],

  // 电台错误
  [4001, '电台网络连接失败'],
  [4002, '电台连接超时']
]);

/**
 * 获取错误信息
 * @param errorCode 错误码
 * @returns 错误信息字符串
 */
export function getErrorMessage(errorCode: MusicPlayerErrorCode): string {
  const message: string | undefined = ERROR_MESSAGES.get(errorCode as number);
  return message !== undefined ? message : '未知错误';
}

/**
 * 错误对象接口
 */
export interface MusicPlayerError {
  code: number;
  message: string;
}

/**
 * 创建错误对象
 * @param errorCode 错误码
 * @returns 包含错误码和信息的对象
 */
export function createError(errorCode: MusicPlayerErrorCode): MusicPlayerError {
  const error: MusicPlayerError = {
    code: errorCode as number,
    message: getErrorMessage(errorCode)
  };
  return error;
}
