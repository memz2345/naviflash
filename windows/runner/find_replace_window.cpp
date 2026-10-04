                                         
  
                                        
  
                                                
                                               
                                                    
                                                     
                                     
                                                     
                                          
                                                   
                                                     
  
                                             
                                                        
#include "find_replace_window.h"

#include <algorithm>
#include <cctype>
#include <cwctype>
#include <regex>
#include <string>
#include <vector>

#include <windows.h>

#pragma comment(lib, "user32.lib")

namespace find_replace {
namespace {

constexpr wchar_t kWindowClass[] = L"NaviFlashFindReplaceWindow";
constexpr int kWindowW = 560;
constexpr int kWindowH = 436;

enum : int {
  kIdFindEdit = 100,
  kIdReplaceEdit,
  kIdResultText,
  kIdCaseBox,
  kIdWordBox,
  kIdRegexBox,
  kIdList,
  kIdPrev,
  kIdNext,
  kIdReplaceOne,
  kIdReplaceAll,
  kIdDeleteMatches,
  kIdOk,
  kIdCancel,
};

struct State {
  Labels labels;
  std::vector<std::wstring> rules;
  std::vector<int> matches;
  int cursor = -1;
  bool case_sensitive = false;
  bool whole_word = false;
  bool use_regex = false;
  bool saved = false;
                     
  bool closed = false;
  HWND hwnd = nullptr;
  HWND find_edit = nullptr;
  HWND replace_edit = nullptr;
  HWND result_text = nullptr;
  HWND list = nullptr;
};

std::wstring ToLowerCopy(const std::wstring& s) {
  std::wstring out(s);
  std::transform(out.begin(), out.end(), out.begin(), [](wchar_t c) {
    return static_cast<wchar_t>(std::towlower(c));
  });
  return out;
}

std::wstring GetEditString(HWND edit) {
  const int len = GetWindowTextLengthW(edit);
  if (len <= 0) return std::wstring();
  std::vector<wchar_t> buf(static_cast<size_t>(len) + 1, L'\0');
  GetWindowTextW(edit, buf.data(), len + 1);
  return std::wstring(buf.data());
}

                                 
bool TextMatches(const std::wstring& text, const std::wstring& find,
                 bool case_sensitive, bool whole, bool use_regex) {
  if (find.empty()) return false;
  try {
    if (use_regex) {
      auto flags = std::regex_constants::ECMAScript;
      if (!case_sensitive) flags |= std::regex_constants::icase;
      const std::wregex re(find, flags);
      return whole ? std::regex_match(text, re)
                   : std::regex_search(text, re);
    }
    if (!case_sensitive) {
      const std::wstring t = ToLowerCopy(text);
      const std::wstring f = ToLowerCopy(find);
      return whole ? (t == f) : (t.find(f) != std::wstring::npos);
    }
    return whole ? (text == find) : (text.find(find) != std::wstring::npos);
  } catch (...) {
                        
    return false;
  }
}

                                          
std::wstring ReplaceIn(const std::wstring& text, const std::wstring& find,
                       const std::wstring& repl, bool case_sensitive,
                       bool whole, bool use_regex) {
  if (find.empty()) return text;
  try {
    if (use_regex) {
      auto flags = std::regex_constants::ECMAScript;
      if (!case_sensitive) flags |= std::regex_constants::icase;
      const std::wregex re(find, flags);
      if (whole) return std::regex_match(text, re) ? repl : text;
      return std::regex_replace(text, re, repl);
    }
    std::wstring out;
    const std::wstring hay = case_sensitive ? text : ToLowerCopy(text);
    const std::wstring needle = case_sensitive ? find : ToLowerCopy(find);
    size_t pos = 0;
    while (true) {
      const size_t hit = hay.find(needle, pos);
      if (hit == std::wstring::npos) {
        out.append(text, pos, std::wstring::npos);
        break;
      }
      out.append(text, pos, hit - pos);
      out.append(repl);
      pos = hit + needle.size();
    }
    if (whole && out == text) {
      return TextMatches(text, find, case_sensitive, true, false) ? repl : text;
    }
    return out;
  } catch (...) {
    return text;
  }
}

void UpdateResultText(State* s) {
  const std::wstring text =
      s->labels.result_prefix + std::to_wstring(s->matches.size());
  SetWindowTextW(s->result_text, text.c_str());
}

void FillList(State* s) {
  const LRESULT sel = SendMessageW(s->list, LB_GETCURSEL, 0, 0);
  const int top = static_cast<int>(SendMessageW(s->list, LB_GETTOPINDEX, 0, 0));
  SendMessageW(s->list, LB_RESETCONTENT, 0, 0);
  for (const std::wstring& r : s->rules) {
    SendMessageW(s->list, LB_ADDSTRING, 0, reinterpret_cast<LPARAM>(r.c_str()));
  }
                     
  if (s->cursor >= 0 && s->cursor < static_cast<int>(s->matches.size())) {
    const int idx = s->matches[s->cursor];
    SendMessageW(s->list, LB_SETCURSEL, static_cast<WPARAM>(idx), 0);
    SendMessageW(s->list, LB_SETTOPINDEX, static_cast<WPARAM>(idx), 0);
  } else {
    SendMessageW(s->list, LB_SETCURSEL, static_cast<WPARAM>(sel), 0);
    SendMessageW(s->list, LB_SETTOPINDEX, static_cast<WPARAM>(top), 0);
  }
}

void Recompute(State* s) {
  const std::wstring find = GetEditString(s->find_edit);
  s->matches.clear();
  if (!find.empty()) {
    for (size_t i = 0; i < s->rules.size(); ++i) {
      if (TextMatches(s->rules[i], find, s->case_sensitive, s->whole_word,
                      s->use_regex)) {
        s->matches.push_back(static_cast<int>(i));
      }
    }
  }
  s->cursor = s->matches.empty() ? -1 : 0;
  UpdateResultText(s);
  FillList(s);
}

void ReplaceAt(State* s, int match_pos) {
  if (match_pos < 0 || match_pos >= static_cast<int>(s->matches.size())) return;
  const int idx = s->matches[match_pos];
  const std::wstring find = GetEditString(s->find_edit);
  const std::wstring repl = GetEditString(s->replace_edit);
  const std::wstring next =
      ReplaceIn(s->rules[idx], find, repl, s->case_sensitive, s->whole_word,
                s->use_regex);
  if (next.empty()) {
    s->rules.erase(s->rules.begin() + idx);
  } else {
    s->rules[idx] = next;
  }
  Recompute(s);
}

void ReplaceAll(State* s) {
  const std::wstring find = GetEditString(s->find_edit);
  const std::wstring repl = GetEditString(s->replace_edit);
  std::vector<std::wstring> out;
  out.reserve(s->rules.size());
  for (const std::wstring& rule : s->rules) {
    if (!TextMatches(rule, find, s->case_sensitive, s->whole_word,
                     s->use_regex)) {
      out.push_back(rule);
      continue;
    }
    const std::wstring next =
        ReplaceIn(rule, find, repl, s->case_sensitive, s->whole_word,
                  s->use_regex);
    if (!next.empty()) out.push_back(next);
  }
  s->rules = out;
  Recompute(s);
}

void DeleteMatches(State* s) {
  const std::wstring find = GetEditString(s->find_edit);
  std::vector<std::wstring> out;
  out.reserve(s->rules.size());
  for (const std::wstring& rule : s->rules) {
    if (!TextMatches(rule, find, s->case_sensitive, s->whole_word,
                     s->use_regex)) {
      out.push_back(rule);
    }
  }
  s->rules = out;
  Recompute(s);
}

void MoveCursor(State* s, int delta) {
  if (s->matches.empty()) return;
  const int n = static_cast<int>(s->matches.size());
  s->cursor = (s->cursor + delta + n) % n;
  FillList(s);
}

HWND MakeStatic(HWND parent, const std::wstring& text, int x, int y, int w,
                int h, HFONT font, int id) {
  HWND hwnd = CreateWindowExW(0, L"STATIC", text.c_str(),
                              WS_CHILD | WS_VISIBLE | SS_LEFT, x, y, w, h,
                              parent, reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)),
                              GetModuleHandle(nullptr), nullptr);
  if (hwnd && font) {
    SendMessageW(hwnd, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
  }
  return hwnd;
}

HWND MakeEdit(HWND parent, int x, int y, int w, int h, HFONT font, int id) {
  HWND hwnd = CreateWindowExW(
      WS_EX_CLIENTEDGE, L"EDIT", L"",
      WS_CHILD | WS_VISIBLE | ES_AUTOHSCROLL | WS_TABSTOP, x, y, w, h, parent,
      reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)), GetModuleHandle(nullptr),
      nullptr);
  if (hwnd && font) {
    SendMessageW(hwnd, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
  }
  return hwnd;
}

HWND MakeButton(HWND parent, const std::wstring& text, int x, int y, int w,
                int h, HFONT font, int id) {
  HWND hwnd = CreateWindowExW(
      0, L"BUTTON", text.c_str(), WS_CHILD | WS_VISIBLE | WS_TABSTOP, x, y, w,
      h, parent, reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)),
      GetModuleHandle(nullptr), nullptr);
  if (hwnd && font) {
    SendMessageW(hwnd, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
  }
  return hwnd;
}

HWND MakeCheck(HWND parent, const std::wstring& text, int x, int y, int w,
               int h, HFONT font, int id) {
  HWND hwnd = CreateWindowExW(
      0, L"BUTTON", text.c_str(),
      WS_CHILD | WS_VISIBLE | BS_AUTOCHECKBOX | WS_TABSTOP, x, y, w, h, parent,
      reinterpret_cast<HMENU>(static_cast<INT_PTR>(id)), GetModuleHandle(nullptr),
      nullptr);
  if (hwnd && font) {
    SendMessageW(hwnd, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
  }
  return hwnd;
}

LRESULT CALLBACK WndProc(HWND hwnd, UINT msg, WPARAM wparam, LPARAM lparam) {
  State* s = reinterpret_cast<State*>(
      GetWindowLongPtrW(hwnd, GWLP_USERDATA));

  switch (msg) {
    case WM_CREATE: {
      const CREATESTRUCTW* cs = reinterpret_cast<CREATESTRUCTW*>(lparam);
      SetWindowLongPtrW(hwnd, GWLP_USERDATA,
                        reinterpret_cast<LONG_PTR>(cs->lpCreateParams));
      return 0;
    }
    case WM_COMMAND: {
      if (s == nullptr) break;
      const int id = LOWORD(wparam);
      const int code = HIWORD(wparam);
      if (code == EN_CHANGE && id == kIdFindEdit) {
        Recompute(s);
        return 0;
      }
      if (code == BN_CLICKED) {
        switch (id) {
          case kIdCaseBox:
            s->case_sensitive = !s->case_sensitive;
            Recompute(s);
            return 0;
          case kIdWordBox:
            s->whole_word = !s->whole_word;
            Recompute(s);
            return 0;
          case kIdRegexBox:
            s->use_regex = !s->use_regex;
            Recompute(s);
            return 0;
          case kIdPrev:
            MoveCursor(s, -1);
            return 0;
          case kIdNext:
            MoveCursor(s, 1);
            return 0;
          case kIdReplaceOne:
            ReplaceAt(s, s->cursor);
            return 0;
          case kIdReplaceAll:
            ReplaceAll(s);
            return 0;
          case kIdDeleteMatches:
            DeleteMatches(s);
            return 0;
          case kIdOk:
            s->saved = true;
            DestroyWindow(hwnd);
            return 0;
          case kIdCancel:
            DestroyWindow(hwnd);
            return 0;
          default:
            break;
        }
      }
      break;
    }
    case WM_CLOSE:
      DestroyWindow(hwnd);
      return 0;
    case WM_DESTROY:
                                                  
                                            
                                           
      if (s != nullptr) s->closed = true;
      return 0;
    default:
      break;
  }
  return DefWindowProcW(hwnd, msg, wparam, lparam);
}

bool RegisterWindowClass() {
  WNDCLASSEXW wc = {};
  wc.cbSize = sizeof(wc);
  wc.lpfnWndProc = WndProc;
  wc.hInstance = GetModuleHandle(nullptr);
  wc.lpszClassName = kWindowClass;
  wc.hCursor = LoadCursor(nullptr, IDC_ARROW);
  wc.hbrBackground = reinterpret_cast<HBRUSH>(COLOR_BTNFACE + 1);
  wc.style = CS_HREDRAW | CS_VREDRAW;
  return RegisterClassExW(&wc) != 0 ||
         GetLastError() == ERROR_CLASS_ALREADY_EXISTS;
}

}              

bool Show(HWND owner, const Labels& labels,
          const std::vector<std::wstring>& rules_in,
          std::vector<std::wstring>* rules_out) {
  if (!RegisterWindowClass()) return false;

  State state;
  state.labels = labels;
  state.rules = rules_in;

  const HINSTANCE inst = GetModuleHandle(nullptr);
  HWND hwnd = CreateWindowExW(
      WS_EX_DLGMODALFRAME, kWindowClass, labels.title.c_str(),
      WS_POPUPWINDOW | WS_CAPTION | WS_SYSMENU | WS_VISIBLE, CW_USEDEFAULT,
      CW_USEDEFAULT, kWindowW, kWindowH, owner, nullptr, inst, &state);
  if (hwnd == nullptr) return false;
  state.hwnd = hwnd;

                           
  RECT wr = {0, 0, kWindowW, kWindowH};
  AdjustWindowRectEx(&wr, WS_POPUPWINDOW | WS_CAPTION | WS_SYSMENU, FALSE,
                     WS_EX_DLGMODALFRAME);
  SetWindowPos(hwnd, nullptr, 0, 0, wr.right - wr.left, wr.bottom - wr.top,
               SWP_NOMOVE | SWP_NOZORDER | SWP_NOACTIVATE);

  HFONT font = reinterpret_cast<HFONT>(GetStockObject(DEFAULT_GUI_FONT));

  MakeStatic(hwnd, labels.find, 16, 18, 56, 22, font, -1);
  state.find_edit = MakeEdit(hwnd, 76, 16, 300, 24, font, kIdFindEdit);
  state.result_text = MakeStatic(hwnd, labels.result_prefix + L"0", 386, 18,
                                 156, 22, font, kIdResultText);
  MakeStatic(hwnd, labels.replace, 16, 50, 56, 22, font, -1);
  state.replace_edit = MakeEdit(hwnd, 76, 48, 300, 24, font, kIdReplaceEdit);

  MakeCheck(hwnd, labels.case_sensitive, 386, 48, 46, 24, font, kIdCaseBox);
  MakeCheck(hwnd, labels.whole_word, 436, 48, 40, 24, font, kIdWordBox);
  MakeCheck(hwnd, labels.regex, 480, 48, 44, 24, font, kIdRegexBox);

  state.list = CreateWindowExW(
      WS_EX_CLIENTEDGE, L"LISTBOX", L"",
      WS_CHILD | WS_VISIBLE | WS_VSCROLL | WS_HSCROLL | LBS_NOTIFY |
          LBS_NOINTEGRALHEIGHT | WS_TABSTOP,
      16, 82, 528, 190, hwnd, reinterpret_cast<HMENU>(static_cast<INT_PTR>(kIdList)), inst, nullptr);
  if (state.list && font) {
    SendMessageW(state.list, WM_SETFONT, reinterpret_cast<WPARAM>(font), TRUE);
  }

  MakeButton(hwnd, labels.prev, 16, 286, 78, 30, font, kIdPrev);
  MakeButton(hwnd, labels.next, 100, 286, 78, 30, font, kIdNext);
  MakeButton(hwnd, labels.replace_one, 184, 286, 78, 30, font, kIdReplaceOne);
  MakeButton(hwnd, labels.replace_all, 268, 286, 78, 30, font, kIdReplaceAll);
  MakeButton(hwnd, labels.delete_matches, 352, 286, 108, 30, font,
             kIdDeleteMatches);

                  
  const HWND ok = MakeButton(hwnd, labels.ok, 358, 336, 88, 32, font, kIdOk);
  MakeButton(hwnd, labels.cancel, 456, 336, 88, 32, font, kIdCancel);
  SendMessageW(ok, BM_SETSTYLE,
               static_cast<WPARAM>(BS_DEFPUSHBUTTON), TRUE);

  FillList(&state);
  UpdateResultText(&state);
  SetFocus(state.find_edit);

                                                       
  const bool had_owner = owner != nullptr && IsWindowEnabled(owner);
  if (had_owner) EnableWindow(owner, FALSE);
  ShowWindow(hwnd, SW_SHOW);
  UpdateWindow(hwnd);

  MSG msg;
  while (!state.closed) {
    const BOOL got = GetMessageW(&msg, nullptr, 0, 0);
    if (got <= 0) break;                    
    if (IsWindow(hwnd) && IsDialogMessageW(hwnd, &msg)) continue;
    TranslateMessage(&msg);
    DispatchMessageW(&msg);
  }

  if (had_owner) EnableWindow(owner, TRUE);
  if (owner != nullptr) SetForegroundWindow(owner);

  if (state.saved && rules_out != nullptr) {
    *rules_out = state.rules;
  }
  return state.saved;
}

}                           
