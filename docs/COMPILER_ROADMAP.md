# HMX Compiler Roadmap (this repository)

Each phase below ends with a signed commit pushed to GitHub. Native gates:
`tests/run_integration.sh` (68), `tests/run_negative_tests.sh` (274),
`tests/run_stress_tests.sh` (149), `tests/run_cli_tests.sh` (33) — all must be
green after every phase; valgrind + fuzz gates after codegen/runtime phases.

| Phase | Milestone |
|---|---|
| P0 | Bootstrap repo, vendor front end from `hmx-lang`, ADR 0004 (this commit) |
| P1 | IR extraction — C emitter consumes IR (3 sub-PRs: statements, expressions, per-type helpers; generated C byte-identical after each) |
| P2 | Runtime library — inline `sd_*` helpers extracted to `runtime/hxrt.c` → `libhxrt.a` |
| P3 | x86-64 assembly backend v1 + `run_backend_diff.sh` differential suite → tag `0.1.0-alpha` |
| P4 | ✅ Flip default backend to asm; C backend kept behind a flag (-b c) |
| P5 | Tier B: machine-code encoder + static ELF writer + libc-free runtime; P5c flips the compiled default to -b elf → tag `0.2.0-independence` |

compiled-default: elf

P5b landed 2026-10-25 (hmx-lang commit `aeb6c4e`, vendored here): `-b elf`
covers asm-v1's full v1 surface plus decimal and text — a literal pool
(strings + exact double bits) rides between the generated code and the
runtime image; text routes through the hxrt refcount ABI port inside
`enc_rt.c` (byte-identical `sd_str` layout, O(1) substring views, hxrt
panic texts); decimal arithmetic goes via SSE (`addsd/subsd/mulsd/divsd`,
exact `-0.0` sign flips) with NaN-correct comparisons; print emits the
printf byte stream through per-argument helper calls (left-to-right
argument evaluation, no arity cap); `%f` is formatted by a 1536-bit bignum
with round-half-even on the exact binary value (byte-identical to glibc
over 150k random doubles). Differential gate: `run_elf_diff.sh` walks BOTH
fixture sets (the asm-v1 fixtures + the elf subset + decimal/runtime-panic
cases) — 12/12 byte-identical + 10 negative cases.

P5c landed 2026-10-25 (this commit): the compiled default in this repo is
**`-b elf`** — the vendored CMakeLists reads `compiled-default: elf` from
this roadmap (P4's marker-existence mechanism upgraded to marker content in
hmx-lang `40b8c96`, so the CMake source stays byte-identical across repos).
`-b asm` and `-b c` remain one flag away; the C path stays the sanitizer
host and differential oracle. Tagged `0.2.0-independence`.
| C1 | System stdlib v1: fs / time / args / env / rng |
| C2 | hashmap/hashset + JSON |
| C3 | TCP + HTTP → **backend-ready** |
| C4 | WASM backend + DOM host imports → **frontend-ready** |
| C5 | FFI (SDL/raylib/OpenGL) → **game-ready** |
| C6 | Freestanding/multiboot target → **os-ready** |
| C7 | Concurrency (epoll async event loop; threads later) |

P4 landed 2026-10-22 (hmx-lang commit `7c690d1`, vendored here): the effective
backend resolves as `-b` flag › `HMX_BACKEND` env › compiled default. This repo
compiles `HMX_DEFAULT_BACKEND="asm"` (CMake keys on this roadmap's presence);
hmx-lang keeps the C emitter as its default until the asm backend reaches
feature parity. The native runners pin `HMX_BACKEND="${HMX_BACKEND:-c}"`, so
each suite stays an exact C-oracle gate in both repos; the asm path is gated
by `tests/run_backend_diff.sh`.

After P4, when the language evolves, features land in `hmx-lang` first (it owns
the web playground parity), then are vendored here via `tools/vendor.sh`.
Once this repo reaches full feature parity with `hmx-lang`, it becomes the
primary HMX repository.
