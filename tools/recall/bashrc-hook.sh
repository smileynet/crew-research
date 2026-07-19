
# ─── Recall Ingestion (ensure cron + staleness check) ─────────────────────────
# Ensures cron is running (WSL doesn't auto-start services) and triggers
# recall ingestion if last run was >4 hours ago.
_recall_ensure_cron() {
    if ! pgrep -x cron >/dev/null 2>&1; then
        sudo service cron start >/dev/null 2>&1 || true
    fi
}

_recall_ingest_if_stale() {
    # Success marker — written by the recall CLI after each ingest
    # (same path doctor.sh and recall-session-start steering check).
    local success_marker="$HOME/.recall/last_ingest"
    # Attempt stamp — touched when a run fires; prevents retry storms when
    # ingestion keeps failing (success marker stays stale, correctly).
    local attempt_stamp="$HOME/.recall-last-ingest"
    local stale_seconds=14400  # 4 hours
    local now
    now=$(date +%s)

    # Fresh successful ingest → nothing to do
    if [[ -f "$success_marker" ]]; then
        local last_success
        last_success=$(stat -c %Y "$success_marker" 2>/dev/null || echo 0)
        if (( now - last_success < stale_seconds )); then
            return 0
        fi
    fi

    # Recent attempt (running or failed) → don't re-fire yet
    if [[ -f "$attempt_stamp" ]]; then
        local last_attempt
        last_attempt=$(stat -c %Y "$attempt_stamp" 2>/dev/null || echo 0)
        if (( now - last_attempt < stale_seconds )); then
            return 0
        fi
    fi

    # Touch stamp immediately to prevent concurrent runs
    touch "$attempt_stamp"
    # Run in background, detached
    (
        export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
        nohup "$HOME/.local/bin/recall-ingest-all.sh" >> /tmp/recall-ingest.log 2>&1 &
    )
}

_recall_ensure_cron
_recall_ingest_if_stale
