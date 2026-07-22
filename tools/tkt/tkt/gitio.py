"""tkt git facade — fetch/stage/commit/push plumbing.

Design authority: design/patterns/surgical-git-side-effects.md (D2a):
staging always takes ONE explicit path; never add -A / add . / commit --all.
"""

from __future__ import annotations

import subprocess
from pathlib import Path


class GitError(Exception):
    pass


def _run(repo: Path, *args: str, check: bool = True) -> subprocess.CompletedProcess:
    r = subprocess.run(["git", "-C", str(repo), *args], capture_output=True, text=True)
    if check and r.returncode != 0:
        raise GitError(f"git {' '.join(args)}: {r.stderr.strip() or r.stdout.strip()}")
    return r


def repo_root(start: Path) -> Path:
    r = _run(start, "rev-parse", "--show-toplevel")
    return Path(r.stdout.strip())


def default_remote_branch(repo: Path) -> str | None:
    r = _run(repo, "symbolic-ref", "--quiet", "refs/remotes/origin/HEAD", check=False)
    if r.returncode == 0 and r.stdout.strip():
        return r.stdout.strip().removeprefix("refs/remotes/")
    for cand in ("origin/main", "origin/master"):
        if _run(repo, "rev-parse", "--verify", "--quiet", cand, check=False).returncode == 0:
            return cand
    return None


def has_remote(repo: Path) -> bool:
    return bool(_run(repo, "remote", check=False).stdout.strip())


def fetch(repo: Path) -> None:
    _run(repo, "fetch", "--quiet")


def remote_ticket_names(repo: Path) -> list[str]:
    """Ticket filenames on the remote default branch (the other sessions' claims)."""
    branch = default_remote_branch(repo)
    if not branch:
        return []
    r = _run(repo, "ls-tree", "-r", "--name-only", branch, "--", ".tickets/", check=False)
    return [line.rsplit("/", 1)[-1] for line in r.stdout.splitlines() if line.endswith(".md")]


def commit_single_file(repo: Path, file: Path, message: str) -> None:
    """Stage exactly one explicit path and commit only that pathspec (D2a)."""
    rel = file.relative_to(repo)
    _run(repo, "add", "--", str(rel))
    _run(repo, "commit", "--quiet", "-m", message, "--only", "--", str(rel))


def commit_files(repo: Path, files: list[Path], message: str) -> None:
    """Atomic multi-file commit for renumber/batch (pattern scope extension
    2026-07-22): every path explicitly staged and tool-edited; the resulting
    commit is verified to contain EXACTLY the edit list, loud failure + rollback
    on mismatch. Bulk staging idioms remain banned."""
    rels = sorted(str(f.relative_to(repo)) for f in files)
    for rel in rels:
        _run(repo, "add", "--", rel)
    _run(repo, "commit", "--quiet", "-m", message, "--only", "--", *rels)
    committed = sorted(
        _run(repo, "diff-tree", "--no-commit-id", "--name-only", "-r", "HEAD").stdout.split()
    )
    if committed != rels:
        _run(repo, "reset", "--quiet", "HEAD~1")
        raise GitError(
            f"staged-set verification failed: commit contained {committed}, expected {rels} — rolled back"
        )


def push(repo: Path) -> bool:
    """Push; False = rejected (lost race), raise on other errors."""
    r = _run(repo, "push", "--quiet", check=False)
    if r.returncode == 0:
        return True
    err = (r.stderr or "").lower()
    if "rejected" in err or "non-fast-forward" in err or "fetch first" in err:
        return False
    raise GitError(f"git push: {r.stderr.strip()}")


def show_upstream_file(repo: Path, rel: str) -> str | None:
    """Content of a file on the remote default branch, or None if absent."""
    branch = default_remote_branch(repo)
    if not branch:
        return None
    r = _run(repo, "show", f"{branch}:{rel}", check=False)
    return r.stdout if r.returncode == 0 else None


def discard_file_changes(repo: Path, rel: str) -> None:
    """Discard local changes to ONE path, restoring the HEAD version
    (explicit-pathspec discipline — never a tree-wide reset)."""
    _run(repo, "checkout", "HEAD", "--", rel)


def undo_commit_keep_file(repo: Path) -> None:
    """Roll back the claim commit after a lost race (file kept, UNTRACKED —
    a mixed reset; staged content would block the pull --rebase that follows)."""
    _run(repo, "reset", "--quiet", "HEAD~1")


def pull_rebase(repo: Path) -> None:
    _run(repo, "pull", "--rebase", "--quiet")
