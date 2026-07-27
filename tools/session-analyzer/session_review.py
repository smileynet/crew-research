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
import subprocess
import sys
import time
from collections import defaultdict
from pathlib import Path

SESS = Path.home() / ".kiro" / "sessions" / "cli"

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
    files = sorted(f for f in SESS.glob("*.jsonl") if f.stat().st_mtime >= cutoff)

    date = time.strftime("%Y-%m-%d")
    digest_path = Path(args.digest) if args.digest else Path(f".scratch/session-review-digest-{date}.md")
    exdir = digest_path.parent / f"session-review-excerpts-{date}"
    exdir.mkdir(parents=True, exist_ok=True)

    by_project = defaultdict(lambda: {"p1": [], "p2": []})
    scanned = 0
    for f in files:
        scanned += 1
        cwd = session_cwd(f)
        project = Path(cwd).name if cwd else "unknown"
        p1_hits, p2_lines, p2_kinds = scan_session(f)

        if p1_hits:
            ex = exdir / f"p1-{f.stem[:8]}.md"
            ex.write_text(f"# {f.stem} ({project})\n\n" + "\n\n---\n\n".join(
                h["excerpt"] for h in p1_hits[:10]))
            rec = {"session": f.stem[:8], "hits": len(p1_hits), "excerpt_file": str(ex)}
            if args.confirm:
                rec["verdict"] = confirm_with_llm(ex, "p1")
            by_project[project]["p1"].append(rec)
        if len(p2_lines) >= P2_BURST and len(p2_kinds) >= P2_MIN_KINDS:
            ex = exdir / f"p2-{f.stem[:8]}.md"
            ex.write_text(f"# {f.stem} ({project})\n\n" + "\n\n---\n\n".join(sorted(p2_lines)[:25]))
            rec = {"session": f.stem[:8], "distinct_failure_lines": len(p2_lines),
                   "excerpt_file": str(ex)}
            if args.confirm:
                rec["verdict"] = confirm_with_llm(ex, "p2")
            by_project[project]["p2"].append(rec)

    # Digest — grouped per project; crew-research rows are the GLOBAL lane
    lines = [f"# Session Review Digest — {date} ({args.days}d, {scanned} sessions)",
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
