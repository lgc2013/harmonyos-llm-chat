# HarmonyOS 模拟器运行 Skill

在模拟器上构建并运行 HarmonyOS 应用。

## 执行步骤

### 构建并运行 HAP

```bash
"D:\software\Dev-eco\DevEco Studio\tools\node\node.exe" "D:\software\Dev-eco\DevEco Studio\tools\hvigor\bin\hvigorw.js" --mode module -p module=entry@default -p product=default -p requiredDeviceType=phone assembleHap --analyze=normal --parallel --incremental --daemon
```

## 使用场景

- 功能验证测试
- UI 界面预览
- 端到端测试

## 前置条件

- 模拟器已启动并连接
- 项目已成功编译
- 设备类型为 phone

## 注意事项

- 确保模拟器已正确启动
- 如遇连接问题，检查 HDC 连接状态
- 首次安装可能需要授权
