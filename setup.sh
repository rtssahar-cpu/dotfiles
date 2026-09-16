#!/bin/bash

# =========================================================
# 開発サーバー（Ubuntu）初期セットアップスクリプト
# =========================================================

echo "==== 🚀 セットアップを開始します ===="

# 1. システムのパッケージを最新化
echo "📦 システムパッケージを更新中..."
sudo apt update && sudo apt upgrade -y

# 2. 仮想メモリ（Swap）のスマート作成（自動検知＋対話型）
if [ -f /swapfile ]; then
    echo "⏩ 仮想メモリはすでに存在するためスキップします。"
else
    # 物理メモリの合計容量を取得（MB単位）
    TOTAL_MEM=$(free -m | awk '/^Mem:/{print $2}')
    
    # 物理メモリが約1.5GB（1500MB）未満の場合のみ提案する
    if [ "$TOTAL_MEM" -lt 1500 ]; then
        echo "⚠️ 物理メモリが ${TOTAL_MEM}MB と少なめです（メモリ不足による強制終了の危険性があります）。"
        # ユーザーに作成するかどうかを尋ねる (デフォルトはNo)
        read -p "❓ 安定稼働のために2GBの仮想メモリ(Swap)を作成しますか？ (y/N): " ANS
        case "$ANS" in
            [Yy]* )
                echo "💾 仮想メモリ(2GB)を作成中..."
                sudo fallocate -l 2G /swapfile
                sudo chmod 600 /swapfile
                sudo mkswap /swapfile
                sudo swapon /swapfile
                
                # サーバー再起動時にもスワップを維持するための設定
                sudo sh -c 'echo "/swapfile none swap sw 0 0" >> /etc/fstab'
                echo "✅ 仮想メモリの作成が完了しました。"
                ;;
            * )
                echo "⏩ 仮想メモリの作成をスキップしました。"
                ;;
        esac
    else
        echo "⏩ 物理メモリが十分（${TOTAL_MEM}MB）あるため、仮想メモリの作成をスキップします。"
    fi
fi

# 3. GitHub CLI (gh) のインストール
if ! command -v gh &> /dev/null; then
    echo "🐙 GitHub CLI をインストール中..."
    (type -p wget >/dev/null || (sudo apt update && sudo apt-get install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
    echo "✅ GitHub CLI のインストールが完了しました。"
else
    echo "⏩ GitHub CLI はすでにインストールされているためスキップします。"
fi

# 4. Docker と Docker Compose のインストール
if ! command -v docker &> /dev/null; then
    echo "🐳 Docker をインストール中..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # ubuntuユーザーがsudoなしでdockerコマンドを使えるように権限を付与
    sudo usermod -aG docker ubuntu
    echo "✅ Docker のインストールが完了しました。"
else
    echo "⏩ Docker はすでにインストールされているためスキップします。"
fi

# 5. SSH（SSM）接続のタイムアウト防止設定
echo "🔌 SSH接続の安定化（無通信タイムアウト防止）を設定中..."
SSHD_CONFIG="/etc/ssh/sshd_config"

# ClientAliveIntervalが未設定の場合のみ追記（冪等性の担保）
if ! sudo grep -q "^ClientAliveInterval" $SSHD_CONFIG; then
    echo "ClientAliveInterval 30" | sudo tee -a $SSHD_CONFIG > /dev/null
fi

# ClientAliveCountMaxが未設定の場合のみ追記
if ! sudo grep -q "^ClientAliveCountMax" $SSHD_CONFIG; then
    echo "ClientAliveCountMax 120" | sudo tee -a $SSHD_CONFIG > /dev/null
fi

# 設定を反映させるためにSSHサービスを再起動
sudo systemctl restart ssh
echo "✅ SSH接続の安定化設定が完了しました。"

# 6. Neovim（最新安定版）のインストール
NVIM_MIN_VERSION="0.10.0"
NEED_NVIM_INSTALL=true
if command -v nvim &> /dev/null; then
    CURRENT_NVIM_VERSION=$(nvim --version | head -n1 | awk '{print $2}' | sed 's/^v//')
    if [ "$(printf '%s\n' "$NVIM_MIN_VERSION" "$CURRENT_NVIM_VERSION" | sort -V | head -n1)" = "$NVIM_MIN_VERSION" ]; then
        NEED_NVIM_INSTALL=false
    fi
fi

if [ "$NEED_NVIM_INSTALL" = true ]; then
    echo "📝 Neovim をインストール中..."
    ARCH=$(uname -m)
    if [ "$ARCH" = "x86_64" ]; then
        NVIM_ASSET="nvim-linux-x86_64.tar.gz"
        NVIM_DIRNAME="nvim-linux-x86_64"
    elif [ "$ARCH" = "aarch64" ]; then
        NVIM_ASSET="nvim-linux-arm64.tar.gz"
        NVIM_DIRNAME="nvim-linux-arm64"
    else
        echo "❌ 未対応のアーキテクチャです: $ARCH"
        exit 1
    fi

    curl -fLo /tmp/nvim.tar.gz "https://github.com/neovim/neovim/releases/latest/download/${NVIM_ASSET}"
    sudo rm -rf /opt/nvim
    sudo tar -C /opt -xzf /tmp/nvim.tar.gz
    sudo mv "/opt/${NVIM_DIRNAME}" /opt/nvim
    sudo ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
    rm -f /tmp/nvim.tar.gz
    echo "✅ Neovim のインストールが完了しました。"
else
    echo "⏩ Neovim はすでに十分新しいバージョンがインストールされているためスキップします。"
fi

# 7. LazyVim 動作に必要な依存パッケージのインストール
echo "🔧 LazyVim に必要な依存パッケージをインストール中..."
sudo apt-get update
sudo apt-get install -y ripgrep fd-find unzip build-essential python3 python3-pip python3-venv default-jdk

# fd-find は Ubuntu では fdfind という名前でインストールされるため fd という名前でも呼べるようにする
if command -v fdfind &> /dev/null && ! command -v fd &> /dev/null; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi
echo "✅ 依存パッケージのインストールが完了しました。"

# 8. Node.js のインストール（LSP・フォーマッタ・リンタ用）
if ! command -v node &> /dev/null; then
    echo "📦 Node.js をインストール中..."
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "✅ Node.js のインストールが完了しました。"
else
    echo "⏩ Node.js はすでにインストールされているためスキップします。"
fi

# 9. Claude Code CLI のインストール（claudecode.nvim 用）
if ! command -v claude &> /dev/null; then
    echo "🤖 Claude Code CLI をインストール中..."
    sudo npm install -g @anthropic-ai/claude-code
    echo "✅ Claude Code CLI のインストールが完了しました。"
else
    echo "⏩ Claude Code CLI はすでにインストールされているためスキップします。"
fi

# 10. LazyVim 設定の配置
echo "⚙️ LazyVim の設定を配置中..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NVIM_CONFIG_DIR="$HOME/.config/nvim"

if [ -d "$NVIM_CONFIG_DIR" ] && [ ! -L "$NVIM_CONFIG_DIR/init.lua" ]; then
    BACKUP_DIR="${NVIM_CONFIG_DIR}.bak.$(date +%Y%m%d%H%M%S)"
    echo "📂 既存の設定を ${BACKUP_DIR} にバックアップします。"
    mv "$NVIM_CONFIG_DIR" "$BACKUP_DIR"
fi

mkdir -p "$NVIM_CONFIG_DIR"
cp -R "$SCRIPT_DIR/nvim/." "$NVIM_CONFIG_DIR/"
echo "✅ LazyVim の設定の配置が完了しました。"

# 11. プラグインの事前インストール
echo "🔌 LazyVim のプラグインをインストール中..."
nvim --headless "+Lazy! sync" +qa
echo "✅ LazyVim のプラグインのインストールが完了しました。"


echo "==== 🎉 すべてのセットアップが完了しました！ ===="
echo "※ Dockerの権限設定を反映させるため、一度サーバーから exit して入り直してください。"
echo "※ 入り直した後、 gh auth login を実行してGitHubと連携してください。"
echo "※ nvim を起動すると LazyVim がプラグインを読み込みます（初回は少し時間がかかります）。"
echo "※ ClaudeCode を使う場合は、 claude を一度実行してログインしてください。"
