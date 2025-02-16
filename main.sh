#!/bin/bash
set -Eeuo pipefail

# 檢查並選擇包管理器
if command -v apt-get >/dev/null 2>&1; then
    PM="apt-get"
    UPDATE_CMD="sudo apt-get update -y"
    INSTALL_CMD="sudo apt-get install -y"
elif command -v dnf >/dev/null 2>&1; then
    PM="dnf"
    UPDATE_CMD=""
    INSTALL_CMD="sudo dnf install -y"
elif command -v yum >/dev/null 2>&1; then
    PM="yum"
    UPDATE_CMD=""
    INSTALL_CMD="sudo yum install -y"
else
    echo "沒有找到支持的包管理工具 (apt-get, dnf 或 yum)。"
    exit 1
fi

echo "使用的包管理器：$PM"

# 更新軟件源並安裝依賴
$UPDATE_CMD
$INSTALL_CMD zsh git curl tmux vi fontconfig

# 如果沒有安裝 oh‑my‑zsh，則使用本地版本安裝
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    ln -sf "$HOME/dotfiles/.oh-my-zsh" "$HOME/.oh-my-zsh"
    echo "已安裝本地維護的 oh-my-zsh。"
else
    echo "oh-my-zsh 已存在，跳過安裝步驟。"
fi

# 建立配置文件的軟連接
ln -sf "$HOME/dotfiles/.zshrc" "$HOME/"
# 注意：如果先前已處理 oh‑my‑zsh 的 symlink，可考慮移除此行，避免重複
ln -sf "$HOME/dotfiles/.oh-my-zsh" "$HOME/.oh-my-zsh"

# 建立其他設定檔的軟連接
ln -sf "$HOME/dotfiles/.config" "$HOME/"
ln -sf "$HOME/dotfiles/.tmux.conf" "$HOME/"
ln -sf "$HOME/dotfiles/.inputrc" "$HOME/"

# 切換默認 shell 為 zsh
if command -v chsh >/dev/null 2>&1; then
    chsh -s "$(command -v zsh)"
elif command -v usermod >/dev/null 2>&1; then
    sudo usermod -s "$(command -v zsh)" "$USER"
else
    echo "無法自動更改預設 shell，請手動將預設 shell 設定為 zsh。"
fi

# 安裝 Neovim (呼叫 neovim_install.sh)
if [ -x "./script/neovim_install.sh" ]; then
    ./script/neovim_install.sh
else
    echo "neovim_install.sh 不存在或沒有執行權限。"
    exit 1
fi

# 安裝 Neovim Plug
sh -c 'curl -fLo "$HOME/.local/share/nvim/site/autoload/plug.vim" --create-dirs \
  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' \
  && chmod -R a=rwX "$HOME/.local"

# 只取 vim-plug 部分，生成系統初始化設定檔
# 只取 vim-plug 部分，生成系統初始化設定檔
sudo mkdir -p /usr/share/nvim && sudo env "HOME=$HOME" sh -c 'sed "/call plug#end()/q" "$HOME/.config/nvim/init.vim" > /usr/share/nvim/sysinit.vim'

# 執行 PlugInstall 以安裝 vim-plug 指定的插件
nvim -e -u /usr/share/nvim/sysinit.vim -i NONE -c "PlugInstall|q" -c "qa" \
   && echo "Plug Plugins Install: OK" \
   && chmod -R a=rwX "$HOME/.vim" \
   && chmod -R a=rwX "$HOME/.local/state" \
   && rm -rf "$HOME/.cache"

# 安裝 Hack Fonts
echo "開始安裝 Hack Fonts..."
# 假設字型檔案存放在 "$HOME/dotfiles/fonts" 且已是 patched 版本
if [ -d "$HOME/dotfiles/fonts" ]; then
    # 指定使用者字型安裝路徑 (如需系統安裝請考慮 /usr/local/share/fonts, 並加入 sudo)
    font_dir="$HOME/.local/share/fonts/HackFonts"
    mkdir -p "$font_dir"
    # 複製字型
    cp -fvr "$HOME/dotfiles/fonts/"* "$font_dir/"
    # 更新字型快取
    fc-cache -fv "$font_dir"
    echo "Hack Fonts 安裝完成！"
else
    echo "找不到字型目錄：$HOME/dotfiles/fonts，跳過 Hack Fonts 安裝。"
fi

echo "部署完成！請重啟終端以使配置生效。"
