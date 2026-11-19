#!/usr/bin/env python3
"""3-way JSON merge helper for conflicted *.xcstrings files during git merge.

Preserves upstream additions/removals/comments/English updates while keeping
existing zh-Hans translations when the English source text has not changed.
"""
import json
import subprocess
import sys
from pathlib import Path


def git_show(stage: int, path: str) -> dict | None:
    try:
        raw = subprocess.check_output(
            ["git", "show", f":{stage}:{path}"], stderr=subprocess.DEVNULL
        )
        return json.loads(raw.decode("utf-8"))
    except (subprocess.CalledProcessError, json.JSONDecodeError, UnicodeDecodeError):
        return None


def english_value(entry: dict | None, key: str) -> str | None:
    if not entry:
        return None
    val = entry.get("localizations", {}).get("en", {}).get("stringUnit", {}).get("value")
    return val if val is not None else key


def merge_file(path: str) -> bool:
    base = git_show(1, path)
    ours = git_show(2, path)
    theirs = git_show(3, path)
    if ours is None or theirs is None:
        print(f"Skipping {path}: cannot 3-way merge (leaving conflict unresolved)")
        return False

    base_s = (base or {}).get("strings", {})
    ours_s = ours.get("strings", {})
    theirs_s = theirs.get("strings", {})

    merged_s = {}
    reused = 0
    en_changed = []

    for key, t_entry in theirs_s.items():
        entry = json.loads(json.dumps(t_entry))
        o_entry = ours_s.get(key)
        b_entry = base_s.get(key)
        zh = (o_entry or {}).get("localizations", {}).get("zh-Hans")
        if zh is not None:
            if b_entry is not None and english_value(t_entry, key) != english_value(b_entry, key):
                en_changed.append(key)
            else:
                locs = entry.setdefault("localizations", {})
                if "zh-Hans" not in locs:
                    locs["zh-Hans"] = zh
                    reused += 1
        merged_s[key] = entry

    merged = dict(theirs)
    merged["strings"] = merged_s
    Path(path).write_text(
        json.dumps(merged, ensure_ascii=False, indent=2, separators=(", ", " : ")) + "\n",
        encoding="utf-8",
    )
    subprocess.check_call(["git", "add", path])
    print(f"Merged {path}: total={len(merged_s)}, reused_zh={reused}, en_changed={len(en_changed)}")
    for k in en_changed:
        print(f"  en changed (needs re-translation): {k!r}")
    return True


def main():
    paths = sys.argv[1:]
    if not paths:
        out = subprocess.check_output(
            ["git", "diff", "--name-only", "--diff-filter=U", "--", "*.xcstrings"],
            text=True,
        )
        paths = [line.strip() for line in out.splitlines() if line.strip()]
    for p in paths:
        merge_file(p)


if __name__ == "__main__":
    main()
