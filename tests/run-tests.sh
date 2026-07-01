#!/usr/bin/env bash
# Local Docker-based e2e test runner for my-dotfiles.
# Builds a test image, runs container-test.sh inside it, reports results.
#
# Usage:
#   ./tests/run-tests.sh                    # Test all configured OS targets
#   ./tests/run-tests.sh ubuntu             # Ubuntu 22.04 only
#   ./tests/run-tests.sh ubuntu:24.04       # Specific version
#   ./tests/run-tests.sh fedora             # Fedora 40
#   ./tests/run-tests.sh --list             # Show available targets
#
# Environment variables:
#   KEEP_CONTAINERS=1   Don't remove containers after test (for debugging)
#   REBUILD=1           Force Docker image rebuild (skip cache)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KEEP_CONTAINERS="${KEEP_CONTAINERS:-0}"
REBUILD="${REBUILD:-0}"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

# ── Target definitions ────────────────────────────────────────────────────────
# Format: "name|dockerfile|build-arg"

TARGETS=(
    "ubuntu-22.04|tests/Dockerfile.ubuntu|UBUNTU_VERSION=22.04"
    "ubuntu-24.04|tests/Dockerfile.ubuntu|UBUNTU_VERSION=24.04"
    "debian-12|tests/Dockerfile.debian|DEBIAN_VERSION=12"
    "fedora-40|tests/Dockerfile.fedora|FEDORA_VERSION=40"
    "rocky-9|tests/Dockerfile.rocky|ROCKY_VERSION=9"
)

list_targets() {
    echo "Available targets:"
    for t in "${TARGETS[@]}"; do
        IFS='|' read -r name _ _ <<< "$t"
        echo "  $name"
    done
}

resolve_target() {
    local query="$1"
    for t in "${TARGETS[@]}"; do
        IFS='|' read -r name _ _ <<< "$t"
        if [[ "$name" == "$query"* ]]; then
            echo "$t"
            return 0
        fi
    done
    echo ""
}

# ── Runner ────────────────────────────────────────────────────────────────────

run_target() {
    local name="$1" dockerfile="$2" build_arg="$3"
    local image_tag="dotfiles-test-${name}"
    local container_name="dotfiles-test-${name}-$$"

    echo ""
    echo -e "${BOLD}▶ Testing: ${name}${NC}"
    echo "  Dockerfile : $dockerfile"
    echo "  Build arg  : $build_arg"
    echo ""

    local build_flags=()
    [ "$REBUILD" = "1" ] && build_flags+=(--no-cache)

    docker build \
        --file "$REPO_DIR/$dockerfile" \
        --build-arg "$build_arg" \
        --tag "$image_tag" \
        "${build_flags[@]}" \
        "$REPO_DIR" 2>&1 | sed 's/^/  [build] /'

    local rm_flag="--rm"
    [ "$KEEP_CONTAINERS" = "1" ] && rm_flag=""

    local exit_code=0
    docker run \
        $rm_flag \
        --name "$container_name" \
        --env "REPO_DIR=/repo" \
        "$image_tag" || exit_code=$?

    if [ "$exit_code" -eq 0 ]; then
        echo -e "\n  ${GREEN}✓ PASSED: ${name}${NC}"
    else
        echo -e "\n  ${RED}✗ FAILED: ${name} (exit $exit_code)${NC}"
        if [ "$KEEP_CONTAINERS" = "1" ]; then
            echo "  Container '$container_name' kept for inspection."
            echo "  Debug with: docker exec -it $container_name bash"
        fi
    fi

    return $exit_code
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    if [ "${1:-}" = "--list" ]; then
        list_targets
        exit 0
    fi

    if ! command -v docker >/dev/null 2>&1; then
        echo "Docker is not installed or not in PATH." >&2
        exit 1
    fi

    local selected_targets=()
    local query="${1:-all}"

    if [ "$query" = "all" ]; then
        selected_targets=("${TARGETS[@]}")
    else
        local match
        match=$(resolve_target "$query")
        if [ -z "$match" ]; then
            echo "Unknown target: $query" >&2
            list_targets
            exit 1
        fi
        selected_targets=("$match")
    fi

    echo ""
    echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║       my-dotfiles e2e test suite (Docker)            ║${NC}"
    echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo "  Repo: $REPO_DIR"
    echo "  Targets: ${#selected_targets[@]}"
    [ "$KEEP_CONTAINERS" = "1" ] && echo "  KEEP_CONTAINERS=1 (containers won't be auto-removed)"
    [ "$REBUILD" = "1" ] && echo "  REBUILD=1 (no Docker cache)"

    local overall_pass=0
    local overall_fail=0
    declare -A results

    for t in "${selected_targets[@]}"; do
        IFS='|' read -r name dockerfile build_arg <<< "$t"
        if run_target "$name" "$dockerfile" "$build_arg"; then
            results[$name]="PASS"
            overall_pass=$((overall_pass + 1))
        else
            results[$name]="FAIL"
            overall_fail=$((overall_fail + 1))
        fi
    done

    echo ""
    echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}  Summary${NC}"
    echo ""
    for t in "${selected_targets[@]}"; do
        IFS='|' read -r name _ _ <<< "$t"
        if [ "${results[$name]}" = "PASS" ]; then
            echo -e "  ${GREEN}✓${NC}  $name"
        else
            echo -e "  ${RED}✗${NC}  $name"
        fi
    done
    echo ""
    echo -e "  ${GREEN}${overall_pass} passed${NC}  ${RED}${overall_fail} failed${NC}"
    echo -e "${BOLD}══════════════════════════════════════════════════════${NC}"
    echo ""

    [ "$overall_fail" -eq 0 ]
}

main "$@"
