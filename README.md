# nix-config

jhl 的 nix-darwin + home-manager flake，目前管三台 Mac。NixOS 的骨架已经搭好但还没有机器。

私有数据在同级的 [`../nix-secrets`](https://github.com/jhl-hk/nix-secrets)（private），作为 flake input 引入。

## 结构

```
.
├── flake.nix              # host 自动发现、overlays、packages、checks、devShells
├── lib/                   # lib.custom：relativeToRoot / scanPaths
├── modules/               # 提供 options 的可复用模块，全部 scanPaths 自动导入
│   ├── common/            #   跨 NixOS/Darwin/HM —— host-spec.nix 在这里
│   ├── home/              #   home-manager 作用域
│   └── hosts/{common,nixos,darwin}/
├── overlays/              # additions / customLib / modifications / unstable
├── pkgs/common/           # 自制包，packagesFromDirectoryRecursive 自动发现
├── hosts/
│   ├── common/
│   │   ├── core/          # 每台机器都有的，含 hostSpec 灌注点
│   │   ├── users/jhl/     # 系统级用户 + home-manager 接线
│   │   └── optional/      # ★ 不会自动导入，host 自己点名
│   ├── darwin/<HostName>/ # 一台机器一个目录，自动发现
│   └── nixos/             # 空骨架
└── home/jhl/
    ├── common/core/       # 到处都要的基线
    ├── common/optional/   # 按机器点的菜
    └── <HostName>.nix     # 每台机器的点菜单
```

## 三条组装通道 + 一条数据总线

**Hosts** — `hosts/darwin/<Name>/` 里放个目录就是一台新机器，`flake.nix` 用 `readDir` 自动发现。host 文件很薄：设 `hostSpec.hostName`，然后从 `hosts/common/optional/` 里点需要的东西。

**Home** — 每个 `(用户, 机器)` 组合对应 `home/jhl/<HostName>.nix`，导入 `common/core` 加若干 `common/optional`。

**Modules** — `modules/**` 下的文件由 `lib.custom.scanPaths` 自动导入，只提供 `options`，不打开任何功能。打开是 host 的事（`<name>.enable = true`）。

**数据总线** — `modules/common/host-spec.nix` 定义 `hostSpec` 选项树，`hosts/common/core/default.nix` 用一行 `inherit (inputs.nix-secrets) ...` 灌进去。之后所有模块读 `config.hostSpec.<x>`，**不要**直接碰 `inputs.nix-secrets`。

### 最关键的一条规则

`modules/**` **会**自动导入，`hosts/common/optional/**` **不会**。前者定义能力，后者描述某一台机器的选择 —— 打开一个 host 文件就能看全这台机器跑什么。

## 常用命令

```bash
just rebuild        # 重建并切换当前机器（前后自动跑 update-nix-secrets 和 check-sops）
just build          # 只构建不切换
just check          # nix flake check --all-systems，会真的构建每台机器
just diff           # git diff，忽略 flake.lock
just update         # 更新 flake input + brew
just check-beta     # 报告这台机器是不是 macOS seed 版本
just clean          # 清理旧 generation

nix develop         # 进开发 shell：sops / age / ssh-to-age / just / gum / alejandra
```

Secrets 相关：`just sops-edit shared` 编辑密文，`just rekey` 改完 `.sops.yaml` 后重新加密，`just update-nix-secrets` 拉取并重新锁定。

## 加东西放哪儿

| 想加什么 | 放哪儿 |
|---|---|
| 每台机器都要的系统包 | `hosts/common/core/default.nix` 的 `environment.systemPackages` |
| 部分机器要的功能，没有参数 | `hosts/common/optional/darwin/<name>.nix`，然后在 host 的 `imports` 里点名 |
| 有参数、要 `enable` 开关的功能 | `modules/hosts/darwin/<name>/default.nix`（自动导入） |
| Homebrew 的 brew/cask/masApp | `hosts/common/core/darwin/apps.nix`（全机器）或某个 optional 文件（部分机器） |
| 到处都要的 dotfile | `home/jhl/common/core/<name>.nix` + 加进同目录 `default.nix` 的 imports |
| 只在 macOS 成立的 dotfile | `home/jhl/common/core/darwin/<name>.nix` |
| 按机器开关的 dotfile | `home/jhl/common/optional/<类>/<name>.nix`，在 `home/jhl/<Host>.nix` 里点名 |
| nixpkgs 里没有的包 | `pkgs/common/<name>/package.nix`（自动发现） |
| 覆写 nixpkgs 的包 | `overlays/default.nix` 的 `modifications`；要新版本优先用 `pkgs.unstable.<x>` |

详细的模板和边界情况见 `claude/skills/nix-config/references/recipes.md`。

## 几个必须知道的坑

- **`system.stateVersion` 类型按平台不同**：nix-darwin 要整数（`6`），NixOS 要字符串（`"25.05"`）。写混了求值就报类型错误。它钉的是迁移逻辑不是当前版本，不读 release notes 别动。
- **`lib.custom.relativeToRoot` 吃字符串，不吃路径字面量**。`relativeToRoot "hosts/common/core"` 对，`relativeToRoot ./hosts/common/core` 错。
- **`environment.systemPath` 用 `lib.mkOrder 1100`**。nix-darwin 把 nix 路径定义在默认序 1000、`/usr/bin` 那批在 1200，普通定义会随模块顺序漂移，Homebrew 的路径就可能跑到 nix 前面或 `/usr/bin` 后面。
- **home-manager 的 `extraSpecialArgs` 里不能传 `lib`**。会顶掉 HM 自己的 lib，`lib.hm` 消失，一堆模块炸。`lib.custom` 走 overlays 的 `customLib` 层挂进 `pkgs.lib`。
- **Darwin 上 sops 解密失败是静默的**。`just check-sops` 在 macOS 只能看目录在不在。接新 secret 时必须手工确认渲染出来的文件里没有残留 placeholder。
- **`onActivation.cleanup = "zap"`**：没在 `apps.nix` 里声明过的 Homebrew 包会在下次 switch 时被卸载。手动 `brew install` 的东西是临时的。
- **改了 nix-secrets 一定要 push**。它是 locked remote input，本地改动对 flake 不可见。`just rebuild` 会自动跑 `update-nix-secrets`，但 push 得自己来。

## 参考

- 设计来源：[EmergentMind/nix-config](https://github.com/EmergentMind/nix-config)
- [nix-darwin 手册](https://daiderd.com/nix-darwin/manual/index.html) · [home-manager 手册](https://nix-community.github.io/home-manager/) · [NixOS Options](https://search.nixos.org/options)
