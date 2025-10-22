#!/usr/bin/env zsh
# =================================================================
# PYTHON - Python Environment Management
# =================================================================
# Pyenv setup, environment switching, project initialization
# =================================================================

# Default environment to auto-activate
export DEFAULT_PYENV_VENV="geo31111"

# Initialize pyenv if available
if command -v pyenv >/dev/null 2>&1; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    
    # Initialize pyenv
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
    
    # Initialize virtualenv plugin if available
    if command -v pyenv-virtualenv-init >/dev/null 2>&1; then
        eval "$(pyenv virtualenv-init -)"
    fi
    
    # Auto-activate default environment
    if [[ -n "$DEFAULT_PYENV_VENV" ]] && pyenv versions --bare | grep -q "^${DEFAULT_PYENV_VENV}$"; then
        pyenv activate "$DEFAULT_PYENV_VENV" 2>/dev/null || pyenv shell "$DEFAULT_PYENV_VENV" 2>/dev/null
    fi
fi

# Switch Python environments
py_env_switch() {
    local env_name="${1:-list}"
    
    if [[ "$env_name" == "list" ]]; then
        echo "📋 Available Python environments:"
        pyenv versions
        echo ""
        echo "Current: $(pyenv version-name 2>/dev/null || echo 'system')"
        return 0
    fi
    
    if pyenv versions --bare | grep -q "^${env_name}$"; then
        pyenv activate "$env_name" 2>/dev/null || pyenv shell "$env_name" 2>/dev/null
        echo "✅ Activated: $env_name"
        python --version
    else
        echo "❌ Environment not found: $env_name"
        echo "Available:"
        pyenv versions --bare
        return 1
    fi
}

# Get current Python executable path (for external tools)
get_python_path() {
    # Returns the actual Python binary path, not shim
    if command -v pyenv >/dev/null 2>&1; then
        # Use pyenv's Python
        echo "$(pyenv which python 2>/dev/null || which python)"
    else
        which python
    fi
}

# Get current Python version (major.minor)
get_python_version() {
    python -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')"
}

# Show Python environment status
python_status() {
    echo "🐍 Python Environment"
    echo "===================="
    echo "Manager: pyenv"
    echo "Active: $(pyenv version-name 2>/dev/null || echo 'system')"
    echo "Python: $(python --version 2>&1)"
    echo "Version: $(get_python_version)"
    echo "Location: $(which python)"
    echo "Actual Binary: $(get_python_path)"
    
    if command -v uv >/dev/null 2>&1; then
        echo "UV: $(uv --version 2>&1 | head -1)"
    fi
}

# Run command with current Python (for Spark, Jupyter, etc.)
with_python() {
    local cmd="$1"
    shift
    
    # Set Python env vars for the command
    PYSPARK_PYTHON="$(get_python_path)" \
    PYSPARK_DRIVER_PYTHON="$(get_python_path)" \
    JUPYTER_PYTHON="$(get_python_path)" \
    "$cmd" "$@"
}

# Switch to UV for project-based management
use_uv() {
    if command -v uv >/dev/null 2>&1; then
        echo "✅ Using UV for project management"
        echo "💡 Run: uv init <project> to create new project"
    else
        echo "❌ UV not installed"
        echo "Install: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
}

# Initialize data science project structure
ds_project_init() {
    local project_name="${1:-}"
    local use_spark="${2:-}"
    
    if [[ -z "$project_name" ]]; then
        echo "Usage: ds_project_init <project_name> [spark]"
        return 1
    fi
    
    echo "📦 Creating data science project: $project_name"
    
    mkdir -p "$project_name"/{data,notebooks,src,tests,output}
    cd "$project_name"
    
    # Create basic structure
    touch src/__init__.py
    touch tests/__init__.py
    touch README.md
    
    # Create requirements.txt
    cat > requirements.txt << 'EOF'
pandas
numpy
matplotlib
seaborn
jupyter
EOF
    
    # Add Spark dependencies if requested
    if [[ "$use_spark" == "spark" ]]; then
        echo "pyspark" >> requirements.txt
    fi
    
    echo "✅ Project structure created"
    echo "💡 Next steps:"
    echo "   cd $project_name"
    echo "   uv init  # or python -m venv .venv"
    echo "   pip install -r requirements.txt"
}

# Aliases
alias py='python'
alias py3='python3'
alias ipy='ipython'
alias jn='jupyter notebook'

echo "✅ python loaded ($(pyenv version-name 2>/dev/null || echo 'system'))"



