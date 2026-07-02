# 說明

此 repo 用於管理開發環境的 dotfiles，重點結合了 [Oh My Zsh](https://ohmyz.sh) 以及 [Neovim](https://neovim.io)。  
支援 **Linux**（Debian/Ubuntu、Fedora/RHEL、Arch 等）與 **macOS**。

管理方式採用 [chezmoi](https://www.chezmoi.io)，取代舊版的手動符號連結腳本。

---

## 快速開始

### 1. 安裝 chezmoi

```sh
# macOS
brew install chezmoi

# Linux（下載 binary，請先確認腳本內容再執行）
sh -c "$(curl -fsLS get.chezmoi.io)"
```

### 2. Clone 此 repo

```sh
git clone https://github.com/sunick2009/my-dotfiles.git ~/my-dotfiles
```

### 3. 確認環境

```sh
~/my-dotfiles/bootstrap-chezmoi.sh --doctor
```

偵測到缺少套件時，會根據目前系統（macOS / Ubuntu / Fedora / Arch 等）自動列出建議安裝指令，例如：

```
  Recommended install command:

    sudo apt-get update && sudo apt-get install -y zsh tmux neovim
```

### 4. 預覽變更

```sh
~/my-dotfiles/bootstrap-chezmoi.sh --dry-run
```

首次執行時，chezmoi 會互動式詢問幾個選項，包含名稱、Email、是否安裝 Oh My Zsh、字型、Neovim 插件與 tmux TPM 插件。布林選項預設為 `true`。

### 5. 套用

```sh
~/my-dotfiles/bootstrap-chezmoi.sh --apply
```

### 重新設定選項

若需要更改首次填寫的設定（例如關閉 Oh My Zsh、字型安裝或 tmux TPM 插件安裝）：

```sh
~/my-dotfiles/bootstrap-chezmoi.sh --reconfigure
```

這會清除現有設定並重新詢問所有選項，完成後再執行 `--apply` 即可。

詳細說明請見 [`docs/chezmoi-non-nix.md`](docs/chezmoi-non-nix.md)。

---

## 管理的設定檔

| 來源（repo） | 套用至 |
|-------------|--------|
| `dot_zshrc` | `~/.zshrc` |
| `dot_tmux.conf` | `~/.tmux.conf` |
| `dot_inputrc` | `~/.inputrc` |
| `dot_config/nvim/` | `~/.config/nvim/` |
| `dot_claude/settings.json.tmpl` | `~/.claude/settings.json` |
| `dot_claude/executable_statusline-command.sh` | `~/.claude/statusline-command.sh` |

Oh My Zsh 與 zsh 插件由 chezmoi 於首次 apply 時自動下載，不再隨 repo 一起 vendored。  
TPM 與 tmux 插件可於首次 apply 時自動安裝。  
vim-plug 與 Neovim 插件亦於首次 apply 時自動安裝（需已安裝 `nvim`）。

---

## 插件列表

### Zsh 插件

- git
- zsh-autosuggestions
- zsh-syntax-highlighting

### Neovim 插件（由 vim-plug 管理）

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

### Tmux 插件（由 TPM 管理）

- christoomey/vim-tmux-navigator
- tmux-plugins/tmux-yank
- tmux-plugins/tmux-prefix-highlight
- wfxr/tmux-power
- tmux-plugins/tmux-resurrect
- tmux-plugins/tmux-continuum

---

## 舊版安裝方式

原本的 `main.sh` 腳本已移至 [`legacy/`](legacy/) 保留。  
舊版僅支援 Linux（Debian/Fedora），不建議用於新安裝。

---

## 資料來源

大部分內容參考自 [seashell](https://gitlab.com/pivert/seashell) 的設計，並進一步整合了我的 ohmyzsh 設定。
