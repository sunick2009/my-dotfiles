# 說明

此腳本主要用途是設定及安裝開發環境，重點結合了 [Oh My Zsh](https://ohmyz.sh) 以及 [Neovim](https://neovim.io)。腳本會根據不同作業系統的套件管理工具進行相應的安裝與設定，像是使用 `dnf`、`apt` 或其他工具。

## 主要功能

- **建立配置檔連結**：根據預設將配置檔（例如 [`.config`](.config) 、[`.tmux.conf`](.tmux.conf) 、[`.inputrc`](.inputrc)）連結到使用者的主目錄。
- **變更預設 Shell**：若系統中有 `chsh` 或 `usermod` 指令，則會自動更改預設 shell 為 `zsh`。
- **安裝 Neovim**：如果發現 neovim_install.sh 存在且具有執行權限，則會呼叫此腳本來安裝 Neovim。
- **其他設定**：可能額外包含一些自訂設定（例如個人化的 ohmyzsh 配置）。

## 如何使用

1. 先確認腳本具備執行權限：  
   ```sh
   chmod +x main.sh
   ```

2. 執行腳本：  
   ```sh
   ./main.sh
   ```

3. 腳本執行後會依序處理上述功能，並依作業系統自動選擇適合的套件管理指令，如下列範例（使用 `yum`）：
   ```bash
   elif command -v yum >/dev/null 2>&1; then
       PM="yum"
       UPDATE_CMD=""
       INSTALL_CMD="sudo yum install -y"
   ```

## 插件列表

### Zsh 插件

- git
- zsh-autosuggestions
- zsh-syntax-highlighting

### Neovim 插件

- vim-airline/vim-airline
- vim-airline/vim-airline-themes
- altercation/vim-colors-solarized
- tomasr/molokai
- lambdalisue/suda.vim
- scrooloose/nerdcommenter
- tmhedberg/matchit
- scrooloose/nerdtree
- arcticicestudio/nord-vim
- sheerun/vim-polyglot
- tpope/vim-fugitive
- jiangmiao/auto-pairs
- jpalardy/vim-slime （僅用於 Python）
- hanschen/vim-ipython-cell （僅用於 Python）
- tmhedberg/SimpylFold
- tpope/vim-surround
- arouene/vim-ansible-vault （用於 yaml, yaml.ansible）
- hkupty/iron.nvim

## 資料來源

大部分內容參考自 [seashell](https://gitlab.com/pivert/seashell) 的設計，並進一步整合了我的 ohmyzsh 設定。
