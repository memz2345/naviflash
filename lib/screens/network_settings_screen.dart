                                           
  
                                            
                                                 
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/app_tooltip.dart';
import 'package:provider/provider.dart';
import '../services/network_settings_service.dart';
import '../widgets/widgets.dart';
import '../widgets/page_background.dart';
import '../src/loading_indicator_m3e.dart';
import '../l10n/app_localizations.dart';

class NetworkSettingsScreen extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const NetworkSettingsScreen({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  @override
  State<NetworkSettingsScreen> createState() => _NetworkSettingsScreenState();
}

class _NetworkSettingsScreenState extends State<NetworkSettingsScreen> {
  final _dohController = TextEditingController();
  final _refererController = TextEditingController();
  final _userAgentController = TextEditingController();

  final Map<String, NetCheckResult> _results = {};
  bool _testing = false;

                                  
  static const List<({String name, String url})> _testTargets = [
    (name: 'Cloudflare DoH', url: 'https://1.1.1.1/dns-query'),
    (name: 'Bilibili API', url: 'https://api.bilibili.com/'),
  ];

  @override
  void initState() {
    super.initState();
    _refererController.text = context.read<NetworkSettingsService>().referer;
    _userAgentController.text = context
        .read<NetworkSettingsService>()
        .userAgent;
    WidgetsBinding.instance.addPostFrameCallback((_) => _runAllTests());
  }

  @override
  void dispose() {
    _dohController.dispose();
    _refererController.dispose();
    _userAgentController.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }


  Future<void> _runAllTests() async {
    if (_testing) return;
    setState(() => _testing = true);
    final service = context.read<NetworkSettingsService>();
    for (final target in _testTargets) {
      final result = await _testTarget(service, target);
      if (!mounted) return;
      setState(() => _results[target.name] = result);
    }
    setState(() => _testing = false);
  }

  Future<void> _runSingleTest(String name, String url) async {
    final service = context.read<NetworkSettingsService>();
    setState(() => _results.remove(name));
    final result = await _testTarget(service, (name: name, url: url));
    if (!mounted) return;
    setState(() => _results[name] = result);
  }

  Future<NetCheckResult> _testTarget(
    NetworkSettingsService service,
    ({String name, String url}) target,
  ) async {
    return service.testUrl(name: target.name, url: target.url);
  }


  String? _dohResult;
  bool _dohLoading = false;

  Future<void> _queryDoh() async {
    final domain = _dohController.text.trim();
    if (domain.isEmpty) return;
    FocusScope.of(context).unfocus();
    final service = context.read<NetworkSettingsService>();
    setState(() {
      _dohLoading = true;
      _dohResult = null;
    });
    try {
      final ip = await service.queryDoH(domain);
      if (!mounted) return;
      setState(() {
        _dohLoading = false;
        _dohResult = ip;
      });
      if (ip == null) {
        _showSnack(AppLocalizations.of(context).netDohNoRecord(domain));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _dohLoading = false);
      _showSnack(AppLocalizations.of(context).netDohQueryFailed(e.toString()));
    }
  }

  void _applyDohResult() {
    final service = context.read<NetworkSettingsService>();
    final domain = _dohController.text.trim();
    final ip = _dohResult;
    if (domain.isEmpty || ip == null) return;
    HapticFeedback.lightImpact();
    service.setHostOverride(domain, ip);
    _showSnack(AppLocalizations.of(context).netMappingSaved(domain, ip));
  }

  void _addHostOverride() {
    HapticFeedback.lightImpact();
    final service = context.read<NetworkSettingsService>();
    final hostController = TextEditingController();
    final ipController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.netAddHostMapping),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostController,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.netDomainLabel,
                  hintText: 'example.com',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ipController,
                autocorrect: false,
                decoration: InputDecoration(
                  labelText: l10n.netIpLabel,
                  hintText: '1.2.3.4',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final host = hostController.text.trim();
                final ip = ipController.text.trim();
                if (host.isEmpty || ip.isEmpty) return;
                service.setHostOverride(host, ip);
                Navigator.pop(ctx);
                _showSnack(l10n.netMappingAdded(host, ip));
              },
              child: Text(l10n.netAdd),
            ),
          ],
        );
      },
    );
  }

  void _removeHostOverride(String host) {
    HapticFeedback.lightImpact();
    context.read<NetworkSettingsService>().removeHostOverride(host);
    _showSnack(AppLocalizations.of(context).netMappingRemoved(host));
  }

  void _showSnack(String message) {
    if (!mounted) return;
    showAppToast(context, message);
  }


  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final service = context.watch<NetworkSettingsService>();
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
                                          
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'network_settings_fab',
          onPressed: _addHostOverride,
          icon: const Icon(Icons.add),
          label: Text(l10n.netAddMapping),
        ),
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
            CustomScrollView(
              physics: const ClampingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),                                                  
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.netTitle,
                  expandedHeight: 152,
                  leading: widget.isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.netBackTooltip,
                          icon: Icons.arrow_back,
                          onTap: _handleBack,
                        ),
                  actions: [
                    MorphIconButton(
                      icon: Icons.refresh,
                      tooltip: l10n.netRetestAll,
                      onTap: _testing ? null : _runAllTests,
                    ),
                    const SizedBox(width: 4),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                                                           
                                                          
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                                         
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            flashKey: 'insecure_cert',
                            child: SwitchListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              secondary: Icon(
                                Icons.verified_user_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: Text(l10n.netAllowInsecureCert),
                              subtitle: Text(
                                l10n.netAllowInsecureCertDesc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              value: service.allowInsecureCert,
                              onChanged: (value) =>
                                  service.setAllowInsecureCert(value),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 32),

                                      
                        _buildSectionTitle(
                          context,
                          l10n.netConnectivitySection,
                        ),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          for (final target in _testTargets)
                            MorphRowItem(
                              flashKey: target == _testTargets.first
                                  ? 'connectivity_test'
                                  : null,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 4,
                                ),
                                leading: Icon(
                                  Icons.dns_outlined,
                                  size: 26,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                title: Text(target.name),
                                subtitle: Text(
                                  target.url,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: _buildTestIndicator(target.name),
                                onTap: () =>
                                    _runSingleTest(target.name, target.url),
                              ),
                            ),
                        ]),
                        const SizedBox(height: 32),

                                        
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSectionTitle(
                              context,
                              l10n.netHostMappingSection,
                            ),
                            TextButton.icon(
                              onPressed: () {
                                service.resetHostOverrides();
                                _showSnack(l10n.netMappingReset);
                              },
                              icon: const Icon(Icons.restart_alt, size: 18),
                              label: Text(l10n.netRestoreDefaults),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ...buildMorphSegmentedList([
                          if (service.hostOverrides.isEmpty)
                            MorphRowItem(
                              interactive: false,
                              flashKey: 'host_overrides',
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                title: Text(
                                  l10n.netNoMappings,
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            )
                          else
                            for (final entry in service.hostOverrides.entries)
                              MorphRowItem(
                                flashKey:
                                    entry.key ==
                                        service.hostOverrides.keys.first
                                    ? 'host_overrides'
                                    : null,
                                child: ListTile(
                                  dense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 2,
                                  ),
                                  leading: Icon(
                                    Icons.link_outlined,
                                    size: 22,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  title: Text(
                                    entry.key,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  subtitle: Text(
                                    entry.value,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.close,
                                      size: 18,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    onPressed: () =>
                                        _removeHostOverride(entry.key),
                                  ),
                                ),
                              ),
                        ]),
                        const SizedBox(height: 32),

                                       
                        _buildSectionTitle(context, l10n.netDohQuerySection),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            interactive: false,
                            flashKey: 'doh_query',
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                12,
                                16,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.netDohQueryDesc,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _dohController,
                                    autocorrect: false,
                                    decoration: InputDecoration(
                                      labelText: l10n.netDomainLabel,
                                      hintText: 'example.com',
                                      suffixIcon: _dohLoading
                                          ? const Padding(
                                              padding: EdgeInsets.all(12),
                                              child: LoadingIndicatorM3E(
                                                constraints: BoxConstraints(
                                                  minWidth: 20,
                                                  maxWidth: 20,
                                                  minHeight: 20,
                                                  maxHeight: 20,
                                                ),
                                              ),
                                            )
                                          : IconButton(
                                              icon: const Icon(Icons.search),
                                              onPressed: _queryDoh,
                                            ),
                                    ),
                                    onSubmitted: (_) => _queryDoh(),
                                  ),
                                  if (_dohResult != null) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          size: 18,
                                          color: colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            l10n.netDohResultDisplay(
                                              _dohController.text,
                                              _dohResult!,
                                            ),
                                            style: const TextStyle(
                                              fontFeatures: [
                                                FontFeature.tabularFigures(),
                                              ],
                                            ),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: _applyDohResult,
                                          child: Text(l10n.netSaveAsMapping),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 32),

                                    
                        _buildSectionTitle(context, l10n.netHeadersSection),
                        const SizedBox(height: 12),
                        ...buildMorphSegmentedList([
                          MorphRowItem(
                            flashKey: 'referer',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.http_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text('Referer'),
                              subtitle: Text(
                                service.referer.isEmpty
                                    ? l10n.netRefererNotSet
                                    : service.referer,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onTap: () => _showHeaderEditor(
                                title: 'Referer',
                                hint: 'https://www.bilibili.com/',
                                controller: _refererController,
                                onSave: (value) => service.setReferer(value),
                              ),
                            ),
                          ),
                          MorphRowItem(
                            flashKey: 'user_agent',
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: Icon(
                                Icons.person_pin_outlined,
                                size: 26,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              title: const Text('User-Agent'),
                              subtitle: Text(
                                service.userAgent.isEmpty
                                    ? l10n.netNotSet
                                    : service.userAgent,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              onTap: () => _showHeaderEditor(
                                title: 'User-Agent',
                                hint:
                                    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                                controller: _userAgentController,
                                onSave: (value) => service.setUserAgent(value),
                              ),
                            ),
                          ),
                        ]),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestIndicator(String name) {
    final result = _results[name];
    if (result == null) {
      return Icon(
        Icons.circle_outlined,
        size: 22,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      );
    }
    final color = result.success
        ? Colors.green
        : Theme.of(context).colorScheme.error;
    return AppTooltip(
      message: result.message,
      child: Icon(
        result.success ? Icons.check_circle : Icons.cancel,
        size: 22,
        color: color,
      ),
    );
  }

  void _showHeaderEditor({
    required String title,
    required String hint,
    required TextEditingController controller,
    required ValueChanged<String> onSave,
  }) {
    HapticFeedback.lightImpact();
    final localController = TextEditingController(text: controller.text);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        final l10n = AppLocalizations.of(ctx);
        return AlertDialog(
          title: Text(l10n.netHeaderEditorTitle(title)),
          content: TextField(
            controller: localController,
            autocorrect: false,
            decoration: InputDecoration(hintText: hint, labelText: title),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final value = localController.text.trim();
                onSave(value);
                controller.text = value;
                Navigator.pop(ctx);
                _showSnack(l10n.netHeaderSaved(title));
              },
              child: Text(l10n.commonSave),
            ),
          ],
        );
      },
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
}
