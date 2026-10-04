import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/services/cloud_sync_service.dart';
import 'package:naviflash/services/playlist_service.dart';
import 'package:naviflash/services/settings_service.dart';       
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:provider/provider.dart';
import '../services/webdav_service.dart';
import '../src/loading_indicator_m3e.dart';
import '../l10n/app_localizations.dart';

const double _kGroupRadius = 16.0;
const double _kItemRadius = 8.0;
const double _kItemPressedRadius = 12.0;
const double _kListEdgeRadius = 2.0;
const double _kIconBtnRadius = 14.0;
const double _kCardGap = 2.0;
const Duration _kMorphDuration = Duration(milliseconds: 70);
const Curve _kMorphCurve = Curves.fastOutSlowIn;

class WebDavSettingsScreen extends StatefulWidget {
  const WebDavSettingsScreen({super.key});
  @override
  State<WebDavSettingsScreen> createState() => _WebDavSettingsScreenState();
}

class _WebDavSettingsScreenState extends State<WebDavSettingsScreen> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remotePathController = TextEditingController();
  bool _obscurePassword = true;
  bool _isTesting = false;
  bool _testSuccess = false;
  final _passphraseController = TextEditingController();
  bool _obscurePassphrase = true;
                           
  bool _isSettingsBusy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final service = Provider.of<WebDavService>(context, listen: false);
      _urlController.text = service.serverUrl;
      _usernameController.text = service.username;
      _passwordController.text = service.password;
      _remotePathController.text = service.remoteBasePath;
      _passphraseController.text = service.syncPassphrase;
    });
  }

  @override
  void dispose() {
    _urlController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _remotePathController.dispose();
    _passphraseController.dispose();
    super.dispose();
  }

  void _showSnackBar(String message, ColorScheme colorScheme) {
    if (!mounted) return;
                                                             
    showAppToast(context, message);
  }

  Future<void> _saveAndTest() async {
    final l10n = AppLocalizations.of(context);
    final service = Provider.of<WebDavService>(context, listen: false);
    await service.setServerUrl(_urlController.text.trim());
    await service.setUsername(_usernameController.text.trim());
    await service.setPassword(_passwordController.text);
    await service.setRemoteBasePath(_remotePathController.text.trim());
    setState(() {
      _isTesting = true;
      _testSuccess = false;
    });
    final success = await service.testConnection();
    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = success;
      });
      _showSnackBar(
        success ? l10n.webdavConnectSuccess : '❌ ${service.lastError}',
        Theme.of(context).colorScheme,
      );
    }
  }

  Future<void> _saveOnly() async {
    final l10n = AppLocalizations.of(context);
    final service = Provider.of<WebDavService>(context, listen: false);
    await service.setServerUrl(_urlController.text.trim());
    await service.setUsername(_usernameController.text.trim());
    await service.setPassword(_passwordController.text);
    await service.setRemoteBasePath(_remotePathController.text.trim());
    if (mounted) {
      _showSnackBar(l10n.webdavConfigSaved, Theme.of(context).colorScheme);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
                                        
    final settings = context.watch<SettingsService>();
    final hideInfo = settings.hideWebDavInfo;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainer,
                                           
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'webdav_settings_fab',
        onPressed: _isTesting ? null : _saveAndTest,
        icon: _isTesting
            ? const LoadingIndicatorM3E(
                constraints: BoxConstraints(
                  minWidth: 18,
                  maxWidth: 18,
                  minHeight: 18,
                  maxHeight: 18,
                ),
              )
            : const Icon(Icons.wifi_tethering),
        label: Text(_isTesting ? l10n.webdavTesting : l10n.webdavSaveAndTest),
      ),
      body: Consumer<WebDavService>(
        builder: (context, webdav, _) {
          final colorScheme = Theme.of(context).colorScheme;
          return CustomScrollView(
              physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),                                                  
              slivers: [
                SliverAppBar(
                  pinned: true,
                  leading: _MorphIconButton(
                    tooltip: l10n.startScreenGoBack,
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                  backgroundColor: Colors.transparent,
                  actions: [
                                     
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: _MorphIconButton(
                        tooltip: l10n.webdavSaveOnly,
                        icon: Icons.save_outlined,
                        onTap: _isTesting ? null : _saveOnly,
                      ),
                    ),
         
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: _MorphIconButton(
                        tooltip: hideInfo ? l10n.webdavShowInfo : l10n.webdavHideInfo,
                        icon: hideInfo
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        onTap: () {
                          settings.setHideWebDavInfo(!hideInfo);
                        },
                      ),
                    ),
                  ],
                  expandedHeight: 152,
                  flexibleSpace: LayoutBuilder(
                    builder: (context, constraints) {
                      final safePadding = MediaQuery.of(context).padding;
                      final isCollapsed = constraints.biggest.height <=
                          kToolbarHeight + safePadding.top;
                      const leadingWidth = 48.0;
                      const dur = Duration(milliseconds: 260);
                      const curve = Curves.easeInOut;
                      return Stack(
                        children: [
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            child: AnimatedOpacity(
                              opacity: isCollapsed ? 1 : 0,
                              duration: dur,
                              curve: curve,
                              child: ClipRect(
                                child: SizedBox(
                                  height: kToolbarHeight + safePadding.top,
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                        sigmaX: 10.0, sigmaY: 10.0),
                                    child: Container(
                                      color: colorScheme.surface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: isCollapsed ? 0 : 1,
                            duration: dur,
                            curve: curve,
                            child: AnimatedContainer(
                              duration: dur,
                              curve: curve,
                              alignment: Alignment.bottomLeft,
                              padding: EdgeInsets.only(
                                left: 16.0,
                                top: safePadding.top,
                                bottom: 16.0,
                              ),
                              child: Text(
                                l10n.profileWebdavBackup,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ),
                          ),
                          AnimatedOpacity(
                            opacity: isCollapsed ? 1 : 0,
                            duration: dur,
                            curve: curve,
                            child: AnimatedContainer(
                              duration: dur,
                              curve: curve,
                              alignment: Alignment.centerLeft,
                              padding: EdgeInsets.only(
                                left: leadingWidth + safePadding.left + 8.0,
                                top: safePadding.top,
                              ),
                              child: Text(
                                l10n.profileWebdavBackup,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                   
                      _buildStatusCard(webdav, colorScheme, hideInfo),
                      const SizedBox(height: 24),
                      _buildSectionTitle(context, l10n.webdavServerConfig),
                      const SizedBox(height: 12),
                              
                      Padding(
                        padding: const EdgeInsets.only(bottom: _kCardGap),
                        child: _MorphItem(
                          selected: false,
                          isFirst: true,
                          interactive: false,
                          child: TextField(
                            controller: _urlController,
                            obscureText: hideInfo,    
                            decoration: _underlineDeco(
                              label: l10n.webdavServerUrlLabel,
                              hint: 'https://dav.example.com',
                              icon: Icons.dns_outlined,
                            ),
                            keyboardType: TextInputType.url,
                            onChanged: (_) =>
                                setState(() => _testSuccess = false),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: _kCardGap),
                        child: _MorphItem(
                          selected: false,
                          interactive: false,
                          child: TextField(
                            controller: _usernameController,
                            obscureText: hideInfo,    
                            decoration: _underlineDeco(
                              label: l10n.webdavUsernameLabel,
                              hint: 'your_username',
                              icon: Icons.person_outline,
                            ),
                            onChanged: (_) =>
                                setState(() => _testSuccess = false),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: _kCardGap),
                        child: _MorphItem(
                          selected: false,
                          interactive: false,
                          child: TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword || hideInfo,    
                            decoration: _underlineDeco(
                              label: l10n.webdavPasswordLabel,
                              hint: '••••••••',
                              icon: Icons.lock_outline,
                              suffix: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined),
                                onPressed: () => setState(() =>
                                    _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            onChanged: (_) =>
                                setState(() => _testSuccess = false),
                          ),
                        ),
                      ),
                      _MorphItem(
                        selected: false,
                        isLast: true,
                        interactive: false,
                        child: TextField(
                          controller: _remotePathController,
                          obscureText: hideInfo,    
                          decoration: _underlineDeco(
                            label: l10n.webdavRemotePathLabel,
                            hint: '/navi_backup',
                            icon: Icons.folder_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_testSuccess) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius:
                                BorderRadius.circular(_kItemRadius),
                            border: Border.all(
                                color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle,
                                  color: Colors.green, size: 20),
                              const SizedBox(width: 8),
                              Text(l10n.webdavConnectVerified,
                                  style: TextStyle(color: Colors.green)),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                                             
                      _buildSectionTitle(context, l10n.webdavMediaSync),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.only(bottom: _kCardGap),
                        child: _MorphItem(
                          selected: false,
                          isFirst: true,
                          child: SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            title: Text(l10n.webdavSyncPlaylists),
                            subtitle: Text(
                              _formatSyncTime(webdav.playlistsLastSync),
                            ),
                            value: webdav.syncPlaylists,
                            onChanged: webdav.isConfigured
                                ? (v) => webdav.setSyncPlaylists(v)
                                : null,
                            secondary: Icon(
                              Icons.queue_music_outlined,
                              color: webdav.syncPlaylists
                                  ? theme.colorScheme.primary
                                  : null,
                            ),
                          ),
                        ),
                      ),
                      _MorphItem(
                        selected: false,
                        isLast: true,
                        child: SwitchListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          title: Text(l10n.webdavSyncDanmaku),
                          subtitle: Text(
                            _formatSyncTime(webdav.danmakuLastSync),
                          ),
                          value: webdav.syncDanmaku,
                          onChanged: webdav.isConfigured
                              ? (v) => webdav.setSyncDanmaku(v)
                              : null,
                          secondary: Icon(
                            Icons.subtitles_outlined,
                            color: webdav.syncDanmaku
                                ? theme.colorScheme.primary
                                : null,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: _kCardGap),
                        child: _MorphItem(
                          selected: false,
                          isLast: true,
                          interactive: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                            child: TextField(
                              controller: _passphraseController,
                              obscureText: _obscurePassphrase,
                              autocorrect: false,
                              decoration: _underlineDeco(
                                label: webdav.syncPassphraseEnabled
                                    ? l10n.webdavPassphraseEncrypted
                                    : l10n.webdavPassphrasePlain,
                                hint: l10n.webdavPassphraseHint,
                                icon: Icons.lock_outline,
                                suffix: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        _obscurePassphrase
                                            ? Icons.visibility_outlined
                                            : Icons.visibility_off_outlined,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(() =>
                                          _obscurePassphrase =
                                              !_obscurePassphrase),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.auto_fix_high,
                                          size: 20),
                                      tooltip: l10n.webdavGeneratePassphrase,
                                      onPressed: () => _generatePassphrase(
                                          webdav, theme.colorScheme),
                                    ),
                                  ],
                                ),
                              ),
                              onChanged: (v) =>
                                  webdav.setSyncPassphrase(v),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          l10n.webdavMediaSyncHint,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color:
                                theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          webdav.syncPassphraseEnabled
                              ? l10n.webdavEncryptionOn
                              : l10n.webdavEncryptionOff,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: webdav.syncPassphraseEnabled
                                ? theme.colorScheme.primary
                                : theme.colorScheme.error,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                                                 
                      _buildSectionTitle(context, '设置备份'),
                      const SizedBox(height: 12),
                      _MorphItem(
                        selected: false,
                        isFirst: true,
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          leading: _isSettingsBusy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: LoadingIndicatorM3E(
                                    constraints: BoxConstraints(
                                      minWidth: 18,
                                      maxWidth: 18,
                                      minHeight: 18,
                                      maxHeight: 18,
                                    ),
                                  ),
                                )
                              : Icon(Icons.cloud_upload_outlined,
                                  color: webdav.isConfigured
                                      ? theme.colorScheme.primary
                                      : null),
                          title: const Text('备份设置'),
                          subtitle: Text(
                            webdav.syncPassphraseEnabled
                                ? '全量设置项序列化加密后上传到云端'
                                : '全量设置项上传到云端（未启用口令加密）',
                          ),
                          enabled: webdav.isConfigured && !_isSettingsBusy,
                          onTap: _confirmBackupSettings,
                        ),
                      ),
                      _MorphItem(
                        selected: false,
                        isLast: true,
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          leading: Icon(Icons.cloud_download_outlined,
                              color: webdav.isConfigured
                                  ? theme.colorScheme.primary
                                  : null),
                          title: const Text('恢复设置'),
                          subtitle: const Text(
                            '从云端下载设置并覆盖本地同名项（重启后完全生效）',
                          ),
                          enabled: webdav.isConfigured && !_isSettingsBusy,
                          onTap: _confirmRestoreSettings,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Text(
                          '与媒体同步共用同一加密口令；备份包含登录凭据等敏感配置，'
                          '建议开启口令加密后再备份。',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color:
                                theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionTitle(context, l10n.webdavManage),
                      const SizedBox(height: 12),
                      ...(() {
                        final items = <_RowItem>[];
                        if (webdav.lastSyncTime != null) {
                          items.add(_RowItem(
                            interactive: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: _buildInfoRow(
                                Icons.schedule,
                                l10n.webdavLastSync,
                                _formatDateTime(webdav.lastSyncTime!),
                              ),
                            ),
                          ));
                        }
                        if (webdav.lastError.isNotEmpty) {
                          items.add(_RowItem(
                            interactive: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 10),
                              child: _buildInfoRow(
                                Icons.error_outline,
                                l10n.webdavLastError,
                                webdav.lastError,
                                isError: true,
                              ),
                            ),
                          ));
                        }
                        items.add(_RowItem(
                          interactive: true,
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16),
                            leading: Icon(Icons.delete_forever,
                                color: Theme.of(context).colorScheme.error),
                            title: Text(l10n.webdavClearConfig),
                            subtitle:
                                Text(l10n.webdavClearConfigSubtitle),
                            onTap: () =>
                                _showClearConfirmDialog(webdav),
                          ),
                        ));
                        return List.generate(items.length, (i) {
                          final isFirst = i == 0;
                          final isLast = i == items.length - 1;
                          return Padding(
                            padding: EdgeInsets.only(
                                bottom: isLast ? 0 : _kCardGap),
                            child: _MorphItem(
                              selected: false,
                              isFirst: isFirst,
                              isLast: isLast,
                              interactive: items[i].interactive,
                              child: items[i].child,
                            ),
                          );
                        });
                      })(),
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            );
        },
      ),
    );
  }

  InputDecoration _underlineDeco({
    required String label,
    String? hint,
    IconData? icon,
    Widget? suffix,
  }) {
    final cs = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      suffixIcon: suffix,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent)),
      enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.transparent)),
      focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: cs.primary, width: 2)),
    );
  }

                       
  Widget _buildStatusCard(
      WebDavService webdav, ColorScheme colorScheme, bool hideInfo) {
    final l10n = AppLocalizations.of(context);
    final isActive = webdav.isConfigured && webdav.enabled;
    final isConfigured = webdav.isConfigured;
    late Color statusBg;
    late Color statusFg;
    late IconData statusIcon;
    late String statusText;

    if (isActive) {
      statusBg = colorScheme.primary;
      statusFg = colorScheme.onPrimary;
      statusIcon = Icons.check;
      final name = hideInfo
          ? '••••'
          : (webdav.username.isNotEmpty ? webdav.username : l10n.webdavUserLabel);
      statusText = l10n.webdavStatusActive(name);
    } else if (isConfigured) {
      statusBg = colorScheme.tertiary;
      statusFg = colorScheme.onTertiary;
      statusIcon = Icons.cloud_queue_outlined;
      final name = hideInfo
          ? '••••'
          : (webdav.username.isNotEmpty ? webdav.username : l10n.webdavUserLabel);
      statusText = l10n.webdavStatusConfigured(name);
    } else {
      statusBg = colorScheme.error;
      statusFg = colorScheme.onError;
      statusIcon = Icons.cloud_off_outlined;
      statusText = l10n.webdavStatusNotConfigured;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(_kGroupRadius),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: statusBg,
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: statusFg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(statusIcon, color: statusBg, size: 56),
                  ),
                ),
              ),
              Container(
                color: statusFg,
                padding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      statusText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: statusBg,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    if (webdav.serverUrl.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
           
                        hideInfo ? '••••••••••••' : webdav.serverUrl,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: statusBg.withValues(alpha: 0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (webdav.isBatchBackingUp)
            Positioned(
              top: 12,
              right: 12,
              child: LoadingIndicatorM3E(
                color: statusFg,
                constraints: BoxConstraints(
                  minWidth: 22,
                  maxWidth: 22,
                  minHeight: 22,
                  maxHeight: 22,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      textAlign: TextAlign.left,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  String _formatSyncTime(DateTime? time) {
    final l10n = AppLocalizations.of(context);
    if (time == null) return l10n.webdavNotSynced;
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return l10n.webdavJustNow;
    if (diff.inHours < 1) return l10n.webdavMinutesAgo(diff.inMinutes);
    if (diff.inDays < 1) return l10n.webdavHoursAgo(diff.inHours);
    final hm = '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    return l10n.webdavSyncedDate(time.month, time.day, hm);
  }

                                   
  void _generatePassphrase(WebDavService webdav, ColorScheme colorScheme) {
    final l10n = AppLocalizations.of(context);
    final generated = webdav.generateSyncPassphrase();
    _passphraseController.text = generated;
    webdav.setSyncPassphrase(generated);
    Clipboard.setData(ClipboardData(text: generated));
    _showSnackBar(l10n.webdavPassphraseGenerated, colorScheme);
  }

                                                                      

  Future<bool> _confirmDialog(String title, String content,
      {String confirmText = '确定'}) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        content: Text(content, style: const TextStyle(fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _confirmBackupSettings() async {
    final ok = await _confirmDialog(
      '备份设置到云端？',
      '将把应用的全部设置项序列化后上传到 WebDAV（WebDAV 服务器的账号密码'
      '保存在本机安全存储中，不包含在备份内），云端已有的设置备份会被覆盖。',
      confirmText: '备份',
    );
    if (!ok || !mounted) return;
    await _runSettingsOp(restore: false);
  }

  Future<void> _confirmRestoreSettings() async {
    final ok = await _confirmDialog(
      '从云端恢复设置？',
      '将下载云端设置备份并写入本地，云端值会覆盖当前同名设置，'
      '该操作不可撤销。恢复后建议重启应用使其完全生效。',
      confirmText: '恢复',
    );
    if (!ok || !mounted) return;
    await _runSettingsOp(restore: true);
  }

  Future<void> _runSettingsOp({required bool restore}) async {
    if (_isSettingsBusy) return;
    setState(() => _isSettingsBusy = true);
                                                       
    final sync = CloudSyncService(
      webdav: Provider.of<WebDavService>(context, listen: false),
      playlists: Provider.of<PlaylistService>(context, listen: false),
    );
    final r = restore ? await sync.restoreSettings() : await sync.backupSettings();
    if (!mounted) return;
    setState(() => _isSettingsBusy = false);
    showAppToast(context, r.message, error: !r.ok);
  }

  Widget _buildInfoRow(IconData icon, String label, String value,
      {bool isError = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: isError ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 13,
                      color: isError ? Theme.of(context).colorScheme.error : null,
                      fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  void _showClearConfirmDialog(WebDavService webdav) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.webdavConfirmClear),
        content: Text(l10n.webdavClearConfirmText),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            onPressed: () {
              webdav.clearConfig();
              _urlController.clear();
              _usernameController.clear();
              _passwordController.clear();
              _remotePathController.text = '/navi_backup';
              setState(() => _testSuccess = false);
              Navigator.pop(ctx);
            },
            child: Text(l10n.webdavClear),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _MorphIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  const _MorphIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });
  @override
  State<_MorphIconButton> createState() => _MorphIconButtonState();
}

class _MorphIconButtonState extends State<_MorphIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = cs.secondaryContainer;
    final pressedColor = Color.alphaBlend(
      cs.onSecondaryContainer.withValues(alpha: 0.12),
      base,
    );
    final radius =
        BorderRadius.circular(_pressed ? _kIconBtnRadius : 100.0);

    Widget button = AnimatedContainer(
      duration: _kMorphDuration,
      curve: _kMorphCurve,
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _pressed ? pressedColor : base,
        borderRadius: radius,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: widget.onTap,
          onHighlightChanged: (v) => setState(() => _pressed = v),
          borderRadius: radius,
          highlightColor: Colors.transparent,
          splashColor: cs.onSecondaryContainer.withValues(alpha: 0.3),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Icon(widget.icon,
                  size: 22, color: cs.onSecondaryContainer),
            ),
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = AppTooltip(
        message: widget.tooltip!,
        triggerMode: TooltipTriggerMode.longPress,
        child: button,
      );
    }
    return Center(child: button);
  }
}

class _MorphItem extends StatefulWidget {
  final bool selected;
  final bool isFirst;
  final bool isLast;
  final bool interactive;
  final Widget child;
  const _MorphItem({
    required this.selected,
    required this.child,
    this.isFirst = false,
    this.isLast = false,
    this.interactive = true,
  });
  @override
  State<_MorphItem> createState() => _MorphItemState();
}

class _MorphItemState extends State<_MorphItem> {
  bool _pressed = false;

  BorderRadius _defaultRadius() {
    const big = _kItemPressedRadius;
    const edge = _kListEdgeRadius;
    if (widget.isFirst && widget.isLast) {
      return BorderRadius.circular(big);
    }
    if (widget.isFirst) {
      return BorderRadius.only(
        topLeft: const Radius.circular(big),
        topRight: const Radius.circular(big),
        bottomLeft: const Radius.circular(edge),
        bottomRight: const Radius.circular(edge),
      );
    }
    if (widget.isLast) {
      return BorderRadius.only(
        topLeft: const Radius.circular(edge),
        topRight: const Radius.circular(edge),
        bottomLeft: const Radius.circular(big),
        bottomRight: const Radius.circular(big),
      );
    }
    return BorderRadius.circular(edge);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base =
        widget.selected ? cs.secondaryContainer : cs.surfaceBright;
    final overlay = widget.selected
        ? cs.onSecondaryContainer.withValues(alpha: 0.10)
        : cs.onSurface.withValues(alpha: 0.08);
    final color = _pressed ? Color.alphaBlend(overlay, base) : base;
    final radius = _pressed
        ? BorderRadius.circular(_kItemPressedRadius)
        : _defaultRadius();

    final container = AnimatedContainer(
      duration: _kMorphDuration,
      curve: _kMorphCurve,
      decoration: BoxDecoration(color: color, borderRadius: radius),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: widget.child,
      ),
    );

    if (!widget.interactive) return container;

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: container,
    );
  }
}

class _RowItem {
  final Widget child;
  final bool interactive;
  const _RowItem({required this.child, this.interactive = true});
}