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
    echo "Usage: $0 [--doctor | --dry-run | --apply]"
    echo ""
    echo "  --doctor    Check that chezmoi and dependencies are installed"
    echo "  --dry-run   Show what chezmoi would apply (no changes made)"
    echo "  --apply     Apply dotfiles to your home directory"
    exit 1
}

case "${1:-}" in
    --doctor)  MODE="doctor" ;;
    --dry-run) MODE="dry-run" ;;
    --apply)   MODE="apply" ;;
    *)         usage ;;
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

check_deps() {
    local missing=()
    for cmd in zsh git curl tmux; do
        if command -v "$cmd" >/dev/null 2>&1; then
            print_ok "$cmd ($(command -v "$cmd"))"
        else
            print_warn "$cmd — NOT FOUND"
            missing+=("$cmd")
        fi
    done
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo ""
        print_warn "Missing: ${missing[*]}"
        echo "Install them before running --apply."
        return 1
    fi
    return 0
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

dry_run() {
    echo ""
    echo "=== chezmoi dry-run (no changes will be made) ==="
    echo ""
    check_chezmoi
    echo ""
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
    print_info "Running: chezmoi apply --source \"$REPO_DIR\""
    echo ""
    chezmoi apply --source "$REPO_DIR"
    echo ""
    print_ok "Done. Restart your shell for changes to take effect."
    echo ""
}

# ── Dispatch ──────────────────────────────────────────────────────────────────

case "$MODE" in
    doctor)  doctor ;;
    dry-run) dry_run ;;
    apply)   apply ;;
esac
