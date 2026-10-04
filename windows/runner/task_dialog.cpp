                                 
  
                    
                                                       
                                                     
                                                      
                                                                        
                                                     
                                                         
#include "task_dialog.h"

#include <string>
#include <vector>

#include <commctrl.h>
#include <windows.h>

#pragma comment(lib, "comctl32.lib")

namespace task_dialog {
namespace {

                             
constexpr int kFirstButtonId = 2000;

}              

int Show(HWND owner, const Options& options) {
  if (options.links.empty()) return kFailed;

                                                         
  INITCOMMONCONTROLSEX icc = {sizeof(icc), ICC_STANDARD_CLASSES};
  InitCommonControlsEx(&icc);

                                           
  std::vector<std::wstring> texts;
  texts.reserve(options.links.size());
  for (const CommandLink& link : options.links) {
    std::wstring text = link.text;
    if (!link.subtitle.empty()) text += L"\n" + link.subtitle;
    texts.push_back(std::move(text));
  }

  std::vector<TASKDIALOG_BUTTON> buttons(texts.size());
  for (size_t i = 0; i < texts.size(); ++i) {
    buttons[i].nButtonID = kFirstButtonId + static_cast<int>(i);
    buttons[i].pszButtonText = texts[i].c_str();
  }

  TASKDIALOGCONFIG config = {sizeof(config)};
  config.hwndParent = owner;
  config.dwFlags = TDF_USE_COMMAND_LINKS | TDF_ALLOW_DIALOG_CANCELLATION |
                   TDF_POSITION_RELATIVE_TO_WINDOW;
  config.pszWindowTitle =
      options.title.empty() ? nullptr : options.title.c_str();
  config.pszMainInstruction =
      options.heading.empty() ? nullptr : options.heading.c_str();
  config.pszContent = options.content.empty() ? nullptr : options.content.c_str();
  config.pszMainIcon = TD_INFORMATION_ICON;
  config.pButtons = buttons.data();
  config.cButtons = static_cast<UINT>(buttons.size());
  config.nDefaultButton = kFirstButtonId;

  int pressed = 0;
  const HRESULT hr = TaskDialogIndirect(&config, &pressed, nullptr, nullptr);
  if (FAILED(hr)) return kFailed;
  if (pressed >= kFirstButtonId) return pressed - kFirstButtonId;
  return kCancelled;
}

}                          
