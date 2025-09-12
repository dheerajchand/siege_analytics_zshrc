# Docker Context Switching

This document describes the Docker context switching functionality added to the modular zsh configuration system.

## Overview

The Docker module now supports switching between different container runtimes (Docker Desktop and Rancher Desktop) seamlessly. This solves the common issue of having both Docker Desktop and Rancher Desktop installed, where they can conflict with each other.

## Features

### Environment Variables

- `DEFAULT_CONTAINER_RUNTIME`: Sets the preferred container runtime (defaults to `rancher-desktop`)
- `CURRENT_DOCKER_CONTEXT`: Tracks the currently active Docker context

### Functions

#### `switch_docker_context(context)`

Intelligently switches between Docker Desktop and Rancher Desktop contexts with automatic startup and fallback.

**Parameters:**
- `context`: The context to switch to (`rancher-desktop`, `docker-desktop`, `rancher`, or `docker`)

**Usage:**
```bash
switch_docker_context rancher-desktop
switch_docker_context docker-desktop
```

**Enhanced Behavior:**
1. **Attempts to switch** to the specified context
2. **If runtime not running**: Automatically starts it with progress indicators
3. **Waits for startup**: Shows countdown timer during initialization
4. **Smart fallback**: If startup fails, tries the other runtime
5. **Sets context**: Updates `CURRENT_DOCKER_CONTEXT` environment variable
6. **Clear feedback**: Provides success/failure messages with emojis

**Startup Process:**
- Shows "⚠️ [Runtime] not ready, attempting to start..."
- Displays "⏳ Waiting for [Runtime] to start... (X seconds remaining)"
- On success: "✅ [Runtime] started successfully"
- On failure: Falls back to other runtime or reports both failed

#### `auto_switch_docker_context()`

Automatically switches to the preferred container runtime based on `DEFAULT_CONTAINER_RUNTIME`.

**Usage:**
```bash
auto_switch_docker_context
```

### Aliases

#### Smart Switching Aliases
- `docker-switch-rancher`: Switch to Rancher Desktop (auto-start with fallback)
- `docker-switch-docker`: Switch to Docker Desktop (auto-start with fallback)

#### Direct Starting Aliases  
- `start-rancher`: Start Rancher Desktop (with fallback to Docker Desktop)
- `start-docker`: Start Docker Desktop (with fallback to Rancher Desktop)

#### Status and Context Aliases
- `docker-context`: List all available Docker contexts
- `docker-status`: Show current Docker status and context

## Configuration

### Setting Default Container Runtime

You can set your preferred container runtime by setting the `DEFAULT_CONTAINER_RUNTIME` environment variable:

```bash
# In your shell profile or environment
export DEFAULT_CONTAINER_RUNTIME="rancher-desktop"  # or "docker-desktop"
```

### Automatic Context Switching

The Docker module automatically attempts to switch to your preferred context when it loads. This happens in the `ensure_docker_available()` function.

## Usage Examples

### Basic Context Switching

```bash
# Switch to Rancher Desktop (auto-starts if not running)
docker-switch-rancher

# Switch to Docker Desktop (auto-starts if not running)
docker-switch-docker

# Check current context
docker-context
```

### Direct Runtime Starting

```bash
# Start Rancher Desktop (with fallback to Docker Desktop)
start-rancher

# Start Docker Desktop (with fallback to Rancher Desktop)  
start-docker
```

### Checking Status

```bash
# Show Docker status
docker-status

# List all contexts
docker context ls
```

### Programmatic Usage

```bash
# Switch context programmatically
switch_docker_context rancher-desktop

# Auto-switch to default
auto_switch_docker_context
```

## Integration with Three-Tier System

The Docker context switching integrates with the three-tier zsh loading system:

- **Light Mode**: Docker context switching is available but not auto-executed
- **Staggered Mode**: Docker context switching happens in the background during progressive loading
- **Heavy Mode**: Docker context switching happens immediately during full module loading

## Troubleshooting

### Common Issues

1. **"Cannot connect to Docker daemon"**
   - The target container runtime may not be running
   - The system will automatically fall back to the other context

2. **Context switching fails**
   - Ensure both Docker Desktop and Rancher Desktop are installed
   - Check that the target context exists with `docker context ls`

3. **Auto-switching doesn't work**
   - Verify `DEFAULT_CONTAINER_RUNTIME` is set correctly
   - Check that the preferred runtime is installed and running

### Debug Commands

```bash
# Check current context
docker context ls

# Check environment variables
echo "DEFAULT_CONTAINER_RUNTIME: $DEFAULT_CONTAINER_RUNTIME"
echo "CURRENT_DOCKER_CONTEXT: $CURRENT_DOCKER_CONTEXT"

# Test context switching manually
switch_docker_context rancher-desktop
switch_docker_context docker-desktop
```

## Benefits

1. **No More Conflicts**: Eliminates conflicts between Docker Desktop and Rancher Desktop
2. **Automatic Fallback**: If your preferred runtime isn't available, it falls back to the other
3. **Seamless Switching**: Easy switching between runtimes without manual configuration
4. **IDE Integration**: Works seamlessly with the staggered mode for JetBrains IDEs
5. **Persistent Configuration**: Remembers your preferred runtime across sessions

## Future Enhancements

Potential future improvements could include:

- Support for additional container runtimes (Podman, etc.)
- Context-specific environment variables
- Automatic runtime detection based on project requirements
- Integration with Docker Compose for multi-runtime projects
