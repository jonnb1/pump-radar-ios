#!/usr/bin/env python3
"""Print the UDID of an available iPhone simulator for xcodebuild."""

import json
import subprocess
import sys


def main() -> None:
    raw = subprocess.check_output(["xcrun", "simctl", "list", "devices", "available", "-j"])
    data = json.loads(raw)
    candidates = []
    for runtime, devices in data.get("devices", {}).items():
        if "iOS" not in runtime:
            continue
        for device in devices:
            if not device.get("isAvailable", True):
                continue
            name = device.get("name", "")
            if "iPhone" not in name:
                continue
            score = 10
            if name.strip() == "iPhone 16":
                score = 120
            elif "iPhone 16" in name:
                score = 100
            elif name.strip() == "iPhone 15":
                score = 90
            elif "iPhone 17" in name:
                score = 80
            elif "iPhone 15" in name:
                score = 70
            candidates.append((score, runtime, device["udid"], name))
    if not candidates:
        sys.exit("No available iPhone simulator")
    candidates.sort(key=lambda item: (item[0], item[1]))
    score, runtime, udid, name = candidates[-1]
    print(f"Using {name} from {runtime}", file=sys.stderr)
    print(udid)


if __name__ == "__main__":
    main()
