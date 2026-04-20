.DEFAULT_GOAL := help
.PHONY: help test test-verbose lint format format-check startup-time profile install clean

# ---------------------------------------------------------------------------
# Environment surface passed to the test runner so modules with stub-
# sensitive checks (spark/hadoop/zeppelin) don't pull in real SDKMAN paths.
# Matches the CI env in .github/workflows/test.yml.
TEST_ENV := \
	SPARK_HOME=/tmp/stub-spark \
	HADOOP_HOME=/tmp/stub-hadoop \
	ZEPPELIN_HOME=/tmp/stub-zeppelin \
	ZSH_TEST_MODE=1

BASH_SCRIPTS := install.sh setup-software.sh bash-bridge.sh
SHFMT_FLAGS := -i 4 -ci -kp -sr

# ---------------------------------------------------------------------------
help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

test: ## Run the full test suite
	@mkdir -p /tmp/stub-spark /tmp/stub-hadoop /tmp/stub-zeppelin
	@$(TEST_ENV) zsh run-tests.zsh

test-verbose: ## Run the full test suite with per-test RUN/PASS output
	@mkdir -p /tmp/stub-spark /tmp/stub-hadoop /tmp/stub-zeppelin
	@$(TEST_ENV) zsh run-tests.zsh --verbose

lint: ## Run shellcheck on the bash scripts
	@shellcheck -S error $(BASH_SCRIPTS)

format: ## Apply shfmt formatting to the bash scripts
	@shfmt -w $(SHFMT_FLAGS) $(BASH_SCRIPTS)

format-check: ## Check bash scripts are already shfmt-formatted
	@shfmt -d $(SHFMT_FLAGS) $(BASH_SCRIPTS)

startup-time: ## Measure interactive-shell startup (6 runs, drops warm-up)
	@$(TEST_ENV) ZSH_STARTUP_RUNS=6 zsh tests/test-startup-budget.zsh

profile: ## Run a profiled shell and print the zprof report
	@ZSH_FORCE_FULL_INIT=1 ZSH_PROFILE=1 \
		ZSH_STATUS_BANNER_MODE=off ZSH_AUTO_RECOVER_MODE=off \
		zsh -i -c exit

install: ## Run the installer (interactive)
	@./install.sh

clean: ## Remove test-run stub directories and XDG zcompdump cache
	@rm -rf /tmp/stub-spark /tmp/stub-hadoop /tmp/stub-zeppelin
	@rm -rf "$${XDG_CACHE_HOME:-$$HOME/.cache}"/zsh/zcompdump-*
