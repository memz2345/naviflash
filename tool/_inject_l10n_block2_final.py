# tool/_inject_l10n_block2_final.py
# 精确匹配补 key（修复子串误跳）。只补缺失的，已存在不动；尾逗号正确。
import io
import os
import re

ROOT = r'F:\f\naviflashv2\lib\l10n'

PAIRS = [
    ('comic', '漫画', 'Comics'),
    ('memberShop', '会员购小店', 'Member Shop'),
    ('audioZone', '音频区', 'Audio Zone'),
    ('opusTab', '图文', 'Opus'),
    ('matchInfo', '比赛详情', 'Match'),
    ('watchLive', '看直播', 'Watch Live'),
    ('interestStation', '兴趣小站', 'Interest Zone'),
    ('noteManage', '笔记管理', 'Notes'),
    ('noteUnpublished', '未发布笔记', 'Unpublished'),
    ('notePublished', '公开笔记', 'Published'),
    ('deleteSelected', '删除选中', 'Delete Selected'),
    ('confirmDeleteNote', '确定删除已选中的笔记吗？', 'Delete the selected notes?'),
    ('selectAll', '全选', 'Select All'),
    ('favTopic', '我的话题', 'My Topics'),
    ('cancelFavTopic', '确定取消收藏该话题？', 'Cancel following this topic?'),
    ('loadFailed', '加载失败', 'Failed to load'),
    ('inputIdTitle', '输入 ID', 'Enter ID'),
    ('inputIdHint', '请输入赛事或兴趣小站的 ID', 'Enter the match or tribe ID'),
    ('noContent', '暂无内容', 'No content'),
    ('bubbleAll', '全部', 'All'),
    ('cancel', '取消', 'Cancel'),
    ('deleted', '已删除', 'Deleted'),
    ('operationFailed', '操作失败', 'Operation failed'),
    ('confirm', '确定', 'Confirm'),
]


def is_en(name):
    return 'en' in name.lower()


def has(content, key):
    return re.search(r'"%s"\s*:' % re.escape(key), content) is not None


def inject(path):
    with io.open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    crlf = '\r\n' in content
    eol = '\r\n' if crlf else '\n'
    use_en = is_en(os.path.basename(path))
    add = []
    for key, zh, en in PAIRS:
        if has(content, key):
            continue
        add.append((key, en if use_en else zh))
    if not add:
        print('skip (none missing): ' + os.path.basename(path))
        return
    idx = content.rfind('}')
    if idx < 0:
        print('ERROR no }: ' + os.path.basename(path))
        return
    lines = [',']
    for n, (k, v) in enumerate(add):
        comma = '' if n == len(add) - 1 else ','
        lines.append('  "%s": "%s"%s' % (k, v, comma))
    block = eol.join(lines) + eol
    new = content[:idx] + block + content[idx:]
    with io.open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(new)
    print('added %d: %s' % (len(add), os.path.basename(path)))


def main():
    for name in [
        'app_zh_CN.arb', 'app_zh.arb', 'app_zh_HK.arb', 'app_zh_TW.arb',
        'app_en.arb', 'app_en_US.arb',
    ]:
        inject(os.path.join(ROOT, name))


if __name__ == '__main__':
    main()
