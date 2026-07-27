"""Tests for recall CLI — subprocess smoke tests for all commands."""

import json
import os
import subprocess
import sys
from pathlib import Path

import pytest

RECALL_CMD = [sys.executable, "-m", "recall.cli"]


@pytest.fixture
def cli_env(tmp_path):
    """Environment with isolated RECALL_DB for CLI subprocess tests."""
    db_path = str(tmp_path / "cli-test.sqlite3")
    env = os.environ.copy()
    env["RECALL_DB"] = db_path
    env["HF_HUB_VERBOSITY"] = "error"
    return env


def run_recall(args: list[str], env: dict, input_text: str = None) -> subprocess.CompletedProcess:
    """Run recall CLI and return the result."""
    return subprocess.run(
        RECALL_CMD + args,
        capture_output=True,
        text=True,
        env=env,
        input=input_text,
        timeout=60,
        cwd=str(Path(__file__).parent.parent),
    )


# ─── Basic commands ───────────────────────────────────────────────

def test_help(cli_env):
    result = run_recall(["--help"], cli_env)
    assert result.returncode == 0
    assert "recall" in result.stdout.lower()


def test_version(cli_env):
    result = run_recall(["--version"], cli_env)
    assert result.returncode == 0
    assert "0.2.0" in result.stdout


def test_no_command_shows_help(cli_env):
    result = run_recall([], cli_env)
    assert result.returncode == 1


# ─── status ───────────────────────────────────────────────────────

def test_status_empty_db(cli_env):
    result = run_recall(["status"], cli_env)
    assert result.returncode == 0
    assert "0 drawers" in result.stdout


# ─── health ───────────────────────────────────────────────────────

def test_health_json(cli_env):
    result = run_recall(["health", "--json"], cli_env)
    assert result.returncode == 0
    data = json.loads(result.stdout)
    assert data["total_chunks"] == 0
    assert data["wing_count"] == 0
    assert isinstance(data["missing_projects"], list)


def test_health_human(cli_env):
    result = run_recall(["health"], cli_env)
    assert result.returncode == 0
    assert "Recall Health" in result.stdout


# ─── add ──────────────────────────────────────────────────────────

def test_add_stores_fact(cli_env):
    result = run_recall(["add", "Test fact for unit testing", "--wing", "test_wing"], cli_env)
    assert result.returncode == 0
    assert "Stored" in result.stdout


def test_add_rejects_too_long(cli_env):
    long_text = "x" * 2001
    result = run_recall(["add", long_text, "--wing", "test"], cli_env)
    assert result.returncode == 1
    assert "too long" in result.stderr.lower() or "too long" in result.stdout.lower()


# ─── search ───────────────────────────────────────────────────────

def test_search_empty_db(cli_env):
    result = run_recall(["search", "test query"], cli_env)
    assert result.returncode == 0
    assert "No results" in result.stdout


def test_search_after_add(cli_env):
    # Add something first
    run_recall(["add", "SQLite is great for local storage", "--wing", "search_test"], cli_env)
    result = run_recall(["search", "SQLite storage"], cli_env)
    assert result.returncode == 0
    # Should find results (not "No results")
    assert "SQLite" in result.stdout or "Results" in result.stdout


# ─── import ───────────────────────────────────────────────────────

def test_import_nonexistent_dir(cli_env):
    result = run_recall(["import", "/nonexistent/path"], cli_env)
    assert result.returncode == 1
    assert "not a directory" in result.stderr.lower() or "not a directory" in result.stdout.lower()


def test_import_empty_dir(cli_env, tmp_path):
    empty_dir = tmp_path / "empty"
    empty_dir.mkdir()
    result = run_recall(["import", str(empty_dir)], cli_env)
    assert result.returncode == 0
    assert "No .md files" in result.stdout


def test_import_with_files(cli_env, tmp_path):
    mem_dir = tmp_path / "memory"
    mem_dir.mkdir()
    (mem_dir / "test.md").write_text("# Test\n\nSome content for import testing.\n")
    result = run_recall(["import", str(mem_dir), "--wing", "import_test"], cli_env)
    assert result.returncode == 0
    assert "new" in result.stdout.lower() or "chunks" in result.stdout.lower()


# ─── forget ───────────────────────────────────────────────────────

def test_forget_requires_wing(cli_env):
    result = run_recall(["forget"], cli_env)
    assert result.returncode != 0
    assert "required" in result.stderr.lower()


def test_forget_dry_run(cli_env):
    # Add data first
    run_recall(["add", "Data to forget", "--wing", "forget_test"], cli_env)
    result = run_recall(["forget", "--wing", "forget_test", "--dry-run"], cli_env)
    assert result.returncode == 0
    assert "dry-run" in result.stdout.lower()
    assert "1" in result.stdout  # 1 chunk


def test_forget_nonexistent_wing(cli_env):
    result = run_recall(["forget", "--wing", "doesnt_exist", "--yes"], cli_env)
    assert result.returncode == 0
    assert "No data" in result.stdout


# ─── gc ───────────────────────────────────────────────────────────

def test_gc_requires_older_than(cli_env):
    result = run_recall(["gc"], cli_env)
    assert result.returncode != 0
    assert "required" in result.stderr.lower()


def test_gc_dry_run_empty(cli_env):
    result = run_recall(["gc", "--older-than", "1", "--dry-run"], cli_env)
    assert result.returncode == 0
    assert "No chunks" in result.stdout


# ─── ingest ───────────────────────────────────────────────────────

def test_ingest_nonexistent_dir(cli_env):
    result = run_recall(["ingest", "/nonexistent/path"], cli_env)
    assert result.returncode == 1


def test_ingest_empty_dir(cli_env, tmp_path):
    empty_dir = tmp_path / "sessions"
    empty_dir.mkdir()
    result = run_recall(["ingest", str(empty_dir)], cli_env)
    assert result.returncode == 0
    assert "0 JSONL" in result.stdout or "no files" in result.stdout.lower()


# ─── prime ────────────────────────────────────────────────────────

def test_prime_outputs_instructions(cli_env):
    result = run_recall(["prime", "--wing", "test"], cli_env)
    assert result.returncode == 0
    assert "Recall" in result.stdout
    assert "recall search" in result.stdout
