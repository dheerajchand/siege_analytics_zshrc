#!/usr/bin/env python3
"""
Create a Zeppelin notebook that mixes Scala and Python cells to validate:
- Sedona SQL functions
- GraphFrames on Spark
- Cross-language interoperability between Scala and PySpark paragraphs
"""

from __future__ import annotations

import argparse
import json
import re
import webbrowser
import sys
import time
import urllib.error
import urllib.parse
import urllib.request


BASE_PARAGRAPHS = [
    {
        "title": "Scala: Session + Sedona Registration",
        "text": """%spark
import spark.implicits._
import org.apache.sedona.sql.utils.SedonaSQLRegistrator

SedonaSQLRegistrator.registerAll(spark)
println("Spark version: " + spark.version)
println("Spark master: " + spark.sparkContext.master)
println("Sedona registrator: " + spark.conf.get("spark.kryo.registrator", "missing"))
""",
    },
    {
        "title": "Scala: Sedona SQL + GraphFrames",
        "text": """%spark
import spark.implicits._
import org.graphframes.GraphFrame

val sedonaRow = spark.sql("SELECT ST_AsText(ST_Point(1.0, 2.0)) AS wkt").collect()(0)
println("Sedona WKT from Scala: " + sedonaRow.getAs[String]("wkt"))

val vertices = Seq(("a", "Alice"), ("b", "Bob"), ("c", "Cara")).toDF("id", "name")
val edges = Seq(("a", "b"), ("b", "c"), ("c", "a")).toDF("src", "dst")
val g = GraphFrame(vertices, edges)
val inDeg = g.inDegrees.orderBy($"id")
inDeg.createOrReplaceTempView("graphframe_in_degrees")
println("GraphFrames inDegrees rows: " + inDeg.count())
inDeg.show(false)
""",
    },
    {
        "title": "Python: Read GraphFrames Output from Scala",
        "text": """%spark.pyspark
df = spark.sql("SELECT id, inDegree FROM graphframe_in_degrees ORDER BY id")
rows = df.collect()
print("Rows from Scala GraphFrames temp view:", len(rows))
for row in rows:
    print(row["id"], row["inDegree"])
""",
    },
    {
        "title": "Python: Sedona SQL Smoke Test",
        "text": """%spark.pyspark
wkt = spark.sql("SELECT ST_AsText(ST_Point(10.0, 20.0)) AS wkt").collect()[0]["wkt"]
print("Sedona WKT from Python:", wkt)
""",
    },
]


def paragraphs_for_mode(mode: str) -> list[dict[str, str]]:
    if mode == "livy":
        replaced = []
        for para in BASE_PARAGRAPHS:
            text = para["text"].replace("%spark.pyspark", "%livy.pyspark").replace("%spark", "%livy.spark")
            replaced.append({"title": para["title"], "text": text})
        return replaced
    if mode == "external":
        return [
            {
                "title": "External Spark 4.1 mode",
                "text": """%md
# External Spark Mode

This stack is using Zeppelin `external` mode for Spark 4.1 stability.

Notebook paragraphs below include Python environment, Hadoop/service diagnostics,
Spark worker functionality checks, and Scala/Python Sedona + GraphFrames verification snippets.
Run them via `%sh` using Spark 4.1 outside Zeppelin's embedded Spark interpreter.
""",
            },
            {
                "title": "Python environment diagnostics",
                "text": """%sh
set -euo pipefail
if command -v pyenv >/dev/null 2>&1; then
  eval "$(pyenv init --path)" || true
  eval "$(pyenv init -)" || true
  if [ -n "${PYENV_DEFAULT_VENV:-}" ]; then
    pyenv shell "${PYENV_DEFAULT_VENV}" || true
  fi
fi
echo "PYTHON3_BIN=$(command -v python3)"
python3 --version
if command -v pyenv >/dev/null 2>&1; then
  pyenv version
fi
python3 - <<'PY'
import importlib
mods=["pyspark","py4j"]
missing=[]
for m in mods:
    try:
        importlib.import_module(m)
        print(f"{m}=OK")
    except Exception:
        missing.append(m)
if missing:
    print("PYTHON_IMPORTS_WARN_MISSING=" + ",".join(missing))
else:
    print("PYTHON_IMPORTS=OK")
PY
""",
            },
            {
                "title": "Hadoop and data-service diagnostics",
                "text": """%sh
set -euo pipefail
REQUIRE_CLUSTER_SERVICES="${REQUIRE_CLUSTER_SERVICES:-0}"
SPARK_MODE="${SPARK_EXECUTION_MODE:-auto}"
if [ "$SPARK_MODE" = "local" ]; then
  EXPECT_CLUSTER_SERVICES=0
elif [ "$SPARK_MODE" = "cluster" ]; then
  EXPECT_CLUSTER_SERVICES=1
else
  EXPECT_CLUSTER_SERVICES="$REQUIRE_CLUSTER_SERVICES"
fi
echo "HADOOP_HOME=${HADOOP_HOME:-unset}"
echo "SPARK_HOME=${SPARK_HOME:-unset}"
echo "JAVA_HOME=${JAVA_HOME:-unset}"
echo "SPARK_EXECUTION_MODE=${SPARK_MODE}"
echo "REQUIRE_CLUSTER_SERVICES=${REQUIRE_CLUSTER_SERVICES}"
if ! command -v hadoop >/dev/null 2>&1 && [ -x "$HOME/.sdkman/candidates/hadoop/current/bin/hadoop" ]; then
  export PATH="$HOME/.sdkman/candidates/hadoop/current/bin:$PATH"
fi

if ! command -v hadoop >/dev/null 2>&1; then
  echo "HADOOP_CMD=MISSING"
  exit 1
fi
echo "HADOOP_CMD=OK"
hadoop version | head -n 2

if command -v jps >/dev/null 2>&1; then
  echo "JPS_SERVICES:"
  jps | egrep 'NameNode|DataNode|ResourceManager|NodeManager|Master|Worker|HistoryServer|LivyServer' || true
fi

if command -v hdfs >/dev/null 2>&1; then
  if jps | grep -q NameNode 2>/dev/null; then
    echo "HDFS_ROOT_LIST:"
    hdfs dfs -ls / 2>/dev/null || true
  else
    if [ "$EXPECT_CLUSTER_SERVICES" = "1" ]; then
      echo "HDFS_STATUS=FAIL_NAMENODE_NOT_RUNNING"
    else
      echo "HDFS_STATUS=SKIP_NAMENODE_NOT_RUNNING_LOCAL_OR_OPTIONAL"
    fi
  fi
fi

if command -v yarn >/dev/null 2>&1; then
  if jps | grep -q ResourceManager 2>/dev/null; then
    echo "YARN_NODE_LIST:"
    yarn node -list 2>/dev/null || true
  else
    if [ "$EXPECT_CLUSTER_SERVICES" = "1" ]; then
      echo "YARN_STATUS=FAIL_RESOURCEMANAGER_NOT_RUNNING"
    else
      echo "YARN_STATUS=SKIP_RESOURCEMANAGER_NOT_RUNNING_LOCAL_OR_OPTIONAL"
    fi
  fi
fi

if curl -fsS http://127.0.0.1:8080 >/dev/null 2>&1; then
  echo "SPARK_MASTER_UI=UP"
else
  if [ "$EXPECT_CLUSTER_SERVICES" = "1" ]; then
    echo "SPARK_MASTER_UI=FAIL_DOWN_OR_NOT_RUNNING"
  else
    echo "SPARK_MASTER_UI=SKIP_DOWN_OR_NOT_RUNNING_LOCAL_OR_OPTIONAL"
  fi
fi

if [ "$EXPECT_CLUSTER_SERVICES" = "1" ]; then
  if jps | grep -q NameNode 2>/dev/null && jps | grep -q ResourceManager 2>/dev/null && curl -fsS http://127.0.0.1:8080 >/dev/null 2>&1; then
    echo "DATA_SERVICES_EXPECTED_STATUS=OK"
  else
    echo "DATA_SERVICES_EXPECTED_STATUS=FAIL"
    exit 1
  fi
else
  echo "DATA_SERVICES_EXPECTED_STATUS=OK_LOCAL_OR_OPTIONAL"
fi
""",
            },
            {
                "title": "Spark workers: functional/dysfunctional diagnostics",
                "text": """%sh
set -euo pipefail
zsh -lc '
source ~/.config/zsh/modules/settings.zsh >/dev/null
source ~/.config/zsh/modules/utils.zsh >/dev/null
source ~/.config/zsh/modules/spark.zsh >/dev/null
set +e
echo "=== MODE local: status ==="
SPARK_EXECUTION_MODE=local spark_workers_health
echo "LOCAL_STATUS_RC=$?"
echo
echo "=== MODE local: probe (packages) ==="
SPARK_EXECUTION_MODE=local spark_workers_health --probe --with-packages
echo "LOCAL_PROBE_RC=$?"
echo
echo "=== MODE cluster: status ==="
SPARK_EXECUTION_MODE=cluster spark_workers_health
echo "CLUSTER_STATUS_RC=$?"
echo
echo "=== MODE cluster: probe (packages) ==="
SPARK_EXECUTION_MODE=cluster spark_workers_health --summary >/dev/null 2>&1
if [ "$?" -eq 0 ]; then
  SPARK_EXECUTION_MODE=cluster spark_workers_health --probe --with-packages --master "${SPARK_MASTER_URL:-spark://localhost:7077}"
  echo "CLUSTER_PROBE_RC=$?"
else
  echo "CLUSTER_PROBE_STATUS=SKIP_CLUSTER_MASTER_NOT_AVAILABLE"
  echo "CLUSTER_PROBE_RC=0"
fi
set -e
'
""",
            },
            {
                "title": "Python: Spark 4.1 + Sedona + GraphFrames classpath smoke",
                "text": """%sh
set -euo pipefail
cat > /tmp/zeppelin_spark41_py_smoke.py <<'PY'
from pyspark.sql import SparkSession
from py4j.java_gateway import java_import

spark = SparkSession.builder.appName("zeppelin-spark41-py-smoke").getOrCreate()
java_import(spark._jvm, "org.apache.sedona.sql.utils.SedonaSQLRegistrator")
spark._jvm.org.apache.sedona.sql.utils.SedonaSQLRegistrator.registerAll(spark._jsparkSession)
print("SPARK_VERSION=" + spark.version)
print("SEDONA_WKT=" + spark.sql("SELECT ST_AsText(ST_Point(10.0, 20.0)) AS wkt").collect()[0]["wkt"])
try:
    _ = spark._jvm.org.graphframes.GraphFrame
    print("GRAPHFRAMES_CLASS=OK")
except Exception as exc:  # noqa: BLE001
    print("GRAPHFRAMES_CLASS=FAIL")
    raise
spark.stop()
PY

spark-submit --master 'local[*]' \\
  --conf spark.sql.extensions=org.apache.sedona.sql.SedonaSqlExtensions \\
  --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \\
  --conf spark.kryo.registrator=org.apache.sedona.core.serde.SedonaKryoRegistrator \\
  --packages org.apache.sedona:sedona-spark-shaded-4.0_2.13:1.8.1,org.datasyslab:geotools-wrapper:1.8.1-33.1,io.graphframes:graphframes-spark4_2.13:0.10.0 \\
  /tmp/zeppelin_spark41_py_smoke.py
""",
            },
            {
                "title": "Scala: Spark 4.1 + Sedona + GraphFrames smoke",
                "text": """%sh
set -euo pipefail
cat > /tmp/zeppelin_spark41_scala_smoke.scala <<'SCALA'
import org.graphframes.GraphFrame

println("SPARK_VERSION=" + spark.version)
val wkt = spark.sql("SELECT ST_AsText(ST_Point(1.0, 2.0)) AS wkt").collect()(0).getString(0)
println("SEDONA_WKT=" + wkt)

val vertices = Seq(("a", "Alice"), ("b", "Bob"), ("c", "Cara")).toDF("id", "name")
val edges = Seq(("a", "b"), ("b", "c"), ("c", "a")).toDF("src", "dst")
val g = GraphFrame(vertices, edges)
println("GRAPHFRAMES_INDEGREES=" + g.inDegrees.count())
sys.exit(0)
SCALA

spark-shell --master 'local[*]' \\
  --conf spark.api.mode=classic \\
  --conf spark.sql.extensions=org.apache.sedona.sql.SedonaSqlExtensions \\
  --conf spark.serializer=org.apache.spark.serializer.KryoSerializer \\
  --conf spark.kryo.registrator=org.apache.sedona.core.serde.SedonaKryoRegistrator \\
  --packages org.apache.sedona:sedona-spark-shaded-4.0_2.13:1.8.1,org.datasyslab:geotools-wrapper:1.8.1-33.1,io.graphframes:graphframes-spark4_2.13:0.10.0 \\
  -I /tmp/zeppelin_spark41_scala_smoke.scala
""",
            },
        ]
    return BASE_PARAGRAPHS


def api_request(
    base_url: str,
    method: str,
    path: str,
    payload: dict | None = None,
    timeout_s: int = 20,
) -> dict:
    url = urllib.parse.urljoin(base_url.rstrip("/") + "/", path.lstrip("/"))
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(url, data=data, method=method, headers=headers)
    try:
        with urllib.request.urlopen(req, timeout=timeout_s) as resp:
            raw = resp.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"HTTP {exc.code} {method} {path}: {body}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Connection error for {method} {path}: {exc}") from exc
    try:
        return json.loads(raw)
    except json.JSONDecodeError as exc:
        raise RuntimeError(f"Invalid JSON from {method} {path}: {raw[:400]}") from exc


def wait_for_zeppelin(base_url: str, timeout_s: int) -> None:
    deadline = time.time() + timeout_s
    last_error = "unknown error"
    while time.time() < deadline:
        try:
            res = api_request(base_url, "GET", "/api/version")
            if res.get("status") == "OK":
                return
            last_error = str(res)
        except Exception as exc:  # noqa: BLE001
            last_error = str(exc)
        time.sleep(2)
    raise RuntimeError(f"Timed out waiting for Zeppelin API: {last_error}")


def find_note_id(base_url: str, note_name: str) -> str | None:
    def normalize(name: str) -> str:
        return " ".join(re.sub(r"[^A-Za-z0-9]+", " ", name).split()).lower()

    res = api_request(base_url, "GET", "/api/notebook/")
    if res.get("status") != "OK":
        raise RuntimeError(f"Failed listing notebooks: {res}")
    target_norm = normalize(note_name)
    for note in res.get("body", []):
        note_path = str(note.get("path", ""))
        if normalize(note_path.lstrip("/")) == target_norm:
            return str(note.get("id"))
    return None


def create_note(base_url: str, note_name: str) -> str:
    try:
        res = api_request(base_url, "POST", "/api/notebook/", {"name": note_name})
    except RuntimeError as exc:
        msg = str(exc)
        if "NotePathAlreadyExistsException" in msg:
            existing = find_note_id(base_url, note_name)
            if existing:
                api_request(base_url, "DELETE", f"/api/notebook/{existing}")
                res = api_request(base_url, "POST", "/api/notebook/", {"name": note_name})
            else:
                raise
        else:
            raise
    if res.get("status") != "OK":
        raise RuntimeError(f"Failed creating notebook: {res}")
    note_id = res.get("body")
    if not note_id:
        raise RuntimeError(f"Notebook create returned no id: {res}")
    return str(note_id)


def add_paragraph(base_url: str, note_id: str, title: str, text: str) -> str:
    res = api_request(
        base_url,
        "POST",
        f"/api/notebook/{note_id}/paragraph",
        {"title": title, "text": text},
    )
    if res.get("status") != "OK":
        raise RuntimeError(f"Failed adding paragraph '{title}': {res}")
    para_id = res.get("body")
    if not para_id:
        raise RuntimeError(f"Paragraph create returned no id for '{title}': {res}")
    return str(para_id)


def run_paragraph_and_wait(base_url: str, note_id: str, para_id: str, timeout_s: int) -> str:
    res = api_request(
        base_url,
        "POST",
        f"/api/notebook/job/{note_id}/{para_id}",
        timeout_s=120,
    )
    if res.get("status") not in {"OK", "PENDING"}:
        raise RuntimeError(f"Failed to start paragraph {para_id}: {res}")

    deadline = time.time() + timeout_s
    while time.time() < deadline:
        detail = api_request(base_url, "GET", f"/api/notebook/{note_id}/paragraph/{para_id}")
        if detail.get("status") != "OK":
            time.sleep(1)
            continue
        paragraph = detail.get("body", {})
        status = str(paragraph.get("status", "UNKNOWN"))
        if status in {"FINISHED", "ERROR", "ABORT", "CANCELED"}:
            return status
        time.sleep(2)
    return "TIMEOUT"

def notebook_url(base_url: str, note_id: str, ui: str) -> str:
    b = base_url.rstrip("/")
    if ui == "classic":
        return f"{b}/classic/#/notebook/{note_id}"
    return f"{b}/#/notebook/{note_id}"


def main() -> int:
    parser = argparse.ArgumentParser(description="Seed Zeppelin Sedona/GraphFrames smoke notebook")
    parser.add_argument("--base-url", default="http://127.0.0.1:8081", help="Zeppelin base URL")
    parser.add_argument(
        "--note-name",
        default="Sedona GraphFrames Smoke Test",
        help="Notebook name",
    )
    parser.add_argument(
        "--integration-mode",
        choices=["embedded", "livy", "external"],
        default="embedded",
        help="Zeppelin Spark integration mode",
    )
    parser.add_argument(
        "--run",
        action="store_true",
        help="Run all paragraphs after creating notebook",
    )
    parser.add_argument(
        "--wait-timeout",
        type=int,
        default=240,
        help="Per-paragraph timeout in seconds when --run is set",
    )
    parser.add_argument(
        "--api-timeout",
        type=int,
        default=120,
        help="Wait timeout for Zeppelin API readiness in seconds",
    )
    parser.add_argument(
        "--ui",
        choices=["angular", "classic"],
        default="classic",
        help="Preferred Zeppelin UI route to print/open",
    )
    parser.add_argument(
        "--open-ui",
        action="store_true",
        help="Open resulting notebook URL in browser",
    )
    args = parser.parse_args()

    wait_for_zeppelin(args.base_url, args.api_timeout)

    existing = find_note_id(args.base_url, args.note_name)
    if existing:
        api_request(args.base_url, "DELETE", f"/api/notebook/{existing}")
        print(f"Deleted existing notebook: {args.note_name} ({existing})")

    note_id = create_note(args.base_url, args.note_name)
    print(f"Created notebook: {args.note_name} ({note_id})")

    paragraphs = paragraphs_for_mode(args.integration_mode)
    para_ids: list[str] = []
    for para in paragraphs:
        para_id = add_paragraph(args.base_url, note_id, para["title"], para["text"])
        para_ids.append(para_id)
        print(f"Added paragraph: {para['title']} ({para_id})")

    if args.run:
        failed = False
        for para, para_id in zip(paragraphs, para_ids):
            status = run_paragraph_and_wait(args.base_url, note_id, para_id, args.wait_timeout)
            print(f"Run status [{para['title']}]: {status}")
            if status != "FINISHED":
                failed = True
        if failed:
            print("One or more paragraphs failed. Check Zeppelin paragraph output/logs.", file=sys.stderr)
            url = notebook_url(args.base_url, note_id, args.ui)
            print(f"Notebook URL ({args.ui}): {url}")
            if args.ui != "classic":
                print(f"Notebook URL (classic): {notebook_url(args.base_url, note_id, 'classic')}")
            return 1

    url = notebook_url(args.base_url, note_id, args.ui)
    print(f"Notebook URL ({args.ui}): {url}")
    if args.ui != "classic":
        print(f"Notebook URL (classic): {notebook_url(args.base_url, note_id, 'classic')}")
    if args.open_ui:
        webbrowser.open(url)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
