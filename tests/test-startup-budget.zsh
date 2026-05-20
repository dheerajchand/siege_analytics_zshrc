#!/usr/bin/env zsh
# Startup-time budget test.
#
# Runs `zsh -i -c exit` several times, computes the median wall-clock time
# (excluding a warm-up sample), and fails if it exceeds ZSH_STARTUP_BUDGET_MS.
#
# Deterministic env:
#   ZSH_FORCE_FULL_INIT=1         — skip non-TTY fast path
#   ZSH_STATUS_BANNER_MODE=off    — skip heavy status banner
#   ZSH_AUTO_RECOVER_MODE=off     — skip service auto-recovery
#
# Overrides:
#   ZSH_STARTUP_BUDGET_MS (default 2500)
#   ZSH_STARTUP_RUNS      (default 6 — 1 warm-up + 5 measured)
#   SKIP_STARTUP_BUDGET=1  — skip the test entirely

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

test_startup_budget_under_cap() {
    if [[ "${SKIP_STARTUP_BUDGET:-0}" == "1" ]]; then
        TEST_SKIP=1
        return 0
    fi

    local budget="${ZSH_STARTUP_BUDGET_MS:-2500}"
    local runs="${ZSH_STARTUP_RUNS:-6}"

    zmodload zsh/datetime 2>/dev/null || {
        _print_fail "zsh/datetime module unavailable"
        return 1
    }

    # Prepare a ZDOTDIR that points at the repo's zshrc. Without this, a
    # subprocess `zsh -i` uses $HOME/.zshrc which is missing on CI runners,
    # and measurement becomes ~7ms of nothing.
    local zdot
    zdot="$(mktemp -d)" || {
        _print_fail "mktemp failed"
        return 1
    }
    ln -sf "$ROOT_DIR/zshrc" "$zdot/.zshrc"

    local -a samples
    local i t0 t1 ms
    for (( i = 1; i <= runs; i++ )); do
        t0="$EPOCHREALTIME"
        ZDOTDIR="$zdot" \
            ZSH_FORCE_FULL_INIT=1 \
            ZSH_STATUS_BANNER_MODE=off \
            ZSH_AUTO_RECOVER_MODE=off \
            ZSH_STARTUP_MODE=immediate \
            zsh -i -c exit >/dev/null 2>&1
        t1="$EPOCHREALTIME"
        ms=$(( (t1 - t0) * 1000 ))
        ms=${ms%.*}
        samples+=("$ms")
    done
    rm -rf "$zdot"

    # Discard the first sample as warm-up; median over the rest.
    local -a measured sorted
    measured=("${(@)samples[2,-1]}")
    sorted=(${(on)measured})
    local n=${#sorted}
    local mid_idx=$(( (n + 1) / 2 ))
    local median="${sorted[$mid_idx]}"

    print -- "  samples (ms, 1st = warm-up, discarded): ${samples[*]}"
    print -- "  median: ${median}ms  budget: ${budget}ms"

    if (( median > budget )); then
        _print_fail "startup median ${median}ms exceeds budget ${budget}ms"
        return 1
    fi
    return 0
}

register_test "startup_budget_under_cap" test_startup_budget_under_cap
