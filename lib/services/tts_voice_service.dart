                                      
  
                                        
                                    
  
                                     
                                
import 'dart:convert';
import 'dart:io';

import 'package:naviflash/services/storage_paths.dart';
import 'package:naviflash/services/tts_model_service.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

           
class TtsVoice {
                        
  final String id;

                   
  final String name;

                  
  final String fileName;

                  
  final int createdAt;

  const TtsVoice({
    required this.id,
    required this.name,
    required this.fileName,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fileName': fileName,
        'createdAt': createdAt,
      };

  static TtsVoice? fromJson(Map<dynamic, dynamic> m) {
    final id = m['id']?.toString();
    final name = m['name']?.toString();
    final fileName = m['fileName']?.toString();
    if (id == null || name == null || fileName == null) return null;
    final createdAt = m['createdAt'] is int
        ? m['createdAt'] as int
        : int.tryParse('${m['createdAt']}') ?? 0;
    return TtsVoice(
      id: id,
      name: name,
      fileName: fileName,
      createdAt: createdAt,
    );
  }
}

                                                    
            
const Set<String> kTtsAudioExtensions = {
  'mp3',
  'wav',
  'm4a',
  'aac',
  'flac',
  'ogg',
  'opus',
  'wma',
};

class TtsVoiceService {
  TtsVoiceService._();

  static const String _prefsKey = 'ttsVoices';

                                     
  static const int maxBytes = 50 * 1024 * 1024;

             
  static Future<Directory> get voicesDir async {
    final root = await TtsModelService.ttsRoot;
    final dir = Directory(p.join(root.path, 'voices'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<List<TtsVoice>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw);
      if (list is! List) return const [];
      final out = <TtsVoice>[];
      for (final item in list) {
        if (item is Map) {
          final v = TtsVoice.fromJson(item);
          if (v != null) out.add(v);
        }
      }
      out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return out;
    } catch (_) {
      return const [];
    }
  }

  static Future<void> _saveAll(List<TtsVoice> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode(list.map((v) => v.toJson()).toList()),
    );
  }

                               
  static Future<List<Directory>> _candidateVoiceDirs() async {
    final roots = await StoragePaths.readRootsFor(StorageSlot.models);
    final out = <Directory>[];
    final seen = <String>{};
    for (final r in roots) {
      final path = p.normalize(p.join(r.path, 'tts', 'voices'));
      if (seen.add(path)) out.add(Directory(path));
    }
    return out;
  }

                                       
                         
  static Future<String> absolutePath(TtsVoice voice) async {
    for (final dir in await _candidateVoiceDirs()) {
      final f = File(p.join(dir.path, voice.fileName));
      if (await f.exists()) return f.path;
    }
    return p.join((await voicesDir).path, voice.fileName);
  }

  static const String _selectedKey = 'ttsSelectedVoiceId';

                                   
  static Future<String?> selectedId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_selectedKey);
    if (id == null || id.isEmpty) return null;
    final all = await loadAll();
    for (final v in all) {
      if (v.id == id) return id;
    }
    return null;
  }

                                 
  static Future<void> setSelectedId(String? id) async {
    final prefs = await SharedPreferences.getInstance();
    if (id == null || id.isEmpty) {
      await prefs.remove(_selectedKey);
      return;
    }
    await prefs.setString(_selectedKey, id);
  }

                             
                                      
  static Future<String?> selectedVoicePath() async {
    final id = await selectedId();
    if (id == null) return null;
    final all = await loadAll();
    for (final v in all) {
      if (v.id != id) continue;
      final path = await absolutePath(v);
      return File(path).existsSync() ? path : null;
    }
    return null;
  }

                           
     
                                            
                   
  static Future<TtsVoice> importFile(
    String sourcePath, {
    String? name,
  }) async {
    final src = File(sourcePath);
    if (!await src.exists()) {
      throw TtsVoiceException('文件不存在');
    }
    final ext = p.extension(sourcePath).replaceFirst('.', '').toLowerCase();
    if (ext.isEmpty || !kTtsAudioExtensions.contains(ext)) {
      throw TtsVoiceException('不是支持的音频格式（.$ext）');
    }
    final size = await src.length().catchError((_) => -1);
    if (size <= 0) {
      throw TtsVoiceException('文件为空');
    }
    if (size > maxBytes) {
      throw TtsVoiceException('文件过大（超过 50MB）');
    }

    final id = DateTime.now().microsecondsSinceEpoch.toString();
    final fileName = '$id.$ext';
    final dest = File(p.join((await voicesDir).path, fileName));
    await src.copy(dest.path);

    final voice = TtsVoice(
      id: id,
      name: (name?.trim().isNotEmpty ?? false)
          ? name!.trim()
          : p.basenameWithoutExtension(sourcePath),
      fileName: fileName,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final all = await loadAll();
    await _saveAll([voice, ...all]);
    return voice;
  }

  static Future<void> rename(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;
    final all = await loadAll();
    final idx = all.indexWhere((v) => v.id == id);
    if (idx < 0) return;
    all[idx] = TtsVoice(
      id: all[idx].id,
      name: trimmed,
      fileName: all[idx].fileName,
      createdAt: all[idx].createdAt,
    );
    await _saveAll(all);
  }

                   
  static Future<void> delete(String id) async {
    final all = await loadAll();
    final target = all.where((v) => v.id == id).toList();
    for (final v in target) {
      final f = File(await absolutePath(v));
      if (await f.exists()) {
        await f.delete().catchError((_) => f);
      }
    }
    await _saveAll(all.where((v) => v.id != id).toList());
                                       
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString(_selectedKey) == id) {
      await prefs.remove(_selectedKey);
    }
  }

                         
  static Future<int> pruneMissing() async {
    final all = await loadAll();
    final kept = <TtsVoice>[];
    for (final v in all) {
      final f = File(await absolutePath(v));
      if (await f.exists()) {
        kept.add(v);
      }
    }
    if (kept.length != all.length) {
      await _saveAll(kept);
    }
    return all.length - kept.length;
  }
}

class TtsVoiceException implements Exception {
  final String message;
  TtsVoiceException(this.message);

  @override
  String toString() => message;
}
