#!/usr/bin/env bash
# Bootstrap script for chezmoi-based dotfiles (non-Nix systems).
#
# Usage:
#   ./bootstrap-chezmoi.sh --doctor    # Check environment, print status
#   ./bootstrap-chezmoi.sh --dry-run   # Show what chezmoi would change
#   ./bootstrap-chezmoi.sh --apply     # Apply dotfiles via chezmoi
#
# This script never changes your shell, installs packages, or modifies
# system files without your explicit --apply flag.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MODE=""

# ── Argument parsing ──────────────────────────────────────────────────────────

usage() {
    echo "Usage: $0 [--doctor | --dry-run | --apply | --reconfigure | --migrate-bash]"
    echo ""
    echo "  --doctor        Check that chezmoi and dependencies are installed"
    echo "  --dry-run       Show what chezmoi would apply (no changes made)"
    echo "  --apply         Apply dotfiles to your home directory"
    echo "  --reconfigure   Re-run interactive setup (resets chezmoi config)"
    echo "  --migrate-bash  Extract env vars from ~/.bashrc into ~/.zshrc.local"
    exit 1
}

case "${1:-}" in
    --doctor)        MODE="doctor" ;;
    --dry-run)       MODE="dry-run" ;;
    --apply)         MODE="apply" ;;
    --reconfigure)   MODE="reconfigure" ;;
    --migrate-bash)  MODE="migrate-bash" ;;
    *)              usage ;;
esac

# ── Helpers ───────────────────────────────────────────────────────────────────

print_ok()   { echo "  [OK]  $*"; }
print_warn() { echo "  [!!]  $*"; }
print_info() { echo "  [--]  $*"; }

check_chezmoi() {
    if ! command -v chezmoi >/dev/null 2>&1; then
        print_warn "chezmoi is NOT installed."
        echo ""
        echo "Install chezmoi first:"
        if [[ "$(uname -s)" == "Darwin" ]]; then
            echo "  brew install chezmoi"
        else
            echo "  sh -c \"\$(curl -fsLS get.chezmoi.io)\""
            echo "  (review the script before running — never blindly pipe to shell)"
        fi
        echo ""
        echo "Or download a binary: https://www.chezmoi.io/install/"
        exit 1
    fi
    print_ok "chezmoi $(chezmoi --version | awk '{print $3}')"
}

cmd_to_pkg() {
    case "$1" in
        nvim) echo "neovim" ;;
        *)    echo "$1" ;;
    esac
}

detect_install_cmd() {
    local pkgs=("$@")
    local pkg_list="${pkgs[*]}"
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "brew install ${pkg_list}"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "sudo apt-get update && sudo apt-get install -y ${pkg_list}"
    elif command -v dnf >/dev/null 2>&1; then
        echo "sudo dnf install -y ${pkg_list}"
    elif command -v pacman >/dev/null 2>&1; then
        echo "sudo pacman -S ${pkg_list}"
    elif command -v zypper >/dev/null 2>&1; then
        echo "sudo zypper install ${pkg_list}"
    else
        echo "# unknown package manager — install manually: ${pkg_list}"
    fi
}

check_deps() {
    local missing=()
    for cmd in zsh git curl tmux nvim; do
        if command -v "$cmd" >/dev/null 2>&1; then
            print_ok "$cmd ($(command -v "$cmd"))"
        else
            print_warn "$cmd — NOT FOUND"
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -eq 0 ]]; then
        return 0
    fi

    local pkgs=()
    for cmd in "${missing[@]}"; do
        pkgs+=("$(cmd_to_pkg "$cmd")")
    done

    echo ""
    print_warn "Missing: ${missing[*]}"
    echo ""
    echo "  Recommended install command:"
    echo ""
    echo "    $(detect_install_cmd "${pkgs[@]}")"
    echo ""
    echo "  After installing, re-run: $0 --doctor"
    return 1
}

# ── Modes ─────────────────────────────────────────────────────────────────────

doctor() {
    echo ""
    echo "=== chezmoi dotfiles doctor ==="
    echo ""
    echo "Source repo : $REPO_DIR"
    echo "Home dir    : $HOME"
    echo ""
    check_chezmoi
    echo ""
    echo "Dependencies:"
    check_deps || true
    echo ""
    echo "To preview changes : $0 --dry-run"
    echo "To apply changes   : $0 --apply"
    echo ""
}

ensure_config() {
    if [[ ! -f "$HOME/.config/chezmoi/chezmoi.toml" ]]; then
        print_info "Config not found — running chezmoi init to generate it from template"
        echo ""
        chezmoi init --source "$REPO_DIR"
        echo ""
    fi
}

reconfigure() {
    echo ""
    echo "=== chezmoi reconfigure ==="
    echo ""
    check_chezmoi
    local cfg="$HOME/.config/chezmoi/chezmoi.toml"
    if [[ -f "$cfg" ]]; then
        print_info "Removing existing config: $cfg"
        rm "$cfg"
    fi
    echo ""
    print_info "Running: chezmoi init --source \"$REPO_DIR\""
    echo ""
    chezmoi init --source "$REPO_DIR"
    echo ""
    print_ok "Config regenerated. Run --dry-run or --apply next."
    echo ""
}

dry_run() {
    echo ""
    echo "=== chezmoi dry-run (no changes will be made) ==="
    echo ""
    check_chezmoi
    ensure_config
    print_info "Running: chezmoi diff --source \"$REPO_DIR\""
    echo ""
    chezmoi diff --source "$REPO_DIR"
    echo ""
    print_info "To apply these changes, run: $0 --apply"
    echo ""
}

apply() {
    echo ""
    echo "=== chezmoi apply ==="
    echo ""
    check_chezmoi
    echo ""
    print_info "Source: $REPO_DIR"
    print_info "Target: $HOME"
    echo ""
    ensure_config
    print_info "Running: chezmoi apply --source \"$REPO_DIR\""
    echo ""
    chezmoi apply --source "$REPO_DIR"
    echo ""
    print_ok "Done. Restart your shell for changes to take effect."
    echo ""
}

migrate_bash() {
    echo ""
    echo "=== bash → zsh migration ==="
    echo ""

    local bashrc="$HOME/.bashrc"
    local zshrc_local="$HOME/.zshrc.local"

    if [[ ! -f "$bashrc" ]]; then
        print_warn "~/.bashrc not found — nothing to migrate."
        echo ""
        return 1
    fi

    print_info "Source : $bashrc"
    print_info "Target : $zshrc_local"
    echo ""

    # Extract candidate lines:
    #   export VAR=...   — custom env vars
    #   export PATH=...  — PATH modifications
    # Skip bash-specific internals and system noise
    local extracted
    extracted=$(grep -E '^[[:space:]]*export [A-Za-z_][A-Za-z0-9_]*=' "$bashrc" \
        | grep -v -E 'BASH_|HISTSIZE|HISTFILESIZE|HISTFILE|HISTCONTROL|PS1|PS2|PROMPT_COMMAND|DBUS_SESSION|COLORTERM|LS_COLORS|LESSOPEN|LESSCLOSE|MANPATH' \
        | sed 's/^[[:space:]]*//' \
        | sort -u)

    if [[ -z "$extracted" ]]; then
        print_info "No custom export lines found in ~/.bashrc."
        echo ""
        return 0
    fi

    echo "  Found the following lines to migrate:"
    echo ""
    while IFS= read -r line; do
        echo "    $line"
    done <<< "$extracted"
    echo ""

    # Check if already migrated (idempotent by date marker)
    local marker="# migrated from .bashrc on"
    if grep -q "$marker" "$zshrc_local" 2>/dev/null; then
        echo "  [!!]  ~/.zshrc.local already contains a previous migration."
        echo "        New entries will be appended — review and deduplicate manually."
        echo ""
    fi

    printf '\n%s %s\n' "$marker" "$(date '+%Y-%m-%d')" >> "$zshrc_local"
    while IFS= read -r line; do
        echo "$line" >> "$zshrc_local"
    done <<< "$extracted"

    print_ok "Migrated $(echo "$extracted" | wc -l | tr -d ' ') line(s) to $zshrc_local"
    echo ""
    echo "  Review and edit the file before reloading:"
    echo "    \$EDITOR $zshrc_local"
    echo "    source $zshrc_local"
    echo ""
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "$MODE" in
    doctor)        doctor ;;
    dry-run)       dry_run ;;
    apply)         apply ;;
    reconfigure)   reconfigure ;;
    migrate-bash)  migrate_bash ;;
esac
