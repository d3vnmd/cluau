#!/usr/bin/env python3
"""
Validate UI theme presets and generate their Luau module.

    python3 tools/build_themes.py            # validate + write templates/ui/ThemePresets.luau
    python3 tools/build_themes.py --check    # validate + fail if the generated file is out of date

Source of truth: skills/cluau/assets/themes/*.json. Every preset must:
  • use only real Roblox font families (rbxasset://fonts/families/<Name>.json) and valid weights;
  • pass WCAG contrast: Text/Surface ≥ 4.5, TextMuted/Surface ≥ 3.0, TextOnBackground/Background ≥ 4.5
    (HUD text drawn straight over the world/background — light panels on a dark world need it), OnAccent/Accent ≥ 4.5,
    OnDanger/Danger ≥ 4.5 (designers check this; AI-slop UI usually doesn't).
"""
from __future__ import annotations

import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
THEMES = os.path.join(ROOT, "skills", "cluau", "assets", "themes")
OUT = os.path.join(ROOT, "skills", "cluau", "templates", "ui", "ThemePresets.luau")

ROBLOX_FAMILIES = {
    "AccanthisADFStd", "AmaticSC", "Arimo", "Balthazar", "Bangers", "BuilderMono", "BuilderSans", "ComicNeueAngular",
    "Creepster", "DenkOne", "Fondamento", "FredokaOne", "GothamSSm", "GrenzeGotisch", "Guru", "HighwayGothic",
    "Inconsolata", "IndieFlower", "JosefinSans", "Jura", "Kalam", "LuckiestGuy", "Merriweather", "Michroma",
    "Montserrat", "Nunito", "Oswald", "PatrickHand", "PermanentMarker", "PressStart2P", "Roboto", "RobotoCondensed",
    "RobotoMono", "RomanAntique", "Sarpanch", "SourceSansPro", "SpecialElite", "TitilliumWeb", "Ubuntu", "Zekton",
}
WEIGHTS = {"Thin", "ExtraLight", "Light", "Regular", "Medium", "SemiBold", "Bold", "ExtraBold", "Heavy"}
COLOR_KEYS = ["Background", "Surface", "SurfaceRaised", "SurfaceSunken", "Border", "BorderStrong", "TextMuted", "Text",
              "TextOnBackground",
              "Accent", "AccentHover", "AccentPressed", "AccentShadow", "OnAccent", "Success", "Warning", "Danger",
              "OnDanger", "Scrim", "Currency"]
RARITY_KEYS = ["Common", "Uncommon", "Rare", "Epic", "Legendary"]
FONT_KEYS = ["display", "heading", "body", "bodyBold", "numbers"]
BUTTON_STYLES = {"chunky", "raised", "flat", "outline", "text"}
SHADOWS = {"hard", "soft", "none"}
CONTRAST_RULES = [("Text", "Surface", 4.5), ("Text", "SurfaceRaised", 4.5), ("TextMuted", "Surface", 3.0),
                  ("TextOnBackground", "Background", 4.5),
                  ("OnAccent", "Accent", 4.5), ("OnDanger", "Danger", 4.5)]
HEX = re.compile(r"^#[0-9A-Fa-f]{6}$")


def luminance(hex_color: str) -> float:
    def channel(c: int) -> float:
        v = c / 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (int(hex_color[i:i + 2], 16) for i in (1, 3, 5))
    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)


def contrast(a: str, b: str) -> float:
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def load_themes() -> dict[str, dict]:
    themes = {}
    for path in sorted(glob.glob(os.path.join(THEMES, "*.json"))):
        with open(path, encoding="utf-8") as fh:
            themes[os.path.splitext(os.path.basename(path))[0]] = json.load(fh)
    return themes


def validate(key: str, t: dict) -> list[str]:
    errors = []
    for field in ("name", "mood", "genres", "colors", "rarity", "fonts", "shape", "motion"):
        if field not in t:
            errors.append(f"{key}: missing '{field}'")
    if errors:
        return errors
    for k in COLOR_KEYS:
        if not HEX.match(str(t["colors"].get(k, ""))):
            errors.append(f"{key}: colors.{k} must be #RRGGBB")
    for k in RARITY_KEYS:
        if not HEX.match(str(t["rarity"].get(k, ""))):
            errors.append(f"{key}: rarity.{k} must be #RRGGBB")
    families = set()
    for k in FONT_KEYS:
        spec = t["fonts"].get(k)
        if not (isinstance(spec, list) and len(spec) == 2):
            errors.append(f"{key}: fonts.{k} must be [Family, Weight]")
            continue
        family, weight = spec
        families.add(family)
        if family not in ROBLOX_FAMILIES:
            errors.append(f"{key}: fonts.{k} family '{family}' is not a Roblox font family")
        if weight not in WEIGHTS:
            errors.append(f"{key}: fonts.{k} weight '{weight}' is not an Enum.FontWeight")
    if len(families) > 3:
        errors.append(f"{key}: {len(families)} font families — designers use 2 (3 with a numbers face)")
    shape = t["shape"]
    if shape.get("buttonStyle") not in BUTTON_STYLES:
        errors.append(f"{key}: shape.buttonStyle must be one of {sorted(BUTTON_STYLES)}")
    if shape.get("shadow") not in SHADOWS:
        errors.append(f"{key}: shape.shadow must be one of {sorted(SHADOWS)}")
    if not errors:
        for fg, bg, minimum in CONTRAST_RULES:
            ratio = contrast(t["colors"][fg], t["colors"][bg])
            if ratio < minimum:
                errors.append(f"{key}: contrast {fg}/{bg} = {ratio:.2f} < {minimum}")
    return errors


def lua_string(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def generate(themes: dict[str, dict]) -> str:
    out = [
        "--!strict",
        "-- GENERATED by tools/build_themes.py from skills/cluau/assets/themes/*.json — do not edit by hand.",
        "-- Location: ReplicatedStorage/Shared/UI/ThemePresets (ModuleScript). Theme.luau picks one preset.",
        "",
        "local function hex(value: string): Color3",
        "\treturn Color3.fromHex(value)",
        "end",
        "",
        "local function font(family: string, weight: Enum.FontWeight): Font",
        '\treturn Font.new(`rbxasset://fonts/families/{family}.json`, weight, Enum.FontStyle.Normal)',
        "end",
        "",
        "local ThemePresets = {}",
        "",
    ]
    for key, t in themes.items():
        out.append(f"ThemePresets.{key} = {{")
        out.append(f"\tName = {lua_string(t['name'])},")
        out.append(f"\tMood = {lua_string(t['mood'])},")
        out.append("\tColor = {")
        for k in COLOR_KEYS:
            out.append(f'\t\t{k} = hex("{t["colors"][k]}"),')
        out.append("\t},")
        out.append("\tRarity = {")
        for k in RARITY_KEYS:
            out.append(f'\t\t{k} = hex("{t["rarity"][k]}"),')
        out.append("\t},")
        out.append("\tFont = {")
        for k in FONT_KEYS:
            family, weight = t["fonts"][k]
            out.append(f'\t\t{k[0].upper() + k[1:]} = font("{family}", Enum.FontWeight.{weight}),')
        out.append("\t},")
        s = t["shape"]
        out.append("\tShape = {")
        out.append(f"\t\tRadiusSM = {int(s['radiusSM'])},")
        out.append(f"\t\tRadiusMD = {int(s['radiusMD'])},")
        out.append(f"\t\tStrokeThin = {s['strokeThin']},")
        out.append(f"\t\tStrokeBold = {s['strokeBold']},")
        out.append(f'\t\tButtonStyle = "{s["buttonStyle"]}",')
        out.append(f'\t\tShadow = "{s["shadow"]}",')
        out.append(f"\t\tShadowOffset = {int(s['shadowOffset'])},")
        out.append(f"\t\tGloss = {'true' if s['gloss'] else 'false'},")
        out.append("\t},")
        m = t["motion"]
        out.append("\tMotion = {")
        out.append(f'\t\tPersonality = "{m["personality"]}",')
        out.append(f"\t\tSpringFrequency = {m['springFrequency']},")
        out.append(f"\t\tSpringDamping = {m['springDamping']},")
        out.append("\t},")
        out.append("}")
        out.append("")
    out += [
        "for _, preset in ThemePresets do",
        "\tfor _, group in preset do",
        '\t\tif type(group) == "table" then',
        "\t\t\ttable.freeze(group)",
        "\t\tend",
        "\tend",
        "\ttable.freeze(preset)",
        "end",
        "",
        "return table.freeze(ThemePresets)",
        "",
    ]
    return "\n".join(out)


def main() -> int:
    check_only = "--check" in sys.argv
    themes = load_themes()
    errors = [e for key, t in themes.items() for e in validate(key, t)]
    if errors:
        print("theme validation failed:")
        for e in errors:
            print(f"  ✗ {e}")
        return 1
    content = generate(themes)
    if check_only:
        current = open(OUT, encoding="utf-8").read() if os.path.isfile(OUT) else ""
        if current != content:
            print("ThemePresets.luau is out of date — run: python3 tools/build_themes.py")
            return 1
        print(f"themes ok: {', '.join(themes)}")
        return 0
    with open(OUT, "w", encoding="utf-8") as fh:
        fh.write(content)
    for key, t in themes.items():
        c = t["colors"]
        print(f"  {key:<9} text/surface {contrast(c['Text'], c['Surface']):5.2f}  onAccent/accent {contrast(c['OnAccent'], c['Accent']):5.2f}")
    print(f"wrote {os.path.relpath(OUT, ROOT)} ({len(themes)} presets)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
