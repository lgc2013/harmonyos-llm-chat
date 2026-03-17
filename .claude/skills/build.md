# HarmonyOS 项目编译 Skill

编译 HarmonyOS 项目，包括依赖安装和构建。

## 执行步骤

### 1. 安装依赖

```bash
"D:\software\Dev-eco\DevEco Studio\tools\ohpm\bin\ohpm.bat" install --all --registry https://ohpm.openharmony.cn/ohpm/ --strict_ssl true
```

### 2. 执行编译

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
- 如遇依赖问题，可尝试清理后重新编译
