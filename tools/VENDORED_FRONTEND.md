# Vendored Front End

Vendor source: `hmx-lang` @ 3ad917cb4268e82ccf3cc9d70c253823ddded90f
Commit date:   2026-10-25T15:22:13+05:30
Subject:       .gitignore: ignore stray example-named binaries (hello, xdec)

Vendor through: `() /tmp/opencode/hmx-compiler/tools/vendor.sh <path>` (`tools/vendor.sh` in this repo)

The web-vs-native parity gates live in `hmx-lang`; if a front-end change
lands there, vendor it here and re-run this repo's four native suites before
pushing (see docs/COMPILER_ROADMAP.md).
