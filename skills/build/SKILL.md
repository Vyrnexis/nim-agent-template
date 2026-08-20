---
name: build
description: Compiles and builds the Nim project using standardized native host, generic CPU, and debug compilation profiles.
---

# Build & Compilation Profiles

All compilation tasks are managed via `config.nims` and strictly emit executables into `./bin/` at the repository root.

## Available Compilation Tasks

Execute the desired build profile using `nim <task_name>`:

1. `nim nimRelease`: Native host release binary (GCC/Default)
   - Aggressive speed optimizations targeting host CPU: `-d:release -d:danger --opt:speed --passC:"-march=native -mtune=native"`.
2. `nim nimPortable`: Generic CPU baseline portable binary (GCC/Default)
   - Size-optimized, stripped binary compatible with all target CPUs: `-d:release --opt:size --passC:"-mtune=generic" --passL:"-s"`.
3. `nim nimDebug`: Debug binary (GCC/Default)
   - Diagnostics build with runtime symbols and line tracing: `--debuginfo:on --assertions:on --lineTrace:on --stackTrace:on`.
4. `nim zigRelease`: Native host release binary (Zig CC)
   - Native Clang/Zig toolchain build with -O3 optimizations: `--cc:clang -d:release --passC:"-O3 -march=native"`.
5. `nim zigPortable`: Generic CPU baseline portable binary (Zig CC)
   - Stripped, size-optimized binary targeting baseline CPU model: `--cc:clang -d:release --opt:size --passC:"-Oz" --passC:"-mcpu=baseline" --passL:"-s"`.
6. `nim zigDebug`: Debug binary (Zig CC)
   - Clang/Zig CC debug build preserving debug symbols: `--cc:clang --debuginfo:on`.

## Strict Build Rules & Boundaries
- **Output Directory**: Never emit binaries into the project root or `src/`; all executables must output directly to `./bin/`.
- **Default Mode**: Always default to release builds (`nimRelease` or `nimPortable`) for production and distribution.
- **Debug Builds**: Use `nimDebug` or `zigDebug` strictly when actively diagnosing errors, stack traces, or assertion failures.
