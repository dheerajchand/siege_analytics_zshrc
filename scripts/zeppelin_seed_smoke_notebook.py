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

Notebook paragraphs below include Scala/Python Sedona + GraphFrames verification snippets.
Run them with a compatible Zeppelin Spark interpreter, or execute equivalent scripts via
`spark-shell` / `spark-submit` using Spark 4.1 outside Zeppelin.
""",
            },
            *BASE_PARAGRAPHS,
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
        if args.integration_mode == "external":
            print("External integration mode selected; skipping paragraph execution.")
            print(f"Notebook URL: {args.base_url}/#/notebook/{note_id}")
            return 0
        failed = False
        for para, para_id in zip(paragraphs, para_ids):
            status = run_paragraph_and_wait(args.base_url, note_id, para_id, args.wait_timeout)
            print(f"Run status [{para['title']}]: {status}")
            if status != "FINISHED":
                failed = True
        if failed:
            print("One or more paragraphs failed. Check Zeppelin paragraph output/logs.", file=sys.stderr)
            print(f"Notebook URL: {args.base_url}/#/notebook/{note_id}")
            return 1

    print(f"Notebook URL: {args.base_url}/#/notebook/{note_id}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
