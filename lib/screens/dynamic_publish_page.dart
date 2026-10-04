                                        
                                
                                                     
                                    
                                                        
                                                      
                
                                                         
                                                           
                                            
                                                                         
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:naviflash/services/bilibili_account_service.dart';
import 'package:naviflash/screens/user_picker_page.dart';
import 'package:naviflash/services/bilibili_dynamics_service.dart';
import 'package:naviflash/services/bilibili_dynamic_opus_service.dart';
import 'package:naviflash/widgets/app_toast.dart';
import 'package:naviflash/widgets/page_background.dart';
import 'package:naviflash/widgets/topic_picker_sheet.dart';
import 'package:naviflash/widgets/ugc_rich_text.dart';

                       
enum DynamicPublishMode { text, vote, reserve }

class DynamicPublishPage extends StatefulWidget {
                           
  final String? repostDynId;

                  
  final String? repostPreview;

                 
  final String? repostAuthor;

                        
  final BiliDynEditDraft? editDraft;

                       
  final DynamicPublishMode initialMode;

  const DynamicPublishPage({
    super.key,
    this.repostDynId,
    this.repostPreview,
    this.repostAuthor,
    this.editDraft,
    this.initialMode = DynamicPublishMode.text,
  });

  bool get isRepost => repostDynId != null && repostDynId!.isNotEmpty;
  bool get isEdit => editDraft != null;

  @override
  State<DynamicPublishPage> createState() => _DynamicPublishPageState();
}

class _DynamicPublishPageState extends State<DynamicPublishPage> {
  static const int _maxImages = 9;
  static const int _maxVoteOptions = 16;
  static const int _minVoteOptions = 2;

  final TextEditingController _controller = TextEditingController();
  final List<XFile> _images = [];

                                   
  final TextEditingController _voteTitleController = TextEditingController();
  final TextEditingController _voteDescController = TextEditingController();
  final List<TextEditingController> _voteOptionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _voteDays = 3;

                                    
  final TextEditingController _reserveTitleController = TextEditingController();
  DateTime _reserveStart = DateTime.now().add(const Duration(days: 1));
  bool _reserveStartPicked = false;

                              
  List<BiliEditImage> _existingImages = [];
  bool _private = false;

                                 
  final List<PickedUser> _mentions = [];

                                          
  ({int id, String name})? _topic;
  bool _publishing = false;
  late DynamicPublishMode _mode = widget.initialMode;

  @override
  void initState() {
    super.initState();
    final draft = widget.editDraft;
    if (draft != null) {
      _controller.text = draft.text;
      _existingImages = List.of(draft.images);
      _private = draft.privatePub;
      if (draft.topicId > 0 && draft.topicName.isNotEmpty) {
        _topic = (id: draft.topicId, name: draft.topicName);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _voteTitleController.dispose();
    _voteDescController.dispose();
    for (final c in _voteOptionControllers) {
      c.dispose();
    }
    _reserveTitleController.dispose();
    super.dispose();
  }

                

  Future<void> _pickImages() async {
    try {
      final picked = await ImagePicker().pickMultiImage(
        limit: _maxImages - _images.length,
        imageQuality: 95,
      );
      if (picked.isEmpty || !mounted) return;
      setState(() {
        for (final f in picked) {
          if (_images.length >= _maxImages) break;
          _images.add(f);
        }
      });
    } catch (e) {
      if (mounted) showAppToast(context, '选择图片失败：$e', error: true);
    }
  }

                                               
  Future<void> _pickTopic() async {
    final picked = await showTopicPicker(context);
    if (!mounted || picked == null) return;
    setState(() => _topic = picked);
  }

                                   
  Future<void> _pickMention() async {
    final picked = await Navigator.of(context).push<List<PickedUser>>(
      MaterialPageRoute<List<PickedUser>>(
        builder: (_) => const UserPickerPage(multiSelect: true),
      ),
    );
    if (!mounted || picked == null || picked.isEmpty) return;
    for (final user in picked) {
      _insertMention(user);
    }
  }

                          
  void _insertMention(PickedUser user) {
    final text = _controller.text;
    final selection = _controller.selection;
    final at = selection.isValid ? selection.start : text.length;
    final token = '@${user.name} ';
    final newText = text.replaceRange(at, at, token);
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: at + token.length),
    );
    if (!_mentions.any((m) => m.mid == user.mid)) {
      _mentions.add((mid: user.mid, name: user.name));
    }
    setState(() {});
  }

             

  Future<void> _publish() async {
    if (_publishing) return;
    if (widget.isEdit) return _submitEdit();
    switch (_mode) {
      case DynamicPublishMode.vote:
        return _submitVote();
      case DynamicPublishMode.reserve:
        return _submitReserve();
      case DynamicPublishMode.text:
        return _submitText();
    }
  }

  Future<void> _submitText() async {
    final text = _controller.text.trim();
    if (!widget.isRepost && text.isEmpty && _images.isEmpty) {
      showAppToast(context, '说点什么吧', error: true);
      return;
    }
    if (!BilibiliAccountService.instance.isLoggedIn) {
      showAppToast(context, '还没有登录', error: true);
      return;
    }
    setState(() => _publishing = true);
    try {
                
      final uploaded = await _uploadImages();
      if (uploaded == null) return;
                   
      final res = await BilibiliDynamicsService.publishDynamic(
        text: text,
        images: uploaded,
        repostDynId: widget.repostDynId,
        mentions: _mentions,
        topic: _topic,
      );
      if (!mounted) return;
      if (!res.ok) {
        showAppToast(context, res.message, error: true);
        return;
      }
      showAppToast(context, widget.isRepost ? '转发成功' : '发布成功');
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

                                                         
  Future<List<({int width, int height, double size, String url})>?>
  _uploadImages() async {
    final uploaded = <({int width, int height, double size, String url})>[];
    for (final f in _images) {
      final r = await BilibiliDynamicsService.uploadImage(f.path);
      if (r == null) {
        if (mounted) showAppToast(context, '图片上传失败，请重试', error: true);
        return null;
      }
      uploaded.add(r);
    }
    return uploaded;
  }

                                   
  Future<void> _submitVote() async {
    final title = _voteTitleController.text.trim();
    final options = [
      for (final c in _voteOptionControllers) c.text.trim(),
    ].where((o) => o.isNotEmpty).toList();
    if (title.isEmpty) {
      showAppToast(context, '先写个投票标题', error: true);
      return;
    }
    if (options.length < _minVoteOptions) {
      showAppToast(context, '至少需要 $_minVoteOptions 个选项', error: true);
      return;
    }
    if (!BilibiliAccountService.instance.isLoggedIn) {
      showAppToast(context, '还没有登录', error: true);
      return;
    }
    setState(() => _publishing = true);
    try {
                                 
      final voteRes = await BilibiliDynamicOpusService.createVote(
        title: title,
        desc: _voteDescController.text.trim(),
        durationSec: _voteDays * 24 * 3600,
        options: options,
      );
      if (!mounted) return;
      if (voteRes.err != null || voteRes.voteId == null) {
        showAppToast(context, voteRes.err ?? '创建投票失败', error: true);
        return;
      }
                       
      final res = await BilibiliDynamicOpusService.publishVoteDynamic(
        text: title,
        voteId: voteRes.voteId!,
        voteTitle: title,
        mentions: _mentions,
      );
      if (!mounted) return;
      if (!res.ok) {
        showAppToast(context, res.message, error: true);
        return;
      }
      showAppToast(context, '投票发布成功');
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

                                    
  Future<void> _submitReserve() async {
    final title = _reserveTitleController.text.trim();
    if (title.isEmpty) {
      showAppToast(context, '先写个预约标题', error: true);
      return;
    }
    if (!BilibiliAccountService.instance.isLoggedIn) {
      showAppToast(context, '还没有登录', error: true);
      return;
    }
    setState(() => _publishing = true);
    try {
                  
      final reserveRes = await BilibiliDynamicOpusService.createReserve(
        title: title,
        startTs: _reserveStart.millisecondsSinceEpoch ~/ 1000,
      );
      if (!mounted) return;
      if (reserveRes.err != null || reserveRes.sid == null) {
        showAppToast(context, reserveRes.err ?? '创建预约失败', error: true);
        return;
      }
                      
      final res = await BilibiliDynamicOpusService.publishReserveDynamic(
        reserveSid: reserveRes.sid!,
        text: _controller.text.trim(),
      );
      if (!mounted) return;
      if (!res.ok) {
        showAppToast(context, res.message, error: true);
        return;
      }
      showAppToast(context, '预约动态发布成功');
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

                                     
  Future<void> _submitEdit() async {
    final draft = widget.editDraft!;
    final text = _controller.text.trim();
    if (text.isEmpty && _existingImages.isEmpty && _images.isEmpty) {
      showAppToast(context, '说点什么吧', error: true);
      return;
    }
    if (!BilibiliAccountService.instance.isLoggedIn) {
      showAppToast(context, '还没有登录', error: true);
      return;
    }
    setState(() => _publishing = true);
    try {
      final images = <({int width, int height, double size, String url})>[
        for (final e in _existingImages)
          (width: e.width, height: e.height, size: e.size, url: e.url),
      ];
      final uploaded = await _uploadImages();
      if (uploaded == null) return;
      images.addAll(uploaded);
      final res = await BilibiliDynamicOpusService.editDynamic(
        draft: draft,
        text: text,
        images: images,
        privatePub: _private,
      );
      if (!mounted) return;
      if (!res.ok) {
        showAppToast(context, res.message, error: true);
        return;
      }
      showAppToast(context, '编辑成功');
      Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

                 

  Future<void> _pickReserveStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _reserveStart,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_reserveStart),
    );
    if (time == null || !mounted) return;
    setState(() {
      _reserveStart = DateTime(date.year, date.month, date.day, time.hour, time.minute);
      _reserveStartPicked = true;
    });
  }

                                          
  void _setReserveQuick(int days) {
    final now = DateTime.now();
    setState(() {
      _reserveStart = DateTime(now.year, now.month, now.day + days, 20, 0);
      _reserveStartPicked = true;
    });
  }

             

  String get _title => widget.isEdit
      ? '编辑动态'
      : widget.isRepost
      ? '转发动态'
      : switch (_mode) {
          DynamicPublishMode.vote => '发起投票',
          DynamicPublishMode.reserve => '发布预约',
          DynamicPublishMode.text => '发布动态',
        };

  String get _submitLabel => widget.isEdit
      ? '保存'
      : widget.isRepost
      ? '转发'
      : switch (_mode) {
          DynamicPublishMode.vote => '发起投票',
          DynamicPublishMode.reserve => '发布预约',
          DynamicPublishMode.text => '发布',
        };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surfaceContainer,
      appBar: AppBar(
        title: Text(_title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _publishing ? null : _publish,
              child: _publishing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_submitLabel),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          PageBackground(baseColor: cs.surfaceContainer),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
                              
              if (!widget.isRepost && !widget.isEdit) ...[
                SegmentedButton<DynamicPublishMode>(
                  segments: const [
                    ButtonSegment(
                      value: DynamicPublishMode.text,
                      icon: Icon(Icons.edit_note_outlined, size: 18),
                      label: Text('文字'),
                    ),
                    ButtonSegment(
                      value: DynamicPublishMode.vote,
                      icon: Icon(Icons.bar_chart_rounded, size: 18),
                      label: Text('投票'),
                    ),
                    ButtonSegment(
                      value: DynamicPublishMode.reserve,
                      icon: Icon(Icons.alarm_add_outlined, size: 18),
                      label: Text('预约'),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() => _mode = s.first),
                  showSelectedIcon: false,
                ),
                const SizedBox(height: 12),
              ],
              ...switch (_mode) {
                DynamicPublishMode.vote => _buildVoteForm(cs),
                DynamicPublishMode.reserve => _buildReserveForm(cs),
                DynamicPublishMode.text => _buildTextForm(cs),
              },
            ],
          ),
        ],
      ),
    );
  }

                       

  List<Widget> _buildTextForm(ColorScheme cs) {
    return [
      TextField(
        controller: _controller,
        autofocus: !widget.isRepost && !widget.isEdit,
        maxLines: null,
        minLines: 5,
        maxLength: 2000,
        decoration: InputDecoration(
          hintText: widget.isRepost ? '转发语（可留空）' : '说点什么吧',
          border: InputBorder.none,
          counterStyle: TextStyle(
            color: cs.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        style: const TextStyle(fontSize: 15, height: 1.5),
      ),
      Row(
        children: [
          TextButton.icon(
            onPressed: _publishing ? null : _pickMention,
            icon: const Icon(Icons.alternate_email, size: 18),
            label: const Text('@ 提到谁'),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: _publishing ? null : _pickTopic,
            icon: const Icon(Icons.tag, size: 18),
            label: const Text('# 话题'),
          ),
        ],
      ),
                        
      if (_topic != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              label: Text('#${_topic!.name}'),
              avatar: const Icon(Icons.tag, size: 16),
              onDeleted: widget.isEdit ? null : () => setState(() => _topic = null),
              deleteIconColor: cs.onSurfaceVariant,
            ),
          ),
        ),
      if (widget.isRepost && widget.repostPreview != null) ...[
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if ((widget.repostAuthor ?? '').isNotEmpty)
                Text(
                  '@${widget.repostAuthor}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cs.primary,
                  ),
                ),
              UgcRichText(
                text: widget.repostPreview!,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.45,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ] else ...[
        const SizedBox(height: 8),
                   
        if (widget.isEdit)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('仅自己可见', style: TextStyle(fontSize: 14)),
            value: _private,
            onChanged: _publishing
                ? null
                : (v) => setState(() => _private = v),
          ),
                                 
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < _existingImages.length; i++)
              _existingThumb(cs, i),
            for (var i = 0; i < _images.length; i++) _thumb(cs, i),
            if (_existingImages.length + _images.length < _maxImages)
              InkWell(
                onTap: _pickImages,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: cs.outlineVariant,
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 28,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          widget.isEdit
              ? '已保存的图片可直接保留，新加图片发布时自动上传'
              : '最多 $_maxImages 张图片（发布时自动上传）',
          style: TextStyle(
            fontSize: 11,
            color: cs.onSurfaceVariant,
          ),
        ),
      ],
    ];
  }

             

  List<Widget> _buildVoteForm(ColorScheme cs) {
    return [
      TextField(
        controller: _voteTitleController,
        autofocus: true,
        maxLines: null,
        minLines: 1,
        maxLength: 100,
        decoration: InputDecoration(
          hintText: '投票标题（将作为动态文字发布）',
          border: InputBorder.none,
          counterStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      TextField(
        controller: _voteDescController,
        maxLines: null,
        minLines: 1,
        maxLength: 200,
        decoration: InputDecoration(
          hintText: '投票说明（可留空）',
          border: InputBorder.none,
          counterStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
        ),
        style: const TextStyle(fontSize: 14),
      ),
      const SizedBox(height: 8),
      Text(
        '投票选项（$_minVoteOptions-$_maxVoteOptions 个）',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 6),
      for (var i = 0; i < _voteOptionControllers.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _voteOptionControllers[i],
                  maxLength: 50,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: '选项 ${i + 1}',
                    border: const OutlineInputBorder(),
                    counterText: '',
                  ),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              if (_voteOptionControllers.length > _minVoteOptions) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _publishing
                      ? null
                      : () => setState(() {
                          _voteOptionControllers.removeAt(i).dispose();
                        }),
                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                  color: cs.onSurfaceVariant,
                  tooltip: '删除选项',
                ),
              ],
            ],
          ),
        ),
      if (_voteOptionControllers.length < _maxVoteOptions)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _publishing
                ? null
                : () => setState(
                    () => _voteOptionControllers.add(TextEditingController()),
                  ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('添加选项'),
          ),
        ),
      const SizedBox(height: 12),
      Text(
        '投票时长',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 6),
      SegmentedButton<int>(
        segments: const [
          ButtonSegment(value: 1, label: Text('1 天')),
          ButtonSegment(value: 3, label: Text('3 天')),
          ButtonSegment(value: 7, label: Text('7 天')),
        ],
        selected: {_voteDays},
        onSelectionChanged: _publishing
            ? null
            : (s) => setState(() => _voteDays = s.first),
        showSelectedIcon: false,
      ),
      const SizedBox(height: 8),
      Text(
        '文字投票 · 单选 · 截止后不可再投',
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
      ),
    ];
  }

             

  List<Widget> _buildReserveForm(ColorScheme cs) {
    String two(int n) => n.toString().padLeft(2, '0');
    final start =
        '${_reserveStart.year}-${two(_reserveStart.month)}-'
        '${two(_reserveStart.day)} ${two(_reserveStart.hour)}:${two(_reserveStart.minute)}';
    return [
      TextField(
        controller: _reserveTitleController,
        autofocus: true,
        maxLength: 50,
        decoration: InputDecoration(
          hintText: '预约标题（直播预约）',
          border: InputBorder.none,
          counterStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
        ),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      TextField(
        controller: _controller,
        maxLines: null,
        minLines: 3,
        maxLength: 2000,
        decoration: InputDecoration(
          hintText: '动态文字 / 说明（可留空）',
          border: InputBorder.none,
          counterStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
        ),
        style: const TextStyle(fontSize: 15, height: 1.5),
      ),
      const SizedBox(height: 8),
      ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(Icons.event_outlined, color: cs.primary),
        title: const Text('预约开始时间', style: TextStyle(fontSize: 14)),
        subtitle: Text(start, style: const TextStyle(fontSize: 13)),
        trailing: const Icon(Icons.chevron_right),
        onTap: _publishing ? null : _pickReserveStart,
      ),
      const SizedBox(height: 4),
      Text(
        '快捷时长',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        children: [
          for (final (days, label) in [(1, '1 天后'), (3, '3 天后'), (7, '7 天后')])
            OutlinedButton(
              onPressed: _publishing ? null : () => _setReserveQuick(days),
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: _reserveStartPicked &&
                          _isQuickSelected(days)
                      ? cs.primary
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        '发布后将带「直播预约」卡片，粉丝可一键预约',
        style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
      ),
    ];
  }

  bool _isQuickSelected(int days) {
    final now = DateTime.now();
    final expect = DateTime(now.year, now.month, now.day + days, 20, 0);
    return _reserveStart == expect;
  }

                

  Widget _thumb(ColorScheme cs, int index) {
    final file = _images[index];
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image(
            image: FileImage(File(file.path)),
            width: 86,
            height: 86,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 86,
              height: 86,
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.broken_image_outlined, color: cs.outline),
            ),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: InkWell(
            onTap: () => setState(() => _images.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

                                  
  Widget _existingThumb(ColorScheme cs, int index) {
    final img = _existingImages[index];
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image(
            image: NetworkImage(img.url),
            width: 86,
            height: 86,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 86,
              height: 86,
              color: cs.surfaceContainerHighest,
              child: Icon(Icons.broken_image_outlined, color: cs.outline),
            ),
          ),
        ),
        Positioned(
          right: 2,
          top: 2,
          child: InkWell(
            onTap: () => setState(() => _existingImages.removeAt(index)),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
