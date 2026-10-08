#!/bin/bash
set -e
umask 077
export PADDLE_PDX_CACHE_HOME=/opt/maxkb/ocr/cache
export HF_HOME=/opt/maxkb/ocr/huggingface
export MODELSCOPE_CACHE=/opt/maxkb/ocr/modelscope
exec /opt/maxkb-ocr/venv/bin/python /opt/maxkb-ocr/server.py \
  --model-dir /opt/maxkb-ocr/models \
  --token-file "${MAXKB_OCR_TOKEN_FILE:-/opt/maxkb/ocr/token}"
