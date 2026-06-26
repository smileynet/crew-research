"""Extract condensed conversation summaries for batch review by subagents.

Produces per-conversation summaries with:
- User prompts (full text)
- Tool call sequence
- Shell commands (full)
- Errors
- Working directories (project context)

Groups into batches of ~10 conversations for parallel processing.
"""
import json
import sys
from pathlib import Path
from datetime import datetime, timedelta

def find_recent_files(days):
    sessions_dir = Path.home() / ".kiro" / "sessions"
    cli_dir = sessions_dir / "cli"
    cutoff = datetime.now() - timedelta(days=days)
    files = []
    # V2
    if cli_dir.exists():
        for f in cli_dir.glob("*.jsonl"):
            mtime = datetime.fromtimestamp(f.stat().st_mtime)
            if mtime > cutoff:
                files.append((f, mtime))
    # V3
    for f in sessions_dir.glob("*/sess_*/messages.jsonl"):
        mtime = datetime.fromtimestamp(f.stat().st_mtime)
        if mtime > cutoff:
            files.append((f, mtime))
    return sorted(files, key=lambda x: x[1])

def extract_summary(filepath):
    """Extract a condensed but complete summary of a conversation."""
    is_v3 = filepath.name == "messages.jsonl"
    summary = {
        "file": filepath.name if not is_v3 else filepath.parent.name,
        "session": filepath.parent.name,
        "user_prompts": [],
        "assistant_actions": [],
        "shell_commands": [],
        "errors": [],
        "working_dirs": set(),
        "tool_sequence": [],
        "message_count": 0,
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

            summary["message_count"] += 1

            if is_v3:
                payload = msg.get("payload", {})
                ptype = payload.get("type")
                if ptype == "user":
                    text = payload.get("content", "")
                    if text:
                        summary["user_prompts"].append(text[:500])
                elif ptype == "assistant":
                    text = payload.get("content", "")
                    if text:
                        summary["assistant_actions"].append(("text", text[:300]))
                elif ptype == "tool_use":
                    tool_name = payload.get("toolName", "?")
                    tool_input = payload.get("input", {})
                    summary["tool_sequence"].append(tool_name)
                    if tool_name == "shell":
                        cmd = tool_input.get("command", "")
                        wd = tool_input.get("working_dir", "")
                        summary["shell_commands"].append(cmd[:300])
                        if wd:
                            summary["working_dirs"].add(wd)
                    elif tool_name == "write":
                        path = tool_input.get("path", "")
                        op = tool_input.get("command", "")
                        summary["assistant_actions"].append(("write", f"{op}: {path}"))
                    elif tool_name == "web_search":
                        q = tool_input.get("query", "")
                        summary["assistant_actions"].append(("search", q))
                elif ptype == "tool_result":
                    if payload.get("status") == "error":
                        summary["errors"].append(str(payload.get("content", ""))[:200])
            else:
                kind = msg.get("kind")
                data = msg.get("data", {})

                if kind == "Prompt":
                    for content in data.get("content", []):
                        if content.get("kind") == "text" and content.get("data"):
                            summary["user_prompts"].append(content["data"][:500])

                elif kind == "AssistantMessage":
                    for content in data.get("content", []):
                        if content.get("kind") == "text" and content.get("data"):
                            text = content["data"][:300]
                            if text.strip():
                                summary["assistant_actions"].append(("text", text))
                        elif content.get("kind") == "toolUse":
                            td = content.get("data", {})
                            tool_name = td.get("name", "?")
                            tool_input = td.get("input", {})
                            summary["tool_sequence"].append(tool_name)
                            if tool_name == "shell":
                                cmd = tool_input.get("command", "")
                                wd = tool_input.get("working_dir", "")
                                summary["shell_commands"].append(cmd[:300])
                                if wd:
                                    summary["working_dirs"].add(wd)
                            elif tool_name == "write":
                                path = tool_input.get("path", "")
                                op = tool_input.get("command", "")
                                summary["assistant_actions"].append(("write", f"{op}: {path}"))
                            elif tool_name == "web_search":
                                q = tool_input.get("query", "")
                                summary["assistant_actions"].append(("search", q))

                elif kind == "ToolResults":
                    for content in data.get("content", []):
                        if content.get("kind") == "toolResult":
                            tr = content.get("data", {})
                            if tr.get("status") == "error":
                                err_content = tr.get("content", "")
                                summary["errors"].append(str(err_content)[:200])

    summary["working_dirs"] = list(summary["working_dirs"])
    # Infer project
    project = "unknown"
    for d in summary["working_dirs"]:
        parts = Path(d).parts
        for i, p in enumerate(parts):
            if p == "code" and i + 1 < len(parts):
                project = parts[i + 1]
                break
        if project != "unknown":
            break
    summary["project"] = project

    # Trim for size - keep only what's needed for review
    summary["tool_sequence"] = summary["tool_sequence"][:100]
    summary["shell_commands"] = summary["shell_commands"][:30]
    summary["assistant_actions"] = summary["assistant_actions"][:20]

    return summary

def main():
    days = int(sys.argv[1]) if len(sys.argv) > 1 else 2
    batch_size = int(sys.argv[2]) if len(sys.argv) > 2 else 10
    output_dir = Path(sys.argv[3]) if len(sys.argv) > 3 else Path(".scratch/review-batches")

    output_dir.mkdir(parents=True, exist_ok=True)

    files = find_recent_files(days)
    print(f"Found {len(files)} conversations from last {days} days", file=sys.stderr)

    summaries = []
    for i, (f, mtime) in enumerate(files):
        if (i + 1) % 25 == 0:
            print(f"  Extracted {i+1}/{len(files)}...", file=sys.stderr)
        s = extract_summary(f)
        s["modified"] = mtime.isoformat()
        summaries.append(s)

    # Group into batches
    batches = []
    for i in range(0, len(summaries), batch_size):
        batch = summaries[i:i + batch_size]
        batches.append(batch)

    # Write batches
    for i, batch in enumerate(batches):
        out_path = output_dir / f"batch_{i:02d}.json"
        out_path.write_text(json.dumps(batch, indent=1, default=str), encoding="utf-8")

    print(f"Wrote {len(batches)} batches of ~{batch_size} to {output_dir}/", file=sys.stderr)

    # Write manifest
    manifest = {
        "total_conversations": len(summaries),
        "batches": len(batches),
        "batch_size": batch_size,
        "days": days,
        "projects": list(set(s["project"] for s in summaries)),
    }
    (output_dir / "manifest.json").write_text(json.dumps(manifest, indent=2), encoding="utf-8")

if __name__ == "__main__":
    main()
