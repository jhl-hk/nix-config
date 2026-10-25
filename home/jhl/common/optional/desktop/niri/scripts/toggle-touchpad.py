#!/usr/bin/python3
import fcntl
from pathlib import Path
import subprocess

# Included by config.kdl; present means the touchpad is off.
# git-ignored, so the state stays on this machine.
STATE = """\
input {
    touchpad {
        off
    }
}
"""


def main():
    with open(__file__) as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = Path.home() / ".config/niri/local/touchpad.kdl"
        # Niri reloads the configuration when an included file changes.
        if state.exists():
            state.unlink()
        else:
            state.parent.mkdir(exist_ok=True)
            state.write_text(STATE)
            result = subprocess.run(["niri", "validate"], capture_output=True)
            if result.returncode:
                state.unlink()
                raise RuntimeError(result.stderr.decode())


if __name__ == "__main__":
    main()
