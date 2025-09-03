#!/usr/bin/env zsh

# =============================================================================
# Bash Installation and Compatibility Tests
# =============================================================================

# Source the test framework
source "$(dirname "$0")/../test-framework.zsh"

# =============================================================================
# Test: Bash Compatibility Installation
# =============================================================================

test_bash_compatibility_installation() {
    echo "Testing bash compatibility installation..."
    
    # Test that bash compatibility script exists
    assert_file_exists "$(dirname "$0")/../install-bash-compatibility.sh" "Bash compatibility installer should exist"
    
    # Test that bash compatibility script is executable
    assert_command_success "test -x '$(dirname "$0")/../install-bash-compatibility.sh'" "Bash compatibility installer should be executable"
    
    # Test that bash compatibility layer exists
    assert_file_exists "$(dirname "$0")/../bash-compatibility.zsh" "Bash compatibility layer should exist"
    
    echo "✅ bash compatibility installation tests passed"
}

# =============================================================================
# Test: Quick Install Script
# =============================================================================

test_quick_install_script() {
    echo "Testing quick install script..."
    
    # Test that quick install script exists
    assert_file_exists "$(dirname "$0")/../quick-install-bash.sh" "Quick install script should exist"
    
    # Test that quick install script is executable
    assert_command_success "test -x '$(dirname "$0")/../quick-install-bash.sh'" "Quick install script should be executable"
    
    # Test that script has proper shebang
    local shebang
    shebang=$(head -1 "$(dirname "$0")/../quick-install-bash.sh")
    assert_contains "$shebang" "#!/bin/bash" "Quick install script should have bash shebang"
    
    echo "✅ quick install script tests passed"
}

# =============================================================================
# Test: Full Install Script
# =============================================================================

test_full_install_script() {
    echo "Testing full install script..."
    
    # Test that full install script exists
    assert_file_exists "$(dirname "$0")/../install-for-bash.sh" "Full install script should exist"
    
    # Test that full install script is executable
    assert_command_success "test -x '$(dirname "$0")/../install-for-bash.sh'" "Full install script should be executable"
    
    # Test that script has proper shebang
    local shebang
    shebang=$(head -1 "$(dirname "$0")/../install-for-bash.sh")
    assert_contains "$shebang" "#!/bin/bash" "Full install script should have bash shebang"
    
    # Test that script contains required functions
    local script_content
    script_content=$(cat "$(dirname "$0")/../install-for-bash.sh")
    assert_contains "$script_content" "install_sdkman" "Script should contain SDKMAN installation"
    assert_contains "$script_content" "install_java" "Script should contain Java installation"
    assert_contains "$script_content" "install_spark" "Script should contain Spark installation"
    assert_contains "$script_content" "install_hadoop" "Script should contain Hadoop installation"
    
    echo "✅ full install script tests passed"
}

# =============================================================================
# Test: Bash Compatibility Layer Functions
# =============================================================================

test_bash_compatibility_functions() {
    echo "Testing bash compatibility layer functions..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    
    # Test shell detection
    local detected_shell
    detected_shell=$(detect_shell)
    assert_equal "zsh" "$detected_shell" "Should detect zsh shell"
    
    # Test platform detection
    local detected_platform
    detected_platform=$(detect_platform)
    assert_equal "macos" "$detected_platform" "Should detect macOS platform"
    
    # Test compatibility initialization
    init_compatibility
    assert_equal "zsh" "$CURRENT_SHELL" "CURRENT_SHELL should be zsh"
    assert_equal "macos" "$PLATFORM" "PLATFORM should be macos"
    assert_equal "true" "$IS_ZSH" "IS_ZSH should be true"
    assert_equal "false" "$IS_BASH" "IS_BASH should be false"
    
    echo "✅ bash compatibility layer functions tests passed"
}

# =============================================================================
# Test: Cross-Shell Function Translation
# =============================================================================

test_cross_shell_function_translation() {
    echo "Testing cross-shell function translation..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    
    # Test that functions are available
    assert_command_success "type setup_python_manager" "setup_python_manager should be available"
    assert_command_success "type setup_spark" "setup_spark should be available"
    assert_command_success "type setup_hadoop" "setup_hadoop should be available"
    assert_command_success "type setup_yarn" "setup_yarn should be available"
    assert_command_success "type setup_jupyter" "setup_jupyter should be available"
    assert_command_success "type backup" "backup should be available"
    assert_command_success "type test_system" "test_system should be available"
    
    echo "✅ cross-shell function translation tests passed"
}

# =============================================================================
# Test: Environment Variable Setup
# =============================================================================

test_environment_variable_setup() {
    echo "Testing environment variable setup..."
    
    # Source the bash compatibility layer
    source "$(dirname "$0")/../bash-compatibility.zsh"
    init_compatibility
    
    # Test that environment variables are set
    assert_var_set "CURRENT_SHELL" "CURRENT_SHELL should be set"
    assert_var_set "PLATFORM" "PLATFORM should be set"
    assert_var_set "IS_ZSH" "IS_ZSH should be set"
    assert_var_set "IS_BASH" "IS_BASH should be set"
    assert_var_set "ZSHRC_CONFIG_DIR" "ZSHRC_CONFIG_DIR should be set"
    assert_var_set "ZSHRC_BACKUPS" "ZSHRC_BACKUPS should be set"
    
    # Test that values are correct
    assert_equal "zsh" "$CURRENT_SHELL" "CURRENT_SHELL should be zsh"
    assert_equal "macos" "$PLATFORM" "PLATFORM should be macos"
    assert_equal "true" "$IS_ZSH" "IS_ZSH should be true"
    assert_equal "false" "$IS_BASH" "IS_BASH should be false"
    
    echo "✅ environment variable setup tests passed"
}

# =============================================================================
# Test: Installation Script Validation
# =============================================================================

test_installation_script_validation() {
    echo "Testing installation script validation..."
    
    # Test quick install script syntax
    assert_command_success "bash -n '$(dirname "$0")/../quick-install-bash.sh'" "Quick install script should have valid bash syntax"
    
    # Test full install script syntax
    assert_command_success "bash -n '$(dirname "$0")/../install-for-bash.sh'" "Full install script should have valid bash syntax"
    
    # Test bash compatibility installer syntax
    assert_command_success "bash -n '$(dirname "$0")/../install-bash-compatibility.sh'" "Bash compatibility installer should have valid bash syntax"
    
    echo "✅ installation script validation tests passed"
}

# =============================================================================
# Test: Documentation Files
# =============================================================================

test_documentation_files() {
    echo "Testing documentation files..."
    
    # Test that bash user guide exists
    assert_file_exists "$(dirname "$0")/../wiki/Bash-User-Guide.md" "Bash user guide should exist"
    
    # Test that bash compatibility documentation exists
    assert_file_exists "$(dirname "$0")/../wiki/Bash-Compatibility.md" "Bash compatibility documentation should exist"
    
    # Test that documentation contains required sections
    local bash_guide_content
    bash_guide_content=$(cat "$(dirname "$0")/../wiki/Bash-User-Guide.md")
    assert_contains "$bash_guide_content" "Quick Installation" "Bash guide should contain installation section"
    assert_contains "$bash_guide_content" "Available Functions" "Bash guide should contain functions section"
    assert_contains "$bash_guide_content" "Troubleshooting" "Bash guide should contain troubleshooting section"
    
    echo "✅ documentation files tests passed"
}

# =============================================================================
# Test: GitHub Pages Setup
# =============================================================================

test_github_pages_setup() {
    echo "Testing GitHub Pages setup..."
    
    # Test that .nojekyll file exists
    assert_file_exists "$(dirname "$0")/../docs/.nojekyll" ".nojekyll file should exist"
    
    # Test that index.html exists
    assert_file_exists "$(dirname "$0")/../docs/index.html" "GitHub Pages index.html should exist"
    
    # Test that index.html contains required content
    local index_content
    index_content=$(cat "$(dirname "$0")/../docs/index.html")
    assert_contains "$index_content" "Siege Analytics" "Index should contain Siege Analytics branding"
    assert_contains "$index_content" "GitHub Wiki" "Index should contain GitHub Wiki link"
    assert_contains "$index_content" "Quick Installation" "Index should contain installation section"
    
    echo "✅ GitHub Pages setup tests passed"
}

# =============================================================================
# Test: Installation URLs
# =============================================================================

test_installation_urls() {
    echo "Testing installation URLs..."
    
    # Test that installation scripts contain correct URLs
    local quick_install_content
    quick_install_content=$(cat "$(dirname "$0")/../quick-install-bash.sh")
    assert_contains "$quick_install_content" "github.com/dheerajchand/siege_analytics_zshrc" "Quick install should contain correct repository URL"
    
    local full_install_content
    full_install_content=$(cat "$(dirname "$0")/../install-for-bash.sh")
    assert_contains "$full_install_content" "github.com/dheerajchand/siege_analytics_zshrc" "Full install should contain correct repository URL"
    
    echo "✅ installation URLs tests passed"
}

# =============================================================================
# Test: Bash Configuration Integration
# =============================================================================

test_bash_configuration_integration() {
    echo "Testing bash configuration integration..."
    
    # Test that scripts add proper configuration to .bashrc
    local quick_install_content
    quick_install_content=$(cat "$(dirname "$0")/../quick-install-bash.sh")
    assert_contains "$quick_install_content" "source.*bashrc" "Quick install should modify .bashrc"
    assert_contains "$quick_install_content" "bash-compatibility.zsh" "Quick install should source compatibility layer"
    
    local full_install_content
    full_install_content=$(cat "$(dirname "$0")/../install-for-bash.sh")
    assert_contains "$full_install_content" "configure_bash" "Full install should configure bash"
    assert_contains "$full_install_content" "bash-compatibility.zsh" "Full install should source compatibility layer"
    
    echo "✅ bash configuration integration tests passed"
}

# =============================================================================
# Test: Error Handling
# =============================================================================

test_installation_error_handling() {
    echo "Testing installation error handling..."
    
    # Test that scripts have proper error handling
    local quick_install_content
    quick_install_content=$(cat "$(dirname "$0")/../quick-install-bash.sh")
    assert_contains "$quick_install_content" "set -e" "Quick install should have error handling"
    
    local full_install_content
    full_install_content=$(cat "$(dirname "$0")/../install-for-bash.sh")
    assert_contains "$full_install_content" "set -e" "Full install should have error handling"
    assert_contains "$full_install_content" "trap.*ERR" "Full install should have error trap"
    
    echo "✅ installation error handling tests passed"
}

# =============================================================================
# Test: Cross-Platform Compatibility
# =============================================================================

test_cross_platform_compatibility() {
    echo "Testing cross-platform compatibility..."
    
    # Test that scripts detect different platforms
    local full_install_content
    full_install_content=$(cat "$(dirname "$0")/../install-for-bash.sh")
    assert_contains "$full_install_content" "detect_system" "Full install should detect system"
    assert_contains "$full_install_content" "macos" "Full install should support macOS"
    assert_contains "$full_install_content" "ubuntu" "Full install should support Ubuntu"
    assert_contains "$full_install_content" "redhat" "Full install should support RedHat"
    
    echo "✅ cross-platform compatibility tests passed"
}

# =============================================================================
# Test: Tool Installation Validation
# =============================================================================

test_tool_installation_validation() {
    echo "Testing tool installation validation..."
    
    # Test that scripts install required tools
    local full_install_content
    full_install_content=$(cat "$(dirname "$0")/../install-for-bash.sh")
    assert_contains "$full_install_content" "install_sdkman" "Full install should install SDKMAN"
    assert_contains "$full_install_content" "install_java" "Full install should install Java"
    assert_contains "$full_install_content" "install_spark" "Full install should install Spark"
    assert_contains "$full_install_content" "install_hadoop" "Full install should install Hadoop"
    assert_contains "$full_install_content" "install_python_tools" "Full install should install Python tools"
    
    echo "✅ tool installation validation tests passed"
}

# =============================================================================
# Register Tests
# =============================================================================

register_test "test_bash_compatibility_installation" "test_bash_compatibility_installation"
register_test "test_quick_install_script" "test_quick_install_script"
register_test "test_full_install_script" "test_full_install_script"
register_test "test_bash_compatibility_functions" "test_bash_compatibility_functions"
register_test "test_cross_shell_function_translation" "test_cross_shell_function_translation"
register_test "test_environment_variable_setup" "test_environment_variable_setup"
register_test "test_installation_script_validation" "test_installation_script_validation"
register_test "test_documentation_files" "test_documentation_files"
register_test "test_github_pages_setup" "test_github_pages_setup"
register_test "test_installation_urls" "test_installation_urls"
register_test "test_bash_configuration_integration" "test_bash_configuration_integration"
register_test "test_installation_error_handling" "test_installation_error_handling"
register_test "test_cross_platform_compatibility" "test_cross_platform_compatibility"
register_test "test_tool_installation_validation" "test_tool_installation_validation"
