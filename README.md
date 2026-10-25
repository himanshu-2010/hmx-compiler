# hmx-compiler — the HMX direct backend

This repository compiles [HMX](https://github.com/himanshu-2010/hmx-lang) to
machine code directly. Today it ships the proven C-transpiler path
(HMX → C → gcc) unchanged; the direct x86-64 backend lands phase by phase:

- **P1–P2** — IR extraction + runtime library (`libhxrt.a`)
- **P3–P4** — x86-64 assembly backend, then default → tag `0.1.0-alpha`
- **P5** — hand-written encoder + static ELF writer + libc-free runtime
  (zero external toolchain); **the compiled default is now `-b elf`**: a
  statically-linked `hmx` compiles and runs plain HMX programs with no C
  compiler, assembler, linker or libc on the target machine
  → tag `0.2.0-independence`

Full phase plan with gates: [`docs/COMPILER_ROADMAP.md`](docs/COMPILER_ROADMAP.md).
Decisions: [`docs/adr/0004-direct-backend.md`](docs/adr/0004-direct-backend.md).

## Build

```bash
cmake -S . -B build && cmake --build build     # -> build/hmx
./build/hmx run examples/hello.hmx
```

## Test

```bash
./tests/run_integration.sh      # 68 fixture programs
./tests/run_negative_tests.sh   # 274 compile-error cases
./tests/run_stress_tests.sh     # 149 output/exit-code cases
./tests/run_cli_tests.sh        # 33 CLI behaviour tests
```

## Relationship to hmx-lang

`hmx-lang` owns the language spec, the web playground, and the front end
(`src/` is vendored from it — see `tools/VENDORED_FRONTEND.md`). When this
repository reaches feature parity it becomes the primary HMX repository.
