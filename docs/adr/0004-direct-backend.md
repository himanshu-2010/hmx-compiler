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
9. **Runtime is a first-class artifact (P2, 2026-10-21).** The ~800 lines of
   `sd_*` helpers that used to be emitted inline into every `build_temp.c`
   now live in `runtime/hxrt.c`, built once into `libhmxrt.a` by the
   compiler's own build; generated programs include `runtime/hxrt.h` and the
   driver links it (include dir + library path are baked into the `hmx`
   binary at build time). Sanitizer builds compile `hxrt.c` *from source*
   with the same `-fsanitize` flags so the refcount/UB gates keep observing
   the runtime. `tools/vendor.sh` ships `runtime/` alongside `src/`. The
   libc-free P5 runtime replaces this file wholesale, keeping the same
   symbol surface (the `sd_*` prefix will become the HMX runtime ABI).

12. **P3 = Tier A shim, shipped behind a flag (2026-10-22).** The `-b asm`
    backend emits AT&T-syntax x86-64 assembly text (consumable by the
    system `as`+`cc`), assembled against `runtime/hxrt.c`. This is
    scaffolding for the Tier B encoder (P5): it pioneered the scheduling,
    framing and label invariants — not the artifact. Deliberately NOT the
    long-term backend.
13. **v1 expression/statement subset (2026-10-22).** Values:
    int/bool/char/decimal/text. Expressions: literals, variables,
    arithmetic (incl. compound assign, `++`/`--`), text literal + `+` +
    `==`/`!=`, comparisons, `&&`/`||`/`!`, unary `-`, numeric casts,
    conditional expr, user calls, text built-ins (`length`, `substring`,
    `ord`, `chr`, `s[i]`). Statements: let/const, assignment, print,
    if/else, while, do-while, for, `loop N`, break/continue, return (single
    value), recursion. **Text parameters and text returns are supported.**
    Arrays, tuples, structs, foreach, switch, closures/lambdas, defer/try
    produce a precise `CompileError` (`asm backend v1: …`) — a rejected
    build is the failure mode, never a silent miscompile.
14. **Text ownership schedule (mirrors the C emitter).** Every text
    expression leaves an *owned* `sd_str*` (+1) in `rax` and its consumer
    drops it exactly once. Locals own their slot value; params are
    borrowed. The caller drops a text argument's +1 after the call,
    reading it from a per-call-site parking slot reserved during the scan
    pass (one slot per text argument, keyed by the CallExpr node) — stack
    pops are positional, so in-flight argument values must live in slots,
    never in `rax` across a release call. Return values ride a ret-slot
    (allocated in every frame): pre-zeroed at frame entry, the tail
    reloads it *after* the text releases, since the release calls clobber
    `rax`/`xmm0`.
15. **Call frame protocol.** Each frame = one slot per declaration + 3
    text homes + decimal scratch + ret slot; text local slots are zeroed
    at frame entry and re-executed declarations release-before-store, so
    a `let` inside a loop body is correct across iterations without
    scope-end cleanup. `pending` counts in-flight stack spills for
    16-byte alignment (`sub/add rsp,8` around odd-pending calls); printf
    packs text args as (len, data) word pairs and receives `al` = xmm
    arg count.
16. **Label protocol.** Labels are file-unique via a backend-wide counter
    (the `.L` prefix alone is not enough — GAS refuses duplicate
    definitions of a name within one file, even for local symbols). Loop
    labels: `break` → end label, `continue` → a dedicated
    pre-increment/pre-update label so `loop`'s counter and `for`'s update
    still run on continue.
17. **Block scoping in a flat frame.** Declarations allocate one slot per
    declaration (keyed by the declaration node, `decl_slots_`), and both
    the scan and emit passes snapshot/restore the name map around block
    scopes: sibling branches/loops may redeclare; `for`-headers scope to
    header+body, exactly like the C path's scopes.
18. **Differential gate.** `tests/run_backend_diff.sh` compares the asm
    backend against the C backend (stdout byte-identical + equal exit
    codes) over `tests/backend_diff/` fixtures, plus negative cases that
    must error cleanly, plus an optional valgrind gate over the
    asm-produced binaries (refcount schedule referee).

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
