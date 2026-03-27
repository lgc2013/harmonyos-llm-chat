/**
 * ResponsiveLayout.ets
 * 响应式布局工具类
 *
 * 根据华为UX体验标准，支持不同屏幕尺寸良好显示
 * 参考：https://developer.huawei.com/consumer/cn/doc/design-guides/ux-guidelines-general-0000001760708152
 */

/**
 * 断点枚举
 * - SM: < 600vp (手机竖屏)
 * - MD: 600-840vp (手机横屏、平板)
 * - LG: > 840vp (大屏平板)
 */
export enum Breakpoint {
  SM = 'sm',
  MD = 'md',
  LG = 'lg'
}

/**
 * 响应式值接口
 * 用于根据不同断点返回不同的值
 */
export interface ResponsiveValue<T> {
  sm?: T
  md?: T
  lg?: T
}

/**
 * 网格布局常量
 */
export const GRID_GAP = 16 // vp - 网格间距

/**
 * 内容内边距
 */
export const CONTENT_PADDING = 16 // vp - 内容边距

/**
 * 播放器封面尺寸
 */
export const PLAYER_ART_SIZE_SM = 180 // 小屏幕封面尺寸
export const PLAYER_ART_SIZE_LG = 280 // 大屏幕封面尺寸

/**
 * 断点阈值常量
 */
const BREAKPOINT_SM_MAX = 600 // SM断点最大值
const BREAKPOINT_MD_MAX = 840 // MD断点最大值

/**
 * 根据屏幕宽度获取当前断点
 *
 * @param width 屏幕宽度（vp）
 * @returns 当前断点
 */
export function getCurrentBreakpoint(width: number): Breakpoint {
  if (width < BREAKPOINT_SM_MAX) {
    return Breakpoint.SM
  } else if (width < BREAKPOINT_MD_MAX) {
    return Breakpoint.MD
  } else {
    return Breakpoint.LG
  }
}

/**
 * 判断是否为小屏幕（手机竖屏）
 *
 * @param width 屏幕宽度（vp）
 * @returns 是否为小屏幕
 */
export function isSmallScreen(width: number): boolean {
  return width < BREAKPOINT_SM_MAX
}

/**
 * 判断是否为平板设备
 * 包括MD和LG断点（手机横屏、平板、大屏平板）
 *
 * @param width 屏幕宽度（vp）
 * @returns 是否为平板设备
 */
export function isTablet(width: number): boolean {
  return width >= BREAKPOINT_SM_MAX
}

/**
 * 获取网格列数
 * 根据断点返回适合的网格列数
 *
 * @param breakpoint 当前断点
 * @returns 网格列数
 */
export function getGridColumns(breakpoint: Breakpoint): number {
  switch (breakpoint) {
    case Breakpoint.SM:
      return 4 // 手机竖屏：4列
    case Breakpoint.MD:
      return 8 // 手机横屏/小平板：8列
    case Breakpoint.LG:
      return 12 // 大屏平板：12列
    default:
      return 4
  }
}

/**
 * 获取响应式值
 * 根据断点从ResponsiveValue中选择合适的值
 * 如果指定断点没有值，会按照lg -> md -> sm的顺序回退
 *
 * @param value 响应式值对象
 * @param breakpoint 当前断点
 * @returns 对应的值
 */
export function responsive<T>(value: ResponsiveValue<T>, breakpoint: Breakpoint): T {
  // 首先尝试获取当前断点的值
  const breakpointValue = value[breakpoint]
  if (breakpointValue !== undefined) {
    return breakpointValue
  }

  // 回退策略：lg -> md -> sm
  const fallbackOrder: Breakpoint[] = [Breakpoint.LG, Breakpoint.MD, Breakpoint.SM]

  for (const bp of fallbackOrder) {
    const fallbackValue = value[bp]
    if (fallbackValue !== undefined) {
      return fallbackValue
    }
  }

  // 如果所有断点都没有值，返回undefined（类型断言为T）
  return undefined as T
}

/**
 * 获取播放器封面尺寸
 * 根据断点返回合适的封面尺寸
 *
 * @param breakpoint 当前断点
 * @returns 封面尺寸（vp）
 */
export function getPlayerArtSize(breakpoint: Breakpoint): number {
  return responsive<number>(
    {
      sm: PLAYER_ART_SIZE_SM,
      md: (PLAYER_ART_SIZE_SM + PLAYER_ART_SIZE_LG) / 2, // 中等尺寸
      lg: PLAYER_ART_SIZE_LG
    },
    breakpoint
  )
}

/**
 * 获取内容最大宽度
 * 限制内容在大屏上的最大宽度，提升阅读体验
 *
 * @param breakpoint 当前断点
 * @returns 内容最大宽度（vp），0表示不限制
 */
export function getContentMaxWidth(breakpoint: Breakpoint): number {
  return responsive<number>(
    {
      sm: 0, // 小屏不限制
      md: 720, // 中屏最大720vp
      lg: 960 // 大屏最大960vp
    },
    breakpoint
  )
}

/**
 * 获取列表项高度
 * 根据断点返回合适的列表项高度
 *
 * @param breakpoint 当前断点
 * @returns 列表项高度（vp）
 */
export function getListItemHeight(breakpoint: Breakpoint): number {
  return responsive<number>(
    {
      sm: 64,
      md: 72,
      lg: 80
    },
    breakpoint
  )
}

/**
 * 获取标题字体大小
 * 根据断点返回合适的标题字体大小
 *
 * @param breakpoint 当前断点
 * @returns 字体大小（fp）
 */
export function getTitleFontSize(breakpoint: Breakpoint): number {
  return responsive<number>(
    {
      sm: 20,
      md: 24,
      lg: 28
    },
    breakpoint
  )
}

/**
 * 获取正文字体大小
 * 根据断点返回合适的正文字体大小
 *
 * @param breakpoint 当前断点
 * @returns 字体大小（fp）
 */
export function getBodyFontSize(breakpoint: Breakpoint): number {
  return responsive<number>(
    {
      sm: 14,
      md: 16,
      lg: 18
    },
    breakpoint
  )
}

/**
 * 获取控制按钮尺寸
 * 根据断点返回合适的控制按钮尺寸
 *
 * @param breakpoint 当前断点
 * @returns 按钮尺寸（vp）
 */
export function getControlButtonSize(breakpoint: Breakpoint): number {
  return responsive<number>(
    {
      sm: 44,
      md: 48,
      lg: 56
    },
    breakpoint
  )
}

/**
 * 获取播放/暂停按钮尺寸
 * 播放按钮通常比其他控制按钮更大
 *
 * @param breakpoint 当前断点
 * @returns 按钮尺寸（vp）
 */
export function getPlayButtonSize(breakpoint: Breakpoint): number {
  return responsive<number>(
    {
      sm: 56,
      md: 64,
      lg: 72
    },
    breakpoint
  )
}
