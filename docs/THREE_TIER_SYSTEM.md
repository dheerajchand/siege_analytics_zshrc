# Three-Tier ZSH Configuration System

## Overview

The three-tier ZSH configuration system provides intelligent, context-aware shell loading optimized for different environments and use cases. This system automatically detects the execution context and loads the appropriate configuration mode.

## Modes

### 🚀 Light Mode
**Purpose**: Minimal configuration for context-aware loading
**Use Cases**: CI/CD environments, slow connections, resource-constrained environments
**Loading**: Essential modules only (core, environment)
**Startup Time**: ~0.1 seconds

### ⚡ Staggered Mode  
**Purpose**: Progressive loading with balanced startup speed and functionality
**Use Cases**: JetBrains IDEs (DataSpell, PyCharm, IntelliJ, etc.)
**Loading**: Essential modules first, then additional modules in background
**Startup Time**: ~0.2 seconds initial, full functionality after 2 seconds

### 🔥 Heavy Mode
**Purpose**: Full configuration with all features
**Use Cases**: Regular terminals, development workstations
**Loading**: All modules loaded immediately
**Startup Time**: ~2-5 seconds

## Automatic Detection

The system automatically detects the appropriate mode based on:

### JetBrains IDEs → Staggered Mode
- **Environment Variables**: `JETBRAINS_IDE`, `PYCHARM_HOSTED`, `DATASPELL_IDE`, `TERM_PROGRAM`
- **Parent Process Detection**: Checks for `pycharm`, `dataspell`, `intellij`, `webstorm`, `clion`, `goland`
- **Rationale**: IDEs need context-aware loading but benefit from progressive enhancement

### CI/CD Environments → Light Mode
- **Environment Variables**: `CI`, `GITHUB_ACTIONS`, `JENKINS_URL`
- **Rationale**: CI environments need minimal overhead and fast execution

### Slow Connections → Light Mode
- **Environment Variable**: `SLOW_CONNECTION=true`
- **Rationale**: Avoid heavy network-dependent modules

### Manual Override
- **Environment Variable**: `ZSH_MODE=light|staggered|heavy`
- **Rationale**: Allow explicit control when needed

## Configuration Architecture

### Main ZSHRC Integration
```bash
# ~/.zshrc (main file)
source ~/.config/zsh/zshrc  # Load modular configuration FIRST
# ... rest of configuration (only loads in heavy mode)
```

### Modular Configuration
```bash
# ~/.config/zsh/zshrc (modular file)
# 1. Detect mode
# 2. Load appropriate configuration
# 3. Exit early for light/staggered modes
```

## Progressive Loading (Staggered Mode)

### Phase 1: Immediate Loading
- Core shell functions
- Environment detection
- JetBrains-specific optimizations
- Essential PATH configuration

### Phase 2: Background Loading (after 2 seconds)
- Credentials management
- Database configurations
- Status modules
- Additional utilities

## Commands

### Mode Control
```bash
zsh-mode          # Show current mode status
zsh-toggle        # Switch between light/heavy mode
zsh-light         # Force light mode
zsh-heavy         # Force heavy mode
```

### JetBrains Integration
```bash
jetbrains-status     # Show JetBrains configuration status
upgrade_jetbrains_shell  # Load full configuration immediately
```

## Benefits

### Performance
- **Fast IDE Startup**: No more 1+ minute DataSpell/PyCharm loading times
- **Progressive Enhancement**: Gets better over time without blocking
- **Resource Efficiency**: Light mode uses minimal resources

### User Experience
- **Context Awareness**: Automatically adapts to environment
- **Manual Control**: Override when needed
- **Consistent Interface**: Same commands work in all modes

### Development Workflow
- **IDE Optimization**: JetBrains IDEs get context-aware loading + full functionality
- **CI/CD Friendly**: Light mode for automated environments
- **Flexible**: Easy to customize for different use cases

## Implementation Details

### Detection Logic
```bash
detect_zsh_mode() {
    # Manual override (highest priority)
    if [[ "$ZSH_MODE" == "light" ]]; then echo "light"; return; fi
    if [[ "$ZSH_MODE" == "staggered" ]]; then echo "staggered"; return; fi
    if [[ "$ZSH_MODE" == "heavy" ]]; then echo "heavy"; return; fi
    
    # JetBrains IDEs → staggered
    if [[ "$parent_process" == *"pycharm"* ]]; then echo "staggered"; return; fi
    
    # CI/CD → light
    if [[ -n "$CI" ]]; then echo "light"; return; fi
    
    # Default → heavy
    echo "heavy"
}
```

### Early Exit Strategy
```bash
# Light/Staggered modes exit early to prevent heavy module loading
if [[ "$ZSH_MODE" == "light" ]]; then
    # Load minimal configuration
    exit 0  # Stop main zshrc execution
fi
```

## Troubleshooting

### Mode Not Detected
- Check parent process: `ps -p $PPID -o comm=`
- Verify environment variables
- Use manual override: `export ZSH_MODE=staggered`

### Still Slow Startup
- Ensure modular zshrc is sourced early in main zshrc
- Check for heavy modules loading before detection
- Verify early exit is working

### Missing Functions
- In light mode: Use `zsh-heavy` to load full configuration
- In staggered mode: Wait for background loading or use `upgrade_jetbrains_shell`

## Future Enhancements

- **Smart Caching**: Cache loaded modules for optimized subsequent loading
- **Adaptive Loading**: Adjust loading based on system performance
- **Plugin System**: Allow third-party mode definitions
- **Metrics**: Track startup times and optimize accordingly
