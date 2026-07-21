"""tkt test suite — ticket 40 acceptance criteria.

AC1 frontier parity vs independent computation (+ selection unit rules)
AC2 stale-local allocation past origin's max
AC3 byte-preservation round-trip on an archwright-style ticket
AC4 validate: pass on clean/live corpora, loud fail on violation fixtures
Plus: claim race -> renumber path (D1a), surgical single-file commits (D2a).
"""

from __future__ import annotations

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from tkt import gitio  # noqa: E402
from tkt.cli import cmd_validate, frontier, main  # noqa: E402
from tkt.core import TicketParseError, parse_ticket, set_field, write_ticket  # noqa: E402

CREW = Path(__file__).resolve().parents[3]  # crew-research root


def git(repo: Path, *args: str) -> str:
    r = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True, check=True)
    return r.stdout.strip()


def make_ticket(d: Path, tid: str, slug: str, status: str = "open", deps: str = "", extra: str = "") -> Path:
    p = d / f"{tid}-{slug}.md"
    p.write_text(
        f'---\nid: "{tid}"\ntitle: "{slug}"\nstatus: {status}\nblocked_by: [{deps}]\n{extra}---\n\n# {slug}\n\n- [ ] TBD\n'
    )
    return p


@pytest.fixture
def repo_pair(tmp_path):
    """Bare remote + two clones, each with a seeded .tickets/ corpus."""
    remote = tmp_path / "remote.git"
    subprocess.run(["git", "init", "--bare", "-q", "-b", "main", str(remote)], check=True)
    clones = []
    for name in ("a", "b"):
        c = tmp_path / name
        subprocess.run(["git", "clone", "-q", str(remote), str(c)], check=True)
        git(c, "config", "user.email", "t@t")
        git(c, "config", "user.name", "t")
        clones.append(c)
    a, b = clones
    (a / ".tickets").mkdir()
    make_ticket(a / ".tickets", "41", "seed", status="done")
    git(a, "add", "-A")
    git(a, "commit", "-qm", "seed")
    git(a, "push", "-q", "origin", "HEAD:main")
    git(b, "pull", "-q", "origin", "main")
    for c in clones:
        git(c, "branch", "-q", "--set-upstream-to=origin/main", "main")
    return a, b


def run_tkt(repo: Path, *argv: str, env: dict | None = None) -> tuple[int, str]:
    e = {**os.environ, **(env or {})}
    r = subprocess.run(
        [sys.executable, "-m", "tkt.cli", *argv],
        capture_output=True, text=True, cwd=str(repo),
        env={**e, "PYTHONPATH": str(Path(__file__).resolve().parents[1])},
    )
    return r.returncode, r.stdout + r.stderr


# ------------------------------------------------------------ AC1: frontier

def _tickets(dir: Path):
    return [parse_ticket(p) for p in sorted(dir.glob("*.md"))]


def test_frontier_parity_live_corpus():
    """tkt frontier == independent recomputation over the real crew corpus."""
    corpus = _tickets(CREW / ".tickets")
    got = [t.id for t in frontier(corpus)]
    done = {t.id for t in corpus if t.status == "done"}
    crew_env = os.environ.get("CREW_ENV", "")
    expected = sorted(
        (t for t in corpus
         if t.status == "open"
         and all(d in done for d in t.blocked_by)
         and (not crew_env or t.env in ("either", crew_env))),
        key=lambda t: (t.priority != "high", t.numeric_key()),
    )
    assert got == [t.id for t in expected] and got, "frontier mismatch vs independent computation"


def test_selection_rules(tmp_path):
    d = tmp_path / ".tickets"
    d.mkdir()
    make_ticket(d, "01", "done-dep", status="done")
    make_ticket(d, "02", "plain")
    make_ticket(d, "03", "blocked", deps='"04"')
    make_ticket(d, "04", "wip", status="in_progress")
    make_ticket(d, "05", "urgent", extra="priority: high\n")
    make_ticket(d, "06", "wrong-env", extra="env: personal\n")
    make_ticket(d, "07", "unblocked", deps='"01"')
    os.environ["CREW_ENV"] = "corp"
    try:
        ids = [t.id for t in frontier(_tickets(d))]
    finally:
        os.environ.pop("CREW_ENV")
    assert ids == ["05", "02", "07"], ids  # high jumps; wip/blocked/env-mismatch excluded


# ------------------------------------------------------- AC2: stale-local new

def test_new_allocates_past_origin_max(repo_pair):
    a, b = repo_pair
    # A claims 42 and pushes; B stays stale (tkt's own fetch must see 42)
    rc, out = run_tkt(a, "new", "from-a")
    assert rc == 0 and "42-from-a" in out, out
    rc, out = run_tkt(b, "new", "from-b")
    assert rc == 0 and "43-from-b" in out, f"stale clone must allocate past origin max: {out}"
    assert (b / ".tickets" / "43-from-b.md").exists()


def test_new_race_renumbers(repo_pair, monkeypatch):
    """PUSH_REJECTED path: B loses the race after its fetch, auto-renumbers."""
    a, b = repo_pair
    raced = {"done": False}
    real_fetch = gitio.fetch

    def racing_fetch(repo):
        real_fetch(repo)
        if not raced["done"]:  # A wins the race AFTER B's first fetch+scan
            raced["done"] = True
            rc, out = run_tkt(a, "new", "sniped")
            assert rc == 0 and "42-sniped" in out

    monkeypatch.setattr(gitio, "fetch", racing_fetch)
    rc = main(["new", "from-b"])  # in-process so the monkeypatch applies
    assert rc == 0

    names = sorted(p.name for p in (b / ".tickets").glob("*.md"))
    assert "43-from-b.md" in names and "42-from-b.md" not in names, names
    t = parse_ticket(b / ".tickets" / "43-from-b.md")
    assert t.id == "43", "id field must be renumbered with the filename"


@pytest.fixture(autouse=True)
def _cwd_guard(request, monkeypatch):
    """test_new_race_renumbers runs main() in-process from clone b."""
    if "repo_pair" in request.fixturenames and "race" in request.node.name:
        a, b = request.getfixturevalue("repo_pair")
        monkeypatch.chdir(b)


# -------------------------------------------------- AC3: byte preservation

ARCH_STYLE = (
    "---\n"
    "id: 001\n"
    "title: Bootstrap mise on this machine\n"
    "status: open\n"
    "blocked_by: []\n"
    "created: 2026-07-17\n"
    "---\n\n\n# Bootstrap\n\nProse body with trailing spaces  \nand a list:\n\n- [x] done thing\n"
)


def test_claim_close_preserve_bytes(repo_pair):
    a, _ = repo_pair
    p = a / ".tickets" / "001-bootstrap.md"
    p.write_text(ARCH_STYLE)
    git(a, "add", "-A")
    git(a, "commit", "-qm", "arch-style ticket")
    git(a, "push", "-q")

    rc, out = run_tkt(a, "claim", "001")
    assert rc == 0, out
    after_claim = p.read_text()
    assert "status: in_progress" in after_claim
    assert after_claim.replace("status: in_progress", "status: open") == ARCH_STYLE, \
        "claim must be a single-line surgical edit (created:, unquoted id, prose all byte-identical)"

    rc, out = run_tkt(a, "close", "001")
    assert rc == 0, out
    after_close = p.read_text()
    assert "created: 2026-07-17" in after_close and "id: 001" in after_close
    assert "## Resolution (" in after_close, "dated Resolution stub appended"
    # everything before the appended stub, modulo the status line, is untouched
    prefix = after_close.split("\n\n## Resolution (")[0]
    assert prefix.replace("status: done", "status: open") == ARCH_STYLE.rstrip("\n")


def test_tool_commits_stage_only_ticket(repo_pair):
    """D2a: a dirty tree never leaks into a tool commit."""
    a, _ = repo_pair
    (a / "unrelated.txt").write_text("wip")
    (a / ".tickets" / "41-seed.md").write_text(
        (a / ".tickets" / "41-seed.md").read_text() + "\nhand edit\n"
    )
    rc, out = run_tkt(a, "new", "clean-commit")
    assert rc == 0, out
    committed = git(a, "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD")
    assert committed.splitlines() == [".tickets/42-clean-commit.md"], committed


# ------------------------------------------------------------ AC4: validate

def test_validate_live_corpora_pass():
    for corpus_root in (CREW, Path.home() / "code" / "archwright"):
        rc, out = run_tkt(corpus_root, "validate")
        data = json.loads(out[out.index("{"):])
        assert rc == 0 and data["status"] == "pass", f"{corpus_root}: {data}"


def test_validate_catches_violations(repo_pair):
    a, _ = repo_pair
    d = a / ".tickets"
    make_ticket(d, "50", "dangling", deps='"99"')
    make_ticket(d, "51", "badstatus", status="closed")
    p = d / "52-dup.md"
    p.write_text('---\nid: "41"\ntitle: "dup"\nstatus: open\nblocked_by: []\n---\nx\n')
    (d / "53-broken.md").write_text("no frontmatter at all\n")
    make_ticket(d, "54", "decayed", status="done")  # has "- [ ] TBD" body

    rc, out = run_tkt(a, "validate")
    data = json.loads(out[out.index("{"):])
    rules = {f["rule"] for f in data["findings"]}
    assert rc == 1 and data["status"] == "fail"
    assert {"dangling-blocked-by", "bad-status", "duplicate-id", "unparseable",
            "unchecked-acs-on-done"} <= rules, rules
    named = all(f["file"] for f in data["findings"])
    assert named, "every finding names its file (loud, never anonymous)"


def test_other_commands_fail_loudly_on_unparseable(repo_pair):
    a, _ = repo_pair
    (a / ".tickets" / "60-broken.md").write_text("---\nid: broken only\n")
    rc, out = run_tkt(a, "ready")
    assert rc == 2 and "60-broken.md" in out, \
        f"unparseable ticket must abort ready with the filename, not vanish: {out}"


# ------------------------------------------------------------ parser floor

def test_unknown_fields_survive_rewrite(tmp_path):
    p = tmp_path / "05-x.md"
    p.write_text('---\nid: "05"\ntitle: "x"\nstatus: open\nblocked_by: []\nlane: alpha\nweird_field:   spaced   \n---\nbody\n')
    t = parse_ticket(p)
    set_field(t, "status", "done")
    write_ticket(t)
    out = p.read_text()
    assert "lane: alpha\n" in out and "weird_field:   spaced   \n" in out


def test_duplicate_key_is_parse_error(tmp_path):
    p = tmp_path / "06-x.md"
    p.write_text('---\nid: "06"\ntitle: "x"\nstatus: open\nstatus: done\nblocked_by: []\n---\n')
    with pytest.raises(TicketParseError, match="duplicate"):
        parse_ticket(p)


def test_boolean_prone_keys_stay_text(tmp_path):
    """YAML 1.1 would coerce on:/no: keys to booleans; raw-text parsing must not."""
    p = tmp_path / "07-x.md"
    p.write_text('---\nid: "07"\ntitle: "x"\nstatus: open\nblocked_by: []\non: fire\nno: coercion\n---\nbody\n')
    t = parse_ticket(p)
    assert t.extension_fields() == {"on": "fire", "no": "coercion"}
    assert all(isinstance(k, str) for k, _ in t.fm)
    set_field(t, "status", "done")
    write_ticket(t)
    assert "on: fire\n" in p.read_text() and "no: coercion\n" in p.read_text()


def test_frontier_parity_archwright_corpus():
    arch = Path.home() / "code" / "archwright" / ".tickets"
    if not arch.is_dir():
        pytest.skip("archwright corpus not on this machine")
    corpus = _tickets(arch)
    done = {t.id for t in corpus if t.status == "done"}
    expected = sorted(
        (t for t in corpus if t.status == "open" and all(d in done for d in t.blocked_by)),
        key=lambda t: (t.priority != "high", t.numeric_key()),
    )
    assert [t.id for t in frontier(corpus)] == [t.id for t in expected]
