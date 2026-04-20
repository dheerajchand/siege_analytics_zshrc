# Scripts

One-shot utilities that don't belong in a module because they're
long-running, language-switching, or purpose-specific. Modules may
shell out to these scripts.

## Active

- `zeppelin_seed_smoke_notebook.py` — referenced by
  `modules/zeppelin.zsh`. Creates a Zeppelin notebook that mixes
  Scala and Python cells to validate Sedona + GraphFrames interop.

## Archived (`archived/`)

- `fix_family_private_mac.zsh` — one-off migration helper for
  resolving the "gitlab personal access token" item in the Family
  private vault. Kept for historical reference; not called from
  anywhere.
