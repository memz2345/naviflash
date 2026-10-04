// Helper: fetch files from the PiliPlus repo (for feature comparison only).
// Usage:
//   node tool/pp_fetch.mjs lib/pages/home/view.dart
//   node tool/pp_fetch.mjs lib/pages/home/view.dart --out .workbuddy/pp/home_view.dart
//   node tool/pp_fetch.mjs --list lib/pages/member
//   node tool/pp_fetch.mjs --grep "sponsor" lib/pages
import fs from 'node:fs';
import path from 'node:path';

const REPO = 'bggRGjQaUbCoE/PiliPlus';
const BRANCH = 'main';
const TREE_CACHE = path.join(process.cwd(), '.workbuddy', 'pp_tree_cache.json');

async function getTree() {
  if (fs.existsSync(TREE_CACHE)) {
    const cached = JSON.parse(fs.readFileSync(TREE_CACHE, 'utf8'));
    if (Date.now() - cached.at < 1000 * 60 * 60 * 12) return cached.tree;
  }
  const res = await fetch(
    `https://api.github.com/repos/${REPO}/git/trees/${BRANCH}?recursive=1`,
    { headers: { 'User-Agent': 'naviflash-compare' } },
  );
  const data = await res.json();
  const tree = (data.tree || []).filter((t) => t.type === 'blob').map((t) => t.path);
  fs.mkdirSync(path.dirname(TREE_CACHE), { recursive: true });
  fs.writeFileSync(TREE_CACHE, JSON.stringify({ at: Date.now(), tree }));
  return tree;
}

async function fetchFile(p) {
  const url = `https://raw.githubusercontent.com/${REPO}/${BRANCH}/${p}`;
  const res = await fetch(url);
  if (!res.ok) throw new Error(`${res.status} ${p}`);
  return await res.text();
}

const argv = process.argv.slice(2);
const outIdx = argv.indexOf('--out');
const out = outIdx >= 0 ? argv[outIdx + 1] : null;
const listIdx = argv.indexOf('--list');
const grepIdx = argv.indexOf('--grep');

if (listIdx >= 0) {
  const prefix = argv[listIdx + 1];
  const tree = await getTree();
  console.log(tree.filter((t) => t.startsWith(prefix)).sort().join('\n'));
} else if (grepIdx >= 0) {
  const [pattern, prefix] = [argv[grepIdx + 1], argv[grepIdx + 2] || 'lib'];
  const tree = await getTree();
  const re = new RegExp(pattern, 'i');
  const files = tree.filter((t) => t.startsWith(prefix) && /\.(dart|json|yaml)$/.test(t));
  const hits = [];
  for (const f of files) {
    try {
      const text = await fetchFile(f);
      text.split('\n').forEach((line, i) => {
        if (re.test(line)) hits.push(`${f}:${i + 1}: ${line.trim()}`);
      });
    } catch { /* ignore */ }
  }
  console.log(hits.join('\n'));
} else {
  const target = argv.find((a) => !a.startsWith('--') && a !== out);
  const text = await fetchFile(target);
  if (out) {
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, text);
    console.log(`wrote ${out} (${text.split('\n').length} lines)`);
  } else {
    console.log(text);
  }
}
