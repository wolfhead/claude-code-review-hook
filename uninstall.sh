#!/bin/bash

# Uninstallation script for Claude Code review hook
# Run this from your repository root

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Claude Code Review Hook Uninstaller      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    echo -e "Please run this from the root of your git repository"
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel)
GIT_HOOK="$REPO_ROOT/.git/hooks/commit-msg"

# Check if hook exists
if [ ! -f "$GIT_HOOK" ]; then
    echo -e "${YELLOW}⚠️  No commit-msg hook found${NC}"
    echo -e "The Claude Code review hook may not be installed."
    exit 0
fi

# Check if it's our hook
if ! grep -q "Claude Code.*Review Hook" "$GIT_HOOK" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  The existing commit-msg hook is not a Claude Code review hook${NC}"
    echo -e "The hook may have already been removed or was never installed."
    exit 0
fi

echo -e "${BLUE}Removing Claude Code review hook...${NC}\n"

# Create backup
BACKUP="$GIT_HOOK.backup.$(date +%Y%m%d_%H%M%S)"
cp "$GIT_HOOK" "$BACKUP"
echo -e "${BLUE}Created backup:${NC} $BACKUP"

# Remove the hook
rm "$GIT_HOOK"

echo -e "${GREEN}✅ Claude Code review hook removed successfully!${NC}\n"

# Ask about .claude-review.env
if [ -f "$REPO_ROOT/.claude-review.env" ]; then
    echo -e "${YELLOW}Found .claude-review.env configuration file${NC}"
    echo -e "${BLUE}Would you like to remove it as well? (y/n):${NC} "
    read -r response
    case "$response" in
        [Yy]* )
            rm "$REPO_ROOT/.claude-review.env"
            echo -e "${GREEN}✅ Removed .claude-review.env${NC}\n"
            ;;
        * )
            echo -e "${YELLOW}Keeping .claude-review.env${NC}\n"
            ;;
    esac
fi

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Uninstallation Complete!                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}The Claude Code review hook has been removed.${NC}"
echo -e "To reinstall the hook, run: ${BLUE}./install.sh${NC}\n"
