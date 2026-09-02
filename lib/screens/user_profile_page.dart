import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/webdav_service.dart'; //  新增
import '../widgets/morph_card.dart';
import '../widgets/expressive_app_bar.dart';
import '../widgets/frosted_route.dart';
import '../src/loading_indicator_m3e.dart';
import 'image_viewer_page.dart'; //  新增
import 'webdav_settings_screen.dart'; //  新增
import '../l10n/app_localizations.dart';

class UserProfilePage extends StatefulWidget {
  /// Hero 动画标签；为 null 时不启用 Hero（如分屏右侧直接展示）
  final String? heroTag;

  const UserProfilePage({super.key, this.heroTag});

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  bool _isPickingAvatar = false;
  bool _isPickingDrawerBg = false;

  static const double _expandedHeight = 300.0;
  static const double _avatarRadius = 44.0;

  /// 头像 Hero 动画的固定 tag
  static const String _avatarHeroTag = 'user_profile_avatar_hero';

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final webdav = context.watch<WebDavService>(); //  新增：监听 WebDAV 状态
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLow,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: _expandedHeight,
            pinned: true,
            stretch: true,
            stretchTriggerOffset: 60,
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            leading: MorphIconButton(
              icon: Icons.arrow_back,
              tooltip: l10n.startScreenGoBack,
              onTap: () => Navigator.pop(context),
            ),
            actions: [
              MorphIconButton(
                icon: Icons.edit_outlined,
                tooltip: l10n.profileEditProfile,
                onTap: () => _showNicknameDialog(context, settings),
              ),
              const SizedBox(width: 4),
            ],
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final safeTop = MediaQuery.of(context).padding.top;
                final currentHeight = constraints.biggest.height;
                final isCollapsed =
                    currentHeight <= kToolbarHeight + safeTop + 1;

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // ── 1. 背景图层 ──
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () =>
                              _showBackgroundOptions(context, settings),
                          child: _buildBackgroundImage(settings, cs),
                        ),
                      ),
                    ),
                    // ── 2. 底部渐变遮罩 ──
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 160,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.65),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // ── 3. 展开态内容 ──
                    AnimatedOpacity(
                      opacity: isCollapsed ? 0 : 1,
                      duration: const Duration(milliseconds: 200),
                      child: IgnorePointer(
                        ignoring: isCollapsed,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 12),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildHeroAvatar(settings, cs),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            settings.nickname?.isNotEmpty ==
                                                    true
                                                ? settings.nickname!
                                                : l10n.drawerNoNickname,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontWeight: FontWeight.w700,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 6,
                                                  color: Colors.black54,
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Local Account',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withOpacity(0.75),
                                              fontSize: 13,
                                              shadows: const [
                                                Shadow(
                                                  blurRadius: 4,
                                                  color: Colors.black45,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        _headerSmallButton(
                                          icon: Icons
                                              .photo_camera_outlined,
                                          tooltip: l10n.profileChangeAvatar,
                                          onTap: _isPickingAvatar
                                              ? null
                                              : () => _handlePickAvatar(
                                                  context, settings),
                                        ),
                                        const SizedBox(width: 8),
                                        if (settings.avatarPath != null)
                                          _headerSmallButton(
                                            icon: Icons.delete_outline,
                                            tooltip: l10n.profileRemoveAvatar,
                                            onTap: () =>
                                                _confirmRemoveAvatar(
                                                    context, settings),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    // ── 4. 折叠态毛玻璃 ──
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: AnimatedOpacity(
                        opacity: isCollapsed ? 1 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: ClipRect(
                          child: SizedBox(
                            height: kToolbarHeight + safeTop,
                            child: BackdropFilter(
                              filter: ImageFilter.blur(
                                  sigmaX: 12, sigmaY: 12),
                              child: Container(
                                color: cs.surface
                                    .withOpacity(isDark ? 0.75 : 0.65),
                                alignment: Alignment.bottomLeft,
                                padding: EdgeInsets.only(
                                  left: 72,
                                  bottom: 12,
                                ),
                                child: Text(
                                  settings.nickname?.isNotEmpty == true
                                      ? settings.nickname!
                                      : l10n.profileTitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

// =====  新增：账户管理 Section =====
          SliverToBoxAdapter(
            child: _buildSectionHeader(l10n.profileAccountSection, cs),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: buildMorphSegmentedList([
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(
                        webdav.isConfigured
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined,
                        color: webdav.isConfigured
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                      title: Text(l10n.profileWebdavBackup),
                      subtitle: Text(
                        webdav.isConfigured && webdav.username.isNotEmpty
                            ? l10n.profileWebdavLoggedIn(webdav.username)
                            : l10n.profileNotLoggedIn,
                        style: TextStyle(
                          color: webdav.isConfigured
                              ? cs.primary.withOpacity(0.8)
                              : cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: Icon(Icons.chevron_right,
                          color: cs.onSurfaceVariant),
                      onTap: () {
//  跳转时触发清脆震动反馈
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const WebDavSettingsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          // ===== 头像 Section =====
          SliverToBoxAdapter(
            child: _buildSectionHeader(l10n.profileAvatarSection, cs),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: buildMorphSegmentedList([
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.photo_library_outlined,
                          color: cs.primary),
                      title: Text(l10n.profileChangeAvatar),
                      subtitle: Text(l10n.profilePickFromGallery),
                      trailing: _isPickingAvatar
                          ? const LoadingIndicatorM3E(
                              constraints: BoxConstraints(
                                minWidth: 20,
                                maxWidth: 20,
                                minHeight: 20,
                                maxHeight: 20,
                              ),
                            )
                          : Icon(Icons.chevron_right,
                              color: cs.onSurfaceVariant),
                      onTap: _isPickingAvatar
                          ? null
                          : () => _handlePickAvatar(context, settings),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading:
                          Icon(Icons.delete_outline, color: cs.error),
                      title: Text(l10n.profileRemoveAvatar,
                          style: TextStyle(color: cs.error)),
                      subtitle: Text(l10n.profileRestoreDefaultAvatar),
                      onTap: settings.avatarPath != null
                          ? () =>
                              _confirmRemoveAvatar(context, settings)
                          : null,
                    ),
                  ),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: _buildSectionHeader(l10n.drawerBackgroundTitle, cs),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: buildMorphSegmentedList([
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.wallpaper_outlined,
                          color: cs.primary),
                      title: Text(
                        settings.drawerBackgroundPath != null
                            ? l10n.drawerBackgroundChange
                            : l10n.profileSetBackground,
                      ),
                      subtitle: Text(l10n.profileBgSubtitle),
                      trailing: _isPickingDrawerBg
                          ? const LoadingIndicatorM3E(
                              constraints: BoxConstraints(
                                minWidth: 20,
                                maxWidth: 20,
                                minHeight: 20,
                                maxHeight: 20,
                              ),
                            )
                          : Icon(Icons.chevron_right,
                              color: cs.onSurfaceVariant),
                      onTap: _isPickingDrawerBg
                          ? null
                          : () =>
                              _handlePickDrawerBg(context, settings),
                    ),
                  ),
                  MorphRowItem(
                    child: ListTile(
                      leading: Icon(Icons.restore,
                          color: cs.onSurfaceVariant),
                      title: Text(l10n.profileRestoreDefault),
                      subtitle:
                          Text(l10n.profileBgRemoveSubtitle),
                      onTap: settings.drawerBackgroundPath != null
                          ? () =>
                              _handleRemoveDrawerBg(context, settings)
                          : null,
                    ),
                  ),
                ]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 24)),

          SliverToBoxAdapter(
            child: _buildSectionHeader(l10n.profileInfoSection, cs),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: buildMorphSegmentedList([
                  MorphRowItem(
                    child: ListTile(
                      leading:
                          Icon(Icons.badge_outlined, color: cs.primary),
                      title: Text(l10n.profileNicknameLabel),
                      subtitle: Text(
                        settings.nickname?.isNotEmpty == true
                            ? settings.nickname!
                            : l10n.profileNotSet,
                      ),
                      trailing: Icon(Icons.edit,
                          size: 20, color: cs.onSurfaceVariant),
                      onTap: () =>
                          _showNicknameDialog(context, settings),
                    ),
                  ),
                ]),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: MediaQuery.of(context).padding.bottom + 32,
            ),
          ),
        ],
      ),
    );
  }

// =================  功能1：点击头像查看大图 + Hero =================
  Widget _buildHeroAvatar(SettingsService settings, ColorScheme cs) {
    final hasAvatar = settings.avatarPath != null &&
        File(settings.avatarPath!).existsSync();

    Widget avatar = Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withOpacity(0.9),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: _avatarRadius,
        backgroundColor: cs.surfaceContainerHighest,
        backgroundImage: _avatarImage(settings),
        child: !hasAvatar
            ? Icon(
                Icons.person,
                size: _avatarRadius,
                color: cs.onSurfaceVariant,
              )
            : null,
      ),
    );

    // Hero 包裹（进入本页时的飞行动画，来源页传入）
    if (widget.heroTag != null) {
      avatar = Hero(tag: widget.heroTag!, child: avatar);
    }

//  头像 → 大图查看器的 Hero（独立 tag，点击头像时缩略图飞入大图）
    avatar = Hero(tag: _avatarHeroTag, child: avatar);

//  有头像时，点击跳转 ImageViewerPage（带独立 Hero tag）
    if (hasAvatar) {
      avatar = GestureDetector(
        onTap: () => _openAvatarViewer(context, settings),
        child: avatar,
      );
    }

    return avatar;
  }

///  打开头像大图查看器
  void _openAvatarViewer(BuildContext context, SettingsService settings) {
//  跳转时触发清脆震动反馈
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      heroTransitionRoute(
        page: ImageViewerPage(
          filePath: settings.avatarPath,
          heroTag: _avatarHeroTag,
        ),
      ),
    );
  }

  Widget _buildBackgroundImage(SettingsService settings, ColorScheme cs) {
    final bgPath = settings.drawerBackgroundPath;
    final hasBg = bgPath != null && File(bgPath).existsSync();

    if (hasBg) {
      return Image.file(
        File(bgPath),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _defaultGradient(cs),
      );
    }
    return _defaultGradient(cs);
  }

  Widget _defaultGradient(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary,
            cs.primaryContainer,
            cs.tertiaryContainer,
          ],
        ),
      ),
    );
  }

  ImageProvider? _avatarImage(SettingsService settings) {
    final path = settings.avatarPath;
    if (path != null && File(path).existsSync()) {
      return FileImage(File(path));
    }
    return null;
  }

  Widget _headerSmallButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.2),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }

  void _showBackgroundOptions(
      BuildContext context, SettingsService settings) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final hasBg = settings.drawerBackgroundPath != null &&
        File(settings.drawerBackgroundPath!).existsSync();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return FrostedSheet(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(24)),
          child: Container(
            color: Colors.transparent,
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurface.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Icon(Icons.wallpaper,
                        color: theme.colorScheme.primary, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      l10n.profileBgTitle,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    await _handlePickDrawerBg(context, settings);
                  },
                  icon: const Icon(Icons.photo_library_outlined),
                  label: Text(hasBg ? l10n.drawerBackgroundChange : l10n.drawerBackgroundSelect),
                  style: FilledButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
                if (hasBg) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(sheetContext);
                      await _handleRemoveDrawerBg(context, settings);
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: Text(l10n.drawerBackgroundRemove),
                    style: OutlinedButton.styleFrom(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(
                          color:
                              theme.colorScheme.error.withOpacity(0.5)),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: Text(l10n.commonCancel),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme cs) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: cs.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<void> _handlePickAvatar(
      BuildContext context, SettingsService settings) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isPickingAvatar = true);
    try {
      await settings.pickAndSaveAvatar();
      if (mounted) {
        showAppToast(context, l10n.profileAvatarUpdated);
      }
    } catch (e) {
      if (mounted) {
        showAppToast(context, l10n.profileAvatarFailed('$e'), error: true);
      }
    } finally {
      if (mounted) setState(() => _isPickingAvatar = false);
    }
  }

  void _confirmRemoveAvatar(
      BuildContext context, SettingsService settings) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.profileRemoveAvatar),
        content: Text(l10n.profileRemoveAvatarConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              settings.removeAvatar();
              if (context.mounted) {
                showAppToast(context, l10n.profileAvatarRemoved);
              }
            },
            style:
                FilledButton.styleFrom(backgroundColor: cs.error),
            child: Text(l10n.commonDelete),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePickDrawerBg(
      BuildContext context, SettingsService settings) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _isPickingDrawerBg = true);
    try {
      final success = await settings.pickAndSaveDrawerBackground();
      if (success && mounted) {
        showAppToast(context, l10n.drawerBackgroundUpdated);
      }
    } catch (e) {
      if (mounted) {
        showAppToast(
          context,
          l10n.drawerBackgroundSetFailed('$e'),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingDrawerBg = false);
    }
  }

  Future<void> _handleRemoveDrawerBg(
      BuildContext context, SettingsService settings) async {
    final l10n = AppLocalizations.of(context);
    await settings.removeDrawerBackground();
    if (mounted) {
      showAppToast(context, l10n.drawerBackgroundRestored);
    }
  }

  void _showNicknameDialog(
      BuildContext context, SettingsService settings) {
    final l10n = AppLocalizations.of(context);
    final controller =
        TextEditingController(text: settings.nickname ?? '');
    final focusNode = FocusNode();

    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: Text(l10n.profileSetNickname),
          content: TextField(
            controller: controller,
            focusNode: focusNode,
            autofocus: true,
            maxLength: 20,
            decoration: InputDecoration(
              hintText: l10n.profileNicknameHint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: cs.primary, width: 2),
              ),
            ),
            onSubmitted: (value) {
              final name = value.trim();
              if (name.isNotEmpty) {
                settings.setNickname(name);
                Navigator.pop(ctx);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  showAppToast(ctx, l10n.profileNicknameEmpty, error: true);
                  return;
                }
                settings.setNickname(name);
                Navigator.pop(ctx);
                if (context.mounted) {
                  showAppToast(context, l10n.profileNicknameUpdated);
                }
              },
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
    ).then((_) {
      controller.dispose();
      focusNode.dispose();
    });
  }
}