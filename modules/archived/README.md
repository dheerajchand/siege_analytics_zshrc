# Archived modules

Modules that are no longer loaded by `zshrc` but kept in tree for
reference or easy revival. They are not sourced, not tested in CI, and
not maintained.

To re-enable one, `git mv` it back to `modules/` and add the
corresponding `load_module <name>` call in `zshrc`.
