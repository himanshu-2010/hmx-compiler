# Vendored Front End

Vendor source: `hmx-lang` @ 40b8c96aa8d71663b8031e7b2a97ee4ab8279914
Commit date:   2026-10-25T15:05:34+05:30
Subject:       P5c groundwork: default-backend flip keys on the vendored roadmap content

Vendor through: `() /tmp/opencode/hmx-compiler/tools/vendor.sh <path>` (`tools/vendor.sh` in this repo)

The web-vs-native parity gates live in `hmx-lang`; if a front-end change
lands there, vendor it here and re-run this repo's four native suites before
pushing (see docs/COMPILER_ROADMAP.md).
