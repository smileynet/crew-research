#!/usr/bin/env python3
r"""Windows-native eval runner for crew-research (ticket 147).

The Linux harness (tools/evals/harness/run.sh) can't run on this host: kiro-cli is a
Windows .exe not on the WSL PATH, the activation harness needs the sqlite3 CLI, and
setsid background jobs die when wsl.exe returns. This runner does the same dual-run job
NATIVELY on Windows by invoking kiro-cli.exe directly with KIRO_HOME isolation.

Per task, per condition (with-skill / baseline), per trial:
  1. Build a temp KIRO_HOME containing ONLY the condition's skills.
  2. Run: kiro-cli.exe chat --no-interactive -a --wrap never "<task input>"
  3. Judge the output with kiro-cli.exe against the task's criteria -> integer 1-5.
Emits a scores.jsonl line per def compatible with tools/evals/scripts/confusion-matrix.py
(task_scores[] with {task, condition, avg}).

Usage:
  python run-eval-windows.py <definition.yaml> [--trials N] [--out <dir>]
Env:
  KIRO_CLI_EXE  path to kiro-cli.exe (default: %LOCALAPPDATA%\Kiro-Cli\kiro-cli.exe)
"""
import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
import time
from pathlib import Path

import yaml

REPO = Path(__file__).resolve().parents[2]  # tools/evals/scripts -> repo root
SKILLS_SRC = REPO / "atomics" / "skills"
DEFAULT_EXE = Path(os.environ.get("LOCALAPPDATA", "")) / "Kiro-Cli" / "kiro-cli.exe"
KIRO_EXE = Path(os.environ.get("KIRO_CLI_EXE", str(DEFAULT_EXE)))

ANSI = re.compile(r"\x1b\[[0-9;?]*[a-zA-Z]")


def strip_ansi(s: str) -> str:
    return ANSI.sub("", s)


def _extract_answer(raw: str) -> str:
    """Pull the assistant's final answer text out of kiro-cli's decorated stream.

    kiro-cli prints progress lines then the answer after a '> ' prompt marker. Keep
    everything from the last '> ' onward; fall back to the whole cleaned text.
    """
    clean = strip_ansi(raw or "")
    # The final answer starts after the last standalone "> " marker kiro prints.
    idx = clean.rfind("\n> ")
    if idx == -1 and clean.startswith("> "):
        idx = 0
    if idx != -1:
        clean = clean[idx:].lstrip("\n> ")
    return clean.strip()


def _run_once(query: str, kiro_home: Path, timeout: int) -> str:
    env = dict(os.environ)
    env["KIRO_HOME"] = str(kiro_home)
    try:
        proc = subprocess.run(
            [str(KIRO_EXE), "chat", "--no-interactive", "-a", "--wrap", "never", query],
            capture_output=True, text=True, encoding="utf-8", errors="replace",
            timeout=timeout, env=env, cwd=str(kiro_home),
        )
    except subprocess.TimeoutExpired:
        return "[TIMEOUT]"
    return proc.stdout or ""


def run_kiro(query: str, kiro_home: Path, timeout: int, retries: int = 2) -> str:
    """Invoke kiro-cli.exe with an isolated KIRO_HOME; retry on empty/timeout output.

    Returns the extracted answer text, or "" if still empty after retries (caller
    treats "" as an error, NOT as a low score, so empty generations don't pollute
    the confusion matrix as false negatives).
    """
    for attempt in range(retries + 1):
        answer = _extract_answer(_run_once(query, kiro_home, timeout))
        if answer and answer != "[TIMEOUT]":
            return answer
        time.sleep(2)  # brief backoff before retry
    return ""


def build_home(base: Path, skills: list[str]) -> Path:
    """Create an isolated KIRO_HOME containing only the given skills."""
    home = base / ".kiro"
    (home / "skills").mkdir(parents=True, exist_ok=True)
    for name in skills:
        src = SKILLS_SRC / name
        if src.is_dir():
            shutil.copytree(src, home / "skills" / name, dirs_exist_ok=True)
    return home


JUDGE_TEMPLATE = """You are a strict evaluator scoring an AI assistant's response against a rubric. Read the rubric, then the response, then output your score.

Output format: exactly one line, `SCORE: N` where N is an integer 1-5. No other text.

Guidance:
- Score by the rubric's checklist/criteria ONLY, not your own taste.
- If the rubric rewards NOT fabricating findings (a "PASS" / "well-modeled" case), then a
  response that correctly says the structure is sound with at most minor notes deserves a
  HIGH score (4-5). Do not penalize it for being brief or for declining to refactor.
- If the rubric rewards flagging a problem, only a response that actually identifies the
  specific invalid state / smell deserves a high score.

RUBRIC:
{criteria}

RESPONSE TO SCORE:
{response}

SCORE:"""


def judge(criteria: str, response: str, judge_home: Path, timeout: int, retries: int = 2) -> int:
    """Score 1-5 via kiro-cli; retry on empty/unparseable judge output. Returns 0 if the
    response itself is empty (an errored generation — not a real score)."""
    if not response:
        return 0  # errored/empty generation — sentinel, excluded from scoring
    prompt = JUDGE_TEMPLATE.format(criteria=criteria, response=response[:6000])
    for _ in range(retries + 1):
        out = run_kiro(prompt, judge_home, timeout, retries=1)
        m = re.search(r"SCORE:\s*([1-5])", out)
        if m:
            return int(m.group(1))
        # fallback: last standalone digit
        nums = re.findall(r"\b([1-5])\b", out)
        if nums:
            return int(nums[-1])
    return 0  # unparseable after retries — sentinel


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("definition")
    ap.add_argument("--trials", type=int, default=None)
    ap.add_argument("--out", default=None)
    ap.add_argument("--timeout", type=int, default=180)
    args = ap.parse_args()

    if not KIRO_EXE.exists():
        print(json.dumps({"status": "error", "errors": [f"kiro-cli.exe not found: {KIRO_EXE}"]}))
        return 2

    defn = yaml.safe_load(Path(args.definition).read_text(encoding="utf-8"))
    name = defn["name"]
    trials = args.trials or defn.get("trials", 3)
    timeout = args.timeout or defn.get("timeout", 180)

    # Conditions: prefer explicit conditions:, else legacy skill: -> with-skill/baseline
    conditions = defn.get("conditions")
    if not conditions:
        skill = defn.get("skill")
        conditions = {"with-skill": {"skills": [skill] if skill else []}, "baseline": {"skills": []}}

    tasks = defn["tasks"]
    ts_dir = Path(args.out or (REPO / "tools" / "evals" / "results" / f"win-{time.strftime('%Y%m%dT%H%M%SZ')}"))
    ts_dir.mkdir(parents=True, exist_ok=True)
    outputs_dir = ts_dir / "outputs"
    outputs_dir.mkdir(exist_ok=True)

    # One judge home (no skills) reused across judging calls
    judge_base = Path(tempfile.mkdtemp(prefix="judge-"))
    judge_home = build_home(judge_base, [])

    task_scores = []
    partial_path = ts_dir / "task_scores.partial.jsonl"
    print(f"Running {name}: {len(tasks)} tasks x {len(conditions)} conditions x {trials} trials")
    for t_idx, task in enumerate(tasks):
        task_name = task.get("name", f"task{t_idx}")
        inp = task["input"]
        criteria = task.get("criteria", "Score overall quality 1-5.")
        for cond, spec in conditions.items():
            cbase = Path(tempfile.mkdtemp(prefix=f"eval-{cond}-"))
            chome = build_home(cbase, spec.get("skills", []))
            trial_scores = []
            errors = 0
            for tr in range(trials):
                resp = run_kiro(inp, chome, timeout)
                (outputs_dir / f"{task_name}.{cond}.t{tr}.txt").write_text(resp, encoding="utf-8")
                if not resp:
                    errors += 1
                    print(f"  [{task_name}] {cond} trial{tr}: EMPTY (excluded)")
                    continue
                score = judge(criteria, resp, judge_home, timeout)
                if score == 0:
                    errors += 1
                    print(f"  [{task_name}] {cond} trial{tr}: JUDGE-FAIL (excluded)")
                    continue
                trial_scores.append(score)
                print(f"  [{task_name}] {cond} trial{tr}: {score}")
            # Average over VALID trials only; None avg means all trials errored.
            avg = sum(trial_scores) / len(trial_scores) if trial_scores else None
            rec = {"task": t_idx, "condition": cond, "avg": avg,
                   "scores": trial_scores, "errors": errors}
            task_scores.append(rec)
            with partial_path.open("a", encoding="utf-8") as pf:
                pf.write(json.dumps(rec) + "\n")
            shutil.rmtree(cbase, ignore_errors=True)
    shutil.rmtree(judge_base, ignore_errors=True)

    def cond_avg(cond):
        vals = [ts["avg"] for ts in task_scores if ts["condition"] == cond and ts["avg"] is not None]
        return sum(vals) / len(vals) if vals else 0

    with_avg = cond_avg("with-skill")
    base_avg = cond_avg("baseline")
    row = {
        "name": name, "adapter": "kiro-cli-windows",
        "status": "pass" if with_avg >= defn.get("threshold", 3.0) else "fail",
        "score": with_avg, "with_score": with_avg, "without_score": base_avg,
        "delta": with_avg - base_avg, "task_scores": task_scores,
    }
    scores_path = ts_dir / "scores.jsonl"
    with scores_path.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(row) + "\n")
    print(f"\nwith-skill avg={with_avg:.2f} baseline avg={base_avg:.2f} delta={with_avg-base_avg:+.2f}")
    print(f"scores: {scores_path}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
