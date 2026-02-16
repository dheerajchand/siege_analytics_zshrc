#!/usr/bin/env zsh
# =================================================================
# COMPAT - Version compatibility profiles and guards
# =================================================================

: "${ZSH_STACK_PROFILE:=stable}"

_compat_matrix_file() {
    echo "${ZSH_CONFIG_DIR:-$HOME/.config/zsh}/compatibility-matrix.json"
}

_compat_persist_var() {
    local key="$1"
    local value="$2"
    local file="${ZSH_CONFIG_DIR:-$HOME/.config/zsh}/vars.env"
    if typeset -f settings_persist_var >/dev/null 2>&1; then
        settings_persist_var "$key" "$value" "$file"
        return $?
    fi
    [[ -z "$key" || -z "$file" ]] && return 1
    [[ -f "$file" ]] || touch "$file"
    python3 - "$file" "$key" "$value" <<'PY'
import sys
path, key, value = sys.argv[1:4]
with open(path, "r", encoding="utf-8") as f:
    lines = f.read().splitlines()
needle = f'export {key}="'
new_line = f'export {key}="${{{key}:-{value}}}"'
updated = False
out = []
for line in lines:
    if line.startswith(needle):
        out.append(new_line)
        updated = True
    else:
        out.append(line)
if not updated:
    out.append(new_line)
with open(path, "w", encoding="utf-8") as f:
    f.write("\n".join(out) + "\n")
PY
}

_compat_detect_zeppelin_version() {
    if [[ -n "${ZEPPELIN_VERSION:-}" ]]; then
        echo "$ZEPPELIN_VERSION"
        return 0
    fi
    local ze_home="${ZEPPELIN_HOME:-$HOME/opt/zeppelin/current}"
    if [[ -L "$ze_home" ]]; then
        ze_home="$(readlink "$ze_home" 2>/dev/null || echo "$ze_home")"
        [[ "$ze_home" != /* ]] && ze_home="$HOME/opt/zeppelin/$ze_home"
    fi
    local base="${ze_home:t}"
    if [[ "$base" =~ 'zeppelin-([0-9]+\.[0-9]+\.[0-9]+)' ]]; then
        echo "${match[1]}"
    fi
}

_compat_detect_versions_json() {
    local spark_version=""
    local scala_version=""
    local hadoop_version=""
    local java_version="${JAVA_VERSION:-}"
    local zeppelin_version=""

    if typeset -f _spark_detect_versions >/dev/null 2>&1; then
        local detected
        detected="$(_spark_detect_versions 2>/dev/null || true)"
        spark_version="${detected%% *}"
        scala_version="${detected#* }"
    fi
    [[ -z "$spark_version" ]] && spark_version="${SPARK_VERSION:-}"
    [[ -z "$scala_version" ]] && scala_version="${SPARK_SCALA_VERSION:-}"
    if [[ -z "$scala_version" ]] && command -v scala >/dev/null 2>&1; then
        scala_version="$(scala -version 2>&1 | awk '/version/{print $NF; exit}')"
    fi
    if command -v hadoop >/dev/null 2>&1; then
        hadoop_version="$(hadoop version 2>/dev/null | awk '/Hadoop/{print $2; exit}')"
    fi
    [[ -z "$hadoop_version" ]] && hadoop_version="${HADOOP_VERSION:-}"
    if [[ -z "$java_version" ]] && command -v java >/dev/null 2>&1; then
        java_version="$(java -version 2>&1 | head -n 1 | awk -F'\"' '{print $2}')"
    fi
    zeppelin_version="$(_compat_detect_zeppelin_version 2>/dev/null || true)"
    local zeppelin_mode="${ZEPPELIN_SPARK_INTEGRATION_MODE:-external}"

    python3 - "$spark_version" "$scala_version" "$hadoop_version" "$java_version" "$zeppelin_version" "${SPARK_SEDONA_VERSION:-}" "${SPARK_GRAPHFRAMES_VERSION:-}" "$zeppelin_mode" <<'PY'
import json,sys
print(json.dumps({
  "spark": sys.argv[1],
  "scala": sys.argv[2],
  "hadoop": sys.argv[3],
  "java": sys.argv[4],
  "zeppelin": sys.argv[5],
  "sedona": sys.argv[6],
  "graphframes": sys.argv[7],
  "zeppelin_spark_integration_mode": sys.argv[8],
}))
PY
}

compat_profiles() {
    local matrix="$(_compat_matrix_file)"
    if [[ ! -f "$matrix" ]]; then
        echo "Compatibility matrix missing: $matrix" >&2
        return 1
    fi
    python3 - "$matrix" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
for name,data in m.get("profiles",{}).items():
    desc=data.get("description","")
    print(f"{name}: {desc}")
PY
}

stack_profile_use() {
    local profile=""
    local persist=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --persist) persist=1; shift ;;
            --help|-h)
                echo "Usage: stack_profile_use <profile> [--persist]" >&2
                return 0
                ;;
            *)
                if [[ -z "$profile" ]]; then
                    profile="$1"
                else
                    echo "Usage: stack_profile_use <profile> [--persist]" >&2
                    return 1
                fi
                shift
                ;;
        esac
    done
    if [[ -z "$profile" ]]; then
        echo "Usage: stack_profile_use <profile> [--persist]" >&2
        return 1
    fi
    local matrix="$(_compat_matrix_file)"
    [[ -f "$matrix" ]] || { echo "Missing matrix: $matrix" >&2; return 1; }

    local lines
    lines="$(python3 - "$matrix" "$profile" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
p=m.get("profiles",{}).get(sys.argv[2])
if not p:
    sys.exit(2)
v=p.get("versions",{})
mapping={
  "spark":"SPARK_VERSION",
  "scala":"SPARK_SCALA_VERSION",
  "hadoop":"HADOOP_VERSION",
  "java":"JAVA_VERSION",
  "sedona":"SPARK_SEDONA_VERSION",
  "graphframes":"SPARK_GRAPHFRAMES_VERSION"
}
print("ZSH_STACK_PROFILE=" + sys.argv[2])
for k,env in mapping.items():
    if v.get(k):
        print(env + "=" + str(v[k]))
defaults=p.get("defaults",{})
if defaults.get("zeppelin_spark_integration_mode"):
    print("ZEPPELIN_SPARK_INTEGRATION_MODE=" + str(defaults["zeppelin_spark_integration_mode"]))
if defaults.get("zeppelin_livy_url"):
    print("ZEPPELIN_LIVY_URL=" + str(defaults["zeppelin_livy_url"]))
PY
)"
    if [[ $? -eq 2 ]]; then
        echo "Unknown profile: $profile" >&2
        compat_profiles
        return 1
    fi

    local line key value
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        key="${line%%=*}"
        value="${line#*=}"
        export "$key=$value"
        if (( persist )); then
            _compat_persist_var "$key" "$value"
        fi
    done <<< "$lines"

    echo "✅ Active stack profile: $profile"
    (( persist )) && echo "✅ Persisted profile values to vars.env"
}

stack_profile_status() {
    echo "🧩 Stack Profile"
    echo "==============="
    echo "Profile: ${ZSH_STACK_PROFILE:-unset}"
    echo "Spark: ${SPARK_VERSION:-auto}"
    echo "Scala: ${SPARK_SCALA_VERSION:-auto}"
    echo "Hadoop: ${HADOOP_VERSION:-auto}"
    echo "Java: ${JAVA_VERSION:-auto}"
    echo "Sedona: ${SPARK_SEDONA_VERSION:-auto}"
    echo "GraphFrames: ${SPARK_GRAPHFRAMES_VERSION:-auto}"
    echo "Zeppelin mode: ${ZEPPELIN_SPARK_INTEGRATION_MODE:-external}"
    echo "Livy URL: ${ZEPPELIN_LIVY_URL:-http://127.0.0.1:8998}"
}

stack_validate_versions() {
    local component=""
    local json_mode=0
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --component)
                component="$2"
                shift 2
                ;;
            --json)
                json_mode=1
                shift
                ;;
            --help|-h)
                echo "Usage: stack_validate_versions [--component <name>] [--json]" >&2
                return 0
                ;;
            *)
                echo "Usage: stack_validate_versions [--component <name>] [--json]" >&2
                return 1
                ;;
        esac
    done

    local matrix="$(_compat_matrix_file)"
    [[ -f "$matrix" ]] || { echo "Missing matrix: $matrix" >&2; return 1; }

    local current_json
    current_json="$(_compat_detect_versions_json)"
    local result
    result="$(python3 - "$matrix" "$current_json" "$component" "$json_mode" <<'PY'
import json,sys
matrix=json.load(open(sys.argv[1]))
current=json.loads(sys.argv[2])
component=sys.argv[3]
json_mode=sys.argv[4]=="1"

def matches(cond, value):
    if cond.endswith("*"):
        return value.startswith(cond[:-1])
    return value == cond

problems=[]
for rule in matrix.get("rules", []):
    rc=rule.get("component","")
    if component and rc and rc != component:
        continue
    when=rule.get("when",{})
    ok=True
    for k,cond in when.items():
        v=str(current.get(k,"") or "")
        if not v or not matches(str(cond), v):
            ok=False
            break
    if ok and rule.get("status")=="incompatible":
        problems.append({
          "id":rule.get("id","unknown"),
          "component":rc,
          "reason":rule.get("reason","incompatible combination")
        })

out={"current":current,"issues":problems,"ok":len(problems)==0}
if json_mode:
    print(json.dumps(out))
else:
    if problems:
        print("❌ Version compatibility check failed")
        print(f"Current: Spark={current.get('spark') or 'unknown'} Scala={current.get('scala') or 'unknown'} Hadoop={current.get('hadoop') or 'unknown'} Java={current.get('java') or 'unknown'} Zeppelin={current.get('zeppelin') or 'unknown'} Mode={current.get('zeppelin_spark_integration_mode') or 'unknown'}")
        for p in problems:
            comp=f"[{p['component']}]" if p.get("component") else ""
            print(f" - {p['id']} {comp}: {p['reason']}")
        print("Hint: keep Spark 4.1 with Zeppelin using `zeppelin_integration_use external --persist`.")
    else:
        print("✅ Version compatibility check passed")
    print(json.dumps(out))
PY
)"

    if (( json_mode )); then
        echo "$result"
    else
        local summary
        summary="$(echo "$result" | tail -n 1)"
        echo "$result" | sed '$d'
        local ok
        ok="$(python3 - <<'PY' "$summary"
import json,sys
try:
    print("1" if json.loads(sys.argv[1]).get("ok") else "0")
except Exception:
    print("0")
PY
)"
        [[ "$ok" == "1" ]]
    fi
}

if [[ -z "${ZSH_TEST_MODE:-}" ]]; then
    echo "✅ compat loaded"
fi
