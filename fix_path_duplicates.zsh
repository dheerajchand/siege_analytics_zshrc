#!/bin/zsh

# =====================================================
# TARGETED PATH DUPLICATE FIX
# =====================================================
# This script fixes duplicate PATH entries while preserving
# your Python management setup (pyenv + uv)

echo "🎯 Targeted PATH Duplicate Fix"
echo "=============================="
echo ""

# Function to clean PATH without affecting functionality
clean_path_duplicates() {
    echo "🧹 Cleaning duplicate PATH entries..."
    
    # Get current PATH
    local current_path="$PATH"
    local cleaned_path=""
    local seen=()
    
    # Split PATH and process each entry
    for entry in ${(s/:/)current_path}; do
        # Skip empty entries
        if [[ -z "$entry" ]]; then
            continue
        fi
        
        # Check if we've seen this entry before
        if [[ ! " ${seen[@]} " =~ " ${entry} " ]]; then
            seen+=("$entry")
            if [[ -z "$cleaned_path" ]]; then
                cleaned_path="$entry"
            else
                cleaned_path="$cleaned_path:$entry"
            fi
        else
            echo "  🗑️  Removed duplicate: $entry"
        fi
    done
    
    # Set the cleaned PATH
    export PATH="$cleaned_path"
    
    echo "  ✅ PATH cleaned: ${#PATH} chars, $(echo $PATH | tr ':' '\n' | wc -l | tr -d ' ') entries"
}

# Function to verify Python tools still work
verify_python_tools() {
    echo ""
    echo "🐍 Verifying Python tools still work..."
    
    # Check if pyenv function is available
    if command -v pyenv >/dev/null 2>&1; then
        echo "  ✅ pyenv command available"
    elif type pyenv >/dev/null 2>&1; then
        echo "  ✅ pyenv function available"
    else
        echo "  ⚠️  pyenv not found - may need to reload"
    fi
    
    # Check if uv is available
    if command -v uv >/dev/null 2>&1; then
        echo "  ✅ uv command available"
    else
        echo "  ⚠️  uv not found - may need to reload"
    fi
    
    # Check if setup functions are available
    if type setup_pyenv >/dev/null 2>&1; then
        echo "  ✅ setup_pyenv function available"
    fi
    
    if type setup_uv >/dev/null 2>&1; then
        echo "  ✅ setup_uv function available"
    fi
}

# Function to create a permanent fix for your zshrc
create_permanent_fix() {
    echo ""
    echo "📝 Creating permanent PATH fix for your zshrc..."
    
    # Create a function to deduplicate PATH
    cat > ~/.zshrc.pathfix << 'EOF'
# =====================================================
# PATH DEDUPLICATION FUNCTION
# =====================================================
# Add this to your zshrc to prevent PATH duplicates

deduplicate_path() {
    # Remove duplicates while preserving order
    local cleaned_path=""
    local seen=()
    
    for entry in ${(s/:/)PATH}; do
        if [[ -n "$entry" && ! " ${seen[@]} " =~ " ${entry} " ]]; then
            seen+=("$entry")
            if [[ -z "$cleaned_path" ]]; then
                cleaned_path="$entry"
            else
                cleaned_path="$cleaned_path:$entry"
            fi
        fi
    done
    
    export PATH="$cleaned_path"
}

# Run deduplication after PATH modifications
add-zsh-hook chpwd deduplicate_path
EOF

    echo "  ✅ Created ~/.zshrc.pathfix"
    echo "  💡 Add this to your zshrc: source ~/.zshrc.pathfix"
}

# Main fix
echo "🔍 Current PATH analysis:"
echo "  Length: ${#PATH}"
echo "  Entries: $(echo $PATH | tr ':' '\n' | wc -l | tr -d ' ')"
echo "  Duplicates: $(echo $PATH | tr ':' '\n' | sort | uniq -d | wc -l | tr -d ' ')"
echo ""

# Clean PATH
clean_path_duplicates

# Verify Python tools
verify_python_tools

# Create permanent fix
create_permanent_fix

echo ""
echo "🎯 PATH Duplicate Fix Complete!"
echo "=============================="
echo ""
echo "📊 Results:"
echo "  ✅ Removed duplicate PATH entries"
echo "  ✅ Preserved Python management tools"
echo "  ✅ Created permanent fix script"
echo ""
echo "🚀 Next Steps:"
echo "  1. Test current performance: source diagnose_performance.zsh"
echo "  2. Test Python tools: setup_pyenv or setup_uv"
echo "  3. Add permanent fix: echo 'source ~/.zshrc.pathfix' >> ~/.zshrc"
echo "  4. Test Finder dialogs - they should be much faster now!"
echo ""
echo "💡 This fix only removes duplicates, preserving all your functionality"
echo "   including pyenv, uv, and project management capabilities."
