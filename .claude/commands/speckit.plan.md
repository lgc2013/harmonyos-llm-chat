---
description: 使用计划模板执行实施规划工作流以生成设计工件
handoffs: 
  - label: 创建任务
    agent: speckit.tasks
    prompt: 将计划分解为任务
    send: true
  - label: 创建检查清单
    agent: speckit.checklist
    prompt: 为以下领域创建检查清单...
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前，**必须**考虑用户输入（如果不为空）。

## 大纲

1. **设置**：从仓库根目录运行 `.specify/scripts/powershell/setup-plan.ps1 -Json` 并解析 JSON 获取 FEATURE_SPEC、IMPL_PLAN、SPECS_DIR、BRANCH。对于参数中的单引号，如 "I'm Groot"，请使用转义语法：例如 'I'\''m Groot'（如果可以的话也可以用双引号："I'm Groot"）。

2. **加载上下文**：读取 FEATURE_SPEC 和 `.specify/memory/constitution.md`。加载 IMPL_PLAN 模板（已复制）。

3. **执行计划工作流**：遵循 IMPL_PLAN 模板中的结构：
   - 填写技术上下文（将未知标记为"需要澄清"）
   - 从宪法填写宪法检查部分
   - 评估门控（如果违规无正当理由则报错）
   - 阶段 0：生成 research.md（解决所有需要澄清）
   - 阶段 1：生成 data-model.md、contracts/、quickstart.md
   - 阶段 1：通过运行代理脚本更新代理上下文
   - 设计后重新评估宪法检查

4. **停止并报告**：命令在阶段 2 规划后结束。报告分支、IMPL_PLAN 路径和生成的工件。

## 阶段

### 阶段 0：大纲与研究

1. **从上面的技术上下文中提取未知**：
   - 每个需要澄清 → 研究任务
   - 每个依赖项 → 最佳实践任务
   - 每个集成 → 模式任务

2. **生成并分派研究代理**：

   ```text
   对于技术上下文中的每个未知：
     任务："研究 {未知} 在 {功能上下文}"
   对于每个技术选择：
     任务："在 {领域} 中找到 {技术} 的最佳实践"
   ```

3. **在 `research.md` 中整合发现**，使用格式：
   - 决策：[选择了什么]
   - 理由：[为什么选择]
   - 考虑的替代方案：[还评估了什么]

**输出**：research.md，其中所有需要澄清已解决

### 阶段 1：设计与契约

**前置条件：** `research.md` 完成

1. **从功能规范中提取实体** → `data-model.md`：
   - 实体名称、字段、关系
   - 来自需求的验证规则
   - 状态转换（如果适用）

2. **定义接口契约**（如果项目有外部接口）→ `/contracts/`：
   - 识别项目向用户或其他系统公开的接口
   - 记录适合项目类型的契约格式
   - 示例：库的公共 API、CLI 工具的命令模式、Web 服务的端点、解析器的语法、应用的 UI 契约
   - 如果项目是纯内部的则跳过（构建脚本、一次性工具等）

3. **代理上下文更新**：
   - 运行 `.specify/scripts/powershell/update-agent-context.ps1 -AgentType cursor-agent`
   - 这些脚本检测正在使用的 AI 代理
   - 更新适当的代理特定上下文文件
   - 仅添加当前计划中的新技术
   - 在标记之间保留手动添加的内容

**输出**：data-model.md、/contracts/*、quickstart.md、代理特定文件

## 关键规则

- 使用绝对路径
- 门控失败或未解决的澄清时报错
