                                        
  
            
  
           
                                                          
                                                                 
                                        
                                                          
                                 
  
                    

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

                                                           
const String kOssLockAssetKey = 'pubspec.lock';

               
const String kOssOtherLicense = 'Other';

                                     
class OssParagraph {
  final String text;
  final int indent;

  const OssParagraph(this.text, this.indent);
}

                     
class OssPackage {
  final String name;

                                         
  final String? version;

                                    
  final List<List<OssParagraph>> licenses;

                                                         
  final List<String> licenseIds;

  const OssPackage({
    required this.name,
    required this.licenses,
    required this.licenseIds,
    this.version,
  });

  int get licenseCount => licenses.length;

  String get primaryLicenseId =>
      licenseIds.isEmpty ? kOssOtherLicense : licenseIds.first;

                       
  String get fullText => licenses
      .map((paragraphs) => paragraphs.map((p) => p.text).join('\n\n'))
      .join('\n\n${'-' * 72}\n\n');
}

                
class OssLicenseData {
                     
  final List<OssPackage> packages;

              
  final int totalLicenses;

                  
  final Map<String, int> licenseHistogram;

  const OssLicenseData({
    required this.packages,
    required this.totalLicenses,
    required this.licenseHistogram,
  });

  static const OssLicenseData empty = OssLicenseData(
    packages: <OssPackage>[],
    totalLicenses: 0,
    licenseHistogram: <String, int>{},
  );

  bool get isEmpty => packages.isEmpty;
}

Future<OssLicenseData>? _pending;

                                   
   
                                               
                                                                   
                                    
Future<OssLicenseData> loadOssLicenses({bool refresh = false}) {
  if (refresh) _pending = null;
  final cached = _pending;
  if (cached != null) return cached;

  final future = _collect();
  _pending = future;
  future.then<void>(
    (_) {},
    onError: (Object _, StackTrace __) {
      if (identical(_pending, future)) _pending = null;
    },
  );
  return future;
}

                                          
                                                   
@visibleForTesting
void debugResetOssLicenseCache() {
  _pending = null;
}

                                             
Map<String, String> parseLockVersions(String raw) {
  final versions = <String, String>{};
  var inPackages = false;
  String? current;

  for (final line in const LineSplitter().convert(raw)) {
    if (line.isEmpty) continue;
                              
    if (!line.startsWith(' ')) {
      inPackages = line.trimRight() == 'packages:';
      current = null;
      continue;
    }
    if (!inPackages) continue;
                                
    if (line.startsWith('  ') && !line.startsWith('   ')) {
      final trimmed = line.trim();
      current = trimmed.endsWith(':')
          ? trimmed.substring(0, trimmed.length - 1)
          : null;
      continue;
    }
    if (current == null) continue;
    final trimmed = line.trim();
    if (!trimmed.startsWith('version:')) continue;
    var version = trimmed.substring('version:'.length).trim();
    if (version.length >= 2 &&
        ((version.startsWith('"') && version.endsWith('"')) ||
            (version.startsWith("'") && version.endsWith("'")))) {
      version = version.substring(1, version.length - 1);
    }
    if (version.isNotEmpty) versions[current] = version;
    current = null;
  }
  return versions;
}

                                          
   
                                         
                                      
String detectLicenseId(String text) {
  const headLimit = 4000;
  final t = (text.length > headLimit ? text.substring(0, headLimit) : text)
      .toLowerCase();
  if (t.contains('apache license') && t.contains('version 2.0')) {
    return 'Apache-2.0';
  }
  if (t.contains('mozilla public license')) {
    return t.contains('2.0') ? 'MPL-2.0' : 'MPL-1.1';
  }
  if (t.contains('gnu lesser general public license')) return 'LGPL';
  if (t.contains('gnu library general public license')) return 'LGPL';
  if (t.contains('gnu general public license')) return 'GPL';
  if (t.contains('redistribution and use in source and binary forms')) {
                                     
    return t.contains('neither the name') ? 'BSD-3-Clause' : 'BSD-2-Clause';
  }
  if (t.contains('permission is hereby granted, free of charge')) return 'MIT';
  if (t.contains('permission to use, copy, modify, and')) return 'ISC';
  if (t.contains('this is free and unencumbered software')) return 'Unlicense';
  if (t.contains('zlib license') || t.contains('altered source versions')) {
    return 'Zlib';
  }
  return kOssOtherLicense;
}

Future<Map<String, String>> _loadVersions() async {
  try {
    final raw = await rootBundle.loadString(kOssLockAssetKey);
    return parseLockVersions(raw);
  } catch (error) {
    debugPrint('OssLicenseService: pubspec.lock asset 不可用 ($error)');
    return const <String, String>{};
  }
}

                                              
                
Future<OssLicenseData> _collect() async {
  try {
    return await _collectInner().timeout(const Duration(seconds: 45));
  } on TimeoutException {
    throw StateError('收集开源许可超时：NOTICES 资产不可用？');
  }
}

Future<OssLicenseData> _collectInner() async {
  final versions = await _loadVersions();
  final grouped = <String, List<List<OssParagraph>>>{};
  Object? failure;

  try {
    final entries = await LicenseRegistry.licenses
        .timeout(const Duration(seconds: 30))
        .toList();
    for (final entry in entries) {
      final paragraphs = <OssParagraph>[
        for (final p in entry.paragraphs) OssParagraph(p.text, p.indent),
      ];
      if (paragraphs.isEmpty) continue;
      for (final name in entry.packages) {
        if (name.trim().isEmpty) continue;
        grouped.putIfAbsent(name, () => <List<OssParagraph>>[]).add(paragraphs);
      }
    }
  } catch (error) {
    failure = error;
  }

                                       
  if (grouped.isEmpty && failure != null) {
    throw StateError('读取许可清单失败: $failure');
  }

  final packages = grouped.entries.map((e) {
    return OssPackage(
      name: e.key,
      version: versions[e.key],
      licenses: e.value,
      licenseIds: [
        for (final paragraphs in e.value)
          detectLicenseId(paragraphs.map((p) => p.text).join('\n')),
      ],
    );
  }).toList()..sort(
    (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
  );

  final histogram = <String, int>{};
  var totalLicenses = 0;
  for (final pkg in packages) {
    totalLicenses += pkg.licenseCount;
    for (final id in pkg.licenseIds.toSet()) {
      histogram[id] = (histogram[id] ?? 0) + 1;
    }
  }

  return OssLicenseData(
    packages: packages,
    totalLicenses: totalLicenses,
    licenseHistogram: Map.unmodifiable(histogram),
  );
}
