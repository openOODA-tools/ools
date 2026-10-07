# ools: Sovereign Directory Lister & Metadata Classifier

<div align="center">

```
             _      
  ___   ___ | |___  
 / _ \ / _ \| / __| 
| (_) | (_) | \__ \ 
 \___/ \___/|_|___/ 
```

**Sovereign Directory Lister and Metadata Classifier**  
*Two Faces, One Engine:* Modern terminal ergonomics for humans • Zero-leakage MCP for AI agents  
Written in 100% pure [openOODA](https://github.com/openOODA).

[![License: Apache-2.0](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![openOODA](https://img.shields.io/badge/openOODA-1.0-emerald.svg)](https://openooda.org)
[![Architecture: x86_64 | aarch64](https://img.shields.io/badge/Arch-x86__64%20%7C%20aarch64-lightgrey.svg)]()

</div>

---

## 1. Quick Install

### Automated Installer (Linux x86_64 & aarch64)
```bash
curl -fsSL https://openooda-tools.github.io/ools/install.sh | bash
```

### Native Package Managers
```bash
# Arch Linux (AUR)
yay -S ools-bin
# Or manual PKGBUILD:
cd packaging/arch && makepkg -si

# Debian / Ubuntu (.deb)
curl -fsSL https://openooda-tools.github.io/ools/install.sh | bash -s -- --deb

# Fedora / RHEL (.rpm)
curl -fsSL https://openooda-tools.github.io/ools/install.sh | bash -s -- --rpm
```

### Uninstallation
```bash
ools-uninstall
# or: curl -fsSL https://openooda-tools.github.io/ools/uninstall.sh | bash
```

---

## 2. CLI Usage

```
usage: ools [options] [FILE]...

List information about the FILEs (the current directory by default).
Sort entries alphabetically if neither -t nor -S is specified.

Options:
  -l                   use a long listing format with permissions and size
  -a, --all            do not ignore entries starting with .
  -A, --almost-all     do not list implied . and ..
  -h, --human-readable with -l, print sizes like 1K 234M 2G
  -F, --classify       append indicator (one of */=>@|) to entries
  -t                   sort by modification time, newest first
  -S                   sort by file size, largest first
  -r, --reverse        reverse order while sorting
  -R, --recursive      list subdirectories recursively
  -1                   list one file per line
  -d, --directory      list directories themselves, not their contents
      --color <WHEN>   colorize output: auto, always, never [default: auto]
      --theme <NAME>   override active oote palette
      --json           output entries formatted as JSON Lines
      --mcp            run as Model Context Protocol stdio server
  -h, --help           display this help and exit
  -v, --version        output version information and exit
```

### Common Examples

```bash
# Standard compact grid listing with file icons and oote colors
ools

# Detailed long listing with human-readable sizes
ools -lh

# List all hidden files, sorted by newest modification time
ools -la -t

# Recursive inspection of project structure
ools -R src/

# Pure single-column output for UNIX shell pipeline composition
ools -1 | oogrep "\.oo$"
```

---

## 3. Theming Integration (`oote`)

`ools` synchronizes visual styles, file type colors, and permissions formatting with [oote](https://github.com/openOODA-tools/oote):

* **Configuration:** Reads active palette from `~/.openooda/theme.oot`.
* **Environment Overrides:** Respects `$OODA_THEME` and `$NO_COLOR`.
* **File Classification:** Visual glyphs and distinct highlights for directories, executable binaries, symlinks, sockets, block devices, and archives.

---

## 4. Model Context Protocol (MCP)

When invoked with `--mcp`, `ools` runs a JSON-RPC 2.0 stdio server providing structured directory introspection for AI coding agents:

```bash
ools --mcp
```

### Supported MCP Tools

1. **`list_directory`**:
   Safely lists directory entries with structured JSON fields (`name`, `path`, `kind`, `size_bytes`, `permissions`, `modified_epoch`, `is_symlink`, `symlink_target`).
   * Parameters: `path`, `all`, `recursive`, `sort_by`, `reverse`, `detail_level`.
2. **`stat_entry`**:
   Fetches low-level inode metadata, mode bits, exact byte counts, and timestamps for any specific file node.
   * Parameters: `path`.

---

## 5. Security & Zero Ambient Authority

* **Pure Read-Only:** Operates strictly with `&FsReadCap` and `&EnvCap`. It physically lacks `&FsWriteCap` or `&NetCap` tokens, ensuring it can never mutate storage or leak data over networks.
* **Negative-Trust Traversal:** Recursive walks maintain loop-detection guards against circular symlink traps.
* **Hermetic Binary:** Statically linkable with zero runtime dependency on GNU coreutils or glibc dynamic shims.

---

## 6. License

Apache License, Version 2.0. See [LICENSE](LICENSE) for details.
