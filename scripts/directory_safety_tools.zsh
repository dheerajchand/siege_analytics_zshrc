#!/usr/bin/env zsh

# =====================================================
# DIRECTORY CLEANUP SAFETY TOOLS
# =====================================================
# Implementation of comprehensive safety measures for directory reorganization
# Based on DIRECTORY_CLEANUP_SAFETY_PLAN.md

# =====================================================
# DEPENDENCY ANALYSIS FUNCTIONS
# =====================================================

scan_file_dependencies() {
    local target_file="$1"

    if [[ -z "$target_file" ]]; then
        echo "Usage: scan_file_dependencies <file_path>"
        return 1
    fi

    # SECURITY: Input validation and sanitization
    if [[ "$target_file" == *$'\0'* ]]; then
        echo "❌ Error: Null bytes not allowed in file paths"
        return 1
    fi

    if [[ "$target_file" =~ [\;\|\&\$\`] ]]; then
        echo "❌ Error: Special shell characters not allowed"
        return 1
    fi

    # Canonicalize path to prevent traversal
    if ! target_file=$(realpath "$target_file" 2>/dev/null); then
        echo "❌ Error: Invalid file path"
        return 1
    fi

    echo "🔍 DEPENDENCY SCAN for: $target_file"
    echo "=================================================="

    # Find all files that reference this file by name (safe basename extraction)
    local safe_basename
    safe_basename=$(basename "$target_file" 2>/dev/null) || {
        echo "❌ Error: Cannot extract basename"
        return 1
    }

    echo "\n📄 Files that reference $safe_basename:"
    rg -l --fixed-strings "$safe_basename" . --type zsh 2>/dev/null | while read file; do
        echo "  📁 $file"
    done

    # Find direct source statements (safe search)
    echo "\n🔗 Direct source statements:"
    rg --fixed-strings "source.*$safe_basename" . --type zsh -n 2>/dev/null | while read line; do
        echo "  $line"
    done

    # Find path references (safe directory extraction)
    local safe_dirname
    safe_dirname=$(dirname "$target_file" 2>/dev/null) || safe_dirname="."
    echo "\n📂 Path references to $safe_dirname:"
    if [[ "$safe_dirname" != "." ]]; then
        rg --fixed-strings "$safe_dirname" . --type zsh -n 2>/dev/null | head -10 | while read line; do
            echo "  $line"
        done
    fi

    # Find include-style references (safe basename without extension)
    echo "\n📥 Include-style references:"
    local safe_name
    safe_name=$(basename "$target_file" .zsh 2>/dev/null) || safe_name="$safe_basename"
    rg --fixed-strings "\$.*$safe_name" . --type zsh -n 2>/dev/null | while read line; do
        echo "  $line"
    done

    echo "\n✅ Dependency scan complete"
}

create_dependency_matrix() {
    local output_file="${1:-dependency_matrix.txt}"

    echo "📊 Creating dependency matrix..."
    echo "# DEPENDENCY MATRIX - $(date)" > "$output_file"
    echo "# Format: SOURCE_FILE -> REFERRING_FILE:LINE -> TYPE" >> "$output_file"

    # Scan all .zsh files
    find . -name "*.zsh" -type f | while read source_file; do
        echo "\nAnalyzing: $source_file" | tee -a "$output_file"

        # Find references to this file
        rg -n "$(basename "$source_file")" . --type zsh 2>/dev/null | while read ref; do
            echo "  $source_file -> $ref -> BASENAME_REF" >> "$output_file"
        done

        # Find source statements
        rg -n "source.*$(basename "$source_file")" . --type zsh 2>/dev/null | while read ref; do
            echo "  $source_file -> $ref -> SOURCE_STATEMENT" >> "$output_file"
        done
    done

    echo "✅ Dependency matrix created: $output_file"
}

# =====================================================
# SYSTEM HEALTH TESTING
# =====================================================

test_system_health() {
    echo "🩺 COMPREHENSIVE SYSTEM HEALTH CHECK"
    echo "===================================="

    local tests_passed=0
    local tests_failed=0

    # Test 1: Syntax validation
    echo "\n🔍 Test 1: ZSH syntax validation"
    if zsh -n /Users/dheerajchand/.config/zsh/zshrc 2>/dev/null; then
        echo "  ✅ PASS - Syntax is valid"
        ((tests_passed++))
    else
        echo "  ❌ FAIL - Syntax errors detected"
        ((tests_failed++))
    fi

    # Test 2: Basic loading
    echo "\n🔍 Test 2: Basic zshrc loading"
    if source /Users/dheerajchand/.config/zsh/zshrc >/dev/null 2>&1; then
        echo "  ✅ PASS - Loads successfully"
        ((tests_passed++))
    else
        echo "  ❌ FAIL - Loading failed"
        ((tests_failed++))
        return 1  # Can't continue if basic loading fails
    fi

    # Test 3: Critical functions exist
    echo "\n🔍 Test 3: Critical functions availability"
    local critical_functions=("load_module" "show_loaded_modules" "mkcd" "command_exists")
    for func in "${critical_functions[@]}"; do
        if command -v "$func" >/dev/null 2>&1; then
            echo "  ✅ $func - Available"
            ((tests_passed++))
        else
            echo "  ❌ $func - Missing"
            ((tests_failed++))
        fi
    done

    # Test 4: Module loading
    echo "\n🔍 Test 4: Module loading functionality"
    if load_module utils >/dev/null 2>&1; then
        echo "  ✅ PASS - Module loading works"
        ((tests_passed++))
    else
        echo "  ❌ FAIL - Module loading broken"
        ((tests_failed++))
    fi

    # Test 5: Environment variables
    echo "\n🔍 Test 5: Critical environment variables"
    local critical_vars=("ZSH_CONFIG_DIR" "HOME" "PATH" "SHELL")
    for var in "${critical_vars[@]}"; do
        if [[ -n "${(P)var}" ]]; then
            echo "  ✅ $var - Set"
            ((tests_passed++))
        else
            echo "  ❌ $var - Missing"
            ((tests_failed++))
        fi
    done

    echo "\n📊 HEALTH CHECK RESULTS"
    echo "======================="
    echo "Tests passed: $tests_passed"
    echo "Tests failed: $tests_failed"

    if [[ $tests_failed -eq 0 ]]; then
        echo "✅ System health: EXCELLENT"
        return 0
    elif [[ $tests_failed -le 2 ]]; then
        echo "⚠️  System health: FAIR (minor issues)"
        return 1
    else
        echo "❌ System health: POOR (major issues)"
        return 2
    fi
}

# =====================================================
# SAFE MOVE OPERATIONS
# =====================================================

pre_move_validation() {
    local file_to_move="$1"
    local destination="$2"

    echo "🔍 PRE-MOVE VALIDATION"
    echo "====================="
    echo "Source: $file_to_move"
    echo "Destination: $destination"

    # SECURITY: Input validation
    for path in "$file_to_move" "$destination"; do
        if [[ "$path" == *$'\0'* ]]; then
            echo "❌ Error: Null bytes not allowed in paths"
            return 1
        fi
        if [[ "$path" =~ [\;\|\&\$\`] ]]; then
            echo "❌ Error: Special shell characters not allowed"
            return 1
        fi
    done

    # Check source file exists and is readable
    if [[ ! -f "$file_to_move" ]]; then
        echo "❌ Source file doesn't exist: $file_to_move"
        return 1
    fi

    if [[ ! -r "$file_to_move" ]]; then
        echo "❌ Source file is not readable: $file_to_move"
        return 1
    fi

    # Check destination directory exists
    local dest_dir=$(dirname "$destination")
    if [[ ! -d "$dest_dir" ]]; then
        echo "❌ Destination directory doesn't exist: $dest_dir"
        echo "💡 Create it first: mkdir -p \"$dest_dir\""
        return 1
    fi

    # Check for conflicts
    if [[ -f "$destination" ]]; then
        echo "⚠️  File already exists at destination: $destination"
        echo "💡 Consider renaming or backup strategy"
        return 1
    fi

    # Test current system health
    echo "\n🧪 Testing current system health..."
    if ! test_system_health >/dev/null 2>&1; then
        echo "❌ Current system is already unhealthy"
        echo "💡 Fix existing issues before moving files"
        return 1
    fi

    # Scan dependencies
    echo "\n🔍 Scanning dependencies..."
    scan_file_dependencies "$file_to_move"

    echo "\n✅ Pre-move validation passed"
    return 0
}

safe_move_file() {
    local source_file="$1"
    local destination="$2"

    echo "🚚 SAFE FILE MOVE OPERATION"
    echo "=========================="

    # SECURITY: Input validation for both parameters
    for path in "$source_file" "$destination"; do
        if [[ -z "$path" ]]; then
            echo "❌ Error: Empty path provided"
            return 1
        fi
        if [[ "$path" == *$'\0'* ]]; then
            echo "❌ Error: Null bytes not allowed in paths"
            return 1
        fi
        if [[ "$path" =~ [;|&$`] ]]; then
            echo "❌ Error: Special shell characters not allowed"
            return 1
        fi
    done

    # 1. Pre-move validation
    if ! pre_move_validation "$source_file" "$destination"; then
        echo "❌ Pre-move validation failed - aborting"
        return 1
    fi

    # 2. Create backup
    local backup_dir="/tmp/file_move_backup_$(date +%Y%m%d_%H%M%S)"
    echo "\n📦 Creating backup..."
    mkdir -p "$backup_dir"
    rsync -av . "$backup_dir/" >/dev/null 2>&1
    echo "✅ Backup created: $backup_dir"

    # 3. Find and update all references
    echo "\n🔄 Updating references..."
    local refs_updated=0

    # Create temporary script to update references
    local update_script="/tmp/update_refs_$(date +%Y%m%d_%H%M%S).sh"
    echo "#!/bin/bash" > "$update_script"

    # Find all references and prepare updates
    while IFS=: read -r file line_num line_content; do
        if [[ -n "$file" && -f "$file" ]]; then
            echo "sed -i.bak 's|$source_file|$destination|g' \"$file\"" >> "$update_script"
            ((refs_updated++))
        fi
    done < <(rg -n "$source_file" . --type zsh 2>/dev/null)

    if [[ $refs_updated -gt 0 ]]; then
        echo "Found $refs_updated reference(s) to update"
        echo "Executing reference updates..."
        chmod +x "$update_script"
        bash "$update_script"
        rm "$update_script"
        echo "✅ References updated"
    else
        echo "No references found to update"
    fi

    # 4. Move the file with error handling
    echo "\n📁 Moving file..."
    if ! mv "$source_file" "$destination" 2>/dev/null; then
        echo "❌ Failed to move file: Permission denied or other error"
        echo "🔄 Initiating rollback..."
        rollback_move "$backup_dir"
        return 1
    fi
    echo "✅ File moved: $source_file → $destination"

    # 5. Test system after move
    echo "\n🧪 Testing system after move..."
    if test_system_health >/dev/null 2>&1; then
        echo "✅ System functional after move"
        echo "🗑️  Cleaning up backup..."
        rm -rf "$backup_dir"
        return 0
    else
        echo "❌ System broken after move - initiating rollback"
        rollback_move "$backup_dir"
        return 1
    fi
}

rollback_move() {
    local backup_dir="$1"

    if [[ ! -d "$backup_dir" ]]; then
        echo "❌ Backup directory not found: $backup_dir"
        return 1
    fi

    echo "🔄 EMERGENCY ROLLBACK"
    echo "===================="
    echo "Restoring from: $backup_dir"

    # Restore from backup
    rsync -av --delete "$backup_dir/" ./ >/dev/null 2>&1

    # Test restored system
    if test_system_health >/dev/null 2>&1; then
        echo "✅ Rollback successful - system restored"
        rm -rf "$backup_dir"
        return 0
    else
        echo "❌ Rollback failed - manual intervention required"
        echo "Backup preserved at: $backup_dir"
        return 1
    fi
}

# =====================================================
# BATCH OPERATIONS
# =====================================================

incremental_batch_move() {
    local move_plan_file="$1"

    if [[ ! -f "$move_plan_file" ]]; then
        echo "❌ Move plan file not found: $move_plan_file"
        echo "💡 Create a file with format: source_file -> destination_file"
        return 1
    fi

    echo "📦 INCREMENTAL BATCH MOVE"
    echo "========================"

    # Test initial state
    if ! test_system_health >/dev/null 2>&1; then
        echo "❌ Initial system state is unhealthy - aborting"
        return 1
    fi

    local moved_files=()
    local line_num=0

    while IFS= read -r line; do
        ((line_num++))

        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^# ]] && continue

        # Parse source and destination (simple string splitting)
        if [[ "$line" == *" -> "* ]]; then
            local source_file="${line%% -> *}"
            local dest_file="${line##* -> }"
            # Trim whitespace
            source_file="${source_file## }"
            source_file="${source_file%% }"
            dest_file="${dest_file## }"
            dest_file="${dest_file%% }"

            echo "\n🔄 [$line_num] Processing: $source_file → $dest_file"

            if safe_move_file "$source_file" "$dest_file"; then
                moved_files+=("$line")
                echo "✅ [$line_num] Successfully moved"
            else
                echo "❌ [$line_num] Move failed - aborting batch operation"
                return 1
            fi
        else
            echo "⚠️  [$line_num] Invalid format: $line"
        fi
    done < "$move_plan_file"

    echo "\n✅ Batch move completed successfully"
    echo "📊 Moved ${#moved_files[@]} files"
    return 0
}

# =====================================================
# REFERENCE INTEGRITY CHECKING
# =====================================================

check_reference_integrity() {
    echo "🔍 REFERENCE INTEGRITY CHECK"
    echo "============================"

    local broken_refs=0
    local total_refs=0

    # Check source statements
    echo "\n📄 Checking source statements..."
    while IFS=: read -r file line_num line_content; do
        ((total_refs++))

        # Extract the path from source statement
        local source_path
        # Simple extraction using parameter expansion
        if [[ "$line_content" == *"source "* ]]; then
            source_path="${line_content#*source }"
            source_path="${source_path%% *}"
            source_path="${source_path//[\"\']/}"

            # Handle relative paths
            if [[ "$source_path" != /* ]]; then
                source_path="$(dirname "$file")/$source_path"
            fi

            if [[ ! -f "$source_path" ]]; then
                echo "  ❌ Broken: $file:$line_num → $source_path"
                ((broken_refs++))
            fi
        fi
    done < <(rg -n 'source\s+' . --type zsh 2>/dev/null)

    # Check if statements with file tests
    echo "\n📁 Checking file existence tests..."
    while IFS=: read -r file line_num line_content; do
        ((total_refs++))

        # Extract paths from [[ -f "path" ]] statements
        if [[ "$line_content" == *"[[ -f "* ]]; then
            local test_path="${line_content#*[[ -f }"
            test_path="${test_path%% *}"
            test_path="${test_path%%]]*}"
            test_path="${test_path//[\"\']/}"

            # Handle relative paths and variables
            if [[ "$test_path" != /* && "$test_path" != \$* ]]; then
                test_path="$(dirname "$file")/$test_path"
            fi

            # Skip variable references
            if [[ "$test_path" != \$* && ! -f "$test_path" ]]; then
                echo "  ❌ Broken: $file:$line_num → $test_path"
                ((broken_refs++))
            fi
        fi
    done < <(rg -n '\[\[.*-f\s+' . --type zsh 2>/dev/null)

    echo "\n📊 INTEGRITY CHECK RESULTS"
    echo "=========================="
    echo "Total references checked: $total_refs"
    echo "Broken references found: $broken_refs"

    if [[ $broken_refs -eq 0 ]]; then
        echo "✅ All references are intact"
        return 0
    else
        echo "❌ Found $broken_refs broken references"
        echo "💡 Run fixes before proceeding with any changes"
        return 1
    fi
}

# =====================================================
# UTILITY FUNCTIONS
# =====================================================

create_move_plan_template() {
    local output_file="${1:-move_plan.txt}"

    cat > "$output_file" << 'EOF'
# DIRECTORY REORGANIZATION MOVE PLAN
# Format: source_file -> destination_file
# Lines starting with # are comments and will be ignored

# Example moves:
# old_script.zsh -> scripts/old_script.zsh
# config_file.zsh -> config/config_file.zsh
# test_file.zsh -> tests/test_file.zsh

# Add your move operations below:

EOF

    echo "📝 Move plan template created: $output_file"
    echo "💡 Edit this file to specify your reorganization plan"
}

emergency_rollback() {
    echo "🚨 EMERGENCY ROLLBACK INITIATED"
    echo "==============================="

    # Find most recent backup
    local latest_backup=$(ls -1dt /tmp/file_move_backup_* 2>/dev/null | head -1)

    if [[ -n "$latest_backup" ]]; then
        echo "📦 Found backup: $latest_backup"
        rollback_move "$latest_backup"
    else
        echo "❌ No automatic backup found"
        echo "💡 Check for manual backups or git history"
        return 1
    fi
}

# =====================================================
# MAIN INTERFACE FUNCTIONS
# =====================================================

directory_safety_help() {
    cat << 'EOF'
🛡️  DIRECTORY CLEANUP SAFETY TOOLS
================================

ANALYSIS FUNCTIONS:
  scan_file_dependencies <file>     - Scan what references a file
  create_dependency_matrix [output] - Create full dependency matrix
  check_reference_integrity         - Check all file references

TESTING FUNCTIONS:
  test_system_health                 - Comprehensive system health check

MOVE OPERATIONS:
  safe_move_file <source> <dest>     - Safely move a single file
  incremental_batch_move <plan_file> - Move multiple files incrementally

UTILITY FUNCTIONS:
  create_move_plan_template [file]   - Create template for batch moves
  emergency_rollback                 - Emergency rollback to last backup

WORKFLOW EXAMPLE:
  1. scan_file_dependencies old_file.zsh
  2. test_system_health
  3. safe_move_file old_file.zsh new/location/old_file.zsh
  4. check_reference_integrity

For batch operations:
  1. create_move_plan_template my_moves.txt
  2. # Edit my_moves.txt with your moves
  3. incremental_batch_move my_moves.txt

EOF
}

# Auto-run help if script is executed directly
if [[ "${(%):-%x}" == "${0}" ]]; then
    directory_safety_help
fi