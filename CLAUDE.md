# HarmonyOS 项目规则

## 设计规范（必须遵循）

### 设计最佳实践
参考华为官方设计指南：
- [设计最佳实践](https://developer.huawei.com/consumer/cn/doc/design-guides/practices-overview-0000001746498066)

### UX体验标准
遵守华为应用UX体验标准：
- [UX体验标准](https://developer.huawei.com/consumer/cn/doc/design-guides/ux-guidelines-general-0000001760708152)

## 编译和运行

必须使用以下skill进行编译和验证：

| Skill | 用途 | 文件 |
|-------|------|------|
| `/build` | 编译项目 | `.claude/skills/build.md` |
| `/run-emulator` | 模拟器运行 | `.claude/skills/run-emulator.md` |

## 设计文档要求

所有设计文档（plan.md、quickstart.md、tasks.md）必须：
1. 引用已有skill
2. 使用完整命令路径
3. 遵循华为设计最佳实践
4. 符合UX体验标准

## TDD 开发模式

严格遵循红-绿-重构循环：
1. 🔴 红：先编写失败的测试用例
2. 🟢 绿：编写最少代码使测试通过
3. 🔄 重构：优化代码结构

## 代码规范

- 遵循 ArkTS 语法规范
- 使用显式类型声明（禁止 any/unknown）
- API Key 必须通过用户设置界面配置，禁止硬编码
