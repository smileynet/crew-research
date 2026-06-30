#!/usr/bin/env python3
"""Extract agy (Antigravity CLI) session data via local language_server RPC.

Usage:
    python extract_agy_session.py [--cascade-id ID] [--log-file PATH] [--format summary|json]

Discovers the local language_server (IDE persistent or CLI ephemeral),
calls RPC to retrieve session trajectory, and outputs structured data
for eval harness scoring or proof assertions.

Requires: Python 3.8+ stdlib only (no external deps).
"""

import argparse
import json
import os
import platform
import re
import ssl
import subprocess
import sys
import urllib.request


def parse_args():
    p = argparse.ArgumentParser(description="Extract agy session via RPC")
    p.add_argument("--cascade-id", help="Specific cascade/session ID")
    p.add_argument("--log-file", help="Parse cascade_id from agy log file")
    p.add_argument("--format", choices=["summary", "json"], default="summary")
    return p.parse_args()


def cascade_id_from_log(log_path):
    """Extract cascade_id from agy --log-file output."""
    try:
        with open(log_path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
        match = re.search(r"Created conversation ([0-9a-f-]{36})", content)
        return match.group(1) if match else None
    except (OSError, IOError):
        return None


def discover_servers_windows():
    """Discover language_server processes on Windows via PowerShell."""
    servers = []
    try:
        # Use PowerShell to get process details reliably
        ps_cmd = (
            'Get-CimInstance Win32_Process -Filter "Name like \'%language_server%\'" '
            '| Select-Object ProcessId, CommandLine '
            '| ConvertTo-Json -Compress'
        )
        result = subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_cmd],
            capture_output=True, text=True, timeout=15
        )
        if result.returncode != 0 or not result.stdout.strip():
            return servers

        data = json.loads(result.stdout)
        # Normalize to list (single result comes as dict)
        if isinstance(data, dict):
            data = [data]

        for proc in data:
            cmdline = proc.get("CommandLine", "")
            pid = proc.get("ProcessId")
            if not cmdline or not pid:
                continue
            token_match = re.search(r"--csrf_token\s+(\S+)", cmdline)
            if not token_match:
                continue
            token = token_match.group(1)
            is_ide = "language_server_windows_x64" in cmdline or "--standalone" in cmdline
            ports = _get_port_windows(int(pid))
            for port in ports:
                servers.append({
                    "pid": int(pid),
                    "port": port,
                    "token": token,
                    "is_ide": is_ide,
                })
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError, json.JSONDecodeError):
        pass
    # Sort: IDE first (more reliable)
    servers.sort(key=lambda s: (not s["is_ide"], s["pid"]))
    return servers


def _get_port_windows(pid):
    """Get listening ports for a PID on Windows via PowerShell."""
    try:
        ps_cmd = (
            f'Get-NetTCPConnection -OwningProcess {pid} -State Listen -ErrorAction SilentlyContinue '
            '| Select-Object -ExpandProperty LocalPort'
        )
        result = subprocess.run(
            ["powershell", "-NoProfile", "-Command", ps_cmd],
            capture_output=True, text=True, timeout=10
        )
        ports = []
        for line in result.stdout.strip().splitlines():
            line = line.strip()
            if line.isdigit():
                ports.append(int(line))
        return ports
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    return []


def discover_servers_unix():
    """Discover language_server processes on macOS/Linux."""
    servers = []
    try:
        result = subprocess.run(
            ["ps", "-axo", "pid=,command="],
            capture_output=True, text=True, timeout=10
        )
        for line in result.stdout.splitlines():
            if "language_server" not in line or "--csrf_token" not in line:
                continue
            parts = line.strip().split(None, 1)
            if len(parts) < 2:
                continue
            pid = int(parts[0])
            cmdline = parts[1]
            token_match = re.search(r"--csrf_token\s+(\S+)", cmdline)
            if not token_match:
                continue
            token = token_match.group(1)
            is_ide = "Antigravity.app" in cmdline or "language_server_" in cmdline
            port = _get_port_unix(pid)
            if port:
                servers.append({
                    "pid": pid,
                    "port": port,
                    "token": token,
                    "is_ide": is_ide,
                })
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    servers.sort(key=lambda s: (not s["is_ide"], s["pid"]))
    return servers


def _get_port_unix(pid):
    """Get listening port for a PID on macOS/Linux."""
    try:
        result = subprocess.run(
            ["lsof", "-Pan", f"-p{pid}", "-iTCP", "-sTCP:LISTEN"],
            capture_output=True, text=True, timeout=10
        )
        for line in result.stdout.splitlines():
            match = re.search(r":(\d+)\s", line)
            if match:
                port = int(match.group(1))
                if port > 1024:
                    return port
    except (subprocess.TimeoutExpired, FileNotFoundError, OSError):
        pass
    return None


def discover_servers():
    """Platform-aware server discovery."""
    if platform.system() == "Windows":
        return discover_servers_windows()
    return discover_servers_unix()


def rpc_call(server, method, payload=None):
    """Call language_server RPC endpoint."""
    url = f"https://127.0.0.1:{server['port']}/exa.language_server_pb.LanguageServerService/{method}"
    data = json.dumps(payload or {}).encode("utf-8")

    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    req = urllib.request.Request(
        url,
        data=data,
        headers={
            "Content-Type": "application/json",
            "x-codeium-csrf-token": server["token"],
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=15, context=ctx) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception:
        return None


def get_most_recent_cascade(server):
    """Get the most recent cascade ID from the server or local files."""
    # Try RPC first
    result = rpc_call(server, "GetAllCascadeTrajectories")
    if result:
        trajectories = result.get("trajectories", [])
        if trajectories:
            return trajectories[-1].get("cascadeId")

    # Fallback: discover from local conversation .db files (sorted by mtime)
    conv_dirs = [
        os.path.expanduser("~/.gemini/antigravity/conversations"),
        os.path.expanduser("~/.gemini/antigravity-cli/conversations"),
    ]
    db_files = []
    for conv_dir in conv_dirs:
        if os.path.isdir(conv_dir):
            for f in os.listdir(conv_dir):
                if f.endswith(".db"):
                    full = os.path.join(conv_dir, f)
                    db_files.append((os.path.getmtime(full), f[:-3]))  # strip .db
    if db_files:
        db_files.sort(reverse=True)  # most recent first
        return db_files[0][1]  # cascade_id is the filename without extension

    return None


def get_trajectory_steps(server, cascade_id):
    """Get all steps for a cascade."""
    payload = {"cascadeId": cascade_id, "startIndex": 0, "endIndex": 200}
    return rpc_call(server, "GetCascadeTrajectorySteps", payload)


STEP_TYPE_MAP = {
    "CORTEX_STEP_TYPE_USER_INPUT": "user_input",
    "CORTEX_STEP_TYPE_PLANNER_RESPONSE": "model_response",
    "CORTEX_STEP_TYPE_EPHEMERAL_MESSAGE": "system_prompt",
    "CORTEX_STEP_TYPE_VIEW_FILE": "file_read",
    "CORTEX_STEP_TYPE_EDIT_FILE": "file_write",
    "CORTEX_STEP_TYPE_SHELL_COMMAND": "shell",
    "CORTEX_STEP_TYPE_CHECKPOINT": "checkpoint",
}


def parse_steps(raw_result):
    """Parse RPC response into structured steps."""
    if not raw_result:
        return []
    steps = []
    for raw_step in raw_result.get("steps", []):
        step_type = raw_step.get("type", "")
        mapped = STEP_TYPE_MAP.get(step_type, step_type)
        step = {"type": mapped}

        if "userInput" in raw_step:
            step["text"] = raw_step["userInput"].get("userResponse", "")
        elif "plannerResponse" in raw_step:
            pr = raw_step["plannerResponse"]
            step["response"] = pr.get("response", "")
            step["thinking"] = pr.get("thinking", "")
            duration = pr.get("thinkingDuration", "")
            if duration:
                try:
                    step["duration_s"] = float(duration.rstrip("s"))
                except (ValueError, AttributeError):
                    pass
        elif "ephemeralMessage" in raw_step:
            step["text"] = raw_step["ephemeralMessage"].get("content", "")
        elif mapped == "file_read":
            step["path"] = raw_step.get("path", raw_step.get("filePath", ""))
        elif mapped == "file_write":
            step["path"] = raw_step.get("path", raw_step.get("filePath", ""))
        elif mapped == "shell":
            step["command"] = raw_step.get("command", raw_step.get("shellCommand", ""))
        elif mapped == "checkpoint":
            step["intent"] = raw_step.get("checkpoint", {}).get("userIntent", "")

        steps.append(step)
    return steps


def build_summary(steps):
    """Build summary dict from parsed steps."""
    tool_calls = 0
    errors = 0
    files_read = []
    files_written = []
    skills_activated = []
    response_text = ""
    thinking_duration_ms = 0

    tool_types = {"file_read", "file_write", "shell"}
    tool_breakdown = {}

    for step in steps:
        t = step["type"]
        if t in tool_types:
            tool_calls += 1
            tool_breakdown[t] = tool_breakdown.get(t, 0) + 1
        if t == "file_read" and step.get("path"):
            files_read.append(step["path"])
        if t == "file_write" and step.get("path"):
            files_written.append(step["path"])
        if t == "model_response":
            response_text = step.get("response", "")
            if step.get("duration_s"):
                thinking_duration_ms = int(step["duration_s"] * 1000)
        if t == "system_prompt":
            content = step.get("text", "")
            # Detect skill activation from ephemeral messages
            skill_match = re.search(r"name:\s*(\S+)", content)
            if skill_match:
                skills_activated.append(skill_match.group(1))

    return {
        "tool_calls": tool_calls,
        "errors": errors,
        "files_read": files_read,
        "files_written": files_written,
        "skills_activated": skills_activated,
        "response_text": response_text,
        "thinking_duration_ms": thinking_duration_ms,
        "tool_breakdown": tool_breakdown,
    }


def format_summary_text(summary):
    """Format summary as human-readable text for eval judge."""
    lines = ["--- Session Behavioral Summary ---"]
    lines.append(f"Total tool invocations: {summary['tool_calls']}")
    lines.append(f"Errors encountered: {summary['errors']}")
    lines.append("")

    if summary["tool_breakdown"]:
        lines.append("Tool usage breakdown:")
        for tool, count in sorted(summary["tool_breakdown"].items()):
            lines.append(f"  {count} {tool}")
        lines.append("")

    if summary["files_read"]:
        lines.append("Files accessed:")
        for f in summary["files_read"][:20]:
            lines.append(f"  {f}")
        lines.append("")

    if summary["files_written"]:
        lines.append("Files written:")
        for f in summary["files_written"][:20]:
            lines.append(f"  {f}")
        lines.append("")

    if summary["skills_activated"]:
        lines.append(f"Skills activated: {', '.join(summary['skills_activated'])}")
        lines.append("")

    resp = summary["response_text"]
    if resp:
        lines.append(f"Model response (first 500 chars):")
        lines.append(f"  {resp[:500]}")
        lines.append("")

    if summary["thinking_duration_ms"]:
        lines.append(f"Thinking duration: {summary['thinking_duration_ms'] / 1000:.2f}s")

    lines.append("--- End Summary ---")
    return "\n".join(lines)


def main():
    args = parse_args()

    # Determine cascade_id
    cascade_id = args.cascade_id
    if not cascade_id and args.log_file:
        cascade_id = cascade_id_from_log(args.log_file)

    # Discover servers
    servers = discover_servers()
    if not servers:
        error = {"error": "no language_server found", "fallback": "log-file-only"}
        print(json.dumps(error))
        sys.exit(0)

    # Try each server
    result = None
    for server in servers:
        if not cascade_id:
            cascade_id = get_most_recent_cascade(server)
        if cascade_id:
            result = get_trajectory_steps(server, cascade_id)
            if result:
                break

    if not result:
        error = {"error": "no trajectory found", "cascade_id": cascade_id}
        print(json.dumps(error))
        sys.exit(0)

    steps = parse_steps(result)
    summary = build_summary(steps)

    if args.format == "json":
        output = {
            "cascade_id": cascade_id,
            "steps": steps,
            "summary": summary,
        }
        print(json.dumps(output, indent=2))
    else:
        print(format_summary_text(summary))


if __name__ == "__main__":
    main()
