                               
  
                                                  
                             
  
                       
                         
                                           
                            
  
                                                      
                                 
                                                           
#ifndef RUNNER_TASK_DIALOG_H_
#define RUNNER_TASK_DIALOG_H_

#include <string>
#include <vector>

#include <windows.h>

namespace task_dialog {

                            
struct CommandLink {
  std::wstring text;
  std::wstring subtitle;
};

struct Options {
  std::wstring title;                
  std::wstring heading;               
  std::wstring content;              
  std::vector<CommandLink> links;
};

                                                    
                                     
constexpr int kCancelled = -1;
constexpr int kFailed = -2;

int Show(HWND owner, const Options& options);

}                          

#endif                          
