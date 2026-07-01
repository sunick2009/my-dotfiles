# chezmoi dotfiles — Non-Nix Systems

This guide covers the **chezmoi-based** dotfiles setup for Linux and macOS.
If you are on NixOS, use Home Manager instead (see main README).

---

## What gets managed

| File | Destination |
|------|-------------|
| `dot_zshrc` | `~/.zshrc` |
| `dot_tmux.conf` | `~/.tmux.conf` |
| `dot_inputrc` | `~/.inputrc` |
| `dot_config/nvim/` | `~/.config/nvim/` |

Oh My Zsh and its plugins are fetched via `.chezmoiexternal.toml` on first apply
(no vendored copy in the repo).

---

## Prerequisites

- `chezmoi` installed ([install guide](https://www.chezmoi.io/install/))
- `zsh`, `git`, `curl`, `tmux` available

---

## Fresh install

```bash
# 1. Clone the repo
git clone https://github.com/sunick2009/my-dotfiles.git ~/my-dotfiles

# 2. Check your environment
~/my-dotfiles/bootstrap-chezmoi.sh --doctor

# 3. Preview what will change (no files are modified)
~/my-dotfiles/bootstrap-chezmoi.sh --dry-run

# 4. Apply
~/my-dotfiles/bootstrap-chezmoi.sh --apply
```

During the first `chezmoi apply` you will be prompted for:

| Prompt | Default | Description |
|--------|---------|-------------|
| Full name | — | Stored in `~/.config/chezmoi/chezmoi.toml` |
| Email | — | Same |
| Install Oh My Zsh | `true` | Downloads OMZ + plugins via chezmoi external |
| Install Hack fonts | `false` | Copies fonts from `fonts/mac_linux/` |
| Change shell to zsh | `false` | Runs `chsh` — requires your password |
| Run PlugInstall | `true` | First-run Neovim plugin install via vim-plug |

You can change any answer by editing `~/.config/chezmoi/chezmoi.toml`.

---

## Migrating from the old main.sh

If you previously ran `main.sh`:

```bash
# 1. Back up existing files chezmoi will overwrite
cp ~/.zshrc ~/.zshrc.bak
cp ~/.tmux.conf ~/.tmux.conf.bak
cp ~/.inputrc ~/.inputrc.bak
cp -r ~/.config/nvim ~/.config/nvim.bak

# 2. Remove the old symlinks (if they point into the old repo)
[ -L ~/.zshrc ] && rm ~/.zshrc
[ -L ~/.tmux.conf ] && rm ~/.tmux.conf
[ -L ~/.inputrc ] && rm ~/.inputrc
[ -L ~/.config ] && rm ~/.config   # only if .config itself was symlinked

# 3. Remove old oh-my-zsh if it was a symlink to the vendored copy
[ -L ~/.oh-my-zsh ] && rm ~/.oh-my-zsh

# 4. Apply via chezmoi
~/my-dotfiles/bootstrap-chezmoi.sh --apply
```

---

## Day-to-day usage

```bash
# See what would change
chezmoi diff

# Apply changes
chezmoi apply

# Edit a managed file (opens in $EDITOR, then re-applies)
chezmoi edit ~/.zshrc

# Pull updates from the repo and re-apply
cd ~/my-dotfiles && git pull
chezmoi apply --source ~/my-dotfiles
```

---

## How to roll back

chezmoi does not keep automatic backups, but it warns before overwriting.
Before applying, always run `chezmoi diff` first.

To restore from your manual backup:
```bash
cp ~/.zshrc.bak ~/.zshrc
# etc.
```

---

## Oh My Zsh

Oh My Zsh is managed by `.chezmoiexternal.toml` and is installed to `~/.oh-my-zsh/`
during `chezmoi apply`. The plugins `zsh-autosuggestions` and `zsh-syntax-highlighting`
are cloned into `~/.oh-my-zsh/custom/plugins/`.

To skip Oh My Zsh entirely, set `installOhMyZsh = false` in
`~/.config/chezmoi/chezmoi.toml` and run `chezmoi apply`.

---

## Neovim

Neovim is **not** installed by chezmoi. Install it separately:

- macOS: `brew install neovim`
- Ubuntu/Debian: download from [neovim releases](https://github.com/neovim/neovim/releases)
- Fedora/RHEL: `sudo dnf install -y neovim`

The Neovim config (`~/.config/nvim/`) is managed by chezmoi.
vim-plug installs plugins automatically on first Neovim launch (via `init.vim`'s
bootstrap block), or you can run `:PlugInstall` manually.

---

## Fonts

Hack Nerd Font files are in `fonts/mac_linux/`. They are installed only if
`installFonts = true` is set:

- **Linux**: copied to `~/.local/share/fonts/HackFonts/`, `fc-cache` refreshed
- **macOS**: copied to `~/Library/Fonts/HackFonts/`

---

## Linux vs macOS differences

| Feature | Linux | macOS |
|---------|-------|-------|
| Font install dir | `~/.local/share/fonts/` | `~/Library/Fonts/` |
| Font cache | `fc-cache -fv` | automatic |
| Oh My Zsh | same | same |
| Shell change | `chsh -s $(which zsh)` | `chsh -s $(which zsh)` |

---

## Known limitations

- Neovim plugins are not installed during `chezmoi apply`; vim-plug bootstraps itself on first launch.
- `changeShell` requires `chsh` which may need your login password or sudo on some systems.
- The `run_once_` scripts only run once per machine. If you need to re-run them, delete the relevant entry in `~/.local/share/chezmoi/` (or use `chezmoi state delete-bucket --bucket=scriptState`).
- Oh My Zsh updates (`omz update`) are independent of chezmoi — run them separately.

---

## Legacy scripts

The original `main.sh` and `script/neovim_install.sh` are preserved in `legacy/`
for reference but are not recommended for new installs. They are Linux-only and
do not support macOS.
