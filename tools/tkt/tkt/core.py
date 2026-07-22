"""tkt core — frontmatter engine and ticket model.

Design authority: design/patterns/preserve-or-fail.md, intersection-contract.md.
Frontmatter is an ordered list of key -> raw-text lines. No YAML library:
ids stay text (archwright's unquoted `id: 010` would octal-coerce), unknown
fields survive rewrites verbatim, and writes are line-surgical.
"""

from __future__ import annotations

import re
from dataclasses import dataclass, field
from pathlib import Path

STATUS_VALUES = ("open", "in_progress", "done")
ENV_VALUES = ("corp", "personal", "either")
REQUIRED_FIELDS = ("id", "title", "status", "blocked_by")
KNOWN_FIELDS = REQUIRED_FIELDS + ("env", "spec", "priority")

# --- R18 input validation (spec 2026-07-22; research: cli-input-validation.md) ---
# Allowlist validated BEFORE any filesystem operation. No dots/slashes by
# construction, so traversal and extension tricks are excluded at the charset.
SLUG_RE = re.compile(r"^[a-z0-9][a-z0-9-]*$")
ID_REF_RE = re.compile(r"^[A-Za-z0-9_-]+$")
# Windows reserved device names, rejected on ALL platforms (cargo's approach).
WINDOWS_RESERVED = frozenset(
    {"con", "prn", "aux", "nul"}
    | {f"com{i}" for i in range(1, 10)}
    | {f"lpt{i}" for i in range(1, 10)}
)


def validate_slug(slug: str) -> str | None:
    """Return an error message, or None if the slug is safe."""
    if not SLUG_RE.match(slug):
        return (
            f"invalid slug {slug!r} — allowed: lowercase letters, digits, dashes,"
            " starting with a letter or digit"
        )
    if slug.lower() in WINDOWS_RESERVED:
        return f"invalid slug {slug!r} — reserved device name on Windows"
    return None


def validate_free_text(value: str, what: str = "title") -> str | None:
    """Return an error message, or None if the value round-trips safely.

    The raw-text frontmatter engine (preserve-or-fail) never interprets escape
    sequences, so escaping-on-write would misread on every consumer. The tool
    instead REFUSES to emit what it cannot round-trip: double quotes,
    backslashes, and newlines in free-text values are rejected at input.
    """
    for ch, name in (('"', "double quote"), ("\\", "backslash"), ("\n", "newline")):
        if ch in value:
            return f"{what} contains a {name} — not representable in tkt frontmatter"
    return None

FENCE = re.compile(r"^---\s*$")
KEY_LINE = re.compile(r"^([A-Za-z_][A-Za-z0-9_-]*):(.*)$")


class TicketParseError(Exception):
    """A ticket file the tool cannot parse. Loud in every command — never a skip."""

    def __init__(self, path: Path | str, reason: str):
        self.path = str(path)
        self.reason = reason
        super().__init__(f"{self.path}: {reason}")


@dataclass
class Ticket:
    path: Path
    # Ordered frontmatter as (key, raw_value_text) pairs; list-valued fields
    # keep their raw inline text. Unknown keys ride here untouched. Blank
    # lines inside frontmatter are stored as ("", original_line).
    fm: list[tuple[str, str]]
    body: str  # everything after the closing fence, byte-preserved
    had_body: bool = True

    def get(self, key: str) -> str | None:
        if not key:
            return None
        for k, v in self.fm:
            if k == key:
                return v.strip()
        return None

    @property
    def id(self) -> str:
        raw = self.get("id") or ""
        return raw.strip().strip('"').strip("'")

    @property
    def status(self) -> str:
        return (self.get("status") or "").strip()

    @property
    def blocked_by(self) -> list[str]:
        raw = self.get("blocked_by") or ""
        m = re.match(r"\[(.*)\]", raw)
        if not m:
            return []
        items = [x.strip().strip('"').strip("'") for x in m.group(1).split(",")]
        return [x for x in items if x]

    @property
    def env(self) -> str:
        return (self.get("env") or "either").strip() or "either"

    @property
    def priority(self) -> str | None:
        return self.get("priority")

    @property
    def title(self) -> str:
        return (self.get("title") or "").strip().strip('"')

    def numeric_key(self) -> tuple[int, str]:
        m = re.match(r"(\d+)(.*)", self.id)
        return (int(m.group(1)), m.group(2)) if m else (1 << 30, self.id)

    def extension_fields(self) -> dict[str, str]:
        return {k: v.strip() for k, v in self.fm if k not in KNOWN_FIELDS}


def parse_ticket(path: Path) -> Ticket:
    """Parse one ticket file. Raises TicketParseError on anything malformed."""
    try:
        text = path.read_text(encoding="utf-8")
    except OSError as e:
        raise TicketParseError(path, f"unreadable: {e}")

    lines = text.split("\n")
    if not lines or not FENCE.match(lines[0]):
        raise TicketParseError(path, "no opening frontmatter fence on line 1")

    fm: list[tuple[str, str]] = []
    close_idx = None
    i = 1
    while i < len(lines):
        line = lines[i]
        if FENCE.match(line):
            close_idx = i
            break
        m = KEY_LINE.match(line)
        if m:
            fm.append((m.group(1), m.group(2)))
        elif line.startswith((" ", "\t")) and fm:
            # continuation line (multi-line value): append to previous raw value
            k, v = fm[-1]
            fm[-1] = (k, v + "\n" + line)
        elif line.strip() == "":
            fm.append(("", line))  # preserved verbatim on write
        else:
            raise TicketParseError(path, f"unparseable frontmatter line {i + 1}: {line!r}")
        i += 1

    if close_idx is None:
        raise TicketParseError(path, "no closing frontmatter fence")

    keys = [k for k, _ in fm if k]
    dupes = {k for k in keys if keys.count(k) > 1}
    if dupes:
        raise TicketParseError(path, f"duplicate frontmatter key(s): {', '.join(sorted(dupes))}")

    t = Ticket(
        path=path,
        fm=fm,
        body="\n".join(lines[close_idx + 1:]),
        had_body=len(lines) > close_idx + 1,
    )

    for req in REQUIRED_FIELDS:
        if t.get(req) is None:
            raise TicketParseError(path, f"missing required field: {req}")
    return t


def write_ticket(t: Ticket) -> None:
    """Serialize surgically: original raw lines, no re-quoting, no reordering."""
    parts = ["---"]
    for k, v in t.fm:
        parts.append(v if k == "" else f"{k}:{v}")
    parts.append("---")
    header = "\n".join(parts)
    out = header + "\n" + t.body if t.had_body else header + "\n"
    t.path.write_text(out, encoding="utf-8")


def set_field(t: Ticket, key: str, raw_value: str) -> None:
    """Replace one field's raw text in place (or append before end if absent)."""
    for idx, (k, _) in enumerate(t.fm):
        if k == key:
            t.fm[idx] = (k, f" {raw_value}")
            return
    t.fm.append((key, f" {raw_value}"))
