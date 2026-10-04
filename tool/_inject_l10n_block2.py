# tool/_inject_l10n_block2.py
# 给 6 个 arb 注入块 2 / 块 5 新增文案 key（去重，保留 CRLF）。
import os

ROOT = r'F:\f\naviflashv2\lib\l10n'

# (key) -> (zh, en)
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


def inject(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    eol = '\r\n' if '\r\n' in content else '\n'
    base = os.path.basename(path)
    use_en = is_en(base)
    added = []
    for key, zh, en in PAIRS:
        if key in content:
            continue
        val = en if use_en else zh
        added.append(f'  "{key}": "{val}"')
    if not added:
        print(f'skip (all present): {base}')
        return
    # 在最后一个 } 之前插入
    idx = content.rfind('}')
    if idx < 0:
        print('ERROR no }: ' + base)
        return
    insert = ',' + eol + eol.join(added) + eol
    new = content[:idx] + insert + content[idx:]
    with open(path, 'w', encoding='utf-8', newline='') as f:
        f.write(new)
    print(f'added {len(added)} keys: {base}')


def main():
    for name in [
        'app_zh_CN.arb', 'app_zh.arb', 'app_zh_HK.arb', 'app_zh_TW.arb',
        'app_en.arb', 'app_en_US.arb',
    ]:
        inject(os.path.join(ROOT, name))


if __name__ == '__main__':
    main()
