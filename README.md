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
just                # 列出全部 recipe
just rebuild        # 重建并切换当前机器（前后自动跑 update-nix-secrets 和 check-sops）
just build          # 只构建不切换
just check          # nix flake check --all-systems，会真的构建每台机器
just diff           # git diff，忽略 flake.lock
just update         # 更新 flake input + brew
just fmt            # alejandra 格式化
just check-beta     # 报告这台机器是不是 macOS seed 版本
just clean          # 清理旧 generation

nix develop         # 进开发 shell：sops / age / ssh-to-age / just / gum / alejandra / deadnix
```

Secrets 相关:

```bash
just sops-edit shared    # 编辑 ../nix-secrets/secrets/shared.yaml（会自动建目录、检查 age key）
just rekey               # 改完 .sops.yaml 后把每个密文重新加密给当前收件人
just update-nix-secrets  # 拉取 nix-secrets 并重新锁定
just check-sops          # 断言本机声明的每个 secret 都落到了 /run/secrets（rebuild 后自动跑）
just verify-sops         # canary 端到端自检，见下
```

**没有 CI。** 没有 `.github/`，没有 GitHub Actions。`just check` 就是 push 前的关卡，在本地跑。

### 验证 sops 管道

改了 age key、`.sops.yaml` 收件人、或者升级 macOS 之后，可以用一次性 canary 端到端验一遍。canary 模块验完就删了，从 git 历史取回：

```bash
p=hosts/common/optional/darwin/sops-canary.nix
git show "$(git rev-list -n1 HEAD -- "$p")^:$p" > "$p"
```

（`rev-list -n1` 找到最后一次动这个文件的提交，也就是删除它的那次；`^` 取它的父提交。直接 `git show HEAD:$p` 是不行的，删除之后 HEAD 里已经没有这个文件了。）

然后按该文件头部的三步走（建密文 → import → rebuild），`just verify-sops` 会检查四项：裸密文的值、`sops.templates` 的占位符是否真替换、目标权限、以及 `launchctl kickstart` 重跑证明**开机那条路**也通。验完把 import、`shared.yaml` 里的 canary、模块本身一起清掉。

`just verify-sops` 有前置条件检查，缺哪一步会直接说，不会给你一堆红叉。

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
- **sops 的两条落地路径可见性不同**。`switch` 时走 `postActivation`（`activate` 带 `set -e`，解密失败会**中止 switch 并报错**）；开机时走 `launchd.daemons.sops-install-secrets`，输出只进 launchd 日志。
- **`sops.templates.<x>.path` 落地的是软链**，指向 `/run/secrets/rendered/<name>`，而 `/run/secrets` 本身又是 `→ /run/secrets.d/N`（带代际编号，activation 原子切换）。三个后果：`owner`/`mode` 作用在**目标**上（查权限要 `stat -L`）；`/run` 易失，重启后靠 launchd 重建，重建完成前是悬空链；**任何写这个路径的命令**（`npm login`、`npm config set`）会写穿软链改到 `/run/secrets/rendered/`，下次 activation 直接冲掉 —— 改值要改源头 YAML。
- **加 secret 的顺序不能反**：先在 `nix-secrets` 里建好密文并 push，再在 host 里 import 消费模块。反过来会在求值期就挂（`opening file ... No such file or directory`），因为 `validateSopsFiles` 在求值时就检查文件存在。
- **`onActivation.cleanup = "zap"`**：没在 `apps.nix` 里声明过的 Homebrew 包会在下次 switch 时被卸载。手动 `brew install` 的东西是临时的。
- **改了 nix-secrets 一定要 push**。它是 locked remote input，本地改动对 flake 不可见。`just rebuild` 会自动跑 `update-nix-secrets`，但 push 得自己来。

## 参考

- 设计来源：[EmergentMind/nix-config](https://github.com/EmergentMind/nix-config)
- [nix-darwin 手册](https://daiderd.com/nix-darwin/manual/index.html) · [home-manager 手册](https://nix-community.github.io/home-manager/) · [NixOS Options](https://search.nixos.org/options)
