#!/usr/bin/env zsh

# =====================================================
# AUTO-BACKUP TOGGLE SYSTEM
# =====================================================
# 
# Functions to safely toggle automatic backup functionality
# on/off without breaking the system
# =====================================================

export BACKUP_TOGGLE_MODULE_LOADED="true"

# Show current auto-backup status
backup_status() {
    echo "📊 Auto-Backup System Status"
    echo "============================"
    echo ""
    
    # Check if backup module is loaded
    if [[ "$BACKUP_MODULE_LOADED" == "true" ]]; then
        echo "📦 Backup Module: ✅ LOADED"
    else
        echo "📦 Backup Module: ❌ NOT LOADED"
    fi
    
    # Check environment variable
    echo "⚙️  AUTO_BACKUP_ON_CHANGE: ${AUTO_BACKUP_ON_CHANGE:-unset}"
    
    # Check if hook is active
    local hook_active=false
    if [[ -n "${preexec_functions[@]}" ]] && [[ "${preexec_functions[@]}" =~ "auto_backup_trigger" ]]; then
        hook_active=true
    fi
    
    if $hook_active; then
        echo "🪝 Preexec Hook: ✅ ACTIVE"
        echo "🚨 Status: AUTO-BACKUP IS ON"
    else
        echo "🪝 Preexec Hook: ❌ INACTIVE"
        echo "✅ Status: AUTO-BACKUP IS OFF"
    fi
    
    echo ""
    echo "📁 Backup Directory: ${ZSHRC_BACKUPS:-~/.zshrc_backups}"
    echo "⏰ Backup Interval: ${AUTO_BACKUP_INTERVAL:-3600} seconds"
    
    # Show recent backups
    if [[ -d "${ZSHRC_BACKUPS:-$HOME/.zshrc_backups}" ]]; then
        local backup_count=$(find "${ZSHRC_BACKUPS:-$HOME/.zshrc_backups}" -name "config_*" | wc -l | tr -d ' ')
        echo "💾 Total Backups: $backup_count"
    fi
}

# Enable auto-backup
backup_auto_on() {
    echo "🔄 Enabling Auto-Backup System..."
    
    # Load backup module if not already loaded
    if [[ "$BACKUP_MODULE_LOADED" != "true" ]]; then
        if [[ -f "$HOME/.config/zsh/backup-system.zsh" ]]; then
            echo "📦 Loading backup module..."
            source "$HOME/.config/zsh/backup-system.zsh"
        else
            echo "❌ Error: backup-system.zsh not found"
            return 1
        fi
    fi
    
    # Set environment variable
    export AUTO_BACKUP_ON_CHANGE=true
    
    # Add the hook if not already present
    if ! [[ "${preexec_functions[@]}" =~ "auto_backup_trigger" ]]; then
        echo "🪝 Adding preexec hook..."
        autoload -U add-zsh-hook
        add-zsh-hook preexec auto_backup_trigger
    fi
    
    echo "✅ Auto-backup is now ENABLED"
    echo "💡 Every command will check if backup is needed"
    backup_status
}

# Disable auto-backup  
backup_auto_off() {
    echo "🛑 Disabling Auto-Backup System..."
    
    # Set environment variable
    export AUTO_BACKUP_ON_CHANGE=false
    
    # Remove the hook if present
    if [[ "${preexec_functions[@]}" =~ "auto_backup_trigger" ]]; then
        echo "🪝 Removing preexec hook..."
        add-zsh-hook -d preexec auto_backup_trigger
    fi
    
    echo "✅ Auto-backup is now DISABLED"
    echo "💡 Manual backup still available with 'backup' command"
    backup_status
}

# Toggle auto-backup on/off
backup_auto_toggle() {
    local current_state="off"
    
    # Check if currently enabled
    if [[ "$AUTO_BACKUP_ON_CHANGE" == "true" ]] && [[ "${preexec_functions[@]}" =~ "auto_backup_trigger" ]]; then
        current_state="on"
    fi
    
    echo "🔄 Current auto-backup state: $current_state"
    
    if [[ "$current_state" == "on" ]]; then
        backup_auto_off
    else
        backup_auto_on
    fi
}

# Permanently disable auto-backup in config file
backup_auto_disable_permanent() {
    echo "🛑 Permanently Disabling Auto-Backup in Configuration..."
    
    local backup_file="$HOME/.config/zsh/backup-system.zsh"
    if [[ -f "$backup_file" ]]; then
        # Update the configuration file
        sed -i.bak 's/export AUTO_BACKUP_ON_CHANGE=true/export AUTO_BACKUP_ON_CHANGE=false/' "$backup_file"
        sed -i.bak 's/^add-zsh-hook preexec auto_backup_trigger/# add-zsh-hook preexec auto_backup_trigger/' "$backup_file"
        
        echo "✅ Configuration file updated"
        echo "💡 Changes will take effect in new shell sessions"
    else
        echo "❌ Backup configuration file not found"
        return 1
    fi
    
    # Also disable in current session
    backup_auto_off
}

# Convenience aliases
alias backup-status='backup_status'
alias backup-on='backup_auto_on'  
alias backup-off='backup_auto_off'
alias backup-toggle='backup_auto_toggle'
alias backup-disable='backup_auto_disable_permanent'