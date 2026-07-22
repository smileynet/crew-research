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
    ID_REF_RE,
    STATUS_VALUES,
    Ticket,
    TicketParseError,
    parse_ticket,
    remove_field,
    replace_ref_in_blocked_by,
    requote_like,
    set_field,
    validate_free_text,
    validate_slug,
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
    # R18: validate every argument BEFORE any filesystem operation.
    if err := validate_slug(args.slug):
        sys.exit(f"tkt: {err}")
    title = args.title or args.slug.replace("-", " ")
    for value, what in ((title, "title"), (args.spec or "", "spec")):
        if err := validate_free_text(value, what):
            sys.exit(f"tkt: {err}")
    for dep in (args.blocked_by or "").split(","):
        if dep.strip() and not ID_REF_RE.match(dep.strip()):
            sys.exit(f"tkt: invalid blocked-by ref {dep.strip()!r}")

    d = tickets_dir()
    repo = gitio.repo_root(d)
    remote = gitio.has_remote(repo)
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
            if path.resolve().parent != d.resolve():  # belt-and-braces after allowlist
                sys.exit(f"tkt: slug {args.slug!r} escapes .tickets/")
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


def _upstream_status(repo: Path, t: Ticket) -> str | None:
    upstream = gitio.show_upstream_file(repo, str(t.path.relative_to(repo)))
    m = re.search(r"^status:\s*(\S+)", upstream or "", re.M)
    return m.group(1) if m else None


def _preflight_race_check(repo: Path, t: Ticket, verb: str, lost_states: set[str]) -> None:
    """R19 primary detection: fetch and inspect upstream BEFORE editing.

    Two same-second claims can produce byte-identical commits (same tree,
    parent, author, timestamp -> same SHA), making the push-CAS vacuously
    'succeed' for both parties. Checking upstream first closes that hole and
    reports the winner without ever dirtying the local file.
    """
    if not gitio.has_remote(repo):
        return
    gitio.fetch(repo)
    status = _upstream_status(repo, t)
    if status in lost_states:
        sys.exit(f"tkt: lost {verb} race — {t.id} is already {status} upstream (pull to sync)")


def _commit_and_push(repo: Path, t: Ticket, verb: str, lost_states: set[str]) -> None:
    """Commit the lifecycle edit and push, reporting a lost race informatively.

    R19 backstop: git's push rejection IS the claim CAS for the residual
    fetch->push window. On rejection, inspect the upstream ticket — if its
    status reached a lost-state, someone else won; roll back the local edit,
    report the winner's state, exit 1 (a contested outcome, not a crash).
    Unrelated-traffic rejections rebase and retry once.
    """
    gitio.commit_single_file(repo, t.path, f"chore(tickets): {verb} {t.id}")
    if not gitio.has_remote(repo):
        return
    for attempt in (1, 2):
        if gitio.push(repo):
            return
        gitio.fetch(repo)
        upstream_status = _upstream_status(repo, t)
        if upstream_status in lost_states:
            rel = str(t.path.relative_to(repo))
            gitio.undo_commit_keep_file(repo)
            gitio.discard_file_changes(repo, rel)  # tree clean again
            gitio.pull_rebase(repo)  # fast-forwards to the winner's state
            sys.exit(
                f"tkt: lost {verb} race — {t.id} is already {upstream_status} upstream"
            )
        if attempt == 1:
            gitio.pull_rebase(repo)  # unrelated traffic; our commit rebases cleanly
    sys.exit(f"tkt: push rejected twice for {verb} {t.id} — resolve upstream state manually")


def cmd_claim(args) -> int:
    d = tickets_dir()
    t = _find(load_corpus(d), args.id)
    if t.status != "open":
        sys.exit(f"tkt: {t.id} is {t.status}, not open")
    repo = gitio.repo_root(d)
    lost = {"in_progress", "done"}
    _preflight_race_check(repo, t, "claim", lost)
    set_field(t, "status", "in_progress")
    write_ticket(t)
    _commit_and_push(repo, t, "claim", lost_states=lost)
    print(f"claimed {t.path.name} (in_progress pushed)")
    return 0


def cmd_close(args) -> int:
    d = tickets_dir()
    t = _find(load_corpus(d), args.id)
    if t.status == "done":
        sys.exit(f"tkt: {t.id} is already done")
    repo = gitio.repo_root(d)
    lost = {"done"}
    _preflight_race_check(repo, t, "close", lost)
    set_field(t, "status", "done")
    if "## Resolution" not in t.body:
        t.body = t.body.rstrip("\n") + f"\n\n## Resolution ({date.today().isoformat()})\n\nTBD\n"
    write_ticket(t)
    unchecked = len(UNCHECKED_AC.findall(t.body))
    if unchecked:
        print(f"warning: {unchecked} unchecked acceptance box(es) — fill in before trusting history", file=sys.stderr)
    _commit_and_push(repo, t, "close", lost_states=lost)
    print(f"closed {t.path.name} (dated Resolution stub appended)")
    return 0


# ---------------------------------------------------------------- edit

def cmd_edit(args) -> int:
    """Surgical field corrections (R-evidence: arch 042 born with a wrong
    blocker; hand-edit had no tool support). Set semantics; empty string
    clears an optional field."""
    d = tickets_dir()
    t = _find(load_corpus(d), args.id)
    changed = []

    if args.title is not None:
        if not args.title:
            sys.exit("tkt: title is required and cannot be cleared")
        if err := validate_free_text(args.title, "title"):
            sys.exit(f"tkt: {err}")
        set_field(t, "title", requote_like(t.get("title") or '""', args.title))
        changed.append("title")
    if args.blocked_by is not None:
        deps = [x.strip() for x in args.blocked_by.split(",") if x.strip()]
        for dep in deps:
            if not ID_REF_RE.match(dep):
                sys.exit(f"tkt: invalid blocked-by ref {dep!r}")
        set_field(t, "blocked_by", "[" + ", ".join(f'"{x}"' for x in deps) + "]")
        changed.append("blocked_by")
    for name, value, choices in (
        ("env", args.env, ENV_VALUES),
        ("priority", args.priority, ("high",)),
    ):
        if value is None:
            continue
        if value == "":
            remove_field(t, name)
        elif value not in choices:
            sys.exit(f"tkt: {name} must be one of {'/'.join(choices)} (or '' to clear)")
        else:
            set_field(t, name, value)
        changed.append(name)
    if args.spec is not None:
        if args.spec == "":
            remove_field(t, "spec")
        else:
            if err := validate_free_text(args.spec, "spec"):
                sys.exit(f"tkt: {err}")
            set_field(t, "spec", f'"{args.spec}"')
        changed.append("spec")

    if not changed:
        sys.exit("tkt: nothing to edit — pass at least one field option")
    write_ticket(t)
    repo = gitio.repo_root(d)
    gitio.commit_single_file(repo, t.path, f"chore(tickets): edit {t.id} ({', '.join(changed)})")
    if gitio.has_remote(repo):
        if not gitio.push(repo):
            gitio.pull_rebase(repo)
            if not gitio.push(repo):
                sys.exit(f"tkt: push rejected twice for edit {t.id} — resolve upstream state manually")
    print(f"edited {t.path.name}: {', '.join(changed)}")
    return 0


# ---------------------------------------------------------------- renumber

def cmd_renumber(args) -> int:
    """R12: filename + id field + inbound blocked_by refs move in ONE atomic
    commit (commit_files verifies the staged set). Birth-window operation —
    cited ids are external contracts; a cited old id draws a warning."""
    if not re.fullmatch(r"\d+", args.new_id):
        sys.exit(f"tkt: new id must be digits, got {args.new_id!r}")
    d = tickets_dir()
    repo = gitio.repo_root(d)
    corpus = load_corpus(d)

    holders = [t for t in corpus if t.id == args.old_id]
    if not holders:
        sys.exit(f"tkt: no ticket with id {args.old_id!r}")
    if len(holders) > 1 and not args.file:
        names = ", ".join(t.path.name for t in holders)
        sys.exit(f"tkt: id {args.old_id!r} is held by {len(holders)} files ({names}) — pass --file")
    src = holders[0] if len(holders) == 1 else next(
        (t for t in holders if t.path.name == args.file), None)
    if src is None:
        sys.exit(f"tkt: --file {args.file!r} does not hold id {args.old_id!r}")

    if any(t.id == args.new_id for t in corpus):
        sys.exit(f"tkt: id {args.new_id!r} already exists locally")
    if gitio.has_remote(repo):
        gitio.fetch(repo)
        taken = {n.split("-", 1)[0] for n in gitio.remote_ticket_names(repo)}
        if args.new_id in taken:
            sys.exit(f"tkt: id {args.new_id!r} already exists on origin")

    # cited-id warning: prose references won't follow a renumber
    cited = []
    plan = repo / "docs" / "plan.md"
    if plan.is_file() and re.search(rf"^\|\s*{re.escape(args.old_id)}\s*\|", plan.read_text(), re.M):
        cited.append("docs/plan.md")
    for t in corpus:
        if t is not src and re.search(rf"\b{re.escape(args.old_id)}\b", t.body):
            cited.append(t.path.name)
    if cited:
        print(f"warning: {args.old_id} looks cited in {', '.join(cited)} — "
              "prose/commit references will NOT follow this renumber", file=sys.stderr)

    slug = src.path.name.split("-", 1)[1]  # keep .md suffix
    old_path = src.path
    new_path = d / f"{args.new_id}-{slug}"
    set_field(src, "id", requote_like(src.get("id") or "", args.new_id))
    src.path = new_path
    write_ticket(src)
    old_path.unlink()

    # inbound refs: rewritten only when the old id is vacant after the move
    edited = [old_path, new_path]
    refs_updated = 0
    if len(holders) == 1:
        for t in corpus:
            if t is src or args.old_id not in t.blocked_by:
                continue
            new_raw = replace_ref_in_blocked_by(t.get("blocked_by") or "", args.old_id, args.new_id)
            if new_raw is not None:
                set_field(t, "blocked_by", new_raw.strip())
                write_ticket(t)
                edited.append(t.path)
                refs_updated += 1
    else:
        print(f"note: another file still holds id {args.old_id} — inbound refs left pointing at it",
              file=sys.stderr)

    gitio.commit_files(repo, edited, f"chore(tickets): renumber {args.old_id} -> {args.new_id}")
    if gitio.has_remote(repo):
        if not gitio.push(repo):
            gitio.pull_rebase(repo)
            if not gitio.push(repo):
                sys.exit(f"tkt: push rejected twice for renumber — resolve upstream state manually")
    print(f"renumbered {args.old_id} -> {new_path.name} ({refs_updated} inbound ref(s) updated)")
    return 0


# ---------------------------------------------------------------- sync-plan

PLAN_ROW = re.compile(r"^\|\s*(\d+)\s*\|[^|]*\|([^|]*)\|\s*$", re.M)


def cmd_sync_plan(args) -> int:
    """R9 drift-check: ticket status vs a docs/plan.md-style `| NN | title |
    status |` table. Report-only (crew exit contract: 0=no drift, 1=drift,
    2=crash). Rows whose ticket no longer exists are archived history; open
    tickets missing a row are warnings."""
    d = tickets_dir()
    repo = gitio.repo_root(d)
    plan = Path(args.plan) if args.plan else repo / "docs" / "plan.md"
    if not plan.is_file():
        sys.exit(f"tkt: no plan file at {plan}")

    corpus = {t.id: t for t in load_corpus(d)}
    findings: list[dict] = []
    rows: dict[str, bool] = {}
    for tid, status_cell in PLAN_ROW.findall(plan.read_text(encoding="utf-8")):
        rows[tid] = "✅" in status_cell

    for tid, plan_done in rows.items():
        t = corpus.get(tid)
        if t is None:
            continue  # archived history
        ticket_done = t.status == "done"
        if plan_done != ticket_done:
            findings.append({
                "file": t.path.name, "rule": "plan-status-drift",
                "message": f"plan says {'done' if plan_done else 'not done'}, "
                           f"ticket is {t.status}",
                "severity": "error",
            })
    for tid, t in corpus.items():
        if t.status != "done" and tid not in rows:
            findings.append({
                "file": t.path.name, "rule": "missing-plan-row",
                "message": f"{t.status} ticket has no plan row", "severity": "warning",
            })

    errors = [f for f in findings if f["severity"] == "error"]
    warnings = [f for f in findings if f["severity"] == "warning"]
    status = "fail" if errors or (args.strict and warnings) else "pass"
    print(json.dumps({"status": status, "findings": findings}, indent=2))
    return 1 if status == "fail" else 0


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

    p = sub.add_parser("edit", help="surgical field corrections; '' clears an optional field")
    p.add_argument("id")
    p.add_argument("--title")
    p.add_argument("--blocked-by", dest="blocked_by", metavar="IDS", help="comma-separated ids ('' clears)")
    p.add_argument("--env")
    p.add_argument("--spec")
    p.add_argument("--priority")
    p.set_defaults(fn=cmd_edit)

    p = sub.add_parser("renumber", help="move a ticket to a new id: filename + id + inbound refs, one atomic commit")
    p.add_argument("old_id")
    p.add_argument("new_id")
    p.add_argument("--file", help="disambiguate when two files hold the same id")
    p.set_defaults(fn=cmd_renumber)

    p = sub.add_parser("sync-plan", help="drift-check ticket status vs a plan table (report-only)")
    p.add_argument("--check", action="store_true", required=True, help="report drift (the only mode)")
    p.add_argument("--strict", action="store_true", help="warnings also fail")
    p.add_argument("plan", nargs="?", help="plan file (default: docs/plan.md)")
    p.set_defaults(fn=cmd_sync_plan)

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
