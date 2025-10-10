# System Architecture - ZSH Configuration System

## Overview

The ZSH Configuration System uses a **three-tier modular architecture** with on-demand loading, hostile testing, and enterprise-grade security.

```
┌─────────────────────────────────────────────────────────────────┐
│                        ZSH SYSTEM ARCHITECTURE                  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│ TIER 1: MINIMAL CORE (<0.5s startup)                           │
├─────────────────────────────────────────────────────────────────┤
│ • Essential PATH setup                                          │
│ • Basic aliases and prompt                                      │
│ • Oh-My-Zsh minimal plugins                                     │
│ • Module loading system (load_module function)                 │
│ • Context detection (Docker, Claude Code, IDE)                 │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ TIER 2: AUTO-LOADED MODULES (Staggered Mode)                   │
├─────────────────────────────────────────────────────────────────┤
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ │
│ │   utils     │ │   python    │ │  database   │ │    docker   │ │
│ │  module     │ │   module    │ │   module    │ │   module    │ │
│ └─────────────┘ └─────────────┘ └─────────────┘ └─────────────┘ │
│ ┌─────────────┐ ┌─────────────┐                                │
│ │ javascript  │ │    spark    │                                │
│ │   module    │ │   module    │                                │
│ └─────────────┘ └─────────────┘                                │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│ TIER 3: SECURITY & CONFIGURATION LAYER                         │
├─────────────────────────────────────────────────────────────────┤
│ • credentials.zsh - Multi-backend credential management         │
│ • environment.zsh - Environment variable management            │
│ • variables.zsh - System configuration variables               │
│ • Hostile testing framework                                     │
└─────────────────────────────────────────────────────────────────┘
```

## Module Loading System

### Context-Aware Loading

```
┌─────────────────────────────────────────────────────────────────┐
│                     CONTEXT DETECTION                          │
└─────────────────────────────────────────────────────────────────┘

    Terminal Startup
           │
           ▼
    ┌─────────────┐
    │ Environment │
    │  Detection  │
    └─────────────┘
           │
           ├─── Docker Container? ──► Light Mode (minimal loading)
           │
           ├─── Claude Code? ──────► Staggered Mode + verbose output
           │
           ├─── IDE (PyCharm)? ────► Staggered Mode + compatibility fixes
           │
           └─── Development? ──────► Staggered Mode (default)

Light Mode:
┌─────────────────────────────────────────────────────────────────┐
│ • Basic shell only                                              │
│ • Instructions to enable full functionality                     │
│ • ZSH_MODE=staggered exec zsh to upgrade                       │
└─────────────────────────────────────────────────────────────────┘

Staggered Mode:
┌─────────────────────────────────────────────────────────────────┐
│ • All modules auto-loaded                                       │
│ • Full development environment                                  │
│ • Background services available                                 │
└─────────────────────────────────────────────────────────────────┘
```

### Module Dependency Graph

```
                    load_module()
                         │
                         ▼
              ┌─────────────────────┐
              │     utils.zsh       │ ◄─── Base for all modules
              │  (mkcd, extract,    │
              │   backup, findtext) │
              └─────────────────────┘
                         │
         ┌───────────────┼───────────────┐
         ▼               ▼               ▼
   ┌──────────┐  ┌──────────────┐  ┌──────────┐
   │ python   │  │   docker     │  │database  │
   │ module   │  │   module     │  │ module   │
   └──────────┘  └──────────────┘  └──────────┘
         │               │               │
         │               │               └──► Credential System
         │               │
         ▼               ▼
   ┌──────────┐  ┌──────────────┐
   │  spark   │  │ javascript   │
   │ module   │  │   module     │
   └──────────┘  └──────────────┘
         │
         ▼
   ┌──────────┐
   │ hadoop   │
   │ module   │
   └──────────┘

Dependencies:
• spark module → python module → utils module
• database module → credential system
• All modules → utils module (base functions)
```

## Security Architecture

### Credential Management System

```
┌─────────────────────────────────────────────────────────────────┐
│                 CREDENTIAL SECURITY LAYER                      │
└─────────────────────────────────────────────────────────────────┘

Application Layer
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Database Functions (pg_connect, mysql_connect, etc.)           │
│ • setup_postgres_credentials()                                 │
│ • setup_mysql_credentials()                                    │
│ • setup_snowflake_credentials()                               │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Credential Management API                                       │
│ • get_credential(service, user, field)                        │
│ • store_credential(service, user, data)                       │
│ • credential_backend_status()                                 │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Multi-Backend Storage                                          │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │
│ │   1Password     │ │  macOS Keychain │ │  Linux Keyring  │    │
│ │   (preferred)   │ │   (fallback)    │ │   (fallback)    │    │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘    │
└─────────────────────────────────────────────────────────────────┘

Security Features:
• Encrypted storage only (no plain text)
• Zero information disclosure in error messages
• Command injection resistance
• Backend failover and detection
```

### Hostile Testing Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                    HOSTILE TESTING FRAMEWORK                   │
└─────────────────────────────────────────────────────────────────┘

Production Code
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Function Implementation                                         │
│ • mkcd(), command_exists(), pg_connect(), etc.                │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Hostile Test Suite                                             │
│ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐    │
│ │   Injection     │ │   Resource      │ │ Race Condition  │    │
│ │   Resistance    │ │   Exhaustion    │ │   Testing       │    │
│ │   Testing       │ │   Testing       │ │                 │    │
│ └─────────────────┘ └─────────────────┘ └─────────────────┘    │
│ ┌─────────────────┐ ┌─────────────────┐                       │
│ │  Information    │ │  Environmental  │                       │
│ │  Disclosure     │ │     Attack      │                       │
│ │  Prevention     │ │    Testing      │                       │
│ └─────────────────┘ └─────────────────┘                       │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Production Readiness Certification                             │
│ • 11/11 hostile tests passing                                  │
│ • Zero critical vulnerabilities                                │
│ • 100% security compliance                                     │
└─────────────────────────────────────────────────────────────────┘
```

## Function Interdependence Map

### Core Function Dependencies

```
                      command_exists()
                           │
                           ▼
              ┌─────────────────────────┐
              │     All Functions       │
              │ (validate dependencies) │
              └─────────────────────────┘
                           │
         ┌─────────────────┼─────────────────┐
         ▼                 ▼                 ▼
   ┌──────────┐     ┌─────────────┐   ┌─────────────┐
   │ is_online│     │    mkcd     │   │  path_add   │
   │    ()    │     │     ()      │   │     ()      │
   └──────────┘     └─────────────┘   └─────────────┘
         │                 │                 │
         ▼                 ▼                 ▼
   Network-dependent  Directory-based    PATH management
   operations         operations         functions
```

### Module Function Dependencies

```
Python Module Functions:
┌─────────────────────────────────────────────────────────────────┐
│ py_env_switch() ──► command_exists() ──► pyenv, uv              │
│       │                                                         │
│       ▼                                                         │
│ ds_project_init() ──► mkcd() ──► py_env_switch()               │
│       │                                                         │
│       ▼                                                         │
│ python_info() ──► command_exists() ──► python, pip, uv        │
└─────────────────────────────────────────────────────────────────┘

Database Module Functions:
┌─────────────────────────────────────────────────────────────────┐
│ setup_postgres_credentials() ──► get_credential()              │
│            │                           │                       │
│            ▼                           ▼                       │
│ pg_connect() ──► setup_postgres_credentials()                  │
│            │                           │                       │
│            ▼                           ▼                       │
│ pg_status() ──► command_exists() ──► psql, pg_isready         │
└─────────────────────────────────────────────────────────────────┘

Docker Module Functions:
┌─────────────────────────────────────────────────────────────────┐
│ setup_docker_environment() ──► command_exists() ──► docker     │
│            │                                                    │
│            ▼                                                    │
│ docker_status() ──► setup_docker_environment()                │
│            │                                                    │
│            ▼                                                    │
│ docker_cleanup() ──► docker_status() ──► command_exists()     │
└─────────────────────────────────────────────────────────────────┘
```

### Service Integration Flow

```
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE INTEGRATION                         │
└─────────────────────────────────────────────────────────────────┘

User Command: smart_spark_submit analysis.py
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 1. Environment Detection                                        │
│    • is_online() ──► Network availability                      │
│    • command_exists() ──► Spark installation check            │
│    • detect_platform() ──► Resource optimization              │
└─────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Dependency Validation                                        │
│    • hadoop_status() ──► HDFS availability                    │
│    • spark_status() ──► Spark cluster status                 │
│    • python_info() ──► Python environment validation         │
└─────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Resource Allocation                                          │
│    • Memory allocation based on platform                       │
│    • CPU core detection                                        │
│    • Storage space validation                                  │
└─────────────────────────────────────────────────────────────────┘
            │
            ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. Job Submission                                              │
│    • Spark job submission with optimized parameters           │
│    • Real-time monitoring                                      │
│    • Error handling and recovery                              │
└─────────────────────────────────────────────────────────────────┘
```

## Performance Architecture

### Startup Optimization

```
Shell Startup (Target: <0.5s)
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Tier 1: Immediate (0-100ms)                                    │
│ • Essential PATH setup                                          │
│ • Prompt configuration                                          │
│ • Basic aliases                                                 │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Tier 2: Fast Loading (100-300ms)                              │
│ • Context detection                                            │
│ • Module system initialization                                 │
│ • Oh-My-Zsh minimal plugins                                   │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Tier 3: Background/Lazy (300-500ms)                           │
│ • Auto-loaded modules (if staggered mode)                     │
│ • Environment variable setup                                   │
│ • Service status checking                                      │
└─────────────────────────────────────────────────────────────────┘

Background Services (Optional):
┌─────────────────────────────────────────────────────────────────┐
│ • path-optimizer: Background PATH cleanup                      │
│ • environment-setup: Environment variable caching             │
│ • health-monitor: System health monitoring                     │
└─────────────────────────────────────────────────────────────────┘
```

### Memory Management

```
Memory Usage Profile:
┌─────────────────────────────────────────────────────────────────┐
│ Minimal Core:        ~2MB   (essential functions only)         │
│ + Utils Module:      ~1MB   (backup, extract, findtext)       │
│ + Python Module:     ~1MB   (environment switching)           │
│ + Database Module:   ~0.5MB (credential management)           │
│ + Docker Module:     ~0.5MB (container management)            │
│ + Spark Module:      ~1MB   (big data processing)             │
│ + All Modules:       ~6MB   (complete system)                 │
└─────────────────────────────────────────────────────────────────┘

Resource Limits:
• Startup time: <0.5s (minimal), <2s (full)
• Memory usage: <10MB total
• PATH length: <500 characters
• Function count: <100 functions
```

## Error Handling and Recovery

### Failure Recovery Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     FAILURE RECOVERY                           │
└─────────────────────────────────────────────────────────────────┘

Function Call
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 1. Pre-Execution Validation                                    │
│    • command_exists() checks                                   │
│    • Parameter validation                                       │
│    • Resource availability                                      │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 2. Protected Execution                                          │
│    • Error trapping (set -e disabled where needed)            │
│    • Output redirection                                        │
│    • Timeout handling                                          │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 3. Graceful Degradation                                        │
│    • Fallback mechanisms                                       │
│    • Alternative implementations                               │
│    • User-friendly error messages                             │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ 4. State Recovery                                              │
│    • Original directory restoration                            │
│    • Environment variable cleanup                              │
│    • Process cleanup                                           │
└─────────────────────────────────────────────────────────────────┘

Examples:
• mkcd() → Failed directory creation → Stay in original directory
• pg_connect() → Connection failure → Show available databases
• spark_submit() → Cluster unavailable → Fall back to local mode
```

## Testing Integration

### Hostile Testing Integration

```
┌─────────────────────────────────────────────────────────────────┐
│                   TESTING ARCHITECTURE                         │
└─────────────────────────────────────────────────────────────────┘

Development
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Code Implementation                                             │
│ • Function development                                          │
│ • Error handling                                               │
│ • Input validation                                             │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Hostile Testing (Mandatory)                                    │
│ • Security vulnerability tests                                 │
│ • Resource exhaustion tests                                    │
│ • Race condition tests                                         │
│ • Environmental attack tests                                   │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼ (All tests must pass)
┌─────────────────────────────────────────────────────────────────┐
│ Production Certification                                        │
│ • hostile-comprehensive-final.zsh: 11/11 PASSING              │
│ • Zero critical vulnerabilities                                │
│ • 100% security compliance                                     │
└─────────────────────────────────────────────────────────────────┘
      │
      ▼
┌─────────────────────────────────────────────────────────────────┐
│ Deployment                                                      │
│ • Production-ready code                                         │
│ • Security validated                                           │
│ • Performance tested                                           │
└─────────────────────────────────────────────────────────────────┘
```

This architecture ensures the ZSH configuration system is secure, performant, and reliable for enterprise development environments while maintaining the flexibility needed for data science and software development workflows.