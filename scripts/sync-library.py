#!/usr/bin/env python3
"""Copy every skill listed in library/INDEX.md from a claude-skills clone into library/.

    python3 -I scripts/sync-library.py <path to a claude-skills clone>

Each listed skill folder is replaced whole, so files the source has dropped do not linger.
Run scripts/check-plugin.py afterwards.
"""
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LIB = ROOT / "library"


def listed_skills():
    rows = re.findall(r"^\| ([a-z][a-z0-9-]*) \|", (LIB / "INDEX.md").read_text(encoding="utf-8"), re.M)
    return [r for r in rows if r != "skill"]


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    src = Path(sys.argv[1]).expanduser().resolve()
    missing = [s for s in listed_skills() if not (src / s / "SKILL.md").is_file()]
    if missing:
        sys.exit(f"not found in {src}: {', '.join(missing)}")
    for name in listed_skills():
        dest = LIB / name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(src / name, dest)
    shutil.copy2(src / "LICENSE", LIB / "LICENSE")
    print(f"copied {len(listed_skills())} skills and LICENSE from {src}")


if __name__ == "__main__":
    main()
