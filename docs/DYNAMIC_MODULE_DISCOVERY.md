# Dynamic Module Discovery System

## Overview

The zsh configuration uses a **dynamic module discovery system** that automatically detects and loads modules based on the current shell mode. This eliminates hardcoding and ensures consistency across all modes.

## Architecture

### Module Discovery

```bash
# Automatically discover all available modules
ALL_MODULES=($(find "$ZSH_CONFIG_MODULES" -name "*.zsh" -exec basename {} .zsh \; 2>/dev/null))
```

The system scans `~/.config/zsh/config/` for all `.zsh` files and creates an array of module names.

### Mode Configuration

```bash
# Manually specify only what should be in light mode
MODULES_LIGHT=("core" "environment" "paths")

# Heavy mode = Everything - Light mode (set difference)
MODULES_HEAVY=($(printf '%s\n' "${ALL_MODULES[@]}" "${MODULES_LIGHT[@]}" | sort | uniq -u))
```

## Shell Modes

### Light Mode
- **Purpose**: Minimal configuration for context-aware loading
- **Modules**: Only manually specified modules (`core`, `environment`, `paths`)
- **Use Case**: CI/CD, remote servers, minimal environments

### Heavy Mode  
- **Purpose**: Full development environment
- **Modules**: All discovered modules (light + heavy)
- **Use Case**: Local development, full-featured terminals

### Staggered Mode
- **Purpose**: Progressive loading for IDEs
- **Phase 1**: Load light modules immediately
- **Phase 2**: Load heavy modules progressively in background
- **Use Case**: JetBrains IDEs, slow startup scenarios

## Module Loading Functions

### `load_module(module_name)`
Safely loads a single module with error handling.

```bash
load_module "jetbrains"  # Loads jetbrains.zsh
```

### `load_modules(module_array)`
Loads multiple modules and reports success.

```bash
load_modules "${MODULES_LIGHT[@]}"  # Load all light modules
```

## Powerlevel10k Integration

The system respects Powerlevel10k's instant prompt mode and suppresses console output during initialization to prevent warnings.

```bash
# Only output messages when not in instant prompt mode
[[ -z "$POWERLEVEL9K_INSTANT_PROMPT" ]] && echo "Loading modules..."
```

## Benefits

### ✅ Zero Hardcoding
- New modules automatically discovered
- No need to update multiple mode configurations
- Impossible to forget modules in different modes

### ✅ Consistency
- Set operations ensure `HEAVY = ALL - LIGHT`
- No duplicate module definitions
- Automatic module inclusion

### ✅ Maintenance-Free
- Add `new_module.zsh` → automatically available in heavy/staggered
- Only add to `MODULES_LIGHT` if needed in light mode
- Self-maintaining system

### ✅ Performance Optimized
- Light mode: minimal modules for context-aware loading
- Staggered mode: progressive loading for IDEs
- Heavy mode: full functionality when needed

## Usage Examples

### Adding a New Module

1. **Create the module file**:
   ```bash
   touch ~/.config/zsh/config/new_feature.zsh
   ```

2. **Module is automatically available** in heavy and staggered modes

3. **Add to light mode** if needed:
   ```bash
   MODULES_LIGHT=("core" "environment" "paths" "new_feature")
   ```

### Checking Module Status

```bash
# See all discovered modules
echo "All modules: ${ALL_MODULES[*]}"
echo "Light modules: ${MODULES_LIGHT[*]}"
echo "Heavy modules: ${MODULES_HEAVY[*]}"

# Check current mode
echo "Current mode: $ZSH_MODE"
```

## Troubleshooting

### Module Not Loading
1. Check file exists: `ls -la ~/.config/zsh/config/module_name.zsh`
2. Check syntax: `zsh -n ~/.config/zsh/config/module_name.zsh`
3. Check discovery: `echo "${ALL_MODULES[*]}"`

### Console Output Issues
- System automatically suppresses output during Powerlevel10k instant prompt
- Messages only appear during normal initialization

### Mode Detection Issues
```bash
# Force specific mode
export ZSH_MODE="heavy"
exec zsh

# Check mode detection
detect_zsh_mode
```

## Implementation Details

### Set Operations
The system uses Unix `sort` and `uniq` commands to perform set difference:
```bash
# HEAVY = ALL - LIGHT
MODULES_HEAVY=($(printf '%s\n' "${ALL_MODULES[@]}" "${MODULES_LIGHT[@]}" | sort | uniq -u))
```

### Error Handling
All module loading includes error handling and graceful degradation:
```bash
source "$module_file" 2>/dev/null || echo "⚠️  ${module_name} module had warnings"
```

### Background Loading
Staggered mode uses background processes for progressive loading:
```bash
(load_modules "${MODULES_HEAVY[@]}") &
```

This system provides a robust, maintainable, and performant module loading architecture that scales automatically with new modules while maintaining consistency across all shell modes.
