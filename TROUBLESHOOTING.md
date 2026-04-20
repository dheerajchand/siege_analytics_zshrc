# Zsh Configuration Troubleshooting

## Common Issues and Solutions

### Test suite flakes with unexplained SIGPIPE / exit 141

Symptom: `tests/test-*.zsh` assertions of the form
`cmd | grep -q "..."` flake — sometimes pass, sometimes fail, with no
code change. The failing run returns exit 141.

Cause: `pipefail` is enabled globally somewhere. `grep -q` exits on
first match; upstream producer gets SIGPIPE; `pipefail` surfaces the
141 as the pipe's overall status, failing the assertion.

Fix: ensure `run-tests.zsh` does **not** enable `pipefail` globally
(test `conventions_runner_no_global_pipefail` guards this).
Inside individual tests that genuinely need strict mode, use
`emulate -L zsh` + `setopt pipefail` inside a function so the option
is scoped.

Workaround in a single assertion: capture output first, then grep the
variable, so there's no live pipe:

```zsh
out="$(cmd)"
echo "$out" | grep -q "..."
```

See [STYLE.md](STYLE.md) §Shell flags and GitHub issue #90 for the
full investigation.

### Python/Pyenv Not Working - "command not found: pip/python"

**Symptoms:**
- `pip` command not found
- `python` command not found
- `pyenv` exists but doesn't initialize properly
- `PYENV_VERSION` is set but tools still unavailable

**Root Cause:**
The `~/.zshrc` file is missing or not loading the modular configuration.

**Solution:**
Create a symlink from `~/.zshrc` to this modular config:

```bash
rm ~/.zshrc  # Remove if it exists
ln -s ~/.config/zsh/zshrc ~/.zshrc
ls -la ~/.zshrc  # Verify symlink created
```

**Verification:**
Open a new terminal and test:

```bash
which python pip pyenv
python --version
pip --version
```

All three commands should work and point to pyenv shims.

**Why This Happens:**
- Zsh loads `~/.zshrc` on startup
- If this file doesn't exist or doesn't source our config, nothing loads
- Pyenv initialization in `~/.config/zsh/modules/python.zsh` never runs
- Result: `$PATH` missing pyenv shims

---

### Claude CLI Crashes with JavaScript Error

**Symptoms:**
```bash
claude --version
# Shows JavaScript code instead of version
# Or crashes with long JavaScript output
```

**Root Cause:**
Corrupted or incompatible Claude CLI installation.

**Solution:**
Reinstall the Claude CLI:

```bash
npm uninstall -g @anthropic-ai/claude-code
npm install -g @anthropic-ai/claude-code
```

**Note:** This is a separate issue from the zsh/Python configuration.

---

### Configuration Not Loading After Fixes

**If Python still doesn't work after creating symlink:**

1. **Check the symlink:**
   ```bash
   ls -la ~/.zshrc
   # Should show: ~/.zshrc -> /Users/your user/.config/zsh/zshrc
   ```

2. **Reload your shell:**
   ```bash
   exec zsh  # Start fresh shell
   # OR
   source ~/.zshrc  # Reload in current shell
   ```

3. **Manual pyenv initialization (temporary fix):**
   ```bash
   eval "$(pyenv init --path)"
   eval "$(pyenv init -)"
   which python pip  # Should work now
   ```

4. **Check pyenv shims permissions:**
   ```bash
   ls -ld ~/.pyenv/shims
   # Should be: drwxr-xr-x
   chmod 755 ~/.pyenv/shims  # Fix if needed
   ```

---

### Pyenv Shims "Not Writable" Error

**Symptoms:**
```
pyenv: cannot rehash: /Users/username/.pyenv/shims isn't writable
```

**Solution:**
```bash
ls -ld ~/.pyenv/shims
chmod 755 ~/.pyenv/shims
```

**Extended Attributes Issue:**
If you see `@` in the permissions (e.g., `drwxr-xr-x@`), clear extended attributes:

```bash
xattr -lr ~/.pyenv/shims  # List extended attributes
xattr -cr ~/.pyenv/shims  # Clear them
```

---

### IDE-Specific Issues (PyCharm, DataSpell, VSCode)

**If Python works in terminal but not in IDE:**

1. **IDE terminal might not load login shells:**
   - PyCharm: Settings → Tools → Terminal → Shell path
   - Set to: `/bin/zsh --login`

2. **IDE might cache old Python path:**
   - File → Invalidate Caches → Restart

3. **Point IDE to correct Python:**
   ```bash
   # Find the Python path
   which python
   # Use this path in IDE interpreter settings
   ```

---

### Module Not Loading

**If a specific module fails to load:**

1. **Check module file exists:**
   ```bash
   ls -la ~/.config/zsh/modules/python.zsh
   ls -la ~/.config/zsh/modules/spark.zsh
   # etc.
   ```

2. **Check for syntax errors:**
   ```bash
   zsh -n ~/.config/zsh/modules/python.zsh  # Syntax check
   ```

3. **Load manually to see errors:**
   ```bash
   source ~/.config/zsh/modules/python.zsh
   # Watch for error messages
   ```

---

### Backup System Not Working

**If `backup` command fails:**

1. **Check if git repo initialized:**
   ```bash
   cd ~/.config/zsh
   git status
   ```

2. **Initialize if needed:**
   ```bash
   cd ~/.config/zsh
   git init
   git remote add origin <your-repo-url>
   ```

3. **Test backup:**
   ```bash
   backup "test commit"
   ```

---

## Quick Diagnostics

Run this diagnostic script to check your configuration:

```bash
#!/bin/bash
echo "=== ZSH Configuration Diagnostics ==="
echo ""

echo "1. Checking ~/.zshrc..."
if [ -L ~/.zshrc ]; then
    echo "   ✅ Symlink exists: $(readlink ~/.zshrc)"
else
    echo "   ❌ Not a symlink or doesn't exist"
fi
echo ""

echo "2. Checking pyenv..."
if command -v pyenv >/dev/null 2>&1; then
    echo "   ✅ pyenv found: $(which pyenv)"
    echo "   Version: $(pyenv --version)"
else
    echo "   ❌ pyenv not found"
fi
echo ""

echo "3. Checking Python..."
if command -v python >/dev/null 2>&1; then
    echo "   ✅ python found: $(which python)"
    echo "   Version: $(python --version)"
else
    echo "   ❌ python not found"
fi
echo ""

echo "4. Checking pip..."
if command -v pip >/dev/null 2>&1; then
    echo "   ✅ pip found: $(which pip)"
    echo "   Version: $(pip --version)"
else
    echo "   ❌ pip not found"
fi
echo ""

echo "5. Checking PATH for pyenv shims..."
if echo $PATH | grep -q ".pyenv/shims"; then
    echo "   ✅ pyenv shims in PATH"
else
    echo "   ❌ pyenv shims not in PATH"
fi
echo ""

echo "6. Module files..."
for module in utils python spark hadoop docker database credentials backup; do
    if [ -f ~/.config/zsh/modules/$module.zsh ]; then
        echo "   ✅ $module.zsh exists"
    else
        echo "   ❌ $module.zsh missing"
    fi
done
```

Save this as `~/.config/zsh/diagnose.sh` and run: `bash ~/.config/zsh/diagnose.sh`

---

## Getting Help

If none of these solutions work:

1. **Check loaded modules:**
   ```bash
   modules  # Shows what's loaded
   ```

2. **Check help:**
   ```bash
   help  # Shows all available commands
   ```

3. **View logs:**
   ```bash
   # Enable debug mode
   set -x
   source ~/.zshrc
   set +x
   ```

4. **Full repository status:**
   ```bash
   cd ~/.config/zsh
   git status
   git log --oneline -5
   ```

---

**Last Updated:** November 3, 2025

