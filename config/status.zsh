#!/usr/bin/env zsh
# =====================================================
# STATUS MODULE - Comprehensive System Status
# =====================================================
# 
# This module provides comprehensive status reporting
# for the entire ZSH configuration system.
#
# Author: Enhanced ZSH Configuration System
# Version: 1.0.0

# Status module marker
export STATUS_MODULE_LOADED=true

# =====================================================
# MASTER STATUS FUNCTION
# =====================================================

function master_status() {
    echo "🎯 Master System Status Report"
    echo "====================================="
    echo "$(date)"
    echo ""
    
    # Core system status
    if command -v modular_zsh_status >/dev/null 2>&1; then
        echo "📦 MODULE SYSTEM STATUS:"
        echo "------------------------"
        modular_zsh_status
        echo ""
    fi
    
    # Environment and platform info
    if command -v environment_info >/dev/null 2>&1; then
        echo "🌍 ENVIRONMENT STATUS:"
        echo "---------------------"
        environment_info
        echo ""
    fi
    
    # Python system status
    if command -v python_status >/dev/null 2>&1; then
        echo "🐍 PYTHON SYSTEM STATUS:"
        echo "-----------------------"
        python_status
        echo ""
    fi
    
    # Backup system status
    if command -v backup_status >/dev/null 2>&1; then
        echo "💾 BACKUP SYSTEM STATUS:"
        echo "-----------------------"
        backup_status
        echo ""
    fi
    
    # Docker status
    if command -v docker_status >/dev/null 2>&1; then
        echo "🐳 DOCKER SYSTEM STATUS:"
        echo "-----------------------"
        docker_status
        echo ""
    fi
    
    # Spark status
    if command -v spark_status >/dev/null 2>&1; then
        echo "⚡ SPARK SYSTEM STATUS:"
        echo "----------------------"
        spark_status
        echo ""
    fi
    
    # Hadoop status
    if command -v hadoop_status >/dev/null 2>&1; then
        echo "🐘 HADOOP SYSTEM STATUS:"
        echo "-----------------------"
        hadoop_status
        echo ""
    fi
    
    # Credential system status
    if command -v credential_backend_status >/dev/null 2>&1; then
        echo "🔐 CREDENTIAL SYSTEM STATUS:"
        echo "---------------------------"
        credential_backend_status
        echo ""
    fi
    
    # Database status
    if command -v database_status >/dev/null 2>&1; then
        echo "🗄️  DATABASE SYSTEM STATUS:"
        echo "---------------------------"
        database_status
        echo ""
    fi
    
    echo "✅ Master status report complete!"
    echo "💡 Use individual status commands for detailed info"
}

# =====================================================
# QUICK STATUS FUNCTIONS
# =====================================================

function quick_status() {
    echo "⚡ Quick System Status"
    echo "====================="
    echo ""
    
    # Core modules
    local loaded_count=0
    for module in ${(k)LOADED_MODULES}; do
        if [[ "${LOADED_MODULES[$module]}" == "success" ]]; then
            ((loaded_count++))
        fi
    done
    echo "📦 Modules: $loaded_count loaded"
    
    # Platform
    echo "🌍 Platform: ${ZSH_PLATFORM:-unknown}"
    
    # Python
    if command -v python_status >/dev/null 2>&1; then
        local python_version=$(get_current_python_version 2>/dev/null || echo "none")
        echo "🐍 Python: $python_version"
    fi
    
    # Virtual environment
    if [[ -n "$VIRTUAL_ENV" ]]; then
        echo "🌱 Venv: $(basename $VIRTUAL_ENV)"
    else
        echo "🌱 Venv: none"
    fi
    
    echo ""
    echo "💡 Run 'master_status' for complete report"
}

function status_help() {
    echo "📊 Status System Commands"
    echo "========================"
    echo ""
    echo "🎯 master_status        - Complete system status report"
    echo "⚡ quick_status         - Quick overview"
    echo "📊 status_help          - This help"
    echo ""
    echo "Individual Status Commands:"
    echo "---------------------------"
    echo "📦 modular_zsh_status   - Module loading status"
    echo "🌍 environment_info     - Platform and environment"
    echo "🐍 python_status        - Python system status"
    echo "💾 backup_status        - Backup system status"
    echo "🐳 docker_status        - Docker system status"
    echo "⚡ spark_status         - Spark system status"
    echo "🐘 hadoop_status        - Hadoop system status"
    echo "🔐 credential_backend_status - Security status"
    echo "🗄️  database_status     - Database status"
    echo ""
    echo "💡 Status module loaded and ready!"
}

# =====================================================
# ALIASES
# =====================================================

alias mstatus="master_status"
alias qstatus="quick_status"
alias status-help="status_help"

echo "📊 Status module loaded - try 'master_status' or 'mstatus'"