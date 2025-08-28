#!/usr/bin/env zsh
# ============================================
# Python Manager Benchmarks
# ============================================

benchmark_managers() {
    local packages="pandas numpy scikit-learn"
    
    echo "📊 Benchmarking Python Managers"
    echo "================================"
    echo "Packages: $packages"
    echo ""
    
    # Test directories
    local pyenv_dir="/tmp/bench_pyenv_$$"
    local uv_dir="/tmp/bench_uv_$$"
    
    # Benchmark pyenv
    if command -v pyenv &>/dev/null; then
        mkdir -p "$pyenv_dir" && cd "$pyenv_dir"
        python -m venv .venv
        source .venv/bin/activate
        
        local pyenv_start=$(date +%s)
        # LAZY: pip install $packages &>/dev/null
        local pyenv_time=$(($(date +%s) - pyenv_start))
        
        deactivate
        cd - >/dev/null
        rm -rf "$pyenv_dir"
        
        echo "pyenv: ${pyenv_time}s"
    fi
    
    # Benchmark uv
    if command -v uv &>/dev/null; then
        mkdir -p "$uv_dir" && cd "$uv_dir"
        uv venv &>/dev/null
        
        local uv_start=$(date +%s)
        uv # LAZY: pip install $packages &>/dev/null
        local uv_time=$(($(date +%s) - uv_start))
        
        cd - >/dev/null
        rm -rf "$uv_dir"
        
        echo "uv:    ${uv_time}s"
        
        if [[ -n "$pyenv_time" ]]; then
            echo ""
            echo "⚡ uv is $((pyenv_time / uv_time))x faster"
        fi
    fi
}

alias pybench="benchmark_managers"
