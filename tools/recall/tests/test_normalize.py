"""Tests for recall.normalize — session JSONL format parsing."""

import json
from pathlib import Path

import pytest

from recall.normalize import (
    detect_and_parse,
    extract_cwd_from_session,
    parse_codex_jsonl,
    parse_kiro_cli_jsonl,
    parse_kiro_v3_jsonl,
)


# ─── Kiro v1/v2 format ───────────────────────────────────────────

KIRO_V2_VALID = "\n".join([
    json.dumps({"version": "v1", "kind": "Prompt", "data": {
        "content": [{"kind": "text", "data": "How do I sort a list?"}],
        "meta": {"timestamp": 1780000000}
    }}),
    json.dumps({"version": "v1", "kind": "AssistantMessage", "data": {
        "content": [{"kind": "text", "data": "Use sorted() for a new list or .sort() for in-place."}]
    }}),
    json.dumps({"version": "v1", "kind": "Prompt", "data": {
        "content": [{"kind": "text", "data": "Show me an example."}],
        "meta": {"timestamp": 1780000060}
    }}),
    json.dumps({"version": "v1", "kind": "AssistantMessage", "data": {
        "content": [{"kind": "text", "data": "Here's an example: sorted([3,1,2]) returns [1,2,3]."}]
    }}),
])


def test_kiro_v2_parses_messages():
    result = parse_kiro_cli_jsonl(KIRO_V2_VALID)
    assert result is not None
    assert len(result) == 4
    assert result[0] == ("user", "How do I sort a list?")
    assert result[1] == ("assistant", "Use sorted() for a new list or .sort() for in-place.")


def test_kiro_v2_tool_use_summarized():
    content = "\n".join([
        json.dumps({"version": "v1", "kind": "Prompt", "data": {
            "content": [{"kind": "text", "data": "Read the file."}]
        }}),
        json.dumps({"version": "v1", "kind": "AssistantMessage", "data": {
            "content": [
                {"kind": "text", "data": "Let me read it."},
                {"kind": "toolUse", "data": {"name": "read", "input": {"__tool_use_purpose": "Check contents"}}}
            ]
        }}),
        json.dumps({"version": "v1", "kind": "Prompt", "data": {
            "content": [{"kind": "text", "data": "Thanks."}]
        }}),
        json.dumps({"version": "v1", "kind": "AssistantMessage", "data": {
            "content": [{"kind": "text", "data": "You're welcome."}]
        }}),
    ])
    result = parse_kiro_cli_jsonl(content)
    assert result is not None
    assert "[tool: read] Check contents" in result[1][1]


def test_kiro_v2_rejects_non_kiro():
    content = json.dumps({"role": "user", "content": "hello"})
    assert parse_kiro_cli_jsonl(content) is None


def test_kiro_v2_requires_minimum_messages():
    # Only 1 message pair = too short
    content = json.dumps({"version": "v1", "kind": "Prompt", "data": {
        "content": [{"kind": "text", "data": "Hello"}]
    }})
    assert parse_kiro_cli_jsonl(content) is None


def test_kiro_v2_handles_malformed_json():
    content = "not json at all\n{broken\n" + KIRO_V2_VALID
    result = parse_kiro_cli_jsonl(content)
    # Should still parse the valid lines
    assert result is not None


# ─── Kiro v3 format ───────────────────────────────────────────────

KIRO_V3_VALID = "\n".join([
    json.dumps({"id": "1", "timestamp": 1780000000, "payload": {"type": "user", "content": "What is Rust?"}}),
    json.dumps({"id": "2", "timestamp": 1780000010, "payload": {"type": "assistant", "content": "Rust is a systems programming language."}}),
    json.dumps({"id": "3", "timestamp": 1780000020, "payload": {"type": "user", "content": "How fast is it?"}}),
    json.dumps({"id": "4", "timestamp": 1780000030, "payload": {"type": "assistant", "content": "Very fast — zero-cost abstractions."}}),
])


def test_kiro_v3_parses_messages():
    result = parse_kiro_v3_jsonl(KIRO_V3_VALID)
    assert result is not None
    assert len(result) == 4
    assert result[0] == ("user", "What is Rust?")
    assert result[1] == ("assistant", "Rust is a systems programming language.")


def test_kiro_v3_consecutive_assistant_merged():
    content = "\n".join([
        json.dumps({"id": "1", "timestamp": 1, "payload": {"type": "user", "content": "Hi"}}),
        json.dumps({"id": "2", "timestamp": 2, "payload": {"type": "assistant", "content": "Hello!"}}),
        json.dumps({"id": "3", "timestamp": 3, "payload": {"type": "assistant", "content": "How can I help?"}}),
        json.dumps({"id": "4", "timestamp": 4, "payload": {"type": "user", "content": "Thanks"}}),
        json.dumps({"id": "5", "timestamp": 5, "payload": {"type": "assistant", "content": "Welcome!"}}),
    ])
    result = parse_kiro_v3_jsonl(content)
    assert result is not None
    # Two consecutive assistant messages should merge
    assert result[1] == ("assistant", "Hello!\nHow can I help?")
    assert len(result) == 4


def test_kiro_v3_rejects_non_v3():
    content = json.dumps({"version": "v1", "kind": "Prompt", "data": {}})
    assert parse_kiro_v3_jsonl(content) is None


def test_kiro_v3_empty_content_skipped():
    content = "\n".join([
        json.dumps({"id": "1", "timestamp": 1, "payload": {"type": "user", "content": "Hi"}}),
        json.dumps({"id": "2", "timestamp": 2, "payload": {"type": "assistant", "content": ""}}),
        json.dumps({"id": "3", "timestamp": 3, "payload": {"type": "assistant", "content": "Hello!"}}),
        json.dumps({"id": "4", "timestamp": 4, "payload": {"type": "user", "content": "More"}}),
        json.dumps({"id": "5", "timestamp": 5, "payload": {"type": "assistant", "content": "Sure."}}),
    ])
    result = parse_kiro_v3_jsonl(content)
    assert result is not None
    # Empty assistant content should be skipped
    assert ("assistant", "") not in result


# ─── Codex format ─────────────────────────────────────────────────

CODEX_VALID = "\n".join([
    json.dumps({"type": "session_meta", "session_id": "abc123"}),
    json.dumps({"type": "event_msg", "payload": {"type": "user_message", "message": "Fix the bug"}}),
    json.dumps({"type": "event_msg", "payload": {"type": "agent_message", "message": "I'll look at the error."}}),
    json.dumps({"type": "event_msg", "payload": {"type": "user_message", "message": "Thanks"}}),
    json.dumps({"type": "event_msg", "payload": {"type": "agent_message", "message": "Done."}}),
])


def test_codex_parses_messages():
    result = parse_codex_jsonl(CODEX_VALID)
    assert result is not None
    assert len(result) == 4
    assert result[0] == ("user", "Fix the bug")
    assert result[1] == ("assistant", "I'll look at the error.")


def test_codex_requires_session_meta():
    # Without session_meta, should reject
    content = "\n".join([
        json.dumps({"type": "event_msg", "payload": {"type": "user_message", "message": "Hi"}}),
        json.dumps({"type": "event_msg", "payload": {"type": "agent_message", "message": "Hello"}}),
    ])
    assert parse_codex_jsonl(content) is None


def test_codex_requires_minimum_messages():
    content = "\n".join([
        json.dumps({"type": "session_meta", "session_id": "abc"}),
        json.dumps({"type": "event_msg", "payload": {"type": "user_message", "message": "Hi"}}),
    ])
    assert parse_codex_jsonl(content) is None


def test_codex_skips_non_event_msg():
    content = "\n".join([
        json.dumps({"type": "session_meta", "session_id": "x"}),
        json.dumps({"type": "heartbeat"}),
        json.dumps({"type": "event_msg", "payload": {"type": "user_message", "message": "Hello"}}),
        json.dumps({"type": "event_msg", "payload": {"type": "agent_message", "message": "Hi"}}),
    ])
    result = parse_codex_jsonl(content)
    assert result is not None
    assert len(result) == 2


# ─── detect_and_parse (format auto-detection) ────────────────────

def test_detect_and_parse_kiro_v2(tmp_path):
    f = tmp_path / "session.jsonl"
    f.write_text(KIRO_V2_VALID, encoding="utf-8")
    result = detect_and_parse(f)
    assert result is not None
    assert result[0][0] == "user"


def test_detect_and_parse_kiro_v3(tmp_path):
    f = tmp_path / "messages.jsonl"
    f.write_text(KIRO_V3_VALID, encoding="utf-8")
    result = detect_and_parse(f)
    assert result is not None
    assert result[0][0] == "user"


def test_detect_and_parse_codex(tmp_path):
    f = tmp_path / "session.jsonl"
    f.write_text(CODEX_VALID, encoding="utf-8")
    result = detect_and_parse(f)
    assert result is not None


def test_detect_and_parse_empty(tmp_path):
    f = tmp_path / "empty.jsonl"
    f.write_text("", encoding="utf-8")
    assert detect_and_parse(f) is None


def test_detect_and_parse_garbage(tmp_path):
    f = tmp_path / "garbage.jsonl"
    f.write_text("this is not json\nneither is this\n", encoding="utf-8")
    assert detect_and_parse(f) is None


# ─── extract_cwd_from_session ─────────────────────────────────────

def test_extract_cwd_v2(tmp_path):
    session_id = "test-session-001"
    meta = tmp_path / f"{session_id}.json"
    meta.write_text(json.dumps({"cwd": "/home/user/project", "session_id": session_id}))
    result = extract_cwd_from_session(tmp_path, session_id)
    assert result == "/home/user/project"


def test_extract_cwd_v3(tmp_path):
    session_dir = tmp_path / "sess_abc123"
    session_dir.mkdir()
    meta = session_dir / "session.json"
    meta.write_text(json.dumps({"workspacePaths": ["/home/user/myproject"]}))
    result = extract_cwd_from_session(session_dir, "sess_abc123")
    assert result == "/home/user/myproject"


def test_extract_cwd_missing(tmp_path):
    result = extract_cwd_from_session(tmp_path, "nonexistent")
    assert result is None
