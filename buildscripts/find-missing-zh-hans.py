#!/usr/bin/env python3
"""List macOS UI strings that have no Simplified Chinese translation.

Checks the String Catalogs (*.xcstrings) used by the Mac app and the XIBs
localized through Base.lproj + zh-Hans.lproj/*.strings. Run from anywhere:

    python3 buildscripts/find-missing-zh-hans.py
"""
import json
import re
import xml.etree.ElementTree as ET
from pathlib import Path

LANG = "zh-Hans"
ROOT = Path(__file__).resolve().parent.parent
SEARCH_DIRS = ["Mac", "Shared", "Modules"]
SKIP_PARTS = {"Tests", ".build", "iOS"}
XIB_ATTRIBUTES = ("title", "label", "placeholderString", "toolTip", "paletteLabel")
# Interface Builder placeholders that code replaces at runtime.
PLACEHOLDER = re.compile(r"^(Item \d+|Text Cell|Table View Cell|Version Text|<<.*>>|NetNewsWire|[^A-Za-z]*|\S+@\S+|[\w.-]+\.(com|org|net))$")


def relevant(path):
    return not SKIP_PARTS.intersection(path.relative_to(ROOT).parts)


def missing_in_catalog(path):
    catalog = json.loads(path.read_text(encoding="utf-8"))
    for key, entry in catalog.get("strings", {}).items():
        if not key.strip() or entry.get("shouldTranslate", True) is False:
            continue
        if entry.get("extractionState") == "stale":
            continue
        unit = entry.get("localizations", {}).get(LANG)
        if unit is None or unit.get("stringUnit", {}).get("state") == "new":
            yield key


def missing_in_xib(xib):
    if (xib.parent.parent / "mul.lproj" / (xib.stem + ".xcstrings")).exists():
        return  # Localized through its String Catalog, checked above.
    strings_file = xib.parent.parent / f"{LANG}.lproj" / (xib.stem + ".strings")
    translated = set()
    if strings_file.exists():
        translated = set(re.findall(r'^"([^"]+)"\s*=', strings_file.read_text(encoding="utf-8"), re.M))
    for element in ET.parse(xib).iter():
        object_id = element.get("id")
        if not object_id:
            continue
        for attribute in XIB_ATTRIBUTES:
            value = element.get(attribute)
            if value and not PLACEHOLDER.match(value.strip()) and f"{object_id}.{attribute}" not in translated:
                yield f"{object_id}.{attribute} = {value!r}"


def main():
    total = 0
    for directory in SEARCH_DIRS:
        for path in sorted((ROOT / directory).rglob("*.xcstrings")):
            if not relevant(path):
                continue
            keys = list(missing_in_catalog(path))
            if keys:
                print(f"\n{path.relative_to(ROOT)} ({len(keys)})")
                for key in keys:
                    print(f"  {key!r}")
                total += len(keys)
        for xib in sorted((ROOT / directory).rglob("Base.lproj/*.xib")):
            if not relevant(xib):
                continue
            items = list(missing_in_xib(xib))
            if items:
                print(f"\n{xib.relative_to(ROOT)} ({len(items)})")
                for item in items:
                    print(f"  {item}")
                total += len(items)
    print(f"\n{total} untranslated" if total else "All strings have zh-Hans translations.")


if __name__ == "__main__":
    main()
