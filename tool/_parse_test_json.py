#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""解析 `flutter test -r json` 的输出，汇总「总数 / 失败数 / 失败清单」。

用途：本项目的门槛是「**不新增失败** + `flutter analyze` 0 error」，
所以每次改完都要跟基线逐条对名单，而不是只看总数。

用法：
    # 1) 跑测试并落盘（注意清代理，否则 flutter_tester 起不来）
    env -u http_proxy -u https_proxy -u HTTP_PROXY -u HTTPS_PROXY \
        -u all_proxy -u ALL_PROXY -u NO_PROXY -u no_proxy \
        "PROGRAMFILES(X86)=C:\\Program Files (x86)" \
        flutter test -r json > build/_verify/test_full.json 2>&1

    # 2) 看名单
    python tool/_parse_test_json.py build/_verify/test_full.json

    # 3) 跟上次/基线对比（只报新增与消失）
    python tool/_parse_test_json.py build/_verify/test_full.json --baseline baseline.json

输出里的 `suite` 是相对路径，方便直接复制去跑单文件：
    flutter test test/xxx_test.dart
"""
import argparse
import collections
import json
import os
import sys


def load(path):
    """返回 (total, suites: {id: relpath}, failures: [(relpath, name)])。"""
    suites = {}
    tests = {}
    done = []
    total_lines = 0
    with open(path, encoding='utf-8', errors='replace') as f:
        for line in f:
            line = line.strip()
            if not line.startswith('{'):
                continue
            total_lines += 1
            try:
                o = json.loads(line)
            except ValueError:
                continue
            kind = o.get('type')
            if kind == 'suite':
                s = o['suite']
                suites[s['id']] = s.get('path') or '?'
            elif kind == 'testStart':
                t = o['test']
                tests[t['id']] = (t.get('suiteID'), t.get('name', '?'))
            elif kind == 'testDone':
                done.append(o)

    failures = []
    skipped = 0
    for d in done:
        if d.get('skipped'):
            skipped += 1
            continue
        if d.get('result') == 'success':
            continue
        suite_id, name = tests.get(d['testID'], (None, '?'))
        # "loading <file>" 是每个 suite 的伪用例，不算真失败
        if name.startswith('loading '):
            continue
        failures.append((suites.get(suite_id, '?'), name))

    return len(tests), suites, failures, skipped


def rel(p):
    """尽量把绝对路径转成相对仓库根的路径。"""
    p = p.replace('\\', '/')
    for anchor in ('/test/', '/lib/'):
        if anchor in p:
            return p[p.index(anchor) + 1:]
    return p


def key(item):
    return (rel(item[0]), item[1])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('json', help='flutter test -r json 的输出文件')
    ap.add_argument('--baseline', help='基线 json；给了就只对比新增/消失')
    args = ap.parse_args()

    if not os.path.exists(args.json):
        sys.exit('找不到 %s' % args.json)

    total, _suites, failures, skipped = load(args.json)
    cur = {key(x) for x in failures}

    if args.baseline:
        if not os.path.exists(args.baseline):
            sys.exit('找不到基线 %s' % args.baseline)
        _t2, _s2, base_fail, _sk2 = load(args.baseline)
        base = {key(x) for x in base_fail}
        added = sorted(cur - base)
        gone = sorted(base - cur)
        print('当前失败 %d 项，基线 %d 项' % (len(cur), len(base)))
        print('新增 %d 项：' % len(added))
        for sp, nm in added:
            print('  + %s :: %s' % (sp, nm))
        print('消失 %d 项：' % len(gone))
        for sp, nm in gone:
            print('  - %s :: %s' % (sp, nm))
        print('=> ' + ('无新增失败，通过门槛' if not added else '有新增失败！'))
        return 0 if not added else 1

    print('TOTAL=%d SKIPPED=%d FAILED=%d' % (total, skipped, len(cur)))
    print('---')
    for sp, nm in sorted(cur):
        print('%s :: %s' % (sp, nm))
    return 0


if __name__ == '__main__':
    sys.exit(main())
