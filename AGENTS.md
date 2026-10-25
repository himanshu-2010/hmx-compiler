# AGENTS.md

## Project layout

This repository is **hmx-compiler** — the HMX direct-backend compiler. Its goal
(ADR 0004) is to compile HMX to machine code directly (x86-64 first), ending
the dependency on a C toolchain for user programs. The original C-transpiler
path is **kept permanently** as the sanitizer host and differential oracle.

Source of truth for the language front end (lexer/parser/AST/resolver) is
`hmx-lang` (sibling checkout, `../hmx-lang`); vendor updates with
`tools/vendor.sh` and record them in `tools/VENDORED_FRONTEND.md`.

```
src/            vendored front end + C emitter (lexer.l, parser.y, ast, type_resolver, codegen, main.cpp)
src/ir/         (Phase 1) IR definition + AST→IR lowering
src/backend/    (P3+) backend.cpp (Tier A asm text), (P5a) encoder.cpp +
                elf_writer.cpp + elf_backend.cpp (Tier B `-b elf`: machine-code
                encoder, static ELF writer, freestanding runtime image)
runtime/        (Phase 2) hxrt.c → libhxrt.a; (Phase 5) libc-free runtime/libc/
tests/          4+bash runners + fixtures/*.hmx (run_packaging_tests.sh intentionally
                NOT vendored — it drives hmx-lang's packaging manifests)
docs/adr/       ADRs 0001-0003 vendored, 0004 = direct-backend decision
docs/COMPILER_ROADMAP.md  phase plan P0..C7 with gates
```

## Build & test commands

All commands from the repo root:

> **P4:** the built `hmx` here defaults to the asm backend (`-b c` reaches
> the C emitter; the native runners pin `HMX_BACKEND=c` for the C-oracle
> suites). In hmx-lang the compiled default is the C emitter.

```bash
cmake -S . -B build
cmake --build build            # builds build/hmx binary

./tests/run_integration.sh     # 68 .hmx fixture programs (exit 0 = pass)
./tests/run_negative_tests.sh  # 274 compile-error cases (exit 1 + stderr match)
./tests/run_stress_tests.sh    # 149 output/exit-code cases (exact stdout match)
./tests/run_cli_tests.sh       # 33 CLI behaviour tests

./tests/run_valgrind_tests.sh --fixtures   # after any codegen or runtime change
./tests/run_ubsan_tests.sh                 # run it BARE (instrumented-compile gates)
HMX_UBSAN=1 ./tests/run_integration.sh
HMX_ASAN=1 ./tests/run_stress_tests.sh
./tests/fuzz/run_fuzz.sh
```

Run all four main suites after any compiler change; there is no single
`test` command. The runners exercise `build/hmx` the same way as in
`hmx-lang` (stdout/stderr/exit-code), so suite expectations stay identical.

## Locked decisions (ADR 0004)

- Language name stays **HMX**; `.hmx` extension; binary `hmx`.
- Tier B end state: hand-written x86-64 encoder + static ELF writer + libc-free
  runtime. Tier A (asm text + system linker) is the Phase 3 shim; **P4 made it
  this repo's compiled default** (hmx-lang keeps the C default until asm
  reaches feature parity).
- The C emitter is permanent (sanitizer host + differential oracle backend).
- System V AMD64 ABI; aggregates pass by pointer at HMX-internal boundaries.
- x86-64 Linux first, macOS second; aarch64 and Windows later phases.

## Known quirks inherited from hmx-lang's src/

- Bison emits nine harmless shift/reduce conflicts; do not `%prec`-fix them.
- Never `dynamic_cast` to a base class in the front end (libFuzzer libc++abi
  quirk); cast to concrete node types, use `ASTNode::source_line` for bases.
- AST depth is capped at 200 (`HMX_MAX_NESTING`); keep `gather_children` in
  sync with new node types.
- Heap ownership: locals own their value, **params are borrowed**; new write
  paths reaching a borrowed slot must promote to owned or they are
  use-after-free. `valgrind --fixtures` and ASan suites are the gates.
- generics are monomorphized by the resolver (M17); declarations live in
  `generic_fns_`, erased after `resolve()`; clones copy only semantic fields.

## Workflow

1. Work phase by phase per `docs/COMPILER_ROADMAP.md`; each phase ends with a
   GPG-signed commit pushed to GitHub after all its gates are green.
2. Phase 1 IR-extraction sub-steps must keep the generated C **byte-identical**
   on every suite case (diff `build_temp.c` with `-keep-c`) — that is the
   referee for the refactor.
3. After any codegen/runtime change run valgrind + ASan/UBSan gates too.
4. If `../hmx-lang` moves the front end forward, re-vendor before building on
   top.
