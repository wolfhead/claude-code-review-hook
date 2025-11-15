# Claude Code Review Hook

Automated AI code review using Claude Code CLI that runs before every git commit via Husky.

## Quick Start

```bash
# 1. Clone or download this tool
git clone https://github.com/your-repo/claude-code-review-hook.git /path/to/claude-code-review-hook

# 2. Navigate to your project repository
cd /path/to/your/project

# 3. Run the installer from the tool directory
/path/to/claude-code-review-hook/install.sh
```

The installer will automatically:
- Prompt to install Claude Code if not found
- Prompt to install Husky if not found
- Set up the commit-msg hook in YOUR repository via Husky
- Work alongside your existing hooks

**Note**: This tool doesn't need to be in your project. It's a standalone tool that installs hooks into your target repository.

## What It Does

- Automatically reviews all staged changes **and commit message** before finalizing commit
- Verifies that commit message matches the actual code changes
- Provides intelligent feedback with full codebase context
- **Blocks commits** when critical security or quality issues are found
- Helps maintain code quality and catch bugs early
- Works alongside other hooks via Husky

### How Blocking Works

When the AI review detects critical issues (security vulnerabilities, serious bugs, etc.), it will:
1. Display the review with issues found
2. **Block the commit** (exit with error code)
3. Show message: "❌ COMMIT BLOCKED"

The review looks for the pattern "BLOCK COMMIT" in the AI's response to determine if the commit should be blocked. This works with various formats including markdown formatting.

### Commit Message Context

The hook runs during the `commit-msg` phase, which means it has access to your commit message and can:
- Verify that the commit message accurately describes the code changes
- Check if the scope matches (e.g., "refactor only" should have no behavior changes)
- Detect mismatches between intent and implementation (e.g., message says "fix bug" but code adds new feature)
- Provide more relevant feedback based on what you're trying to accomplish

The commit message you write (with `-m` or in your editor) is included in the review, giving Claude full context about both **what** changed (the code) and **why** it changed (your message).

## Files

- **`commit-msg`** - The actual git hook script that reviews your code and commit message
- **`install.sh`** - Interactive installation script
- **`uninstall.sh`** - Uninstallation script to remove the hook

## Prerequisites

The installation script will help you install these if missing:
- **Claude Code**: `npm install -g @anthropic/claude-code`
- **Husky**: `npm install --save-dev husky` (for hook management)
- **Node.js/npm**: Required for the above packages

## Installation

```bash
# Interactive installation (prompts for confirmations)
./install.sh

# Non-interactive installation (auto-confirms all prompts)
./install.sh -y
```

The installer will:
1. Check if you're in a git repository
2. Check for Claude Code and offer to install if missing
3. Check for Husky and offer to install if missing
4. Add the review hook to `.husky/commit-msg`
5. Verify authentication status

**Options:**
- `-y`: Non-interactive mode - automatically answers "yes" to all prompts (useful for CI/CD or scripts)

## Uninstallation

```bash
# Remove the Claude Code review hook
./uninstall.sh
```

The uninstaller will:
- Remove the hook from `.husky/commit-msg`
- Preserve other hooks you may have
- Optionally clean up empty hook files
- Keep backups for safety

## Configuration

### Custom API Settings

You can configure the review hook to use separate API settings (different from your global Claude Code configuration):

**Option 1: Using `.claude-review.env` file (Recommended)**

Create a `.claude-review.env` file in your repository root with standard Claude Code environment variables:

```bash
# API key (or ANTHROPIC_AUTH_TOKEN for some providers)
export ANTHROPIC_API_KEY=sk-ant-...

# Custom API endpoint (e.g., for proxy, custom deployment, DeepSeek)
export ANTHROPIC_BASE_URL=https://api.anthropic.com

# Custom model
export ANTHROPIC_MODEL=claude-sonnet-4

# Optional: Request timeout in milliseconds
export API_TIMEOUT_MS=600000

# Optional: Disable non-essential traffic
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1
```

**Note:** The installer can create a template for you. This file is automatically added to `.gitignore` for security.

**Configuration Display:**
When you commit, the hook will show which custom settings are being used:
```
📝 Configuration from .claude-review.env:
   🔑 API Key: sk_7Cyz***...***6GE
   🌐 Base URL: https://api.jiekou.ai/anthropic
   🤖 Model: claude-sonnet-4-5-20250929
   ⏱️  Timeout: 600000ms
   🚫 Disable non-essential traffic: enabled
```
*Note: API keys are masked for security (shows first 7 and last 3 characters only)*

**Option 2: Using environment variables**

Export the variables before committing:

```bash
export ANTHROPIC_API_KEY=sk-ant-...
export ANTHROPIC_BASE_URL=https://api.anthropic.com
export ANTHROPIC_MODEL=claude-sonnet-4

git commit -m "your message"
```

**Important:** The hook runs in a subprocess, so these environment variables only affect the review and won't leak into your main shell session.

### Why Separate Configuration?

- **Separate billing**: Use different API keys for reviews vs. development
- **Custom endpoints**: Route review requests through a proxy or different region
- **Model selection**: Use a specific model for code reviews (e.g., faster/cheaper model)
- **Team setup**: Different team members can use different settings without conflicts

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

You can share this tool with your team in two ways:

**Option 1: Each team member installs individually**
```bash
# Team members clone the tool
git clone https://github.com/your-repo/claude-code-review-hook.git ~/tools/claude-code-review-hook

# Then install it in their local copy of the project
cd /path/to/project
~/tools/claude-code-review-hook/install.sh
```

**Option 2: Add the tool as a git submodule to your project** (optional)
```bash
# Add as submodule in your project
git submodule add https://github.com/your-repo/claude-code-review-hook.git .tools/claude-code-review-hook

# Team members can then install with:
git submodule update --init
.tools/claude-code-review-hook/install.sh
```

## Technical Details

### How It Works

The hook runs during the `commit-msg` phase of the git commit process:
1. You write your commit message (with `-m` flag or in your editor)
2. Git calls the `commit-msg` hook, passing the commit message file path
3. The hook reads both the commit message and staged changes
4. Claude Code reviews both together, checking for consistency and issues
5. If approved, the commit proceeds; if blocked, the commit is aborted

The hook uses Claude Code CLI in headless mode with the following flags:
- `--print`: Non-interactive mode for automation
- `--strict-mcp-config`: Disables all MCP servers and tools to ensure maximum compatibility with proxy endpoints and custom API configurations

This minimal configuration prevents tool definitions from being sent to the API, ensuring the hook works reliably across different API endpoints, proxy configurations, and API versions.

## Troubleshooting

### Hook fails with no output

If you see the configuration but then the hook fails silently:

```
📝 Configuration from .claude-review.env:
   🔑 API Key: sk_7Cyz***...***6GE
   ...
husky - commit-msg script failed (code 1)
```

**Common causes:**

1. **Authentication Error**
   - Invalid API key in `.claude-review.env`
   - API key doesn't have access to the specified endpoint
   - Solution: Check your `ANTHROPIC_API_KEY` or run `claude auth`

2. **Network/Connection Error**
   - Can't reach the API endpoint
   - Custom `ANTHROPIC_BASE_URL` is incorrect
   - Solution: Check your internet connection and verify the base URL

3. **Model Error**
   - Invalid model name in `ANTHROPIC_MODEL`
   - Model not available at the endpoint
   - Solution: Check the model name (e.g., `claude-sonnet-4-5-20250929`)

4. **API Compatibility Error** (e.g., `tools.3.custom.input_examples: Extra inputs are not permitted`)
   - Your proxy/endpoint uses an older API version or doesn't support tool definitions
   - Solution: The hook now uses `--strict-mcp-config` by default to disable all MCP servers and tools
   - This prevents tool definitions from being sent to the API
   - If you still encounter this, verify your endpoint supports the Anthropic Messages API

The hook now displays detailed error messages and troubleshooting hints when failures occur.

### Bypass the hook temporarily

If you need to commit without running the review:
```bash
git commit --no-verify -m "your message"
```

## Why Husky?

We use [Husky](https://typicode.github.io/husky/) for hook management because:
- Multiple git hooks can coexist peacefully
- Hooks are committed to the repository
- Easy team-wide setup
- Industry standard for JavaScript/TypeScript projects
