                                          
  
                                                  
                                 
  
                                       
                                                    
  
                                     
                                                           
                                                    
                                       
  
                                          
                        
                                      
                                              
                                        
                                                     
                                            
                                                    
  
                           
                                                      
                                                    
                                               
#ifndef RUNNER_DESKTOP_SHELL_CHANNELS_H_
#define RUNNER_DESKTOP_SHELL_CHANNELS_H_

#include <flutter/binary_messenger.h>
#include <windows.h>

#include <string>
#include <vector>

namespace desktop_shell {

                                             
enum class ProgressMode {
  kNone = 0,                  
  kIndeterminate = 1,                   
  kDeterminate = 2,                  
  kPaused = 3,                   
  kError = 4,                   
};

            
                                                     
                                        
void Register(flutter::BinaryMessenger* messenger, HWND top_hwnd,
              HWND view_hwnd);

                        
void Unregister();

                                 
                                             
                                                 
void SetLaunchArgs(const std::vector<std::string>& args);

                                                 
                                         
bool HandleForwardedArgs(const std::string& payload);

                                             
                                     
bool IsHandledLaunchArg(const std::string& arg);

                          
constexpr char kLaunchArgSeparator = '\x1e';

                                  
void EnableFileDrop(HWND hwnd);

                                                      
bool HandleDropFiles(HDROP drop);

                          
void SetTaskbarProgress(ProgressMode mode, int value);

}                            

#endif                                     
