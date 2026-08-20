#!/usr/bin/env bash
# Initialize a new Nim project with tool selection, build tasks, MCP configuration, and agent skills.

set -euo pipefail

# Resolve canonical script location across symlinks
SOURCE_PATH="${BASH_SOURCE[0]}"
while [[ -h "${SOURCE_PATH}" ]]; do
  DIR_STEP="$(cd -P "$(dirname "${SOURCE_PATH}")" && pwd)"
  SOURCE_PATH="$(readlink "${SOURCE_PATH}")"
  [[ "${SOURCE_PATH}" != /* ]] && SOURCE_PATH="${DIR_STEP}/${SOURCE_PATH}"
done
SCRIPT_DIR="$(cd -P "$(dirname "${SOURCE_PATH}")" && pwd)"

# Print a formatted section header.
print_header() {
  local title="$1"
  echo "================================================================================"
  echo "  ${title}"
  echo "================================================================================"
}

# Print an informational message.
print_info() {
  local msg="$1"
  echo "[INFO] ${msg}"
}

# Print an error message.
print_error() {
  local msg="$1"
  echo "[ERROR] ${msg}" >&2
}

# Prompt user for text input with a fallback default value.
prompt_default() {
  local prompt_text="$1"
  local default_val="$2"
  local input_val=""

  read -r -p "${prompt_text} [${default_val}]: " input_val
  if [[ -z "${input_val}" ]]; then
    echo "${default_val}"
  else
    echo "${input_val}"
  fi
}

# Sanitize arbitrary input string to valid snake_case Nim identifier.
sanitize_identifier() {
  local raw="$1"
  local sanitized
  sanitized=$(echo "${raw}" | tr '[:upper:]' '[:lower:]' | tr '-' '_' | tr ' ' '_' | sed -E 's/[^a-z0-9_]//g' | sed -E 's/_+/_/g' | sed -E 's/^_//;s/_$//')
  if [[ -z "${sanitized}" ]]; then
    sanitized="nim_app"
  fi
  echo "${sanitized}"
}

# Check existence of a required command or exit with instructions.
check_prerequisite() {
  local cmd="$1"
  local install_hint="$2"

  if ! command -v "${cmd}" >/dev/null 2>&1; then
    print_error "Command '${cmd}' not found on PATH."
    echo "${install_hint}" >&2
    exit 1
  fi
}

# Display command-line usage information.
show_usage() {
  cat << 'EOF'
Usage: init_nim_project.sh [OPTIONS]

Interactive or automated scaffolding for modern Nim projects with AI skills and MCP tooling.

Options:
  -n, --name NAME          Project name (default: current directory name or my_nim_app)
  -t, --tooling TOOL       Package tool: 'nimble' or 'atlas' (default: nimble)
  -k, --kind KIND          Project kind: 'bin' or 'lib' (default: bin)
  -a, --author AUTHOR      Author name (default: Vyrenxis)
  -l, --license LICENSE    License type (default: MIT)
  -i, --in-place           Scaffold in current working directory instead of creating a subdirectory
  --no-skills              Skip copying agent skills into .agents/skills/
  --install-cli            Install symlink into ~/.local/bin/init-nim-project and exit
  -h, --help               Display this help text and exit
EOF
}

main() {
  local cli_name=""
  local cli_tooling=""
  local cli_kind=""
  local cli_author=""
  local cli_license=""
  local cli_in_place="false"
  local cli_import_skills="true"
  local cli_mode="false"

  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--name)
        cli_name="$2"
        cli_mode="true"
        shift 2
        ;;
      -t|--tooling)
        cli_tooling="$2"
        cli_mode="true"
        shift 2
        ;;
      -k|--kind)
        cli_kind="$2"
        cli_mode="true"
        shift 2
        ;;
      -a|--author)
        cli_author="$2"
        cli_mode="true"
        shift 2
        ;;
      -l|--license)
        cli_license="$2"
        cli_mode="true"
        shift 2
        ;;
      -i|--in-place)
        cli_in_place="true"
        cli_mode="true"
        shift
        ;;
      --no-skills)
        cli_import_skills="false"
        cli_mode="true"
        shift
        ;;
      --install-cli)
        mkdir -p "${HOME}/.local/bin"
        ln -sf "${SCRIPT_DIR}/init_nim_project.sh" "${HOME}/.local/bin/init-nim-project"
        print_info "Installed symlink to ${HOME}/.local/bin/init-nim-project"
        exit 0
        ;;
      -h|--help)
        show_usage
        exit 0
        ;;
      *)
        print_error "Unknown option: $1"
        show_usage
        exit 1
        ;;
    esac
  done

  print_header "Nim Project Scaffolding Initializer"

  local current_dir_name
  current_dir_name=$(basename "${PWD}")

  local project_name=""
  local tool_choice=""
  local type_choice=""
  local author_name=""
  local license_type=""
  local import_skills="Y"
  local target_in_place="false"

  if [[ "${cli_mode}" == "true" ]]; then
    local raw_name="${cli_name:-${current_dir_name}}"
    project_name=$(sanitize_identifier "${raw_name}")
    tool_choice=$([[ "${cli_tooling}" == "atlas" ]] && echo "2" || echo "1")
    type_choice=$([[ "${cli_kind}" == "lib" ]] && echo "2" || echo "1")
    author_name="${cli_author:-Vyrenxis}"
    license_type="${cli_license:-MIT}"
    import_skills=$([[ "${cli_import_skills}" == "true" ]] && echo "Y" || echo "N")
    target_in_place="${cli_in_place}"
  else
    # 1. Interactive prompts
    local default_name="my_nim_app"
    if [[ "${current_dir_name}" != "nim-agent-template" && "${current_dir_name}" != "github" ]]; then
      default_name="${current_dir_name}"
    fi

    local raw_project_name
    raw_project_name=$(prompt_default "Enter project name" "${default_name}")
    project_name=$(sanitize_identifier "${raw_project_name}")

    if [[ "${PWD}" != "${SCRIPT_DIR}" ]]; then
      echo ""
      echo "Select Destination:"
      echo "  1) Create subdirectory (./${project_name})"
      echo "  2) In-place (scaffold in current directory: ${PWD})"
      local dest_choice
      dest_choice=$(prompt_default "Choice (1 or 2)" "1")
      if [[ "${dest_choice}" == "2" ]]; then
        target_in_place="true"
      fi
    else
      target_in_place="false"
    fi

    echo ""
    echo "Select Tooling:"
    echo "  1) Nimble (Standard packaging)"
    echo "  2) Atlas (Workspace & isolated dependencies)"
    tool_choice=$(prompt_default "Choice (1 or 2)" "1")

    echo ""
    echo "Select Project Type:"
    echo "  1) Binary / Executable"
    echo "  2) Library Package"
    type_choice=$(prompt_default "Choice (1 or 2)" "1")

    echo ""
    author_name=$(prompt_default "Enter author name" "Vyrenxis")
    license_type=$(prompt_default "Enter license type" "MIT")

    echo ""
    import_skills=$(prompt_default "Import agent skills into .agents/skills/? (Y/n)" "Y")
  fi

  # Prevent in-place scaffolding directly inside the template source repository
  if [[ "${target_in_place}" == "true" && "${PWD}" == "${SCRIPT_DIR}" ]]; then
    print_error "Cannot scaffold in-place directly inside the template source repository."
    echo "Please change to your project workspace directory or omit --in-place to create a subdirectory." >&2
    exit 1
  fi

  # Determine target directory
  local target_dir="${PWD}"
  if [[ "${target_in_place}" != "true" ]]; then
    target_dir="${PWD}/${project_name}"
    mkdir -p "${target_dir}"
  fi

  # 2. Dependency verification
  check_prerequisite "nim" "Please install Nim using Choosenim or your system package manager."
  if [[ "${tool_choice}" == "2" ]]; then
    check_prerequisite "atlas" "Atlas is required. Install via: nimble install atlas"
  else
    check_prerequisite "nimble" "Nimble is required. It is bundled with standard Nim distributions."
  fi

  print_info "Target directory: ${target_dir}"
  cd "${target_dir}"

  # Create standard directories
  mkdir -p src tests bin tools .mcp .agents/skills .github/workflows

  # 3. Core Nim Package Setup
  if [[ "${tool_choice}" == "1" ]]; then
    cat << _NIMBLE_EOF_ > "${project_name}.nimble"
# Package

version       = "0.1.0"
author        = "${author_name}"
description   = "Scaffolded Nim project: ${project_name}"
license       = "${license_type}"
srcDir        = "src"
binDir        = "bin"
_NIMBLE_EOF_

    if [[ "${type_choice}" == "1" ]]; then
      cat << _NIMBLE_BIN_EOF_ >> "${project_name}.nimble"
bin           = @["${project_name}"]
_NIMBLE_BIN_EOF_
    fi

    cat << '_NIMBLE_TASKS_EOF_' >> "${project_name}.nimble"

# Dependencies

requires "nim >= 2.0.0"

task test, "Run the full test suite":
  exec "nim c -r --verbosity:0 tests/test_all.nim"

task fmt, "Format all source files using nimpretty":
  exec "nimpretty src/**/*.nim tests/**/*.nim"

task docs, "Generate HTML documentation":
  exec "nim doc --project --outdir:htmldocs src/" & project_name & ".nim"
_NIMBLE_TASKS_EOF_
  else
    # Initialize Atlas workspace
    if command -v atlas >/dev/null 2>&1; then
      if [[ ! -f "nim.cfg" && ! -f "atlas.json" ]]; then
        atlas init || true
      fi
    fi
  fi

  # 4. Generate Main Source File (avoid overwriting existing logic if in-place)
  if [[ ! -f "src/${project_name}.nim" ]]; then
    if [[ "${type_choice}" == "1" ]]; then
      cat << _SRC_BIN_EOF_ > "src/${project_name}.nim"
## Main application module for ${project_name}.
## Provides the primary execution entry point and core logic.

proc runApplication*(appName: string): int =
  ## Runs the primary execution workflow and returns an exit code.
  echo "Starting " & appName
  result = 0

when isMainModule:
  quit(runApplication("${project_name}"))
_SRC_BIN_EOF_
    else
      cat << _SRC_LIB_EOF_ > "src/${project_name}.nim"
## Core library module for ${project_name}.
## Implements exported types and library operations.

type
  Context* = object
    ## Operational state container for ${project_name}.
    name*: string
    isActive*: bool

proc initContext*(name: string): Context =
  ## Initializes and returns a new Context instance.
  result = Context(name: name, isActive: true)

proc execute*(ctx: Context): bool =
  ## Executes the configured operation within the context.
  result = ctx.isActive
_SRC_LIB_EOF_
    fi
  fi

  # 5. Generate Unit Tests
  if [[ ! -f "tests/test_all.nim" ]]; then
    cat << _TEST_HEADER_EOF_ > "tests/test_all.nim"
## Test suite for ${project_name}.
## Exercises module functionality using the standard unittest framework.

import std/unittest
import ../src/${project_name}

suite "${project_name} test suite":
  test "basic initialization":
_TEST_HEADER_EOF_

    if [[ "${type_choice}" == "1" ]]; then
      cat << '_TEST_BIN_BODY_EOF_' >> "tests/test_all.nim"
    check runApplication("test_run") == 0
_TEST_BIN_BODY_EOF_
    else
      cat << '_TEST_LIB_BODY_EOF_' >> "tests/test_all.nim"
    let ctx = initContext("test_env")
    check ctx.name == "test_env"
    check ctx.isActive == true
    check execute(ctx) == true
_TEST_LIB_BODY_EOF_
    fi
  fi

  # 6. Generate Project-Local Zig Wrappers
  if [[ -f "${SCRIPT_DIR}/tools/zigcc" ]]; then
    cp "${SCRIPT_DIR}/tools/zigcc" "tools/zigcc"
    chmod +x "tools/zigcc"
  else
    cat << 'EOF_ZIGCC_SH' > "tools/zigcc"
#!/usr/bin/env bash
exec zig cc "$@"
EOF_ZIGCC_SH
    chmod +x "tools/zigcc"
  fi

  if [[ -f "${SCRIPT_DIR}/tools/zigcc.cmd" ]]; then
    cp "${SCRIPT_DIR}/tools/zigcc.cmd" "tools/zigcc.cmd"
  else
    cat << 'EOF_ZIGCC_CMD' > "tools/zigcc.cmd"
@echo off
zig cc %*
EOF_ZIGCC_CMD
  fi

  # 7. Generate config.nims with dynamic zigcc resolution and 6 build tasks
  cat << _CONFIG_NIMS_EOF_ > "config.nims"
# Strict build configuration and task orchestrator for ${project_name}

switch("outdir", "bin")

let zigccExe =
  if findExe("zigcc").len > 0:
    "zigcc"
  elif defined(windows):
    "tools/zigcc.cmd"
  else:
    "./tools/zigcc"

task nimRelease, "Build native host-optimized binary (aggressive speed, march=native)":
  ## Compiles high-performance binary optimized strictly for the current host CPU.
  selfExec "c -d:release -d:danger --opt:speed --passC:\"-march=native -mtune=native\" src/${project_name}.nim"

task nimPortable, "Build portable binary for generic CPUs (stripped, baseline instructions)":
  ## Compiles stripped, portable binary targeting generic CPU baseline compatibility.
  selfExec "c -d:release --opt:size --passC:\"-mtune=generic\" --passL:\"-s\" src/${project_name}.nim"

task nimDebug, "Build debug binary with stack traces and assertions":
  ## Compiles debug binary with full assertions, line tracing, and symbols.
  selfExec "c --debuginfo:on --assertions:on --lineTrace:on --stackTrace:on src/${project_name}.nim"

task zigRelease, "Build native host-optimized binary using Zig CC (O3, march=native)":
  ## Compiles native binary using Zig toolchain with -O3 optimization for host CPU.
  selfExec "c --cc:clang --clang.exe:\"" & zigccExe & "\" --clang.linkerexe:\"" & zigccExe & "\" --passC:\"-O3 -march=native\" src/${project_name}.nim"

task zigPortable, "Build portable binary for generic CPUs using Zig CC (stripped, baseline instructions)":
  ## Compiles stripped binary using Zig toolchain targeting generic baseline CPUs and size reduction.
  selfExec "c --cc:clang --clang.exe:\"" & zigccExe & "\" --clang.linkerexe:\"" & zigccExe & "\" -d:release --opt:size --passC:\"-Oz\" --passC:\"-mcpu=baseline\" --passL:\"-s\" src/${project_name}.nim"

task zigDebug, "Build debug binary using Zig CC with debug symbols":
  ## Compiles debug binary using Zig toolchain preserving debug symbols.
  selfExec "c --cc:clang --clang.exe:\"" & zigccExe & "\" --clang.linkerexe:\"" & zigccExe & "\" --debuginfo:on src/${project_name}.nim"

task test, "Run test suite":
  ## Executes unittest suite.
  selfExec "c -r --verbosity:0 tests/test_all.nim"

task fmt, "Format codebase via nimpretty":
  ## Formats source and test files in-place.
  selfExec "pretty --indent:2 src/${project_name}.nim"

task docs, "Generate HTML documentation":
  ## Emits HTML documentation into htmldocs directory.
  selfExec "doc --project --outdir:htmldocs src/${project_name}.nim"
_CONFIG_NIMS_EOF_

  # 8. Generate MCP Configuration
  cat << '_MCP_CONFIG_EOF_' > ".mcp/servers.json"
{
  "mcpServers": {
    "nimlangserver": {
      "command": "nimlangserver",
      "args": ["--mcp"]
    }
  }
}
_MCP_CONFIG_EOF_

  # 9. Setup Skills (.agents/skills/)
  local bundled_skills_dir="${SCRIPT_DIR}/skills"
  local user_skills_dir="${HOME}/.gemini/config/skills"

  if [[ "${import_skills}" =~ ^[Yy]$ ]]; then
    if [[ -d "${bundled_skills_dir}" ]]; then
      print_info "Copying bundled skills from template repository..."
      cp -r "${bundled_skills_dir}"/* ".agents/skills/" 2>/dev/null || true
    elif [[ -d "${user_skills_dir}" ]]; then
      print_info "Copying user skills from ${user_skills_dir} to .agents/skills/..."
      cp -r "${user_skills_dir}"/* ".agents/skills/" 2>/dev/null || true
    else
      print_info "Creating default baseline skills."
      mkdir -p ".agents/skills/build"
      cat << '_SKILL_BUILD_EOF_' > ".agents/skills/build/SKILL.md"
---
name: build
description: Compiles the project using one of the six standard configuration profiles.
---

# Build Profiles

Execute the target compilation mode using `nim <task_name>`:

1. `nim nimRelease`: Native host binary with `-d:release`, `-d:danger`, `--opt:speed`, `-march=native -mtune=native`.
2. `nim nimPortable`: Generic CPU binary with `-d:release`, `--opt:size`, `-mtune=generic`, `--passL:"-s"`.
3. `nim nimDebug`: Debug binary with `--debuginfo:on`, `--assertions:on`, `--lineTrace:on`, `--stackTrace:on`.
4. `nim zigRelease`: Clang/Zig CC release binary with `-O3 -march=native`.
5. `nim zigPortable`: Clang/Zig CC generic CPU binary with `-d:release`, `--opt:size`, `-Oz`, `-mcpu=baseline`, `-s`.
6. `nim zigDebug`: Clang/Zig CC debug binary with `--debuginfo:on`.

All compiled outputs are strictly emitted to `./bin/`.
_SKILL_BUILD_EOF_

      mkdir -p ".agents/skills/run-tests"
      cat << '_SKILL_TEST_EOF_' > ".agents/skills/run-tests/SKILL.md"
---
name: run-tests
description: Runs the project unit tests and validation suites.
---

# Running Tests

Execute the test suite via:
- `nim test` or `nim c -r tests/test_all.nim`
_SKILL_TEST_EOF_

      mkdir -p ".agents/skills/format-code"
      cat << '_SKILL_FMT_EOF_' > ".agents/skills/format-code/SKILL.md"
---
name: format-code
description: Formats Nim source files adhering to standard conventions.
---

# Code Formatting

Execute codebase formatting via:
- `nim fmt` or `nimpretty --indent:2 src/*.nim tests/*.nim`
_SKILL_FMT_EOF_

      mkdir -p ".agents/skills/docs-gen"
      cat << '_SKILL_DOCS_EOF_' > ".agents/skills/docs-gen/SKILL.md"
---
name: docs-gen
description: Generates HTML documentation from exported doc comments.
---

# Documentation Generation

Generate HTML documentation via:
- `nim docs` or `nim doc --project --outdir:htmldocs src/*.nim`
_SKILL_DOCS_EOF_
    fi
  fi

  # 10. GitHub Actions CI Workflow
  cat << '_CI_WORKFLOW_EOF_' > ".github/workflows/ci.yml"
name: CI

on:
  push:
    branches: [ main, master ]
  pull_request:
    branches: [ main, master ]

jobs:
  build-and-test:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4

      - name: Set up Nim
        uses: jiro4989/setup-nim-action@v2
        with:
          nim-version: 'stable'

      - name: Verify code formatting
        run: |
          nimpretty --check src/

      - name: Run test suite
        run: |
          nim test
_CI_WORKFLOW_EOF_

  # 11. Repository Infrastructure Files
  if [[ ! -f ".gitignore" ]]; then
    cat << '_GITIGNORE_EOF_' > ".gitignore"
# Nim compiler artifacts
nimcache/
bin/
htmldocs/
*.exe
*.out
*.o
*.a
*.so
*.dylib
*.dll

# Tooling and dependencies
.nimble-paths
deps/
.atlas/

# Editor and OS metadata
.vscode/
.idea/
*.swp
*~
.DS_Store
Thumbs.db
_GITIGNORE_EOF_
  fi

  # 12. Project README
  if [[ "${target_in_place}" != "true" || ! -f "README.md" ]]; then
    cat << _README_EOF_ > "README.md"
# ${project_name}

Nim project configured with standard compilation tasks, MCP support, and automated CI workflows.

## Directory Layout

- \`src/\`: Source code modules.
- \`tests/\`: Test suites.
- \`tools/\`: Build helper wrappers (\`tools/zigcc\` for Zig CC invocations).
- \`bin/\`: Compiled binary target directory.
- \`.mcp/\`: MCP server configuration.
- \`.agents/skills/\`: Local agent skill definitions.
- \`.github/workflows/\`: GitHub Actions CI pipeline.

## Build Tasks

Six optimized build modes are defined in \`config.nims\` and output to \`./bin/\`:

| Task | Toolchain | Profile Description | Key Flags |
|---|---|---|---|
| \`nim nimRelease\` | GCC/Default | Native Host Optimized | \`-d:release -d:danger --opt:speed -march=native\` |
| \`nim nimPortable\` | GCC/Default | Generic Portable Size | \`-d:release --opt:size -mtune=generic -s\` |
| \`nim nimDebug\` | GCC/Default | Full Debug & Diagnostics | \`--debuginfo:on --assertions:on --stackTrace:on\` |
| \`nim zigRelease\` | Zig CC | Native Host Optimized | \`-O3 -march=native\` |
| \`nim zigPortable\` | Zig CC | Generic Portable Size | \`-d:release --opt:size -Oz -mcpu=baseline -s\` |
| \`nim zigDebug\` | Zig CC | Full Debug & Diagnostics | \`--debuginfo:on\` |

## Development Commands

- Run test suite: \`nim test\`
- Format codebase: \`nim fmt\`
- Generate documentation: \`nim docs\`

## Acknowledgements & Attributions

- **[nimlangserver](https://github.com/nim-lang/langserver)**: Official Nim Language Server with MCP support.
- **[planetis-m/skills](https://github.com/planetis-m/skills)**: Curated agent skill repository for Nim development by [planetis-m](https://github.com/planetis-m).
- **[setup-nim-action](https://github.com/jiro4989/setup-nim-action)**: Nim GitHub Actions runner by [jiro4989](https://github.com/jiro4989).
_README_EOF_
  fi

  # 13. Final Summary
  print_header "Project Initialization Complete"
  echo "Project Location: ${target_dir}"
  echo "Module Name:      ${project_name}"
  echo ""
  echo "Next Steps:"
  if [[ "${target_in_place}" != "true" ]]; then
    echo "  1. cd ${project_name}"
    echo "  2. nim test"
    echo "  3. nim nimRelease"
  else
    echo "  1. nim test"
    echo "  2. nim nimRelease"
  fi
  echo "================================================================================"
}

main "$@"
