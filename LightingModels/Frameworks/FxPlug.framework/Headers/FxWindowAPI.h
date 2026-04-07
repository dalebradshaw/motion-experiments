/*!
	@header		FxWindowAPI.h
	@abstract	Defines the FxWindowAPI protocol.
	@discussion	These protocols are required for plug-ins that want to properly manage
                windows within the host application's UI.
*/

/* Copyright © 2010-2021 Apple Inc. All rights reserved. */

#ifndef __FX_WINDOW_API_H__
#define __FX_WINDOW_API_H__

/*!
    @protocol   FxWindowAPI
    @abstract   A set of host methods a plug-in can call to create and destroy a window
    @discussion If your plug-in needs to create or destroy a window, it should do so using
                this API. This will allow the host to create windows which match the
                host look and feel, and to track resource usage.
*/
__attribute__ ((deprecated("Not supported in FxPlug 4.")))
@protocol FxWindowAPI

/*!
    @method     createWindowWithContentRect:
    @abstract   Tells the host application to create a new window with the given size.
    @param      contentRect     The bounding rectangle of the content area of the window you
                                wish the host application to create.
    @result     Returns a pointer to an NSWindow object or nil if it failed to allocate one.
 
*/
- (NSWindow*)createWindowWithContentRect:(NSRect)contentRect
__attribute__ ((deprecated("Not supported in FxPlug 4.")));


/*!
    @method     destroyWindow:
    @abstract   Tells the host application to release the resources used by the window.
    @param      window      The window to be released.
 
*/
- (void)destroyWindow:(NSWindow*)window
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

@end



/*!
    @protocol   FxWindowHost
    @abstract   Your plug-in must implement this protocol if it wishes to host windows in the
                applications UI.
    @discussion If you implement this protocol, the host application will let your plug-in know
                when is the appropriate time to remove your custom windows from the UI.
*/
__attribute__ ((deprecated("Not supported in FxPlug 4.")))
@protocol FxWindowHost

/*!
    @method     destroyAllWindows
    @abstract   When called, your plug-in should release any windows it created during its 
                operation.
 
*/
- (void)destroyAllWindows
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

@end

#endif // __FX_WINDOW_API_H__

