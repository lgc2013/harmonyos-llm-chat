# HarmonyOS 应用测试 Skill

## 快速测试流程

### 1. 编译安装
```bash
# 编译
cd D:/01-design-agent/harmonyos/MyApplication
"/d/software/Dev-eco/DevEco Studio/tools/hvigor/bin/hvigorw.bat" --mode module -p module=entry@default -p product=default assembleHap --no-daemon

# 安装
powershell.exe -Command "& 'D:\software\Dev-eco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' install -r 'D:\01-design-agent\harmonyos\MyApplication\entry\build\default\outputs\default\entry-default-unsigned.hap'"

# 启动
powershell.exe -Command "& 'D:\software\Dev-eco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' shell aa start -a EntryAbility -b com.example.myapplication"
```

### 2. 查看日志
```bash
powershell.exe -Command "& 'D:\software\Dev-eco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' shell hilog -x" | grep "关键词"
```

### 3. 截图验证
```bash
# 截图
powershell.exe -Command "& 'D:\software\Dev-eco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' shell 'snapshot_display -f /data/local/tmp/test.jpeg'"

# 传输
powershell.exe -Command "& 'D:\software\Dev-eco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' file recv /data/local/tmp/test.jpeg D:\01-design-agent\harmonyos\MyApplication\test.jpeg"
```

### 4. 清除数据重新测试
```bash
# 卸载
powershell.exe -Command "& 'D:\software\Dev-eco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' uninstall com.example.myapplication"

# 重新安装
powershell.exe -Command "& 'D:\software\Dev-eco\DevEco Studio\sdk\default\openharmony\toolchains\hdc.exe' install 'D:\01-design-agent\harmonyos\MyApplication\entry\build\default\outputs\default\entry-default-unsigned.hap'"
```

## 常用命令别名

建议在 CLAUDE.md 中添加：
```markdown
## 测试命令

| 操作 | 命令 |
|------|------|
| 编译 | `hvigorw.bat --mode module -p module=entry@default -p product=default assembleHap --no-daemon` |
| 安装 | `hdc.exe install -r <hap路径>` |
| 启动 | `hdc.exe shell aa start -a EntryAbility -b com.example.myapplication` |
| 日志 | `hdc.exe shell hilog -x \| grep "LLMChat"` |
| 截图 | `hdc.exe shell 'snapshot_display -f /data/local/tmp/test.jpeg'` |
| 传文件 | `hdc.exe file recv /data/local/tmp/test.jpeg <本地路径>` |
```
