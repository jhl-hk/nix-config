# Mac App Store 应用自动安装

## 前提条件

要自动安装 Mac App Store 应用，你需要：

1. **安装 mas-cli**（已在配置中添加）
2. **登录 Apple ID**

## 检查登录状态

```bash
mas account
```

如果已登录，会显示你的 Apple ID 邮箱。

## 登录 Apple ID

### 方法一：使用 mas 命令（推荐）

```bash
mas signin your@email.com
```

然后输入密码和双重认证码。

**注意**：从 macOS 10.13+ 开始，由于安全限制，`mas signin` 可能不工作。

### 方法二：通过 App Store 应用登录

1. 打开 App Store 应用
2. 点击左下角的账户图标
3. 登录你的 Apple ID
4. 验证登录状态：`mas account`

## 已配置的 MAS 应用

在 `hosts/common/darwin/homebrew.nix` 中配置的应用：

```nix
masApps = {
  "Yubico Authenticator" = 1497506650; # YubiKey Auth App
  "Infuse" = 1136220934; # Video Player
};
```

## 手动安装单个应用

如果自动安装失败，可以手动安装：

```bash
# 安装 Infuse
mas install 1136220934

# 安装 Yubico Authenticator
mas install 1497506650
```

## 查找应用 ID

如果要添加新的 MAS 应用：

```bash
# 搜索应用
mas search "应用名称"

# 列出已安装的应用及其 ID
mas list
```

## 常见问题

### 1. 安装失败：PKInstallError

**原因**：未登录 Apple ID

**解决**：
```bash
# 检查登录状态
mas account

# 如果未登录，通过 App Store 应用登录
open -a "App Store"
```

### 2. signin 命令不工作

**原因**：macOS 10.13+ 安全限制

**解决**：使用 App Store GUI 登录

### 3. 需要购买的应用

**说明**：mas 只能安装你账户中已购买/已下载过的应用

**解决**：
1. 在 App Store 中手动"获取"或购买应用
2. 然后 mas 就能自动安装了

## 添加新应用

1. 在 App Store 或使用 `mas search` 找到应用 ID
2. 编辑 `hosts/common/darwin/homebrew.nix`：

```nix
masApps = {
  "应用名称" = 应用ID;
  # 例如：
  "Xcode" = 497799835;
};
```

3. 重新构建：
```bash
make switch
```

## 卸载 MAS 应用

从配置中移除应用后，由于 `cleanup = "zap"` 设置，重新构建时会自动卸载。

或手动卸载：
```bash
mas uninstall 应用ID
```
