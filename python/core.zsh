#!/usr/bin/env zsh
# ============================================
# Core Python Management Functions
# ============================================

# Core logging function
python_log() {
    local level=$1
    shift
    local message="$@"
    
    case $level in
        ERROR)   echo "❌ [Python] $message" >&2 ;;
        WARN)    echo "⚠️  [Python] $message" >&2 ;;
        INFO)    echo "ℹ️  [Python] $message" ;;
        DEBUG)   [[ $PYTHON_DEBUG -eq 1 ]] && echo "🔍 [Python] $message" ;;
        SUCCESS) echo "✅ [Python] $message" ;;
    esac
}

# Initialize Python manager
init_python_manager() {
    local manager=${1:-$PYTHON_MANAGER}
    
    python_log DEBUG "Initializing $manager..."
    
    local manager_module="$PYTHON_ZSH_HOME/managers/${manager}.zsh"
    if [[ -f "$manager_module" ]]; then
        source "$manager_module"
        
        if type "setup_${manager}" > /dev/null; then
            "setup_${manager}"
            export PYTHON_MANAGER="$manager"
            echo "$PYTHON_MANAGER" > "$PYTHON_MANAGER_STATE_FILE"
            return 0
        fi
    fi
    return 1
}

# Switch managers
switch_python_manager() {
    local target=$1
    
    if [[ -z "$target" ]]; then
        echo "Usage: switch_python_manager [pyenv|uv]"
        echo "Current: $PYTHON_MANAGER"
        return 1
    fi
    
    cleanup_python_env
    
    if init_python_manager "$target"; then
        python_log SUCCESS "Switched to $target"
        echo "Reload shell: exec zsh"
    else
        python_log ERROR "Failed to switch"
        return 1
    fi
}

# Clean environment
cleanup_python_env() {
    unset PYENV_ROOT PYENV_SHELL PYENV_VERSION
    unset UV_HOME UV_PYTHON_PREFERENCE
    unset PYSPARK_PYTHON PYSPARK_DRIVER_PYTHON
    
    local aliases=(uvpy uvrun uvsync uvlock uvpip)
    for alias in $aliases; do
        unalias $alias 2>/dev/null
    done
}

# Get Python version
get_current_python_version() {
    case "$PYTHON_MANAGER" in
        pyenv)
            local version_name=$(pyenv version-name 2>/dev/null)
            if [[ "$version_name" == "system" ]]; then
                # Try to get system python version, fallback to available versions
                if command -v python3 &>/dev/null; then
                    python3 --version 2>&1 | cut -d' ' -f2 2>/dev/null || echo "system (unavailable)"
                elif command -v python &>/dev/null; then
                    python --version 2>&1 | cut -d' ' -f2 2>/dev/null || echo "system (unavailable)"
                else
                    echo "system (unavailable)"
                fi
            else
                echo "${version_name:-none}"
            fi
            ;;
        uv)
            uv run python --version 2>&1 | cut -d' ' -f2 2>/dev/null || echo "none"
            ;;
        *)
            if command -v python3 &>/dev/null; then
                python3 --version 2>&1 | cut -d' ' -f2 2>/dev/null || echo "none"
            elif command -v python &>/dev/null; then
                python --version 2>&1 | cut -d' ' -f2 2>/dev/null || echo "none"
            else
                echo "none"
            fi
            ;;
    esac
}

# Create virtual environment
create_venv() {
    local name=${1:-.venv}
    local python_version=$2
    
    case "$PYTHON_MANAGER" in
        pyenv)
            if [[ -n "$python_version" ]]; then
                PYENV_VERSION="$python_version" python -m venv "$name"
            else
                python -m venv "$name"
            fi
            ;;
        uv)
            if [[ -n "$python_version" ]]; then
                uv venv --python "$python_version" "$name"
            else
                uv venv "$name"
            fi
            ;;
    esac
}

# Auto-activate venv
auto_activate_venv() {
    local venv_dirs=(.venv venv env)
    
    for venv in $venv_dirs; do
        if [[ -d "$venv" ]] && [[ -f "$venv/bin/activate" ]]; then
            if [[ "$VIRTUAL_ENV" != "$PWD/$venv" ]]; then
                source "$venv/bin/activate"
                return 0
            fi
        fi
    done
    
    if [[ -n "$VIRTUAL_ENV" ]] && [[ ! "$PWD" =~ "$(dirname $VIRTUAL_ENV)" ]]; then
        deactivate 2>/dev/null
    fi
}

# Select pyenv version interactively
select_pyenv_version() {
    if [[ "$PYTHON_MANAGER" != "pyenv" ]]; then
        python_log ERROR "This function requires pyenv manager"
        return 1
    fi
    
    if ! command -v pyenv &>/dev/null; then
        python_log ERROR "pyenv not installed"
        return 1
    fi
    
    local versions=($(pyenv versions --bare | grep -v '/' | sort -V))
    
    if [[ ${#versions[@]} -eq 0 ]]; then
        python_log ERROR "No Python versions installed"
        echo "Install a version with: pyenv install <version>"
        return 1
    fi
    
    echo "🐍 Available Python versions:"
    echo "============================="
    
    local current=$(pyenv version-name 2>/dev/null)
    for i in {1..${#versions[@]}}; do
        local marker=""
        [[ "${versions[$i]}" == "$current" ]] && marker=" (current)"
        echo "  $i) ${versions[$i]}$marker"
    done
    
    echo ""
    echo -n "Select version (1-${#versions[@]}) or 'q' to quit: "
    read selection
    
    if [[ "$selection" == "q" ]]; then
        echo "Cancelled"
        return 0
    fi
    
    if [[ "$selection" =~ '^[0-9]+$' ]] && [[ $selection -ge 1 ]] && [[ $selection -le ${#versions[@]} ]]; then
        local selected_version=${versions[$selection]}
        echo ""
        echo "Setting global Python version to: $selected_version"
        
        if pyenv global "$selected_version"; then
            python_log SUCCESS "Global version set to $selected_version"
            echo "New version: $(get_current_python_version)"
        else
            python_log ERROR "Failed to set global version"
            return 1
        fi
    else
        python_log ERROR "Invalid selection: $selection"
        return 1
    fi
}

# Set preferred pyenv default environment
set_pyenv_default() {
    local env_name="$1"
    
    if [[ "$PYTHON_MANAGER" != "pyenv" ]]; then
        python_log ERROR "This function is for pyenv manager only"
        return 1
    fi
    
    if [[ -z "$env_name" ]]; then
        echo "Usage: set_pyenv_default <environment_name>"
        echo "Current pyenv default: ${PYENV_DEFAULT_ENV:-none}"
        if command -v pyenv &>/dev/null; then
            echo ""
            echo "Available environments:"
            pyenv versions --bare | sed 's/^/  /'
        fi
        return 1
    fi
    
    if ! command -v pyenv &>/dev/null; then
        python_log ERROR "pyenv not installed"
        return 1
    fi
    
    # Verify the environment exists
    if ! pyenv versions --bare | grep -q "^${env_name}$"; then
        python_log ERROR "Environment '$env_name' not found in pyenv"
        echo "Available environments:"
        pyenv versions --bare | sed 's/^/  /'
        return 1
    fi
    
    # Store the preference
    export PYENV_DEFAULT_ENV="$env_name"
    echo "PYENV_DEFAULT_ENV='$env_name'" > "$HOME/.config/pyenv_default_env"
    
    python_log SUCCESS "Pyenv default environment set to: $env_name"
    
    # Apply it immediately
    if pyenv global "$env_name"; then
        python_log SUCCESS "Switched to default environment: $env_name"
    else
        python_log ERROR "Failed to switch to $env_name"
        return 1
    fi
}

# Auto-set default pyenv version (respects PYENV_DEFAULT_ENV)
set_default_pyenv_version() {
    if [[ "$PYTHON_MANAGER" != "pyenv" ]]; then
        return 0
    fi
    
    if ! command -v pyenv &>/dev/null; then
        return 0
    fi
    
    local current=$(pyenv version-name 2>/dev/null)
    
    # If system is set but unavailable, or no version is set, pick a default
    if [[ "$current" == "system" ]] && ! command -v python &>/dev/null && ! command -v python3 &>/dev/null; then
        local versions=($(pyenv versions --bare | sort -V))
        local preferred_version=""
        
        # First priority: Check for user-defined pyenv default environment
        if [[ -n "$PYENV_DEFAULT_ENV" ]]; then
            for version in "${versions[@]}"; do
                if [[ "$version" == "$PYENV_DEFAULT_ENV" ]]; then
                    preferred_version="$version"
                    python_log INFO "Using configured pyenv default: $preferred_version"
                    break
                fi
            done
        fi
        
        # Second priority: Look for 'geo' environments (current preference pattern)
        if [[ -z "$preferred_version" ]]; then
            for version in "${versions[@]}"; do
                if [[ "$version" =~ geo ]]; then
                    preferred_version="$version"
                    python_log INFO "Using geo environment: $preferred_version"
                    break
                fi
            done
        fi
        
        # Third priority: Prefer Python 3.11+ base versions
        if [[ -z "$preferred_version" ]]; then
            local base_versions=($(pyenv versions --bare | grep -v '/' | sort -V))
            for version in "${base_versions[@]}"; do
                if [[ "$version" =~ ^3\.(1[1-9]|[2-9][0-9])\. ]]; then
                    preferred_version="$version"
                    python_log INFO "Using latest compatible version: $preferred_version"
                    break
                fi
            done
        fi
        
        # Last resort: Use the latest available version
        if [[ -z "$preferred_version" ]] && [[ ${#versions[@]} -gt 0 ]]; then
            preferred_version="${versions[-1]}"
            python_log INFO "Using latest available version: $preferred_version"
        fi
        
        # Apply the selected version
        if [[ -n "$preferred_version" ]]; then
            pyenv global "$preferred_version" >/dev/null 2>&1
        fi
    fi
}

# Status
python_status() {
    echo "╔════════════════════════════════════════╗"
    echo "║        Python Environment Status        ║"
    echo "╚════════════════════════════════════════╝"
    echo ""
    echo "Manager:  $PYTHON_MANAGER"
    echo "Python:   $(get_current_python_version)"
    echo "Venv:     ${VIRTUAL_ENV:-none}"
    echo "Config:   $PYTHON_ZSH_HOME"
    
    if [[ "$PYTHON_MANAGER" == "pyenv" ]] && command -v pyenv &>/dev/null; then
        local versions_count=$(pyenv versions --bare | grep -v '/' | wc -l | tr -d ' ')
        echo "Pyenv:    $versions_count version(s) installed"
    fi
}

# Help
pyhelp() {
    echo "Python Environment Commands"
    echo "=========================="
    echo ""
    echo "Manager:"
    echo "  use_pyenv       Switch to pyenv"
    echo "  use_uv          Switch to uv"
    echo "  pystatus        Show status"
    echo "  pyhealth        Health check"
    echo ""
    echo "Pyenv Management:"
    echo "  pyselect        Select global Python version interactively"
    echo "  pydefault       Set preferred default environment"
    echo ""
    echo "Projects:"
    echo "  pyproject       Create project"
    echo "  pyvenv          Create venv"
    echo "  activate        Activate venv"
    echo ""
    echo "Notebooks:"
    echo "  pynb            Start Jupyter"
    echo "  pyds            Setup DataSpell"
    echo ""
    echo "Spark:"
    echo "  pyspark-init    Create Spark project"
}

# Aliases
alias use_pyenv="switch_python_manager pyenv"
alias use_uv="switch_python_manager uv"
alias pystatus="python_status"
alias pyvenv="create_venv"
alias activate="source .venv/bin/activate 2>/dev/null || source venv/bin/activate 2>/dev/null"

# Pyenv-specific aliases
alias pyselect="select_pyenv_version"
alias pydefault="set_pyenv_default"

# Hooks
if [[ -n "$ZSH_VERSION" ]]; then
    autoload -U add-zsh-hook
    add-zsh-hook chpwd auto_activate_venv
fi

# ==== COMPREHENSIVE PYTHON HELP SYSTEM ====

python_help() {
    echo "🐍 Advanced Python Development Environment"
    echo "=========================================="
    echo ""
    echo "🎯 System Status: Python ZSH v${PYTHON_ZSH_VERSION:-unknown}"
    echo "📋 Active Manager: ${PYTHON_MANAGER:-not set}"
    echo ""

    echo "🚀 Core Commands:"
    echo "   python_status    - Detailed environment status with virtualenv info"
    echo "   python_help      - This comprehensive guide"
    echo "   pyhelp           - Quick reference"
    echo "   setup_pyenv      - Initialize pyenv for session"
    echo "   setup_uv         - Initialize uv for session"
    echo ""

    echo "🔧 Advanced Features:"
    if declare -f switch_python_manager >/dev/null 2>&1; then
        echo "   switch_python_manager - Switch between pyenv/uv"
    fi
    if declare -f auto_activate_venv >/dev/null 2>&1; then
        echo "   auto_activate_venv   - Smart project environment detection"
    fi
    if declare -f python_benchmark >/dev/null 2>&1; then
        echo "   python_benchmark     - Performance testing utilities"
    fi
    if declare -f python_health_check >/dev/null 2>&1; then
        echo "   python_health_check  - System diagnostics"
    fi
    echo ""

    echo "🐍 Pyenv Workflow:"
    echo "   # Environment Management"
    echo "   pyenv virtualenv 3.11.11 myproject    - Create virtualenv"
    echo "   pyenv activate myproject               - Activate virtualenv"
    echo "   pyenv deactivate                       - Deactivate"
    echo "   pyenv global geo31111                  - Set as global default"
    echo "   pyenv local geo31111                   - Set for current project"
    echo ""
    echo "   # Quick Reference"
    echo "   pyenv versions                         - List all environments"
    echo "   pyenv virtualenvs                      - List all virtualenvs"
    echo "   pyenv version                          - Show current + source"
    echo ""

    echo "📦 UV Integration:"
    echo "   uv init --python 3.12                 - Create UV project"
    echo "   uv add requests pandas                 - Add packages"
    echo "   uv run python script.py               - Run in project env"
    echo "   uv sync                                - Install dependencies"
    echo ""

    echo "🚀 Big Data Integration:"
    echo "   load_big_data                          - Spark/Hadoop stack"
    echo "   # Then use existing Spark functions"
    echo ""

    echo "💡 Advanced Tips:"
    echo "   • python_status shows current virtualenv details"
    echo "   • .python-version files auto-activate environments"
    echo "   • Global default: pyenv global <env>"
    echo "   • Project default: pyenv local <env>"
    echo "   • Quick switch: pyenv shell <env>"
    echo ""

    echo "📊 Current Environment:"
    if command -v pyenv >/dev/null 2>&1; then
        local current_version=$(pyenv version 2>/dev/null)
        echo "   🎯 Active: $current_version"
        if [[ "$current_version" == *"/envs/"* ]]; then
            local venv_name=$(echo "$current_version" | sed 's/.*\/envs\/\([^[:space:]]*\).*/\1/')
            echo "   🌍 Virtualenv: $venv_name"
        fi
    fi
}

# Enhanced quick help for advanced system
pyhelp() {
    echo "🐍 Advanced Python Environment"
    echo "=============================="
    echo ""
    echo "🔧 Core:       setup_pyenv | setup_uv | python_status"
    echo "🚀 Big Data:   load_big_data"
    echo "📖 Full Help:  python_help"
    echo ""
    echo "📋 Current Environment:"
    echo "   Manager: ${PYTHON_MANAGER:-not set}"
    echo "   Active: ${PYTHON_ACTIVE:-none}"

    if command -v pyenv >/dev/null 2>&1; then
        local pyenv_info=$(pyenv version 2>/dev/null)
        if [[ "$pyenv_info" == *"/envs/"* ]]; then
            local venv_name=$(echo "$pyenv_info" | sed 's/.*\/envs\/\([^[:space:]]*\).*/\1/')
            echo "   Virtualenv: ✅ $venv_name"
        else
            echo "   Virtualenv: None"
        fi
    fi

    echo ""
    echo "💡 System: Advanced Python ZSH v${PYTHON_ZSH_VERSION:-unknown}"
}

# ==== LAZY LOADING SYSTEM ====

# Lazy load notebooks integration
jupyter_spark() {
    load_python_module "integrations/notebooks.zsh" 0
    command jupyter_spark "$@"
}

# Lazy load Spark integration
spark_python() {
    load_python_module "integrations/spark.zsh" 0
    command spark_python "$@"
}

# Lazy load benchmarks
python_benchmark() {
    load_python_module "utils/benchmarks.zsh" 0
    command python_benchmark "$@"
}

# Lazy load health checks
python_health_check() {
    load_python_module "utils/health.zsh" 0
    command python_health_check "$@"
}
