# tool/patch_rail_account.py
#
# 一次性补丁：宽屏 rail 底部头像 + 昵称改为「B 站登录账号优先」，
# 并监听账号变化（登录/退出后即时刷新，不再一直显示「请先登录」）。
# 用法：python tool/patch_rail_account.py
import io
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = "lib/widgets/collapsible_side_bar.dart"

OLD = """  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final settingsService = context.read<SettingsService>();
    final hasAvatar =
        settingsService.avatarPath != null &&
        File(settingsService.avatarPath!).existsSync();

    final avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: cs.primaryContainer,
        backgroundImage: hasAvatar
            ? FileImage(File(settingsService.avatarPath!))
            : const AssetImage('assets/bili_icons/noface.jpeg'),
      ),
    );

    final themeBtn = IconButton(
      icon: const Icon(Icons.brightness_4, size: 20),
      tooltip: l10n.drawerSwitchToDark,
      color: cs.onSurfaceVariant,
      onPressed: () => _toggleThemeMode(context, settingsService),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: isExpanded
            ? Row(
                children: [
                  const SizedBox(width: 14),
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      settingsService.nickname?.isNotEmpty == true
                          ? settingsService.nickname!
                          : '请先登录',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  themeBtn,
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [avatar, const SizedBox(height: 4), themeBtn],
              ),
      ),
    );
  }
"""

NEW = """  @override
  Widget build(BuildContext context) {
    final settingsService = context.read<SettingsService>();
    // B 站账号变化（登录 / 退出 / 改名）后即时刷新头像与昵称。
    return ListenableBuilder(
      listenable: BilibiliAccountService.instance,
      builder: (context, _) => _buildBody(context, settingsService),
    );
  }

  Widget _buildBody(BuildContext context, SettingsService settingsService) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final account = BilibiliAccountService.instance;
    final loggedIn = account.isLoggedIn;
    // 优先显示 B 站账号（登录后不再显示「请先登录」），其次本地资料。
    final name = loggedIn && account.uname.isNotEmpty
        ? account.uname
        : (settingsService.nickname?.isNotEmpty == true
              ? settingsService.nickname!
              : '请先登录');
    final hasAvatar =
        settingsService.avatarPath != null &&
        File(settingsService.avatarPath!).existsSync();
    final headers = NetworkSettingsService.instance.apiHeaders.isEmpty
        ? null
        : NetworkSettingsService.instance.apiHeaders;
    final ImageProvider? avatarImage = loggedIn && account.avatarUrl.isNotEmpty
        ? CachedImageProvider(
            BilibiliUserSpaceService.avatarUrl(account.avatarUrl),
            headers: headers,
          )
        : hasAvatar
        ? FileImage(File(settingsService.avatarPath!))
        : null;

    final avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: cs.primaryContainer,
        backgroundImage:
            avatarImage ?? const AssetImage('assets/bili_icons/noface.jpeg'),
      ),
    );

    final themeBtn = IconButton(
      icon: const Icon(Icons.brightness_4, size: 20),
      tooltip: l10n.drawerSwitchToDark,
      color: cs.onSurfaceVariant,
      onPressed: () => _toggleThemeMode(context, settingsService),
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: isExpanded
            ? Row(
                children: [
                  const SizedBox(width: 14),
                  avatar,
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  themeBtn,
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [avatar, const SizedBox(height: 4), themeBtn],
              ),
      ),
    );
  }
"""

IMPORTS_OLD = "import 'package:naviflash/services/settings_service.dart';"
IMPORTS_NEW = (
    "import 'package:naviflash/services/bilibili_account_service.dart';\n"
    "import 'package:naviflash/services/bilibili_user_space_service.dart';\n"
    "import 'package:naviflash/services/cached_image_provider.dart';\n"
    "import 'package:naviflash/services/network_settings_service.dart';\n"
    "import 'package:naviflash/services/settings_service.dart';"
)


def main():
    full = os.path.join(ROOT, TARGET)
    with io.open(full, "r", encoding="utf-8") as f:
        text = f.read()
    missing = []
    for old, new in ((OLD, NEW), (IMPORTS_OLD, IMPORTS_NEW)):
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
