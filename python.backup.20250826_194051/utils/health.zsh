#!/usr/bin/env zsh
# ============================================
# Python Environment Health Checks
# ============================================

python_doctor() {
    echo "🏥 Python Environment Health Check"
    echo "=================================="
    
    local issues=0
    
    # Check Python
    if command -v python &>/dev/null; then
        echo "✅ Python: $(python --version 2>&1)"
    else
        echo "❌ Python not found"
        ((issues++))
    fi
    
    # Check pip
    if command -v pip &>/dev/null; then
        echo "✅ pip: $(pip --version)"
    else
        echo "⚠️  pip not found"
        ((issues++))
    fi
    
    # Check manager
    case "$PYTHON_MANAGER" in
        pyenv)
            if command -v pyenv &>/dev/null; then
                echo "✅ pyenv: $(pyenv --version)"
            else
                echo "❌ pyenv not installed"
                ((issues++))
            fi
            ;;
        uv)
            if command -v uv &>/dev/null; then
                echo "✅ uv: $(uv --version)"
            else
                echo "❌ uv not installed"
                ((issues++))
            fi
            ;;
    esac
    
    # Check venv
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "✅ Virtual environment active"
    else
        echo "ℹ️  No virtual environment active"
    fi
    
    # Check Spark Python
    if [[ -n "$PYSPARK_PYTHON" ]]; then
        echo "✅ PySpark Python: $PYSPARK_PYTHON"
    else
        echo "ℹ️  PySpark Python not set"
    fi
    
    echo ""
    if [[ $issues -eq 0 ]]; then
        echo "🎉 All checks passed!"
    else
        echo "⚠️  Found $issues issue(s)"
    fi
}

alias pyhealth="python_doctor"
