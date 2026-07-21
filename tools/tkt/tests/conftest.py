"""Shared fixtures — bare remote + clones, ticket factory, subprocess runner.

Everything here operates through public surfaces (files, git, CLI subprocess)
so both the white-box suite (test_tkt.py) and the black-box suite
(test_blackbox.py) can build on it.
"""

from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest

TKT_PKG = Path(__file__).resolve().parents[1]  # tools/tkt
CREW = Path(__file__).resolve().parents[3]     # crew-research root

sys.path.insert(0, str(TKT_PKG))


def git(repo: Path, *args: str) -> str:
    r = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True, check=True)
    return r.stdout.strip()


def make_ticket(d: Path, tid: str, slug: str, status: str = "open", deps: str = "", extra: str = "") -> Path:
    p = d / f"{tid}-{slug}.md"
    p.write_text(
        f'---\nid: "{tid}"\ntitle: "{slug}"\nstatus: {status}\nblocked_by: [{deps}]\n{extra}---\n\n# {slug}\n\n- [ ] TBD\n'
    )
    return p


def run_tkt(repo: Path, *argv: str, env: dict | None = None) -> tuple[int, str]:
    """Run tkt as a subprocess (module mode) — the black-box boundary."""
    e = {**os.environ, **(env or {})}
    r = subprocess.run(
        [sys.executable, "-m", "tkt.cli", *argv],
        capture_output=True, text=True, cwd=str(repo),
        env={**e, "PYTHONPATH": str(TKT_PKG)},
    )
    return r.returncode, r.stdout + r.stderr


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
