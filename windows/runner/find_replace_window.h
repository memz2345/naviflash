                                       
  
                                                      
  
                                                          
                                                     
                                                            
                                  
  
                                                           
#ifndef RUNNER_FIND_REPLACE_WINDOW_H_
#define RUNNER_FIND_REPLACE_WINDOW_H_

#include <string>
#include <vector>

#include <windows.h>

namespace find_replace {

                                    
struct Labels {
  std::wstring title;
  std::wstring find;                         
  std::wstring replace;                      
  std::wstring result_prefix;                
  std::wstring case_sensitive;               
  std::wstring whole_word;                 
  std::wstring regex;                        
  std::wstring prev;                  
  std::wstring next;                  
  std::wstring replace_one;           
  std::wstring replace_all;           
  std::wstring delete_matches;           
  std::wstring ok;                    
  std::wstring cancel;                
};

                      
   
                                                
                                                      
   
                                         
bool Show(HWND owner, const Labels& labels,
          const std::vector<std::wstring>& rules_in,
          std::vector<std::wstring>* rules_out);

}                           

#endif                                  
