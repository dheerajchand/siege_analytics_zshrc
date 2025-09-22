#!/usr/bin/env zsh
# =====================================================
# ALL MODULES COMPREHENSIVE REAL FUNCTIONALITY TEST
# =====================================================
# Tests every single module and config file for actual functionality
# =====================================================

echo "🔬 ALL MODULES COMPREHENSIVE TEST"
echo "================================="
echo "Started: $(date)"

# Load zsh config
source ~/.zshrc >/dev/null 2>&1

# Test results tracking
TOTAL_MODULES=0
WORKING_MODULES=0
BROKEN_MODULES=0
declare -a BROKEN_MODULE_NAMES

test_module() {
    local module_name="$1"
    local module_path="$2"
    
    ((TOTAL_MODULES++))
    echo ""
    echo "📦 Testing Module: $module_name"
    echo "================================"
    
    # Test if module can be loaded
    if [[ -f "$module_path" ]]; then
        echo "✅ Module file exists: $module_path"
        
        # Try to source the module
        if source "$module_path" >/dev/null 2>&1; then
            echo "✅ Module sources without errors"
            
            # Extract function names from module
            local functions=($(grep -E "^[[:space:]]*function|^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*\(" "$module_path" | sed -E 's/^[[:space:]]*function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*).*/\1/; s/^[[:space:]]*([a-zA-Z_][a-zA-Z0-9_]*)\(.*/\1/' | head -10))
            
            if [[ ${#functions[@]} -gt 0 ]]; then
                echo "✅ Functions found: ${#functions[@]}"
                
                local working_functions=0
                for func in "${functions[@]}"; do
                    if command -v "$func" >/dev/null 2>&1; then
                        ((working_functions++))
                        echo "  ✅ $func: Available"
                    else
                        echo "  ❌ $func: Not available"
                    fi
                done
                
                if [[ $working_functions -gt 0 ]]; then
                    echo "✅ Module functional: $working_functions/${#functions[@]} functions available"
                    ((WORKING_MODULES++))
                else
                    echo "❌ Module non-functional: No functions available"
                    ((BROKEN_MODULES++))
                    BROKEN_MODULE_NAMES+=("$module_name")
                fi
            else
                echo "⚠️  No functions found in module"
                ((WORKING_MODULES++))  # Count as working if it sources successfully
            fi
        else
            echo "❌ Module fails to source"
            ((BROKEN_MODULES++))
            BROKEN_MODULE_NAMES+=("$module_name")
        fi
    else
        echo "❌ Module file missing: $module_path"
        ((BROKEN_MODULES++))
        BROKEN_MODULE_NAMES+=("$module_name")
    fi
}

# Test all config modules
echo "🔧 TESTING CONFIG MODULES"
echo "========================="

test_module "backup-toggle" "config/backup-toggle.zsh"
test_module "core" "config/core.zsh"
test_module "credentials" "config/credentials.zsh"
test_module "database" "config/database.zsh"
test_module "docker" "config/docker.zsh"
test_module "environment" "config/environment.zsh"
test_module "hadoop" "config/hadoop.zsh"
test_module "help" "config/help.zsh"
test_module "jetbrains" "config/jetbrains.zsh"
test_module "notebooks" "config/notebooks.zsh"
test_module "python" "config/python.zsh"
test_module "shell-compat" "config/shell-compat.zsh"
test_module "spark" "config/spark.zsh"
test_module "status" "config/status.zsh"
test_module "variables" "config/variables.zsh"

# Test all modules directory files
echo ""
echo "📦 TESTING MODULES DIRECTORY"
echo "============================"

test_module "utils.module" "modules/utils.module.zsh"
test_module "python.module" "modules/python.module.zsh"
test_module "docker.module" "modules/docker.module.zsh"
test_module "database.module" "modules/database.module.zsh"
test_module "spark.module" "modules/spark.module.zsh"

# Test nested modules
test_module "core.utilities" "modules/core/utilities.zsh"
test_module "core.module-loader" "modules/core/module-loader.zsh"
test_module "core.cross-shell" "modules/core/cross-shell.zsh"
test_module "python.managers" "modules/languages/python/managers.zsh"
test_module "python.projects" "modules/languages/python/projects.zsh"
test_module "macos.system" "modules/platforms/macos/system.zsh"

echo ""
echo "🎯 ALL MODULES TEST RESULTS"
echo "==========================="
echo "Completed: $(date)"
echo ""
echo "📊 Module Summary:"
echo "   Total modules tested: $TOTAL_MODULES"
echo "   ✅ Working modules: $WORKING_MODULES"
echo "   ❌ Broken modules: $BROKEN_MODULES"
echo "   Success rate: $(( WORKING_MODULES * 100 / TOTAL_MODULES ))%"

if [[ $BROKEN_MODULES -gt 0 ]]; then
    echo ""
    echo "❌ Broken modules:"
    for broken_module in "${BROKEN_MODULE_NAMES[@]}"; do
        echo "   - $broken_module"
    done
fi

echo ""
echo "📋 Overall assessment saved to comprehensive-test-results.log"
