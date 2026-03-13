# Developer Welcome

Back: [Home](Home)

## Repository Overview

This repository (`siege_analytics_zshrc`) is a modular zsh configuration system. It manages shell environment setup, secrets, data platform tooling (Spark, Hadoop, Databricks), Python environments, Docker helpers, and more.

### Structure

```
.
├── zshrc                       # Main entry point, sourced by ~/.zshrc
├── modules/                    # Feature modules (one per concern)
│   ├── agents.zsh
│   ├── backup.zsh
│   ├── credentials.zsh
│   ├── database.zsh
│   ├── databricks.zsh
│   ├── docker.zsh
│   ├── python.zsh
│   ├── secrets.zsh
│   ├── settings.zsh
│   ├── spark-hadoop.zsh
│   ├── utils.zsh
│   └── ...
├── tests/                      # Test suites
│   ├── test-framework.zsh      # Assertion framework
│   ├── run-tests.zsh           # Test runner
│   ├── test-secrets.zsh
│   ├── test-databricks.zsh
│   └── ...
├── wiki/                       # Documentation (also GitHub wiki)
├── vars.env                    # Shared configuration variables
├── vars.mac.env                # macOS-specific variables
├── compatibility-matrix.json   # Spark/Hadoop version profiles
├── .github/workflows/          # CI (test + mirror)
└── CONTRIBUTING.md             # Contribution guidelines
```

### Module Loading

`zshrc` sources modules in dependency order. Each module:
1. Checks a guard variable to avoid double-loading.
2. Defines functions (prefixed by module name where appropriate).
3. Prints a loaded message (suppressed when `ZSH_TEST_MODE=1`).

## Setup

### Prerequisites

- macOS or Linux with zsh 5.8+
- git
- python3 (for compat module and JSON operations)
- Optional: 1Password CLI (`op`), pyenv, Docker

### Clone and Link

```bash
git clone git@github.com:dheerajchand/siege_analytics_zshrc.git ~/.config/zsh
```

Add to `~/.zshrc`:
```bash
source ~/.config/zsh/zshrc
```

### First Run

1. Copy example files:
   ```bash
   cp ~/.config/zsh/secrets.env.example ~/.config/zsh/secrets.env
   cp ~/.config/zsh/secrets.1p.example ~/.config/zsh/secrets.1p
   ```
2. Edit `secrets.env` with your values.
3. Open a new terminal — the banner should appear.

## Making Changes

1. Create a branch from `develop`:
   ```bash
   git checkout develop && git pull
   git checkout -b feature/my-change
   ```

2. Edit modules or add tests.

3. Run the test suite:
   ```bash
   zsh run-tests.zsh --verbose
   ```

4. Commit using [conventional commits](../CONTRIBUTING.md):
   ```bash
   git commit -m "feat: describe change"
   ```

5. Push and open a PR targeting `develop`:
   ```bash
   git push -u origin feature/my-change
   gh pr create --base develop
   ```

CI will run the `test` workflow. Once it passes, the PR can be merged.

## Key Commands

| Command | Description |
|---------|-------------|
| `zsh_help` | Show all available commands |
| `zshconfig` | Open config directory |
| `zshreboot` | Reload shell configuration |
| `backup "msg"` | Commit and push current branch |
| `secrets_profiles` | List available profiles |
| `python_status` | Show Python environment info |
| `zsh run-tests.zsh` | Run the test suite |

## Further Reading

- [CONTRIBUTING.md](../CONTRIBUTING.md) — Branching model, commit format, PR rules
- [Coding Standards](Coding-Standards) — Code style and patterns
- [Testing Guide](Testing-Guide) — How to write and run tests
- [Shell Operations Guide](Shell-Operations-Guide) — End-to-end workflows
- [Quick Start](Quick-Start) — Rapid setup guide
