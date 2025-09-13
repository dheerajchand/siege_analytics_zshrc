#!/usr/bin/env zsh

# =====================================================
# HIERARCHICAL MODULE LOADER
# =====================================================
#
# Enhanced module loader that supports both flat and hierarchical module structures.
# Maintains backward compatibility with existing loading modes.
# =====================================================

# Enhanced function to load hierarchical modules
load_hierarchical_modules() {
    # Load modules from the new hierarchical structure
    # This function supplements the existing module loading system

    local modules_base="$HOME/.config/zsh/modules"

    # Core utilities (always loaded first)
    if [[ -f "$modules_base/core/utilities.zsh" ]]; then
        source "$modules_base/core/utilities.zsh"
        [[ -z "$POWERLEVEL9K_INSTANT_PROMPT" ]] && echo "  ✅ Core utilities loaded"
    fi

    # Load modules based on current ZSH_MODE
    case "$ZSH_MODE" in
        "light")
            # Light mode: Only essential functions
            [[ -z "$POWERLEVEL9K_INSTANT_PROMPT" ]] && echo "  ⚡ Loading light hierarchical modules..."
            ;;
        "heavy"|"staggered")
            # Heavy/Staggered mode: Load platform-specific modules
            if [[ "$OSTYPE" == "darwin"* ]]; then
                if [[ -f "$modules_base/platforms/macos/system.zsh" ]]; then
                    source "$modules_base/platforms/macos/system.zsh"
                    [[ -z "$POWERLEVEL9K_INSTANT_PROMPT" ]] && echo "  ✅ macOS system utilities loaded"
                fi
            fi

            # Load Python modules if in heavy mode or staggered phase 2
            if [[ "$ZSH_MODE" == "heavy" ]] || [[ -n "$ZSH_STAGGERED_PHASE_2" ]]; then
                if [[ -f "$modules_base/languages/python/managers.zsh" ]]; then
                    source "$modules_base/languages/python/managers.zsh"
                    [[ -z "$POWERLEVEL9K_INSTANT_PROMPT" ]] && echo "  ✅ Python managers loaded"
                fi

                if [[ -f "$modules_base/languages/python/projects.zsh" ]]; then
                    source "$modules_base/languages/python/projects.zsh"
                    [[ -z "$POWERLEVEL9K_INSTANT_PROMPT" ]] && echo "  ✅ Python projects loaded"
                fi
            fi
            ;;
    esac
}

# Function to load modules from a directory recursively
load_module_directory() {
    local dir="$1"
    local pattern="${2:-*.zsh}"

    if [[ -d "$dir" ]]; then
        find "$dir" -name "$pattern" -type f | sort | while read -r module_file; do
            if [[ -f "$module_file" ]]; then
                source "$module_file" 2>/dev/null || true
                local module_name=$(basename "$module_file" .zsh)
                [[ -z "$POWERLEVEL9K_INSTANT_PROMPT" ]] && echo "  ✅ ${module_name} loaded"
            fi
        done
    fi
}

# Module loader loaded indicator
export MODULE_LOADER_LOADED=true