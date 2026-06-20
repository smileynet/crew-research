"""chunker.py — Exchange-pair chunking + room classification."""

import json
from pathlib import Path
from typing import Optional

CHUNK_SIZE = 800
MIN_CHUNK_SIZE = 30

DEFAULT_TOPIC_KEYWORDS = {
    "technical": ["code", "function", "bug", "error", "api", "server", "deploy", "git", "test", "debug", "refactor"],
    "architecture": ["architecture", "design", "pattern", "structure", "interface", "module", "component", "layer"],
    "planning": ["plan", "roadmap", "milestone", "scope", "requirement", "spec", "backlog", "sprint"],
    "decisions": ["decided", "chose", "recommendation", "trade-off", "approach", "option", "prefer", "agree"],
    "problems": ["problem", "issue", "broken", "failed", "crash", "stuck", "workaround", "fix", "solved"],
}


def load_topic_keywords() -> dict:
    config_path = Path.home() / ".recall" / "config.json"
    if config_path.exists():
        try:
            config = json.loads(config_path.read_text())
            custom = config.get("topic_keywords")
            if custom and isinstance(custom, dict):
                return custom
        except (json.JSONDecodeError, KeyError):
            pass
    return DEFAULT_TOPIC_KEYWORDS


def classify_room(text: str, keywords: Optional[dict] = None) -> str:
    if keywords is None:
        keywords = load_topic_keywords()
    text_lower = text[:3000].lower()
    scores = {}
    for room, kws in keywords.items():
        score = sum(1 for kw in kws if kw in text_lower)
        if score > 0:
            scores[room] = score
    return max(scores, key=scores.get) if scores else "general"


def chunk_messages(messages: list[tuple[str, str]]) -> list[str]:
    """Chunk conversation messages into ~CHUNK_SIZE char drawers."""
    chunks = []
    current = []
    current_len = 0

    for role, text in messages:
        line = f"> {text}" if role == "user" else text
        if current_len + len(line) > CHUNK_SIZE and current:
            chunks.append("\n".join(current))
            current = []
            current_len = 0
        current.append(line)
        current_len += len(line)

    if current:
        chunks.append("\n".join(current))

    return [c for c in chunks if len(c) >= MIN_CHUNK_SIZE]
