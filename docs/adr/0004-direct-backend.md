# ADR 0004: Direct Backend (HMX stops being a C transpiler)

Date: 2026-10-21
Status: Accepted (governs this repository's purpose)

## Context

`hmx-lang` compiles HMX by transpiling to C and invoking `gcc -O2`. That path
stays working forever (it is the sanitizer/oracle backend), but it makes the
language depend on a full C toolchain at user-compile time, inherits C's
semantics fights (`volatile` locals for setjmp, struct-by-value ABI, `#line`
bookkeeping), and blocks the capabilities on the language roadmap: a real
unwinder for `try`/`catch` cleanup, checked arithmetic, file/network stdlib,
WASM, and freestanding (OS) targets.

## Decisions

1. **Tier B end state — fully independent toolchain.** The compiler emits
   x86-64 machine code directly (hand-written encoder), writes static ELF
   executables itself, and ships a libc-free runtime (`mmap` allocator,
   syscall I/O, own formatters/parsers, own `hx_setjmp`/`hx_longjmp`).
   No `gcc`/`as`/`ld` dependency for user programs.
2. **Interim Tier A shim (Phase 3)** emits x86-64 assembly text and links via
   the system toolchain, so the IR/backend boundary is proven before the
   encoder lands.
3. **The C emitter is permanent.** ASan/UBSan instrumentation of user programs
   is only possible through generated C, and the C backend serves as the
   differential oracle (`tests/run_backend_diff.sh`, added in Phase 3).
4. **Independent repo.** This work lives here (`hmx-compiler`), not on a
   branch of `hmx-lang`. When this repo reaches full feature parity with
   `hmx-lang`, it becomes the primary HMX repository; `hmx-lang` remains the
   language spec + web playground and is synced via `tools/vendor.sh`.
5. **Front-end sourcing.** `hmx-lang` is the source of truth for
   lexer/parser/AST/resolver. This repo vendors `src/` from it and records the
   source commit in `tools/VENDORED_FRONTEND.md`.
6. **Target order.** x86-64 Linux first; macOS (same System V ABI) second;
   aarch64 and Windows PE are later phases (encoder is IR-driven, so only the
   encoder/target tables change).
7. **ABI.** Internal code uses the System V AMD64 ABI so libc interop
   (malloc/printf/setjmp, Phase 3) stays trivial; aggregates pass by pointer
   at HMX-internal call boundaries.
8. **Identity.** The language name stays **HMX** (decided 2026-10-21);
   extensions `.hmx`, binary `hmx`, symbol prefixes unchanged.

## Consequences

- Phase 1 (IR statement lowering) must keep generated C byte-identical on all
  524 suite cases; done in P1a/P1b (both `hmx-lang` commits `bf055c7`, `b5f7729`),
  which also moved every pre-pass walker onto the IR tree.
- **Expression policy (P1b decision):** expressions are *not* copied into IR
  nodes. The IR owns statement structure; expression subtrees are reached via
  the annotated AST (`resolved_type`, ownership/liveness decisions already
  live there). Copying them into a second tree would duplicate resolver state
  with zero gain. Backends therefore walk IR statements + AST expression
  subtrees. This is the intended steady-state shape, not a transitional gap.
- Stdout/stderr buffering in the libc-free runtime must reproduce stdio's
  pipe behavior (fully buffered stdout, unbuffered stderr) or the exact-output
  test expectations shift.
- `parse_int`/`parse_decimal` and `%f` formatting must be byte-compatible with
  the C/strtol/strtod behavior; the differential backend suite is the referee.
- Overflow checks become explicit (`jo` after add/sub/imul) in the direct
  backend — pre-Work for the M19 checked-arithmetic flag.
- Ownership of the M18.2 unwind limitation: with direct codegen the compiler
  owns frames, so catch-time cleanup (release retains, run defers in unwound
  scopes) becomes expressible for the first time.
