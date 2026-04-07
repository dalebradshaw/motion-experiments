//
//  FxAppearanceAPI.h
//  FxPlug
//
/* Copyright © 2013-2021 Apple Inc. All rights reserved. */


#import <Foundation/Foundation.h>
#ifndef FxPlug_FxAppearanceAPI_h
#define FxPlug_FxAppearanceAPI_h    

#import <AppKit/AppKit.h>

//Colors
__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxBackgroundWindowColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxFocusRingColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxSliderTickColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxDisabledSliderTickColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxTextBackgroundColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxWindowFrameTextColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxActiveListRowColor; //even numbered rows

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxActiveAlternateListRowColor; //odd numbered rows

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxDialDimpleBottomColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxDialDimpleOutlineColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxDialDimpleTopColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxDisabledControlTextColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxPaneBackgroundColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxPaneCapSelectedColor;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxWindowFrameColor;


//Font Dictionaries
__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxHeaderTextAttributes;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxSelectedLabelTextAttributes;

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
extern NSString* kFxItalicizedLabelTextAttributes;


__attribute__ ((deprecated("Not supported in FxPlug 4.")))
@protocol FxAppearanceAPI

-(BOOL)getThemeColor:(NSColor**)color forID:(NSString*)key
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

-(BOOL)getThemeFontDictionary:(NSDictionary**)font forID:(NSString*)key
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

@end




#endif
