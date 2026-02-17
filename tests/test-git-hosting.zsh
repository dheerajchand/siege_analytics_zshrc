#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/github.zsh"
source "$ROOT_DIR/modules/gitlab.zsh"

_make_test_repo() {
    local tmp="$1"
    git init "$tmp" >/dev/null 2>&1 || return 1
    git -C "$tmp" config user.email "test@example.com"
    git -C "$tmp" config user.name "Test User"
    echo "seed" > "$tmp/README.md"
    git -C "$tmp" add README.md
    git -C "$tmp" commit -m "init" >/dev/null 2>&1 || return 1
}

_make_gh_stub() {
    local bin="$1"
    cat > "$bin/gh" <<'SH'
#!/usr/bin/env zsh
set -e
cmd1="${1:-}"; cmd2="${2:-}"
if [[ "$cmd1" == "auth" && "$cmd2" == "status" ]]; then
  exit 0
fi
if [[ "$cmd1" == "repo" && "$cmd2" == "list" ]]; then
  printf '%s' "${GH_REPO_LIST_JSON:-[]}"
  exit 0
fi
if [[ "$cmd1" == "repo" && "$cmd2" == "clone" ]]; then
  target="${4:-}"
  mkdir -p "$target/.git"
  exit 0
fi
if [[ "$cmd1" == "issue" && "$cmd2" == "view" ]]; then
  printf '%s\n' "${GH_ISSUE_TITLE:-Sample Issue}"
  exit 0
fi
if [[ "$cmd1" == "issue" && "$cmd2" == "list" ]]; then
  echo "issue list"
  exit 0
fi
if [[ "$cmd1" == "issue" && "$cmd2" == "close" ]]; then
  echo "closed"
  exit 0
fi
if [[ "$cmd1" == "pr" && "$cmd2" == "view" ]]; then
  printf '%s' "${GH_PR_VIEW_JSON:-{\"state\":\"OPEN\",\"isDraft\":false,\"mergeStateStatus\":\"CLEAN\"}}"
  exit 0
fi
if [[ "$cmd1" == "pr" && "$cmd2" == "merge" ]]; then
  [[ -n "${GH_PR_MERGE_MARK:-}" ]] && : > "$GH_PR_MERGE_MARK"
  exit 0
fi
if [[ "$cmd1" == "pr" && "$cmd2" == "update-branch" ]]; then
  [[ -n "${GH_PR_REBASE_MARK:-}" ]] && : > "$GH_PR_REBASE_MARK"
  exit 0
fi
if [[ "$cmd1" == "pr" && "$cmd2" == "create" ]]; then
  echo "pr created"
  exit 0
fi
if [[ "$cmd1" == "release" && "$cmd2" == "create" ]]; then
  [[ -n "${GH_RELEASE_MARK:-}" ]] && : > "$GH_RELEASE_MARK"
  exit 0
fi
exit 1
SH
    chmod +x "$bin/gh"
}

_make_glab_stub() {
    local bin="$1"
    cat > "$bin/glab" <<'SH'
#!/usr/bin/env zsh
set -e
cmd1="${1:-}"; cmd2="${2:-}"
if [[ "$cmd1" == "auth" && "$cmd2" == "status" ]]; then
  exit 0
fi
if [[ "$cmd1" == "repo" && "$cmd2" == "clone" ]]; then
  target="${4:-}"
  mkdir -p "$target/.git"
  exit 0
fi
if [[ "$cmd1" == "issue" && "$cmd2" == "list" ]]; then
  echo "issue list"
  exit 0
fi
if [[ "$cmd1" == "mr" && "$cmd2" == "create" ]]; then
  [[ -n "${GL_MR_CREATE_MARK:-}" ]] && : > "$GL_MR_CREATE_MARK"
  exit 0
fi
if [[ "$cmd1" == "mr" && "$cmd2" == "merge" ]]; then
  [[ -n "${GL_MR_MERGE_MARK:-}" ]] && : > "$GL_MR_MERGE_MARK"
  exit 0
fi
if [[ "$cmd1" == "release" && "$cmd2" == "create" ]]; then
  [[ -n "${GL_RELEASE_MARK:-}" ]] && : > "$GL_RELEASE_MARK"
  exit 0
fi
if [[ "$cmd1" == "api" ]]; then
  method="GET"
  path=""
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -X) method="$2"; shift 2 ;;
      -f) shift 2 ;;
      *)
        if [[ -z "$path" ]]; then
          path="$1"
        fi
        shift
        ;;
    esac
  done
  if [[ "$path" == groups/*/projects* ]]; then
    printf '%s' "${GL_GROUP_PROJECTS_JSON:-[]}"
    exit 0
  fi
  if [[ "$path" == projects/*/issues/* && "$method" == "GET" ]]; then
    printf '{"title":"%s"}' "${GL_ISSUE_TITLE:-Sample GL Issue}"
    exit 0
  fi
  if [[ "$path" == projects/*/merge_requests/* && "$method" == "GET" ]]; then
    printf '%s' "${GL_MR_VIEW_JSON:-{\"state\":\"opened\",\"title\":\"MR\",\"detailed_merge_status\":\"mergeable\"}}"
    exit 0
  fi
  if [[ "$path" == projects/*/issues/*/notes && "$method" == "POST" ]]; then
    exit 0
  fi
  if [[ "$path" == projects/*/issues/* && "$method" == "PUT" ]]; then
    exit 0
  fi
  if [[ "$path" == projects/*/merge_requests/*/rebase && "$method" == "PUT" ]]; then
    [[ -n "${GL_MR_REBASE_MARK:-}" ]] && : > "$GL_MR_REBASE_MARK"
    exit 0
  fi
  exit 1
fi
exit 1
SH
    chmod +x "$bin/glab"
}

test_gh_org_clone_all_clones_non_archived() {
    local old_path="$PATH" old_pwd="$PWD"
    local tmp bin dest
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    dest="$tmp/dest"
    mkdir -p "$bin" "$dest"

    _make_gh_stub "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r

    export GH_REPO_LIST_JSON='[{"nameWithOwner":"acme/one","sshUrl":"git@github.com:acme/one.git","isArchived":false},{"nameWithOwner":"acme/two","sshUrl":"git@github.com:acme/two.git","isArchived":true}]'

    gh_org_clone_all --org acme --dest "$dest"

    assert_true "[[ -d '$dest/one/.git' ]]" "gh_org_clone_all should clone active repo"
    assert_false "[[ -d '$dest/two/.git' ]]" "gh_org_clone_all should skip archived repo by default"

    PATH="$old_path"
    cd "$old_pwd"
    rm -rf "$tmp"
}

test_gh_issue_start_creates_branch() {
    local old_path="$PATH" old_pwd="$PWD"
    local tmp bin repo branch
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    repo="$tmp/repo"
    mkdir -p "$bin"

    _make_gh_stub "$bin"
    _make_test_repo "$repo"

    PATH="$bin:/usr/bin:/bin"
    hash -r
    export GH_ISSUE_TITLE='Fix auth bug quickly'

    cd "$repo"
    gh_issue_start 42 --repo acme/one >/dev/null
    branch="$(git -C "$repo" branch --show-current)"
    assert_equal "issue/42-fix-auth-bug-quickly" "$branch" "gh_issue_start should create slugged branch"

    PATH="$old_path"
    cd "$old_pwd"
    rm -rf "$tmp"
}

test_gh_pr_merge_safe_blocks_draft() {
    local old_path="$PATH"
    local tmp bin
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_gh_stub "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r

    export GH_PR_VIEW_JSON='{"state":"OPEN","isDraft":true,"mergeStateStatus":"CLEAN"}'
    assert_command_failure "gh_pr_merge_safe 7 --repo acme/one >/dev/null 2>&1" "gh_pr_merge_safe should block drafts"

    PATH="$old_path"
    rm -rf "$tmp"
}

test_gl_group_clone_all_clones_non_archived() {
    local old_path="$PATH" old_pwd="$PWD"
    local tmp bin dest
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    dest="$tmp/dest"
    mkdir -p "$bin" "$dest"

    _make_glab_stub "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r

    export GL_GROUP_PROJECTS_JSON='[{"path_with_namespace":"team/app1","ssh_url_to_repo":"git@gitlab.com:team/app1.git","archived":false},{"path_with_namespace":"team/app2","ssh_url_to_repo":"git@gitlab.com:team/app2.git","archived":true}]'

    gl_group_clone_all --group team --dest "$dest"

    assert_true "[[ -d '$dest/app1/.git' ]]" "gl_group_clone_all should clone active project"
    assert_false "[[ -d '$dest/app2/.git' ]]" "gl_group_clone_all should skip archived project"

    PATH="$old_path"
    cd "$old_pwd"
    rm -rf "$tmp"
}

test_gl_issue_start_creates_branch() {
    local old_path="$PATH" old_pwd="$PWD"
    local tmp bin repo branch
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    repo="$tmp/repo"
    mkdir -p "$bin"

    _make_glab_stub "$bin"
    _make_test_repo "$repo"

    PATH="$bin:/usr/bin:/bin"
    hash -r
    export GL_ISSUE_TITLE='Improve ETL reliability'

    cd "$repo"
    gl_issue_start 17 --project team/app1 >/dev/null
    branch="$(git -C "$repo" branch --show-current)"
    assert_equal "issue/17-improve-etl-reliability" "$branch" "gl_issue_start should create slugged branch"

    PATH="$old_path"
    cd "$old_pwd"
    rm -rf "$tmp"
}

test_gl_mr_merge_safe_blocks_draft() {
    local old_path="$PATH"
    local tmp bin
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_glab_stub "$bin"
    PATH="$bin:/usr/bin:/bin"
    hash -r

    export GL_MR_VIEW_JSON='{"state":"opened","title":"Draft: ETL fix","detailed_merge_status":"mergeable"}'
    assert_command_failure "gl_mr_merge_safe 11 --project team/app1 >/dev/null 2>&1" "gl_mr_merge_safe should block draft MRs"

    PATH="$old_path"
    rm -rf "$tmp"
}

test_git_hosting_status_reports_auth() {
    local old_path="$PATH"
    local tmp bin out
    tmp="$(mktemp -d)"
    bin="$tmp/bin"
    mkdir -p "$bin"
    _make_gh_stub "$bin"
    _make_glab_stub "$bin"

    PATH="$bin:/usr/bin:/bin"
    hash -r

    out="$(git_hosting_status 2>&1 || true)"
    assert_contains "$out" "GitHub: authenticated" "git_hosting_status should report GitHub auth"
    assert_contains "$out" "GitLab: authenticated" "git_hosting_status should report GitLab auth"

    PATH="$old_path"
    rm -rf "$tmp"
}

register_test "gh_org_clone_all_clones_non_archived" test_gh_org_clone_all_clones_non_archived
register_test "gh_issue_start_creates_branch" test_gh_issue_start_creates_branch
register_test "gh_pr_merge_safe_blocks_draft" test_gh_pr_merge_safe_blocks_draft
register_test "gl_group_clone_all_clones_non_archived" test_gl_group_clone_all_clones_non_archived
register_test "gl_issue_start_creates_branch" test_gl_issue_start_creates_branch
register_test "gl_mr_merge_safe_blocks_draft" test_gl_mr_merge_safe_blocks_draft
register_test "git_hosting_status_reports_auth" test_git_hosting_status_reports_auth
