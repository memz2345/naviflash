// tool/win_find_replace_probe.dart
//
// Windows 原生窗口的联调脚本（先用于「查找和替换」，现也用于任务对话框）。
//
// 为什么用 FFI 而不是 PowerShell：本机安全策略拦 `Add-Type`（UIA / P-Invoke 全废），
// 而 Dart FFI 直接调 user32 不受限，还能读控件文字、改输入框、点按钮 —— **全程不用鼠标**。
//
// 用法：
//   dart run tool/win_find_replace_probe.dart
//       找窗口（默认标题「查找和替换」），列出全部子控件的类名 + 文字
//   dart run tool/win_find_replace_probe.dart --find 广告 --ok
//       往「查找」框写「广告」，读回结果计数，然后点「确定」
//   dart run tool/win_find_replace_probe.dart --find 广告 --replace 广子 --click 全部 --click 确定
//       改查找/替换框后按顺序点按钮（BM_CLICK），验证批量替换/删除
//   dart run tool/win_find_replace_probe.dart --title "AI 朗读" --click-nth 0
//       任意窗口：--title 指定标题，--click-nth N 点第 N 个按钮
//       （TaskDialog 的命令链接也是 Button，副标题在文字里以换行分隔）
//
// 退出码：0 找到窗口；1 没找到。
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// ── user32 绑定 ──
final DynamicLibrary _user32 = DynamicLibrary.open('user32.dll');

typedef _HwndFn = IntPtr Function(IntPtr, IntPtr, Pointer<Utf16>,
    Pointer<Utf16>);
typedef _HwndDart = int Function(int, int, Pointer<Utf16>, Pointer<Utf16>);

final _findWindowEx = _user32
    .lookupFunction<_HwndFn, _HwndDart>('FindWindowExW');

typedef _SendMsgNative = IntPtr Function(IntPtr, Uint32, IntPtr, IntPtr);
typedef _SendMsgDart = int Function(int, int, int, int);

final _sendMessage = _user32
    .lookupFunction<_SendMsgNative, _SendMsgDart>('SendMessageW');

typedef _GetClassNative = Int32 Function(IntPtr, Pointer<Utf16>, Int32);
typedef _GetClassDart = int Function(int, Pointer<Utf16>, int);

final _getClassName = _user32
    .lookupFunction<_GetClassNative, _GetClassDart>('GetClassNameW');

const int _wmSetText = 0x000C;
const int _wmGetText = 0x000D;
const int _wmGetTextLength = 0x000E;
const int _bmClick = 0x00F5;

/// TDM_CLICK_BUTTON（WM_USER + 102）：TaskDialog 官方留给「模拟点某个按钮」的消息，
/// 命令链接照样认 —— wParam 传按钮 id。比 WM_COMMAND 靠谱（DirectUI 内部不认后者）。
const int _tdmClickButton = 0x0466;

Pointer<Utf16> _toUtf16(String s) {
  final units = s.codeUnits;
  final ptr = calloc<Uint16>(units.length + 1);
  for (var i = 0; i < units.length; i++) {
    ptr[i] = units[i];
  }
  ptr[units.length] = 0;
  return ptr.cast<Utf16>();
}

String _windowText(int hwnd) {
  final len = _sendMessage(hwnd, _wmGetTextLength, 0, 0);
  if (len <= 0) return '';
  final buf = calloc<Uint16>(len + 2);
  _sendMessage(hwnd, _wmGetText, len + 1, buf.address);
  final text = buf.cast<Utf16>().toDartString();
  calloc.free(buf);
  return text;
}

String _className(int hwnd) {
  final buf = calloc<Uint16>(256);
  _getClassName(hwnd, buf.cast<Utf16>(), 256);
  final name = buf.cast<Utf16>().toDartString();
  calloc.free(buf);
  return name;
}

int _findWindow(String title) {
  final t = _toUtf16(title);
  final hwnd = _findWindowEx(0, 0, nullptr, t);
  calloc.free(t);
  return hwnd;
}

/// 子控件列表：class / text / hwnd
List<({String cls, String text, int hwnd})> _children(int parent) {
  final out = <({String cls, String text, int hwnd})>[];
  var child = _findWindowEx(parent, 0, nullptr, nullptr);
  while (child != 0) {
    out.add((cls: _className(child), text: _windowText(child), hwnd: child));
    child = _findWindowEx(parent, child, nullptr, nullptr);
  }
  return out;
}

int _childByClassText(int parent, String cls, String text) {
  final c = _toUtf16(cls);
  final t = _toUtf16(text);
  final hwnd = _findWindowEx(parent, 0, c, t);
  calloc.free(c);
  calloc.free(t);
  return hwnd;
}

int _childByClassTextIndexed(int parent, String cls, int index) {
  var found = 0;
  var child = _findWindowEx(parent, 0, nullptr, nullptr);
  while (child != 0) {
    if (_className(child).toLowerCase() == cls.toLowerCase()) {
      if (found == index) return child;
      found++;
    }
    child = _findWindowEx(parent, child, nullptr, nullptr);
  }
  return 0;
}

void _setText(int hwnd, String text) {
  final t = _toUtf16(text);
  _sendMessage(hwnd, _wmSetText, 0, t.address);
  calloc.free(t);
}

void main(List<String> args) {
  String? argOf(String flag) {
    final i = args.indexOf(flag);
    return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
  }

  final windowTitle = argOf('--title') ?? '查找和替换';
  final clickNth = int.tryParse(argOf('--click-nth') ?? '');
  final commandId = int.tryParse(argOf('--command') ?? '');
  final findText = argOf('--find');
  final replaceText = argOf('--replace');
  final clicks = <String>[
    for (var i = 0; i < args.length; i++)
      if (args[i] == '--click' && i + 1 < args.length) args[i + 1],
  ];
  final clickOk = args.contains('--ok');

  final hwnd = _findWindow(windowTitle);
  if (hwnd == 0) {
    stdout.writeln('NOT FOUND: 没有标题为「$windowTitle」的窗口');
    exit(1);
  }
  stdout.writeln('FOUND hwnd=$hwnd');

  final kids = _children(hwnd);
  stdout.writeln('children=${kids.length}');
  for (final k in kids) {
    stdout.writeln('  [${k.cls}] ${k.text}');
  }

  if (findText != null) {
    final edit = kids.firstWhere(
      (k) => k.cls.toLowerCase() == 'edit',
      orElse: () => (cls: '', text: '', hwnd: 0),
    );
    if (edit.hwnd == 0) {
      stdout.writeln('NO EDIT');
      exit(2);
    }
    _setText(edit.hwnd, findText);
    sleep(const Duration(milliseconds: 400));
    final after = _children(hwnd)
        .where((k) => k.text.contains('搜索结果'))
        .map((k) => k.text)
        .toList();
    stdout.writeln('RESULT_TEXT=$after');
  }

  if (replaceText != null) {
    final edit = _childByClassTextIndexed(hwnd, 'Edit', 1);
    if (edit != 0) _setText(edit, replaceText);
    sleep(const Duration(milliseconds: 200));
  }

  for (final label in clicks) {
    final btn = _childByClassText(hwnd, 'Button', label);
    if (btn == 0) {
      stdout.writeln('NO BUTTON: $label');
      continue;
    }
    _sendMessage(btn, _bmClick, 0, 0);
    stdout.writeln('CLICKED $label');
    sleep(const Duration(milliseconds: 300));
  }

  if (commandId != null) {
    _sendMessage(hwnd, _tdmClickButton, commandId, 0);
    stdout.writeln('SENT TDM_CLICK_BUTTON $commandId');
    sleep(const Duration(milliseconds: 400));
  }

  if (clickNth != null) {
    final buttons = _children(
      hwnd,
    ).where((k) => k.cls.toLowerCase() == 'button').toList();
    if (clickNth < 0 || clickNth >= buttons.length) {
      stdout.writeln('NO BUTTON #$clickNth (共 ${buttons.length})');
    } else {
      _sendMessage(buttons[clickNth].hwnd, _bmClick, 0, 0);
      stdout.writeln(
        'CLICKED #$clickNth [${buttons[clickNth].text.replaceAll('\n', ' / ')}]',
      );
    }
    sleep(const Duration(milliseconds: 300));
  }

  if (clickOk) {
    final ok = _childByClassText(hwnd, 'Button', '确定');
    if (ok == 0) {
      stdout.writeln('NO OK BUTTON');
      exit(3);
    }
    _sendMessage(ok, _bmClick, 0, 0);
    stdout.writeln('CLICKED OK');
  }
  exit(0);
}
