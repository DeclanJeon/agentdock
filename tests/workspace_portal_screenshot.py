#!/usr/bin/env python3
"""Capture a screenshot via xdg-desktop-portal and save it to a requested PNG path.

This is useful on GNOME/Wayland sessions where direct screenshot CLIs are not
installed and org.gnome.Shell.Screenshot rejects untrusted DBus calls.
"""
from __future__ import annotations

import shutil
import sys
import uuid
from pathlib import Path
from urllib.parse import unquote, urlparse

import gi

gi.require_version("Gio", "2.0")
gi.require_version("GLib", "2.0")
from gi.repository import Gio, GLib  # noqa: E402


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: workspace_portal_screenshot.py <output.png>", file=sys.stderr)
        return 2

    output = Path(sys.argv[1])
    output.parent.mkdir(parents=True, exist_ok=True)

    bus = Gio.bus_get_sync(Gio.BusType.SESSION, None)
    unique_name = bus.get_unique_name().replace(":", "").replace(".", "_")
    token = "agentdock_" + uuid.uuid4().hex
    handle_path = f"/org/freedesktop/portal/desktop/request/{unique_name}/{token}"
    loop = GLib.MainLoop()
    response: dict[str, object] = {}

    def on_response(_conn, _sender, _path, _iface, _signal, params, _data):
        code, results = params.unpack()
        response["code"] = code
        response["results"] = results
        loop.quit()

    bus.signal_subscribe(
        "org.freedesktop.portal.Desktop",
        "org.freedesktop.portal.Request",
        "Response",
        handle_path,
        None,
        Gio.DBusSignalFlags.NO_MATCH_RULE,
        on_response,
        None,
    )

    options = {
        "handle_token": GLib.Variant("s", token),
        "interactive": GLib.Variant("b", False),
    }
    bus.call_sync(
        "org.freedesktop.portal.Desktop",
        "/org/freedesktop/portal/desktop",
        "org.freedesktop.portal.Screenshot",
        "Screenshot",
        GLib.Variant("(sa{sv})", ("", options)),
        GLib.VariantType("(o)"),
        Gio.DBusCallFlags.NONE,
        10000,
        None,
    )

    GLib.timeout_add_seconds(20, lambda: (loop.quit(), False)[1])
    loop.run()

    if response.get("code") != 0:
        print(f"portal screenshot failed: response={response}", file=sys.stderr)
        return 3
    results = response.get("results") or {}
    uri = results.get("uri") if isinstance(results, dict) else None
    if not isinstance(uri, str) or not uri.startswith("file://"):
        print(f"portal screenshot returned unsupported uri: {uri!r}", file=sys.stderr)
        return 4

    source = Path(unquote(urlparse(uri).path))
    shutil.copyfile(source, output)
    print(output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
