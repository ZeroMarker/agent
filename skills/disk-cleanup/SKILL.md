---
name: disk-cleanup
description: Clean disk space by removing system logs, temporary files, package manager caches, and old snap versions. Use when user asks to free disk space, clean up storage, remove caches, or when disk usage is high.
---

# Disk Cleanup

## Overview

Automated disk cleanup tool that identifies and removes unnecessary files to free storage space. Supports system logs, temporary files, package manager caches (apt, npm, cargo, uv), and old snap versions.

## Quick Start

Run the cleanup script to analyze and clean all categories:

```bash
scripts/cleanup.sh
```

Or clean specific categories:

```bash
scripts/cleanup.sh --logs        # System logs only
scripts/cleanup.sh --caches      # Package manager caches only
scripts/cleanup.sh --snaps       # Old snap versions only
scripts/cleanup.sh --temp        # Temporary files only
```

## Cleanup Categories

### 1. System Logs

- **Journal logs**: Keep last 7 days, remove older
- **btmp files**: Failed login records (can be large)
- **Auth logs**: Compressed old auth logs

### 2. Temporary Files

- `/tmp/*`: User temporary files
- `/var/tmp/*`: System temporary files

### 3. Package Manager Caches

- **apt**: `/var/cache/apt` (package archives)
- **npm**: `~/.npm` (JavaScript packages)
- **cargo**: `~/.cargo/registry/src` (Rust source code)
- **uv**: `~/.local/share/uv` (Python packages)

### 4. Snap Packages

- Old revisions of snap packages
- Disabled snap versions

## Usage Examples

### Example 1: Full cleanup

```bash
scripts/cleanup.sh
```

### Example 2: Check before cleaning

```bash
scripts/cleanup.sh --dry-run
```

### Example 3: Clean only large caches

```bash
scripts/cleanup.sh --caches --min-size 100M
```

## Resources

### scripts/

- `cleanup.sh`: Main cleanup script with options for selective cleaning
