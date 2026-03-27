/**
 * 过渡动画定义
 * 包含页面转场、模态框转场、淡入淡出等动画配置
 * 遵循华为UX体验标准：转场时长 >= 200ms，使用弹性曲线
 */

/**
 * 页面转场动画配置
 * 从右侧滑入，向左滑出
 * 遵循UX标准：时长 >= 200ms
 */
export const pageTransition: PageTransitionOptions = {
  duration: 300,
  curve: Curve.FastOutSlowIn,
  slide: SlideEffect.Right
};

/**
 * 页面转场配置接口
 */
export interface PageTransitionOptions {
  duration: number;
  curve: Curve;
  slide: SlideEffect;
}

/**
 * 滑动方向枚举
 */
export enum SlideEffect {
  Left = 'Left',
  Right = 'Right',
  Up = 'Up',
  Down = 'Down'
}

/**
 * 模态框转场动画配置
 * 从底部向上滑入
 */
export const modalTransition: ModalTransitionOptions = {
  duration: 250,
  curve: Curve.EaseOut,
  slide: SlideEffect.Up
};

/**
 * 模态框转场配置接口
 */
export interface ModalTransitionOptions {
  duration: number;
  curve: Curve;
  slide: SlideEffect;
}

/**
 * 淡入淡出转场动画配置
 */
export const fadeTransition: FadeTransitionOptions = {
  duration: 200,
  curve: Curve.Linear
};

/**
 * 淡入淡出转场配置接口
 */
export interface FadeTransitionOptions {
  duration: number;
  curve: Curve;
}

/**
 * 弹簧动画曲线参数
 * 用于需要更自然回弹效果的动画
 */
export const springCurveParams = {
  response: 0.5,
  dampingFraction: 0.8,
  overlapDuration: 0.0
};

/**
 * 动画方向类型
 */
export type SlideDirection = 'left' | 'right' | 'up' | 'down';

/**
 * 创建滑动转场动画效果
 * @param direction 滑动方向
 * @returns 滑动转场配置对象
 */
export function createSlideTransition(direction: SlideDirection): SlideTransitionResult {
  const config: SlideTransitionResult = {
    duration: 300,
    curve: Curve.FastOutSlowIn,
    translate: { x: 0, y: 0 }
  };

  switch (direction) {
    case 'left':
      config.translate = { x: -100, y: 0 };
      break;
    case 'right':
      config.translate = { x: 100, y: 0 };
      break;
    case 'up':
      config.translate = { x: 0, y: -100 };
      break;
    case 'down':
      config.translate = { x: 0, y: 100 };
      break;
  }

  return config;
}

/**
 * 滑动转场结果接口
 */
export interface SlideTransitionResult {
  duration: number;
  curve: Curve;
  translate: TranslateConfig;
}

/**
 * 平移配置接口
 */
export interface TranslateConfig {
  x: number;
  y: number;
}

/**
 * 创建缩放转场动画效果
 * @param scale 缩放比例 (0.0 - 1.0)
 * @returns 缩放转场配置对象
 */
export function createScaleTransition(scale: number): ScaleTransitionResult {
  return {
    duration: 250,
    curve: Curve.Spring,
    scale: {
      x: scale,
      y: scale
    }
  };
}

/**
 * 缩放转场结果接口
 */
export interface ScaleTransitionResult {
  duration: number;
  curve: Curve;
  scale: ScaleConfig;
}

/**
 * 缩放配置接口
 */
export interface ScaleConfig {
  x: number;
  y: number;
}

/**
 * 创建淡入淡出转场动画效果
 * @param opacity 透明度 (0.0 - 1.0)
 * @returns 淡入淡出转场配置对象
 */
export function createFadeTransition(opacity: number): FadeTransitionResult {
  return {
    duration: 200,
    curve: Curve.Linear,
    opacity: opacity
  };
}

/**
 * 淡入淡出转场结果接口
 */
export interface FadeTransitionResult {
  duration: number;
  curve: Curve;
  opacity: number;
}

/**
 * 组合转场动画配置
 * 同时包含滑动和淡入淡出效果
 */
export const combinedTransition: CombinedTransitionOptions = {
  duration: 300,
  curve: Curve.FastOutSlowIn,
  slide: SlideEffect.Right,
  opacity: 0.0
};

/**
 * 组合转场配置接口
 */
export interface CombinedTransitionOptions {
  duration: number;
  curve: Curve;
  slide: SlideEffect;
  opacity: number;
}

/**
 * 列表项动画配置
 * 用于列表项进入/退出动画
 */
export const listItemTransition: ListItemTransitionOptions = {
  duration: 200,
  curve: Curve.EaseOut,
  delay: 0
};

/**
 * 列表项转场配置接口
 */
export interface ListItemTransitionOptions {
  duration: number;
  curve: Curve;
  delay: number;
}

/**
 * 创建交错延迟动画配置
 * 用于列表项依次出现的效果
 * @param index 列表项索引
 * @param baseDelay 基础延迟（毫秒）
 * @returns 带延迟的动画配置
 */
export function createStaggeredTransition(index: number, baseDelay: number = 50): ListItemTransitionOptions {
  return {
    duration: 200,
    curve: Curve.EaseOut,
    delay: index * baseDelay
  };
}

/**
 * 按钮点击反馈动画配置
 */
export const buttonPressTransition: ScaleTransitionResult = {
  duration: 100,
  curve: Curve.EaseOut,
  scale: {
    x: 0.95,
    y: 0.95
  }
};

/**
 * 卡片展开动画配置
 */
export const cardExpandTransition: CardExpandTransitionOptions = {
  duration: 300,
  curve: Curve.Spring,
  scale: {
    x: 1.0,
    y: 1.0
  },
  opacity: 1.0
};

/**
 * 卡片展开转场配置接口
 */
export interface CardExpandTransitionOptions {
  duration: number;
  curve: Curve;
  scale: ScaleConfig;
  opacity: number;
}
