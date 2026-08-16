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

echo "==== 🎉 すべてのセットアップが完了しました！ ===="
echo "※ Dockerの権限設定を反映させるため、一度サーバーから exit して入り直してください。"
echo "※ 入り直した後、 gh auth login を実行してGitHubと連携してください。"