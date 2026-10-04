import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import 'package:naviflash/services/webdav_service.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:naviflash/screens/webdav_settings_screen.dart';
import '../src/loading_indicator_m3e.dart';
import 'package:naviflash/l10n/app_localizations.dart';
import 'package:naviflash/l10n/l10n_helper.dart';
import 'package:naviflash/widgets/app_toast.dart';

                
class SubtitleTrackInfo {
  final String id;
  final String label;
  final String? uri;

  SubtitleTrackInfo({
    required this.id,
    required this.label,
    this.uri,
  });
}

                                           
                
                                                       
class SubtitlePanel extends StatefulWidget {
                                       
                                         
  final bool embedded;

  final Player player;

             
  final double fontSize;
  final Color fontColor;
  final Color bgColor;

                
  final bool dragEnabled;
  final VoidCallback onDragChanged;
  final VoidCallback onResetPosition;

           
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<Color> onFontColorChanged;
  final ValueChanged<Color> onBgColorChanged;

  const SubtitlePanel({
    super.key,
    required this.player,
    required this.fontSize,
    required this.fontColor,
    required this.bgColor,
    required this.dragEnabled,
    required this.onDragChanged,
    required this.onResetPosition,
    required this.onFontSizeChanged,
    required this.onFontColorChanged,
    required this.onBgColorChanged,
    this.embedded = false,
  });

  @override
  State<SubtitlePanel> createState() => _SubtitlePanelState();
}

class _SubtitlePanelState extends State<SubtitlePanel> {

                
    
                                    
                                             
  bool get _themed => widget.embedded;
  ColorScheme get _cs => Theme.of(context).colorScheme;

                
  Color get _fg => _themed ? _cs.onSurface : Colors.white;

                  
  Color get _fgMuted => _themed ? _cs.onSurfaceVariant : Colors.white70;

          
  Color get _line => _themed ? _cs.outlineVariant : Colors.white24;

  List<SubtitleTrackInfo> _tracks = [];
  String _activeTrackId = '';
  bool _isLoading = false;
  StreamSubscription? _tracksSub;

         
  static const _fontColors = [
    Colors.white,
    Colors.yellow,
    Colors.greenAccent,
    Colors.cyanAccent,
    Colors.redAccent,
  ];
  static const _bgColors = [
    Color(0x80000000),
    Color(0xCC000000),
    Color(0x00000000),
    Color(0x800033AA),
  ];

  @override
  void initState() {
    super.initState();
    _refreshTracks();
    _tracksSub = widget.player.stream.tracks.listen((_) {
      if (mounted) _refreshTracks();
    });
  }

  @override
  void dispose() {
    _tracksSub?.cancel();
    super.dispose();
  }

  void _refreshTracks() {
    final subtitleTracks = widget.player.state.tracks.subtitle;
    final current = widget.player.state.track.subtitle;

                                      
    final noId = SubtitleTrack.no().id;
    final autoId = SubtitleTrack.auto().id;

    final tracks = <SubtitleTrackInfo>[
      SubtitleTrackInfo(id: noId, label: L10n.current.subtitleOff),
      SubtitleTrackInfo(id: autoId, label: L10n.current.displayModeAuto),
    ];

    for (final t in subtitleTracks) {
      if (t.id == noId || t.id == autoId) continue;
      tracks.add(SubtitleTrackInfo(
        id: t.id,
        label: t.title ?? t.language ?? L10n.current.subtitleTrackFallback(t.id),

      ));
    }

    setState(() {
      _tracks = tracks;
      _activeTrackId = current.id;
    });
  }

  void _selectTrack(String trackId) {
    setState(() => _activeTrackId = trackId);

    final noId = SubtitleTrack.no().id;
    final autoId = SubtitleTrack.auto().id;

    if (trackId == noId) {
      widget.player.setSubtitleTrack(SubtitleTrack.no());
    } else if (trackId == autoId) {
      widget.player.setSubtitleTrack(SubtitleTrack.auto());
    } else {
      final all = widget.player.state.tracks.subtitle;
      final target = all.firstWhere(
        (t) => t.id == trackId,
        orElse: () => SubtitleTrack.no(),
      );
      widget.player.setSubtitleTrack(target);
    }
  }

  Future<void> _loadLocalSubtitle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['srt', 'ass', 'ssa', 'vtt', 'sub'],
    );
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final name = result.files.single.name;
    widget.player.setSubtitleTrack(
      SubtitleTrack.uri(filePath, title: name, language: 'ext'),
    );
    _refreshTracks();
    if (mounted) {
      final l10n = AppLocalizations.of(context);
      showAppToast(context, l10n.subtitleLoadedLocal(name));
    }
  }

  Future<void> _loadWebDavSubtitle() async {
    final webdav = context.read<WebDavService>();
    final l10n = AppLocalizations.of(context);
    if (!webdav.isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.subtitleWebdavNotConfigured),
            action: SnackBarAction(
              label: l10n.webdavGoLogin,
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const WebDavSettingsScreen(),
                ),
              ),
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    final subtitles = await webdav.listSubtitleFiles();
    if (mounted) setState(() => _isLoading = false);
    if (!mounted) return;

    if (subtitles.isEmpty) {
      showAppToast(context, l10n.subtitleWebdavFolderEmpty);
      return;
    }

    final selected = await showDialog<RemoteFileEntry>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(AppLocalizations.of(ctx).subtitleSelectFile),
        children: subtitles
            .map((sub) => SimpleDialogOption(
                  onPressed: () => Navigator.of(ctx).pop(sub),
                  child: Row(children: [
                    const Icon(Icons.subtitles, color: Colors.green, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(sub.name,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ]),
                ))
            .toList(),
      ),
    );
    if (selected == null) return;

                                                
    final url = webdav.getFileStreamUrl(selected.path);
    await _downloadAndApplySubtitle(url, webdav.getAuthHeaders(), selected.name);
  }

  Future<void> _downloadAndApplySubtitle(
    String url,
    Map<String, String> headers,
    String name,
  ) async {
    try {
      final client = await NetworkSettingsService.instance.getApiClient();
      final resp = await client
          .get(
            Uri.parse(url),
            headers: {
              ...headers,
              ...NetworkSettingsService.instance.apiHeaders,
            },
          )
          .timeout(const Duration(seconds: 20));
      if (resp.statusCode != 200) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          showAppToast(
            context,
            l10n.subtitleDownloadFailed(resp.statusCode),
          );
        }
        return;
      }
      final dir = await getTemporaryDirectory();
      final ext = name.contains('.') ? name.split('.').last : 'srt';
      final file = File(
          '${dir.path}/navi_sub_${DateTime.now().millisecondsSinceEpoch}.$ext');
      await file.writeAsBytes(resp.bodyBytes);
      if (!mounted) return;

      widget.player.setSubtitleTrack(
        SubtitleTrack.uri(file.path, title: name, language: 'webdav'),
      );
      _refreshTracks();
      final l10n = AppLocalizations.of(context);
      showAppToast(context, l10n.subtitleLoadedRemote(name));
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        showAppToast(context, l10n.subtitleLoadError(e.toString()));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.embedded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(l10n.subtitlePanelTitle,
                style: TextStyle(
                    color: _fg,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),

               
        ..._tracks.map((track) => RadioGroup<String>(
              groupValue: _activeTrackId,
              onChanged: (val) {
                if (val != null) _selectTrack(val);
              },
              child: RadioListTile<String>(
                title: Text(track.label,
                    style: TextStyle(color: _fg, fontSize: 13)),
                value: track.id,
                activeColor: Colors.blue,
                dense: true,
                visualDensity: VisualDensity.compact,
              ),
            )),

        Divider(color: _line),

               
        ListTile(
          leading: Icon(Icons.folder_open, color: _fgMuted, size: 20),
          title: Text(l10n.subtitleLoadLocal,
              style: TextStyle(color: _fg, fontSize: 13)),
          dense: true,
          onTap: _loadLocalSubtitle,
        ),
        ListTile(
          leading:
              Icon(Icons.cloud_download, color: _fgMuted, size: 20),
          title: Text(l10n.subtitleLoadWebdav,
              style: TextStyle(color: _fg, fontSize: 13)),
          dense: true,
          trailing: _isLoading
              ? const LoadingIndicatorM3E(
                  constraints: BoxConstraints(
                    minWidth: 16,
                    maxWidth: 16,
                    minHeight: 16,
                    maxHeight: 16,
                  ),
                )
              : null,
          onTap: _isLoading ? null : _loadWebDavSubtitle,
        ),

        Divider(color: _line),

             
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(l10n.subtitleFontSize,
                  style: TextStyle(color: _fgMuted, fontSize: 12)),
              const Spacer(),
              Text('${widget.fontSize.toInt()}',
                  style: TextStyle(color: _fg, fontSize: 12)),
            ]),
            Slider(
              value: widget.fontSize,
              min: 24,
              max: 96,
              divisions: 12,
              activeColor: Colors.blue,
              onChanged: widget.onFontSizeChanged,
            ),

            const SizedBox(height: 4),
            Text(l10n.subtitleFontColor,
                style: TextStyle(color: _fgMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: _fontColors
                  .map((c) => _ColorDot(
                        color: c,
                        selected: widget.fontColor.toARGB32() == c.toARGB32(),
                        onTap: () => widget.onFontColorChanged(c),
                      ))
                  .toList(),
            ),

            const SizedBox(height: 8),
            Text(l10n.subtitleBgColor,
                style: TextStyle(color: _fgMuted, fontSize: 12)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              children: _bgColors
                  .map((c) => _ColorDot(
                        color: c,
                        selected: widget.bgColor.toARGB32() == c.toARGB32(),
                        onTap: () => widget.onBgColorChanged(c),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 8),
          ]),
        ),

        Divider(color: _line),

                     
        SwitchListTile(
          secondary: Icon(
            Icons.drag_indicator,
            color: _fgMuted,
            size: 20,
          ),
          title: Text(l10n.subtitleDragToggle,
              style: TextStyle(color: _fg, fontSize: 13)),
          subtitle: Text(l10n.subtitleDragHint,
              style: TextStyle(color: _fgMuted, fontSize: 11)),
          value: widget.dragEnabled,
          activeThumbColor: Colors.blue,
          dense: true,
          onChanged: (_) => widget.onDragChanged(),
        ),
        ListTile(
          leading: Icon(Icons.restart_alt, color: _fgMuted, size: 20),
          title: Text(l10n.subtitlePositionReset,
              style: TextStyle(color: _fg, fontSize: 13)),
          dense: true,
          onTap: widget.onResetPosition,
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;
  const _ColorDot(
      {required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
              color: selected
                  ? Colors.blue
                  : Theme.of(context).colorScheme.outline,
              width: selected ? 2.5 : 1),
        ),
      ),
    );
  }
}