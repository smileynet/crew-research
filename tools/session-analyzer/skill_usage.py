"""Analyze skill activation and steering compliance from kiro-cli session logs.

Usage:
    python skill_usage.py [--days N] [--output FILE]

Signals (per session):
  - skill activation: read/glob of .kiro/skills/<slug>/SKILL.md, native
    SkillsTool skillName invocations, or /slug user invocation in a prompt
  - steering compliance: recall search before history answers, nohup for eval
    runs, handoff writes
  - tool usage: recall/subagent/web_search shell + tool call counts, per cwd

Caveats (see report): reads only kiro-cli v2 JSONLs; context-injection loads
(steering, eager skills) leave no per-turn marker and are NOT counted;
sessions from this repo's own development inflate counts for skills being
edited (filtered by cwd where possible).
"""
import json
import re
import sys
import time
from collections import Counter, defaultdict
from pathlib import Path

SKILL_READ = re.compile(r'\.kiro[/\\]+skills[/\\]+([a-z][a-z0-9-]+)[/\\]+SKILL\.md')
SKILL_TOOL = re.compile(r'"skillName"\s*:\s*"([a-z][a-z0-9-]+)"')
SLASH = re.compile(r'^/([a-z][a-z-]{2,40})\b')


def parse_args():
    days, output = 30, None
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--days" and i + 1 < len(args):
            days = int(args[i + 1]); i += 2
        elif args[i] == "--output" and i + 1 < len(args):
            output = args[i + 1]; i += 2
        else:
            i += 1
    return days, output


def session_cwd(jsonl_path):
    meta = jsonl_path.with_suffix(".json")
    if meta.exists():
        try:
            return json.loads(meta.read_text(errors="ignore")).get("cwd", "")
        except (json.JSONDecodeError, OSError):
            return ""
    return ""


def user_prompts(text):
    """Yield user message content strings from raw JSONL text."""
    for m in re.finditer(r'USER MESSAGE BEGIN ---\\n(.*?)\\n--- USER MESSAGE END', text):
        yield m.group(1)


def main():
    days, output = parse_args()
    cli_dir = Path.home() / ".kiro" / "sessions" / "cli"
    cutoff = time.time() - days * 86400
    files = [f for f in cli_dir.glob("*.jsonl") if f.stat().st_mtime > cutoff]

    deployed = sorted(
        p.parent.name for p in (Path.home() / ".kiro" / "skills").glob("*/SKILL.md")
    )

    activations = Counter()          # skill -> sessions with any activation signal
    activation_kind = defaultdict(Counter)  # skill -> signal kind counts
    tool_usage = Counter()
    per_project_sessions = Counter()
    compliance = Counter()
    crew_repo_sessions = 0

    for f in files:
        try:
            text = f.read_text(errors="ignore")
        except OSError:
            continue
        cwd = session_cwd(f)
        project = Path(cwd).name if cwd else "unknown"
        per_project_sessions[project] += 1
        is_crew = "crew-research" in cwd
        crew_repo_sessions += is_crew

        session_skills = set()
        for m in SKILL_READ.finditer(text):
            slug = m.group(1)
            # skip crew-research dev sessions touching skill SOURCE files
            if is_crew and ("atomics/skills/" + slug) in text:
                continue
            session_skills.add(slug)
            activation_kind[slug]["file_read"] += 1
        for m in SKILL_TOOL.finditer(text):
            session_skills.add(m.group(1))
            activation_kind[m.group(1)]["native_tool"] += 1
        for prompt in user_prompts(text):
            sm = SLASH.match(prompt)
            if sm and sm.group(1) in deployed:
                session_skills.add(sm.group(1))
                activation_kind[sm.group(1)]["slash_invoke"] += 1
        for s in session_skills:
            activations[s] += 1

        # tool distribution (cheap string counts — approximate)
        for tool in ("web_search", "subagent", "knowledge"):
            n = text.count(f'"name":"{tool}"') + text.count(f'"name": "{tool}"')
            if n:
                tool_usage[tool] += n
        tool_usage["recall_cli"] += len(re.findall(r'recall (search|add|prime|import|ingest)\b', text))

        # steering compliance signals
        if re.search(r'what did we decide|last session|previously', text, re.I):
            compliance["history_questions"] += 1
            if "recall search" in text:
                compliance["history_q_with_recall_search"] += 1
        if "evals/harness/run.sh" in text:
            compliance["eval_run_sessions"] += 1
            if "nohup" in text or "setsid" in text:
                compliance["eval_run_with_nohup"] += 1
        if re.search(r'HANDOFF\.md', text):
            compliance["handoff_touched"] += 1

    never_used = [s for s in deployed if activations[s] == 0]

    report = {
        "window_days": days,
        "sessions": len(files),
        "crew_research_dev_sessions": crew_repo_sessions,
        "deployed_skills": len(deployed),
        "skill_activations_sessions": dict(activations.most_common()),
        "activation_signal_kinds": {k: dict(v) for k, v in activation_kind.items()},
        "never_activated": never_used,
        "tool_usage": dict(tool_usage),
        "sessions_per_project": dict(per_project_sessions.most_common(15)),
        "steering_compliance": dict(compliance),
    }
    out = json.dumps(report, indent=2)
    if output:
        Path(output).write_text(out)
        print(f"Written: {output}")
    else:
        print(out)


if __name__ == "__main__":
    main()
