                              
  
                                                           
                                                            
                          

import 'package:flex_seed_scheme/flex_seed_scheme.dart';
import 'package:flutter/material.dart';

                               
extension ThemeSeedColorExt on Color {
                                                      
     
                                                      
                                                 
                                                                
                              
  ColorScheme asColorSchemeSeed([
    FlexSchemeVariant variant = FlexSchemeVariant.tonalSpot,
    Brightness brightness = Brightness.light,
  ]) =>
      SeedColorScheme.fromSeeds(
        primaryKey: this,
        variant: variant,
        brightness: brightness,
        useExpressiveOnContainerColors: false,
      );
}
