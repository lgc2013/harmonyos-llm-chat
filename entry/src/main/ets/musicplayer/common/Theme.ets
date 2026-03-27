/**
 * 主题工具类
 * 定义亮色和暗色主题的颜色常量，提供主题切换和状态管理功能
 */

/**
 * 亮色主题颜色配置
 * 适用于日间模式或明亮环境
 */
export const LightColors = {
  /** 主色调 - 用于主要按钮、强调元素 */
  primary: '#007DFF',
  /** 次要色调 - 用于次要操作、成功状态 */
  secondary: '#4CAF50',
  /** 背景色 - 页面主背景 */
  background: '#FFFFFF',
  /** 表面色 - 卡片、对话框等表面 */
  surface: '#F5F5F5',
  /** 主要文字颜色 - 标题、重要内容 */
  textPrimary: '#000000',
  /** 次要文字颜色 - 描述、辅助信息 */
  textSecondary: '#666666',
  /** 分割线颜色 */
  divider: '#E0E0E0',
  /** 错误颜色 - 错误提示、警告 */
  error: '#FF0000',
  /** 禁用状态颜色 */
  disabled: '#BDBDBD',
  /** 成功状态颜色 */
  success: '#4CAF50',
  /** 警告状态颜色 */
  warning: '#FF9800',
  /** 信息状态颜色 */
  info: '#2196F3',
  /** 播放进度条已播放部分颜色 */
  progressActive: '#007DFF',
  /** 播放进度条未播放部分颜色 */
  progressInactive: '#E0E0E0',
  /** 播放进度条缓冲部分颜色 */
  progressBuffered: '#BDBDBD',
  /** 专辑封面占位符背景色 */
  albumPlaceholder: '#E0E0E0',
  /** 播放控制按钮颜色 */
  controlButton: '#333333',
  /** 播放控制按钮激活状态颜色 */
  controlButtonActive: '#007DFF',
  /** 卡片阴影颜色 */
  cardShadow: 'rgba(0, 0, 0, 0.1)',
  /** 列表项悬停背景色 */
  listItemHover: '#F0F0F0',
  /** 列表项选中背景色 */
  listItemSelected: '#E3F2FD',
  /** 输入框边框颜色 */
  inputBorder: '#CCCCCC',
  /** 输入框聚焦边框颜色 */
  inputBorderFocused: '#007DFF',
  /** 标签背景色 */
  tagBackground: '#E0E0E0',
  /** 标签文字颜色 */
  tagText: '#333333'
} as const;

/**
 * 暗色主题颜色配置
 * 适用于夜间模式或暗色环境
 */
export const DarkColors = {
  /** 主色调 - 用于主要按钮、强调元素 */
  primary: '#3B82F6',
  /** 次要色调 - 用于次要操作、成功状态 */
  secondary: '#22C55E',
  /** 背景色 - 页面主背景 */
  background: '#121212',
  /** 表面色 - 卡片、对话框等表面 */
  surface: '#1E1E1E',
  /** 主要文字颜色 - 标题、重要内容 */
  textPrimary: '#FFFFFF',
  /** 次要文字颜色 - 描述、辅助信息 */
  textSecondary: '#AAAAAA',
  /** 分割线颜色 */
  divider: '#333333',
  /** 错误颜色 - 错误提示、警告 */
  error: '#EF4444',
  /** 禁用状态颜色 */
  disabled: '#555555',
  /** 成功状态颜色 */
  success: '#22C55E',
  /** 警告状态颜色 */
  warning: '#F59E0B',
  /** 信息状态颜色 */
  info: '#3B82F6',
  /** 播放进度条已播放部分颜色 */
  progressActive: '#3B82F6',
  /** 播放进度条未播放部分颜色 */
  progressInactive: '#333333',
  /** 播放进度条缓冲部分颜色 */
  progressBuffered: '#444444',
  /** 专辑封面占位符背景色 */
  albumPlaceholder: '#333333',
  /** 播放控制按钮颜色 */
  controlButton: '#FFFFFF',
  /** 播放控制按钮激活状态颜色 */
  controlButtonActive: '#3B82F6',
  /** 卡片阴影颜色 */
  cardShadow: 'rgba(0, 0, 0, 0.3)',
  /** 列表项悬停背景色 */
  listItemHover: '#2A2A2A',
  /** 列表项选中背景色 */
  listItemSelected: '#1E3A5F',
  /** 输入框边框颜色 */
  inputBorder: '#444444',
  /** 输入框聚焦边框颜色 */
  inputBorderFocused: '#3B82F6',
  /** 标签背景色 */
  tagBackground: '#333333',
  /** 标签文字颜色 */
  tagText: '#FFFFFF'
} as const;

/**
 * 颜色配置接口
 * 定义主题颜色必须包含的所有属性
 */
export interface ColorConfig {
  /** 主色调 */
  primary: string;
  /** 次要色调 */
  secondary: string;
  /** 背景色 */
  background: string;
  /** 表面色 */
  surface: string;
  /** 主要文字颜色 */
  textPrimary: string;
  /** 次要文字颜色 */
  textSecondary: string;
  /** 分割线颜色 */
  divider: string;
  /** 错误颜色 */
  error: string;
  /** 禁用状态颜色 */
  disabled: string;
  /** 成功状态颜色 */
  success: string;
  /** 警告状态颜色 */
  warning: string;
  /** 信息状态颜色 */
  info: string;
  /** 播放进度条已播放部分颜色 */
  progressActive: string;
  /** 播放进度条未播放部分颜色 */
  progressInactive: string;
  /** 播放进度条缓冲部分颜色 */
  progressBuffered: string;
  /** 专辑封面占位符背景色 */
  albumPlaceholder: string;
  /** 播放控制按钮颜色 */
  controlButton: string;
  /** 播放控制按钮激活状态颜色 */
  controlButtonActive: string;
  /** 卡片阴影颜色 */
  cardShadow: string;
  /** 列表项悬停背景色 */
  listItemHover: string;
  /** 列表项选中背景色 */
  listItemSelected: string;
  /** 输入框边框颜色 */
  inputBorder: string;
  /** 输入框聚焦边框颜色 */
  inputBorderFocused: string;
  /** 标签背景色 */
  tagBackground: string;
  /** 标签文字颜色 */
  tagText: string;
}

/**
 * 主题类型枚举
 * 定义可用的主题类型
 */
export enum ThemeType {
  /** 亮色主题 */
  LIGHT = 'light',
  /** 暗色主题 */
  DARK = 'dark'
}

/**
 * 当前主题状态
 * 用于响应式主题切换
 */
class ThemeState {
  /** 当前主题类型 */
  private currentThemeType: ThemeType = ThemeType.LIGHT;

  /** 主题变更监听器列表 */
  private listeners: Array<(theme: ColorConfig) => void> = [];

  /**
   * 获取当前主题类型
   * @returns 当前主题类型枚举值
   */
  getThemeType(): ThemeType {
    return this.currentThemeType;
  }

  /**
   * 获取当前主题颜色配置
   * @returns 当前主题的颜色配置对象
   */
  getColors(): ColorConfig {
    return this.currentThemeType === ThemeType.DARK ? DarkColors : LightColors;
  }

  /**
   * 设置主题类型
   * @param type 目标主题类型
   */
  setThemeType(type: ThemeType): void {
    if (this.currentThemeType !== type) {
      this.currentThemeType = type;
      this.notifyListeners();
    }
  }

  /**
   * 切换主题（亮色/暗色之间切换）
   */
  toggleTheme(): void {
    this.currentThemeType = this.currentThemeType === ThemeType.LIGHT
      ? ThemeType.DARK
      : ThemeType.LIGHT;
    this.notifyListeners();
  }

  /**
   * 检查当前是否为暗色主题
   * @returns 是否为暗色主题
   */
  isDarkMode(): boolean {
    return this.currentThemeType === ThemeType.DARK;
  }

  /**
   * 添加主题变更监听器
   * @param listener 监听器回调函数
   */
  addListener(listener: (theme: ColorConfig) => void): void {
    this.listeners.push(listener);
  }

  /**
   * 移除主题变更监听器
   * @param listener 要移除的监听器回调函数
   */
  removeListener(listener: (theme: ColorConfig) => void): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }

  /**
   * 通知所有监听器主题已变更
   */
  private notifyListeners(): void {
    const colors = this.getColors();
    this.listeners.forEach((listener) => {
      listener(colors);
    });
  }
}

/**
 * 全局主题状态实例
 * 用于在整个应用中访问和修改主题状态
 */
export const CurrentTheme: ThemeState = new ThemeState();

/**
 * 检查当前是否为暗色主题
 * 便捷函数，直接返回当前主题状态
 * @returns 是否为暗色主题
 */
export function isDarkMode(): boolean {
  return CurrentTheme.isDarkMode();
}

/**
 * 获取当前主题颜色配置
 * 便捷函数，直接返回当前颜色配置
 * @returns 当前主题的颜色配置对象
 */
export function getThemeColors(): ColorConfig {
  return CurrentTheme.getColors();
}

/**
 * 切换主题
 * 便捷函数，在亮色和暗色主题之间切换
 */
export function toggleTheme(): void {
  CurrentTheme.toggleTheme();
}

/**
 * 设置主题类型
 * 便捷函数，设置指定的主题类型
 * @param type 目标主题类型
 */
export function setTheme(type: ThemeType): void {
  CurrentTheme.setThemeType(type);
}
