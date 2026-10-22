#!/usr/bin/env python3
"""Read tray icon metadata without reading messages or icon pixel data."""

import json
import subprocess
import sys


def property_value(service, path, interface, name):
    result = subprocess.run(
        ["busctl", "--user", "--json=short", "get-property",
         service, path, interface, name],
        capture_output=True, text=True, timeout=5,
    )
    if result.returncode:
        raise RuntimeError(result.stderr.strip())
    value = json.loads(result.stdout)["data"]
    if isinstance(value, list) and len(value) == 1:
        return value[0]
    return value


def main():
    try:
        items = property_value(
            "org.kde.StatusNotifierWatcher", "/StatusNotifierWatcher",
            "org.kde.StatusNotifierWatcher", "RegisteredStatusNotifierItems",
        )
        # busctl encodes an array property as a single nested array.
        if isinstance(items, str):
            items = [items]
        entries = []
        for item in items:
            service, separator, suffix = item.partition("/")
            path = "/" + suffix if separator else "/StatusNotifierItem"
            entry = {"service": service, "path": path}
            for name in ("Id", "IconName", "IconThemePath", "Status"):
                try:
                    entry[name] = property_value(
                        service, path, "org.kde.StatusNotifierItem", name,
                    )
                except RuntimeError as error:
                    entry[name] = {"error": str(error)}
            entries.append(entry)
        relevant = [entry for entry in entries if any(
            term in (str(entry.get("Id", "")) + " "
                     + str(entry.get("IconName", ""))).lower()
            for term in ("telegram", "fcitx", "ibus", "keyboard", "input")
        )]
        print(json.dumps(relevant or entries, indent=2, ensure_ascii=False))
        return 0
    except (RuntimeError, subprocess.TimeoutExpired, ValueError, KeyError) as error:
        print("Cannot read desktop tray metadata: " + str(error), file=sys.stderr)
        print("Run this command in your desktop terminal: python3 " + __file__,
              file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
