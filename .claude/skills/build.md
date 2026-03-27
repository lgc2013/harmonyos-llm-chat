# HarmonyOS 项目编译 Skill

编译 HarmonyOS 项目，生成 HAP 包。

## 执行步骤

### 执行编译

```bash
"D:\software\Dev-eco\DevEco Studio\tools\node\node.exe" "D:\software\Dev-eco\DevEco Studio\tools\hvigor\bin\hvigorw.js" --sync -p product=default --analyze=normal --parallel --incremental --daemon
```

## 使用场景

- 开发过程中验证代码编译
- 提交代码前确保编译通过
- CI/CD 流水线中

## 注意事项

- 确保DevEco Studio路径正确
- 首次编译可能需要较长时间
- `@ohos/hvigor` 等依赖由 DevEco Studio 自带，无需通过 ohpm 安装
- 如遇依赖问题，可尝试清理 `.hvigor/cache` 目录后重新编译
