#!/usr/bin/env bash
#
# scripts/release.sh - 自动从 CHANGELOG.md 抽取本版本说明，打 tag 并发布 GitHub Release
# Auto-extract this version's notes from CHANGELOG.md, tag, and publish a Release
#
# 用法 / Usage:
#   bash scripts/release.sh              # 完整流程：抽取 → 打 tag → push → release edit
#   bash scripts/release.sh --notes-only # 只刷新已有 release 的 notes（不重打 tag）
#   bash scripts/release.sh --dry-run    # 演示，不执行写操作
#

set -euo pipefail

MODE="full"
case "${1:-}" in
    --notes-only) MODE="notes-only" ;;
    --dry-run)    MODE="dry-run" ;;
    "") ;;
    *) echo "Unknown flag: $1" >&2; exit 2 ;;
esac

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

VERSION="$(tr -d '[:space:]' < scripts/version)"
TAG="v${VERSION}"

# 把 Cargo.toml 的 version 同步到 scripts/version —— 避免 banner 读到老版本号
# Sync Cargo.toml [package].version with scripts/version so the binary's
# env!("CARGO_PKG_VERSION") matches what's in the tag.
CARGO_TOML="$ROOT/xynrin-tui/Cargo.toml"
if [[ -f "$CARGO_TOML" ]]; then
    CUR_CARGO="$(awk -F'"' '/^version *=/ {print $2; exit}' "$CARGO_TOML")"
    if [[ "$CUR_CARGO" != "$VERSION" ]]; then
        echo "==> Bumping Cargo.toml: $CUR_CARGO -> $VERSION"
        if [[ "$MODE" != "dry-run" ]]; then
            sed -i.bak -E "0,/^version *=.*/s//version = \"${VERSION}\"/" "$CARGO_TOML"
            rm -f "${CARGO_TOML}.bak"
            ( cd "$ROOT/xynrin-tui" && cargo build --release --offline 2>/dev/null \
                || cargo build --release 2>/dev/null \
                || true )
            git add "$CARGO_TOML" "$ROOT/xynrin-tui/Cargo.lock" 2>/dev/null || true
            if ! git diff --cached --quiet 2>/dev/null; then
                git commit -m "chore(release): sync Cargo.toml to v${VERSION}

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
                git push origin main || true
            fi
        fi
    fi
fi

echo "==> Version: $VERSION  Tag: $TAG  Mode: $MODE"

# ============================================================
# 1. 从 CHANGELOG.md 抽取本版本段落（共享脚本）
# Extract this version's section from CHANGELOG.md (shared)
# ============================================================
NOTES_FILE="$(mktemp -t xynrin-notes.XXXXXX)"
trap 'rm -f "$NOTES_FILE"' EXIT

bash "$ROOT/scripts/extract-changelog.sh" "$VERSION" > "$NOTES_FILE"

if [[ ! -s "$NOTES_FILE" ]]; then
    echo "ERROR: CHANGELOG.md has no section for version $VERSION." >&2
    echo "       Add a '## [$VERSION] - YYYY-MM-DD' block before releasing." >&2
    exit 1
fi

echo "==> Release notes preview:"
echo "----------------------------------------"
head -20 "$NOTES_FILE"
[[ "$(wc -l < "$NOTES_FILE")" -gt 20 ]] && echo "..."
echo "----------------------------------------"

# ============================================================
# 2. notes-only: 仅刷新现有 release 说明
# notes-only: just refresh notes of an existing release
# ============================================================
if [[ "$MODE" == "notes-only" ]]; then
    if ! command -v gh &> /dev/null; then
        echo "gh CLI required for --notes-only." >&2
        exit 1
    fi
    echo "==> Updating notes of existing release $TAG"
    gh release edit "$TAG" --notes-file "$NOTES_FILE"
    echo "==> Done"
    exit 0
fi

# ============================================================
# 3. 完整流程：检查工作区、打 tag、push
# Full flow: clean check, tag, push
# ============================================================
if [[ -n "$(git status --porcelain)" ]]; then
    echo "ERROR: Working tree not clean. Commit or stash first." >&2
    git status --short
    exit 1
fi

if git rev-parse "$TAG" &> /dev/null; then
    echo "Tag $TAG already exists locally."
    if [[ "$MODE" != "dry-run" ]]; then
        echo "Re-run with --notes-only to update its notes, or move the tag manually." >&2
        exit 1
    fi
fi

echo "==> Tagging $TAG"
[[ "$MODE" == "dry-run" ]] || git tag -a "$TAG" -m "Release $TAG"

echo "==> Pushing tag (this triggers the CI build)"
[[ "$MODE" == "dry-run" ]] || git push origin "$TAG"

# ============================================================
# 4. CI 在后台跨平台编译；等它创建 release（带二进制和占位 body）后，
#    用 CHANGELOG 段覆盖 notes
# CI runs the cross-compile in background; once it has created the
# release with binaries, overwrite the body with the CHANGELOG section
# ============================================================
if [[ "$MODE" == "dry-run" ]]; then
    echo "==> [dry-run] would wait for CI then run: gh release edit $TAG --notes-file ..."
    echo "==> Done (dry-run)"
    exit 0
fi

if ! command -v gh &> /dev/null; then
    echo "gh CLI not installed. Tag is pushed; install gh and run --notes-only later." >&2
    exit 0
fi

echo "==> Waiting for CI release to appear (up to 10 min)..."
for _ in $(seq 1 60); do
    if gh release view "$TAG" &> /dev/null; then
        break
    fi
    sleep 10
done

if ! gh release view "$TAG" &> /dev/null; then
    echo "Release not created yet. Run \`bash scripts/release.sh --notes-only\` after CI finishes." >&2
    exit 0
fi

echo "==> Overwriting release notes from CHANGELOG.md"
gh release edit "$TAG" --notes-file "$NOTES_FILE"
echo "==> Done: https://github.com/Xynrin/termux-tools/releases/tag/$TAG"
