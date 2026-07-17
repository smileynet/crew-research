
# ─── Recall Ingestion (ensure cron + staleness check) ─────────────────────────
# Ensures cron is running (WSL doesn't auto-start services) and triggers
# recall ingestion if last run was >4 hours ago.
_recall_ensure_cron() {
    if ! pgrep -x cron >/dev/null 2>&1; then
        sudo service cron start >/dev/null 2>&1 || true
    fi
}

_recall_ingest_if_stale() {
    local stamp_file="$HOME/.recall-last-ingest"
    local stale_seconds=14400  # 4 hours
    local now
    now=$(date +%s)

    if [[ -f "$stamp_file" ]]; then
        local last_run
        last_run=$(stat -c %Y "$stamp_file" 2>/dev/null || echo 0)
        local elapsed=$((now - last_run))
        if [[ $elapsed -lt $stale_seconds ]]; then
            return 0
        fi
    fi

    # Touch stamp immediately to prevent concurrent runs
    touch "$stamp_file"
    # Run in background, detached
    (
        export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
        nohup "$HOME/.local/bin/recall-ingest-all.sh" >> /tmp/recall-ingest.log 2>&1 &
    )
}

_recall_ensure_cron
_recall_ingest_if_stale
