#!/bin/bash

# Installation script for Claude Code review hook
# Installs directly to .git/hooks (no Husky, no npm dependencies)
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
GIT_HOOK="$REPO_ROOT/.git/hooks/commit-msg"

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
        if command -v npm &> /dev/null; then
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
            echo -e "${RED}❌ npm not found${NC}"
            echo -e "${YELLOW}Please install Node.js and npm first, then run:${NC}"
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

# Install the hook
echo -e "${BLUE}📦 Installing commit-msg hook...${NC}"

# Create hooks directory if it doesn't exist
mkdir -p "$REPO_ROOT/.git/hooks"

# Check if hook already exists
if [ -f "$GIT_HOOK" ]; then
    echo -e "${YELLOW}⚠️  A commit-msg hook already exists${NC}"

    # Check if it's our hook
    if grep -q "Claude Code.*Review Hook" "$GIT_HOOK" 2>/dev/null; then
        if prompt_yes_no "${BLUE}Would you like to overwrite the existing Claude Code hook?${NC}"; then
            # Create backup
            BACKUP="$GIT_HOOK.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$GIT_HOOK" "$BACKUP"
            echo -e "${BLUE}Created backup:${NC} $BACKUP"
        else
            echo -e "${GREEN}Keeping existing hook. Installation cancelled.${NC}\n"
            exit 0
        fi
    else
        echo -e "${RED}The existing hook is not a Claude Code review hook.${NC}"
        if prompt_yes_no "${BLUE}Would you like to replace it? (A backup will be created)${NC}"; then
            # Create backup
            BACKUP="$GIT_HOOK.backup.$(date +%Y%m%d_%H%M%S)"
            cp "$GIT_HOOK" "$BACKUP"
            echo -e "${BLUE}Created backup:${NC} $BACKUP"
        else
            echo -e "${YELLOW}Installation cancelled to preserve existing hook.${NC}\n"
            exit 0
        fi
    fi
fi

# Copy the hook
cp "$HOOK_SOURCE" "$GIT_HOOK"
chmod +x "$GIT_HOOK"

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

echo -e "${GREEN}The hook has been installed to:${NC}"
echo -e "  $GIT_HOOK\n"

echo -e "${GREEN}Next steps:${NC}"
echo -e "1. Make some changes to your code"
echo -e "2. Stage them: ${BLUE}git add <files>${NC}"
echo -e "3. Commit: ${BLUE}git commit -m \"your message\"${NC}"
echo -e "4. Claude will automatically review your changes!\n"

echo -e "${YELLOW}Tip:${NC} To bypass the review when needed, use:"
echo -e "     ${BLUE}git commit --no-verify -m \"your message\"${NC}\n"

echo -e "${YELLOW}Note:${NC} This hook is installed locally in .git/hooks/"
echo -e "     Team members need to install it individually on their machines.\n"

echo -e "${GREEN}Happy coding! 🚀${NC}"
