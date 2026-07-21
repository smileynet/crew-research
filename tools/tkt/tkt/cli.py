"""tkt CLI — ready / new / claim / close / validate / query.

Design authority: design/models/tkt-actors.md, design/specs/*.
Selection: layered-selection (eligibility -> urgency -> ascending id).
Allocation: git-native-claim (fetch -> scan local+origin -> create -> commit ->
push = the claim; rejected push -> re-allocate, max 3 attempts).
"""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from datetime import date
from pathlib import Path

from .core import (
    ENV_VALUES,
    STATUS_VALUES,
    Ticket,
    TicketParseError,
    parse_ticket,
    set_field,
    write_ticket,
)
from . import gitio

MAX_ATTEMPTS = 3
UNCHECKED_AC = re.compile(r"^\s*- \[ \]", re.M)


def tickets_dir(cwd: Path | None = None) -> Path:
    root = gitio.repo_root(cwd or Path.cwd())
    d = root / ".tickets"
    if not d.is_dir():
        sys.exit(f"tkt: no .tickets/ directory in {root}")
    return d


def load_corpus(d: Path) -> list[Ticket]:
    """Parse every ticket. TicketParseError propagates — loud in every command."""
    return [parse_ticket(p) for p in sorted(d.glob("*.md"))]


def _row(t: Ticket) -> dict:
    row = {
        "id": t.id,
        "title": t.title,
        "status": t.status,
        "blocked_by": t.blocked_by,
    }
    for opt in ("env", "spec", "priority"):
        v = t.get(opt)
        if v is not None:
            row[opt] = v.strip().strip('"')
    ext = t.extension_fields()
    if ext:
        row["extensions"] = ext
    return row


# ---------------------------------------------------------------- selection

def frontier(corpus: list[Ticket]) -> list[Ticket]:
    """layered-selection: eligibility -> urgency jump -> ascending numeric id."""
    crew_env = os.environ.get("CREW_ENV", "").strip()
    done = {t.id for t in corpus if t.status == "done"}

    def eligible(t: Ticket) -> bool:
        if t.status != "open":
            return False
        if not all(dep in done for dep in t.blocked_by):
            return False
        if crew_env and t.env not in ("either", crew_env):
            return False
        return True

    pool = [t for t in corpus if eligible(t)]
    return sorted(pool, key=lambda t: (t.priority != "high", t.numeric_key()))


def cmd_ready(args) -> int:
    corpus = load_corpus(tickets_dir())
    rows = frontier(corpus)
    if args.json:
        for t in rows:
            print(json.dumps(_row(t)))
    else:
        for t in rows:
            flag = "  [HIGH]" if t.priority == "high" else ""
            print(f"{t.id}  {t.title}{flag}")
        wip = [t for t in corpus if t.status == "in_progress"]
        if wip:
            print("\nin progress (claimed elsewhere):", ", ".join(t.id for t in wip))
    return 0


def cmd_query(args) -> int:
    for t in load_corpus(tickets_dir()):
        print(json.dumps(_row(t)))
    return 0


# ---------------------------------------------------------------- allocation

def _id_width(names: list[str]) -> int:
    widths = [len(m.group(1)) for n in names if (m := re.match(r"(\d+)-", n))]
    if not widths:
        return 2
    # width used by the numerically largest existing id (the live convention)
    pairs = [(int(m.group(1)), len(m.group(1))) for n in names if (m := re.match(r"(\d+)-", n))]
    return max(pairs)[1]


def _max_id(names: list[str]) -> int:
    ids = [int(m.group(1)) for n in names if (m := re.match(r"(\d+)-", n))]
    return max(ids, default=0)


def _new_ticket_text(tid: str, title: str, args) -> str:
    fm = [f'id: "{tid}"', f'title: "{title}"', "status: open"]
    deps = ", ".join(f'"{d.strip()}"' for d in (args.blocked_by or "").split(",") if d.strip())
    fm.append(f"blocked_by: [{deps}]")
    if args.env:
        fm.append(f"env: {args.env}")
    if args.spec:
        fm.append(f'spec: "{args.spec}"')
    if args.priority:
        fm.append(f"priority: {args.priority}")
    body = f"\n# {title}\n\n## What to build\n\nTBD\n\n## Acceptance criteria\n\n- [ ] TBD\n"
    return "---\n" + "\n".join(fm) + "\n---\n" + body


def cmd_new(args) -> int:
    """Mint-to-announce, one command: fetch -> scan -> create -> commit -> push."""
    d = tickets_dir()
    repo = gitio.repo_root(d)
    remote = gitio.has_remote(repo)
    title = args.title or args.slug.replace("-", " ")
    path = None
    proposed = None
    first_proposed = None

    for attempt in range(1, MAX_ATTEMPTS + 1):
        if remote:
            gitio.fetch(repo)
        names = [p.name for p in d.glob("*.md") if path is None or p != path]
        if remote:
            names += gitio.remote_ticket_names(repo)
        tid = str(_max_id(names) + 1).zfill(_id_width(names))

        if path is None:
            path = d / f"{tid}-{args.slug}.md"
            path.write_text(_new_ticket_text(tid, title, args), encoding="utf-8")
            proposed = first_proposed = tid
        elif tid != proposed:
            new_path = d / f"{tid}-{args.slug}.md"
            t = parse_ticket(path)
            set_field(t, "id", f'"{tid}"')
            t.path = new_path
            write_ticket(t)
            path.unlink()
            path, proposed = new_path, tid

        gitio.commit_single_file(repo, path, f"chore(tickets): new {tid} {args.slug}")
        if not remote:
            print(f"created {path.name} (no remote — claim is local only)")
            return 0
        if gitio.push(repo):
            note = f" (renumbered {first_proposed}→{proposed})" if proposed != first_proposed else ""
            print(f"claimed {path.name}{note}")
            return 0
        # lost race: undo claim commit (file kept, untracked), reconcile, retry
        gitio.undo_commit_keep_file(repo)
        gitio.pull_rebase(repo)

    path.unlink()
    sys.exit(f"tkt: allocation failed after {MAX_ATTEMPTS} attempts (push repeatedly rejected)")


# ---------------------------------------------------------------- lifecycle

def _find(corpus: list[Ticket], tid: str) -> Ticket:
    for t in corpus:
        if t.id == tid:
            return t
    sys.exit(f"tkt: no ticket with id {tid!r}")


def _commit_and_push(repo: Path, t: Ticket, verb: str) -> None:
    gitio.commit_single_file(repo, t.path, f"chore(tickets): {verb} {t.id}")
    if gitio.has_remote(repo):
        if not gitio.push(repo):
            gitio.pull_rebase(repo)
            if not gitio.push(repo):
                sys.exit(f"tkt: push rejected twice for {verb} {t.id} — resolve upstream state manually")


def cmd_claim(args) -> int:
    d = tickets_dir()
    t = _find(load_corpus(d), args.id)
    if t.status != "open":
        sys.exit(f"tkt: {t.id} is {t.status}, not open")
    set_field(t, "status", "in_progress")
    write_ticket(t)
    _commit_and_push(gitio.repo_root(d), t, "claim")
    print(f"claimed {t.path.name} (in_progress pushed)")
    return 0


def cmd_close(args) -> int:
    d = tickets_dir()
    t = _find(load_corpus(d), args.id)
    if t.status == "done":
        sys.exit(f"tkt: {t.id} is already done")
    set_field(t, "status", "done")
    if "## Resolution" not in t.body:
        t.body = t.body.rstrip("\n") + f"\n\n## Resolution ({date.today().isoformat()})\n\nTBD\n"
    write_ticket(t)
    unchecked = len(UNCHECKED_AC.findall(t.body))
    if unchecked:
        print(f"warning: {unchecked} unchecked acceptance box(es) — fill in before trusting history", file=sys.stderr)
    _commit_and_push(gitio.repo_root(d), t, "close")
    print(f"closed {t.path.name} (dated Resolution stub appended)")
    return 0


# ---------------------------------------------------------------- validate

def _cycles(tickets: dict[str, list[str]]) -> list[str]:
    state: dict[str, int] = {}
    cyclic: list[str] = []

    def visit(node: str, stack: list[str]) -> None:
        state[node] = 1
        for dep in tickets.get(node, []):
            if state.get(dep) == 1:
                cyclic.append(" -> ".join(stack + [node, dep]))
            elif state.get(dep, 0) == 0 and dep in tickets:
                visit(dep, stack + [node])
        state[node] = 2

    for n in tickets:
        if state.get(n, 0) == 0:
            visit(n, [])
    return cyclic


def cmd_validate(args) -> int:
    d = tickets_dir()
    findings: list[dict] = []

    def add(file: str, rule: str, message: str, severity: str) -> None:
        findings.append({"file": file, "rule": rule, "message": message, "severity": severity})

    corpus: list[Ticket] = []
    for p in sorted(d.glob("*.md")):
        try:
            corpus.append(parse_ticket(p))
        except TicketParseError as e:
            rule = "missing-required-field" if e.reason.startswith("missing required field") else "unparseable"
            add(p.name, rule, e.reason, "error")

    ids: dict[str, str] = {}
    for t in corpus:
        name = t.path.name
        if t.status not in STATUS_VALUES:
            add(name, "bad-status", f"status {t.status!r} not in {'/'.join(STATUS_VALUES)}", "error")
        env = t.get("env")
        if env is not None and env.strip() not in ENV_VALUES:
            add(name, "bad-env", f"env {env.strip()!r} not in {'/'.join(ENV_VALUES)}", "error")
        if not name.startswith(f"{t.id}-"):
            add(name, "id-filename-mismatch", f"id {t.id!r} vs filename", "error")
        if t.id in ids:
            add(name, "duplicate-id", f"id {t.id!r} also in {ids[t.id]}", "error")
        ids.setdefault(t.id, name)

    known = {t.id for t in corpus}
    graph = {t.id: t.blocked_by for t in corpus}
    for t in corpus:
        for dep in t.blocked_by:
            if dep not in known:
                add(t.path.name, "dangling-blocked-by", f"ref {dep!r} has no ticket", "error")
    for cyc in _cycles(graph):
        add("(graph)", "cyclic-blocked-by", cyc, "error")

    for t in corpus:
        if t.status == "done" and (n := len(UNCHECKED_AC.findall(t.body))):
            add(t.path.name, "unchecked-acs-on-done", f"{n} unchecked box(es)", "warning")

    errors = [f for f in findings if f["severity"] == "error"]
    warnings = [f for f in findings if f["severity"] == "warning"]
    status = "fail" if errors or (args.strict and warnings) else "pass"
    print(json.dumps({"status": status, "findings": findings}, indent=2))
    return 1 if status == "fail" else 0


# ---------------------------------------------------------------- main

def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(prog="tkt", description="Git-native ticket CLI (.tickets/ contract)")
    sub = ap.add_subparsers(dest="command", required=True)

    p = sub.add_parser("ready", help="frontier: open + deps done + env match; high first, then id")
    p.add_argument("--json", action="store_true")
    p.set_defaults(fn=cmd_ready)

    p = sub.add_parser("new", help="allocate + claim a new ticket (fetch, scan, create, commit, push)")
    p.add_argument("slug")
    p.add_argument("--title")
    p.add_argument("--spec")
    p.add_argument("--env", choices=list(ENV_VALUES))
    p.add_argument("--priority", choices=["high"])
    p.add_argument("--blocked-by", dest="blocked_by", metavar="IDS", help="comma-separated ids")
    p.set_defaults(fn=cmd_new)

    p = sub.add_parser("claim", help="mark open ticket in_progress (pushed = visible WIP)")
    p.add_argument("id")
    p.set_defaults(fn=cmd_claim)

    p = sub.add_parser("close", help="mark done, append dated Resolution stub, warn unchecked ACs")
    p.add_argument("id")
    p.set_defaults(fn=cmd_close)

    p = sub.add_parser("validate", help="contract + decay findings as JSON (exit 0 pass / 1 fail)")
    p.add_argument("--strict", action="store_true", help="warnings also fail")
    p.set_defaults(fn=cmd_validate)

    p = sub.add_parser("query", help="all tickets as JSON lines")
    p.set_defaults(fn=cmd_query)

    args = ap.parse_args(argv)
    try:
        return args.fn(args)
    except TicketParseError as e:
        print(f"tkt: unparseable ticket — {e}", file=sys.stderr)
        return 2
    except gitio.GitError as e:
        print(f"tkt: {e}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
