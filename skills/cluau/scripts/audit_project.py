#!/usr/bin/env python3
"""
cluau-audit: a studio-style review map of a Roblox codebase (Rojo src/ or exported scripts).

    python3 audit_project.py SRC_DIR [--json] [--out report.md]

Produces, in one report:
  1. Remote inventory   — every OnServerEvent/OnServerInvoke handler with: validated? rate-limited?
                           yields inside? (heuristic, per handler body)
  2. Placement problems — client APIs in server scripts and vice versa, DataStores outside the server,
                           server-only containers referenced from client code.
  3. Persistence map    — DataStores/OrderedDataStores/MemoryStores used, write styles, BindToClose,
                           ProcessReceipt locations.
  4. Lint summary       — cluau-lint findings grouped by rule.
It never modifies files. Heuristics are conservative: treat findings as review sites, not verdicts.
"""
from __future__ import annotations

import argparse
import json
import os
import re
import sys
from collections import Counter, defaultdict

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import luau_lint  # noqa: E402

HANDLER = re.compile(r"([\w.:\"()\[\]]+?)\s*\.\s*(OnServerEvent\s*:\s*Connect|OnServerInvoke\s*=)")
HANDLER_VAR = re.compile(r"([A-Za-z_]\w*)\s*\.\s*(?:OnServerEvent|OnServerInvoke)\b")
REMOTE_NAME = re.compile(r"""(?:event|func|unreliable|WaitForChild|FindFirstChild)\s*\(\s*["']([\w]+)["']""")
VALIDATION = re.compile(r"\btypeof\s*\(|\btype\s*\(|\bGuard\.|\bsanitize\w*\s*\(|\bvalidate\w*\s*\(|\bt\.\w+\s*\(")
RATE_LIMIT = re.compile(r":\s*check\s*\(|[Ll]imiter|[Cc]ooldown|[Dd]ebounce|lastRequest|os\.clock\(\)\s*-")
YIELD = re.compile(r"\btask\.wait\s*\(|\w+Async\s*\(|:\s*InvokeServer\s*\(|:\s*Wait\s*\(")

CLIENT_ONLY = re.compile(r"\bLocalPlayer\b|\bOnClientEvent\b|\bFireServer\s*\(|\bInvokeServer\s*\(|\bCurrentCamera\b|\bRenderStepped\b|\bUserInputService\b|\bPlayerGui\b")
SERVER_ONLY = re.compile(r"\bOnServerEvent\b|\bOnServerInvoke\b|\bFireClient\s*\(|\bFireAllClients\s*\(|\bDataStoreService\b|\bServerStorage\b|\bServerScriptService\b|\bMessagingService\b|\bMemoryStoreService\b|\bProcessReceipt\b|\bBanAsync\b|\bHttpService\s*:\s*GetSecret")
STORE = re.compile(r":\s*(GetDataStore|GetOrderedDataStore|GetSortedMap|GetQueue|GetHashMap)\s*\(\s*[\"']?([^\"')]*)")
WRITE = re.compile(r":\s*(SetAsync|UpdateAsync|IncrementAsync|RemoveAsync)\s*\(")


def classify(path: str, code: str) -> str:
    """server | client | module (by Rojo naming first, then folder names)."""
    lower = path.replace("\\", "/").lower()
    if lower.endswith((".server.luau", ".server.lua")):
        return "server"
    if lower.endswith((".client.luau", ".client.lua")):
        return "client"
    parts = set(lower.split("/"))
    if parts & {"server", "serverscriptservice", "serverstorage", "services"}:
        return "server-module"
    if parts & {"client", "starterplayerscripts", "startercharacterscripts", "startergui", "controllers"}:
        return "client-module"
    return "module"


def takes_no_args(body: str) -> bool:
    """True when the handler's only parameter is the player (nothing client-controlled to validate)."""
    m = re.search(r"function\s*\w*\s*\(([^)]*)\)", body)
    if not m:
        return False
    params = [p for p in m.group(1).split(",") if p.strip()]
    return len(params) <= 1


def handler_body(lines: list[str], start: int) -> str:
    """Lines belonging to a handler that starts at `start` (0-based), by indentation."""
    indent = len(lines[start]) - len(lines[start].lstrip())
    body = [lines[start]]
    for line in lines[start + 1:]:
        stripped = line.strip()
        if not stripped:
            body.append(line)
            continue
        current = len(line) - len(line.lstrip())
        if current <= indent:
            if stripped.startswith("end"):
                body.append(line)
            break
        body.append(line)
    return "\n".join(body)


def audit(root: str) -> dict:
    remotes, placement, stores = [], [], []
    receipts, bind_to_close, lint_counts = [], [], Counter()
    write_styles: dict[str, Counter] = defaultdict(Counter)
    files = list(luau_lint.iter_files([root]))
    for path in files:
        with open(path, encoding="utf-8", errors="replace") as fh:
            src = fh.read()
        code = luau_lint.build_views(src)[0]
        strings_view = luau_lint.build_views(src)[1]
        rel = os.path.relpath(path, root)
        kind = classify(rel, code)
        code_lines = code.splitlines()
        str_lines = strings_view.splitlines()

        for i, line in enumerate(code_lines):
            if HANDLER.search(line):
                body = handler_body(code_lines, i)
                # `OnServerEvent:Connect(onBuy)` / `OnServerInvoke = onGet` → analyze the named function instead.
                named = re.search(r"(?:Connect\s*\(\s*|OnServerInvoke\s*=\s*)([A-Za-z_]\w*)\s*\)?\s*$", line.strip())
                if named and named.group(1) != "function":
                    fn_line = next((j for j, l in enumerate(code_lines)
                                    if re.match(r"\s*(?:local\s+)?function\s+" + re.escape(named.group(1)) + r"\s*\(", l)), None)
                    if fn_line is not None:
                        body = handler_body(code_lines, fn_line)
                names = REMOTE_NAME.findall(str_lines[i]) if i < len(str_lines) else []
                if not names:
                    # `local buy = ...:WaitForChild("BuyItem")` … `buy.OnServerEvent` → resolve the variable.
                    var = HANDLER_VAR.search(line)
                    if var:
                        decl = re.search(r"local\s+" + re.escape(var.group(1)) + r"\b[^\n]*", strings_view)
                        names = REMOTE_NAME.findall(decl.group(0)) if decl else []
                remotes.append({
                    "file": rel, "line": i + 1,
                    "remote": names[-1] if names else "?",
                    "validated": "n/a" if takes_no_args(body) else bool(VALIDATION.search(body)),
                    "rate_limited": bool(RATE_LIMIT.search(body)),
                    "yields": bool(YIELD.search(body)),
                })

        if kind.startswith("server"):
            for m in CLIENT_ONLY.finditer(code):
                placement.append({"file": rel, "line": code.count("\n", 0, m.start()) + 1,
                                  "problem": f"client-only API `{m.group(0).strip()}` in server code ({kind})"})
        if kind.startswith("client"):
            for m in SERVER_ONLY.finditer(code):
                placement.append({"file": rel, "line": code.count("\n", 0, m.start()) + 1,
                                  "problem": f"server-only API `{m.group(0).strip()}` in client code ({kind}) — clients can read this code and the call fails/leaks"})

        for m in STORE.finditer(strings_view):
            stores.append({"file": rel, "line": strings_view.count("\n", 0, m.start()) + 1, "api": m.group(1), "name": m.group(2).strip() or "?"})
        for m in WRITE.finditer(code):
            write_styles[rel][m.group(1)] += 1
        if re.search(r"\bProcessReceipt\s*=", code):
            receipts.append(rel)
        if "BindToClose" in code:
            bind_to_close.append(rel)
        for f in luau_lint.lint_source(src, rel, require_strict=False):
            lint_counts[f"{f.rule} ({f.severity})"] += 1

    return {
        "root": root, "files": len(files), "remotes": remotes, "placement": placement, "stores": stores,
        "writes": {k: dict(v) for k, v in write_styles.items()}, "process_receipt": receipts,
        "bind_to_close": bind_to_close, "lint": dict(lint_counts.most_common()),
    }


def to_markdown(report: dict) -> str:
    yes = lambda b: b if isinstance(b, str) else ("✅" if b else "❌")  # noqa: E731
    out = [f"# cluau audit — {report['root']}", "", f"Scanned {report['files']} Luau file(s). Heuristic map — every ❌ is a review site.", ""]
    out += ["## 1. Remote handlers", ""]
    if report["remotes"]:
        out += ["| Remote | Location | Validated | Rate-limited | No yield inside |", "|---|---|---|---|---|"]
        for r in report["remotes"]:
            out.append(f"| `{r['remote']}` | `{r['file']}:{r['line']}` | {yes(r['validated'])} | {yes(r['rate_limited'])} | {yes(not r['yields'])} |")
        out += ["", "A yield inside a handler is only a bug if it sits between a check and the state change it guards (sharp-edges CX-02)."]
    else:
        out.append("No server remote handlers found.")
    out += ["", "## 2. Placement problems", ""]
    out += [f"- `{p['file']}:{p['line']}` — {p['problem']}" for p in report["placement"]] or ["None found."]
    out += ["", "## 3. Persistence", ""]
    out += [f"- `{s['file']}:{s['line']}` — `{s['api']}(\"{s['name']}\")`" for s in report["stores"]] or ["No DataStore/MemoryStore usage."]
    for path, counts in report["writes"].items():
        out.append(f"- writes in `{path}`: " + ", ".join(f"{k}×{v}" for k, v in sorted(counts.items())))
    out.append(f"- `ProcessReceipt` assigned in: {', '.join(f'`{p}`' for p in report['process_receipt']) or 'nowhere'}"
               + (" ⚠️ more than once — only one handler may exist" if len(report["process_receipt"]) > 1 else ""))
    out.append(f"- `BindToClose` in: {', '.join(f'`{p}`' for p in report['bind_to_close']) or 'nowhere ⚠️'}")
    out += ["", "## 4. Lint summary", ""]
    out += [f"- {rule}: {count}" for rule, count in report["lint"].items()] or ["Clean."]
    return "\n".join(out) + "\n"


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="cluau-audit", description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("root")
    parser.add_argument("--json", action="store_true")
    parser.add_argument("--out", help="write the markdown report to this file")
    args = parser.parse_args(argv)
    report = audit(args.root)
    if args.json:
        print(json.dumps(report, indent=2, ensure_ascii=False))
        return 0
    md = to_markdown(report)
    if args.out:
        with open(args.out, "w", encoding="utf-8") as fh:
            fh.write(md)
        print(f"cluau-audit: report written to {args.out}", file=sys.stderr)
    else:
        print(md)
    return 0


if __name__ == "__main__":
    sys.exit(main())
