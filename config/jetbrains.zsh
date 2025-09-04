#!/usr/bin/env zsh

# =====================================================
# JETBRAINS DEVELOPMENT TOOLS INTEGRATION
# =====================================================
# 
# Provides seamless integration with JetBrains IDEs and tooling:
# - PyCharm for Python development
# - IntelliJ IDEA for Java/Scala
# - DataGrip for database management
# - DataSpell for data science
# - WebStorm for web development
#
# Auto-generated CLI tools by JetBrains Toolbox provide:
# - Command line access to all IDEs
# - Project opening from terminal
# - Wait functionality for git editors
# - Consistent interface across tools
# =====================================================

# JetBrains tools configuration
export JETBRAINS_TOOLS_PATH="$HOME/.jetbrains/bin"

# Ensure JetBrains bin directory exists
if [[ ! -d "$JETBRAINS_TOOLS_PATH" ]]; then
    mkdir -p "$JETBRAINS_TOOLS_PATH"
fi

# Add JetBrains tools to PATH (high priority for CLI access)
export PATH="$JETBRAINS_TOOLS_PATH:$PATH"

# =====================================================
# JETBRAINS TOOL FUNCTIONS
# =====================================================

jetbrains_status() {
    # Check status of JetBrains tooling integration
    #
    # Shows available tools, versions, and configuration status
    #
    # Returns:
    #     0: All tools properly configured
    #     1: Issues found with configuration
    echo "🛠️  JetBrains Development Tools Status"
    echo ""
    
    # Check if JetBrains Toolbox is installed
    if [[ -d "$JETBRAINS_TOOLS_PATH" ]]; then
        echo "✅ JetBrains Toolbox integration: Active"
        echo "📁 Tools directory: $JETBRAINS_TOOLS_PATH"
        echo ""
        
        # List available tools
        echo "Available CLI Tools:"
        local tool_count=0
        for tool in "$JETBRAINS_TOOLS_PATH"/*; do
            if [[ -x "$tool" && ! -d "$tool" ]]; then
                local tool_name=$(basename "$tool")
                echo "  ✅ $tool_name"
                ((tool_count++))
            fi
        done
        
        if [[ $tool_count -eq 0 ]]; then
            echo "  ⚠️  No CLI tools found"
            echo "  💡 Generate tools from JetBrains Toolbox → Settings → Tools"
        fi
        
        echo ""
        echo "Total tools: $tool_count"
        
        # Check PATH integration
        if [[ ":$PATH:" == *":$JETBRAINS_TOOLS_PATH:"* ]]; then
            echo "✅ PATH integration: Active"
        else
            echo "❌ PATH integration: Missing"
            echo "💡 Add export PATH=\"\$JETBRAINS_TOOLS_PATH:\$PATH\" to your shell config"
        fi
        
    else
        echo "❌ JetBrains Toolbox integration: Not found"
        echo "💡 Install JetBrains Toolbox and generate CLI tools"
        return 1
    fi
}

pycharm_clean_launch() {
    # Launch PyCharm with clean environment to debug file dialog issues
    #
    # This bypasses potential environment variable conflicts that might
    # interfere with macOS file dialogs
    #
    # Args:
    #     project_path (str, optional): Path to project to open
    #
    # Examples:
    #     pycharm_clean_launch
    #     pycharm_clean_launch ~/my_project
    local project_path="$1"
    
    echo "🚀 Launching PyCharm with clean environment..."
    echo "💡 This may resolve file dialog issues"
    
    if [[ -n "$project_path" ]]; then
        env -i PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
            HOME="$HOME" \
            USER="$USER" \
            "/Users/dheerajchand/Applications/PyCharm.app/Contents/MacOS/pycharm" "$project_path"
    else
        env -i PATH="/usr/bin:/bin:/usr/sbin:/sbin" \
            HOME="$HOME" \
            USER="$USER" \
            "/Users/dheerajchand/Applications/PyCharm.app/Contents/MacOS/pycharm"
    fi
}

jetbrains_diagnose_env() {
    # Diagnose potential environment conflicts with JetBrains IDEs
    #
    # Checks for common issues that can cause GUI problems:
    # - Java environment conflicts
    # - Library path issues
    # - PATH conflicts
    echo "🔍 JetBrains Environment Diagnosis"
    echo ""
    
    # Check Java configuration
    echo "☕ Java Environment:"
    if [[ -n "$JAVA_HOME" ]]; then
        echo "  JAVA_HOME: $JAVA_HOME"
        if java -version >/dev/null 2>&1; then
            local java_version=$(java -version 2>&1 | head -1)
            echo "  Java Version: $java_version"
        else
            echo "  ❌ Java not accessible from JAVA_HOME"
        fi
    else
        echo "  ⚠️  JAVA_HOME not set"
    fi
    
    # Check for problematic environment variables
    echo ""
    echo "🔍 Potentially Problematic Variables:"
    local issues_found=0
    
    if [[ -n "$LD_LIBRARY_PATH" ]]; then
        echo "  ❌ LD_LIBRARY_PATH: $LD_LIBRARY_PATH"
        echo "     💡 Can interfere with macOS GUI applications"
        ((issues_found++))
    else
        echo "  ✅ LD_LIBRARY_PATH: Not set (good)"
    fi
    
    if [[ -n "$DYLD_LIBRARY_PATH" ]]; then
        echo "  ⚠️  DYLD_LIBRARY_PATH: $DYLD_LIBRARY_PATH" 
        echo "     💡 May cause library conflicts"
        ((issues_found++))
    else
        echo "  ✅ DYLD_LIBRARY_PATH: Not set (good)"
    fi
    
    # Check PATH for JetBrains integration
    echo ""
    echo "🛤️  PATH Configuration:"
    if [[ ":$PATH:" == *":$JETBRAINS_TOOLS_PATH:"* ]]; then
        echo "  ✅ JetBrains tools in PATH"
    else
        echo "  ❌ JetBrains tools missing from PATH"
        ((issues_found++))
    fi
    
    echo ""
    if [[ $issues_found -eq 0 ]]; then
        echo "✅ No obvious environment conflicts found"
    else
        echo "⚠️  Found $issues_found potential issues"
        echo "💡 Try launching with pycharm_clean_launch for testing"
    fi
    
    return $issues_found
}

# =====================================================
# PROJECT MANAGEMENT HELPERS
# =====================================================

open_project() {
    # Open project in appropriate JetBrains IDE based on project type
    #
    # Auto-detects project type and launches the right IDE:
    # - Python projects → PyCharm
    # - Java/Scala projects → IntelliJ IDEA  
    # - Web projects → WebStorm
    # - Data science projects → DataSpell
    #
    # Args:
    #     project_path (str): Path to project directory
    #
    # Examples:
    #     open_project ~/my_python_project
    #     open_project .
    local project_path="${1:-.}"
    
    if [[ ! -d "$project_path" ]]; then
        echo "❌ Project directory not found: $project_path"
        return 1
    fi
    
    # Resolve absolute path
    project_path=$(cd "$project_path" && pwd)
    
    echo "🔍 Analyzing project: $project_path"
    
    # Detect project type
    local ide_choice=""
    local reason=""
    
    # Python project detection
    if [[ -f "$project_path/requirements.txt" || -f "$project_path/pyproject.toml" || -f "$project_path/setup.py" ]]; then
        # Check if it's a data science project
        if [[ -d "$project_path/notebooks" ]] || grep -q "jupyter\|pandas\|numpy\|matplotlib" "$project_path/requirements.txt" 2>/dev/null; then
            ide_choice="dataspell"
            reason="Data science project (has notebooks or DS libraries)"
        else
            ide_choice="pycharm"
            reason="Python project"
        fi
    # Java/Scala project detection
    elif [[ -f "$project_path/pom.xml" || -f "$project_path/build.gradle" || -f "$project_path/build.sbt" ]]; then
        ide_choice="idea"
        reason="Java/Scala project"
    # Web project detection
    elif [[ -f "$project_path/package.json" || -f "$project_path/angular.json" || -f "$project_path/vue.config.js" ]]; then
        ide_choice="webstorm"
        reason="Web development project"
    # Default to PyCharm for mixed or unknown projects
    else
        ide_choice="pycharm"
        reason="Default choice for mixed/unknown project type"
    fi
    
    echo "🎯 Selected IDE: $ide_choice ($reason)"
    
    # Launch the chosen IDE
    if command -v "$ide_choice" >/dev/null 2>&1; then
        echo "🚀 Launching $ide_choice with project: $project_path"
        "$ide_choice" "$project_path"
    else
        echo "❌ $ide_choice CLI tool not found"
        echo "💡 Install from JetBrains Toolbox and generate CLI tools"
        return 1
    fi
}

# =====================================================
# ALIASES AND SHORTCUTS
# =====================================================

# IDE shortcuts
alias py='pycharm'
alias idea='idea' 
alias ws='webstorm'
alias dg='datagrip'
alias ds='dataspell'

# Project management
alias project='open_project'
alias jb-status='jetbrains_status'
alias jb-diagnose='jetbrains_diagnose_env'
alias jb-clean='pycharm_clean_launch'

# =====================================================
# INITIALIZATION
# =====================================================

# Verify JetBrains integration on module load
if [[ "$JETBRAINS_VERIFY_ON_LOAD" == "true" ]]; then
    jetbrains_status >/dev/null || echo "⚠️  JetBrains integration issues detected. Run 'jb-status' for details."
fi