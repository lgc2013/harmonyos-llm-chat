---
description: 根据自然语言功能描述创建或更新功能规范
handoffs: 
  - label: 构建技术计划
    agent: speckit.plan
    prompt: 为规范创建计划。我正在用...构建
  - label: 澄清规范需求
    agent: speckit.clarify
    prompt: 澄清规范需求
    send: true
---

## 用户输入

```text
$ARGUMENTS
```

在继续之前，**必须**考虑用户输入（如果不为空）。

## 大纲

触发消息中用户在 `/speckit.specify` 后面输入的文本**就是**功能描述。假设您在此对话中始终可以使用它，即使下面 `$ARGUMENTS` 字面显示。除非用户提供了空命令，否则不要要求用户重复。

给定该功能描述，执行以下操作：

1. **生成一个简洁的短名称**（2-4 个词）用于分支：
   - 分析功能描述并提取最有意义的关键词
   - 创建一个 2-4 个词的短名称，捕捉功能的本质
   - 尽可能使用动作-名词格式（例如，"add-user-auth"、"fix-payment-bug"）
   - 保留技术术语和缩写（OAuth2、API、JWT 等）
   - 保持简洁但足以让人一眼理解功能
   - 示例：
     - "I want to add user authentication" → "user-auth"
     - "Implement OAuth2 integration for the API" → "oauth2-api-integration"
     - "Create a dashboard for analytics" → "analytics-dashboard"
     - "Fix payment processing timeout bug" → "fix-payment-timeout"

2. **创建新分支前检查现有分支**：

   a. 首先，获取所有远程分支以确保我们有最新信息：

      ```bash
      git fetch --all --prune
      ```

   b. 在所有来源中找到该短名称的最高功能编号：
      - 远程分支：`git ls-remote --heads origin | grep -E 'refs/heads/[0-9]+-<short-name>$'`
      - 本地分支：`git branch | grep -E '^[* ]*[0-9]+-<short-name>$'`
      - Specs 目录：检查匹配 `specs/[0-9]+-<short-name>` 的目录

   c. 确定下一个可用编号：
      - 从所有三个来源提取所有编号
      - 找到最高编号 N
      - 新分支编号使用 N+1

   d. 使用计算出的编号和短名称运行脚本 `.specify/scripts/powershell/create-new-feature.ps1 -Json "$ARGUMENTS"`：
      - 传递 `--number N+1` 和 `--short-name "your-short-name"` 以及功能描述
      - Bash 示例：`.specify/scripts/powershell/create-new-feature.ps1 -Json "$ARGUMENTS" --json --number 5 --short-name "user-auth" "Add user authentication"`
      - PowerShell 示例：`.specify/scripts/powershell/create-new-feature.ps1 -Json "$ARGUMENTS" -Json -Number 5 -ShortName "user-auth" "Add user authentication"`

   **重要**：
   - 检查所有三个来源（远程分支、本地分支、specs 目录）以找到最高编号
   - 只匹配具有确切短名称模式的分支/目录
   - 如果没有找到具有此短名称的现有分支/目录，从编号 1 开始
   - 每个功能必须只运行此脚本一次
   - JSON 作为输出在终端中提供 - 始终参考它以获取您要查找的实际内容
   - JSON 输出将包含 BRANCH_NAME 和 SPEC_FILE 路径
   - 对于参数中的单引号，如 "I'm Groot"，请使用转义语法：例如 'I'\''m Groot'（如果可以的话也可以用双引号："I'm Groot"）

3. 加载 `.specify/templates/spec-template.md` 以了解所需部分。

4. 遵循此执行流程：

    1. 从输入中解析用户描述
       如果为空：错误 "未提供功能描述"
    2. 从描述中提取关键概念
       识别：参与者、动作、数据、约束
    3. 对于不清楚的方面：
       - 根据上下文和行业标准做出明智的猜测
       - 仅在以下情况下标记 [NEEDS CLARIFICATION: 具体问题]：
         - 选择显著影响功能范围或用户体验
         - 存在具有不同影响的多种合理解释
         - 不存在合理的默认值
       - **限制：最多 3 个 [NEEDS CLARIFICATION] 标记**
       - 按影响程度优先处理澄清：范围 > 安全/隐私 > 用户体验 > 技术细节
    4. 填写用户场景和测试部分
       如果没有清晰的用户流程：错误 "无法确定用户场景"
    5. 生成功能需求
       每个需求必须是可测试的
       对未指定的细节使用合理的默认值（在假设部分记录假设）
    6. 定义成功标准
       创建可衡量的、技术无关的结果
       包括定量指标（时间、性能、数量）和定性衡量（用户满意度、任务完成度）
       每个标准必须在没有实施细节的情况下可验证
    7. 识别关键实体（如果涉及数据）
    8. 返回：成功（规范准备好进行规划）

5. 使用模板结构将规范写入 SPEC_FILE，用从功能描述（参数）派生的具体细节替换占位符，同时保留部分顺序和标题。

6. **规范质量验证**：编写初始规范后，根据质量标准进行验证：

   a. **创建规范质量检查清单**：在 `FEATURE_DIR/checklists/requirements.md` 使用检查清单模板结构生成检查清单文件，包含以下验证项：

      ```markdown
      # Specification Quality Checklist: [FEATURE NAME]
      
      **Purpose**: Validate specification completeness and quality before proceeding to planning
      **Created**: [DATE]
      **Feature**: [Link to spec.md]
      
      ## Content Quality
      
      - [ ] No implementation details (languages, frameworks, APIs)
      - [ ] Focused on user value and business needs
      - [ ] Written for non-technical stakeholders
      - [ ] All mandatory sections completed
      
      ## Requirement Completeness
      
      - [ ] No [NEEDS CLARIFICATION] markers remain
      - [ ] Requirements are testable and unambiguous
      - [ ] Success criteria are measurable
      - [ ] Success criteria are technology-agnostic (no implementation details)
      - [ ] All acceptance scenarios are defined
      - [ ] Edge cases are identified
      - [ ] Scope is clearly bounded
      - [ ] Dependencies and assumptions identified
      
      ## Feature Readiness
      
      - [ ] All functional requirements have clear acceptance criteria
      - [ ] User scenarios cover primary flows
      - [ ] Feature meets measurable outcomes defined in Success Criteria
      - [ ] No implementation details leak into specification
      
      ## Notes
      
      - Items marked incomplete require spec updates before `/speckit.clarify` or `/speckit.plan`
      ```

   b. **运行验证检查**：根据每个检查清单项审查规范：
      - 对于每个项目，确定它是通过还是失败
      - 记录发现的具体问题（引用相关规范部分）

   c. **处理验证结果**：

      - **如果所有项目都通过**：标记检查清单完成并继续步骤 6

      - **如果项目失败（不包括 [NEEDS CLARIFICATION]）**：
        1. 列出失败的项目和具体问题
        2. 更新规范以解决每个问题
        3. 重新运行验证直到所有项目通过（最多 3 次迭代）
        4. 如果 3 次迭代后仍然失败，在检查清单备注中记录剩余问题并警告用户

      - **如果 [NEEDS CLARIFICATION] 标记仍然存在**：
        1. 从规范中提取所有 [NEEDS CLARIFICATION: ...] 标记
        2. **限制检查**：如果存在超过 3 个标记，只保留 3 个最关键的（按范围/安全/UX 影响），对其余的做出明智的猜测
        3. 对于每个需要澄清的（最多 3 个），以此格式向用户呈现选项：

           ```markdown
           ## 问题 [N]: [主题]
           
           **上下文**：[引用相关规范部分]
           
           **我们需要知道的**：[来自 NEEDS CLARIFICATION 标记的具体问题]
           
           **建议答案**：
           
           | 选项 | 答案 | 影响 |
           |--------|--------|--------------|
           | A      | [第一个建议答案] | [这意味着什么] |
           | B      | [第二个建议答案] | [这意味着什么] |
           | C      | [第三个建议答案] | [这意味着什么] |
           | 自定义 | 提供您自己的答案 | [解释如何提供自定义输入] |
           
           **您的选择**：_[等待用户响应]_
           ```

        4. **关键 - 表格格式**：确保 markdown 表格格式正确：
           - 使用一致的间距，管道符对齐
           - 每个单元格内容前后应有空格：`| Content |` 而不是 `|Content|`
           - 标题分隔符必须至少有 3 个破折号：`|--------|`
           - 测试表格在 markdown 预览中是否正确呈现
        5. 按顺序编号问题（Q1、Q2、Q3 - 最多 3 个）
        6. 在等待响应之前一起呈现所有问题
        7. 等待用户响应所有问题的选择（例如，"Q1: A, Q2: Custom - [详情], Q3: B"）
        8. 通过将每个 [NEEDS CLARIFICATION] 标记替换为用户选择或提供的答案来更新规范
        9. 解决所有澄清后重新运行验证

   d. **更新检查清单**：每次验证迭代后，使用当前通过/失败状态更新检查清单文件

7. 报告完成，包含分支名称、规范文件路径、检查清单结果以及下一阶段的准备情况（`/speckit.clarify` 或 `/speckit.plan`）。

**注意：**脚本在写入之前会创建并检出新分支并初始化规范文件。

## 一般指南

## 快速指南

- 专注于用户需要**什么**以及**为什么**。
- 避免**如何**实施（无技术栈、API、代码结构）。
- 为业务利益相关者编写，而非开发人员。
- 不要创建嵌入在规范中的任何检查清单。那将是一个单独的命令。

### 部分要求

- **强制部分**：每个功能必须完成
- **可选部分**：仅在与功能相关时包含
- 当某部分不适用时，完全删除它（不要留作"N/A"）

### AI 生成指南

根据用户提示创建此规范时：

1. **做出明智的猜测**：使用上下文、行业标准和常见模式来填补空白
2. **记录假设**：在假设部分记录合理的默认值
3. **限制澄清**：最多 3 个 [NEEDS CLARIFICATION] 标记 - 仅用于关键决策：
   - 显著影响功能范围或用户体验
   - 具有不同影响的多种合理解释
   - 缺乏任何合理的默认值
4. **优先处理澄清**：范围 > 安全/隐私 > 用户体验 > 技术细节
5. **像测试人员一样思考**：每个模糊的需求都应该无法通过"可测试且明确"的检查清单项
6. **需要澄清的常见区域**（仅在不存在合理默认值时）：
   - 功能范围和边界（包含/排除特定用例）
   - 用户类型和权限（如果存在多种冲突解释）
   - 安全/合规要求（当法律/财务重要时）

**合理默认值示例**（不要询问这些）：

- 数据保留：针对领域的行业标准实践
- 性能目标：标准 Web/移动应用期望，除非另有指定
- 错误处理：带有适当回退的用户友好消息
- 认证方法：标准会话式或 Web 应用的 OAuth2
- 集成模式：使用项目适当的模式（Web 服务的 REST/GraphQL、库的函数调用、工具的 CLI 参数等）

### 成功标准指南

成功标准必须：

1. **可衡量**：包括具体指标（时间、百分比、数量、比率）
2. **技术无关**：不提及框架、语言、数据库或工具
3. **以用户为中心**：从用户/业务角度描述结果，而非系统内部
4. **可验证**：可以在不知道实施细节的情况下进行测试/验证

**好的示例**：

- "用户可以在 3 分钟内完成结账"
- "系统支持 10,000 个并发用户"
- "95% 的搜索在 1 秒内返回结果"
- "任务完成率提高 40%"

**糟糕的示例**（以实施为中心）：

- "API 响应时间低于 200ms"（太技术化，使用"用户立即看到结果"）
- "数据库可处理 1000 TPS"（实施细节，使用面向用户的指标）
- "React 组件高效渲染"（框架特定）
- "Redis 缓存命中率超过 80%"（技术特定）
