/**
 * 公共模块统一导出
 * 导出所有常量、错误码、工具函数、主题、转场和响应式布局
 */

// 常量
export {
  Constants,
  RADIO_API_BASE,
  DEFAULT_TIMEOUT,
  MAX_PLAYLIST_ITEMS,
  DEFAULT_VOLUME,
  SUPPORTED_AUDIO_FORMATS
} from './Constants'

// 错误码
export { ErrorCodes, ErrorCode } from './ErrorCodes'

// 工具函数
export { formatTime, generateId, clamp, debounce } from './Utils'

// 主题
export { LightColors, DarkColors, CurrentTheme, isDarkMode } from './Theme'

// 转场动画
export { pageTransition, modalTransition, fadeTransition, createSlideTransition, createScaleTransition, createFadeTransition } from './Transitions'

// 响应式布局
export {
  Breakpoint,
  getCurrentBreakpoint,
  isSmallScreen,
  isTablet,
  responsive,
  GRID_GAP,
  CONTENT_PADDING,
  PLAYER_ART_SIZE_SM,
  PLAYER_ART_SIZE_LG
} from './ResponsiveLayout'
