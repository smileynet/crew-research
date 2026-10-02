#!/usr/bin/env python3
"""session_review.py — collect self-improvement candidates from archived
session transcripts (ticket 34; manual counterpart lives in /guidance-sync).

Probes:
  P1 corrections — human messages correcting/redirecting the agent
  P2 friction    — failure bursts indicating stalled work

Pipeline: prefilter (this script, free) -> excerpt files -> optional LLM
confirmation (--confirm, kiro-cli headless) -> digest for HUMAN triage.
This tool NEVER creates tickets (grill Q03 2026-07-19: digest artifact,
human triages; cron graduation only after precision proves out).

Routing (AC2): each finding carries its session's project (cwd sidecar).
Findings about crew-research-deployed guidance (global skills/steering) are
GLOBAL -> proposals become crew-research tickets; findings about a project's
own .kiro/skills, AGENTS.md, or tools/ are LOCAL -> proposals against that
repo. The digest groups candidates per project and marks the crew-research
rows as the global lane.

Detector provenance (spike 2026-07-25, precision study in ticket 34 AC1):
  - templated/agent-authored prompts excluded from P1 (5/7 raw candidates
    were machine prompts before this filter)
  - P2 skips tool results from content-FETCHING tools (fetched-doc tracebacks
    were a false-positive class) and counts DISTINCT failure lines (repeated
    log-noise was another)
  - P1 includes discovery-phrased correction patterns (the FN probe found a
    keyword-free correction); recall stays partial by design — the weekly
    LLM full-pass is the completing move if ever needed

Transcript format (verified 2026-07-25): v1 JSONL lines, user prompts are
kind:Prompt entries; toolUse (name + toolUseId) under AssistantMessage;
ToolResults reference toolUseId. No USER MESSAGE BEGIN wrappers.

Output: JSON summary to stdout (validation contract), digest markdown to
--digest path. Exit 0 (findings are data, not failures); 2 on crash.
"""
import argparse
import json
import re
import sqlite3
import subprocess
import sys
import time
from collections import defaultdict
from pathlib import Path

SESS = Path.home() / ".kiro" / "sessions" / "cli"


def sqlite_db_path() -> Path:
    """v3 session store (ticket 169). Linux XDG + macOS locations."""
    import os
    xdg = os.environ.get("XDG_DATA_HOME")
    candidates = []
    if xdg:
        candidates.append(Path(xdg) / "kiro-cli" / "data.sqlite3")
    candidates.append(Path.home() / ".local" / "share" / "kiro-cli" / "data.sqlite3")
    candidates.append(Path.home() / "Library" / "Application Support" / "kiro-cli" / "data.sqlite3")
    for c in candidates:
        if c.exists():
            return c
    return candidates[0]  # default (may not exist)


def _sqlite_latest_ms(db: Path) -> int:
    """Max updated_at (ms) in conversations_v2, or 0 if unreadable/empty.
    Read-only — the DB may be written live by kiro-cli."""
    try:
        conn = sqlite3.connect(f"file:{db}?mode=ro&immutable=1", uri=True, timeout=5)
        try:
            row = conn.execute("SELECT max(updated_at) FROM conversations_v2").fetchone()
            return int(row[0]) if row and row[0] is not None else 0
        finally:
            conn.close()
    except sqlite3.Error:
        return 0

P1_PATTERNS = [
    r"^no[,.\s]",
    r"\bthat'?s (wrong|not right|not what)\b",
    r"\bnot what i (asked|meant|wanted)\b",
    r"\bi meant\b",
    r"\bundo (that|this|the)\b",
    r"\brevert (that|this)\b",
    r"\byou should have\b",
    r"\bwhy did you\b",
    r"\bstop[,.\s]",
    r"\bdon'?t do that\b",
    r"\bwrong (file|branch|direction|approach)\b",
    r"\bactually[,]? (no|use|do|it should)\b",
    # discovery-phrased corrections (spike FN probe, 2026-07-25)
    r"\bwe need to (re-?do|re-?view|re-?run|fix) .{0,40}(as well|again|too)\b",
    r"\bshould have been\b",
    r"\bthat was (already|supposed to)\b",
]
P2_PATTERNS = [
    r"command not found",
    r"oldStr not found",
    r"No such file or directory",
    r"Traceback \(most recent call last\)",
    r"exit status: [1-9]",
    r"fatal: ",
    r"Error: ",
]
P2_BURST = 4       # distinct failure LINES required
P2_MIN_KINDS = 2   # across at least 2 pattern kinds

# tool results from these tools carry third-party content (docs, search hits)
# — failure text inside them is not OUR friction (spike FP class a)
FETCH_TOOLS = {"web_fetch", "web_search", "knowledge", "introspect",
               "InternalSearch", "ReadInternalWebsites", "InternalCodeSearch"}

TEMPLATED_MARKERS = (
    "## Objective (iteration",
    "Research:",
    "--- CONTEXT ENTRY BEGIN",
)

P1_RE = [re.compile(p, re.IGNORECASE) for p in P1_PATTERNS]
P2_RE = [re.compile(p) for p in P2_PATTERNS]


def session_cwd(jsonl_path: Path) -> str:
    meta = jsonl_path.with_suffix(".json")
    if meta.exists():
        try:
            return json.loads(meta.read_text(errors="ignore")).get("cwd", "")
        except (json.JSONDecodeError, OSError):
            return ""
    return ""


def _texts(node):
    if isinstance(node, str):
        yield node
    elif isinstance(node, dict):
        for k in ("data", "content", "message", "text", "stdout", "stderr"):
            if k in node:
                yield from _texts(node[k])
    elif isinstance(node, list):
        for item in node:
            yield from _texts(item)


def _tool_use_ids(d) -> dict:
    """toolUseId -> tool name from an AssistantMessage line."""
    out = {}
    for c in (d.get("data") or {}).get("content") or []:
        if isinstance(c, dict) and c.get("kind") == "toolUse":
            td = c.get("data") or {}
            if td.get("toolUseId") and td.get("name"):
                out[td["toolUseId"]] = td["name"]
    return out


def scan_session(path: Path):
    """Return (p1_hits, p2_distinct_lines, p2_kinds) for one session."""
    p1_hits = []
    p2_lines = set()
    p2_kinds = set()
    tool_names = {}  # toolUseId -> name

    for line in path.open(errors="ignore"):
        try:
            d = json.loads(line)
        except json.JSONDecodeError:
            continue
        kind = d.get("kind")

        if kind == "Prompt":
            for text in _texts(d.get("data") or {}):
                if len(text) > 2000 or any(m in text for m in TEMPLATED_MARKERS):
                    continue
                for rx in P1_RE:
                    if rx.search(text):
                        p1_hits.append({"pattern": rx.pattern, "excerpt": text[:400]})
                        break
            continue

        if kind == "AssistantMessage":
            tool_names.update(_tool_use_ids(d))

        # P2 scan — skip fetched-content tool results (FP class a)
        data = d.get("data") or {}
        for c in data.get("content") or [data]:
            if isinstance(c, dict) and c.get("kind") == "toolResult":
                tid = (c.get("data") or {}).get("toolUseId", "")
                if tool_names.get(tid) in FETCH_TOOLS:
                    continue
            for text in _texts(c):
                for rx in P2_RE:
                    for m in rx.finditer(text):
                        # distinct-LINE dedupe (FP class b: repeated log noise)
                        ls = text.rfind("\n", 0, m.start()) + 1
                        le = text.find("\n", m.end())
                        p2_lines.add(text[ls: le if le != -1 else m.end() + 120][:200])
                        p2_kinds.add(rx.pattern)
    return p1_hits, p2_lines, p2_kinds


def _add_p2(text, p2_lines, p2_kinds):
    """Shared P2 scan over one text blob (distinct-line dedupe, FP class b)."""
    for rx in P2_RE:
        for m in rx.finditer(text):
            ls = text.rfind("\n", 0, m.start()) + 1
            le = text.find("\n", m.end())
            p2_lines.add(text[ls: le if le != -1 else m.end() + 120][:200])
            p2_kinds.add(rx.pattern)


def scan_v3_conversation(value_json: str):
    """Scan a v3 conversations_v2.value JSON for P1/P2 — mirrors scan_session.
    Format map: tools/session-analyzer/v3-sqlite-format.md."""
    p1_hits, p2_lines, p2_kinds = [], set(), set()
    try:
        v = json.loads(value_json)
    except (json.JSONDecodeError, TypeError):
        return p1_hits, p2_lines, p2_kinds

    for turn in v.get("history") or []:
        if not isinstance(turn, dict):
            continue
        # map tool_use_id -> name from the assistant turn (for FETCH_TOOLS filter)
        tool_names = {}
        a = turn.get("assistant") or {}
        tu = (a.get("ToolUse") or {}).get("tool_uses") or []
        for t in tu:
            if isinstance(t, dict) and t.get("id") and t.get("name"):
                tool_names[t["id"]] = t["name"]

        u = (turn.get("user") or {}).get("content") or {}
        # P1 — user prompt text
        if isinstance(u, dict) and "Prompt" in u:
            text = ((u.get("Prompt") or {}).get("prompt")) or ""
            if isinstance(text, str) and text and len(text) <= 2000 \
                    and not any(mk in text for mk in TEMPLATED_MARKERS):
                for rx in P1_RE:
                    if rx.search(text):
                        p1_hits.append({"pattern": rx.pattern, "excerpt": text[:400]})
                        break
        # P2 — tool results (skip fetched-content tools)
        if isinstance(u, dict) and "ToolUseResults" in u:
            for r in (u.get("ToolUseResults") or {}).get("tool_use_results") or []:
                if not isinstance(r, dict):
                    continue
                if tool_names.get(r.get("tool_use_id", "")) in FETCH_TOOLS:
                    continue
                for text in _texts(r.get("content")):
                    _add_p2(text, p2_lines, p2_kinds)
        # P2 — assistant response text can also carry error strings
        resp = (a.get("Response") or {}).get("content")
        if isinstance(resp, str) and resp:
            _add_p2(resp, p2_lines, p2_kinds)
    return p1_hits, p2_lines, p2_kinds


def iter_sqlite_conversations(db: Path, cutoff_s: float):
    """Yield (conv_id, cwd, value_json) for conversations updated since cutoff.
    Read-only; the DB is written live by kiro-cli."""
    uri = f"file:{db}?mode=ro&immutable=1"
    conn = sqlite3.connect(uri, uri=True, timeout=5)
    try:
        cur = conn.execute(
            "SELECT conversation_id, key, value FROM conversations_v2 "
            "WHERE updated_at >= ? ORDER BY updated_at DESC",
            (int(cutoff_s * 1000),))
        for conv_id, key, value in cur:
            yield conv_id, (key or ""), value
    finally:
        conn.close()


def confirm_with_llm(excerpt_file: Path, probe: str, timeout: int = 120) -> str:
    """Optional headless confirmation leg. Returns verdict text or 'SKIPPED: reason'."""
    import shutil
    if not shutil.which("kiro-cli"):
        return "SKIPPED: kiro-cli not on PATH"
    q = {
        "p1": "Does this transcript excerpt contain a GENUINE user correction (human telling the agent it did something wrong or redirecting a mistaken approach)? Instructions and task descriptions are NOT corrections. Answer VERDICT: GENUINE or VERDICT: NOT, then one line why.",
        "p2": "Do these failure excerpts show GENUINE friction (repeated failures on the same thing, error loops, workarounds)? Red-green test cycles, deliberate probes, and immediately-resolved one-offs are BENIGN. Answer VERDICT: GENUINE or VERDICT: BENIGN, then one line why.",
    }[probe]
    try:
        r = subprocess.run(
            ["kiro-cli", "chat", "--no-interactive", "--trust-tools=read",
             f"Read {excerpt_file} then answer. {q}"],
            capture_output=True, text=True, timeout=timeout)
        m = re.search(r"VERDICT:\s*(\w+)", r.stdout)
        return m.group(0) if m else "SKIPPED: no verdict parsed"
    except (subprocess.TimeoutExpired, OSError) as e:
        return f"SKIPPED: {type(e).__name__}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--days", type=int, default=7)
    ap.add_argument("--confirm", action="store_true",
                    help="LLM-confirm candidates via kiro-cli headless (slower)")
    ap.add_argument("--digest", default="")
    args = ap.parse_args()

    cutoff = time.time() - args.days * 86400

    # Source selection (ticket 169): choose the store with the FRESHER data, not
    # merely "SQLite if it exists". Verified 2026-10-02: on kiro-cli 2.27.0 (TUI
    # client) the live store is JSONL while an older SQLite data.sqlite3 can sit
    # frozen (content max a month stale) with a touched mtime — preferring it by
    # existence alone would read stale data and silently miss all recent sessions.
    # When a true 3.0 build makes SQLite the live store, its max(updated_at) will
    # lead and this picks it automatically. Format map: tools/session-analyzer/v3-sqlite-format.md.
    db = sqlite_db_path()
    sqlite_latest = _sqlite_latest_ms(db) if db.exists() else 0  # ms, 0 if none
    jsonl_latest = 0.0
    if SESS.exists():
        mts = [f.stat().st_mtime for f in SESS.glob("*.jsonl")]
        jsonl_latest = max(mts) * 1000 if mts else 0  # to ms
    use_sqlite = sqlite_latest > jsonl_latest
    source = "sqlite" if use_sqlite else "jsonl"

    date = time.strftime("%Y-%m-%d")
    digest_path = Path(args.digest) if args.digest else Path(f".scratch/session-review-digest-{date}.md")
    exdir = digest_path.parent / f"session-review-excerpts-{date}"
    exdir.mkdir(parents=True, exist_ok=True)

    # Build a uniform work list: (source_id, cwd, scan_fn producing (p1,p2l,p2k))
    units = []  # (sid, cwd)
    results = {}  # sid -> (p1_hits, p2_lines, p2_kinds)
    if use_sqlite:
        try:
            for conv_id, key, value in iter_sqlite_conversations(db, cutoff):
                sid = conv_id[:8]
                units.append((sid, key))
                results[sid] = scan_v3_conversation(value)
        except sqlite3.Error as e:
            # SQLite unreadable -> fall back to JSONL rather than failing silently
            print(f"session_review: sqlite read failed ({e}); falling back to JSONL",
                  file=sys.stderr)
            use_sqlite = False
            source = "jsonl"
    if not use_sqlite:
        files = sorted(f for f in SESS.glob("*.jsonl") if f.stat().st_mtime >= cutoff)
        for f in files:
            sid = f.stem[:8]
            units.append((sid, session_cwd(f)))
            results[sid] = scan_session(f)

    by_project = defaultdict(lambda: {"p1": [], "p2": []})
    scanned = 0
    for sid, cwd in units:
        scanned += 1
        project = Path(cwd).name if cwd else "unknown"
        p1_hits, p2_lines, p2_kinds = results[sid]

        if p1_hits:
            ex = exdir / f"p1-{sid}.md"
            ex.write_text(f"# {sid} ({project})\n\n" + "\n\n---\n\n".join(
                h["excerpt"] for h in p1_hits[:10]))
            rec = {"session": sid, "hits": len(p1_hits), "excerpt_file": str(ex)}
            if args.confirm:
                rec["verdict"] = confirm_with_llm(ex, "p1")
            by_project[project]["p1"].append(rec)
        if len(p2_lines) >= P2_BURST and len(p2_kinds) >= P2_MIN_KINDS:
            ex = exdir / f"p2-{sid}.md"
            ex.write_text(f"# {sid} ({project})\n\n" + "\n\n---\n\n".join(sorted(p2_lines)[:25]))
            rec = {"session": sid, "distinct_failure_lines": len(p2_lines),
                   "excerpt_file": str(ex)}
            if args.confirm:
                rec["verdict"] = confirm_with_llm(ex, "p2")
            by_project[project]["p2"].append(rec)

    # Zero-data guard (ticket 169): a window with no sessions from EITHER store is
    # a loud warning, not a silent pass (the JSONL-dual-write-stopped failure mode).
    if scanned == 0:
        print(f"session_review: WARNING no sessions found in {args.days}d window "
              f"(source={source}, sqlite={'present' if db.exists() else 'absent'}, "
              f"jsonl_dir={'present' if SESS.exists() else 'absent'})", file=sys.stderr)

    # Digest — grouped per project; crew-research rows are the GLOBAL lane
    lines = [f"# Session Review Digest — {date} ({args.days}d, {scanned} sessions, source={source})",
             "",
             "Human triage artifact — this pipeline never creates tickets.",
             "Routing: crew-research rows = GLOBAL lane (proposals become crew-research",
             "tickets); other projects = LOCAL lane (proposals against that repo).",
             ""]
    total_p1 = total_p2 = 0
    for project in sorted(by_project):
        pdata = by_project[project]
        lane = "GLOBAL" if project == "crew-research" else "local"
        lines.append(f"## {project} ({lane})")
        for rec in pdata["p1"]:
            total_p1 += 1
            v = f" — {rec['verdict']}" if "verdict" in rec else ""
            lines.append(f"- P1 correction candidate: session {rec['session']}, {rec['hits']} hit(s){v} → {rec['excerpt_file']}")
        for rec in pdata["p2"]:
            total_p2 += 1
            v = f" — {rec['verdict']}" if "verdict" in rec else ""
            lines.append(f"- P2 friction candidate: session {rec['session']}, {rec['distinct_failure_lines']} distinct failure lines{v} → {rec['excerpt_file']}")
        lines.append("")
    if not by_project:
        lines.append("_No candidates in window._")
    digest_path.write_text("\n".join(lines) + "\n")

    print(json.dumps({
        "status": "pass",
        "window_days": args.days,
        "source": source,
        "sessions_scanned": scanned,
        "p1_candidates": total_p1,
        "p2_candidates": total_p2,
        "confirmed": args.confirm,
        "digest": str(digest_path),
    }, indent=1))
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception as e:  # crash = exit 2 per validation contract
        print(f"session_review: {e}", file=sys.stderr)
        sys.exit(2)
