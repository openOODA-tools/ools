# ools: House Laws & Agent Engineering Standards (v1)

This document is the **single canonical source of truth** for all code, architecture, and system integration standards across `ools`. Every human contributor and AI agent must strictly follow these rules without exception.

---

## 1. The Page Rule (Code Layout & Sizing)

A **page** is one committed `.oo` or `.oot` file. Every page holds one idea, fits in one head, and carries its own weight. This rule is enforced by automated verification under `make verify`: red pages fail the build.

### Hard Sizing Invariants
- **16–256 Lines**: Every committed source file must be between **16 and 256 lines**, counted as exact line breaks (blank lines and comments count).
- **Shim Exemption (Floor Only)**: A file is a shim when every non-comment line is an import or re-export (`import "..."`). Shims skip the 16-line floor. The **256-line ceiling still strictly applies**.
- **Directory Density ($\le 8$ files)**: At most **8 `.oo` files per directory**, tests included. Crowded directories must split into functional subdirectories grouped by domain.
- **Banned File Names (Name the function, not the drawer)**:
  `util.oo`, `utils.oo`, `helper.oo`, `helpers.oo`, `common.oo`, `misc.oo`, `shared.oo`, `base.oo`, `core.oo`.

### Splitting, Folding, and Naming
- **Over 256 lines**: Split along functional boundaries into a new subdirectory with an `anchor.oo` shim. One page = one verb or one wholly owned noun.
- **Under 16 lines (and not a shim)**: Fold into its closest sibling or caller. Never pad lines with artificial whitespace or comments to reach 16.
- **Action pages lead with a verb**: `walk_dir.oo`, `render_grid.oo`, `render_long.oo`, `sort_entries.oo`.
- **State pages name what they own**: `ls_opts.oo`, `dir_entry.oo`, `file_kind.oo`, `icon_map.oo`.
- **Boundary pages speak trust verbs**: `verify_path.oo`, `admit_entry.oo`, `enforce_scope.oo`.

---

## 2. The 4-Element Academy Header (Mandatory on Every Page)

Every committed `.oo` file must begin with the standard 4-element Academy docstring within its first 7 lines:

```oo
// # Component Name - Subtitle
//
// Logline: Single-sentence imperative summary of functional responsibility.
//
// Setup: Preconditions, wired capability tokens, imported contracts.
//
// Beats:
//   1. First sequential phase of execution.
//   2. Next phase.
//   3. Final phase / exit state.
```

- **ASD-STE100 Compliance**: Clear, concise English. No filler or ambiguous verbs.
- **Imports**: All imports must be relative string literals (e.g. `import "scan/walk_dir.oo";`). Never use `::` namespaces.

---

## 3. Capability Security & Negative-Trust Discipline

`ools` is a read-only directory introspection utility operating under the Object-Capability (OCap) security model:

### Capability Contracts
- **Zero Ambient Authority**: Access to directories and file status requires an explicit `&FsReadCap` token. Environment reads (`COLUMNS`, `OODA_THEME`, `NO_COLOR`) require `&EnvCap`.
- **Read-Only by Construction**: `ools` is architecturally forbidden from holding `&FsWriteCap` or `&NetCap`. It cannot create, mutate, or delete files, and cannot open network connections.
- **Subprocess Safety**: Never invoke `/bin/sh` or `/bin/ls`. All filesystem scanning must be native via capability-gated host syscalls.

### Negative-Trust Edge Falsification
Every release requires passing tests on the following boundary edge cases:
1. **Empty Directories**: Must handle 0-byte directory blocks with exit code 0.
2. **Broken / Dangling Symlinks**: Must render broken symlink target and indicator (`-> [broken]`), never crash with ENOENT.
3. **Circular Symlink Traversal**: Recursive scanning (`-R`) must maintain an inode-set to detect and abort symlink loops without stack overflow.
4. **Special UNIX Nodes**: Correct classification of FIFOs, domain sockets, character devices, block devices.
5. **Permission Denied**: Unreadable directories must emit a structured diagnostic to stderr and continue scanning other arguments, returning exit code 1.
6. **Non-UTF-8 Filenames**: Must safely escape non-printable byte sequences without panicking.
7. **Narrow Terminals**: If terminal width < 40 columns, automatically collapse multi-column grid into single-column stream.
8. **TTY Detection**: If stdout is not a TTY (piped to another tool), default to single-column output without ANSI color escapes unless `--color=always`.

---

## 4. Model Context Protocol (MCP) Surface

When invoked with `--mcp`, `ools` runs a JSON-RPC 2.0 stdio server implementing the following tools:

### Tool 1: `list_directory`
- **Description**: Safely lists contents of a directory with rich metadata, sorting, and capability filtering.
- **Arguments**:
  - `path` (string, optional, default: `.`): Directory path to inspect.
  - `all` (boolean, optional, default: `false`): Include hidden files (`.` prefixed).
  - `recursive` (boolean, optional, default: `false`): Recursively inspect subdirectories.
  - `sort_by` (string, enum: `["name", "size", "time", "extension"]`, default: `"name"`).
  - `reverse` (boolean, optional, default: `false`): Reverse sort order.
  - `detail_level` (string, enum: `["compact", "detailed", "json"]`, default: `"detailed"`).

### Tool 2: `stat_entry`
- **Description**: Inspects exact metadata for a specific filesystem node without ambient leakage.
- **Arguments**:
  - `path` (string, required): Path to the filesystem entry.
- **Returns**: Mode, permissions, owner, group, size_bytes, atime, mtime, file_kind, symlink_target.

---

## 5. Verification Commands

Before committing, run:
```bash
make verify    # Runs Page Rule, Academy header, and line-limit audits
make test      # Executes hermetic unit & negative-trust integration tests
```
EOF
