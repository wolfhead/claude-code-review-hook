#!/bin/bash

# Test script to demonstrate configuration display and API key masking

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to mask API key for display (show first 7 and last 3 characters)
mask_api_key() {
    local key="$1"
    if [ -z "$key" ]; then
        echo "(not set)"
        return
    fi
    local len=${#key}
    if [ $len -le 10 ]; then
        echo "***"
    else
        local prefix="${key:0:7}"
        local suffix="${key: -3}"
        echo "${prefix}***...***${suffix}"
    fi
}

echo -e "${BLUE}Testing API Key Masking:${NC}\n"

# Test cases
TEST_KEYS=(
    "sk-ant-demo-key-1234567890abcdefghijklmnopqrstuvwxyz"
    "sk_7Cyzd03nd79-dvuMcIGDN-Eudnp_KdwNbMYMnRzM6GE"
    "short"
    ""
)

for key in "${TEST_KEYS[@]}"; do
    if [ -z "$key" ]; then
        echo "Empty key: $(mask_api_key "$key")"
    else
        echo "Original: $key"
        echo "Masked:   $(mask_api_key "$key")"
        echo ""
    fi
done

echo -e "\n${BLUE}Example Configuration Display:${NC}"
echo -e "${BLUE}📝 Configuration from .claude-review.env:${NC}"
echo -e "   ${BLUE}🔑 API Key:${NC} $(mask_api_key 'sk_7Cyzd03nd79-dvuMcIGDN-Eudnp_KdwNbMYMnRzM6GE')"
echo -e "   ${BLUE}🌐 Base URL:${NC} https://api.jiekou.ai/anthropic"
echo -e "   ${BLUE}🤖 Model:${NC} claude-sonnet-4-5-20250929"
echo ""
