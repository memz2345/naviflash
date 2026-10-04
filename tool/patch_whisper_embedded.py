# tool/patch_whisper_embedded.py
#
# 一次性补丁：私信会话列表改为「嵌入消息中心」的非滚动 Column
# （父级 ListView 负责滚动 / 下拉刷新，翻页改为「加载更多」按钮）。
# 用法：python tool/patch_whisper_embedded.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = "lib/widgets/msg_views.dart"

OLD_HEAD = """class WhisperSessionListView extends StatefulWidget {
  const WhisperSessionListView({super.key});

  @override
  State<WhisperSessionListView> createState() => _WhisperSessionListViewState();
}

class _WhisperSessionListViewState extends State<WhisperSessionListView>
    with AutomaticKeepAliveClientMixin {
  final List<BiliImSession> _sessions = [];
  final ScrollController _scroll = ScrollController();
  int? _offset;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 320) _loadMore();
  }
"""

NEW_HEAD = """class WhisperSessionListView extends StatefulWidget {
  /// 外部刷新信号：消息中心下拉刷新时 +1，这里重新拉第一页。
  final ValueNotifier<int>? reloadTick;

  const WhisperSessionListView({super.key, this.reloadTick});

  @override
  State<WhisperSessionListView> createState() => _WhisperSessionListViewState();
}

/// 嵌入消息中心的会话列表：自身不滚动（由外层 ListView 滚动），
/// 翻页用底部「加载更多」按钮。
class _WhisperSessionListViewState extends State<WhisperSessionListView> {
  final List<BiliImSession> _sessions = [];
  int? _offset;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.reloadTick?.addListener(_onReloadTick);
    _load();
  }

  @override
  void dispose() {
    widget.reloadTick?.removeListener(_onReloadTick);
    super.dispose();
  }

  void _onReloadTick() {
    if (mounted) _load();
  }
"""

OLD_BODY = """  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    if (!BilibiliImService.canUse && _sessions.isEmpty && !_loading) {
      return MsgLoginPrompt(
        icon: Icons.mail_outline,
        title: AppLocalizations.of(context).msgLoginPromptWhisper,
      );
    }
    if (_loading) return const Center(child: LoadingIndicatorM3E());
    if (_error != null && _sessions.isEmpty) {
      return Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: LoadRetryPill(onRetry: _load),
          ),
        ],
      );
    }
    if (_sessions.isEmpty) {
      return MsgEmptyView(
        icon: Icons.mail_outline,
        title: AppLocalizations.of(context).msgWhisperEmpty,
        subtitle: AppLocalizations.of(context).msgWhisperEmptySubtitle,
      );
    }
    return AppRefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        controller: _scroll,
        physics: const AppRefreshScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
        itemCount: _sessions.length + 1,
        itemBuilder: (context, index) {
          if (index >= _sessions.length) {
            if (_loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            }
            return const SizedBox(height: 8);
          }
          final session = _sessions[index];
          return GestureDetector(
            onSecondaryTap: () => _showActions(session),
            child: msgGlassCard(
              margin: kMsgCardMargin,
              child: _SessionTile(
                session: session,
                onTap: () => _openChat(session),
                onLongPress: () => _showActions(session),
              ),
            ),
          );
        },
      ),
    );
  }
}
"""

NEW_BODY = """  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (!BilibiliImService.canUse && _sessions.isEmpty && !_loading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: MsgLoginPrompt(
          icon: Icons.mail_outline,
          title: AppLocalizations.of(context).msgLoginPromptWhisper,
        ),
      );
    }
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: LoadingIndicatorM3E()),
      );
    }
    if (_error != null && _sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          children: [
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 12),
            LoadRetryPill(onRetry: _load),
          ],
        ),
      );
    }
    if (_sessions.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: MsgEmptyView(
          icon: Icons.mail_outline,
          title: AppLocalizations.of(context).msgWhisperEmpty,
          subtitle: AppLocalizations.of(context).msgWhisperEmptySubtitle,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final session in _sessions)
          GestureDetector(
            onSecondaryTap: () => _showActions(session),
            child: msgGlassCard(
              margin: kMsgCardMargin,
              child: _SessionTile(
                session: session,
                onTap: () => _openChat(session),
                onLongPress: () => _showActions(session),
              ),
            ),
          ),
        if (_hasMore)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
            child: OutlinedButton(
              onPressed: _loadingMore ? null : _loadMore,
              child: _loadingMore
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(AppLocalizations.of(context).msgLoadMore),
            ),
          ),
      ],
    );
  }
}
"""

REPLACEMENTS = [(OLD_HEAD, NEW_HEAD), (OLD_BODY, NEW_BODY)]


def main():
    full = os.path.join(ROOT, TARGET)
    with io.open(full, "r", encoding="utf-8") as f:
        text = f.read()
    missing = []
    for old, new in REPLACEMENTS:
        if old not in text:
            missing.append(old.strip().splitlines()[0][:80])
            continue
        text = text.replace(old, new, 1)
    with io.open(full, "w", encoding="utf-8", newline="\n") as f:
        f.write(text)
    if missing:
        print("MISS %s:" % TARGET)
        for m in missing:
            print("   - %s" % m)
        return 1
    print("ok   %s" % TARGET)
    return 0


if __name__ == "__main__":
    sys.exit(main())
