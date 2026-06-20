"""Create a pre-seeded recall database for eval reproducibility.

Run this once to generate the fixture DB at tools/evals/fixtures/recall.sqlite3.
The eval harness copies this DB to the temp workspace before running tasks.
"""

import sys
from pathlib import Path

# Add the recall package to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "recall"))

FIXTURE_DB = Path(__file__).parent / "recall.sqlite3"
FIXTURE_CONTENT = [
    {
        "content": "We chose field-relative yards as the canonical coordinate system for play data. Yards are human-readable for coaches, the conversion to 3D is a clean multiply (yards * 0.9144 = meters), and it avoids normalized [0,1] coordinates which hide domain meaning. The editor projects yards into pixels, runtime projects yards into Godot meters.",
        "wing": "lacrosse_bosse",
        "room": "decisions",
        "type": "decision",
        "source": "agent-write",
    },
    {
        "content": "Decision: zero new autoloads for the first execution slice. PracticeFlowCoordinator owns app-flow dependencies. PracticeExecution owns run-scoped dependencies. Runtime children receive dependencies by explicit setup/start calls. Godot's autoload docs frame singletons around state that must persist between scene changes — our rebuild pushes run state into RuntimeExecutionContext instead.",
        "wing": "lacrosse_bosse",
        "room": "decisions",
        "type": "decision",
        "source": "agent-write",
    },
    {
        "content": "The state machine is polling-driven, not event-driven. StateIdle.update() checks conditions every physics frame. Nothing externally pushes events. Objectives serve dual roles: task tracker for humans AND physics controller for AI. This means objectives can't be dumb data — they know Fielder3D internals. The controller is implicit (whichever code ran last wins).",
        "wing": "lacrosse_bosse",
        "room": "architecture",
        "type": "fact",
        "source": "agent-write",
    },
    {
        "content": "We decided this is a ground-up rebuild of the practice execution path. Build the ideal PracticeExecution surface first, then reconnect setup/editor/menu flows to it. Game3D compatibility is not the primary migration constraint. Breaking functionality on this branch is acceptable — we'll be complete before rollout.",
        "wing": "lacrosse_bosse",
        "room": "decisions",
        "type": "decision",
        "source": "agent-write",
    },
    {
        "content": "Mirroring should be a non-destructive transform against the base play. PracticeRunConfig carries source_play + mirrored flag. PracticeExecution prepares a disposable runtime copy unconditionally — even when mirrored == false — because runtime also mutates current_step. The mirror transform runs on the copy, never the source.",
        "wing": "lacrosse_bosse",
        "room": "decisions",
        "type": "decision",
        "source": "agent-write",
    },
    {
        "content": "The fielder controller split resolves the core architectural tension: FielderBody3D owns CharacterBody3D movement. FielderController owns objective interpretation and body commands. PlayerFielderController handles human input. AIFielderController drives AI behavior. Single ownership at each layer, no implicit 'last writer wins'.",
        "wing": "lacrosse_bosse",
        "room": "architecture",
        "type": "fact",
        "source": "agent-write",
    },
    {
        "content": "Ball state is owned by BallStateManager — a dedicated service that validates transitions, applies physics, and emits ball_state_changed. Objectives and controllers request actions (throw_to, catch_attempt) but don't directly mutate possession. States: held(owner), in_flight(from, to, flight_id), loose.",
        "wing": "lacrosse_bosse",
        "room": "architecture",
        "type": "fact",
        "source": "agent-write",
    },
    {
        "content": "lacrosse-bosse-platform is positioned as the future canonical repo. lacrosse-bosse (game code) and lacrosse-bosse-agentic (agent docs) are source references, not automatic authority. The platform uses a monorepo layout: client/ for Godot project, services/ for backend, infra/ for CDK.",
        "wing": "lacrosse_bosse",
        "room": "planning",
        "type": "fact",
        "source": "agent-write",
    },
]


def main():
    import os
    # Override DB path for fixture
    os.environ["RECALL_DB_PATH"] = str(FIXTURE_DB)

    # Patch store to use fixture path
    from recall import store
    store.DB_PATH = FIXTURE_DB

    if FIXTURE_DB.exists():
        FIXTURE_DB.unlink()

    from recall import embedder

    conn = store.get_connection()
    print(f"Creating fixture DB: {FIXTURE_DB}")

    for item in FIXTURE_CONTENT:
        emb = embedder.embed_document(item["content"])
        store.upsert(
            conn,
            content=item["content"],
            embedding=emb,
            wing=item["wing"],
            room=item["room"],
            type_=item["type"],
            source=item["source"],
        )

    conn.commit()
    total = conn.execute("SELECT COUNT(*) FROM drawers").fetchone()[0]
    conn.close()
    print(f"Done: {total} drawers seeded.")


if __name__ == "__main__":
    main()
