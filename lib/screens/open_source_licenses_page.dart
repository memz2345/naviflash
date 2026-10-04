                                             
  
                                                    
                                    
                                      

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../build_info.g.dart';
import '../services/oss_license_service.dart';
import '../widgets/expressive_app_bar.dart';
import '../widgets/morph_card.dart';
import '../widgets/page_background.dart';
import '../l10n/app_localizations.dart';
import 'oss_package_license_page.dart';

class OpenSourceLicensesPage extends StatefulWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const OpenSourceLicensesPage({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  @override
  State<OpenSourceLicensesPage> createState() => _OpenSourceLicensesPageState();
}

class _OpenSourceLicensesPageState extends State<OpenSourceLicensesPage> {
  final ScrollController _scrollCtrl = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final GlobalKey _searchKey = GlobalKey();

  OssLicenseData? _data;
  Object? _error;
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      final next = _searchCtrl.text;
      if (next == _query) return;
      setState(() => _query = next);
    });
    _load();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _load({bool refresh = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await loadOssLicenses(refresh: refresh);
      if (!mounted) return;
      setState(() {
        _data = data;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

                                           
  List<OssPackage> get _visiblePackages {
    final all = _data?.packages ?? const <OssPackage>[];
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return all;
    return [
      for (final pkg in all)
        if (pkg.name.toLowerCase().contains(query) ||
            (pkg.version ?? '').toLowerCase().contains(query) ||
            pkg.licenseIds.any((id) => id.toLowerCase().contains(query)))
          pkg,
    ];
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

                                          
  Future<void> _focusSearch() async {
    final ctx = _searchKey.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        alignment: 0.08,
      );
    } else if (_scrollCtrl.hasClients) {
      await _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
    if (mounted) _searchFocus.requestFocus();
  }

  void _openPackage(OssPackage pkg) {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OssPackageLicensePage(package: pkg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final searching = _query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer),
          CustomScrollView(
            controller: _scrollCtrl,
            physics: const ClampingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),                                                  
            slivers: [
              ExpressiveSliverAppBar(
                title: l10n.ossTitle,
                expandedHeight: 152,
                leading: widget.isSplitView
                    ? null
                    : MorphIconButton(
                        tooltip: l10n.ossBackTooltip,
                        icon: Icons.arrow_back,
                        onTap: _handleBack,
                      ),
                actions: [
                  MorphIconButton(
                    tooltip: l10n.ossSearchHint,
                    icon: Icons.search_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _focusSearch();
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildHeader(l10n),
                    const SizedBox(height: 16),
                    _buildSearchField(cs, l10n),
                    if (searching) ...[
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          '${l10n.ossDepsSection} · '
                          '${_visiblePackages.length} / ${_data?.packages.length ?? 0}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ]),
                ),
              ),
              _buildDepsSliver(cs, l10n),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: MediaQuery.of(context).padding.bottom + 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

                                           

  Widget _buildHeader(AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final count = _data?.packages.length ?? 0;
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NaviFlash',
            style: text.displaySmall?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Powered by Flutter ${BuildInfo.flutterVersion}',
            style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            '© 2026',
            style: text.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Text(
                                           
            _data == null
                ? l10n.ossLoading
                : l10n.ossPackagesCount(count, _data!.totalLicenses),
            style: text.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(ColorScheme cs, AppLocalizations l10n) {
    return MorphItem(
      selected: false,
      isFirst: true,
      isLast: true,
      interactive: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: TextField(
          key: _searchKey,
          controller: _searchCtrl,
          focusNode: _searchFocus,
          textInputAction: TextInputAction.search,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            hintText: l10n.ossSearchHint,
            hintStyle: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 38),
            suffixIcon: _query.isEmpty
                ? null
                : IconButton(
                    tooltip: l10n.ossClearSearch,
                    iconSize: 18,
                    icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                    onPressed: () => _searchCtrl.clear(),
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

               

                               
  Widget _buildDepsSliver(ColorScheme cs, AppLocalizations l10n) {
    if (_loading) {
      return _statusSliver(
        cs,
        text: l10n.ossLoading,
        showSpinner: true,
      );
    }
    if (_error != null) {
      return _statusSliver(
        cs,
        text: l10n.ossLoadFailed,
        onRetry: () => _load(refresh: true),
        retryLabel: l10n.ossRetry,
      );
    }
    final packages = _visiblePackages;
    if (packages.isEmpty) {
      return _statusSliver(
        cs,
        text: _query.trim().isEmpty ? l10n.ossLoadFailed : l10n.ossEmptySearch,
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList.builder(
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final pkg = packages[index];
          final isLast = index == packages.length - 1;
          return Padding(
                                                           
                                              
            padding: EdgeInsets.only(bottom: isLast ? 0 : kCardGap),
            child: MorphItem(
              selected: false,
              isFirst: index == 0,
              isLast: isLast,
              child: ListTile(
                title: Text(
                  pkg.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  l10n.ossLicensesCount(pkg.licenseCount),
                  style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (pkg.version != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          'v${pkg.version}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    const SizedBox(width: 6),
                    Icon(
                      Icons.chevron_right,
                      color: cs.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ),
                onTap: () => _openPackage(pkg),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _statusSliver(
    ColorScheme cs, {
    required String text,
    bool showSpinner = false,
    VoidCallback? onRetry,
    String? retryLabel,
  }) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverToBoxAdapter(
        child: MorphItem(
          selected: false,
          isFirst: true,
          isLast: true,
          interactive: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            child: Column(
              children: [
                if (showSpinner)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.2),
                  )
                else
                  Icon(
                    Icons.hourglass_empty_rounded,
                    size: 26,
                    color: cs.onSurfaceVariant,
                  ),
                const SizedBox(height: 12),
                Text(
                  text,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                if (onRetry != null) ...[
                  const SizedBox(height: 12),
                  TextButton(onPressed: onRetry, child: Text(retryLabel ?? '')),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
