#!/usr/bin/env zsh
# ============================================
# uv Manager Implementation
# ============================================

setup_uv() {
    export UV_PYTHON_PREFERENCE="managed"
    export UV_PYTHON_DOWNLOADS="automatic"
    export UV_COMPILE_BYTECODE=1
    export UV_LINK_MODE="copy"
    
    if command -v uv &>/dev/null; then
        export PYSPARK_PYTHON=$(uv run which python 2>/dev/null || which python3)
        export PYSPARK_DRIVER_PYTHON=$PYSPARK_PYTHON
        
        alias uvpy="uv python"
        alias uvrun="uv run"
        alias uvsync="uv sync"
        alias uvlock="uv lock"
        alias uvpip="uv pip"
        
        return 0
    else
        python_log WARN "uv not found"
        return 1
    fi
}

uv_init_project() {
    local python_version=${1:-3.11}
    
    uv init --python "$python_version"
    uv venv
    
    if [[ ! -f "pyproject.toml" ]]; then
        cat > pyproject.toml << TOML
[project]
name = "$(basename $PWD)"
version = "0.1.0"
requires-python = ">=${python_version}"
dependencies = []

[tool.uv]
dev-dependencies = ["pytest", "black", "ruff"]
TOML
    fi
}
