import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:naviflash/services/webdav_service.dart';
import 'package:naviflash/screens/webdav_settings_screen.dart';
import '../src/loading_indicator_m3e.dart';
import '../src/enums.dart';
import '../l10n/app_localizations.dart';
import 'package:naviflash/widgets/app_refresh_indicator.dart';

class WebDavPickResult {
  final String url;
  final String title;
  final Map<String, String> headers;
  final String? subtitleUrl;
  final String? subtitleName;
  final String? authenticatedUrl;

  WebDavPickResult({
    required this.url,
    required this.title,
    required this.headers,
    this.subtitleUrl,
    this.subtitleName,
    this.authenticatedUrl,
  });
}

class WebDavFilePickerDialog extends StatefulWidget {
  final String initialPath;

  const WebDavFilePickerDialog({super.key, this.initialPath = ''});

  static Future<WebDavPickResult?> show(BuildContext context,
      {String? initialPath}) {
    return showDialog<WebDavPickResult>(
      context: context,
      builder: (_) =>
          WebDavFilePickerDialog(initialPath: initialPath ?? ''),
    );
  }

                           
  static Future<List<RemoteFileEntry>?> showMultiSelect(BuildContext context,
      {String? initialPath}) {
    return showDialog<List<RemoteFileEntry>>(
      context: context,
      builder: (_) =>
          _WebDavMultiSelectDialog(initialPath: initialPath ?? ''),
    );
  }

  @override
  State<WebDavFilePickerDialog> createState() =>
      _WebDavFilePickerDialogState();
}

class _WebDavFilePickerDialogState extends State<WebDavFilePickerDialog> {
  List<RemoteFileEntry> _files = [];
  bool _isLoading = true;
  String _currentPath = '';
  final List<String> _pathHistory = [];
  RemoteFileEntry? _selectedVideo;
  RemoteFileEntry? _selectedSubtitle;

  @override
  void initState() {
    super.initState();
    final webdav = context.read<WebDavService>();
    _currentPath = widget.initialPath.isEmpty
        ? '${webdav.remoteBasePath}/videos'
        : widget.initialPath;
    _loadFiles();
  }

  Future<void> _loadFiles({bool showFullLoading = true}) async {
    if (showFullLoading) {
      setState(() => _isLoading = true);
    }
    final webdav = context.read<WebDavService>();
    final files = await webdav.listFiles(_currentPath);
    if (mounted) {
      setState(() {
        _files = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
                                                 
                                        
    await _loadFiles(showFullLoading: false);
  }

  void _navigateTo(String path) {
    _pathHistory.add(_currentPath);
    _currentPath = path;
    _loadFiles();
  }

  void _goBack() {
    if (_pathHistory.isNotEmpty) {
      _currentPath = _pathHistory.removeLast();
      _loadFiles();
    }
  }

  void _goToRoot() {
    final webdav = context.read<WebDavService>();
    _pathHistory.add(_currentPath);
    _currentPath = webdav.remoteBasePath;
    _loadFiles();
  }

  void _jumpTo(String path) {
    if (path == _currentPath) return;
    _pathHistory.add(_currentPath);
    _currentPath = path;
    _loadFiles();
  }

  Future<void> _showPathInputDialog() async {
    final controller = TextEditingController(text: _currentPath);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).webdavInputPath),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '/navi_backup/videos',
            prefixIcon: Icon(Icons.folder_open, size: 20),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(ctx).webdavGoTo),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      final normalized = result.startsWith('/') ? result : '/$result';
      _jumpTo(normalized);
    }
  }

  void _confirmSelection() {
    if (_selectedVideo == null) return;
    final webdav = context.read<WebDavService>();
    Navigator.of(context).pop(WebDavPickResult(
      url: webdav.getFileStreamUrl(_selectedVideo!.path),
      title: _selectedVideo!.name,
      headers: webdav.getAuthHeaders(),
      subtitleUrl: _selectedSubtitle != null
          ? webdav.getFileStreamUrl(_selectedSubtitle!.path)
          : null,
      subtitleName: _selectedSubtitle?.name,
      authenticatedUrl: webdav.getAuthenticatedUrl(_selectedVideo!.path),
    ));
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

                        
    if (!context.watch<WebDavService>().isConfigured) {
      return Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 500,
          height: 600,
          child: _WebDavLoginPrompt(
            message: AppLocalizations.of(context).webdavLoginRequired,
            subtitle: AppLocalizations.of(context).webdavLoginSubtitle,
          ),
        ),
      );
    }

    final pathSegments =
        _currentPath.split('/').where((s) => s.isNotEmpty).toList();

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
            GestureDetector(
              onTap: _showPathInputDialog,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.cloud_outlined),
                      onPressed: null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WebDAV',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentPath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_location_alt_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _loadFiles(showFullLoading: true),
                      tooltip: AppLocalizations.of(context).webdavRefresh,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2, vertical: 6),
                    child: ActionChip(
                      avatar: const Icon(Icons.home, size: 14),
                      label: Text(AppLocalizations.of(context).webdavRoot,
                          style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onPressed: _goToRoot,
                    ),
                  ),
                  if (_pathHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 6),
                      child: ActionChip(
                        avatar: const Icon(Icons.arrow_back, size: 14),
                        label: Text(
                            AppLocalizations.of(context).webdavParent,
                            style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        onPressed: _goBack,
                      ),
                    ),
                  ...pathSegments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final seg = entry.value;
                    final isLast = index == pathSegments.length - 1;
                    final segPath =
                        '/${pathSegments.sublist(0, index + 1).join('/')}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 1, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index > 0)
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ActionChip(
                            label: Text(
                              seg,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isLast
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isLast
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: isLast
                                ? theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.4)
                                : null,
                            onPressed: isLast
                                ? null
                                : () => _jumpTo(segPath),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: _onRefresh,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                child: _isLoading
                    ? ListView(
                        physics: const AppRefreshScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 80.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const LoadingIndicatorM3E(
                                  variant: LoadingIndicatorM3EVariant
                                      .defaultStyle,
                                  constraints: BoxConstraints(
                                    minWidth: 72.0,
                                    minHeight: 72.0,
                                    maxWidth: 72.0,
                                    maxHeight: 72.0,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Now Loading ...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : _files.isEmpty
                        ? ListView(
                            physics: const AppRefreshScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.folder_off_outlined,
                                        size: 48, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text(AppLocalizations.of(context).webdavFolderEmpty,
                                        style:
                                            const TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(AppLocalizations.of(context).webdavPullToRefresh,
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AppRefreshScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _files.length,
                            itemBuilder: (context, index) {
                              final file = _files[index];
                              final isSelected =
                                  _selectedVideo?.path == file.path;
                              final isSubSelected =
                                  _selectedSubtitle?.path == file.path;

                              if (file.isDirectory) {
                                return ListTile(
                                  leading: const Icon(Icons.folder,
                                      color: Colors.amber),
                                  title: Text(file.name),
                                  onTap: () => _navigateTo(file.path),
                                  trailing:
                                      const Icon(Icons.chevron_right),
                                );
                              }

                              final isVideo = file.isVideo;
                              final isSub = file.isSubtitle;

                              return ListTile(
                                leading: Icon(
                                  isVideo
                                      ? Icons.movie_outlined
                                      : Icons.subtitles_outlined,
                                  color: isVideo
                                      ? Colors.blue
                                      : Colors.green,
                                ),
                                title: Text(
                                  file.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isSelected || isSubSelected
                                        ? FontWeight.bold
                                        : null,
                                    color: isSelected
                                        ? Colors.blue
                                        : isSubSelected
                                            ? Colors.green
                                            : null,
                                  ),
                                ),
                                subtitle: Text(_formatSize(file.size)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected)
                                      const Icon(Icons.check_circle,
                                          color: Colors.blue, size: 20),
                                    if (isSubSelected)
                                      const Icon(Icons.check_circle,
                                          color: Colors.green, size: 20),
                                  ],
                                ),
                                selected: isSelected,
                                onTap: () {
                                  setState(() {
                                    if (isVideo) {
                                      _selectedVideo = file;
                                    } else if (isSub) {
                                      _selectedSubtitle = file;
                                    }
                                  });
                                },
                              );
                            },
                          ),
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_selectedVideo != null)
                          Text(' ${_selectedVideo!.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12)),
                        if (_selectedSubtitle != null)
                          Text(' ${_selectedSubtitle!.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.green)),
                        if (_selectedVideo == null)
                          Text(AppLocalizations.of(context).webdavSelectVideo,
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    icon: const Icon(Icons.play_arrow),
                    label: Text(AppLocalizations.of(context).webdavPlay),
                    onPressed:
                        _selectedVideo != null ? _confirmSelection : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

                                                              
                              
                                                              

class _WebDavMultiSelectDialog extends StatefulWidget {
  final String initialPath;

  const _WebDavMultiSelectDialog({this.initialPath = ''});

  @override
  State<_WebDavMultiSelectDialog> createState() =>
      _WebDavMultiSelectDialogState();
}

class _WebDavMultiSelectDialogState extends State<_WebDavMultiSelectDialog> {
  List<RemoteFileEntry> _files = [];
  bool _isLoading = true;
  String _currentPath = '';
  final List<String> _pathHistory = [];

                    
  final List<RemoteFileEntry> _selected = [];

  @override
  void initState() {
    super.initState();
    final webdav = context.read<WebDavService>();
    _currentPath = widget.initialPath.isEmpty
        ? '${webdav.remoteBasePath}/videos'
        : widget.initialPath;
    _loadFiles();
  }

  Future<void> _loadFiles({bool showFullLoading = true}) async {
    if (showFullLoading) {
      setState(() => _isLoading = true);
    }
    final webdav = context.read<WebDavService>();
    final files = await webdav.listFiles(_currentPath);
    if (mounted) {
      setState(() {
        _files = files;
        _isLoading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
                                                 
                                        
    await _loadFiles(showFullLoading: false);
  }

  void _navigateTo(String path) {
    _pathHistory.add(_currentPath);
    _currentPath = path;
    _loadFiles();
  }

  void _goBack() {
    if (_pathHistory.isNotEmpty) {
      _currentPath = _pathHistory.removeLast();
      _loadFiles();
    }
  }

  void _goToRoot() {
    final webdav = context.read<WebDavService>();
    _pathHistory.add(_currentPath);
    _currentPath = webdav.remoteBasePath;
    _loadFiles();
  }

  void _jumpTo(String path) {
    if (path == _currentPath) return;
    _pathHistory.add(_currentPath);
    _currentPath = path;
    _loadFiles();
  }

  Future<void> _showPathInputDialog() async {
    final controller = TextEditingController(text: _currentPath);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(ctx).webdavInputPath),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '/navi_backup/videos',
            prefixIcon: Icon(Icons.folder_open, size: 20),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(ctx).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(AppLocalizations.of(ctx).webdavGoTo),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null && result.isNotEmpty) {
      final normalized = result.startsWith('/') ? result : '/$result';
      _jumpTo(normalized);
    }
  }

  void _toggleSelect(RemoteFileEntry file) {
    setState(() {
      final idx = _selected.indexWhere((f) => f.path == file.path);
      if (idx >= 0) {
        _selected.removeAt(idx);
      } else {
        _selected.add(file);
      }
    });
  }

  void _confirm() {
    if (_selected.isEmpty) return;
    Navigator.of(context).pop(_selected.toList());
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

                        
    if (!context.watch<WebDavService>().isConfigured) {
      return Dialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 500,
          height: 600,
          child: _WebDavLoginPrompt(
            message: AppLocalizations.of(context).webdavLoginRequired,
            subtitle: AppLocalizations.of(context).webdavLoginSubtitleMulti,
          ),
        ),
      );
    }

    final pathSegments =
        _currentPath.split('/').where((s) => s.isNotEmpty).toList();

    return Dialog(
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 500,
        height: 600,
        child: Column(
          children: [
                          
            GestureDetector(
              onTap: _showPathInputDialog,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.checklist, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context).webdavMultiSelectTitle,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _currentPath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.edit_location_alt_outlined,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: () => _loadFiles(showFullLoading: true),
                      tooltip: AppLocalizations.of(context).webdavRefresh,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),

                            
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 2, vertical: 6),
                    child: ActionChip(
                      avatar: const Icon(Icons.home, size: 14),
                      label: Text(AppLocalizations.of(context).webdavRoot,
                          style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onPressed: _goToRoot,
                    ),
                  ),
                  if (_pathHistory.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 2, vertical: 6),
                      child: ActionChip(
                        avatar: const Icon(Icons.arrow_back, size: 14),
                        label: Text(
                            AppLocalizations.of(context).webdavParent,
                            style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        onPressed: _goBack,
                      ),
                    ),
                  ...pathSegments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final seg = entry.value;
                    final isLast = index == pathSegments.length - 1;
                    final segPath =
                        '/${pathSegments.sublist(0, index + 1).join('/')}';
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 1, vertical: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (index > 0)
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ActionChip(
                            label: Text(
                              seg,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isLast
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isLast
                                    ? theme.colorScheme.primary
                                    : null,
                              ),
                            ),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            backgroundColor: isLast
                                ? theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.4)
                                : null,
                            onPressed: isLast
                                ? null
                                : () => _jumpTo(segPath),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const Divider(height: 1),

                           
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: _onRefresh,
                color: theme.colorScheme.primary,
                backgroundColor: theme.colorScheme.surface,
                child: _isLoading
                    ? ListView(
                        physics: const AppRefreshScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 80.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const LoadingIndicatorM3E(
                                  variant: LoadingIndicatorM3EVariant
                                      .defaultStyle,
                                  constraints: BoxConstraints(
                                    minWidth: 72.0,
                                    minHeight: 72.0,
                                    maxWidth: 72.0,
                                    maxHeight: 72.0,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Now Loading ...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : _files.isEmpty
                        ? ListView(
                            physics: const AppRefreshScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            children: [
                              const SizedBox(height: 120),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.folder_off_outlined,
                                        size: 48, color: Colors.grey),
                                    const SizedBox(height: 12),
                                    Text(AppLocalizations.of(context).webdavFolderEmpty,
                                        style:
                                            const TextStyle(color: Colors.grey)),
                                    const SizedBox(height: 4),
                                    Text(AppLocalizations.of(context).webdavPullToRefresh,
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AppRefreshScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding:
                                const EdgeInsets.symmetric(vertical: 4),
                            itemCount: _files.length,
                            itemBuilder: (context, index) {
                              final file = _files[index];

                                       
                              if (file.isDirectory) {
                                return ListTile(
                                  leading: const Icon(Icons.folder,
                                      color: Colors.amber),
                                  title: Text(file.name),
                                  onTap: () => _navigateTo(file.path),
                                  trailing:
                                      const Icon(Icons.chevron_right),
                                );
                              }

                                        
                              if (!file.isVideo) {
                                return const SizedBox.shrink();
                              }

                              final selIdx = _selected
                                  .indexWhere((f) => f.path == file.path);
                              final isSelected = selIdx >= 0;

                              return ListTile(
                                leading: CircleAvatar(
                                  radius: 16,
                                  backgroundColor: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.surfaceContainerHigh,
                                  child: isSelected
                                      ? Text(
                                          '${selIdx + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Icon(
                                          Icons.movie_outlined,
                                          size: 18,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                ),
                                title: Text(
                                  file.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : null,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : null,
                                  ),
                                ),
                                subtitle: Text(
                                  _formatSize(file.size),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: isSelected
                                    ? const Icon(Icons.check_circle,
                                        color: Colors.blue, size: 20)
                                    : null,
                                selected: isSelected,
                                onTap: () => _toggleSelect(file),
                              );
                            },
                          ),
              ),
            ),
            const Divider(height: 1),

                            
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selected.isEmpty
                              ? AppLocalizations.of(context).webdavNoSelection
                              : AppLocalizations.of(context)
                                  .webdavSelectedCount(_selected.length),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _selected.isEmpty
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.primary,
                          ),
                        ),
                        if (_selected.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              AppLocalizations.of(context).webdavSelectionOrder(
                                  '${_selected.map((f) => f.name).take(3).join(', ')}${_selected.length > 3 ? ' ...' : ''}'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_selected.isNotEmpty)
                    TextButton(
                      onPressed: () => setState(() => _selected.clear()),
                      child: Text(AppLocalizations.of(context).webdavClear),
                    ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    icon: const Icon(Icons.check, size: 18),
                    label: Text(AppLocalizations.of(context).webdavConfirmSelection),
                    onPressed: _selected.isNotEmpty ? _confirm : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

                                                              
                                       
                                                              

class _WebDavLoginPrompt extends StatelessWidget {
  final String message;
  final String subtitle;

  const _WebDavLoginPrompt({
    this.message = '',
    this.subtitle = '',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_off_outlined,
          size: 56,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Text(
          message,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          icon: const Icon(Icons.login, size: 18),
          label: Text(l10n.webdavGoLogin),
          onPressed: () {
            final navigator = Navigator.of(context);
            navigator.pop();
            navigator.push(
              MaterialPageRoute(
                builder: (_) => const WebDavSettingsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.commonCancel),
        ),
      ],
    );
  }
}