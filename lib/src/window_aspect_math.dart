                                  
  
                                      
  
                               
                                                        
                                                 
                                                        
                       
                                                         
  
                                   
                                     
                               
                                           
                                  
  
                                 
                                         
import 'dart:math' as math;
import 'dart:ui';

                                    
Size fitSizeWithin(Size want, Size bounds) {
  if (want.width <= bounds.width && want.height <= bounds.height) return want;
  final scale = math.min(
    bounds.width / want.width,
    bounds.height / want.height,
  );
  return Size(want.width * scale, want.height * scale);
}

                                       
Size windowChrome(Size outer, Size client) => Size(
      math.max(0.0, outer.width - client.width),
      math.max(0.0, outer.height - client.height),
    );

                      
Size viewClientSize(FlutterView view) =>
    view.physicalSize / view.devicePixelRatio;

                  
Size displayLogicalSize(Display display) =>
    display.size / display.devicePixelRatio;

                                                  
   
                             
                          
                              
                                  
                                         
   
                                   
                                      
                                   
Size alignWindowOuterSize({
  required Size client,
  required double ratio,
  required Size screen,
  required Size chrome,
  Size minOuter = const Size(400, 300),
}) {
  assert(ratio > 0);
                            
  var wantClient = fitSizeWithin(
    Size(client.height * ratio, client.height),
    screen,
  );
                         
  final minClientW = math.max(1.0, minOuter.width - chrome.width);
  final minClientH = math.max(1.0, minOuter.height - chrome.height);
  if (wantClient.width < minClientW) {
    wantClient = fitSizeWithin(
      Size(minClientW, minClientW / ratio),
      screen,
    );
  }
  if (wantClient.height < minClientH) {
    wantClient = fitSizeWithin(
      Size(minClientH * ratio, minClientH),
      screen,
    );
  }
  return Size(
    wantClient.width + chrome.width,
    wantClient.height + chrome.height,
  );
}
