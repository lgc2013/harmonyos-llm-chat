# 📱 HarmonyOS LLM Chat 应用 - 手机安装指南

## 当前状态

| 项目 | 状态 |
|------|------|
| 应用构建 | ✅ 已完成 |
| 签名配置 | ❌ 需要华为账号 |
| 可安装包 | ⏳ 等待签名 |

---

## 🚀 快速安装（5 分钟完成）

### 方法一：DevEco Studio 自动签名（推荐）

#### 步骤 1：打开项目
```
在 DevEco Studio 中打开：D:\01-design-agent\harmonyos\MyApplication
```

#### 步骤 2：配置签名
1. 点击菜单 **File** → **Project Structure**
2. 选择左侧 **Project** → **Signing Configs**
3. 勾选 ✅ **Automatically generate signature**
4. 点击 **Sign In** 登录华为账号
5. 登录成功后点击 **OK**

#### 步骤 3：构建并安装
1. 手机连接电脑，开启 **USB 调试**
2. 点击 **Run** → **Run 'entry'**
3. 应用自动安装到手机

---

### 方法二：生成可分发的安装包

如果您需要将应用分享给他人安装：

#### 步骤 1：完成自动签名（同上）

#### 步骤 2：生成 APP 包
1. 点击 **Build** → **Build APP(s)**
2. 签名的 APP 包位置：
   ```
   entry/build/default/outputs/default/entry-default-signed.hap
   ```

#### 步骤 3：分享安装
- 将 `.hap` 文件发送给对方
- 对方需要使用 **hdc** 命令安装：
  ```
  hdc install entry-default-signed.hap
  ```

---

## ⚠️ 重要说明

### 为什么需要签名？
- **HarmonyOS NEXT**（纯血鸿蒙）要求所有应用必须签名
- 签名证书需要华为开发者平台颁发
- 个人开发者可以免费申请

### 如何注册华为开发者账号？
1. 访问：https://developer.huawei.com/consumer/cn/
2. 使用华为账号登录
3. 完成实名认证（免费）
4. 即可使用自动签名功能

---

## 📂 文件位置

| 文件 | 路径 |
|------|------|
| 未签名 HAP | `entry/build/default/outputs/default/entry-default-unsigned.hap` (297 KB) |
| 签名 HAP | `entry/build/default/outputs/default/entry-default-signed.hap` (需配置签名后生成) |

---

## 🔧 常见问题

### Q: 提示"No signingConfigs"？
A: 在 DevEco Studio 中完成自动签名配置

### Q: 登录华为账号失败？
A:
1. 确保网络可以访问华为服务器
2. 尝试使用手机扫码登录

### Q: 手机无法识别？
A:
1. 开启手机的 **开发者模式** 和 **USB 调试**
2. 在手机上允许 USB 调试授权
3. 尝试更换 USB 线或端口

---

*更新时间: 2026-03-18*
