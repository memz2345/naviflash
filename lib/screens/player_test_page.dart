                                    
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/playlist_create_dialog.dart';
import 'package:naviflash/widgets/playlist_list_screen.dart';
import 'package:naviflash/widgets/widgets.dart';
import 'package:naviflash/widgets/webdav_file_picker.dart';
import 'package:naviflash/screens/player.dart';
import 'package:naviflash/l10n/app_localizations.dart';

class PlayerTestPage extends StatefulWidget {
  const PlayerTestPage({super.key});

  @override
  State<PlayerTestPage> createState() => _PlayerTestPageState();
}

class _PlayerTestPageState extends State<PlayerTestPage> {
  String? _lastPlayedTitle;
  String? _lastPlayedSource;
  DateTime? _lastPlayedTime;

  Future<void> _openWebDavVideo() async {
    final result = await WebDavFilePickerDialog.show(context);
    if (result == null || !mounted) return;

    _recordHistory(result.title, 'WebDAV');

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MpvPlayerPage(
          videoUrl: result.url,
          httpHeaders: result.headers,
          subtitleUrl: result.subtitleUrl,
          subtitleName: result.subtitleName,
        ),
      ),
    );
  }

  Future<void> _openLocalVideo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (result == null || result.files.single.path == null) return;

    final filePath = result.files.single.path!;
    final fileName = result.files.single.name;

    if (!mounted) return;
    _recordHistory(fileName, AppLocalizations.of(context).testSourceLocal);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MpvPlayerPage(
          videoUrl: filePath,
        ),
      ),
    );
  }
  void _openPlaylistPage() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlaylistListScreen()),
    );
  }

  Future<void> _createPlaylist() async {
    final created = await PlaylistCreateDialog.show(context);
    if (created != null && mounted) {
      showAppToast(
          context,
          AppLocalizations.of(context).testPlaylistCreated(created.name));
    }
  }
  void _recordHistory(String title, String source) {
    setState(() {
      _lastPlayedTitle = title;
      _lastPlayedSource = source;
      _lastPlayedTime = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
                                    
          ExpressiveSliverAppBar(
            title: l10n.testPageTitle,
            leading: MorphIconButton(
              icon: Icons.arrow_back,
              tooltip: l10n.homeBack,
              onTap: () => Navigator.of(context).pop(),
            ),
            
          ),

                      
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

                                    
                  _SectionHeader(
                    icon: Icons.play_circle_outline,
                    title: l10n.testVideoSourceSection,
                    subtitle: l10n.testVideoSourceSubtitle,
                  ),
                  const SizedBox(height: 12),

                                    
                  ...buildMorphSegmentedList([
                    MorphRowItem(
                      child: _SourceTile(
                        icon: Icons.cloud_outlined,
                        iconColor: Colors.blue,
                        title: l10n.testWebdavVideo,
                        subtitle: l10n.testWebdavVideoDesc,
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: _openWebDavVideo,
                      ),
                    ),
                    MorphRowItem(
                      child: _SourceTile(
                        icon: Icons.folder_open,
                        iconColor: Colors.amber.shade700,
                        title: l10n.testLocalVideo,
                        subtitle: l10n.testLocalVideoDesc,
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: _openLocalVideo,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 32),

                                    
                  _SectionHeader(
                    icon: Icons.history,
                    title: l10n.testRecentSection,
                    subtitle: _lastPlayedTitle != null
                        ? l10n.testLastPlayedSubtitle
                        : l10n.testNoRecords,
                  ),
                  const SizedBox(height: 12),

                                 
                  MorphItem(
                    selected: false,
                    isFirst: true,
                    isLast: true,
                    interactive: _lastPlayedTitle != null,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _lastPlayedTitle != null
                          ? _buildHistoryContent(cs)
                          : _buildEmptyHistory(cs),
                    ),
                  ),

          const SizedBox(height: 32),

                       
          _SectionHeader(
            icon: Icons.queue_music,
            title: l10n.testPlaylistSection,
            subtitle: l10n.testPlaylistSectionSubtitle,
          ),
          const SizedBox(height: 12),
          ...buildMorphSegmentedList([
            MorphRowItem(
              child: _SourceTile(
                icon: Icons.queue_music,
                iconColor: Colors.purple,
                title: l10n.testPlaylistManage,
                subtitle: l10n.testPlaylistManageDesc,
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _openPlaylistPage,
              ),
            ),
            MorphRowItem(
              child: _SourceTile(
                icon: Icons.playlist_add,
                iconColor: Colors.teal,
                title: l10n.testPlaylistCreate,
                subtitle: l10n.testPlaylistCreateDesc,
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: _createPlaylist,
              ),
            ),
          ]),

          const SizedBox(height: 32),
                            
          _SectionHeader(
            icon: Icons.bolt_outlined,
            title: l10n.testQuickActionsSection,
            subtitle: l10n.testQuickActionsSubtitle,
          ),
                                    
                  _SectionHeader(
                    icon: Icons.bolt_outlined,
                    title: l10n.testQuickActionsSection,
                    subtitle: l10n.testQuickActionsSubtitle,
                  ),
                  const SizedBox(height: 12),

                  ...buildMorphSegmentedList([
                    MorphRowItem(
                      child: _SourceTile(
                        icon: Icons.link,
                        iconColor: Colors.teal,
                        title: l10n.testUrlDirectPlay,
                        subtitle: l10n.testUrlDirectPlayDesc,
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: _openUrlDialog,
                      ),
                    ),
                    MorphRowItem(
                      child: _SourceTile(
                        icon: Icons.subtitles_outlined,
                        iconColor: Colors.green,
                        title: l10n.testVideoWithSubtitle,
                        subtitle: l10n.testVideoWithSubtitleDesc,
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: _openVideoWithSubtitle,
                      ),
                    ),
                  ]),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryContent(ColorScheme cs) {
    final timeStr = _lastPlayedTime != null
        ? '${_lastPlayedTime!.hour.toString().padLeft(2, '0')}:'
            '${_lastPlayedTime!.minute.toString().padLeft(2, '0')}'
        : '';

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(kItemRadius),
          ),
          child: Icon(
            _lastPlayedSource == 'WebDAV'
                ? Icons.cloud_outlined
                : Icons.folder_open,
            color: cs.onPrimaryContainer,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _lastPlayedTitle!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Text(
                '$_lastPlayedSource · $timeStr',
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.play_circle_filled,
          color: cs.primary,
          size: 28,
        ),
      ],
    );
  }

  Widget _buildEmptyHistory(ColorScheme cs) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(kItemRadius),
          ),
          child: Icon(
            Icons.movie_outlined,
            color: cs.onSurfaceVariant,
            size: 22,
          ),
        ),
        const SizedBox(width: 14),
        Text(
          AppLocalizations.of(context).testNoVideoPlayed,
          style: TextStyle(
            fontSize: 14,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Future<void> _openUrlDialog() async {
    final controller = TextEditingController();
    final l10n = AppLocalizations.of(context);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.testEnterUrlTitle),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'https://example.com/video.mp4',
            prefixIcon: Icon(Icons.link, size: 20),
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.testPlay),
          ),
        ],
      ),
    );
    controller.dispose();

    if (result == null || result.isEmpty || !mounted) return;

    _recordHistory(result, 'URL');

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MpvPlayerPage(videoUrl: result),
      ),
    );
  }

  Future<void> _openVideoWithSubtitle() async {
           
    final videoResult = await FilePicker.platform.pickFiles(
      type: FileType.video,
    );
    if (videoResult == null || videoResult.files.single.path == null) return;

    final videoPath = videoResult.files.single.path!;
    final videoName = videoResult.files.single.name;

    if (!mounted) return;

               
    final l10n = AppLocalizations.of(context);
    final addSub = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.testAddSubtitleTitle),
        content: Text(l10n.testAddSubtitlePrompt(videoName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.testSkip),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.testSelectSubtitle),
          ),
        ],
      ),
    );

    String? subtitlePath;
    if (addSub == true && mounted) {
      final subResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['srt', 'ass', 'ssa', 'vtt', 'sub'],
      );
      if (subResult != null && subResult.files.single.path != null) {
        subtitlePath = subResult.files.single.path;
      }
    }

    if (!mounted) return;
    _recordHistory(videoName, AppLocalizations.of(context).testSourceLocalSubtitle);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MpvPlayerPage(
          videoUrl: videoPath,
          subtitleUrl: subtitlePath,
        ),
      ),
    );
  }

}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SourceTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(kItemPressedRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(kItemRadius),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}