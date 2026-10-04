                                              
  
                                                       
                                                           
                                         
                                                        
                                                    
                                                             
                                                     
                                                                    
  
                              
                                                                  
                                                                 
                    
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:provider/provider.dart';
import 'package:naviflash/widgets/app_tooltip.dart';

import '../l10n/app_localizations.dart';
import '../widgets/liquid_glass_menu_button.dart'
    show LiquidGlassMenuButton;
import '../widgets/search_video_menu.dart' show GlassMenuAction;
import '../services/ugc_filter_service.dart';
import '../services/windows_find_replace.dart';
import '../services/webdav_service.dart';
import '../widgets/app_toast.dart';
import '../widgets/page_background.dart';
import '../widgets/widgets.dart';

                                      
String ugcFilterScopeTitle(AppLocalizations l10n, UgcFilterScope scope) =>
    switch (scope) {
      UgcFilterScope.recommend => l10n.ugcFilterScopeRecommend,
      UgcFilterScope.zone => l10n.ugcFilterScopeZone,
      UgcFilterScope.reply => l10n.ugcFilterScopeReply,
      UgcFilterScope.dyn => l10n.ugcFilterScopeDyn,
    };

String ugcFilterScopeSubtitle(AppLocalizations l10n, UgcFilterScope scope) =>
    switch (scope) {
      UgcFilterScope.recommend => l10n.ugcFilterScopeRecommendSub,
      UgcFilterScope.zone => l10n.ugcFilterScopeZoneSub,
      UgcFilterScope.reply => l10n.ugcFilterScopeReplySub,
      UgcFilterScope.dyn => l10n.ugcFilterScopeDynSub,
    };

IconData ugcFilterScopeIcon(UgcFilterScope scope) => switch (scope) {
  UgcFilterScope.recommend => Icons.recommend_outlined,
  UgcFilterScope.zone => Icons.category_outlined,
  UgcFilterScope.reply => Icons.comment_outlined,
  UgcFilterScope.dyn => Icons.dynamic_feed_outlined,
};

                                           
         
                                           

class UgcFilterSettingsScreen extends StatelessWidget {
  final bool isSplitView;
  final VoidCallback? onBack;

  const UgcFilterSettingsScreen({
    super.key,
    this.isSplitView = false,
    this.onBack,
  });

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
            CustomScrollView(
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                ExpressiveSliverAppBar(
                  title: l10n.ugcFilterTitle,
                  expandedHeight: 152,
                  leading: isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.commonBackTooltip,
                          icon: Icons.arrow_back,
                          onTap: () => _handleBack(context),
                        ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _sectionTitle(context, l10n.ugcFilterSectionScopes),
                        const SizedBox(height: 12),
                        ListenableBuilder(
                          listenable: UgcFilterService.instance,
                          builder: (context, _) => Column(
                            children: buildMorphSegmentedList([
                              for (final scope in UgcFilterScope.values)
                                MorphRowItem(
                                  flashKey: 'ugc_filter_${scope.id}',
                                  child: ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 4,
                                        ),
                                    leading: Icon(
                                      ugcFilterScopeIcon(scope),
                                      size: 26,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    title: Text(
                                      ugcFilterScopeTitle(l10n, scope),
                                    ),
                                    subtitle: Text(
                                      ugcFilterScopeSubtitle(l10n, scope),
                                      style: TextStyle(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          l10n.ugcFilterRulesCount(
                                            UgcFilterService.instance.countOf(
                                              scope,
                                            ),
                                          ),
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.chevron_right,
                                          size: 20,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => UgcFilterScopeScreen(
                                            scope: scope,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                            ]),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            l10n.ugcFilterTip,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
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

  Widget _sectionTitle(BuildContext context, String title) => Text(
    title,
    textAlign: TextAlign.left,
    style: Theme.of(context).textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

                                           
                  
                                           

class UgcFilterScopeScreen extends StatefulWidget {
  const UgcFilterScopeScreen({
    super.key,
    required this.scope,
    this.isSplitView = false,
    this.onBack,
  });

  final UgcFilterScope scope;
  final bool isSplitView;
  final VoidCallback? onBack;

  @override
  State<UgcFilterScopeScreen> createState() => _UgcFilterScopeScreenState();
}

class _UgcFilterScopeScreenState extends State<UgcFilterScopeScreen> {
  final TextEditingController _addController = TextEditingController();
  final TextEditingController _findController = TextEditingController();
  final TextEditingController _replaceController = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _panelOpen = false;
  bool _caseSensitive = false;
  bool _wholeWord = false;
  bool _regex = false;

                       
  List<int> _matches = const <int>[];
  int _cursor = -1;

                                      
  final List<String> _findHistory = <String>[];
  final List<String> _replaceHistory = <String>[];

  UgcFilterService get _service => UgcFilterService.instance;
  UgcFilterScope get _scope => widget.scope;

  @override
  void dispose() {
    _addController.dispose();
    _findController.dispose();
    _replaceController.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _handleBack() {
    if (widget.onBack != null) {
      widget.onBack!();
    } else {
      Navigator.of(context).pop();
    }
  }

                                      

  Future<void> _addRule() async {
    final text = _addController.text.trim();
    if (text.isEmpty) return;
    if (!UgcFilterService.isValidRule(text)) {
      showAppToast(context, AppLocalizations.of(context).ugcFilterInvalid);
      return;
    }
    final added = await _service.addRules(
      _scope,
      UgcFilterService.splitRules(text),
    );
    if (!mounted) return;
    if (added == 0) {
      showAppToast(context, AppLocalizations.of(context).ugcFilterDup);
      return;
    }
    _addController.clear();
    showAppToast(
      context,
      AppLocalizations.of(context).ugcFilterAdded(added),
    );
    _recomputeMatches();
  }

  Future<void> _editRule(int index) async {
    final rules = _service.rulesOf(_scope);
    if (index < 0 || index >= rules.length) return;
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: rules[index]);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => _RuleEditDialog(
        title: l10n.ugcFilterEdit,
        initial: rules[index],
        controller: controller,
      ),
    );
    if (result == null) return;
    final trimmed = result.trim();
    if (trimmed.isEmpty || trimmed == rules[index]) return;
    if (!UgcFilterService.isValidRule(trimmed)) {
      if (mounted) showAppToast(context, l10n.ugcFilterInvalid);
      return;
    }
    await _service.removeAt(_scope, <int>[index]);
    await _service.addRules(_scope, <String>[trimmed]);
    _recomputeMatches();
  }

  Future<void> _deleteRule(int index) async {
    final l10n = AppLocalizations.of(context);
    await _service.removeAt(_scope, <int>[index]);
    if (!mounted) return;
    showAppToast(context, l10n.ugcFilterDeleted);
    _recomputeMatches();
  }

  Future<void> _clearAll() async {
    final l10n = AppLocalizations.of(context);
    await _service.clear(_scope);
    if (!mounted) return;
    showAppToast(context, l10n.ugcFilterCleared);
    _recomputeMatches();
  }

                                    

  void _recomputeMatches() {
    final find = _findController.text;
    if (find.isEmpty) {
      setState(() {
        _matches = const <int>[];
        _cursor = -1;
      });
      return;
    }
    _matches = _service.matchIndexes(
      _scope,
      find: find,
      isRegex: _regex,
      caseSensitive: _caseSensitive,
      wholeWord: _wholeWord,
    );
    _cursor = _matches.isEmpty ? -1 : 0;
    setState(() {});
    if (_cursor >= 0) _scrollTo(_cursor);
  }

  void _scrollTo(int index) {
    if (!_scroll.hasClients) return;
                                   
    final offset = (index * kRuleRowHeight).clamp(
      0.0,
      _scroll.position.maxScrollExtent,
    );
    _scroll.animateTo(
      offset.toDouble(),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
    );
  }

  void _moveCursor(int delta) {
    if (_matches.isEmpty) return;
    setState(() {
      _cursor = (_cursor + delta) % _matches.length;
    });
    _scrollTo(_matches[_cursor]);
  }

  Future<void> _replaceOne() async {
    if (_cursor < 0 || _cursor >= _matches.length) return;
    final l10n = AppLocalizations.of(context);
    final ok = await _service.replaceRuleAt(
      _scope,
      _matches[_cursor],
      find: _findController.text,
      replace: _replaceController.text,
      isRegex: _regex,
      caseSensitive: _caseSensitive,
      wholeWord: _wholeWord,
    );
    if (!mounted) return;
    showAppToast(context, ok ? l10n.ugcFilterReplaced(1) : l10n.ugcFilterNoResult);
    _recomputeMatches();
  }

  Future<void> _replaceAll() async {
    final l10n = AppLocalizations.of(context);
    final n = await _service.replaceInRules(
      _scope,
      find: _findController.text,
      replace: _replaceController.text,
      isRegex: _regex,
      caseSensitive: _caseSensitive,
      wholeWord: _wholeWord,
    );
    if (!mounted) return;
    showAppToast(
      context,
      n == 0 ? l10n.ugcFilterNoResult : l10n.ugcFilterReplaced(n),
    );
    _recomputeMatches();
  }

  Future<void> _deleteMatches() async {
    final l10n = AppLocalizations.of(context);
    final n = await _service.deleteMatching(
      _scope,
      find: _findController.text,
      isRegex: _regex,
      caseSensitive: _caseSensitive,
    );
    if (!mounted) return;
    showAppToast(
      context,
      n == 0 ? l10n.ugcFilterNoResult : l10n.ugcFilterDeletedMatches(n),
    );
    _recomputeMatches();
  }

  void _pushHistory() {
    final f = _findController.text.trim();
    final r = _replaceController.text.trim();
    if (f.isNotEmpty && !_findHistory.contains(f)) _findHistory.insert(0, f);
    if (r.isNotEmpty && !_replaceHistory.contains(r)) {
      _replaceHistory.insert(0, r);
    }
  }

                                    

  Future<void> _importFromClipboard() async {
    final l10n = AppLocalizations.of(context);
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text ?? '';
    if (text.trim().isEmpty) {
      if (mounted) showAppToast(context, l10n.ugcFilterImportEmpty);
      return;
    }
    await _doImport(text);
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      final file = result?.files.singleOrNull;
      if (file == null) return;
      final text = file.bytes != null
          ? utf8.decode(file.bytes!, allowMalformed: true)
          : file.path != null
          ? await File(file.path!).readAsString()
          : '';
      await _doImport(text);
    } catch (e) {
      if (mounted) {
        showAppToast(
          context,
          AppLocalizations.of(context).ugcFilterImportFailed('$e'),
        );
      }
    }
  }

                                           
  Future<void> _doImport(String text) async {
    final l10n = AppLocalizations.of(context);
    final rules = UgcFilterService.splitRules(text);
    if (rules.isEmpty) {
      if (mounted) showAppToast(context, l10n.ugcFilterImportEmpty);
      return;
    }
    final added = await _service.addRules(_scope, rules);
    if (!mounted) return;
    showAppToast(
      context,
      l10n.ugcFilterImported(added, rules.length - added),
    );
    _recomputeMatches();
  }

  Future<void> _export() async {
    final l10n = AppLocalizations.of(context);
    final text = _service.exportText(_scope);
    if (text.trim().isEmpty) {
      if (mounted) showAppToast(context, l10n.ugcFilterExportEmpty);
      return;
    }
    try {
      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}${Platform.pathSeparator}naviflash_${_scope.id}_filter.txt',
      );
      await file.writeAsString(text, flush: true);
      await SharePlus.instance.share(
        ShareParams(files: <XFile>[XFile(file.path)], text: text),
      );
    } catch (e) {
      if (mounted) showAppToast(context, l10n.ugcFilterExportFailed('$e'));
    }
  }

  Future<void> _exportToWebdav() async {
    final l10n = AppLocalizations.of(context);
    final text = _service.exportText(_scope);
    if (text.trim().isEmpty) {
      if (mounted) showAppToast(context, l10n.ugcFilterExportEmpty);
      return;
    }
    final webdav = context.read<WebDavService>();
    final name =
        'ugc_filter_${_scope.id}_${DateTime.now().toIso8601String().substring(0, 10)}.txt';
    final ok = await webdav.uploadBytes('naviflash/$name', utf8.encode(text));
    if (!mounted) return;
    showAppToast(
      context,
      ok ? l10n.ugcFilterWebdavOk(name) : l10n.ugcFilterWebdavFail(webdav.lastError),
    );
  }

                               

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final title = ugcFilterScopeTitle(l10n, _scope);

    return PopScope(
      canPop: widget.onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack();
      },
      child: Scaffold(
        backgroundColor: colorScheme.surfaceContainer,
        body: Stack(
          children: [
            PageBackground(baseColor: colorScheme.surfaceContainer),
            CustomScrollView(
              physics: const ClampingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                ExpressiveSliverAppBar(
                  title: title,
                  expandedHeight: 152,
                  leading: widget.isSplitView
                      ? null
                      : MorphIconButton(
                          tooltip: l10n.commonBackTooltip,
                          icon: Icons.arrow_back,
                          onTap: _handleBack,
                        ),
                  actions: <Widget>[
                                          
                    LiquidGlassMenuButton(
                      icon: Icons.more_vert,
                      tooltip: l10n.ugcFilterMenuMore,
                      menuWidth: 230,
                      actions: <GlassMenuAction>[
                        GlassMenuAction(
                          icon: Icons.content_paste_go_outlined,
                          text: l10n.ugcFilterMenuClipboard,
                          onTap: _importFromClipboard,
                        ),
                        GlassMenuAction(
                          icon: Icons.file_open_outlined,
                          text: l10n.ugcFilterMenuFile,
                          onTap: _importFromFile,
                        ),
                        GlassMenuAction(
                          icon: Icons.ios_share_outlined,
                          text: l10n.ugcFilterMenuExport,
                          onTap: _export,
                        ),
                        GlassMenuAction(
                          icon: Icons.cloud_upload_outlined,
                          text: l10n.ugcFilterMenuWebdav,
                          onTap: _exportToWebdav,
                        ),
                        GlassMenuAction(
                          icon: Icons.delete_sweep_outlined,
                          text: l10n.ugcFilterClear,
                          isDestructive: true,
                          onTap: _clearAll,
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                  ],
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAddRow(context),
                        const SizedBox(height: 12),
                        _buildFindToggle(context),
                        if (_panelOpen) ...[
                          const SizedBox(height: 12),
                          _buildFindPanel(context),
                        ],
                        const SizedBox(height: 12),
                        ListenableBuilder(
                          listenable: _service,
                          builder: (context, _) {
                            final rules = _service.rulesOf(_scope);
                            if (rules.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 32,
                                ),
                                child: Center(
                                  child: Text(
                                    l10n.ugcFilterEmpty,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              );
                            }
                            return LayoutBuilder(
                              builder: (context, constraints) {
                                return SizedBox(
                                  height: rules.length * kRuleRowHeight,
                                  child: ListView.builder(
                                    controller: _scroll,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: rules.length,
                                    itemBuilder: (context, i) =>
                                        _buildRuleRow(context, rules[i], i),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            l10n.ugcFilterTip,
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
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

                                          
  Widget _buildRuleRow(BuildContext context, String rule, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final valid = UgcFilterService.isValidRule(rule);
    final isCurrent = _matches.isNotEmpty &&
        _cursor >= 0 &&
        _cursor < _matches.length &&
        _matches[_cursor] == index;
    final isMatch = _matches.contains(index);

    return Container(
      height: kRuleRowHeight,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: isCurrent
            ? colorScheme.primary.withValues(alpha: 0.16)
            : isMatch
            ? colorScheme.primary.withValues(alpha: 0.07)
            : colorScheme.surfaceContainerHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(
            valid ? Icons.filter_alt_outlined : Icons.error_outline,
            size: 18,
            color: valid ? colorScheme.onSurfaceVariant : colorScheme.error,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              rule,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 14,
                color: valid
                    ? colorScheme.onSurface
                    : colorScheme.error,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 18),
            tooltip: l10n.ugcFilterEdit,
            onPressed: () => _editRule(index),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            tooltip: l10n.ugcFilterDelete,
            onPressed: () => _deleteRule(index),
          ),
        ],
      ),
    );
  }

                
  Widget _buildAddRow(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _addController,
            autocorrect: false,
            enableSuggestions: false,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              hintText: l10n.ugcFilterAddHint,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: (_) => _addRule(),
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.icon(
          onPressed: _addRule,
          icon: const Icon(Icons.add, size: 18),
          label: Text(l10n.ugcFilterAdd),
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.primary,
          ),
        ),
      ],
    );
  }

                 
  Widget _buildFindToggle(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: _onFindReplaceTap,
        icon: Icon(_panelOpen ? Icons.expand_less : Icons.find_in_page_outlined),
        label: Text(l10n.ugcFilterFindReplace),
      ),
    );
  }

                                                   
     
                                         
  Future<void> _onFindReplaceTap() async {
    HapticFeedback.lightImpact();
    if (WindowsFindReplace.isSupported) {
      final List<String>? edited = await WindowsFindReplace.show(
        l10n: AppLocalizations.of(context),
        rules: _service.rulesOf(_scope),
      );
      if (edited == null) return;              
      await _service.setRules(_scope, edited);
      _recomputeMatches();
      return;
    }
    setState(() => _panelOpen = !_panelOpen);
    if (_panelOpen) _recomputeMatches();
  }

                            
  Widget _buildFindPanel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final count = _matches.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
                                  
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.ugcFilterResultCount(count),
                  style: TextStyle(
                    fontSize: 12,
                    color: count == 0
                        ? colorScheme.error
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _toggleChip(
                label: 'Cc',
                selected: _caseSensitive,
                tooltip: l10n.ugcFilterCaseSensitive,
                onTap: () {
                  setState(() => _caseSensitive = !_caseSensitive);
                  _recomputeMatches();
                },
              ),
              _toggleChip(
                label: 'W',
                selected: _wholeWord,
                tooltip: l10n.ugcFilterWholeWord,
                onTap: () {
                  setState(() => _wholeWord = !_wholeWord);
                  _recomputeMatches();
                },
              ),
              _toggleChip(
                label: '.*',
                selected: _regex,
                tooltip: l10n.ugcFilterRegex,
                onTap: () {
                  setState(() => _regex = !_regex);
                  _recomputeMatches();
                },
              ),
            ],
          ),
          const SizedBox(height: 6),
               
          _buildFindField(
            controller: _findController,
            label: l10n.ugcFilterFind,
            history: _findHistory,
            onChanged: (_) => _recomputeMatches(),
          ),
          const SizedBox(height: 6),
               
          _buildFindField(
            controller: _replaceController,
            label: l10n.ugcFilterReplace,
            history: _replaceHistory,
            onChanged: (_) {
              _pushHistory();
              setState(() {});
            },
          ),
          const SizedBox(height: 4),
                                      
          Row(
            children: [
              TextButton(
                onPressed: count == 0 ? null : () => _moveCursor(-1),
                child: Text(l10n.ugcFilterPrev),
              ),
              TextButton(
                onPressed: count == 0 ? null : () => _moveCursor(1),
                child: Text(l10n.ugcFilterNext),
              ),
              const Spacer(),
              TextButton(
                onPressed: count == 0 ? null : _replaceOne,
                child: Text(l10n.ugcFilterReplaceOne),
              ),
              TextButton(
                onPressed: count == 0 ? null : _replaceAll,
                child: Text(l10n.ugcFilterReplaceAll),
              ),
              LiquidGlassMenuButton(
                icon: Icons.more_vert,
                tooltip: l10n.ugcFilterMenuMore,
                menuWidth: 210,
                actions: <GlassMenuAction>[
                  GlassMenuAction(
                    icon: Icons.delete_outline,
                    text: l10n.ugcFilterDeletedMatches(count),
                    isDestructive: count > 0,
                    onTap: _deleteMatches,
                  ),
                  GlassMenuAction(
                    icon: Icons.history_toggle_off_outlined,
                    text: l10n.ugcFilterClearHistory,
                    onTap: () => setState(() {
                      _findHistory.clear();
                      _replaceHistory.clear();
                    }),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool selected,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return AppTooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(left: 6),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

                                 
  Widget _buildFindField({
    required TextEditingController controller,
    required String label,
    required List<String> history,
    required ValueChanged<String> onChanged,
  }) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: TextField(
            controller: controller,
            autocorrect: false,
            enableSuggestions: false,
            style: const TextStyle(fontSize: 13),
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(),
            ),
            onChanged: onChanged,
          ),
        ),
        if (history.isNotEmpty)
          LiquidGlassMenuButton(
            icon: Icons.arrow_drop_down,
            tooltip: l10n.ugcFilterHistory,
            menuWidth: 200,
            actions: <GlassMenuAction>[
              for (final h in history.take(8))
                GlassMenuAction(
                  icon: Icons.history,
                  text: h,
                  onTap: () {
                    controller.text = h;
                    onChanged(h);
                  },
                ),
            ],
          ),
      ],
    );
  }
}

                        
const double kRuleRowHeight = 52.0;

                                                          
class _RuleEditDialog extends StatefulWidget {
  const _RuleEditDialog({
    required this.title,
    required this.initial,
    required this.controller,
  });

  final String title;
  final String initial;
  final TextEditingController controller;

  @override
  State<_RuleEditDialog> createState() => _RuleEditDialogState();
}

class _RuleEditDialogState extends State<_RuleEditDialog> {
  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: widget.controller,
        autofocus: true,
        autocorrect: false,
        enableSuggestions: false,
        maxLines: 3,
        minLines: 1,
        decoration: InputDecoration(
          hintText: l10n.ugcFilterAddHint,
          labelText: widget.title,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, widget.controller.text),
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
