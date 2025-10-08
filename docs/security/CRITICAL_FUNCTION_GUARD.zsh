#!/usr/bin/env zsh
# =====================================================
# CRITICAL FUNCTION GUARD SYSTEM
# =====================================================
#
# Purpose: Prevent accidental deletion of critical functions
# Triggers: After every module load, before reporting success
# =====================================================

# Critical functions that must ALWAYS exist
CRITICAL_SPARK_FUNCTIONS=(
    "default_spark_submit"
    "distributed_spark_submit"
    "smart_spark_submit"
    "spark_yarn_submit"
    "heavy_api_submit"
    "get_spark_dependencies"
)

CRITICAL_PYTHON_FUNCTIONS=(
    "python_help"
    "pyhelp"
    "python_status"
)

# Function verification system
verify_critical_functions() {
    local module="$1"
    local missing_functions=()

    case "$module" in
        "spark")
            for func in "${CRITICAL_SPARK_FUNCTIONS[@]}"; do
                if ! declare -f "$func" >/dev/null 2>&1; then
                    missing_functions+=("$func")
                fi
            done
            ;;
        "python")
            for func in "${CRITICAL_PYTHON_FUNCTIONS[@]}"; do
                if ! declare -f "$func" >/dev/null 2>&1; then
                    missing_functions+=("$func")
                fi
            done
            ;;
    esac

    if [[ ${#missing_functions[@]} -gt 0 ]]; then
        echo "🚨 CRITICAL: Missing functions in $module module:"
        printf '   ❌ %s\n' "${missing_functions[@]}"
        echo ""
        echo "🔧 This indicates a regression. Check git history:"
        echo "   git log --oneline config/$module.zsh"
        return 1
    else
        echo "✅ $module: All critical functions verified"
        return 0
    fi
}

# Enhanced module loading with function verification
load_module_safe() {
    local module="$1"
    local module_path="$ZSH_CONFIG_DIR/modules/$module.module.zsh"

    if [[ -f "$module_path" ]]; then
        echo "📦 Loading $module module..."
        source "$module_path"

        # CRITICAL: Verify functions actually loaded
        if verify_critical_functions "$module"; then
            if [[ -z "$LOADED_MODULES" ]]; then
                export LOADED_MODULES="$module"
            else
                export LOADED_MODULES="$LOADED_MODULES $module"
            fi
        else
            echo "❌ FAILED: $module module did not load critical functions"
            echo "💡 Check: config/$module.zsh for missing function definitions"
            return 1
        fi
    else
        echo "❌ Module not found: $module"
        return 1
    fi
}

# Pre-commit hook to prevent function deletion
check_critical_functions_before_commit() {
    echo "🛡️  Pre-commit: Checking for critical function deletions..."

    # Check staged changes for function deletions
    local deleted_functions=$(git diff --cached | grep "^-.*_submit\|^-.*_help\|^-.*python.*(" | head -5)

    if [[ -n "$deleted_functions" ]]; then
        echo "🚨 WARNING: Critical functions being deleted in this commit:"
        echo "$deleted_functions"
        echo ""
        echo "❓ Are you sure you want to delete these functions? (y/N)"
        read -r confirm
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "❌ Commit aborted to protect critical functions"
            exit 1
        fi
    fi
}

export -f verify_critical_functions load_module_safe check_critical_functions_before_commit