#!/usr/bin/env bash
# limit-watch.sh — theo dõi rate-limit / hết hạn phiên Cursor và đánh thức agent.
#
# Cách dùng:
#   ./mockup/tools/limit-watch.sh once          # kiểm tra một lần, in JSON
#   ./mockup/tools/limit-watch.sh watch 60      # vòng lặp mỗi N giây; khi hết limit → sentinel wake
#
# Sentinel (stdout) khi cần agent quay lại làm việc:
#   AGENT_LOOP_WAKE_mockup_limit {"prompt":"...","reason":"..."}
#
# Môi trường tùy chọn:
#   LIMIT_STATE_FILE  — file trạng thái (mặc định: mockup/tools/.limit-state)
#   LIMIT_RESUME_AT   — epoch giây hết hạn (nếu đã biết từ thông báo Cursor)
#   LIMIT_FORCE_BLOCKED=1 — giả lập đang bị chặn (để thử)

set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE="${LIMIT_STATE_FILE:-$ROOT/mockup/tools/.limit-state}"
INTERVAL="${2:-60}"
MODE="${1:-once}"
PROMPT_DEFAULT='Tiếp tục gói mockup 6–11 theo mockup/CHECKLIST-MOCKUP.md: hoàn thành phần còn dở, không hỏi lại, không sửa app.js/app.css, cập nhật bảng theo dõi khi xong.'

now() { date +%s; }
iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# Heuristic: nếu có LIMIT_RESUME_AT trong tương lai → đang chờ refresh.
# Cursor không expose API token công khai; tool dựa trên state file / biến môi trường
# do agent ghi khi gặp thông báo rate limit.
read_state() {
  local resume_at=""
  local note=""
  if [[ -n "${LIMIT_RESUME_AT:-}" ]]; then
    resume_at="$LIMIT_RESUME_AT"
  elif [[ -f "$STATE" ]]; then
    # shellcheck disable=SC1090
    source "$STATE" 2>/dev/null || true
    resume_at="${RESUME_AT:-}"
    note="${NOTE:-}"
  fi
  local blocked=0
  local remaining=-1
  local t
  t="$(now)"
  if [[ "${LIMIT_FORCE_BLOCKED:-0}" == "1" ]]; then
    blocked=1
    remaining=999
  elif [[ -n "$resume_at" && "$resume_at" =~ ^[0-9]+$ ]]; then
    if (( resume_at > t )); then
      blocked=1
      remaining=$((resume_at - t))
    else
      blocked=0
      remaining=0
    fi
  fi
  printf '{"ts":"%s","blocked":%s,"remaining_sec":%s,"resume_at":%s,"note":%s}\n' \
    "$(iso)" \
    "$blocked" \
    "$remaining" \
    "${resume_at:-null}" \
    "$(python3 -c 'import json,sys; print(json.dumps(sys.argv[1]))' "${note:-}")"
}

mark_blocked() {
  # Usage: mark_blocked <epoch_resume> [note]
  local epoch="${1:?epoch}"
  local note="${2:-rate_limit}"
  cat >"$STATE" <<EOF
RESUME_AT=$epoch
NOTE=$(printf '%q' "$note")
UPDATED=$(now)
EOF
  echo "Wrote $STATE resume_at=$epoch" >&2
}

mark_clear() {
  rm -f "$STATE"
  echo "Cleared $STATE" >&2
}

emit_wake() {
  local reason="$1"
  local prompt="${LIMIT_WAKE_PROMPT:-$PROMPT_DEFAULT}"
  # JSON một dòng cho notify_on_output
  python3 - <<PY
import json
print("AGENT_LOOP_WAKE_mockup_limit " + json.dumps({
  "prompt": """$prompt""",
  "reason": """$reason""",
  "ts": "$(iso)",
}, ensure_ascii=False))
PY
}

case "$MODE" in
  once)
    read_state
    ;;
  mark)
    mark_blocked "${2:?epoch}" "${3:-rate_limit}"
    ;;
  clear)
    mark_clear
    ;;
  watch)
    echo "limit-watch: interval=${INTERVAL}s state=$STATE" >&2
    prev_blocked=""
    while true; do
      json="$(read_state)"
      echo "$json" >&2
      blocked="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["blocked"])' "$json")"
      remaining="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["remaining_sec"])' "$json")"
      if [[ "$blocked" == "1" ]]; then
        prev_blocked=1
        # ngủ đến gần lúc hết hạn, tối đa INTERVAL
        sleep_for="$INTERVAL"
        if [[ "$remaining" =~ ^[0-9]+$ ]] && (( remaining > 0 && remaining < INTERVAL )); then
          sleep_for=$((remaining + 2))
        fi
        sleep "$sleep_for"
      else
        if [[ "$prev_blocked" == "1" ]]; then
          emit_wake "limit_refreshed"
          prev_blocked=0
          mark_clear || true
        fi
        sleep "$INTERVAL"
      fi
    done
    ;;
  *)
    echo "Usage: $0 once|watch [interval]|mark <epoch> [note]|clear" >&2
    exit 2
    ;;
esac
