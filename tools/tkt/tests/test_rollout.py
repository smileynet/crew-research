"""Rollout command tests — ticket 41 / R17 black-box.

edit: surgical field corrections, clear semantics, validation.
renumber: atomic multi-file move on the 37↔39 collision shape, staged-set
verification, inbound ref rewriting, cited-id warning.
sync-plan --check: drift vs a plan table, contract-shaped output.
"""

from __future__ import annotations

import json

import pytest

from conftest import CREW, git, make_ticket, run_tkt


def _contract():
    yaml = pytest.importorskip("yaml", reason="PyYAML needed to read the contract oracle")
    return yaml.safe_load((CREW / "design" / "specs" / "cli-outputs.yaml").read_text())


# ---------------------------------------------------------------------- edit

def test_edit_sets_and_clears_fields(repo_pair):
    a, _ = repo_pair
    make_ticket(a / ".tickets", "42", "editable", extra="env: corp\n")
    git(a, "add", "-A")
    git(a, "commit", "-qm", "seed")
    git(a, "push", "-q")

    rc, out = run_tkt(a, "edit", "42", "--blocked-by", "41", "--priority", "high",
                      "--spec", "ticket-cli", "--env", "")
    assert rc == 0 and "blocked_by" in out and "priority" in out, out

    rc, out = run_tkt(a, "query")
    row = next(r for r in map(json.loads, out.strip().splitlines()) if r["id"] == "42")
    assert row["blocked_by"] == ["41"]
    assert row["priority"] == "high" and row["spec"] == "ticket-cli"
    assert "env" not in row, "empty string must CLEAR the optional field"

    # the edit is a surgical single-file commit, pushed
    committed = git(a, "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD")
    assert committed.splitlines() == [".tickets/42-editable.md"], committed
    git(a, "fetch", "-q")
    assert git(a, "rev-list", "--count", "origin/main..HEAD") == "0", "edit must push"

    rc, out = run_tkt(a, "validate")
    assert rc == 0 and json.loads(out)["status"] == "pass", out


def test_edit_rejects_bad_input(repo_pair):
    a, _ = repo_pair
    rc, out = run_tkt(a, "edit", "41", "--title", 'bad "quote"')
    assert rc != 0 and "double quote" in out, out
    rc, out = run_tkt(a, "edit", "41", "--blocked-by", '4","x')
    assert rc != 0 and "blocked-by" in out, out
    rc, out = run_tkt(a, "edit", "41")
    assert rc != 0 and "nothing to edit" in out, out


# ------------------------------------------------------------------ renumber

def _collision_fixture(a):
    """The 37↔39 shape: two sessions minted the same id; one file must move.
    A third ticket blocks on the id that will become vacant... but here the
    duplicate keeps 37 occupied, so refs must NOT be rewritten."""
    d = a / ".tickets"
    p = d / "37-first.md"
    p.write_text('---\nid: "37"\ntitle: "first"\nstatus: open\nblocked_by: []\n---\nx\n')
    q = d / "37b-second.md"  # collision reconciliation input: same id, second file
    q.write_text('---\nid: "37"\ntitle: "second"\nstatus: open\nblocked_by: []\n---\ny\n')
    make_ticket(d, "38", "dependent", deps='"37"')
    git(a, "add", "-A")
    git(a, "commit", "-qm", "collision state")
    git(a, "push", "-q")


def test_renumber_duplicate_id_collision(repo_pair):
    a, _ = repo_pair
    _collision_fixture(a)

    # ambiguous without --file
    rc, out = run_tkt(a, "renumber", "37", "39")
    assert rc != 0 and "--file" in out, out

    rc, out = run_tkt(a, "renumber", "37", "39", "--file", "37b-second.md")
    assert rc == 0 and "39-second.md" in out, out
    # duplicate remained at 37 -> inbound refs untouched
    assert "0 inbound ref(s)" in out, out

    d = a / ".tickets"
    assert not (d / "37b-second.md").exists()
    body = (d / "39-second.md").read_text()
    assert 'id: "39"' in body
    row = json.loads([l for l in run_tkt(a, "query")[1].splitlines() if '"38"' in l][0])
    assert row["blocked_by"] == ["37"], "refs must still point at the remaining holder"

    rc, out = run_tkt(a, "validate")
    assert rc == 0 and json.loads(out)["status"] == "pass", out


def test_renumber_rewrites_inbound_refs_atomically(repo_pair):
    a, _ = repo_pair
    d = a / ".tickets"
    make_ticket(d, "50", "mover")
    make_ticket(d, "51", "depends-on-mover", deps='"50"')
    (a / "wip.txt").write_text("operator dirt")  # must never ride along
    git(a, "add", "--", ".tickets")
    git(a, "commit", "-qm", "seed")
    git(a, "push", "-q")

    rc, out = run_tkt(a, "renumber", "50", "60")
    assert rc == 0 and "60-mover.md" in out and "1 inbound ref(s)" in out, out

    # ONE commit containing exactly: old path (deletion), new path, edited ref
    committed = sorted(git(a, "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD").splitlines())
    assert committed == [".tickets/50-mover.md", ".tickets/51-depends-on-mover.md",
                         ".tickets/60-mover.md"], committed
    row = json.loads([l for l in run_tkt(a, "query")[1].splitlines() if '"51"' in l][0])
    assert row["blocked_by"] == ["60"]
    rc, out = run_tkt(a, "validate")
    assert rc == 0 and json.loads(out)["status"] == "pass", out


def test_renumber_unquoted_id_style_preserved(repo_pair):
    """Archwright-style unquoted ids keep their quoting through a renumber."""
    a, _ = repo_pair
    p = a / ".tickets" / "050-arch.md"
    p.write_text("---\nid: 050\ntitle: arch style\nstatus: open\nblocked_by: []\ncreated: 2026-07-01\n---\nz\n")
    git(a, "add", "-A")
    git(a, "commit", "-qm", "arch")
    git(a, "push", "-q")
    rc, out = run_tkt(a, "renumber", "050", "060")
    assert rc == 0, out
    body = (a / ".tickets" / "060-arch.md").read_text()
    assert "id: 060\n" in body and '"' not in body.split("\n")[1], body
    assert "created: 2026-07-01" in body, "unknown fields preserved through renumber"


def test_renumber_warns_on_cited_id(repo_pair):
    a, _ = repo_pair
    d = a / ".tickets"
    make_ticket(d, "50", "famous")
    p = d / "51-citer.md"
    p.write_text('---\nid: "51"\ntitle: "citer"\nstatus: open\nblocked_by: []\n---\nSee ticket 50 for context.\n')
    git(a, "add", "-A")
    git(a, "commit", "-qm", "seed")
    git(a, "push", "-q")
    rc, out = run_tkt(a, "renumber", "50", "70")
    assert rc == 0 and "cited" in out and "51-citer.md" in out, out


def test_renumber_refuses_taken_id(repo_pair):
    a, _ = repo_pair
    rc, out = run_tkt(a, "renumber", "41", "41")
    assert rc != 0 and "already exists" in out, out


# ----------------------------------------------------------------- sync-plan

PLAN = """# Plan

| Area | Contents |
|------|----------|
| x    | not a ticket row |

| 41 | seed ticket | ✅ done |
| 42 | drifted | open — still says open |
| 99 | archived history, no ticket file | ✅ done |
"""


def test_sync_plan_check_reports_drift(repo_pair):
    a, _ = repo_pair
    d = a / ".tickets"
    make_ticket(d, "42", "drifted", status="done")   # plan says open -> drift
    make_ticket(d, "43", "unlisted")                  # open, no plan row -> warning
    (a / "docs").mkdir()
    (a / "docs" / "plan.md").write_text(PLAN)
    # NOTE: seed ticket 41 is done in the fixture corpus; plan row agrees

    rc, out = run_tkt(a, "sync-plan", "--check")
    data = json.loads(out)
    assert (rc, data["status"]) == (1, "fail"), f"drift must exit 1: {rc} {out}"
    rules = {(f["rule"], f["file"]) for f in data["findings"]}
    assert ("plan-status-drift", "42-drifted.md") in rules, rules
    assert ("missing-plan-row", "43-unlisted.md") in rules, rules
    assert not any(f["file"].startswith("99") for f in data["findings"]), \
        "archived plan rows (no ticket file) are ignored"

    # contract shape: PlanFinding fields/enums, status enum (oracle = spec YAML)
    contract = _contract()
    pf = contract["sub_schemas"]["PlanFinding"]["fields"]
    for f in data["findings"]:
        assert set(f) == set(pf), f
        assert f["rule"] in pf["rule"]["values"] and f["severity"] in pf["severity"]["values"]
    assert data["status"] in contract["events"]["sync-plan-findings"]["payload"]["status"]["values"]


def test_sync_plan_clean_and_strict(repo_pair):
    a, _ = repo_pair
    (a / "docs").mkdir()
    (a / "docs" / "plan.md").write_text("| 41 | seed | ✅ done |\n")
    rc, out = run_tkt(a, "sync-plan", "--check")
    assert rc == 0 and json.loads(out)["status"] == "pass", out

    make_ticket(a / ".tickets", "42", "unlisted")
    rc, out = run_tkt(a, "sync-plan", "--check")
    assert rc == 0, "warnings alone must not fail without --strict"
    rc, out = run_tkt(a, "sync-plan", "--check", "--strict")
    assert rc == 1, "--strict promotes warnings to failure"
