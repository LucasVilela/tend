#!/usr/bin/env python3
"""Copy design/mood-faces/*.svg into the asset catalog as vector image sets.

Run from the repo root:  python3 scripts/import_mood_faces.py
Each face becomes `mood-<kind>` (and `mood-<kind>-large`), with Preserve Vector Data on and a
single universal scale. The embedded <metadata> block is stripped to keep the bundle small.
Also writes the Background colour set used by the launch screen.
"""
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "design" / "mood-faces"
CATALOG = ROOT / "Practices" / "Resources" / "Assets.xcassets"
FOLDER = CATALOG / "MoodFaces"
INFO = {"author": "xcode", "version": 1}


def write_json(path: pathlib.Path, data: dict) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, indent=2) + "\n")


def main() -> None:
    write_json(CATALOG / "Contents.json", {"info": INFO})
    write_json(FOLDER / "Contents.json", {"info": INFO, "properties": {"provides-namespace": False}})
    count = 0
    for svg in sorted(SRC.glob("*.svg")):
        name = f"mood-{svg.stem}"
        text = re.sub(r"<metadata>.*?</metadata>", "", svg.read_text(), flags=re.S)
        text = text.replace(' xmlns:c2pa="http://c2pa.org/manifest"', "")
        imageset = FOLDER / f"{name}.imageset"
        imageset.mkdir(parents=True, exist_ok=True)
        (imageset / f"{name}.svg").write_text(text)
        write_json(imageset / "Contents.json", {
            "images": [{"filename": f"{name}.svg", "idiom": "universal"}],
            "info": INFO,
            "properties": {"preserves-vector-representation": True},
        })
        count += 1

    tokens = json.loads((ROOT / "design" / "tokens.json").read_text())
    bg = tokens["color"]["background"].lstrip("#")
    rgb = {k: f"0x{bg[i:i + 2]}" for k, i in (("red", 0), ("green", 2), ("blue", 4))}
    color = {"color-space": "srgb", "components": {"alpha": "1.000", **rgb}}
    write_json(CATALOG / "Background.colorset" / "Contents.json", {
        "colors": [{"color": color, "idiom": "universal"}], "info": INFO,
    })
    write_json(CATALOG / "AccentColor.colorset" / "Contents.json", {
        "colors": [{"color": {"color-space": "srgb", "components": {"alpha": "1.000", "red": "0xEC", "green": "0xEA", "blue": "0xE6"}}, "idiom": "universal"}],
        "info": INFO,
    })
    print(f"Imported {count} mood faces into {FOLDER.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
