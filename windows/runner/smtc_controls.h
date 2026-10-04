#ifndef RUNNER_SMTC_CONTROLS_H_
#define RUNNER_SMTC_CONTROLS_H_

#include <windows.h>

#include <cstdint>
#include <functional>
#include <string>

                                        
                                                                  
                                   
                                                     
                                                         
  
                                                
                                             
                             
namespace smtc {

                                            
                              
                                                                                    
bool Init(HWND main_hwnd, std::function<void(const std::string&)> on_action);

                          
void Shutdown();

                                      
void Activate(const std::string& title, const std::string& artist,
              const std::string& art_uri, bool playing,
              int64_t position_ms, int64_t duration_ms);

                                                     
void UpdateMetadata(const std::string& title, const std::string& artist,
                    const std::string& art_uri);

                                              
void UpdatePlaybackState(bool playing);

                     
void UpdatePosition(int64_t position_ms, int64_t duration_ms);

                            
void Deactivate();

                                                
                                                  
                                   
bool HandleWindowMessage(HWND hwnd, UINT message, WPARAM wparam, LPARAM lparam);

}                   

#endif                            
