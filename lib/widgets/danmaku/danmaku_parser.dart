import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:naviflash/services/network_settings_service.dart';
import 'package:xml/xml.dart';
import 'danmaku_model.dart';

class DanmakuParser {
                     
  static List<DanmakuItem> parseXmlString(String xmlStr) {
    final items = <DanmakuItem>[];
    try {
      final document = XmlDocument.parse(xmlStr);
      final dElements = document.findAllElements('d');
      for (final el in dElements) {
        final p = el.getAttribute('p');
        final content = el.innerText.trim();
        if (p == null || content.isEmpty) continue;
        try {
          items.add(DanmakuItem.fromXmlAttr(p, content));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('弹幕 XML 解析失败: $e');
    }
            
    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

             
  static Future<List<DanmakuItem>> parseFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) return [];
    final content = await file.readAsString(encoding: utf8);
    return parseXmlString(content);
  }

              
  static Future<List<DanmakuItem>> parseUrl(
    String url, {
    Map<String, String>? headers,
  }) async {
    try {
      final client = HttpClient();
      final request = await client.getUrl(Uri.parse(url));
      final merged = {
        ...?headers,
        ...NetworkSettingsService.instance.apiHeaders,
      };
      merged.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close();
      if (response.statusCode != 200) return [];
      final body = await response.transform(utf8.decoder).join();
      client.close();
      return parseXmlString(body);
    } catch (e) {
      debugPrint('弹幕 URL 加载失败: $e');
      return [];
    }
  }
}