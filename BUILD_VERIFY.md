# 构建验证指南

## 概述

本文档提供音乐播放器功能的构建和测试验证指南。

## 前置条件

1. 安装 DevEco Studio 4.0 或更高版本
2. 安装 HarmonyOS SDK API 10 或更高版本
3. 配置 Node.js 环境（DevEco Studio 自带）

## 构建步骤

### 1. 打开项目

在 DevEco Studio 中打开 `D:\01-design-agent\harmonyos\MyApplication` 项目。

### 2. 同步项目

点击 `File` > `Sync Project with Build Files` 或使用快捷键同步项目。

### 3. 编译项目

```bash
# 方式一：使用 DevEco Studio 菜单
# Build > Build Hap(s)/APP(s) > Build Hap(s)

# 方式二：使用命令行（在 DevEco Studio 终端中）
hvigorw assembleHap
```

### 4. 运行测试

```bash
# 运行所有测试
hvigorw test

# 或在 DevEco Studio 中右键点击 ohosTest 目录 > Run 'Tests'
```

## 文件统计

### 源文件 (50 个)

| 分类 | 文件数 | 说明 |
|------|--------|------|
| Models | 8 | 数据模型和枚举 |
| Services | 5 | 业务逻辑服务 |
| ViewModels | 5 | 状态管理 |
| Components | 17 | UI 组件 |
| Pages | 8 | 页面 |
| Common | 7 | 常量、工具、主题 |

### 测试文件 (15 个)

| 分类 | 文件数 |
|------|--------|
| Models | 6 |
| Services | 4 |
| ViewModels | 4 |
| Common | 1 |

## 功能验证清单

### US1 - 本地音乐库展示

- [ ] 打开应用，切换到"本地音乐"标签
- [ ] 等待音乐扫描完成
- [ ] 验证音乐列表显示（标题、艺术家、时长）
- [ ] 测试按标题/艺术家/专辑排序
- [ ] 测试搜索功能
- [ ] 验证空状态显示

### US2 - 播放控制

- [ ] 点击音乐开始播放
- [ ] 测试播放/暂停按钮
- [ ] 测试上一首/下一首
- [ ] 测试进度条拖动
- [ ] 测试音量调节
- [ ] 测试播放模式切换（顺序/循环/单曲/随机）

### US3 - 后台播放

- [ ] 播放音乐后切换到其他应用
- [ ] 验证音乐继续播放
- [ ] 锁屏后验证音乐继续播放
- [ ] 验证锁屏界面显示播放控制
- [ ] 来电后验证暂停和恢复

### US4 - 网络电台

- [ ] 切换到"网络电台"标签
- [ ] 验证热门电台列表加载
- [ ] 测试按国家筛选
- [ ] 测试按类型筛选
- [ ] 测试搜索电台
- [ ] 点击电台播放

### US5 - 播放列表管理

- [ ] 切换到"播放列表"标签
- [ ] 创建新播放列表
- [ ] 添加歌曲到播放列表
- [ ] 播放播放列表中的歌曲
- [ ] 从播放列表移除歌曲
- [ ] 删除播放列表

## 已知问题

1. **Node.js 环境**：需要在 DevEco Studio 内置终端运行 hvigor 命令
2. **权限申请**：首次运行需要授予媒体访问权限
3. **网络连接**：网络电台功能需要网络连接

## 故障排除

### 构建失败

1. 清理项目：`Build > Clean Project`
2. 重新同步：`File > Sync Project with Build Files`
3. 删除 `.hvigor` 和 `build` 目录后重新构建

### 运行时错误

1. 检查日志：`Log` 面板查看错误信息
2. 检查权限：确保 `module.json5` 中配置了必要权限
3. 检查导入：确保所有模块正确导出

## 联系支持

如有问题，请查看：
- [HarmonyOS 开发文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides-V5/application-dev-guide-V5)
- [DevEco Studio 使用指南](https://developer.huawei.com/consumer/cn/doc/deveco-studio-guides-V5/deveco-studio-overview-V5)
