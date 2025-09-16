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
$INSTALL_CMD zsh git curl tmux fontconfig

# 處理 oh-my-zsh 安裝與連結
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    # 如果使用者沒有 oh-my-zsh，則建立軟連接到我們的版本
    ln -sf "$HOME/my-dotfiles/.oh-my-zsh" "$HOME/.oh-my-zsh"
    echo "已安裝本地維護的 oh-my-zsh。"
else
    # 如果已經存在 oh-my-zsh，檢查是否為我們的符號連結
    if [ ! -L "$HOME/.oh-my-zsh" ] || [ "$(readlink "$HOME/.oh-my-zsh")" != "$HOME/my-dotfiles/.oh-my-zsh" ]; then
        echo "已偵測到現有 oh-my-zsh 安裝，備份至 $HOME/.oh-my-zsh.backup"
        mv "$HOME/.oh-my-zsh" "$HOME/.oh-my-zsh.backup"
        ln -sf "$HOME/my-dotfiles/.oh-my-zsh" "$HOME/.oh-my-zsh"
        echo "已連結至本地維護的 oh-my-zsh。"
    else
        echo "oh-my-zsh 已正確連結，無需變更。"
    fi
fi

# 檢查並修復 .oh-my-zsh 內部的固定路徑問題
echo "檢查 .oh-my-zsh 內部路徑..."
if [ -d "$HOME/.oh-my-zsh" ]; then
    # 檢查是否存在內部的 .oh-my-zsh 目錄或檔案
    if [ -e "$HOME/.oh-my-zsh/.oh-my-zsh" ]; then
        echo "發現 .oh-my-zsh 內部的 .oh-my-zsh 檔案或目錄，進行處理..."
        # 如果是符號連結，修正指向
        if [ -L "$HOME/.oh-my-zsh/.oh-my-zsh" ]; then
            echo "修正內部符號連結..."
            rm -f "$HOME/.oh-my-zsh/.oh-my-zsh"
            ln -sf "$HOME/.oh-my-zsh" "$HOME/.oh-my-zsh/.oh-my-zsh"
        # 如果是目錄，考慮合併或替換
        elif [ -d "$HOME/.oh-my-zsh/.oh-my-zsh" ]; then
            echo "發現內部 .oh-my-zsh 目錄，備份並替換..."
            mv "$HOME/.oh-my-zsh/.oh-my-zsh" "$HOME/.oh-my-zsh/.oh-my-zsh.internal.backup"
            ln -sf "$HOME/.oh-my-zsh" "$HOME/.oh-my-zsh/.oh-my-zsh"
        # 如果是普通檔案，備份
        elif [ -f "$HOME/.oh-my-zsh/.oh-my-zsh" ]; then
            echo "發現內部 .oh-my-zsh 檔案，備份..."
            mv "$HOME/.oh-my-zsh/.oh-my-zsh" "$HOME/.oh-my-zsh/.oh-my-zsh.file.backup"
        fi
    fi
    
    # 找出並修復可能的固定路徑參考
    echo "掃描並修復 .oh-my-zsh 內部可能的固定路徑..."
    # 使用臨時檔案存儲符合條件的檔案清單
    TEMP_FILE=$(mktemp)
    
    # 分開 find 和 grep 命令，避免因為 xargs 處理空結果而卡住
    find "$HOME/.oh-my-zsh" -type f \( -name "*.zsh" -o -name "*.sh" \) 2>/dev/null > "$TEMP_FILE"
    
    # 檢查是否找到任何檔案
    if [ -s "$TEMP_FILE" ]; then
        # 對每個找到的檔案進行 grep 檢查
        while read -r file; do
            if grep -q "/home/" "$file" 2>/dev/null; then
                echo "處理檔案: $file"
                # 備份原始檔案
                cp "$file" "${file}.path.backup"
                # 替換固定的家目錄路徑為 $HOME 變數
                sed -i "s|/home/[^/]*/|\\$HOME/|g" "$file"
            fi
        done < "$TEMP_FILE"
    else
        echo "沒有找到需要處理的 zsh 或 sh 檔案。"
    fi
    
    # 刪除臨時檔案
    rm -f "$TEMP_FILE"
    echo "路徑修復完成。"
fi

# 建立配置文件的軟連接
ln -sf "$HOME/my-dotfiles/.zshrc" "$HOME/"

# 建立其他設定檔的軟連接
ln -sf "$HOME/my-dotfiles/.config" "$HOME/"
ln -sf "$HOME/my-dotfiles/.tmux.conf" "$HOME/"
ln -sf "$HOME/my-dotfiles/.inputrc" "$HOME/"

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
# 假設字型檔案存放在 "$HOME/my-dotfiles/fonts" 且已是 patched 版本
if [ -d "$HOME/my-dotfiles/fonts" ]; then
    # 指定使用者字型安裝路徑 (如需系統安裝請考慮 /usr/local/share/fonts, 並加入 sudo)
    font_dir="$HOME/.local/share/fonts/HackFonts"
    mkdir -p "$font_dir"
    # 複製字型
    cp -fvr "$HOME/my-dotfiles/fonts/"* "$font_dir/"
    # 更新字型快取
    fc-cache -fv "$font_dir"
    echo "Hack Fonts 安裝完成！"
else
    echo "找不到字型目錄：$HOME/my-dotfiles/fonts，跳過 Hack Fonts 安裝。"
fi

echo "部署完成！請重啟終端以使配置生效。"
