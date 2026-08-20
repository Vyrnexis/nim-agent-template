# nim-agent-template

Interactive project scaffolding tool and repository template for Nim projects featuring AI agent skills, MCP server integration, 6 build orchestrations, and GitHub Actions CI.

## Features

- **Flexible Scaffolding**: Create projects interactively or via CLI flags, either *in-place* (current directory) or inside a new *subdirectory*.
- **Self-Contained Agent Skills**: Pre-bundled with 19 curated Nim agent skills under `skills/` (copied automatically into `.agents/skills/`).
- **6 Standardized Build Profiles**: Native host-optimized, generic CPU baseline portable, and debug builds via GCC and Zig CC in `config.nims`.
- **MCP Tooling**: Automatic `.mcp/servers.json` configuration for `nimlangserver --mcp`.
- **Cross-Platform Tooling**: Includes `tools/zigcc` and `tools/zigcc.cmd` with dynamic resolution in `config.nims`.
- **Strict Standards**: Enforces `./bin/` binary emission, `##` doc comments, and conventional styling.

---

## Prerequisites

- **Nim**: Version 2.0.0 or higher (installed via [choosenim](https://github.com/dom96/choosenim) or system package manager).
- **Package Manager**:
  - `nimble` (bundled with standard Nim installations)
  - `atlas` (optional, installable via `nimble install atlas`)
- **C Toolchains**:
  - GCC or Clang (standard host compiler)
  - `zig` (optional, required only for `zigRelease`, `zigPortable`, and `zigDebug` tasks)

---

## Quick Start

### 1. Interactive Scaffolding

```bash
./init_nim_project.sh
```

Follow the terminal prompts to configure:
- **Project Name** (Sanitized to `snake_case`)
- **Destination** (`1) Subdirectory` or `2) In-place`)
- **Tooling** (`1) Nimble` or `2) Atlas`)
- **Project Type** (`1) Binary` or `2) Library`)
- **Author & License**

### 2. Automated / Scriptable CLI Flags

```bash
# Create a binary application in a new subdirectory
./init_nim_project.sh --name my_app --tooling nimble --kind bin

# Scaffold an Atlas library in-place inside an existing repository
./init_nim_project.sh --name my_lib --tooling atlas --kind lib --in-place
```

### 3. Install System-Wide CLI Command

To use `init-nim-project` anywhere across your system, run `--install-cli` from within this cloned repository:

```bash
# Run from within this repository directory:
./init_nim_project.sh --install-cli
```

This creates a symlink in `~/.local/bin/init-nim-project` pointing back to this repository. The script automatically resolves its canonical path to access all bundled `skills/` and `tools/` when run from any other directory:

```bash
# Scaffold new projects from any working directory:
cd ~/my_workspace
init-nim-project
```

---

## Generated Project Structure

```text
my_nim_app/
├── .agents/
│   └── skills/              # Bundled AI agent skills (19 skills)
├── .github/
│   └── workflows/
│       └── ci.yml           # Automated formatting and test pipeline
├── .mcp/
│   └── servers.json         # nimlangserver MCP configuration
├── bin/                     # Compiled executables destination
├── src/
│   └── my_nim_app.nim       # Core module / entry point with doc comments
├── tests/
│   └── test_all.nim         # Unittest test runner
├── tools/
│   ├── zigcc                # POSIX wrapper for Zig CC invocations
│   └── zigcc.cmd            # Windows wrapper for Zig CC invocations
├── config.nims              # Build task orchestrator (6 build profiles)
├── my_nim_app.nimble        # Nimble package manifest (or atlas config)
├── .gitignore               # Strict compiler/build exclusions
└── README.md                # Project documentation
```

---

## Build Tasks in Generated Projects

All compilation tasks strictly emit executables to `./bin/` at the repository root:

| Task | Toolchain | Target Architecture | Optimization & Flags |
|---|---|---|---|
| `nim nimRelease` | GCC/Default | Host Native | `-d:release -d:danger --opt:speed -march=native -mtune=native` |
| `nim nimPortable` | GCC/Default | Generic CPU | `-d:release --opt:size -mtune=generic -s` |
| `nim nimDebug` | GCC/Default | Host Debug | `--debuginfo:on --assertions:on --stackTrace:on` |
| `nim zigRelease` | Zig CC | Host Native | `-d:release -d:danger --opt:speed -O3 -march=native` |
| `nim zigPortable` | Zig CC | Generic CPU | `-d:release --opt:size -Oz -mcpu=baseline -s` |
| `nim zigDebug` | Zig CC | Host Debug | `--debuginfo:on` |

### Helper Tasks
- `nim test`: Runs the test suite via `tests/test_all.nim`.
- `nim fmt`: Runs `nimpretty` across all source and test files.
- `nim docs`: Emits HTML documentation into `./htmldocs/`.

---

## AI Agent & MCP Integration

- **Model Context Protocol (MCP)**:
  - Configured in `.mcp/servers.json` using `nimlangserver --mcp`.
  - Enables AI agents and IDEs supporting MCP to query symbols, find references, inspect types, and run diagnostic checks.

- **Agent Skills**:
  - Automatically installed into `.agents/skills/` of each generated project.
  - Compatible with agentic coding assistants (e.g., Antigravity, Claude Code, Cursor).

---

## Included Agent Skills (19 Skills)

- `atlas-package-cloner`: Atlas dependency management and workspace configuration.
- `build`: Standardized compilation profiles and binary output rules.
- `docs-gen`: Automated HTML documentation generation.
- `format-code`: Nim source formatting via `nimpretty`.
- `nim-api-design`: API design guidelines for public interfaces.
- `nim-c-bindings`: C header binding and cross-platform native library integration.
- `nim-c-wrappers`: Idiomatic high-level Nim wrappers around raw C bindings.
- `nim-code-organization`: Module structuring and state isolation.
- `nim-debugging`: Defect isolation, stack traces, and sanitizers.
- `nim-defect-analysis`: Memory safety and crash audits.
- `nim-doc-comments`: `##` doc comment standards for `nim doc` and LSP.
- `nim-error-handling`: Exception contracts and Option flow.
- `nim-fuzzing`: LibFuzzer harness and corpus generation.
- `nim-mcp-tools`: Symbol resolution and diagnostic navigation.
- `nim-ownership-hooks`: ARC/ORC ownership and lifetime hooks.
- `nim-style-guide`: Idiomatic Nim style guidelines.
- `nim-testing`: Deterministic test suites via `unittest`.
- `nimonyplugins`: Nimony compile-time plugins.
- `run-tests`: Test execution automation.

---

## Acknowledgements & Attributions

- **[nimlangserver](https://github.com/nim-lang/langserver)**: Official Nim Language Server supporting Language Server Protocol (LSP) and Model Context Protocol (MCP), maintained by the Nim team.
- **[planetis-m/skills](https://github.com/planetis-m/skills)**: Comprehensive curated agent skill repository for Nim development, authored by [planetis-m](https://github.com/planetis-m).
- **[setup-nim-action](https://github.com/jiro4989/setup-nim-action)**: GitHub Actions runner for Nim toolchains, authored by [jiro4989](https://github.com/jiro4989).

---

## License

MIT License. See [LICENSE](LICENSE) for details.
