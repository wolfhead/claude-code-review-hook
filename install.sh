#!/bin/bash

# Installation script for Claude Code review hook
# Run this from your repository root
# Usage: ./install.sh [-y]
#   -y    Auto-confirm all prompts (non-interactive mode)

set -e

# Parse command line arguments
AUTO_YES=false
while getopts "y" opt; do
    case $opt in
        y)
            AUTO_YES=true
            ;;
        \?)
            echo "Usage: $0 [-y]"
            echo "  -y    Auto-confirm all prompts (non-interactive mode)"
            exit 1
            ;;
    esac
done

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Claude Code Review Hook Installer        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    echo -e "Please run this from the root of your git repository"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SOURCE="$SCRIPT_DIR/commit-msg"

# Check if source hook exists
if [ ! -f "$HOOK_SOURCE" ]; then
    echo -e "${RED}❌ Error: Hook script not found at $HOOK_SOURCE${NC}"
    echo -e "Please ensure commit-msg exists in the same directory as this script"
    exit 1
fi

# Function to prompt for yes/no
prompt_yes_no() {
    local prompt="$1"

    # Auto-yes mode
    if [ "$AUTO_YES" = true ]; then
        echo -e "${prompt} (y/n): y [auto]"
        return 0
    fi

    local response
    while true; do
        read -p "$(echo -e ${prompt}) (y/n): " response
        case "$response" in
            [Yy]* ) return 0;;
            [Nn]* ) return 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
}

# Check prerequisites
echo -e "${BLUE}🔍 Checking prerequisites...${NC}\n"

# Check Claude Code installation
CLAUDE_INSTALLED=false
if command -v claude &> /dev/null; then
    CLAUDE_VERSION=$(claude --version 2>&1 || echo "unknown")
    echo -e "${GREEN}✅ Claude Code is installed${NC} ($CLAUDE_VERSION)"
    CLAUDE_INSTALLED=true
else
    echo -e "${YELLOW}⚠️  Claude Code is not installed${NC}"
    if prompt_yes_no "${BLUE}Would you like to install Claude Code now?${NC}"; then
        echo -e "\n${BLUE}Installing Claude Code...${NC}"
        if npm install -g @anthropic/claude-code; then
            echo -e "${GREEN}✅ Claude Code installed successfully!${NC}\n"
            CLAUDE_INSTALLED=true
        else
            echo -e "${RED}❌ Failed to install Claude Code${NC}"
            echo -e "${YELLOW}Please install manually:${NC}"
            echo -e "  npm install -g @anthropic/claude-code"
            echo -e "  ${BLUE}Or visit: https://claude.com/code${NC}\n"
        fi
    else
        echo -e "${YELLOW}Skipping Claude Code installation${NC}"
        echo -e "${YELLOW}Install it later with:${NC}"
        echo -e "  npm install -g @anthropic/claude-code\n"
    fi
fi

# Authentication reminder
if [ "$CLAUDE_INSTALLED" = true ]; then
    echo -e "${BLUE}ℹ️  Make sure Claude Code is authenticated${NC}"
    echo -e "If not already done, run: ${BLUE}claude auth${NC}\n"
fi

# Check for package.json (needed for husky)
if [ ! -f "$REPO_ROOT/package.json" ]; then
    echo -e "${YELLOW}⚠️  No package.json found${NC}"
    echo -e "Initializing npm project..."
    cd "$REPO_ROOT"
    npm init -y

    # Fix the default failing test script
    if command -v node &> /dev/null; then
        node -e "const pkg = require('./package.json'); pkg.scripts.test = 'echo \"No tests - this is a tool project\"'; require('fs').writeFileSync('./package.json', JSON.stringify(pkg, null, 2) + '\n');"
    fi

    echo -e "${GREEN}✅ Created package.json${NC}\n"
fi

# Check husky installation
HUSKY_INSTALLED=false
if [ -d "$REPO_ROOT/node_modules/husky" ] || grep -q "\"husky\"" "$REPO_ROOT/package.json" 2>/dev/null; then
    echo -e "${GREEN}✅ Husky is installed${NC}"
    HUSKY_INSTALLED=true
else
    echo -e "${YELLOW}⚠️  Husky is not installed${NC}"
    if prompt_yes_no "${BLUE}Would you like to install Husky now?${NC}"; then
        echo -e "\n${BLUE}Installing Husky...${NC}"
        cd "$REPO_ROOT"
        if npm install --save-dev husky; then
            echo -e "${GREEN}✅ Husky installed successfully!${NC}\n"
            HUSKY_INSTALLED=true
        else
            echo -e "${RED}❌ Failed to install Husky${NC}"
            echo -e "${YELLOW}Please install manually: npm install --save-dev husky${NC}\n"
            exit 1
        fi
    else
        echo -e "${RED}❌ Husky is required for hook management${NC}"
        echo -e "${YELLOW}Install it manually with: npm install --save-dev husky${NC}\n"
        exit 1
    fi
fi

# Initialize husky if not already initialized
if [ ! -d "$REPO_ROOT/.husky" ]; then
    echo -e "${BLUE}Initializing Husky...${NC}"
    cd "$REPO_ROOT"
    npx husky init

    # Remove the default "npm test" line that husky init adds
    if [ -f "$REPO_ROOT/.husky/pre-commit" ]; then
        sed -i.bak '/^npm test$/d' "$REPO_ROOT/.husky/pre-commit"
        rm -f "$REPO_ROOT/.husky/pre-commit.bak"
    fi

    echo -e "${GREEN}✅ Husky initialized${NC}\n"
fi

# Install the hook via husky
echo -e "${BLUE}📦 Installing commit-msg hook...${NC}"

HUSKY_HOOK="$REPO_ROOT/.husky/commit-msg"

# Create or append to husky commit-msg hook
if [ ! -f "$HUSKY_HOOK" ]; then
    # Create new husky hook (modern format without deprecated husky.sh sourcing)
    cat > "$HUSKY_HOOK" << 'EOF'
#!/bin/sh

EOF
fi

# Check if our hook is already registered
if grep -q "Claude Code Review Hook" "$HUSKY_HOOK" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Claude Code review hook is already installed${NC}"
    if prompt_yes_no "${BLUE}Would you like to overwrite and reinstall it?${NC}"; then
        # Remove old hook section
        sed -i.bak '/# Claude Code Review Hook - START/,/# Claude Code Review Hook - END/d' "$HUSKY_HOOK"
        echo -e "${GREEN}Removing existing hook...${NC}"
    else
        echo -e "${GREEN}Keeping existing hook. Installation cancelled.${NC}\n"
        exit 0
    fi
fi

# Add our hook to husky (pass $1 for commit message file)
cat >> "$HUSKY_HOOK" << EOF

# Claude Code Review Hook - START
# Automatically reviews staged changes and commit message before finalizing commit
"$HOOK_SOURCE" "\$1"
# Claude Code Review Hook - END
EOF

chmod +x "$HUSKY_HOOK"

echo -e "${GREEN}✅ Hook installed successfully!${NC}\n"

# Check for CLAUDE.md
if [ -f "$REPO_ROOT/CLAUDE.md" ]; then
    echo -e "${GREEN}✅ CLAUDE.md found${NC} (project standards will be used)"
else
    echo -e "${YELLOW}ℹ️  No CLAUDE.md found${NC}"
    echo -e "Consider creating one to define project-specific review criteria\n"
fi

# Offer to create custom API configuration
if [ ! -f "$REPO_ROOT/.claude-review.env" ]; then
    if prompt_yes_no "${BLUE}Would you like to create a custom API configuration file (.claude-review.env)?${NC}"; then
        cat > "$REPO_ROOT/.claude-review.env" << 'EOF'
# Claude Code Review Hook Configuration
# This file allows you to use separate API settings for code reviews
# These are standard Claude Code environment variables

# API key (use ANTHROPIC_API_KEY or ANTHROPIC_AUTH_TOKEN depending on provider)
# export ANTHROPIC_API_KEY=sk-ant-...

# API endpoint (examples below)
# Anthropic official:
# export ANTHROPIC_BASE_URL=https://api.anthropic.com
# DeepSeek:
# export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic

# Model name (depends on your provider)
# export ANTHROPIC_MODEL=claude-sonnet-4-5-20250929

# Optional: Request timeout in milliseconds
# export API_TIMEOUT_MS=600000

# Optional: Disable non-essential traffic
# export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

EOF
        echo -e "${GREEN}✅ Created .claude-review.env template${NC}"
        echo -e "${YELLOW}Edit this file to configure custom API settings${NC}\n"

        # Add to .gitignore if not already there
        if [ -f "$REPO_ROOT/.gitignore" ]; then
            if ! grep -q ".claude-review.env" "$REPO_ROOT/.gitignore"; then
                echo ".claude-review.env" >> "$REPO_ROOT/.gitignore"
                echo -e "${GREEN}✅ Added .claude-review.env to .gitignore${NC}\n"
            fi
        else
            echo ".claude-review.env" > "$REPO_ROOT/.gitignore"
            echo -e "${GREEN}✅ Created .gitignore with .claude-review.env${NC}\n"
        fi
    else
        echo -e "${YELLOW}Skipping custom configuration. Hook will use default Claude Code settings.${NC}\n"
    fi
else
    echo -e "${GREEN}✅ .claude-review.env already exists${NC}\n"
fi

# Final instructions
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Installation Complete!                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}Next steps:${NC}"
echo -e "1. Make some changes to your code"
echo -e "2. Stage them: ${BLUE}git add <files>${NC}"
echo -e "3. Commit: ${BLUE}git commit -m \"your message\"${NC}"
echo -e "4. Claude will automatically review your changes!\n"

echo -e "${YELLOW}Tip:${NC} To bypass the review when needed, use:"
echo -e "     ${BLUE}git commit --no-verify -m \"your message\"${NC}\n"

echo -e "${GREEN}Happy coding! 🚀${NC}"
