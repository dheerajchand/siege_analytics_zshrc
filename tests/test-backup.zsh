#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/backup.zsh"

_make_backup_test_repo() {
    local tmp
    tmp="$(mktemp -d)"
    local origin="$tmp/origin.git"
    local backup_remote="$tmp/backup.git"
    local work="$tmp/work"

    git init --bare "$origin" >/dev/null 2>&1 || return 1
    git init --bare "$backup_remote" >/dev/null 2>&1 || return 1
    git init "$work" >/dev/null 2>&1 || return 1
    git -C "$work" config user.email "test@example.com"
    git -C "$work" config user.name "Backup Test"
    cat > "$work/README.md" <<'EOF'
# backup test repo
EOF
    git -C "$work" add README.md
    git -C "$work" commit -m "init" >/dev/null 2>&1 || return 1
    git -C "$work" branch -M main
    git -C "$work" remote add origin "$origin"
    git -C "$work" remote add backup "$backup_remote"
    git -C "$work" push -u origin main >/dev/null 2>&1 || return 1
    git -C "$work" push backup main >/dev/null 2>&1 || return 1
    echo "$tmp"
}

test_backup_requires_git_repo() {
    local old_dir="$ZSHRC_CONFIG_DIR"
    local tmp out
    tmp="$(mktemp -d)"
    ZSHRC_CONFIG_DIR="$tmp"
    out="$(backup "test" 2>&1 || true)"
    assert_contains "$out" "Not a git repository" "backup should refuse non-git dir"
    ZSHRC_CONFIG_DIR="$old_dir"
    rm -rf "$tmp"
}

test_backup_pushes_current_branch() {
    local old_dir="$ZSHRC_CONFIG_DIR"
    local root work out
    root="$(_make_backup_test_repo)"
    work="$root/work"
    git -C "$work" checkout -b feature/backup >/dev/null 2>&1
    echo "backup branch payload" > "$work/feature.txt"

    ZSHRC_CONFIG_DIR="$work"
    out="$(backup "feature backup test" 2>&1 || true)"
    assert_contains "$out" "Pushed to main repo (feature/backup)" "should push active feature branch to origin"
    assert_contains "$out" "Pushed to backup repo (feature/backup)" "should push active feature branch to backup remote"
    assert_command_success "git --git-dir '$root/origin.git' show-ref --verify --quiet refs/heads/feature/backup" "origin should have feature branch"
    assert_command_success "git --git-dir '$root/backup.git' show-ref --verify --quiet refs/heads/feature/backup" "backup remote should have feature branch"

    ZSHRC_CONFIG_DIR="$old_dir"
    rm -rf "$root"
}

test_backup_merge_main_merges_and_returns_branch() {
    local old_dir="$ZSHRC_CONFIG_DIR"
    local root work out current
    root="$(_make_backup_test_repo)"
    work="$root/work"
    git -C "$work" checkout -b feature/merge >/dev/null 2>&1
    echo "merge payload" > "$work/merge.txt"
    git -C "$work" add merge.txt
    git -C "$work" commit -m "feat: merge target" >/dev/null 2>&1
    git -C "$work" push -u origin feature/merge >/dev/null 2>&1
    git -C "$work" push backup feature/merge >/dev/null 2>&1

    ZSHRC_CONFIG_DIR="$work"
    out="$(backup_merge_main 2>&1 || true)"
    assert_contains "$out" "Merged and pushed: feature/merge -> main" "should merge feature branch to main"
    current="$(git -C "$work" branch --show-current)"
    assert_equal "feature/merge" "$current" "should return to original branch after merge"
    assert_command_success "git --git-dir '$root/origin.git' log --oneline main | grep -q \"feat: merge target\"" "origin main should include merged commit"
    assert_command_success "git --git-dir '$root/backup.git' log --oneline main | grep -q \"feat: merge target\"" "backup main should include merged commit"

    ZSHRC_CONFIG_DIR="$old_dir"
    rm -rf "$root"
}

test_pushmain_commits_pushes_and_merges() {
    local old_dir="$ZSHRC_CONFIG_DIR"
    local root work out current
    root="$(_make_backup_test_repo)"
    work="$root/work"
    git -C "$work" checkout -b feature/pushmain >/dev/null 2>&1
    echo "pushmain payload" > "$work/pushmain.txt"

    ZSHRC_CONFIG_DIR="$work"
    out="$(pushmain "pushmain integration test" 2>&1 || true)"
    assert_contains "$out" "Backup complete" "pushmain should run backup"
    assert_contains "$out" "Merged and pushed: feature/pushmain -> main" "pushmain should merge to main"
    assert_command_success "git --git-dir '$root/origin.git' show-ref --verify --quiet refs/heads/feature/pushmain" "origin should have pushed feature branch"
    assert_command_success "git --git-dir '$root/origin.git' log --oneline main | grep -q \"pushmain integration test\"" "origin main should include pushmain commit"
    current="$(git -C "$work" branch --show-current)"
    assert_equal "feature/pushmain" "$current" "pushmain should return to original branch"

    ZSHRC_CONFIG_DIR="$old_dir"
    rm -rf "$root"
}

register_test "backup_requires_git" test_backup_requires_git_repo
register_test "backup_pushes_current_branch" test_backup_pushes_current_branch
register_test "backup_merge_main_merges_and_returns_branch" test_backup_merge_main_merges_and_returns_branch
register_test "pushmain_commits_pushes_and_merges" test_pushmain_commits_pushes_and_merges
