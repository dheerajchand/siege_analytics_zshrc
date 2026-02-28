# Backlog

Back: [Home](Home)

## Open
No open backlog tickets.

## Closed

1. Standardize config directory variable usage
- Status: closed
- Notes: Canonical `ZSHRC_CONFIG_DIR` adopted with fallback to `ZSH_CONFIG_DIR`.

2. Restore missing quick-command workflows used in docs
- Status: closed
- Notes: Added wrappers/functions in `modules/utils.zsh` (`setup_pyenv`, `setup_uv`, `toggle_hidden_files`, `toggle_key_repeat`, `test_*` helpers).

3. Remove personal hardcoded PostgreSQL default user
- Status: closed
- Notes: Added `DEFAULT_PG_USER` and `PGUSER` fallback chain.

4. Codify `eval` safety policy
- Status: closed
- Notes: Added explicit allowlist and restrictions in [Coding Standards](Coding-Standards).

5. Wiki navigation/link integrity hardening
- Status: closed
- Notes: Added wiki link and stale-command tests; fixed stale references.
