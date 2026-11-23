#!/usr/bin/env python3
"""
cluau-style-tile: render UI theme presets as an HTML style tile — what designers show BEFORE building screens.

    python3 style_tile.py                       # all presets → style-tiles.html
    python3 style_tile.py meadow candy -o tiles.html
    python3 style_tile.py path/to/custom-theme.json

Shows, per theme: mood line, palette roles with WCAG contrast, type specimen, buttons in the theme's shape
language (chunky / raised / flat / outline / text), currency pill, progress bar, item cards by rarity, a toast,
and a 16:9 HUD + shop mock. Fonts load from Google Fonts (the Roblox families are Google fonts; Builder Sans is
approximated with Inter). Pass --fontsource DIR to use local @fontsource packages instead (offline).

Open the HTML in a browser, pick/adjust a direction with the user, then generate Luau with
tools/build_themes.py (presets) or copy the tokens into Theme.luau.
"""
from __future__ import annotations

import argparse
import html
import json
import os
import sys

SKILL = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
THEMES_DIR = os.path.join(SKILL, "assets", "themes")

# Roblox family → (web family name, @fontsource package)
WEB_FONTS = {
    "FredokaOne": ("Fredoka One", "fredoka-one"), "LuckiestGuy": ("Luckiest Guy", "luckiest-guy"),
    "Michroma": ("Michroma", "michroma"), "TitilliumWeb": ("Titillium Web", "titillium-web"),
    "Merriweather": ("Merriweather", "merriweather"), "SpecialElite": ("Special Elite", "special-elite"),
    "Oswald": ("Oswald", "oswald"), "Montserrat": ("Montserrat", "montserrat"), "Nunito": ("Nunito", "nunito"),
    "RobotoMono": ("Roboto Mono", "roboto-mono"), "BuilderSans": ("Inter", None),
}
WEIGHT_NUM = {"Thin": 100, "ExtraLight": 200, "Light": 300, "Regular": 400, "Medium": 500, "SemiBold": 600,
              "Bold": 700, "ExtraBold": 800, "Heavy": 900}


def lum(h: str) -> float:
    def ch(c: int) -> float:
        v = c / 255
        return v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
    r, g, b = (int(h[i:i + 2], 16) for i in (1, 3, 5))
    return 0.2126 * ch(r) + 0.7152 * ch(g) + 0.0722 * ch(b)


def contrast(a: str, b: str) -> float:
    x, y = sorted((lum(a), lum(b)), reverse=True)
    return (x + 0.05) / (y + 0.05)


def rgba(h: str, a: float) -> str:
    r, g, b = (int(h[i:i + 2], 16) for i in (1, 3, 5))
    return f"rgba({r},{g},{b},{a})"


def load(arg: str) -> tuple[str, dict]:
    path = arg if arg.endswith(".json") else os.path.join(THEMES_DIR, f"{arg}.json")
    with open(path, encoding="utf-8") as fh:
        return os.path.splitext(os.path.basename(path))[0], json.load(fh)


def font_css(family: str, weight: str) -> str:
    web = WEB_FONTS.get(family, (family, None))[0]
    return f"font-family:'{web}',Inter,system-ui,sans-serif;font-weight:{WEIGHT_NUM.get(weight, 400)};"


def font_links(themes: list[dict], fontsource: str | None) -> str:
    needed: dict[str, set[int]] = {}
    for t in themes:
        for family, weight in t["fonts"].values():
            needed.setdefault(family, set()).add(WEIGHT_NUM.get(weight, 400))
    links = []
    if fontsource:
        for family, weights in needed.items():
            pkg = WEB_FONTS.get(family, (None, None))[1]
            if not pkg:
                continue
            for w in sorted(weights):
                path = os.path.join(fontsource, "@fontsource", pkg, f"{w}.css")
                if not os.path.isfile(path):
                    path = os.path.join(fontsource, "@fontsource", pkg, "index.css")
                links.append(f'<link rel="stylesheet" href="file://{path}">')
    else:
        fams = []
        for family, weights in needed.items():
            web, pkg = WEB_FONTS.get(family, (family, None))
            if pkg:
                fams.append(f"family={web.replace(' ', '+')}:wght@{';'.join(str(w) for w in sorted(weights))}")
        if fams:
            links.append(f'<link rel="stylesheet" href="https://fonts.googleapis.com/css2?{"&".join(fams)}&display=swap">')
    return "\n".join(links)


def button_css(t: dict, variant: str) -> str:
    c, s = t["colors"], t["shape"]
    style = s["buttonStyle"]
    if variant == "disabled":
        # Disabled goes neutral (never "faded accent"): sunken surface, muted text, no depth, no gloss.
        family, weight = t["fonts"]["bodyBold"]
        return (f"{font_css(family, weight)}border-radius:{s['radiusMD']}px;padding:0 22px;height:52px;display:inline-flex;"
                f"align-items:center;justify-content:center;font-size:17px;background:{c['SurfaceSunken']};color:{c['TextMuted']};"
                f"border:1px dashed {c['Border']};" + ("text-transform:uppercase;letter-spacing:1.5px;" if style in ("flat", "outline") else ""))
    bg, fg, edge = (c["Accent"], c["OnAccent"], c["AccentShadow"]) if variant == "primary" else (c["SurfaceRaised"], c["Text"], c["BorderStrong"])
    radius = s["radiusMD"]
    disp_family, disp_weight = t["fonts"]["bodyBold"] if style in ("raised", "outline", "text") else t["fonts"]["display"]
    base = f"{font_css(disp_family, disp_weight)}border-radius:{radius}px;padding:0 22px;height:52px;display:inline-flex;align-items:center;justify-content:center;font-size:19px;cursor:pointer;"
    if style == "chunky":
        outline = c["BorderStrong"]
        # Drop shadow on text only when light text sits on a colored face; on light faces it just smudges.
        text_shadow = f"text-shadow:0 2px 0 {rgba(edge, 0.55)};" if lum(fg) > 0.5 else ""
        gloss = f"background-image:linear-gradient(180deg,{rgba('#FFFFFF', 0.22)} 0%,{rgba('#FFFFFF', 0.0)} 48%);" if s["gloss"] else ""
        return (base + f"background-color:{bg};color:{fg};border:{s['strokeBold']}px solid {outline};"
                f"box-shadow:0 {s['shadowOffset']}px 0 {edge};{gloss}{text_shadow}letter-spacing:.3px;")
    if style == "raised":
        return base + f"background:{bg};color:{fg};border:1px solid {edge};box-shadow:0 3px 10px {rgba('#000000', 0.35)};"
    if style == "flat":
        return base + f"background:{bg};color:{fg};border:none;text-transform:uppercase;letter-spacing:1.2px;font-size:17px;"
    if style == "outline":
        color = c["Accent"] if variant == "primary" else c["Text"]
        fill = rgba(c["Accent"], 0.10) if variant == "primary" else "transparent"
        return base + f"background:{fill};color:{color};border:1px solid {color};text-transform:uppercase;letter-spacing:1.5px;font-size:15px;"
    # text
    color = c["Text"] if variant == "primary" else c["TextMuted"]
    underline = c["Accent"] if variant == "primary" else c["BorderStrong"]
    return base + f"background:none;color:{color};border:none;border-bottom:2px solid {underline};border-radius:0;padding:0 4px;"


def panel_css(t: dict) -> str:
    c, s = t["colors"], t["shape"]
    shadow = {"hard": f"box-shadow:0 {s['shadowOffset']}px 0 {c['BorderStrong']};", "soft": f"box-shadow:0 10px 30px {rgba('#000000', 0.35)};", "none": ""}[s["shadow"]]
    border = f"border:{s['strokeBold'] if s['buttonStyle'] == 'chunky' else s['strokeThin']}px solid {c['BorderStrong'] if s['buttonStyle'] == 'chunky' else c['Border']};"
    if s["buttonStyle"] == "text":
        return f"background:{rgba(c['Surface'], 0.0)};border:none;"
    return f"background:{c['Surface']};border-radius:{s['radiusMD']}px;{border}{shadow}"


def tile(key: str, t: dict) -> str:
    c, s, f = t["colors"], t["shape"], t["fonts"]
    e = html.escape
    ink = c.get("TextOnBackground", c["Text"])  # text drawn directly on the background/world
    ink_muted = c["TextMuted"] if contrast(c["TextMuted"], c["Background"]) >= 3 else rgba(ink, 0.72)
    disp = font_css(*f["display"])
    head = font_css(*f["heading"])
    body = font_css(*f["body"])
    bold = font_css(*f["bodyBold"])
    nums = font_css(*f["numbers"])
    roles = ["Background", "Surface", "SurfaceRaised", "Border", "Text", "TextMuted", "Accent", "AccentShadow", "Success", "Warning", "Danger", "Currency"]
    swatches = "".join(
        f'<div class="sw"><div class="chip" style="background:{c[r]};border:1px solid {rgba(c["Text"], 0.15)}"></div>'
        f'<div class="lbl" style="{body}color:{ink_muted}">{r}<br><b style="color:{ink}">{c[r]}</b></div></div>' for r in roles)
    checks = [("Text / Surface", contrast(c["Text"], c["Surface"]), 4.5), ("Muted / Surface", contrast(c["TextMuted"], c["Surface"]), 3.0), ("OnAccent / Accent", contrast(c["OnAccent"], c["Accent"]), 4.5)]
    check_html = " · ".join(f'{n} <b style="color:{c["Success"] if v >= m else c["Danger"]}">{v:.1f}:1</b>' for n, v, m in checks)
    upper = "text-transform:uppercase;letter-spacing:1.5px;" if s["buttonStyle"] in ("flat", "outline") else ""
    rarity_cards = "".join(
        f'<div class="card" style="{panel_css(t)}background:{c["SurfaceRaised"]};">'
        f'<div class="art" style="background:{c["SurfaceSunken"]};border-radius:{s["radiusSM"]}px;border-bottom:4px solid {t["rarity"][r]}"><div class="gem" style="background:{t["rarity"][r]};border-radius:{max(2, s["radiusSM"])}px"></div></div>'
        f'<div style="{bold}color:{c["Text"]};font-size:16px;margin-top:8px">{n}</div>'
        f'<div style="{bold}color:{t["rarity"][r]};font-size:12px;letter-spacing:1.2px">{r.upper()}</div>'
        f'<div style="{nums}color:{c["Text"]};font-size:15px;margin-top:6px"><span style="color:{c["Currency"]}">●</span> {p}</div></div>'
        for r, n, p in [("Common", "Lantern Cap", "120"), ("Rare", "Ember Trail", "1,250"), ("Epic", "Comet Pet", "8,400"), ("Legendary", "Star Crown", "52,000")])
    gloss = f"background-image:linear-gradient(180deg,{rgba('#FFFFFF', 0.25)},{rgba('#FFFFFF', 0)} 60%);" if s["gloss"] else ""
    pill_border = f"border:{s['strokeBold']}px solid {c['BorderStrong']};" if s["buttonStyle"] == "chunky" else f"border:1px solid {c['Border']};"
    return f"""
<section class="tile" style="background:{c['Background']};color:{ink}">
  <header>
    <div style="{disp}font-size:44px;line-height:1;color:{ink};{upper}">{e(t['name'])}</div>
    <div style="{body}font-size:16px;color:{ink_muted};max-width:780px;margin-top:10px">{e(t['mood'])}</div>
    <div style="{bold}font-size:12px;color:{c['Accent'] if contrast(c['Accent'], c['Background']) >= 3 else ink};letter-spacing:1.4px;margin-top:10px">{e(' · '.join(t['genres']).upper())} &nbsp;—&nbsp; buttons: {s['buttonStyle']} · shadow: {s['shadow']} · motion: {t['motion']['personality']}</div>
  </header>
  <div class="row">
    <div class="col" style="flex:1.1">
      <div class="h" style="{head}color:{ink_muted}">Palette</div>
      <div class="swatches">{swatches}</div>
      <div style="{body}font-size:13px;color:{ink_muted};margin-top:10px">Contrast: {check_html}</div>
      <div class="h" style="{head}color:{ink_muted};margin-top:22px">Type</div>
      <div style="{disp}font-size:40px;line-height:1.05;color:{ink};{upper}">Round Won!</div>
      <div style="{head}font-size:24px;margin-top:6px;color:{ink}">Outfitter — gear for the deep caves</div>
      <div style="{body}font-size:17px;color:{ink};margin-top:6px;max-width:520px">Body copy is written in the game's voice: “Need 40 more coins” — never “Error: insufficient funds”.</div>
      <div style="{nums}font-size:28px;color:{c['Currency'] if contrast(c['Currency'], c['Background']) >= 3 else ink};margin-top:8px">12,480 &nbsp; 03:59</div>
    </div>
    <div class="col" style="flex:1">
      <div class="h" style="{head}color:{ink_muted}">Components</div>
      <div class="btns">
        <span style="{button_css(t, 'primary')}">Buy for 250</span>
        <span style="{button_css(t, 'secondary')}">Equip</span>
        <span style="{button_css(t, 'disabled')}">Need 40 more</span>
      </div>
      <div style="display:flex;gap:14px;align-items:center;margin-top:20px">
        <div style="display:inline-flex;align-items:center;gap:10px;height:44px;padding:0 16px 0 8px;border-radius:999px;background:{c['Surface']};{pill_border}">
          <span style="width:28px;height:28px;border-radius:50%;background:{c['Currency']};border:2px solid {c['AccentShadow']};{gloss}"></span>
          <span style="{nums}font-size:21px;color:{c['Text']}">12,480</span>
        </div>
        <div style="flex:1;height:18px;border-radius:999px;background:{c['SurfaceSunken']};{pill_border}overflow:hidden">
          <div style="width:64%;height:100%;background:{c['Success']};{gloss}"></div>
        </div>
      </div>
      <div style="margin-top:18px;display:flex;align-items:center;gap:12px;padding:12px 16px;{panel_css(t)}background:{c['SurfaceRaised']}">
        <span style="width:4px;height:22px;border-radius:2px;background:{c['Success']}"></span>
        <span style="{body}font-size:16px;color:{c['Text']}">Ember Trail unlocked</span>
      </div>
      <div class="cards">{rarity_cards}</div>
    </div>
  </div>
  <div class="h" style="{head}color:{ink_muted};margin-top:6px">HUD mock (16:9)</div>
  <div class="hud" style="background:linear-gradient(160deg,{c['SurfaceSunken']},{c['Background']});border-radius:{s['radiusMD']}px">
    <div style="position:absolute;top:14px;left:50%;transform:translateX(-50%);display:inline-flex;align-items:center;gap:8px;height:38px;padding:0 14px 0 6px;border-radius:999px;background:{c['Surface']};{pill_border}">
      <span style="width:24px;height:24px;border-radius:50%;background:{c['Currency']};{gloss}"></span><span style="{nums}font-size:18px;color:{c['Text']}">12,480</span></div>
    <div style="position:absolute;left:16px;top:50%;transform:translateY(-50%);display:flex;flex-direction:column;gap:10px">
      <span style="{button_css(t, 'secondary')}height:42px;font-size:15px;width:96px">Shop</span>
      <span style="{button_css(t, 'secondary')}height:42px;font-size:15px;width:96px">Pets</span>
      <span style="{button_css(t, 'secondary')}height:42px;font-size:15px;width:96px">Quests</span></div>
    <div style="position:absolute;left:50%;top:52%;transform:translate(-50%,-50%);width:430px;padding:18px;{panel_css(t)}">
      <div style="display:flex;justify-content:space-between;align-items:center">
        <div><div style="{head}font-size:24px;color:{c['Text']}">Outfitter</div><div style="{body}font-size:13px;color:{c['TextMuted']}">Restocks in 03:59</div></div>
        <span style="{button_css(t, 'secondary')}width:40px;height:40px;padding:0;font-size:16px">✕</span></div>
      <div style="display:flex;gap:10px;margin-top:14px">{''.join(f'<div style="flex:1;height:84px;border-radius:{s["radiusSM"]}px;background:{c["SurfaceSunken"]};border-bottom:4px solid {t["rarity"][r]}"></div>' for r in ['Common', 'Rare', 'Legendary'])}</div>
      <div style="margin-top:14px;text-align:right"><span style="{button_css(t, 'primary')}height:44px;font-size:17px">Buy for 250</span></div>
    </div>
  </div>
</section>"""


def page(themes: list[tuple[str, dict]], fontsource: str | None) -> str:
    tiles = "\n".join(tile(k, t) for k, t in themes)
    return f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>Cluau style tiles</title>
{font_links([t for _, t in themes], fontsource)}
<style>
body{{margin:0;background:#0d0d0d;font-family:Inter,system-ui,sans-serif}}
.tile{{width:1240px;margin:0 auto 28px;padding:34px 40px 40px;box-sizing:border-box}}
.row{{display:flex;gap:40px;margin-top:26px}}
.h{{font-size:12px;letter-spacing:2px;text-transform:uppercase;margin-bottom:12px}}
.swatches{{display:grid;grid-template-columns:repeat(4,1fr);gap:12px}}
.sw{{display:flex;gap:8px;align-items:center}} .chip{{width:38px;height:38px;border-radius:8px;flex:none}}
.lbl{{font-size:11px;line-height:1.35}}
.btns{{display:flex;gap:14px;flex-wrap:wrap}}
.cards{{display:grid;grid-template-columns:repeat(4,1fr);gap:12px;margin-top:18px}}
.card{{padding:10px}} .art{{height:70px;display:flex;align-items:center;justify-content:center}} .gem{{width:30px;height:30px;transform:rotate(45deg)}}
.hud{{position:relative;height:420px;margin-top:4px;overflow:hidden}}
</style></head><body>
{tiles}
</body></html>"""


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="cluau-style-tile", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("themes", nargs="*", help="preset names (assets/themes) or theme .json paths; default: all")
    parser.add_argument("-o", "--out", default="style-tiles.html")
    parser.add_argument("--fontsource", help="directory containing node_modules-style @fontsource packages (offline fonts)")
    args = parser.parse_args(argv)
    names = args.themes or sorted(os.path.splitext(f)[0] for f in os.listdir(THEMES_DIR) if f.endswith(".json"))
    themes = [load(n) for n in names]
    with open(args.out, "w", encoding="utf-8") as fh:
        fh.write(page(themes, args.fontsource))
    print(f"cluau-style-tile: {len(themes)} theme(s) → {args.out}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
