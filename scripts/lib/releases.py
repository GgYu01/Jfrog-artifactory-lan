#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
import urllib.request
from pathlib import Path

VERSION_RE = re.compile(r">(\d+\.\d+\.\d+)/<")


def version_key(version: str) -> tuple[int, ...]:
    return tuple(int(part) for part in version.split("."))


def parse_versions(index_html: str) -> list[str]:
    return sorted(set(VERSION_RE.findall(index_html)), key=version_key)


def latest_version(index_html: str) -> str:
    versions = parse_versions(index_html)
    if not versions:
        raise ValueError("No versions found in upstream index")
    return versions[-1]


def fetch_text(url: str) -> str:
    with urllib.request.urlopen(url, timeout=30) as response:
        return response.read().decode("utf-8", errors="replace")


def main(argv: list[str]) -> int:
    if len(argv) < 2:
        print("usage: releases.py latest <index-url> | parse-file <path>", file=sys.stderr)
        return 2

    command = argv[1]
    if command == "latest":
        if len(argv) != 3:
            print("usage: releases.py latest <index-url>", file=sys.stderr)
            return 2
        print(latest_version(fetch_text(argv[2])))
        return 0

    if command == "parse-file":
        if len(argv) != 3:
            print("usage: releases.py parse-file <path>", file=sys.stderr)
            return 2
        print(latest_version(Path(argv[2]).read_text(encoding="utf-8")))
        return 0

    print(f"unknown command: {command}", file=sys.stderr)
    return 2


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
