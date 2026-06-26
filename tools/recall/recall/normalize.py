"""normalize.py — Parse kiro-cli and codex JSONL into conversation messages."""

import json
from pathlib import Path
from typing import Optional


def detect_and_parse(filepath: Path) -> Optional[list[tuple[str, str]]]:
    """Auto-detect format and parse into [(role, text)] messages."""
    content = filepath.read_text(encoding="utf-8", errors="replace")
    if not content.strip():
        return None

    messages = parse_kiro_v3_jsonl(content)
    if messages:
        return messages

    messages = parse_kiro_cli_jsonl(content)
    if messages:
        return messages

    messages = parse_codex_jsonl(content)
    if messages:
        return messages

    return None


def parse_kiro_v3_jsonl(content: str) -> Optional[list[tuple[str, str]]]:
    """Parse kiro-cli v3 JSONL (payload.type format) into messages."""
    lines = [l.strip() for l in content.split("\n") if l.strip()]
    if not lines:
        return None

    # Detect: v3 uses {id, timestamp, payload: {type, ...}}
    try:
        first = json.loads(lines[0])
    except json.JSONDecodeError:
        return None
    if not (isinstance(first, dict) and "payload" in first
            and isinstance(first.get("payload"), dict)
            and "type" in first["payload"]):
        return None

    messages = []
    for line in lines:
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        payload = entry.get("payload", {})
        if not isinstance(payload, dict):
            continue

        ptype = payload.get("type")
        if ptype == "user":
            text = payload.get("content", "").strip()
            if text:
                messages.append(("user", text))
        elif ptype == "assistant":
            text = payload.get("content", "").strip()
            if text:
                if messages and messages[-1][0] == "assistant":
                    messages[-1] = ("assistant", messages[-1][1] + "\n" + text)
                else:
                    messages.append(("assistant", text))

    return messages if len(messages) >= 2 else None


def parse_kiro_cli_jsonl(content: str) -> Optional[list[tuple[str, str]]]:
    """Parse kiro-cli v1/v2 JSONL into messages with tool summaries."""
    lines = [l.strip() for l in content.split("\n") if l.strip()]
    if not lines:
        return None

    has_kiro = False
    for line in lines[:5]:
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if (isinstance(entry, dict) and entry.get("version") == "v1"
                and entry.get("kind") in ("Prompt", "AssistantMessage", "ToolResults")):
            has_kiro = True
            break

    if not has_kiro:
        return None

    messages = []
    for line in lines:
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(entry, dict) or entry.get("version") != "v1":
            continue

        kind = entry.get("kind")
        data = entry.get("data", {})
        if not isinstance(data, dict):
            continue

        if kind == "Prompt":
            parts = []
            for block in data.get("content", []):
                if isinstance(block, dict) and block.get("kind") == "text":
                    t = block.get("data", "").strip()
                    if t:
                        parts.append(t)
            if parts:
                messages.append(("user", "\n".join(parts)))

        elif kind == "AssistantMessage":
            text_parts = []
            for block in data.get("content", []):
                if not isinstance(block, dict):
                    continue
                bk = block.get("kind")
                if bk == "text":
                    t = block.get("data", "").strip()
                    if t:
                        text_parts.append(t)
                elif bk == "toolUse":
                    td = block.get("data", {})
                    name = td.get("name", "unknown")
                    purpose = td.get("input", {}).get("__tool_use_purpose", "")
                    text_parts.append(f"[tool: {name}]" + (f" {purpose}" if purpose else ""))
            combined = "\n".join(text_parts)
            if combined:
                if messages and messages[-1][0] == "assistant":
                    messages[-1] = ("assistant", messages[-1][1] + "\n" + combined)
                else:
                    messages.append(("assistant", combined))

    return messages if len(messages) >= 2 else None


def parse_codex_jsonl(content: str) -> Optional[list[tuple[str, str]]]:
    """Parse OpenAI Codex CLI rollout JSONL."""
    lines = [l.strip() for l in content.split("\n") if l.strip()]
    messages = []
    has_session_meta = False

    for line in lines:
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue
        if not isinstance(entry, dict):
            continue

        if entry.get("type") == "session_meta":
            has_session_meta = True
            continue
        if entry.get("type") != "event_msg":
            continue

        payload = entry.get("payload", {})
        if not isinstance(payload, dict):
            continue
        msg = payload.get("message")
        if not isinstance(msg, str) or not msg.strip():
            continue

        if payload.get("type") == "user_message":
            messages.append(("user", msg.strip()))
        elif payload.get("type") == "agent_message":
            messages.append(("assistant", msg.strip()))

    if len(messages) >= 2 and has_session_meta:
        return messages
    return None


def extract_cwd_from_session(session_dir: Path, session_id: str) -> Optional[str]:
    """Extract project cwd from session JSON metadata (v2 or v3)."""
    # V2: session_dir/<session_id>.json with "cwd" field
    json_file = session_dir / f"{session_id}.json"
    if json_file.exists():
        try:
            data = json.loads(json_file.read_text(encoding="utf-8", errors="replace"))
            return data.get("cwd")
        except (json.JSONDecodeError, KeyError):
            pass

    # V3: session_dir is already the sess_ dir, look for session.json with workspacePaths
    v3_meta = session_dir / "session.json"
    if v3_meta.exists():
        try:
            data = json.loads(v3_meta.read_text(encoding="utf-8", errors="replace"))
            paths = data.get("workspacePaths", [])
            if paths:
                return paths[0]
        except (json.JSONDecodeError, KeyError):
            pass

    # V2 fallback: scan .json files in directory
    for f in session_dir.glob("*.json"):
        try:
            data = json.loads(f.read_text(encoding="utf-8", errors="replace"))
            if data.get("session_id") == session_id:
                return data.get("cwd")
        except (json.JSONDecodeError, KeyError):
            continue
    return None
