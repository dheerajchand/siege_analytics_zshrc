#!/usr/bin/env zsh

ROOT_DIR="$(cd "$(dirname "${0:A}")/.." && pwd)"
source "$ROOT_DIR/tests/test-framework.zsh"
source "$ROOT_DIR/modules/dataworld.zsh"

test_dataworld_functions_defined() {
    assert_command_success "typeset -f dataworld_sync_csv >/dev/null" "dataworld_sync_csv should be defined"
    assert_command_success "typeset -f data_csv_prune_derived >/dev/null" "data_csv_prune_derived should be defined"
}

test_dataworld_sync_csv_dry_run_lists_csv() {
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/sub"
    echo "a,b" > "$tmp/keep.csv"
    echo "c,d" > "$tmp/sub/also_keep.CSV"
    echo "ignore" > "$tmp/nope.txt"
    export DATA_WORLD_API_TOKEN="fake-token"

    out="$(dataworld_sync_csv "$tmp" --owner me --dataset ds --dry-run 2>&1)"
    assert_contains "$out" "files=2" "dry run should count only csv files"
    assert_contains "$out" "$tmp/keep.csv" "dry run should list csv files"
    assert_contains "$out" "Dry run only" "dry run should not upload"
    assert_not_contains "$out" "nope.txt" "dry run should exclude non-csv files"

    rm -rf "$tmp"
}

test_data_csv_prune_derived_dry_run_preserves_csv() {
    local tmp out
    tmp="$(mktemp -d)"
    mkdir -p "$tmp/a"
    echo "x,y" > "$tmp/a/source.csv"
    echo "geo" > "$tmp/a/shape.shp"
    echo "index" > "$tmp/a/shape.shx"
    echo "zip" > "$tmp/a/tl_2019_48_tabblock10.zip"

    out="$(data_csv_prune_derived "$tmp" --dry-run 2>&1)"
    assert_contains "$out" "Derived geo cleanup plan" "should print cleanup plan"
    assert_contains "$out" "shape.shp" "dry run should identify derived files"
    assert_command_success "[[ -f \"$tmp/a/source.csv\" ]]" "csv should remain in dry-run"
    assert_command_success "[[ -f \"$tmp/a/shape.shp\" ]]" "dry-run should not delete files"

    rm -rf "$tmp"
}

register_test "test_dataworld_functions_defined" "test_dataworld_functions_defined"
register_test "test_dataworld_sync_csv_dry_run_lists_csv" "test_dataworld_sync_csv_dry_run_lists_csv"
register_test "test_data_csv_prune_derived_dry_run_preserves_csv" "test_data_csv_prune_derived_dry_run_preserves_csv"
