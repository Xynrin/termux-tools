#!/usr/bin/env bash
#
# scripts/release.sh - 自动打 tag 并发布 GitHub Release
# Auto-tag and publish a GitHub Release based on scripts/version
#
# 用法 / Usage:
#   bash scripts/release.sh              # 用 scripts/version 打 tag 并发布
#   bash scripts/release.sh --dry-run    # 只演示不执行
#

set -euo pipefail

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

VERSION="$(cat scripts/version | tr -d '[:space:]')"
TAG="v${VERSION}"

echo "==> Version: $VERSION  Tag: $TAG"

# 工作区必须干净（避免遗漏未提交的改动）/ Working tree must be clean
if [[ -n "$(git status --porcelain)" ]]; then
    echo "ERROR: Working tree not clean. Commit or stash first."
    git status --short
    exit 1
fi

# tag 已存在则直接退出 / Skip if tag already exists
if git rev-parse "$TAG" &> /dev/null; then
    echo "Tag $TAG already exists. Skipping."
    exit 0
fi

# 打包源码 tarball / Build source tarball
ARCHIVE="termux-tools-${VERSION}.tar.gz"
echo "==> Creating archive: $ARCHIVE"
[[ $DRY_RUN -eq 1 ]] || git archive --format=tar.gz --prefix="termux-tools-${VERSION}/" -o "/tmp/$ARCHIVE" HEAD

# 创建 tag / Create tag
echo "==> Tagging $TAG"
[[ $DRY_RUN -eq 1 ]] || git tag -a "$TAG" -m "Release $TAG"

# 推送 tag / Push tag
echo "==> Pushing tag"
[[ $DRY_RUN -eq 1 ]] || git push origin "$TAG"

# 用 gh 创建 Release（如可用），否则提示 / Create release via gh if available
if command -v gh &> /dev/null; then
    echo "==> Creating GitHub release with asset"
    [[ $DRY_RUN -eq 1 ]] || gh release create "$TAG" \
        "/tmp/$ARCHIVE" \
        --title "$TAG" \
        --notes "Release $TAG. See commits since previous tag for details."
else
    echo "gh CLI not installed; skipping release creation."
    echo "Asset built at: /tmp/$ARCHIVE"
fi

echo "==> Done"
