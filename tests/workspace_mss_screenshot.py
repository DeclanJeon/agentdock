#!/usr/bin/env python3
"""Capture the current primary monitor to PNG using mss.

This helper is intentionally optional: install mss in a disposable venv and call via
AGENTDOCK_NATIVE_SCREENSHOT_CMD='<venv>/bin/python tests/workspace_mss_screenshot.py {path}'.
"""
from __future__ import annotations

import sys
from pathlib import Path

try:
    import mss
    import mss.tools
except Exception as exc:  # pragma: no cover - optional runtime helper
    raise SystemExit(f"mss is required for this capture helper: {exc}")


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: workspace_mss_screenshot.py <output.png>", file=sys.stderr)
        return 2
    output = Path(sys.argv[1])
    output.parent.mkdir(parents=True, exist_ok=True)
    with mss.mss() as sct:
        monitor = sct.monitors[1] if len(sct.monitors) > 1 else sct.monitors[0]
        image = sct.grab(monitor)
        mss.tools.to_png(image.rgb, image.size, output=str(output))
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
