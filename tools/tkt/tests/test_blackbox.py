"""Black-box acceptance layer — ticket 44 / R17.

Everything here exercises tkt through public surfaces only: the installed
console script, JSON output shapes, exit codes, files, and git state. No
imports from the tkt package, no monkeypatching of internals.

1. Installed-artifact smoke: uv tool install -> `tkt` binary on PATH.
2. Output contracts: real command output validated against
   design/specs/cli-outputs.yaml (the spec YAML is the oracle).
3. Race test: pre-receive hook on the bare remote injects the lost race —
   the renumber path runs end-to-end through real git semantics.
"""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

import pytest

from conftest import CREW, git, make_ticket, run_tkt

CONTRACT_SPEC = CREW / "design" / "specs" / "cli-outputs.yaml"


# ----------------------------------------------- 1. installed-artifact smoke

@pytest.mark.skipif(shutil.which("uv") is None, reason="uv not on PATH — cannot test installed artifact")
def test_installed_console_script_smoke(repo_pair, tmp_path):
    """The `uv tool install` -> `tkt` binary path works (the `npx cdk` failure
    class: entry-point/packaging breaks are invisible to module-mode tests)."""
    a, _ = repo_pair
    make_ticket(a / ".tickets", "42", "openwork")
    git(a, "add", "-A")
    git(a, "commit", "-qm", "open ticket")

    tool_dir = tmp_path / "uv-tools"
    bin_dir = tmp_path / "uv-bin"
    env = {
        **os.environ,
        "UV_TOOL_DIR": str(tool_dir),
        "UV_TOOL_BIN_DIR": str(bin_dir),
        "UV_LINK_MODE": "copy",
    }
    r = subprocess.run(
        ["uv", "tool", "install", "--force", str(CREW / "tools" / "tkt")],
        capture_output=True, text=True, env=env,
    )
    assert r.returncode == 0, f"uv tool install failed:\n{r.stderr}"
    binary = bin_dir / "tkt"
    assert binary.exists(), f"console script not created in {bin_dir}"

    # Run through PATH with the source tree scrubbed from the environment —
    # a passing run must come from the installed artifact alone.
    clean_env = {k: v for k, v in os.environ.items() if k != "PYTHONPATH"}
    clean_env["PATH"] = f"{bin_dir}{os.pathsep}{os.environ['PATH']}"

    r = subprocess.run(["tkt", "ready"], capture_output=True, text=True, cwd=str(a), env=clean_env)
    assert r.returncode == 0 and "42" in r.stdout, f"installed `tkt ready` broken:\n{r.stdout}{r.stderr}"

    r = subprocess.run(["tkt", "validate"], capture_output=True, text=True, cwd=str(a), env=clean_env)
    data = json.loads(r.stdout)
    assert r.returncode == 0 and data["status"] == "pass", f"installed `tkt validate` broken:\n{r.stdout}{r.stderr}"


# ------------------------------------------------------- 2. output contracts

def _load_contract():
    yaml = pytest.importorskip("yaml", reason="PyYAML needed to read the contract oracle")
    return yaml.safe_load(CONTRACT_SPEC.read_text())


_PY_TYPES = {"string": str, "enum": str, "list": list, "map": dict}


def _check_schema(obj: dict, fields: dict, where: str) -> list[str]:
    """Validate one JSON object against a sub_schema's field table."""
    problems = []
    for name, fdef in fields.items():
        if name not in obj:
            if fdef.get("required"):
                problems.append(f"{where}: missing required field {name!r}")
            continue
        v = obj[name]
        want = _PY_TYPES[fdef["type"]]
        if not isinstance(v, want):
            problems.append(f"{where}.{name}: expected {fdef['type']}, got {type(v).__name__} ({v!r})")
        if fdef["type"] == "enum" and v not in fdef["values"]:
            problems.append(f"{where}.{name}: {v!r} not in enum {fdef['values']}")
    for name in obj:
        if name not in fields:
            problems.append(f"{where}: undeclared field {name!r} — update cli-outputs.yaml or drop it")
    return problems


@pytest.fixture
def contract():
    return _load_contract()


def _corpus_with_optionals(a: Path) -> None:
    """Tickets exercising every optional TicketRow field."""
    make_ticket(a / ".tickets", "42", "full-row",
                extra='env: corp\nspec: "ticket-cli"\npriority: high\nlane: alpha\n')
    make_ticket(a / ".tickets", "43", "bare-row")


def test_query_and_ready_rows_honor_contract(repo_pair, contract):
    a, _ = repo_pair
    _corpus_with_optionals(a)
    row_schema = contract["sub_schemas"]["TicketRow"]["fields"]

    for argv in (("query",), ("ready", "--json")):
        rc, out = run_tkt(a, *argv)
        assert rc == 0, out
        rows = [json.loads(line) for line in out.strip().splitlines()]
        assert rows, f"{argv}: no rows"
        problems = [p for i, row in enumerate(rows)
                    for p in _check_schema(row, row_schema, f"{'/'.join(argv)}[{i}]")]
        assert not problems, "\n".join(problems)

    # Optional-field semantics: present only when set in the file
    rc, out = run_tkt(a, "query")
    by_id = {r["id"]: r for r in map(json.loads, out.strip().splitlines())}
    full, bare = by_id["42"], by_id["43"]
    assert full["env"] == "corp" and full["spec"] == "ticket-cli" and full["priority"] == "high"
    assert full["extensions"] == {"lane": "alpha"}, \
        "preserve-or-fail extends to projections: unknown fields must survive into query output"
    for opt in ("env", "spec", "priority", "extensions"):
        assert opt not in bare, f"{opt} must be absent when not set in the file"


def test_validate_output_honors_contract(repo_pair, contract):
    a, _ = repo_pair
    finding_schema = contract["sub_schemas"]["Finding"]["fields"]
    payload = contract["events"]["validate-findings"]["payload"]
    status_values = payload["status"]["values"]

    # pass leg: no contract violations -> status pass, exit 0 (warnings allowed)
    rc, out = run_tkt(a, "validate")
    data = json.loads(out)
    assert data["status"] in status_values
    assert (rc, data["status"]) == (0, "pass"), "exit code must couple to status (0=pass)"
    assert all(f["severity"] == "warning" for f in data["findings"]), \
        "pass status must mean zero error-severity findings"

    # fail leg: violation corpus -> status fail, exit 1, Finding-shaped findings
    make_ticket(a / ".tickets", "50", "dangling", deps='"99"')
    make_ticket(a / ".tickets", "51", "decayed", status="done")  # unchecked ACs -> warning
    rc, out = run_tkt(a, "validate")
    data = json.loads(out)
    assert data["status"] in status_values
    assert (rc, data["status"]) == (1, "fail"), "exit code must couple to status (1=fail)"
    assert data["findings"]
    problems = [p for i, f in enumerate(data["findings"])
                for p in _check_schema(f, finding_schema, f"findings[{i}]")]
    assert not problems, "\n".join(problems)
    severities = {f["severity"] for f in data["findings"]}
    assert severities == {"error", "warning"}, severities


def test_crash_exit_code_is_two(tmp_path):
    """Outside a git repo the tool crashes loudly: exit 2 (crew contract)."""
    plain = tmp_path / "not-a-repo"
    plain.mkdir()
    rc, out = run_tkt(plain, "validate")
    assert rc == 2, f"crash must exit 2, got {rc}: {out}"


# ------------------------------------------------- 3. hook-based race test

RACE_HOOK = """#!/bin/sh
# First push to this remote loses the race: promote the pre-staged snipe
# commit onto main, then reject. Subsequent pushes pass.
if [ ! -f "$GIT_DIR/raced" ]; then
  : > "$GIT_DIR/raced"
  unset GIT_QUARANTINE_PATH GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
  git update-ref refs/heads/main "$(git rev-parse refs/heads/snipe)"
  echo "tkt-test: race lost" >&2
  exit 1
fi
exit 0
"""


def test_new_race_renumbers_end_to_end(repo_pair, tmp_path):
    """Lost race -> renumber, through real git semantics. The competing claim
    lands on origin/main via a pre-receive hook AFTER b's fetch+scan, exactly
    the mid-flight snipe the bounded-retry design (D1a) exists for."""
    a, b = repo_pair
    remote = tmp_path / "remote.git"

    # A's winning claim, pre-staged on a side ref (invisible to b's scan of
    # origin/main until the hook promotes it).
    make_ticket(a / ".tickets", "42", "sniped")
    git(a, "add", "--", ".tickets/42-sniped.md")
    git(a, "commit", "-qm", "chore(tickets): new 42 sniped")
    git(a, "push", "-q", "origin", "HEAD:refs/heads/snipe")

    hook = remote / "hooks" / "pre-receive"
    hook.write_text(RACE_HOOK)
    hook.chmod(0o755)

    rc, out = run_tkt(b, "new", "from-b")
    assert rc == 0, out
    assert "43-from-b" in out and "renumbered" in out, out

    # Final corpus state, asserted on the remote's main branch (the shared truth)
    names = git(remote, "ls-tree", "-r", "--name-only", "main", "--", ".tickets/").splitlines()
    names = sorted(n.rsplit("/", 1)[-1] for n in names)
    assert names == ["41-seed.md", "42-sniped.md", "43-from-b.md"], names

    # b's local file renumbered in both filename and id field
    assert not (b / ".tickets" / "42-from-b.md").exists()
    body = (b / ".tickets" / "43-from-b.md").read_text()
    assert 'id: "43"' in body, "id field must be renumbered with the filename"

    # and the renumbered corpus still validates clean
    rc, out = run_tkt(b, "validate")
    assert rc == 0 and json.loads(out)["status"] == "pass", out
