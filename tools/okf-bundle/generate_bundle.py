#!/usr/bin/env python3
"""Generate an OKF bundle from a reference repo exploration.

Usage:
    python generate_bundle.py <reference-dir> [--output <output-dir>]

This script scans a reference repo and produces an OKF-formatted bundle
with structured concept docs. It handles the mechanical parts (directory
creation, frontmatter formatting, index generation) — the actual content
analysis is expected to come from an LLM subagent that calls write_concept().

For the prototype, it also includes a --scan mode that produces a manifest
of what an LLM should analyze, suitable for feeding to a subagent prompt.
"""

import argparse
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

FRONTMATTER_SEP = "---"


def make_frontmatter(fields: dict) -> str:
    """Serialize a dict to YAML frontmatter block."""
    lines = [FRONTMATTER_SEP]
    # Preferred key order
    order = ("type", "title", "description", "resource", "tags", "timestamp")
    for key in order:
        if key in fields:
            lines.append(_yaml_line(key, fields[key]))
    for key, val in fields.items():
        if key not in order:
            lines.append(_yaml_line(key, val))
    lines.append(FRONTMATTER_SEP)
    return "\n".join(lines)


def _yaml_line(key: str, val) -> str:
    if isinstance(val, list):
        return f"{key}: [{', '.join(str(v) for v in val)}]"
    if isinstance(val, str) and ("\n" in val or len(val) > 80):
        return f'{key}: >\n  {val}'
    return f"{key}: {val}"


def write_concept(bundle_root: Path, concept_path: str, frontmatter: dict, body: str):
    """Write a single OKF concept document."""
    if "timestamp" not in frontmatter:
        frontmatter["timestamp"] = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    dest = bundle_root / concept_path
    dest.parent.mkdir(parents=True, exist_ok=True)
    content = make_frontmatter(frontmatter) + "\n\n" + body.strip() + "\n"
    dest.write_text(content, encoding="utf-8")
    return str(dest.relative_to(bundle_root))


def write_index(bundle_root: Path, dir_path: str, entries: list[dict]):
    """Write an index.md listing entries in a directory.

    entries: list of {"title": ..., "path": ..., "description": ...}
    """
    dest = bundle_root / dir_path / "index.md"
    dest.parent.mkdir(parents=True, exist_ok=True)

    lines = []
    for entry in entries:
        lines.append(f"* [{entry['title']}]({entry['path']}) - {entry['description']}")

    dest.write_text("\n".join(lines) + "\n", encoding="utf-8")


def scan_reference(ref_dir: Path) -> dict:
    """Scan a reference repo and produce a manifest for LLM analysis.

    Returns a dict describing what's in the repo — suitable for feeding
    to a subagent as context for content generation.
    """
    manifest = {
        "name": ref_dir.name,
        "path": str(ref_dir),
        "files": [],
        "key_files": [],
    }

    # Find key files
    key_names = {
        "README.md", "AGENTS.md", "CLAUDE.md", "CONTEXT.md",
        "CHANGELOG.md", "package.json", "Cargo.toml", "pyproject.toml",
        "mise.toml", ".mise.toml",
    }
    skill_files = []

    for root, dirs, files in os.walk(ref_dir):
        # Skip .git
        dirs[:] = [d for d in dirs if d != ".git"]
        rel_root = Path(root).relative_to(ref_dir)

        for f in files:
            rel_path = str(rel_root / f) if str(rel_root) != "." else f
            manifest["files"].append(rel_path)

            if f in key_names:
                manifest["key_files"].append(rel_path)
            if f == "SKILL.md":
                skill_files.append(rel_path)

    manifest["skill_files"] = skill_files
    manifest["file_count"] = len(manifest["files"])
    # Keep files list manageable
    if len(manifest["files"]) > 200:
        manifest["files"] = manifest["files"][:200]
        manifest["truncated"] = True

    return manifest


def generate_scaffold(ref_dir: Path, output_dir: Path):
    """Generate a minimal OKF bundle scaffold from a reference repo scan.

    This creates the directory structure and a placeholder overview.
    Real content would be filled by an LLM subagent.
    """
    name = ref_dir.name
    manifest = scan_reference(ref_dir)
    bundle_root = output_dir / name

    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")

    # Write overview concept
    readme_path = ref_dir / "README.md"
    readme_excerpt = ""
    if readme_path.exists():
        lines = readme_path.read_text(encoding="utf-8").splitlines()
        # Grab first prose lines (skip headings, tables, blank, code fences)
        content_lines = [
            l.strip() for l in lines[1:30]
            if l.strip()
            and not l.startswith("#")
            and not l.startswith("|")
            and not l.startswith("```")
            and not l.startswith("-")
            and not l.startswith("*")
        ]
        readme_excerpt = " ".join(content_lines[:2])[:200].strip()

    write_concept(bundle_root, "overview.md", {
        "type": "Repository",
        "title": name,
        "description": readme_excerpt or f"Reference repository: {name}",
        "resource": str(ref_dir),
        "tags": _infer_tags(manifest),
        "timestamp": now,
    }, _overview_body_placeholder(name, manifest))

    # Write patterns/ scaffold
    write_concept(bundle_root, "patterns/_template.md", {
        "type": "Pattern",
        "title": "[Pattern Name]",
        "description": "[One sentence describing the pattern]",
        "tags": [],
        "timestamp": now,
    }, _pattern_template())

    # Write conventions/ scaffold
    write_concept(bundle_root, "conventions/_template.md", {
        "type": "Convention",
        "title": "[Convention Name]",
        "description": "[One sentence describing the convention]",
        "tags": [],
        "timestamp": now,
    }, _convention_template())

    # Write integrations/ scaffold
    write_concept(bundle_root, "integrations/_template.md", {
        "type": "Integration",
        "title": "[Integration Point]",
        "description": "[How this connects to our project]",
        "tags": [],
        "timestamp": now,
    }, _integration_template())

    # Write root index
    write_index(bundle_root, ".", [
        {"title": name, "path": "overview.md", "description": readme_excerpt or "Repository overview"},
        {"title": "Patterns", "path": "patterns/", "description": "Novel techniques worth adopting"},
        {"title": "Conventions", "path": "conventions/", "description": "Local rules and naming"},
        {"title": "Integrations", "path": "integrations/", "description": "Connection points to our project"},
    ])

    return bundle_root, manifest


def _infer_tags(manifest: dict) -> list:
    tags = []
    files = manifest.get("files", [])
    file_str = " ".join(files).lower()
    if any(f.endswith(".ts") or f.endswith(".js") for f in files):
        tags.append("typescript")
    if any(f.endswith(".py") for f in files):
        tags.append("python")
    if any(f.endswith(".rs") for f in files):
        tags.append("rust")
    if "SKILL.md" in file_str or "skills" in file_str:
        tags.append("skills")
    if "agents" in file_str or "AGENTS.md" in file_str:
        tags.append("agents")
    return tags


def _overview_body_placeholder(name: str, manifest: dict) -> str:
    key_files = manifest.get("key_files", [])
    skills = manifest.get("skill_files", [])
    body = f"# {name}\n\n"
    body += "[LLM: Replace with purpose, architecture, and key decisions]\n\n"
    if key_files:
        body += "# Key Files\n\n"
        for f in key_files[:10]:
            body += f"- `{f}`\n"
    if skills:
        body += "\n# Skills Found\n\n"
        for s in skills:
            body += f"- `{s}`\n"
    body += "\n# Citations\n\n"
    body += f"[1] [{name} source]({manifest['path']})\n"
    return body


def _pattern_template() -> str:
    return """[LLM: Describe the pattern — what problem it solves, how it works,
where it's implemented in the source.]

# Implementation

[Key files and code patterns]

# When to Use

[Situations where this pattern applies]

# Citations

[Links to specific source files]
"""


def _convention_template() -> str:
    return """[LLM: Describe the local rule — what it is, why it exists,
how it deviates from common practice.]

# Rule

[The convention stated concisely]

# Rationale

[Why this convention was chosen]

# Citations

[Links to specific source files]
"""


def _integration_template() -> str:
    return """[LLM: Describe how this reference connects to our project —
what we can adopt, what requires adaptation.]

# Connection

[How this integrates with our workflow]

# Adaptation Required

[What needs to change for our context]

# Citations

[Links to specific source files]
"""


def main():
    parser = argparse.ArgumentParser(description="Generate OKF bundle from reference repo")
    parser.add_argument("reference", help="Path to reference repo directory")
    parser.add_argument("--output", "-o", default=".memory/references",
                        help="Output directory for bundles (default: .memory/references)")
    parser.add_argument("--scan", action="store_true",
                        help="Only scan and emit manifest JSON (for LLM consumption)")
    args = parser.parse_args()

    ref_dir = Path(args.reference).resolve()
    if not ref_dir.is_dir():
        print(f"Error: {ref_dir} is not a directory", file=sys.stderr)
        sys.exit(1)

    if args.scan:
        manifest = scan_reference(ref_dir)
        print(json.dumps(manifest, indent=2))
        return

    output_dir = Path(args.output)
    bundle_root, manifest = generate_scaffold(ref_dir, output_dir)
    print(f"Bundle scaffold created: {bundle_root}")
    print(f"  Files scanned: {manifest['file_count']}")
    print(f"  Key files: {len(manifest['key_files'])}")
    print(f"  Skills found: {len(manifest.get('skill_files', []))}")
    print(f"\nNext: Run LLM subagent to fill concept docs (replace [LLM: ...] placeholders)")


if __name__ == "__main__":
    main()
