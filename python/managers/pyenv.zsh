#!/usr/bin/env zsh
# ============================================
# pyenv Manager Implementation
# ============================================

setup_pyenv() {
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    
    if command -v pyenv &>/dev/null; then
        eval "$(pyenv init -)"
        
        if command -v pyenv-virtualenv &>/dev/null; then
            eval "$(pyenv virtualenv-init -)"
        fi
        
        # Auto-set default version if system is unavailable
        set_default_pyenv_version
        
        export PYSPARK_PYTHON=$(pyenv which python 2>/dev/null || which python3)
        export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON
        
        return 0
    else
        python_log WARN "pyenv not found"
        return 1
    fi
}

pyenv_install_latest() {
    local major=${1:-3}
    local latest=$(pyenv install --list | grep -E "^\s*${major}\.[0-9]+\.[0-9]+$" | tail -1 | xargs)
    
    if [[ -n "$latest" ]]; then
        pyenv install "$latest"
        pyenv global "$latest"
    fi
}
