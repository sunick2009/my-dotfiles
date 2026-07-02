#!/usr/bin/env bash
# E2E test for chezmoi-based dotfiles deployment.
# Runs INSIDE the container (or any clean environment).
# Exits 0 on success, 1 on any failure.
set -euo pipefail

REPO_DIR="${REPO_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
PASS=0
FAIL=0
ERRORS=()

# ── Colour output ──────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_pass() { echo -e "${GREEN}  PASS${NC}  $*"; PASS=$((PASS + 1)); }
log_fail() { echo -e "${RED}  FAIL${NC}  $*"; FAIL=$((FAIL + 1)); ERRORS+=("$*"); }
log_info() { echo -e "${YELLOW}  ----${NC}  $*"; }

# ── Assertion helpers ──────────────────────────────────────────────────────────

assert_file_exists() {
    local label="$1" path="$2"
    if [ -e "$path" ]; then
        log_pass "$label: $path exists"
    else
        log_fail "$label: $path does NOT exist"
    fi
}

assert_not_symlink() {
    local label="$1" path="$2"
    if [ -L "$path" ]; then
        log_fail "$label: $path is a symlink (chezmoi should copy, not symlink)"
    else
        log_pass "$label: $path is a regular file/dir"
    fi
}

assert_contains() {
    local label="$1" path="$2" pattern="$3"
    if grep -qF "$pattern" "$path" 2>/dev/null; then
        log_pass "$label: '$pattern' found in $path"
    else
        log_fail "$label: '$pattern' NOT found in $path"
    fi
}

assert_not_contains() {
    local label="$1" path="$2" pattern="$3"
    if grep -qF "$pattern" "$path" 2>/dev/null; then
        log_fail "$label: '$pattern' found in $path (should not be)"
    else
        log_pass "$label: '$pattern' absent from $path"
    fi
}

assert_count() {
    local label="$1" path="$2" pattern="$3" expected="$4"
    local actual
    actual=$(grep -c "$pattern" "$path" 2>/dev/null || true)
    if [ "$actual" -eq "$expected" ]; then
        log_pass "$label: '$pattern' appears ${expected}x in $path"
    else
        log_fail "$label: '$pattern' appears ${actual}x in $path (expected ${expected}x)"
    fi
}

assert_cmd_ok() {
    local label="$1"; shift
    if "$@" >/dev/null 2>&1; then
        log_pass "$label"
    else
        log_fail "$label (command failed: $*)"
    fi
}

assert_output_contains() {
    local label="$1" pattern="$2"; shift 2
    local out
    out=$("$@" 2>&1 || true)
    if echo "$out" | grep -qF "$pattern"; then
        log_pass "$label: output contains '$pattern'"
    else
        log_fail "$label: output does not contain '$pattern' — got: $out"
    fi
}

# ── Setup: non-interactive chezmoi config ─────────────────────────────────────

setup_chezmoi() {
    log_info "Configuring chezmoi (non-interactive, no network downloads)..."

    git config --global user.email "ci@test.local"
    git config --global user.name "CI Test"
    git config --global init.defaultBranch "main"
    # Suppress detached HEAD advice
    git config --global advice.detachedHead false

    mkdir -p "$HOME/.config/chezmoi"
    cat > "$HOME/.config/chezmoi/chezmoi.toml" <<'EOF'
[data]
    name          = "CI Test User"
    email         = "ci@test.local"
    installOhMyZsh       = false
    installFonts         = false
    changeShell          = false
    installNeovimPlugins = false
EOF
    log_info "chezmoi config written to $HOME/.config/chezmoi/chezmoi.toml"
}

# ── Test suites ───────────────────────────────────────────────────────────────

test_environment() {
    echo ""
    echo "=== Environment ==="
    for cmd in chezmoi zsh git curl tmux nvim; do
        if command -v "$cmd" >/dev/null 2>&1; then
            log_pass "$cmd is available ($(command -v "$cmd"))"
        else
            log_fail "$cmd is NOT installed"
        fi
    done
}

test_apply() {
    echo ""
    echo "=== chezmoi apply ==="
    log_info "Running: chezmoi init --source \"$REPO_DIR\""
    chezmoi init --source "$REPO_DIR"

    log_info "Running: chezmoi apply --source \"$REPO_DIR\""
    chezmoi apply --source "$REPO_DIR"
    log_pass "chezmoi apply exited 0"
}

test_files_exist() {
    echo ""
    echo "=== File presence ==="
    assert_file_exists "zshrc"     "$HOME/.zshrc"
    assert_file_exists "tmux.conf" "$HOME/.tmux.conf"
    assert_file_exists "inputrc"   "$HOME/.inputrc"
    assert_file_exists "nvim/init.vim"            "$HOME/.config/nvim/init.vim"
    assert_file_exists "nvim/ftplugin/python.vim" "$HOME/.config/nvim/ftplugin/python.vim"
    assert_file_exists "nvim/ftplugin/sh.vim"     "$HOME/.config/nvim/ftplugin/sh.vim"
    assert_file_exists "nvim/ftplugin/vim.vim"    "$HOME/.config/nvim/ftplugin/vim.vim"
    assert_file_exists "nvim/templates/sh.tpl"         "$HOME/.config/nvim/templates/sh.tpl"
    assert_file_exists "nvim/templates/python.tpl"     "$HOME/.config/nvim/templates/python.tpl"
    assert_file_exists "nvim/templates/dockerfile.tpl" "$HOME/.config/nvim/templates/dockerfile.tpl"
    assert_file_exists "claude/settings.json"          "$HOME/.claude/settings.json"
    assert_file_exists "claude/statusline-command.sh"  "$HOME/.claude/statusline-command.sh"
}

test_not_symlinks() {
    echo ""
    echo "=== Files are not symlinks (chezmoi copies) ==="
    assert_not_symlink "zshrc"     "$HOME/.zshrc"
    assert_not_symlink "tmux.conf" "$HOME/.tmux.conf"
    assert_not_symlink "inputrc"   "$HOME/.inputrc"
    assert_not_symlink "nvim/"     "$HOME/.config/nvim"
    assert_not_symlink "claude/settings.json" "$HOME/.claude/settings.json"
}

test_init_vim_path_fix() {
    echo ""
    echo "=== init.vim template path correctness ==="
    assert_not_contains "no hardcoded /user/ path"   "$HOME/.config/nvim/init.vim" "/user/.config/nvim"
    assert_contains     "sh template uses ~/..."     "$HOME/.config/nvim/init.vim" "~/.config/nvim/templates/sh.tpl"
    assert_contains     "py template uses ~/..."     "$HOME/.config/nvim/init.vim" "~/.config/nvim/templates/python.tpl"
    assert_contains     "docker template uses ~/..." "$HOME/.config/nvim/init.vim" "~/.config/nvim/templates/dockerfile.tpl"
}

test_tmux_conf() {
    echo ""
    echo "=== tmux.conf quality ==="
    assert_count "default-terminal defined once" "$HOME/.tmux.conf" "default-terminal" 1
}

test_claude_config() {
    echo ""
    echo "=== Claude Code config ==="
    # Template should be rendered — no raw {{ }} left
    assert_not_contains "settings.json: no raw template syntax" \
        "$HOME/.claude/settings.json" "{{"
    # Path should be expanded to the actual home dir
    assert_contains "settings.json: statusline path uses HOME" \
        "$HOME/.claude/settings.json" "$HOME/.claude/statusline-command.sh"
    # Script should be executable
    assert_cmd_ok "statusline-command.sh is executable" \
        test -x "$HOME/.claude/statusline-command.sh"
}

test_zshrc_local() {
    echo ""
    echo "=== zshrc.local integration ==="
    assert_contains "zshrc sources zshrc.local" \
        "$HOME/.zshrc" "zshrc.local"
}

test_idempotency() {
    echo ""
    echo "=== Idempotency: chezmoi diff is empty after apply ==="
    local diff_out
    diff_out=$(chezmoi diff --source "$REPO_DIR" 2>&1 || true)
    if [ -z "$diff_out" ]; then
        log_pass "chezmoi diff is empty (apply is idempotent)"
    else
        log_fail "chezmoi diff is non-empty after apply:"
        echo "$diff_out"
    fi
}

test_bootstrap_script() {
    echo ""
    echo "=== bootstrap-chezmoi.sh --doctor ==="
    assert_cmd_ok "bootstrap --doctor exits 0" \
        bash "$REPO_DIR/bootstrap-chezmoi.sh" --doctor
    assert_output_contains "bootstrap --doctor mentions chezmoi" "chezmoi" \
        bash "$REPO_DIR/bootstrap-chezmoi.sh" --doctor
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║       my-dotfiles chezmoi e2e test                  ║"
    echo "╚══════════════════════════════════════════════════════╝"
    echo ""
    echo "  REPO : $REPO_DIR"
    echo "  HOME : $HOME"
    echo "  USER : $(whoami)"
    echo "  OS   : $(uname -sr)"
    if [ -f /etc/os-release ]; then
        echo "  DIST : $(. /etc/os-release && echo "$PRETTY_NAME")"
    fi
    echo ""

    setup_chezmoi
    test_environment
    test_apply
    test_files_exist
    test_not_symlinks
    test_init_vim_path_fix
    test_tmux_conf
    test_claude_config
    test_zshrc_local
    test_idempotency
    test_bootstrap_script

    echo ""
    echo "══════════════════════════════════════════════════════"
    echo -e "  Results: ${GREEN}${PASS} passed${NC}  ${RED}${FAIL} failed${NC}"
    if [ "${#ERRORS[@]}" -gt 0 ]; then
        echo ""
        echo "  Failed tests:"
        for e in "${ERRORS[@]}"; do
            echo -e "    ${RED}✗${NC} $e"
        done
    fi
    echo "══════════════════════════════════════════════════════"
    echo ""

    [ "$FAIL" -eq 0 ]
}

main "$@"
