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
HUSKY_HOOK="$REPO_ROOT/.husky/pre-commit"

# Check if husky hook exists
if [ ! -f "$HUSKY_HOOK" ]; then
    echo -e "${YELLOW}⚠️  No husky pre-commit hook found${NC}"
    echo -e "The Claude Code review hook may not be installed, or you're using a different hook system."
    exit 0
fi

# Check if our hook is registered
if ! grep -q "Claude Code Review Hook" "$HUSKY_HOOK" 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Claude Code review hook not found in husky pre-commit${NC}"
    echo -e "The hook may have already been removed or was never installed."
    exit 0
fi

echo -e "${BLUE}Removing Claude Code review hook...${NC}\n"

# Create backup
BACKUP="$HUSKY_HOOK.backup.$(date +%Y%m%d_%H%M%S)"
cp "$HUSKY_HOOK" "$BACKUP"
echo -e "${BLUE}Created backup:${NC} $BACKUP"

# Remove our hook section
sed -i.tmp '/# Claude Code Review Hook - START/,/# Claude Code Review Hook - END/d' "$HUSKY_HOOK"
rm -f "$HUSKY_HOOK.tmp"

echo -e "${GREEN}✅ Claude Code review hook removed successfully!${NC}\n"

# Check if the hook file only contains the husky header (empty hook)
REMAINING_LINES=$(grep -v "^#" "$HUSKY_HOOK" | grep -v "^$" | grep -v "^. " | wc -l | tr -d ' ')

if [ "$REMAINING_LINES" -eq 0 ]; then
    echo -e "${YELLOW}The pre-commit hook file is now empty (only husky header remains).${NC}"
    echo -e "${BLUE}Would you like to remove it? (y/n):${NC} "
    read -r response
    case "$response" in
        [Yy]* )
            rm "$HUSKY_HOOK"
            echo -e "${GREEN}✅ Removed empty pre-commit hook file${NC}\n"
            ;;
        * )
            echo -e "${YELLOW}Keeping empty pre-commit hook file${NC}\n"
            ;;
    esac
else
    echo -e "${GREEN}Other hooks remain in .husky/pre-commit${NC}\n"
fi

# Check for old-style .git/hooks installations (from previous versions)
OLD_HOOK="$REPO_ROOT/.git/hooks/pre-commit"
if [ -f "$OLD_HOOK" ]; then
    if grep -q "Claude Code Pre-commit Review Hook" "$OLD_HOOK" 2>/dev/null; then
        echo -e "${BLUE}Found old-style git hook installation${NC}"
        echo -e "${YELLOW}Would you like to remove it too? (y/n):${NC} "
        read -r response
        case "$response" in
            [Yy]* )
                # Look for backups
                BACKUPS=$(ls -1 "$REPO_ROOT/.git/hooks/pre-commit.backup."* 2>/dev/null || echo "")
                if [ -n "$BACKUPS" ]; then
                    echo -e "\n${BLUE}Found backup(s):${NC}"
                    ls -1 "$REPO_ROOT/.git/hooks/pre-commit.backup."*
                    echo -e "\n${YELLOW}Would you like to restore a backup? (y/n):${NC} "
                    read -r restore_response
                    case "$restore_response" in
                        [Yy]* )
                            # If only one backup, use it; otherwise let user choose
                            BACKUP_COUNT=$(echo "$BACKUPS" | wc -l | tr -d ' ')
                            if [ "$BACKUP_COUNT" -eq 1 ]; then
                                mv "$BACKUPS" "$OLD_HOOK"
                                echo -e "${GREEN}✅ Restored backup${NC}\n"
                            else
                                echo -e "${BLUE}Enter the full path of the backup to restore:${NC}"
                                read -r backup_path
                                if [ -f "$backup_path" ]; then
                                    mv "$backup_path" "$OLD_HOOK"
                                    echo -e "${GREEN}✅ Restored backup${NC}\n"
                                else
                                    echo -e "${RED}Backup file not found. Removing hook without restore.${NC}"
                                    rm "$OLD_HOOK"
                                fi
                            fi
                            ;;
                        * )
                            rm "$OLD_HOOK"
                            echo -e "${GREEN}✅ Removed old-style hook${NC}\n"
                            ;;
                    esac
                else
                    rm "$OLD_HOOK"
                    echo -e "${GREEN}✅ Removed old-style hook${NC}\n"
                fi
                ;;
            * )
                echo -e "${YELLOW}Keeping old-style git hook${NC}\n"
                ;;
        esac
    fi
fi

echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Uninstallation Complete!                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}\n"

echo -e "${GREEN}The Claude Code review hook has been removed.${NC}"
echo -e "${YELLOW}Note:${NC} Husky and Claude Code remain installed."
echo -e "To reinstall the hook, run: ${BLUE}./install.sh${NC}\n"
