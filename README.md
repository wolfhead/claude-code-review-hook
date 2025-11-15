# Claude Code Review Hook

Automated AI code review using Claude Code CLI that runs before every git commit via Husky.

## Quick Start

```bash
# Install the pre-commit hook
./install.sh
```

The installer will automatically:
- Prompt to install Claude Code if not found
- Prompt to install Husky if not found
- Set up the pre-commit hook via Husky
- Work alongside your existing hooks

## What It Does

- Automatically reviews all staged changes before commit
- Provides intelligent feedback with full codebase context
- Can block commits with critical issues
- Helps maintain code quality and catch bugs early
- Works alongside other pre-commit hooks via Husky

## Files

- **`pre-commit`** - The actual git hook script that reviews your code
- **`install.sh`** - Interactive installation script
- **`uninstall.sh`** - Uninstallation script to remove the hook

## Prerequisites

The installation script will help you install these if missing:
- **Claude Code**: `npm install -g @anthropic/claude-code`
- **Husky**: `npm install --save-dev husky` (for hook management)
- **Node.js/npm**: Required for the above packages

## Installation

```bash
# Run the installer (it will guide you through setup)
./install.sh
```

The installer will:
1. Check if you're in a git repository
2. Check for Claude Code and offer to install if missing
3. Check for Husky and offer to install if missing
4. Add the review hook to `.husky/pre-commit`
5. Verify authentication status

## Uninstallation

```bash
# Remove the Claude Code review hook
./uninstall.sh
```

The uninstaller will:
- Remove the hook from `.husky/pre-commit`
- Preserve other hooks you may have
- Optionally clean up empty hook files
- Keep backups for safety

## Usage

Once installed, the hook runs automatically on every commit:

```bash
# Normal commit (hook runs automatically)
git add .
git commit -m "feat: add new feature"

# Bypass hook when needed
git commit --no-verify -m "wip: work in progress"
```

## Sharing with Team

After committing these scripts to your repository, team members can install with:

```bash
git pull
./install.sh
```

## Why Husky?

We use [Husky](https://typicode.github.io/husky/) for hook management because:
- Multiple pre-commit hooks can coexist peacefully
- Hooks are committed to the repository
- Easy team-wide setup
- Industry standard for JavaScript/TypeScript projects
