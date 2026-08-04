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
rebuild-pre: update-nix-secrets
    git add --intent-to-add .

# 确认 sops 真的解密成功了
rebuild-post: check-sops

# 拉 nix-secrets 并重新锁定
#
# nix-config 把 nix-secrets 当成 locked remote input，本地改了不 push
# 是不生效的。rebase 失败会被忽略（工作树脏也让 rebuild 继续跑）。
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

# 确认 sops-nix 在 activation 时真的解密了
#
# ⚠️ 在 Darwin 上这个检查很弱：只能看目录在不在，看不到单个 secret 是否
# 解密成功。真正接一个新 secret 时，必须手工确认渲染出来的文件里没有
# 残留的 placeholder。
check-sops:
    #!/usr/bin/env bash
    set -uo pipefail
    if [ -d /run/secrets ] || [ -d "$HOME/.config/sops" ]; then
        echo "sops: /run/secrets 或 ~/.config/sops 存在"
    else
        echo "sops: 没找到 /run/secrets，如果这台机器声明了 secret，说明解密没跑"
    fi
    exit 0
