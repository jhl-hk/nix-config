#!/usr/bin/python3
import fcntl
from pathlib import Path
import re
import subprocess


def toggle(text):
    pattern = r"(?m)^(    touchpad \{\n)(        (?:// )?off)(?=\n)"
    def replace(match):
        line = "        off" if "//" in match[2] else "        // off"
        return match[1] + line
    result, count = re.subn(pattern, replace, text, count=1)
    if count != 1:
        raise RuntimeError("Cannot locate the touchpad off setting")
    return result


def main():
    with open(__file__) as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        config = Path.home() / ".config/niri/config.kdl"
        original = config.read_text()
        updated = toggle(original)
        # Niri reloads the configuration when this file changes.
        config.write_text(updated)
        result = subprocess.run(["niri", "validate"], capture_output=True)
        if result.returncode:
            config.write_text(original)
            raise RuntimeError(result.stderr.decode())


if __name__ == "__main__":
    main()
