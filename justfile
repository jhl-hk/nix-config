# ==========
# Variables
# ==========

hostname := `hostname`
secrets := "../nix-secrets"

# 默认列出所有 recipe
default:
    @just --list

# ==========
# 日常
# ==========

# 重建并切换到新配置
rebuild: rebuild-pre && rebuild-post
    sudo darwin-rebuild switch --flake .#{{ hostname }}
    @printf '\nSwitched to new config\n'

# rebuild 的别名，zsh 里的 sysnew 用的是 rebuild
switch: rebuild

# 只构建不切换
build: rebuild-pre
    sudo darwin-rebuild build --flake .#{{ hostname }}

# 带 --show-trace 的 rebuild，排查求值错误用
rebuild-trace: rebuild-pre && rebuild-post
    sudo darwin-rebuild switch --flake .#{{ hostname }} --show-trace

# rebuild 之后再跑一遍 check，push 之前用
rebuild-full: rebuild check

# 更新 flake input 再 rebuild
rebuild-update: update rebuild

# 检查求值错误
check *ARGS:
    nix flake check --all-systems --show-trace {{ ARGS }}

# 忽略 flake.lock 的 diff，input 更新的噪声太大
diff:
    git diff ':!flake.lock'

# ==========
# rebuild 的前后钩子
# ==========

# 拉最新 secrets，并让 flake 看见未跟踪的新文件
#
# git add --intent-to-add 是必需的：flake 的源码追踪完全忽略未跟踪文件，
# intent-to-add 把它们抬进 index 但不暂存内容。新建的 .nix 文件不做这步
# 会静默地不生效。

# rebuild 前钩子：拉 secrets + 让 flake 看见未跟踪文件
rebuild-pre: update-nix-secrets
    git add --intent-to-add .

# 确认 sops 真的解密成功了
rebuild-post: check-sops

# 拉 nix-secrets 并重新锁定
#
# nix-config 把 nix-secrets 当成 locked remote input，本地改了不 push
# 是不生效的。rebase 失败会被忽略（工作树脏也让 rebuild 继续跑）。

# 拉取 nix-secrets 并重新锁定
update-nix-secrets:
    #!/usr/bin/env bash
    set -uo pipefail
    if [ -d "{{ secrets }}" ]; then
        git -C "{{ secrets }}" fetch
        git -C "{{ secrets }}" rebase > /dev/null 2>&1 || true
    fi
    nix flake update nix-secrets --timeout 5

# ==========
# 维护
# ==========

# 更新 flake input 和 brew
update:
    nix flake update
    brew update && brew upgrade

# 清理旧的 generation
clean:
    sudo nix-collect-garbage -d
    mo clean

# 格式化所有 .nix 文件
fmt:
    nix fmt

# 报告这台机器是不是 macOS beta（决定 darwinHomebrew.macosBeta）
check-beta:
    #!/usr/bin/env bash
    set -euo pipefail
    build=$(sw_vers -buildVersion)
    catalog=$(defaults read /Library/Preferences/com.apple.SoftwareUpdate.plist CatalogURL 2>/dev/null || true)
    printf 'macOS %s (%s)\n' "$(sw_vers -productVersion)" "$build"
    if [[ "$catalog" == *seed* ]]; then
        printf 'beta: yes -- enrolled in a seed catalog\n'
        printf 'set `darwinHomebrew.macosBeta = true;` for this host\n'
    else
        printf 'beta: no -- release software update catalog\n'
        printf 'leave `darwinHomebrew.macosBeta` unset for this host\n'
    fi

# ==========
# Secrets
# ==========

# 生成一把新的 age key（打印到 stdout，不写文件）
age-key:
    nix run nixpkgs#age -- age-keygen

# 改完 .sops.yaml 之后，把每个密文文件重新加密给当前的收件人列表
rekey:
    #!/usr/bin/env bash
    set -euo pipefail
    cd "{{ secrets }}"
    shopt -s nullglob
    files=(secrets/*.yaml)
    if [ ${#files[@]} -eq 0 ]; then
        echo "没有 secrets/*.yaml，跳过"
        exit 0
    fi
    for f in "${files[@]}"; do
        echo "updatekeys $f"
        nix run nixpkgs#sops -- updatekeys -y "$f"
    done
    echo
    echo "别忘了在 {{ secrets }} 里 commit + push，然后跑 just update-nix-secrets"

# 编辑一个密文文件，例：just sops-edit shared
sops-edit FILE:
    #!/usr/bin/env bash
    set -euo pipefail
    export SOPS_AGE_KEY_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
    nix run nixpkgs#sops -- "{{ secrets }}/secrets/{{ FILE }}.yaml"

# rebuild 之后的轻量检查：本机声明的每个 secret 是否都真的落地了
#
# sops-install-secrets 是通过 postActivation 跑的，而 activate 脚本带
# set -e，所以解密失败会直接让 switch 报错中止 —— 不是静默的。
# 这里补的是另一件事：确认声明过的 secret 确实出现在 /run/secrets 下，
# 挡住「配置写了但没生效」这类情况。
#
# 没声明任何 secret 时直接跳过，不会假装成功。

# 确认本机声明的每个 secret 都真的落到了 /run/secrets
check-sops:
    #!/usr/bin/env bash
    set -uo pipefail
    manifest=$(nix eval --raw ".#darwinConfigurations.$(hostname).config.sops.secrets" \
                 --apply 's: builtins.concatStringsSep "\n" (builtins.attrNames s)' 2>/dev/null)
    if [ -z "$manifest" ]; then
        echo "sops: 本机没有声明任何 secret，跳过"
        exit 0
    fi
    rc=0
    while IFS= read -r name; do
        [ -z "$name" ] && continue
        if sudo test -s "/run/secrets/$name"; then
            echo "  ✅ /run/secrets/$name"
        else
            echo "  ❌ /run/secrets/$name 不存在或为空"
            rc=1
        fi
    done <<< "$manifest"
    exit $rc

# canary 自检：把 sops 管道端到端跑通一次
#
# 需要先按 hosts/common/optional/darwin/sops-canary.nix 头部的说明，
# 在 shared.yaml 里写入 canary/value 并把该文件 import 进本机。

# sops 管道端到端自检（需要先配好 canary，见文件头说明）
verify-sops EXPECT="sops-pipeline-ok":
    #!/usr/bin/env bash
    set -uo pipefail
    rc=0

    echo "1) 裸密文 /run/secrets/canary/value"
    if got=$(sudo cat /run/secrets/canary/value 2>/dev/null) && [ "$got" = "{{ EXPECT }}" ]; then
        echo "   ✅ 值正确"
    else
        echo "   ❌ 读到 '${got:-<空>}'，期望 '{{ EXPECT }}'"
        rc=1
    fi

    echo "2) 占位符替换 ~/.sops-canary"
    if [ -f "$HOME/.sops-canary" ]; then
        if grep -q "^canary={{ EXPECT }}$" "$HOME/.sops-canary"; then
            echo "   ✅ 占位符已替换"
        else
            echo "   ❌ 内容不对："
            sed 's/^/      /' "$HOME/.sops-canary"
            rc=1
        fi
    else
        echo "   ❌ 文件不存在"
        rc=1
    fi

    echo "3) 权限"
    perm=$(stat -f '%Sp %Su' "$HOME/.sops-canary" 2>/dev/null || echo "?")
    echo "   $perm  (期望 -rw------- $USER)"

    echo "4) 开机路径（launchd daemon，和 switch 时那条不是同一条）"
    sudo launchctl kickstart -k system/org.nixos.sops-install-secrets 2>&1 | sed 's/^/   /'
    sleep 1
    if sudo test -s /run/secrets/canary/value; then
        echo "   ✅ 重跑后密文仍在"
    else
        echo "   ❌ 重跑后密文没了 —— 重启后会失效"
        rc=1
    fi

    echo
    [ $rc -eq 0 ] && echo "sops 管道端到端通过" || echo "sops 管道有问题，见上面的 ❌"
    exit $rc
