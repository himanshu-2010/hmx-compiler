# Vendored Front End

Vendor source: `hmx-lang` @ b5f7729338a4596f5798880ed8f550b74d31e0c8
Commit date:   2026-10-21T14:59:18+05:30
Subject:       P1b: pre-pass walkers consume the IR tree; single dispatch rule book

Vendor through: `() /tmp/opencode/hmx-compiler/tools/vendor.sh <path>` (`tools/vendor.sh` in this repo)

The web-vs-native parity gates live in `hmx-lang`; if a front-end change
lands there, vendor it here and re-run this repo's four native suites before
pushing (see docs/COMPILER_ROADMAP.md).
