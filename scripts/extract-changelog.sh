#!/usr/bin/env bash
#
# scripts/extract-changelog.sh - 从 CHANGELOG.md 抽取指定版本段落
# Extract a specific version section from CHANGELOG.md
#
# 用法 / Usage:
#   bash scripts/extract-changelog.sh 3.1.0
#
# 输出 / Output: 该版本对应的段落（标题以下、下一个 ## [...] 之前）
#   The body of "## [<ver>] - YYYY-MM-DD" up to the next "## [...]"
#

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <version>" >&2
    exit 2
fi

VERSION="$1"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHANGELOG="$ROOT/CHANGELOG.md"

if [[ ! -f "$CHANGELOG" ]]; then
    echo "CHANGELOG.md not found: $CHANGELOG" >&2
    exit 1
fi

awk -v ver="$VERSION" '
    $0 ~ "^## \\[" ver "\\]" { flag=1; next }
    /^## \[/ && flag        { exit }
    flag                    { print }
' "$CHANGELOG"
