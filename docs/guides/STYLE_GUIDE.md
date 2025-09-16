# 📝 ZSH Configuration Style Guide

## 🎯 **Purpose**

This style guide ensures consistency, maintainability, and security across the ZSH configuration codebase. Following these guidelines helps maintain the A+ code quality we've achieved.

---

## 🏗️ **Architecture Principles**

### **1. Modular Design**
- **Single Responsibility**: Each function should have one clear purpose
- **Focused Modules**: Group related functionality into cohesive modules
- **Loose Coupling**: Minimize dependencies between modules
- **High Cohesion**: Related functions should be grouped together

### **2. Security First**
- **Input Validation**: Always validate user input before processing
- **Path Safety**: Prevent directory traversal attacks
- **Command Safety**: Validate external command execution
- **Privilege Separation**: Use sudo only when necessary with proper validation

### **3. Performance Optimization**
- **Avoid Subprocess Pipelines**: Use efficient alternatives to `ps aux | grep`
- **Minimize External Commands**: Prefer built-in zsh operations
- **Cache Results**: Store expensive operations when appropriate
- **Background Processing**: Use background services for heavy tasks

---

## 🔤 **Naming Conventions**

### **Functions**
```bash
# ✅ Good: Descriptive, action-oriented
function cleanup_uninstalled_containers() { }
function validate_container_name() { }
function get_fileproviderd_cpu() { }

# ❌ Bad: Unclear, abbreviated
function cleanup_apps() { }
function validate() { }
function get_fpd_cpu() { }
```

### **Variables**
```bash
# ✅ Good: Clear, descriptive
local container_name="example.app"
local containers_removed=0
local fileproviderd_cpu=25

# ❌ Bad: Unclear abbreviations
local name="example.app"
local count=0
local fpd_cpu=25
```

### **Constants**
```bash
# ✅ Good: Uppercase with descriptive names
readonly ICLOUD_CPU_WARNING_THRESHOLD=50
readonly MAX_CONTAINER_NAME_LENGTH=100
readonly DEFAULT_TIMEOUT_SECONDS=30

# ❌ Bad: Magic numbers or unclear names
readonly THRESHOLD=50
readonly MAX_LEN=100
readonly TIMEOUT=30
```

### **Private Functions**
```bash
# ✅ Good: Prefix with underscore for internal functions
_validate_container_name() { }
_restart_fileproviderd() { }
_analyze_container_issues() { }

# ✅ Good: Public functions without prefix
icloud_diagnose() { }
icloud_cleanup() { }
path_clean() { }
```

---

## 📋 **Function Documentation**

### **Required Documentation Format**
```bash
function_name() {
    # Brief one-line description of the function
    #
    # Description:
    #   Detailed explanation of what the function does,
    #   its behavior, and key features.
    #
    # Args:
    #   param1 (type): Description of parameter
    #   param2 (type, optional): Description with default value
    #
    # Returns:
    #   0: Success condition
    #   1: Error condition
    #
    # Examples:
    #   function_name "arg1"
    #   function_name "arg1" "optional_arg2"
    #
    # Security:
    #   Input validation: Describe validation performed
    #   Privileges: Note if sudo or special permissions required

    # Implementation here
}
```

### **Example: Well-Documented Function**
```bash
_validate_container_name() {
    # Secure container name validation to prevent directory traversal
    #
    # Description:
    #   Validates container names to ensure they are safe for file system
    #   operations and prevent directory traversal attacks. Checks for
    #   dangerous patterns, character restrictions, and length limits.
    #
    # Args:
    #   container_name (str): Container name to validate
    #
    # Returns:
    #   0: Valid container name
    #   1: Invalid or dangerous container name
    #
    # Examples:
    #   _validate_container_name "com.example.app"
    #   _validate_container_name "my-container_v1.2"
    #
    # Security:
    #   Input validation: Prevents ../,/,~,- patterns
    #   Character whitelist: Only [a-zA-Z0-9._-] allowed
    #   Length limit: Maximum 100 characters

    local container_name="$1"
    # Implementation...
}
```

---

## 🛡️ **Security Guidelines**

### **Input Validation**
```bash
# ✅ Good: Comprehensive validation
_validate_container_name() {
    local container_name="$1"

    # Check for empty input
    if [[ -z "$container_name" ]]; then
        echo "❌ Container name cannot be empty"
        return 1
    fi

    # Check for dangerous patterns
    if [[ "$container_name" =~ \.\./|^/|^-|^~ ]]; then
        echo "❌ Container name contains dangerous path elements"
        return 1
    fi

    # Character whitelist
    if [[ ! "$container_name" =~ ^[a-zA-Z0-9._-]+$ ]]; then
        echo "❌ Container name contains invalid characters"
        return 1
    fi

    # Length validation
    if [[ ${#container_name} -gt 100 ]]; then
        echo "❌ Container name too long (max 100 characters)"
        return 1
    fi

    return 0
}

# ❌ Bad: No validation
function process_container() {
    sudo rm -rf "$HOME/Library/Mobile Documents/*$1*"
}
```

### **Safe Command Execution**
```bash
# ✅ Good: Proper error handling and validation
_safe_find_containers() {
    local container_name="$1"
    local mobile_docs="$HOME/Library/Mobile Documents"

    if [[ ! -d "$mobile_docs" ]]; then
        echo "❌ Mobile Documents directory not found" >&2
        return 1
    fi

    # Use find with strict safety options
    find "$mobile_docs" -maxdepth 1 -type d -name "*${container_name}*" -print0 2>/dev/null
}

# ❌ Bad: Unsafe glob expansion
function find_containers() {
    ls $HOME/Library/Mobile\ Documents/*$1*
}
```

---

## ⚡ **Performance Guidelines**

### **Efficient Subprocess Usage**
```bash
# ✅ Good: Single efficient process
_get_fileproviderd_cpu() {
    local cpu_info
    cpu_info=$(ps -o pid,pcpu,comm -e | awk '/fileproviderd$/ {print int($2); exit}')
    echo "${cpu_info:-0}"
}

# ❌ Bad: Multiple subprocess pipeline
function get_cpu_old() {
    ps aux | grep fileproviderd | grep -v grep | awk '{print $3}' | head -1
}
```

### **Loop Optimization**
```bash
# ✅ Good: Proper while loop that preserves variables
while IFS= read -r dir; do
    [[ -n "$dir" && -d "$dir" ]] && new_path="${new_path:+$new_path:}$dir"
done < <(echo "$PATH" | tr ':' '\n')

# ❌ Bad: Pipeline loop that loses variables
echo "$PATH" | tr ':' '\n' | while read -r dir; do
    [[ -n "$dir" && -d "$dir" ]] && new_path="${new_path:+$new_path:}$dir"
done
```

### **Avoid External Dependencies**
```bash
# ✅ Good: Native zsh arithmetic
if (( fileproviderd_cpu > ICLOUD_CPU_WARNING_THRESHOLD )); then
    echo "High CPU usage detected"
fi

# ❌ Bad: External bc process
if [[ $(echo "$cpu > 50" | bc) -eq 1 ]]; then
    echo "High CPU usage detected"
fi
```

---

## 🔧 **Error Handling**

### **Comprehensive Error Handling**
```bash
# ✅ Good: Proper error handling with specific messages
_execute_brctl_command() {
    local brctl_output

    if ! brctl_output=$(brctl status 2>&1); then
        echo "❌ Failed to execute brctl command" >&2
        echo "Error details: $brctl_output" >&2
        return 1
    fi

    echo "$brctl_output"
    return 0
}

# ❌ Bad: Silent failures
function get_status() {
    brctl status 2>/dev/null
}
```

### **Graceful Degradation**
```bash
# ✅ Good: Fallback when dependencies missing
_check_brctl_available() {
    if ! command -v brctl >/dev/null 2>&1; then
        cat << 'EOF'
❌ brctl not found. Install iCloud sync tools:
   This function requires brctl (part of iCloud/CloudKit tools)
   On macOS, ensure iCloud Drive is enabled in System Preferences

   If brctl is still missing:
   1. Check System Preferences > Apple ID > iCloud > iCloud Drive
   2. Restart the system if iCloud Drive was just enabled
   3. Try running: sudo xcode-select --install
EOF
        return 1
    fi
    return 0
}
```

---

## 🎨 **Code Formatting**

### **Indentation and Spacing**
```bash
# ✅ Good: Consistent 4-space indentation
function well_formatted_function() {
    local variable="value"

    if [[ condition ]]; then
        echo "Properly indented"

        case "$variable" in
            "value1")
                echo "Case properly indented"
                ;;
            "value2")
                echo "Another case"
                ;;
        esac
    fi
}
```

### **Line Length and Wrapping**
```bash
# ✅ Good: Reasonable line length with proper wrapping
function long_parameter_function() {
    local very_long_variable_name="some value"
    local another_long_variable="another value"

    # Wrap long lines at logical points
    if [[ "$very_long_variable_name" == "some value" ]] && \
       [[ "$another_long_variable" == "another value" ]]; then
        echo "Condition met"
    fi
}

# ✅ Good: Heredoc for long text
function show_help() {
    cat << 'EOF'
Usage: command [options]

Options:
    --option1    Description of option 1
    --option2    Description of option 2
    --help       Show this help message
EOF
}
```

---

## 🧪 **Testing Guidelines**

### **Function Testing Pattern**
```bash
# Test helper functions separately
test_validate_container_name() {
    echo "Testing container name validation..."

    # Test valid names
    _validate_container_name "com.example.app" || echo "❌ Valid name rejected"
    _validate_container_name "my-app_v1.2" || echo "❌ Valid name rejected"

    # Test invalid names
    _validate_container_name "../dangerous" && echo "❌ Dangerous name accepted"
    _validate_container_name "/absolute/path" && echo "❌ Absolute path accepted"
    _validate_container_name "~user/path" && echo "❌ Home path accepted"

    echo "✅ Container validation tests complete"
}
```

### **Integration Testing**
```bash
# Test complete workflows
test_icloud_cleanup_workflow() {
    echo "Testing iCloud cleanup workflow..."

    # Mock brctl for testing
    function brctl() { echo "mock output"; }

    # Test dry run mode
    result=$(icloud_cleanup --uninstalled)
    [[ $? -eq 0 ]] || echo "❌ Cleanup failed"

    echo "✅ Workflow tests complete"
}
```

---

## 📦 **Module Organization**

### **File Structure**
```
~/.config/zsh/
├── zshrc                       # Main configuration entry point
├── config/
│   ├── core.zsh               # Essential functions and settings
│   ├── python.zsh             # Python environment management
│   ├── docker.zsh             # Docker utilities
│   └── icloud.zsh             # iCloud diagnostics and cleanup
├── modules/                    # On-demand feature modules
├── services/                   # Background services
└── docs/
    ├── guides/
    │   ├── STYLE_GUIDE.md      # This document
    │   ├── DEBUGGING_DIRECTIVES.md
    │   └── TROUBLESHOOTING.md
    └── examples/               # Usage examples
```

### **Module Template**
```bash
#!/usr/bin/env zsh

# =====================================================
# MODULE_NAME - Brief Description
# =====================================================
#
# Description:
#   Detailed description of what this module provides
#   and when it should be used.
#
# Dependencies:
#   - List external dependencies
#   - Other modules this depends on
#
# Usage:
#   source path/to/module_name.zsh
#   module_function args
#
# Security Notes:
#   - Any security considerations
#   - Privilege requirements
# =====================================================

# Module constants
readonly MODULE_NAME_CONSTANT=value

# Private helper functions
_module_helper_function() {
    # Implementation
}

# Public module functions
module_main_function() {
    # Implementation
}

# Module initialization
if [[ -n "$ZSH_VERSION" ]]; then
    # ZSH-specific initialization
fi

# Export module completion indicator
export MODULE_NAME_LOADED=true
```

---

## 🚨 **Common Anti-Patterns to Avoid**

### **Security Anti-Patterns**
```bash
# ❌ NEVER: Unsafe user input
function dangerous_function() {
    sudo rm -rf $1  # No quotes, no validation
}

# ❌ NEVER: Command injection vulnerability
function vulnerable_search() {
    find . -name $1  # Unquoted variable
}

# ❌ NEVER: Glob expansion risks
function risky_cleanup() {
    rm -rf ~/Documents/*$1*  # Dangerous glob
}
```

### **Performance Anti-Patterns**
```bash
# ❌ NEVER: Subprocess pipeline chains
function slow_process_check() {
    ps aux | grep something | grep -v grep | awk '{print $2}' | head -1
}

# ❌ NEVER: Loop with external commands
function inefficient_loop() {
    for file in $(ls); do
        wc -l "$file"  # External command in loop
    done
}
```

### **Code Quality Anti-Patterns**
```bash
# ❌ NEVER: Monolithic functions
function giant_function() {
    # 200+ lines of mixed responsibilities
    # Multiple case statements
    # No error handling
    # No documentation
}

# ❌ NEVER: Magic numbers
function unclear_thresholds() {
    if [[ $cpu -gt 50 ]]; then  # What is 50?
        action_needed=true
    fi
}
```

---

## ✅ **Pre-Commit Checklist**

Before committing code, ensure:

### **Security Review**
- [ ] All user inputs are validated
- [ ] No command injection vulnerabilities
- [ ] Path traversal attacks prevented
- [ ] Sudo usage is justified and safe

### **Performance Review**
- [ ] No unnecessary subprocess pipelines
- [ ] Efficient loop patterns used
- [ ] External commands minimized
- [ ] Variables persist outside loops

### **Code Quality Review**
- [ ] Functions have single responsibility
- [ ] Variable names are descriptive
- [ ] Magic numbers replaced with constants
- [ ] Comprehensive error handling

### **Documentation Review**
- [ ] Function documentation complete
- [ ] Usage examples provided
- [ ] Security notes included
- [ ] Return codes documented

### **Testing**
- [ ] Function works in isolation
- [ ] Error conditions handled gracefully
- [ ] No silent failures
- [ ] Integration with other functions tested

---

## 🎯 **Style Guide Compliance Examples**

### **✅ Excellent Example**
```bash
#!/usr/bin/env zsh

# Constants
readonly CONTAINER_NAME_MAX_LENGTH=100
readonly VALIDATION_PATTERN='^[a-zA-Z0-9._-]+$'

_validate_container_name() {
    # Secure container name validation to prevent directory traversal
    #
    # Description:
    #   Validates container names using comprehensive security checks
    #   to prevent directory traversal attacks and ensure safe operations.
    #
    # Args:
    #   container_name (str): Container name to validate
    #
    # Returns:
    #   0: Valid container name
    #   1: Invalid or dangerous container name
    #
    # Examples:
    #   _validate_container_name "com.example.app"
    #   _validate_container_name "my-container_v1.2"
    #
    # Security:
    #   Input validation: Prevents ../,/,~,- patterns
    #   Character whitelist: Only [a-zA-Z0-9._-] allowed
    #   Length limit: Maximum 100 characters

    local container_name="$1"

    # Comprehensive validation with specific error messages
    if [[ -z "$container_name" ]]; then
        echo "❌ Container name cannot be empty" >&2
        return 1
    fi

    if [[ "$container_name" =~ \.\./|^/|^-|^~ ]]; then
        echo "❌ Container name contains dangerous path elements: $container_name" >&2
        return 1
    fi

    if [[ ! "$container_name" =~ $VALIDATION_PATTERN ]]; then
        echo "❌ Container name contains invalid characters: $container_name" >&2
        echo "   Only letters, numbers, dots, hyphens, and underscores allowed" >&2
        return 1
    fi

    if [[ ${#container_name} -gt $CONTAINER_NAME_MAX_LENGTH ]]; then
        echo "❌ Container name too long (max $CONTAINER_NAME_MAX_LENGTH characters): ${#container_name}" >&2
        return 1
    fi

    return 0
}

secure_container_operation() {
    # Perform secure operations on validated containers
    #
    # Description:
    #   Demonstrates proper validation, error handling, and secure
    #   operations following all style guide principles.
    #
    # Args:
    #   container_name (str): Container to operate on
    #   operation (str): Operation to perform
    #
    # Returns:
    #   0: Operation successful
    #   1: Validation failed or operation error
    #
    # Examples:
    #   secure_container_operation "com.example.app" "cleanup"
    #
    # Security:
    #   Input validation: Full container name validation
    #   Privileges: Operations performed with minimal privileges

    local container_name="$1"
    local operation="$2"

    # Validate inputs using helper function
    if ! _validate_container_name "$container_name"; then
        return 1
    fi

    # Perform operation with proper error handling
    case "$operation" in
        "cleanup")
            if _cleanup_container_safely "$container_name"; then
                echo "✅ Container cleanup completed: $container_name"
                return 0
            else
                echo "❌ Container cleanup failed: $container_name" >&2
                return 1
            fi
            ;;
        *)
            echo "❌ Invalid operation: $operation" >&2
            echo "Usage: secure_container_operation <container> <cleanup>" >&2
            return 1
            ;;
    esac
}
```

---

## 📚 **References and Resources**

### **Related Documentation**
- [DEBUGGING_DIRECTIVES.md](DEBUGGING_DIRECTIVES.md) - Investigation protocols
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Common problems and solutions
- [MAINTENANCE.md](MAINTENANCE.md) - Maintenance procedures
- [SYSTEM_ARCHITECTURE.md](../SYSTEM_ARCHITECTURE.md) - Overall architecture

### **External Style Guides**
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Bash Hackers Wiki](https://wiki.bash-hackers.org/)
- [ShellCheck](https://www.shellcheck.net/) - Automated shell script analysis

### **Security Resources**
- [OWASP Command Injection Prevention](https://owasp.org/www-community/attacks/Command_Injection)
- [CWE-78: OS Command Injection](https://cwe.mitre.org/data/definitions/78.html)

---

**Last Updated**: $(date)
**Status**: ACTIVE - Use this guide for all development
**Version**: 1.0 - Initial comprehensive style guide

This style guide reflects the A+ code quality standards achieved in the `critical-fixes` branch and should be followed for all future development.