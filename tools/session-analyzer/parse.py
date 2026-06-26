"""Parse kiro-cli session JSONL files and extract structured metrics.

Usage:
    python parse.py [--days N] [--output FILE]

Reads from ~/.kiro/sessions/cli/ and produces a JSON summary.
"""
import json
import sys
import os
from pathlib import Path
from datetime import datetime, timedelta
from collections import Counter, defaultdict

def parse_args():
    days = 2
    output = None
    args = sys.argv[1:]
    i = 0
    while i < len(args):
        if args[i] == "--days" and i + 1 < len(args):
            days = int(args[i + 1])
            i += 2
        elif args[i] == "--output" and i + 1 < len(args):
            output = args[i + 1]
            i += 2
        else:
            i += 1
    return days, output

def find_sessions(days):
    sessions_dir = Path.home() / ".kiro" / "sessions"
    cli_dir = sessions_dir / "cli"
    cutoff = datetime.now() - timedelta(days=days)
    files = []
    # V2: ~/.kiro/sessions/cli/*.jsonl
    if cli_dir.exists():
        for f in cli_dir.glob("*.jsonl"):
            if datetime.fromtimestamp(f.stat().st_mtime) > cutoff:
                files.append(f)
    # V3: ~/.kiro/sessions/<hash>/sess_*/messages.jsonl
    for f in sessions_dir.glob("*/sess_*/messages.jsonl"):
        if datetime.fromtimestamp(f.stat().st_mtime) > cutoff:
            files.append(f)
    return sorted(files, key=lambda f: f.stat().st_mtime)

def extract_shell_command(tool_input):
    if isinstance(tool_input, dict) and "command" in tool_input:
        return tool_input["command"]
    return None

def extract_working_dir(tool_input):
    if isinstance(tool_input, dict) and "working_dir" in tool_input:
        return tool_input["working_dir"]
    return None

def parse_conversation(filepath):
    is_v3 = filepath.name == "messages.jsonl"
    result = {
        "file": str(filepath),
        "session_id": filepath.parent.name if is_v3 else filepath.parent.name,
        "conversation_id": filepath.parent.name if is_v3 else filepath.stem,
        "messages": 0,
        "user_prompts": [],
        "tool_calls": Counter(),
        "shell_commands": [],
        "working_dirs": set(),
        "errors": [],
        "first_timestamp": None,
        "last_timestamp": None,
    }

    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                msg = json.loads(line)
            except json.JSONDecodeError:
                continue

            result["messages"] += 1

            if is_v3:
                _parse_v3_event(msg, result)
            else:
                _parse_v2_event(msg, result)

    result["working_dirs"] = list(result["working_dirs"])
    result["tool_calls"] = dict(result["tool_calls"])
    return result


def _parse_v2_event(msg, result):
    kind = msg.get("kind")
    data = msg.get("data", {})

    if kind == "Prompt":
        ts = data.get("meta", {}).get("timestamp")
        if ts:
            if not result["first_timestamp"] or ts < result["first_timestamp"]:
                result["first_timestamp"] = ts
            if not result["last_timestamp"] or ts > result["last_timestamp"]:
                result["last_timestamp"] = ts
        for content in data.get("content", []):
            if content.get("kind") == "text" and content.get("data"):
                result["user_prompts"].append(content["data"][:200])

    elif kind == "AssistantMessage":
        for content in data.get("content", []):
            if content.get("kind") == "toolUse":
                tool_data = content.get("data", {})
                tool_name = tool_data.get("name", "unknown")
                result["tool_calls"][tool_name] += 1
                tool_input = tool_data.get("input", {})
                if tool_name == "shell":
                    cmd = extract_shell_command(tool_input)
                    if cmd:
                        result["shell_commands"].append(cmd)
                    wd = extract_working_dir(tool_input)
                    if wd:
                        result["working_dirs"].add(wd)

    elif kind == "ToolResults":
        for content in data.get("content", []):
            if content.get("kind") == "toolResult":
                tr_data = content.get("data", {})
                if tr_data.get("status") == "error":
                    result["errors"].append(str(tr_data.get("content", ""))[:200])


def _parse_v3_event(msg, result):
    payload = msg.get("payload", {})
    ptype = payload.get("type")
    ts = msg.get("timestamp")

    if ptype == "user":
        if ts:
            if not result["first_timestamp"] or ts < result["first_timestamp"]:
                result["first_timestamp"] = ts
            if not result["last_timestamp"] or ts > result["last_timestamp"]:
                result["last_timestamp"] = ts
        text = payload.get("content", "")
        if text:
            result["user_prompts"].append(text[:200])

    elif ptype == "assistant":
        if ts:
            if not result["last_timestamp"] or ts > result["last_timestamp"]:
                result["last_timestamp"] = ts
        # V3 assistant content is plain text (tool calls are separate events)
        pass

    elif ptype == "tool_use":
        tool_name = payload.get("toolName", "unknown")
        result["tool_calls"][tool_name] += 1
        tool_input = payload.get("input", {})
        if tool_name == "shell":
            cmd = extract_shell_command(tool_input)
            if cmd:
                result["shell_commands"].append(cmd)
            wd = extract_working_dir(tool_input)
            if wd:
                result["working_dirs"].add(wd)

    elif ptype == "tool_result":
        if payload.get("status") == "error":
            result["errors"].append(str(payload.get("content", ""))[:200])

def infer_project(conversation):
    dirs = conversation["working_dirs"]
    if dirs:
        # Most common working dir prefix
        for d in dirs:
            parts = Path(d).parts
            for i, p in enumerate(parts):
                if p == "code" and i + 1 < len(parts):
                    return parts[i + 1]
    # Try from first user prompt
    for prompt in conversation["user_prompts"]:
        if "code/" in prompt or "code\\" in prompt:
            idx = prompt.find("code/") or prompt.find("code\\")
            if idx > 0:
                rest = prompt[idx + 5:]
                return rest.split("/")[0].split("\\")[0].split(" ")[0]
    return "unknown"

def aggregate(conversations):
    total_tool_calls = Counter()
    total_shell_commands = []
    projects = Counter()
    all_errors = []

    for c in conversations:
        total_tool_calls.update(c["tool_calls"])
        total_shell_commands.extend(c["shell_commands"])
        project = infer_project(c)
        projects[project] += 1
        all_errors.extend(c["errors"])

    # Normalize shell commands for frequency analysis
    cmd_freq = Counter()
    for cmd in total_shell_commands:
        # Extract the base command (first token or recognizable pattern)
        normalized = normalize_command(cmd)
        cmd_freq[normalized] += 1

    return {
        "period_days": None,  # set by caller
        "conversations": len(conversations),
        "total_messages": sum(c["messages"] for c in conversations),
        "tool_call_frequency": dict(total_tool_calls.most_common(20)),
        "shell_command_frequency": dict(cmd_freq.most_common(30)),
        "raw_shell_commands": total_shell_commands,
        "projects": dict(projects.most_common(20)),
        "error_count": len(all_errors),
        "errors_sample": all_errors[:20],
    }

def normalize_command(cmd):
    """Reduce a shell command to its essential pattern for frequency counting."""
    cmd = cmd.strip()
    # Multi-line commands: take first meaningful line
    lines = [l.strip() for l in cmd.split("\n") if l.strip() and not l.strip().startswith("#")]
    if not lines:
        return cmd[:80]
    first = lines[0]
    # Common patterns
    if first.startswith("git "):
        parts = first.split()
        return " ".join(parts[:3]) if len(parts) > 2 else first
    if first.startswith("cd "):
        return "cd <dir>"
    if "Get-ChildItem" in first:
        return "Get-ChildItem ..."
    if "Remove-Item" in first:
        return "Remove-Item ..."
    if "Test-Path" in first:
        return "Test-Path ..."
    if "Get-Content" in first:
        return "Get-Content ..."
    if "ConvertFrom-Json" in first:
        return "... | ConvertFrom-Json"
    if first.startswith("mise run"):
        parts = first.split()
        return " ".join(parts[:3]) if len(parts) > 2 else first
    if first.startswith("python"):
        return "python <script>"
    if first.startswith("pip "):
        return first.split()[0] + " " + first.split()[1] if len(first.split()) > 1 else first
    if first.startswith("npm "):
        return first.split()[0] + " " + first.split()[1] if len(first.split()) > 1 else first
    # Truncate long commands
    return first[:80]

def temporal_analysis(conversations, days):
    """Split metrics by time to detect intra-session learning and cross-session improvement."""
    if not conversations:
        return {}

    # --- Intra-session: first half vs second half of each conversation ---
    intra_shell_first_half = Counter()
    intra_shell_second_half = Counter()
    intra_inline_python = {"first_half": 0, "second_half": 0}
    intra_sleep = {"first_half": 0, "second_half": 0}
    intra_blocking = {"first_half": 0, "second_half": 0}

    for c in conversations:
        cmds = c["shell_commands"]
        if len(cmds) < 4:
            continue
        mid = len(cmds) // 2
        first, second = cmds[:mid], cmds[mid:]

        for cmd in first:
            n = normalize_command(cmd)
            intra_shell_first_half[n] += 1
            if "python" in cmd.lower() and "-c" in cmd:
                intra_inline_python["first_half"] += 1
            if "Start-Sleep" in cmd:
                intra_sleep["first_half"] += 1
            if "Start-Process" in cmd and ("-NoNewWindow" in cmd or "-RedirectStandard" in cmd):
                intra_blocking["first_half"] += 1

        for cmd in second:
            n = normalize_command(cmd)
            intra_shell_second_half[n] += 1
            if "python" in cmd.lower() and "-c" in cmd:
                intra_inline_python["second_half"] += 1
            if "Start-Sleep" in cmd:
                intra_sleep["second_half"] += 1
            if "Start-Process" in cmd and ("-NoNewWindow" in cmd or "-RedirectStandard" in cmd):
                intra_blocking["second_half"] += 1

    # --- Cross-session: split by day ---
    # Sort conversations by file modification time
    sorted_convos = sorted(conversations, key=lambda c: Path(c["file"]).stat().st_mtime)
    mid_idx = len(sorted_convos) // 2
    first_period = sorted_convos[:mid_idx]
    second_period = sorted_convos[mid_idx:]

    def period_metrics(convos):
        shell_total = sum(len(c["shell_commands"]) for c in convos)
        inline_py = sum(1 for c in convos for cmd in c["shell_commands"]
                       if "python" in cmd.lower() and "-c" in cmd)
        sleeps = sum(1 for c in convos for cmd in c["shell_commands"]
                    if "Start-Sleep" in cmd)
        blocking = sum(1 for c in convos for cmd in c["shell_commands"]
                      if "Start-Process" in cmd and
                      ("-NoNewWindow" in cmd or "-RedirectStandard" in cmd))
        tool_reuse = sum(1 for c in convos for cmd in c["shell_commands"]
                        if "tools/" in cmd or "tools\\" in cmd)
        return {
            "conversations": len(convos),
            "shell_commands": shell_total,
            "inline_python": inline_py,
            "start_sleep": sleeps,
            "blocking_start_process": blocking,
            "tool_reuse": tool_reuse,
        }

    return {
        "intra_session": {
            "description": "First half vs second half of each conversation's shell commands",
            "inline_python": intra_inline_python,
            "start_sleep": intra_sleep,
            "blocking_start_process": intra_blocking,
            "learning_signal": {
                "inline_python_reduction": round(
                    1 - (intra_inline_python["second_half"] / max(intra_inline_python["first_half"], 1)), 2),
                "sleep_reduction": round(
                    1 - (intra_sleep["second_half"] / max(intra_sleep["first_half"], 1)), 2),
            }
        },
        "cross_session": {
            "description": f"First {mid_idx} conversations vs last {len(sorted_convos) - mid_idx} conversations",
            "first_period": period_metrics(first_period),
            "second_period": period_metrics(second_period),
            "improvement_signals": {
                "inline_python_per_convo_change": round(
                    (period_metrics(second_period)["inline_python"] / max(len(second_period), 1)) -
                    (period_metrics(first_period)["inline_python"] / max(len(first_period), 1)), 2),
                "sleep_per_convo_change": round(
                    (period_metrics(second_period)["start_sleep"] / max(len(second_period), 1)) -
                    (period_metrics(first_period)["start_sleep"] / max(len(first_period), 1)), 2),
                "tool_reuse_per_convo_change": round(
                    (period_metrics(second_period)["tool_reuse"] / max(len(second_period), 1)) -
                    (period_metrics(first_period)["tool_reuse"] / max(len(first_period), 1)), 2),
            }
        }
    }


def main():
    days, output_path = parse_args()
    print(f"Scanning sessions from last {days} days...", file=sys.stderr)

    files = find_sessions(days)
    print(f"Found {len(files)} conversation files", file=sys.stderr)

    conversations = []
    for i, f in enumerate(files):
        if (i + 1) % 50 == 0:
            print(f"  Parsed {i+1}/{len(files)}...", file=sys.stderr)
        conversations.append(parse_conversation(f))

    summary = aggregate(conversations)
    summary["period_days"] = days
    summary["temporal"] = temporal_analysis(conversations, days)
    summary["status"] = "pass"

    result = json.dumps(summary, indent=2, default=str)

    if output_path:
        Path(output_path).write_text(result, encoding="utf-8")
        print(f"Written to {output_path}", file=sys.stderr)
    else:
        print(result)

if __name__ == "__main__":
    main()
