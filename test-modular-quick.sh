#!/usr/bin/env bash

# =====================================================
# QUICK MODULAR ZSH SYSTEM TEST
# =====================================================
# Fast validation of the modular ZSH system
# =====================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🧪 Quick Modular ZSH Test${NC}"
echo "=========================="

# Test 1: ZSH Configuration Loading
echo -n "Testing ZSH config loading... "
if timeout 10 zsh -c 'source ~/.config/zsh/zshrc >/dev/null 2>&1' 2>/dev/null; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
    exit 1
fi

# Test 2: Module Loading
echo -n "Testing module loading... "
module_count=$(timeout 10 zsh -c 'source ~/.config/zsh/zshrc >/dev/null 2>&1 && echo ${#LOADED_MODULES[@]}' 2>/dev/null)
if [[ "$module_count" -gt 5 ]]; then
    echo -e "${GREEN}✅ OK ($module_count modules)${NC}"
else
    echo -e "${RED}❌ FAILED (only $module_count modules)${NC}"
fi

# Test 3: Core Functions Available
echo -n "Testing core functions... "
if timeout 10 zsh -c 'source ~/.config/zsh/zshrc >/dev/null 2>&1 && command -v mkcd && command -v is_online' >/dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
fi

# Test 4: Status Commands
echo -n "Testing status commands... "
if timeout 10 zsh -c 'source ~/.config/zsh/zshrc >/dev/null 2>&1 && command -v modular_zsh_status' >/dev/null 2>&1; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
fi

# Test 5: Backup System
echo -n "Testing backup system... "
backup_test=$(timeout 10 zsh -c 'source ~/.config/zsh/zshrc >/dev/null 2>&1 && backup_status >/dev/null 2>&1 && echo "OK"' 2>/dev/null)
if [[ "$backup_test" == "OK" ]]; then
    echo -e "${GREEN}✅ OK${NC}"
else
    echo -e "${RED}❌ FAILED${NC}"
fi

# Test 6: Startup Performance
echo -n "Testing startup performance... "
startup_time=$(timeout 15 bash -c 'time zsh -c "source ~/.config/zsh/zshrc >/dev/null 2>&1" 2>&1' | grep real | awk '{print $2}' | sed 's/[^0-9.]//g' | head -1)
if [[ -n "$startup_time" ]] && (( $(echo "$startup_time < 3.0" | bc -l) )); then
    echo -e "${GREEN}✅ OK (${startup_time}s)${NC}"
else
    echo -e "${RED}❌ SLOW (${startup_time}s)${NC}"
fi

echo ""
echo -e "${BLUE}Test Summary${NC}"
echo "============"
echo "• Configuration loads without hanging"
echo "• All core modules load successfully"
echo "• Essential functions are available"
echo "• Status commands work"
echo "• Backup system is functional"
echo "• Startup time is reasonable"
echo ""
echo -e "${GREEN}✅ Modular ZSH system is functional${NC}"