#!/bin/bash

set -e

cleanup() {
  for pid in "${postgres_pid:-}" "${redis_pid:-}" "${maxkb_pid:-}" "${ocr_pid:-}"; do
    if [ -n "$pid" ]; then kill "$pid" 2>/dev/null || true; fi
  done
  wait || true
}
trap cleanup EXIT
trap 'exit 0' TERM INT

if [ -f "/opt/maxkb/PG_VERSION" ] || [ -f "/var/lib/postgresql/data/PG_VERSION" ]; then
  # 如果是v1版本一键安装的的目录则退出
  echo -e "\033[1;31mFATAL ERROR: Upgrade from v1 to v2 is not supported.\033[0m"
  echo -e "\033[1;31mThe process will exit.\033[0m"
  exit 1
fi

if [ "$MAXKB_DB_HOST" = "127.0.0.1" ]; then
  echo -e "\033[1;32mPostgreSQL starting...\033[0m"
  /usr/bin/start-postgres.sh &
  postgres_pid=$!
  sleep 5
  wait-for-it 127.0.0.1:5432 --timeout=120 --strict -- echo -e "\033[1;32mPostgreSQL started.\033[0m"
fi

if [ "$MAXKB_REDIS_HOST" = "127.0.0.1" ]; then
  echo -e "\033[1;32mRedis starting...\033[0m"
  /usr/bin/start-redis.sh &
  redis_pid=$!
  sleep 5
  wait-for-it 127.0.0.1:6379 --timeout=60 --strict -- echo -e "\033[1;32mRedis started.\033[0m"
fi

case "${MAXKB_OCR_ENABLED,,}" in
  1|true|yes)
    echo -e "\033[1;32mOCR starting...\033[0m"
    /usr/bin/start-ocr.sh &
    ocr_pid=$!
    python - "$ocr_pid" <<'PY'
import json
import os
from pathlib import Path
import sys
import time
from urllib.request import ProxyHandler, Request, build_opener

opener = build_opener(ProxyHandler({}))
deadline = time.monotonic() + 330
while time.monotonic() < deadline:
    os.kill(int(sys.argv[1]), 0)
    try:
        token = os.environ.get("MAXKB_OCR_TOKEN") or Path(os.environ["MAXKB_OCR_TOKEN_FILE"]).read_text().strip()
        request = Request("http://127.0.0.1:11637/health", headers={"Authorization": f"Bearer {token}"})
        with opener.open(request, timeout=5) as response:
            if json.load(response).get("ready"):
                print("OCR started.", flush=True)
                break
    except (OSError, ValueError):
        pass
    time.sleep(1)
else:
    raise SystemExit("OCR startup timed out")
PY
    ;;
esac

echo -e "\033[1;32mMaxKB starting...\033[0m"
/usr/bin/start-maxkb.sh &
maxkb_pid=$!
sleep 10
wait-for-it 127.0.0.1:8080 --timeout=180 --strict -- echo -e "\033[1;32mMaxKB started.\033[0m"

wait -n
echo -e "\033[1;31mSystem is shutting down.\033[0m"
