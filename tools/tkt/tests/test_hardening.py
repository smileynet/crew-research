"""Pre-launch hardening tests — ticket 45 / R18 + R19. Black-box per R17.

R18: hostile input rejected BEFORE any filesystem write; accepted input
round-trips (validate green immediately after creation).
R19: a lost claim race reports the winner's state and exits 1, leaving the
loser's clone clean and consistent with upstream.
"""

from __future__ import annotations

import json
import subprocess
from pathlib import Path

import pytest

from conftest import git, make_ticket, run_tkt

# ----------------------------------------------------------------- R18: slugs

HOSTILE_SLUGS = [
    "../evil",            # path traversal
    "a/b",                # separator
    "..",                 # dot-only
    "CON",                # reserved device name, case-insensitive
    "nul",                # reserved device name
    "com3",               # reserved device family
    "-leading",           # leading dash (option-like / not in allowlist)
    "UPPER",              # uppercase
    "a_b",                # dash-only allowlist excludes _ (corpora verified)
    "has space",          # whitespace
    "name.",              # trailing dot (Win32 strips silently)
    "foo:bar",            # colon (frontmatter/key hazard, NTFS ADS)
]


@pytest.mark.parametrize("slug", HOSTILE_SLUGS)
def test_hostile_slugs_rejected_before_any_write(repo_pair, slug):
    a, _ = repo_pair
    before_tickets = sorted(p.name for p in (a / ".tickets").glob("*"))
    before_commit = git(a, "rev-parse", "HEAD")

    rc, out = run_tkt(a, "new", slug)

    assert rc != 0, f"hostile slug {slug!r} accepted: {out}"
    # option-shaped slugs ("-leading") are intercepted by argparse; both
    # rejection surfaces are acceptable as long as nothing was written
    assert ("slug" in out.lower()) or ("usage:" in out), f"error must name the problem: {out}"
    assert sorted(p.name for p in (a / ".tickets").glob("*")) == before_tickets, \
        "no file may be created for a rejected slug"
    assert git(a, "rev-parse", "HEAD") == before_commit, "no commit for rejected input"
    # traversal-shaped slugs must not have landed OUTSIDE .tickets/ either
    stray = [p for p in a.rglob("*evil*")] + [p for p in a.parent.glob("*evil*")]
    assert not stray, f"input escaped .tickets/: {stray}"


def test_benign_slugs_accepted(repo_pair):
    a, _ = repo_pair
    for slug in ("on", "42-follow-up", "x", "trailing-"):
        rc, out = run_tkt(a, "new", slug)
        assert rc == 0, f"benign slug {slug!r} rejected: {out}"
    rc, out = run_tkt(a, "validate")
    assert rc == 0 and json.loads(out)["status"] == "pass", out


# ------------------------------------------------------ R18: free text fields

def test_unroundtrippable_title_rejected(repo_pair):
    a, _ = repo_pair
    before = sorted(p.name for p in (a / ".tickets").glob("*"))
    for bad, needle in [
        ('has "quotes"', "double quote"),
        ("back\\slash", "backslash"),
    ]:
        rc, out = run_tkt(a, "new", "ok-slug", "--title", bad)
        assert rc != 0 and needle in out, f"{bad!r}: {out}"
    assert sorted(p.name for p in (a / ".tickets").glob("*")) == before


def test_hostile_but_legal_title_roundtrips(repo_pair):
    """Colons, YAML-boolean bait, and numbers survive create -> parse -> query."""
    a, _ = repo_pair
    title = "on: fire, 1e3 problems: no coercion"
    rc, out = run_tkt(a, "new", "tricky-title", "--title", title)
    assert rc == 0, out
    rc, out = run_tkt(a, "validate")
    assert rc == 0 and json.loads(out)["status"] == "pass", out
    rc, out = run_tkt(a, "query")
    rows = {r["id"]: r for r in map(json.loads, out.strip().splitlines())}
    assert any(r["title"] == title for r in rows.values()), \
        f"title must round-trip verbatim: {rows}"


def test_blocked_by_injection_rejected(repo_pair):
    a, _ = repo_pair
    rc, out = run_tkt(a, "new", "dep-inject", "--blocked-by", '41", "00')
    assert rc != 0 and "blocked-by" in out, out


# ---------------------------------------------------------- R19: claim races

def _seed_contested(a, b, tid="42", slug="contested"):
    make_ticket(a / ".tickets", tid, slug)
    git(a, "add", "--", f".tickets/{tid}-{slug}.md")
    git(a, "commit", "-qm", f"seed {slug}")
    git(a, "push", "-q")
    git(b, "pull", "-q")


def test_lost_claim_race_reports_winner_state(repo_pair):
    """A claims and pushes; stale B claims the same ticket. B must learn who
    won (upstream status in the message), exit 1, and end clean + consistent.

    Root-cause note: same-second claims from identical git identities produce
    byte-identical commits (same SHA) — the push looks 'up-to-date' and BOTH
    parties think they won. The pre-flight fetch check is what catches this;
    distinct identities below keep the fixture realistic either way."""
    a, b = repo_pair
    git(b, "config", "user.email", "b@t")
    git(b, "config", "user.name", "b")
    _seed_contested(a, b)

    rc, out = run_tkt(a, "claim", "42")
    assert rc == 0, out

    # B is stale (hasn't pulled A's claim) and tries the same claim
    rc, out = run_tkt(b, "claim", "42")
    assert rc == 1, f"lost race is a contested outcome (1), not a crash (2): rc={rc} {out}"
    assert "lost claim race" in out and "in_progress" in out and "42" in out, \
        f"loser must see the winner's state: {out}"

    # B's clone stayed clean: no stray local commit, no local file edit
    git(b, "fetch", "-q")
    assert git(b, "rev-list", "--count", "origin/main..HEAD") == "0", \
        "loser must not keep a local claim commit"
    assert git(b, "status", "--porcelain") == "", "loser's tree must stay clean"
    rc, out = run_tkt(b, "validate")
    assert rc == 0 and json.loads(out)["status"] == "pass", out


RACE_HOOK = """#!/bin/sh
# Reject B's first push after promoting A's pre-staged claim onto main —
# forces the race into the residual fetch->push window (backstop path).
if [ ! -f "$GIT_DIR/raced" ]; then
  : > "$GIT_DIR/raced"
  unset GIT_QUARANTINE_PATH GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
  git update-ref refs/heads/main "$(git rev-parse refs/heads/snipe)"
  echo "tkt-test: race lost" >&2
  exit 1
fi
exit 0
"""


def test_lost_claim_race_in_push_window(repo_pair, tmp_path):
    """The winner lands AFTER B's pre-flight fetch: a pre-receive hook promotes
    A's claim mid-push. B's push-CAS backstop must detect, roll back, report."""
    a, b = repo_pair
    remote = tmp_path / "remote.git"
    _seed_contested(a, b)

    # A's winning claim, pre-staged on a side ref (invisible to B's pre-flight)
    p = a / ".tickets" / "42-contested.md"
    p.write_text(p.read_text().replace("status: open", "status: in_progress"))
    git(a, "add", "--", ".tickets/42-contested.md")
    git(a, "commit", "-qm", "chore(tickets): claim 42")
    git(a, "push", "-q", "origin", "HEAD:refs/heads/snipe")

    hook = remote / "hooks" / "pre-receive"
    hook.write_text(RACE_HOOK)
    hook.chmod(0o755)

    rc, out = run_tkt(b, "claim", "42")
    assert rc == 1, f"backstop must report a contested outcome: rc={rc} {out}"
    assert "lost claim race" in out and "in_progress" in out, out

    # rolled back: no local commit ahead, file restored to the winner's state
    git(b, "fetch", "-q")
    assert git(b, "rev-list", "--count", "origin/main..HEAD") == "0"
    assert "status: in_progress" in (b / ".tickets" / "42-contested.md").read_text()
    assert git(b, "status", "--porcelain") == "", git(b, "status", "--porcelain")


def test_unrelated_traffic_rebase_still_works(repo_pair):
    """Push rejected by unrelated upstream commits (not a race on this ticket)
    must transparently rebase and succeed — the pre-R19 behavior preserved."""
    a, b = repo_pair
    _seed_contested(a, b, slug="quiet")

    # unrelated upstream traffic lands after b's last pull; b's pre-flight
    # fetch sees it, but the ticket itself is untouched upstream
    (a / "unrelated.txt").write_text("noise")
    git(a, "add", "--", "unrelated.txt")
    git(a, "commit", "-qm", "unrelated")
    git(a, "push", "-q")

    rc, out = run_tkt(b, "claim", "42")
    assert rc == 0, f"unrelated traffic must not fail a claim: {out}"
    git(b, "fetch", "-q")
    assert git(b, "rev-list", "--count", "HEAD..origin/main") == "0"
