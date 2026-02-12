#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"

test_spark_health_defined() {
    source "$ROOT_DIR/modules/spark.zsh"
    assert_true "typeset -f spark_health >/dev/null 2>&1" "spark_health should be defined"
    assert_true "typeset -f spark_config_status >/dev/null 2>&1" "spark_config_status should be defined"
}

test_hadoop_health_defined() {
    source "$ROOT_DIR/modules/hadoop.zsh"
    assert_true "typeset -f hadoop_health >/dev/null 2>&1" "hadoop_health should be defined"
    assert_true "typeset -f yarn_health >/dev/null 2>&1" "yarn_health should be defined"
    assert_true "typeset -f hadoop_config_status >/dev/null 2>&1" "hadoop_config_status should be defined"
}

test_spark_home_sdkman_preferred() {
    local out
    if [[ ! -d "$HOME/.sdkman/candidates/spark/current" ]]; then
        return 0
    fi
    out="$(ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/spark.zsh; print -r -- \"\$SPARK_HOME\"" | tail -n 1)"
    assert_equal "$HOME/.sdkman/candidates/spark/current" "$out" "should prefer SDKMAN Spark path"
}

test_spark_install_from_tar_usage() {
    source "$ROOT_DIR/modules/spark.zsh"
    local out
    out="$(spark_install_from_tar 2>&1 || true)"
    assert_contains "$out" "Usage: spark_install_from_tar" "should show usage"
}

test_spark_install_from_tar_dry_run() {
    source "$ROOT_DIR/modules/spark.zsh"
    local tmp out
    tmp="$(mktemp)"
    out="$(spark_install_from_tar --dry-run 4.1.1 "$tmp" 2>&1 || true)"
    assert_contains "$out" "DRY RUN: tar -xf" "should print dry run commands"
    rm -f "$tmp"
}

test_hadoop_home_sdkman_preferred() {
    local out
    if [[ ! -d "$HOME/.sdkman/candidates/hadoop/current" ]]; then
        return 0
    fi
    out="$(ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/hadoop.zsh; print -r -- \"\$HADOOP_HOME\"" | tail -n 1)"
    assert_equal "$HOME/.sdkman/candidates/hadoop/current" "$out" "should prefer SDKMAN Hadoop path"
}

test_hadoop_conf_dir_overrides_invalid() {
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/etc/hadoop"
    touch "$tmp/etc/hadoop/core-site.xml"
    out="$(HADOOP_HOME="$tmp" HADOOP_CONF_DIR="/etc/hadoop" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/hadoop.zsh; print -r -- \"\$HADOOP_CONF_DIR\"" | tail -n 1)"
    assert_equal "$tmp/etc/hadoop" "$out" "should override invalid HADOOP_CONF_DIR"
    rm -rf "$tmp"
}

test_start_hadoop_usage() {
    source "$ROOT_DIR/modules/hadoop.zsh"
    local out
    out="$(start_hadoop --help 2>&1 || true)"
    assert_contains "$out" "Usage: start_hadoop" "should show usage"
}

test_yarn_kill_all_apps_requires_force() {
    source "$ROOT_DIR/modules/hadoop.zsh"
    local out
    out="$(yarn_kill_all_apps 2>&1 || true)"
    assert_contains "$out" "Refusing to kill all apps" "should require --force"
}

test_hdfs_rm_requires_force() {
    source "$ROOT_DIR/modules/hadoop.zsh"
    local out
    out="$(hdfs_rm /tmp 2>&1 || true)"
    assert_contains "$out" "Refusing to delete without --force" "should require --force"
}

test_spark_dependencies_use_jars_dir() {
    source "$ROOT_DIR/modules/spark.zsh"
    local tmp dir out
    tmp="$(mktemp -d)"
    dir="$tmp/jars/spark/4.1.1"
    mkdir -p "$dir"
    touch "$dir/test.jar"
    out="$(JARS_DIR="$tmp/jars" SPARK_VERSION="4.1.1" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/spark.zsh; get_spark_dependencies")"
    assert_contains "$out" "--jars" "should use local jars when available"
    rm -rf "$tmp"
}

test_jar_matrix_resolve_basic() {
    source "$ROOT_DIR/modules/spark.zsh"
    local out
    out="$(SPARK_VERSION=4.1.1 SPARK_SCALA_VERSION=2.13.17 jar_matrix_resolve)"
    assert_contains "$out" "sedona-spark-shaded-4.0_2.13" "should include sedona coords"
    assert_contains "$out" "spark-sql-kafka-0-10_2.13:4.1.1" "should include kafka coords"
}

test_jar_matrix_defaults_spark22() {
    local out
    out="$(SPARK_VERSION=2.2.3 SPARK_SCALA_VERSION= PATH="/usr/bin:/bin" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/spark.zsh; jar_matrix_resolve")"
    assert_contains "$out" "spark-sql-kafka-0-10_2.11:2.2.3" "spark 2.2 should default scala 2.11"
}

test_jar_matrix_defaults_spark24() {
    local out
    out="$(SPARK_VERSION=2.4.8 SPARK_SCALA_VERSION= PATH="/usr/bin:/bin" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/spark.zsh; jar_matrix_resolve")"
    assert_contains "$out" "spark-sql-kafka-0-10_2.12:2.4.8" "spark 2.4 should default scala 2.12"
}

test_jar_matrix_defaults_spark4() {
    local out
    out="$(SPARK_VERSION=4.1.1 SPARK_SCALA_VERSION= PATH="/usr/bin:/bin" ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/spark.zsh; jar_matrix_resolve")"
    assert_contains "$out" "spark-sql-kafka-0-10_2.13:4.1.1" "spark 4.x should default scala 2.13"
}

test_scala_version_sanitized() {
    local out
    out="$(SPARK_VERSION=4.1.1 SPARK_SCALA_VERSION='2.13.17, OpenJDK' ZSH_TEST_MODE=1 zsh -fc "source $ROOT_DIR/modules/spark.zsh; jar_matrix_resolve")"
    assert_contains "$out" "spark-sql-kafka-0-10_2.13:4.1.1" "scala version should be sanitized to binary 2.13"
}

test_jar_matrix_status_defined() {
    source "$ROOT_DIR/modules/spark.zsh"
    assert_true "typeset -f jar_matrix_status >/dev/null 2>&1" "jar_matrix_status should be defined"
}

test_spark_mode_functions_defined() {
    source "$ROOT_DIR/modules/spark.zsh"
    assert_true "typeset -f spark_mode_use >/dev/null 2>&1" "spark_mode_use should be defined"
    assert_true "typeset -f spark_mode_status >/dev/null 2>&1" "spark_mode_status should be defined"
}

test_spark_resolve_master_by_mode() {
    source "$ROOT_DIR/modules/spark.zsh"
    SPARK_LOCAL_MASTER="local[*]"
    SPARK_MASTER_URL="spark://localhost:7077"

    local out
    out="$(_spark_resolve_master local)"
    assert_equal "local[*]" "$out" "local mode should resolve local master"

    out="$(_spark_resolve_master cluster)"
    assert_equal "spark://localhost:7077" "$out" "cluster mode should resolve cluster master"

    _spark_cluster_running() { return 1; }
    out="$(_spark_resolve_master auto)"
    assert_equal "local[*]" "$out" "auto mode should use local master when cluster is down"

    _spark_cluster_running() { return 0; }
    out="$(_spark_resolve_master auto)"
    assert_equal "spark://localhost:7077" "$out" "auto mode should use cluster master when cluster is up"
}

test_spark_mode_use_normalizes_invalid() {
    source "$ROOT_DIR/modules/spark.zsh"
    local out rc
    out="$(spark_mode_use weird 2>&1)"
    rc=$?
    assert_not_equal "0" "$rc" "spark_mode_use should fail for invalid mode"
    assert_contains "$out" "Usage: spark_mode_use" "invalid mode should show usage"
}

test_spark_mode_use_persist_writes_vars_env() {
    source "$ROOT_DIR/modules/spark.zsh"
    local tmp
    tmp="$(mktemp -d)"
    ZSH_CONFIG_DIR="$tmp"
    export ZSH_CONFIG_DIR
    cat > "$tmp/vars.env" <<'EOF'
export SPARK_EXECUTION_MODE="${SPARK_EXECUTION_MODE:-auto}"
EOF

    spark_mode_use local --persist >/dev/null
    assert_equal "local" "${SPARK_EXECUTION_MODE}" "persist mode should also set active env value"
    local persisted
    persisted="$(cat "$tmp/vars.env")"
    assert_contains "$persisted" 'export SPARK_EXECUTION_MODE="${SPARK_EXECUTION_MODE:-local}"' "persist should update vars.env value"

    rm -rf "$tmp"
}

register_test "test_spark_home_sdkman_preferred" "test_spark_home_sdkman_preferred"
register_test "test_spark_install_from_tar_usage" "test_spark_install_from_tar_usage"
register_test "test_spark_install_from_tar_dry_run" "test_spark_install_from_tar_dry_run"
register_test "test_spark_dependencies_use_jars_dir" "test_spark_dependencies_use_jars_dir"
register_test "test_jar_matrix_resolve_basic" "test_jar_matrix_resolve_basic"
register_test "test_jar_matrix_defaults_spark22" "test_jar_matrix_defaults_spark22"
register_test "test_jar_matrix_defaults_spark24" "test_jar_matrix_defaults_spark24"
register_test "test_jar_matrix_defaults_spark4" "test_jar_matrix_defaults_spark4"
register_test "test_scala_version_sanitized" "test_scala_version_sanitized"
register_test "test_jar_matrix_status_defined" "test_jar_matrix_status_defined"
register_test "test_spark_mode_functions_defined" "test_spark_mode_functions_defined"
register_test "test_spark_resolve_master_by_mode" "test_spark_resolve_master_by_mode"
register_test "test_spark_mode_use_normalizes_invalid" "test_spark_mode_use_normalizes_invalid"
register_test "test_spark_mode_use_persist_writes_vars_env" "test_spark_mode_use_persist_writes_vars_env"
register_test "test_hadoop_home_sdkman_preferred" "test_hadoop_home_sdkman_preferred"
register_test "test_start_hadoop_usage" "test_start_hadoop_usage"
register_test "test_yarn_kill_all_apps_requires_force" "test_yarn_kill_all_apps_requires_force"
register_test "test_hdfs_rm_requires_force" "test_hdfs_rm_requires_force"
register_test "test_spark_health_defined" "test_spark_health_defined"
register_test "test_hadoop_health_defined" "test_hadoop_health_defined"
register_test "test_hadoop_conf_dir_overrides_invalid" "test_hadoop_conf_dir_overrides_invalid"
