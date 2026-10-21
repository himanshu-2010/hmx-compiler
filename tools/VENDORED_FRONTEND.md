# Vendored Front End

Vendor source: `hmx-lang` @ 9fd775cf2999358f5d6d51f2ff1b981315faf6b6
Commit date:   2026-10-21T12:33:51+05:30
Subject:       M18.2: add try/catch recoverable runtime faults

Vendor through: `() /tmp/opencode/hmx-compiler/tools/vendor.sh <path>` (`tools/vendor.sh` in this repo)

The web-vs-native parity gates live in `hmx-lang`; if a front-end change
lands there, vendor it here and re-run this repo's four native suites before
pushing (see docs/COMPILER_ROADMAP.md).
