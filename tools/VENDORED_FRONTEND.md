# Vendored Front End

Vendor source: `hmx-lang` @ 4516aecd56e39801369a04645238323eb7433bd1
Commit date:   2026-10-25T13:33:11+05:30
Subject:       P5a fix: force the elfrt blob generation with a custom target

Vendor through: `() /tmp/opencode/hmx-compiler/tools/vendor.sh <path>` (`tools/vendor.sh` in this repo)

The web-vs-native parity gates live in `hmx-lang`; if a front-end change
lands there, vendor it here and re-run this repo's four native suites before
pushing (see docs/COMPILER_ROADMAP.md).
