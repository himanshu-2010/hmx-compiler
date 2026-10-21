#!/usr/bin/env bash
# Vendor the HMX front end (lexer, parser, AST, resolver, C-emitting codegen,
# main.cpp) out of a hmx-lang checkout into this repository, and record which
# hmx-lang commit the vendored copy came from.
#
# hmx-lang remains the source of truth for the language front end (it owns the
# web playground parity gates). This repo pulls src/ from it on demand.
#
# Usage: tools/vendor.sh [path-to-hmx-lang]    # default: ../hmx-lang
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SOURCE="${1:-$REPO_ROOT/../hmx-lang}"

if [ ! -d "$SOURCE/src" ]; then
    echo "error: $SOURCE is not a hmx-lang checkout (no src/)" >&2
    exit 1
fi

cd "$SOURCE"
COMMIT="$(git rev-parse HEAD)"
COMMIT_DATE="$(git show -s --format=%cI HEAD)"
SUBJECT="$(git log -1 --format=%s HEAD)"
cd "$REPO_ROOT"

rsync -a --delete --exclude build_temp.c --exclude '*.o' \
      "$SOURCE/src/" "$REPO_ROOT/src/"

# The build manifest travels with the compiler sources: CMake targets must
# name every source file that lands in src/.
cp "$SOURCE/CMakeLists.txt" "$REPO_ROOT/CMakeLists.txt"

cat > "$REPO_ROOT/tools/VENDORED_FRONTEND.md" <<EOF
# Vendored Front End

Vendor source: \`hmx-lang\` @ ${COMMIT}
Commit date:   ${COMMIT_DATE}
Subject:       ${SUBJECT}

Vendor through: \`() ${REPO_ROOT}/tools/vendor.sh <path>\` (\`tools/vendor.sh\` in this repo)

The web-vs-native parity gates live in \`hmx-lang\`; if a front-end change
lands there, vendor it here and re-run this repo's four native suites before
pushing (see docs/COMPILER_ROADMAP.md).
EOF

echo "vendored hmx-lang @ ${COMMIT}"
