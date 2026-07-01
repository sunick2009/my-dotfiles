#!/usr/bin/env bash

set -Eeuo pipefail

if command -v dpkg >/dev/null 2>&1; then
    curl -sLO https://github.com/neovim/neovim/releases/download/stable/nvim-linux64.deb
    dpkg -i nvim-linux64.deb
    rm nvim-linux64.deb
elif command -v dnf >/dev/null 2>&1; then
    echo "dpkg 不存在，使用 dnf 安裝 Neovim"
    # 嘗試啟用 CRB repository
    sudo dnf config-manager --set-enabled crb || {
        echo "無法啟用 crb，請手動執行: dnf config-manager --set-enabled crb"
        exit 1
    }
    # 嘗試安裝 epel-release
    sudo dnf install -y epel-release || {
        echo "無法安裝 epel-release，請手動執行: dnf install epel-release"
        exit 1
    }
    sudo dnf install -y neovim
else
    echo "無法檢測到 dpkg 或 dnf，請手動安裝 Neovim。"
    exit 1
fi

# Set Neovim shortcuts

NVIM_PATH="/usr/bin"
# 確認替代檔案存放目錄存在（預防 "No such file or directory" 錯誤）
sudo mkdir -p /var/lib/alternatives

# 確認 nvim 執行檔是否存在
if [ ! -x "${NVIM_PATH}/nvim" ]; then
    echo "找不到 nvim 執行檔於 ${NVIM_PATH}/nvim"
    exit 1
fi

# 註冊並設定 update-alternatives
sudo update-alternatives --install /usr/bin/vi neovim "${NVIM_PATH}/nvim" 110 || {
    echo "無法為 vi 註冊 neovim 替代設定"
    exit 1
}

sudo update-alternatives --set neovim "${NVIM_PATH}/nvim" || {
    echo "無法設定 neovim 替代設定"
    exit 1
}

sudo update-alternatives --install /usr/bin/vim vim "${NVIM_PATH}/nvim" 110 || {
    echo "無法為 vim 註冊 neovim 替代設定"
    exit 1
}

sudo update-alternatives --install /usr/bin/editor editor "${NVIM_PATH}/nvim" 1 || {
    echo "無法為 editor 註冊 neovim 替代設定"
    exit 1
}
