# Vendored Front End

Vendor source: `hmx-lang` @ 7c690d18ef41ba98fc0feda1fd7e0b3b1dc64ef9
Commit date:   2026-10-25T13:02:46+05:30
Subject:       P4: backend default resolution — flag > HMX_BACKEND env > compiled default

Vendor through: `() /tmp/opencode/hmx-compiler/tools/vendor.sh <path>` (`tools/vendor.sh` in this repo)

The web-vs-native parity gates live in `hmx-lang`; if a front-end change
lands there, vendor it here and re-run this repo's four native suites before
pushing (see docs/COMPILER_ROADMAP.md).
