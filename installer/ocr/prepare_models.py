# coding=utf-8
"""Validate bundled model files and localize their configuration for the container."""
import json
from pathlib import Path
import sys

from server import model_manifest


def prepare(root):
    expected = json.loads((root / "manifest.json").read_text(encoding="utf-8"))
    if model_manifest(root) != expected:
        raise ValueError("Local OCR model manifest mismatch; run warmup again before building")
    config = json.loads((root / "pipeline.json").read_text(encoding="utf-8"))

    def localize(value):
        if isinstance(value, dict):
            if value.get("model_name"):
                value["model_dir"] = str(root / value["model_name"])
            for child in value.values():
                localize(child)
        elif isinstance(value, list):
            for child in value:
                localize(child)

    localize(config)
    (root / "pipeline.json").write_text(json.dumps(config, ensure_ascii=False, indent=2), encoding="utf-8")
    (root / "manifest.json").write_text(json.dumps(model_manifest(root), indent=2), encoding="utf-8")


if __name__ == "__main__":
    prepare(Path(sys.argv[1]).resolve())
