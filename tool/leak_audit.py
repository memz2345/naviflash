# -*- coding: utf-8 -*-
# Heuristic leak/perf audit for the navi Flutter project.
# Scans all lib/**/*.dart for disposable resources that are never released,
# addListener without removeListener, and setState-after-await without mounted check.
import os, re, json, sys

LIB = r"F:\naviv2\navi\lib"

DISPOSABLE_TYPES = [
    "AnimationController", "TextEditingController", "ScrollController",
    "FocusNode", "PageController", "TabController", "VideoController",
    "Player", "WebViewController", "ValueNotifier", "ChangeNotifier",
    "ScreenshotController", "MobileScannerController", "TransformationController",
    "DraggableScrollableController", "SearchController", "StreamSubscription",
    "Timer", "WebviewController", "FixedExtentScrollController",
    "ScrollableController", "OverlayPortalController",
]
ctor_alt = "|".join(DISPOSABLE_TYPES)

# name = SomeDisposable(   /   name = Timer.periodic(
re_ctor = re.compile(r'(?<![\w.])(\w+)\s*=\s*(?:new\s+)?(' + ctor_alt + r')\s*[<(]')
re_timer_periodic = re.compile(r'(?<![\w.])(\w+)\s*=\s*Timer\.periodic\s*\(')
# name = something.listen(
re_listen = re.compile(r'(?<![\w.])(\w+)\s*=\s*[^\n;=]*?\.listen\s*\(')
# bare .listen( not assigned -> cannot cancel
re_bare_listen = re.compile(r'(?<![\w=)])\s([\w.\[\]]+)\.listen\s*\(')
# X.addListener(
re_add_listener = re.compile(r'(?<![\w.])([\w.\[\]]+)\.addListener\s*\(')
re_set_state = re.compile(r'\bsetState\s*\(')
re_await = re.compile(r'\bawait\b')
re_mounted = re.compile(r'\bmounted\b')
re_dispose_method = re.compile(r'void\s+dispose\s*\(\s*\)')
re_extends_state = re.compile(r'extends\s+State\s*<')

results = []

for root, dirs, files in os.walk(LIB):
    for f in files:
        if not f.endswith(".dart"):
            continue
        path = os.path.join(root, f)
        try:
            with open(path, "r", encoding="utf-8") as fh:
                src = fh.read()
        except Exception:
            continue
        lines = src.split("\n")
        rel = os.path.relpath(path, LIB)
        file_issues = []

        candidates = {}  # name -> (kind, line_no)
        for m in re_ctor.finditer(src):
            name, typ = m.group(1), m.group(2)
            ln = src.count("\n", 0, m.start()) + 1
            candidates.setdefault(name, (typ, ln))
        for m in re_timer_periodic.finditer(src):
            name = m.group(1)
            ln = src.count("\n", 0, m.start()) + 1
            candidates.setdefault(name, ("Timer.periodic", ln))
        for m in re_listen.finditer(src):
            name = m.group(1)
            ln = src.count("\n", 0, m.start()) + 1
            candidates.setdefault(name, ("StreamSubscription", ln))

        for name, (typ, ln) in sorted(candidates.items(), key=lambda kv: kv[1][1]):
            if name in ("state", "widget"):
                continue
            released = (
                re.search(r'(?<![\w.])' + re.escape(name) + r'\s*\?\?\s*[\s\S]{0,40}\.dispose\s*\(', src) or
                re.search(r'(?<![\w.])' + re.escape(name) + r'\??\.dispose\s*\(', src) or
                re.search(r'(?<![\w.])' + re.escape(name) + r'\??\.cancel\s*\(', src) or
                re.search(r'(?<![\w.])' + re.escape(name) + r'\??\.close\s*\(', src)
            )
            if not released:
                file_issues.append({"kind": "unreleased:" + typ, "name": name, "line": ln})

        # addListener without removeListener on same target
        listeners = {}
        for m in re_add_listener.finditer(src):
            target = m.group(1)
            ln = src.count("\n", 0, m.start()) + 1
            if target.endswith("this") or target == "widget":
                continue
            listeners.setdefault(target, ln)
        for target, ln in sorted(listeners.items(), key=lambda kv: kv[1]):
            if not re.search(re.escape(target) + r'\??\.removeListener\s*\(', src):
                file_issues.append({"kind": "listener-no-remove", "name": target, "line": ln})

        # setState after await without mounted guard (same function, rough window)
        for m in re_set_state.finditer(src):
            start = m.start()
            window = src[max(0, start - 600):start]
            if re_await.search(window) and not re_mounted.search(window):
                ln = src.count("\n", 0, start) + 1
                file_issues.append({"kind": "setState-after-await-no-mounted", "name": "setState", "line": ln})

        # State class with controllers but no dispose() at all
        if re_extends_state.search(src) and not re_dispose_method.search(src):
            n_ctrl = len(candidates)
            if n_ctrl > 0:
                file_issues.append({"kind": "state-no-dispose-method", "name": "%d resources" % n_ctrl, "line": 0})

        # bare listen (fire & forget, cannot cancel)
        for m in re_bare_listen.finditer(src):
            target = m.group(1)
            if target in ("stream",):
                pass
            ln = src.count("\n", 0, m.start()) + 1
            # only flag if it looks like a long-lived object (contains .instance or Service or controller)
            if re.search(r'(instance|Service|service|controller|player|Player|notifier|Notifier|hive|box)', target):
                file_issues.append({"kind": "bare-listen-longlived", "name": target + ".listen", "line": ln})

        if file_issues:
            results.append({"file": rel, "issues": file_issues})

json_out = json.dumps(results, ensure_ascii=False, indent=1)
with open(r"F:\naviv2\navi\tool\leak_audit_report.json", "w", encoding="utf-8") as fh:
    fh.write(json_out)

total = sum(len(r["issues"]) for r in results)
print("files with issues:", len(results), " total issues:", total)
for r in sorted(results, key=lambda r: -len(r["issues"]))[:40]:
    print("%4d  %s" % (len(r["issues"]), r["file"]))
    for i in r["issues"][:12]:
        print("       L%-5d %-32s %s" % (i["line"], i["kind"], i["name"]))
    if len(r["issues"]) > 12:
        print("       ... +%d more" % (len(r["issues"]) - 12))
