/*!
	@header		FxHostCapabilities.h

	@abstract	Defines the FxHostCapabilities object.
	@discussion	This header defines a class that describes the plug-in host environment.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */

#ifndef __FX_HOSTCAPABILITIES_H__
#define __FX_HOSTCAPABILITIES_H__

#import <Foundation/Foundation.h>
#import <FxPlug/FxTypes.h>


/*!
    @protocol   FxRenderNotificationAPI
    @abstract   A protocol for forcing the host application to re-render
    @discussion Call this protocol's sole method when you need to tell the host app that
                something in your plugin has changed which the host application doesn't
                know about. This should not be needed very often, so if you find yourself
                using it frequently, think about how you've designed your plugin.
*/

__attribute__ ((deprecated("Not supported in FxPlug 4.")))
@protocol FxRenderNotificationAPI
- (void)forceRenderAtTime:(FxTime)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));
@end



/*!
	@enum       FxTimeBase
	@constant	kFxTimeBase_TIMELINE
	@constant	kFxTimeBase_CLIP
	@discussion	A value of kFxTimeBase_TIMELINE means that times are absolute frame
				numbers, where zero is the start of the timeline. A value of kFxTimeBase_CLIP
				indicates that times are "clip-relative," meaning that zero is
				the start of the "clip." For generators and transitions, the clip is the effect
				itself. For filters, the clip is the video item to which the filter is applied.
*/
enum {
	kFxTimeBase_TIMELINE = 0,
	kFxTimeBase_CLIP = 1
};
typedef NSUInteger FxTimeBase
__attribute__ ((deprecated("Not supported in FxPlug 4.")));


/*!
	@interface	FxHostCapabilities
	@abstract	A source of information about the plug-in host environment
	@discussion	A plug-in can use this class to query the capabilities and unique characteristics of the
				host environment.
				
				<b>IMPORTANT:</b> This class was introduced in FxPlug version 1.1. If you reference
				this class in a plug-in, then it will link and be usable only if 
				version 1.1 or later of FxPlug.framework is installed. Consequently, if you use this class,
				you should either (1) make your plug-in's installer require that FxPlug 1.1 or later
				is present (and alert the user to run Software Update if it's not), or (2) retrieve
				the class by name using a string literal, like so:
<pre>@textblock		
Class theClass = NSClassFromString( @"FxHostCapabilities" );
id hostCaps = [[theClass alloc] initWithAPIManager:_apiManager];
if ( [hostCaps supportsHiddenParameters] )
	{ ... }
@/textblock</pre>
*/

@interface FxHostCapabilities : NSObject
{
@private
	struct FxHostCapabilitiesPriv	*_hostCapPriv
__attribute__ ((deprecated("Not supported in FxPlug 4.")));
}

/*!
	@method		initWithAPIManager:
	@abstract	Initializes the FxHostCapabilities object with the given API Manager
	@param		apiManager	The API Manager.
	@result		The initialized FxHostCapabilities object.
	@discussion	This is the designated initializer for the FxHostCapabilities class. You should
				always use this initializer method rather than -init.
*/
- (id)initWithAPIManager:(id)apiManager
__attribute__ ((deprecated("Not supported in FxPlug 4.")));


/*---------------------------------------------------
			HOST IDENTIFICATION METHODS 
 ---------------------------------------------------*/

/*!
	@method		hostID
	@abstract	Returns the host ID string
	@result		A string that defines the host, e.g.
		@textblock
				@"com.apple.motion" or @"com.apple.FinalCutPro"
		@/textblock
	@discussion	Normally a plug-in should not call this method. It should use one of the specific
				feature check methods, if available. If no feature check method is available, the
				plug-in should usually use -hostIsFCP, -hostIsFCE, or -hostIsMotion.
*/
- (NSString *)hostID
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		hostIsFCP
	@abstract	Indicates whether or not the host is Final Cut Pro
	@result		YES, if the host is Final Cut Pro.
	@discussion	Normally a plug-in should not call this method. It should use one of the specific
				feature check methods, if available.
*/
- (BOOL)hostIsFCP
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		hostIsFCE
	@abstract	Indicates whether or not the host is Final Cut Express
	@result		YES, if the host is Final Cut Express.
	@discussion	Normally a plug-in should not call this method. It should use one of the specific
				feature check methods, if available.
				
		<br/>	NOTE: This method was added in FxPlug version 1.2. If there is a chance that your
				plug-in will run on an earlier version of the FxPlug framework, then you should
				only call this if this method returns YES:
		@textblock
				[FxHostCapabilities respondsToSelector:@selector(hostIsFCE)]
		@/textblock
*/
- (BOOL)hostIsFCE
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		hostIsMotion
	@abstract	Indicates whether or not the host is Motion
	@result		YES, if the host is Motion.
	@discussion	Normally a plug-in should not call this method. It should use one of the specific
				feature check methods, if available.
*/
- (BOOL)hostIsMotion
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		hostVersionNumber
	@abstract	Returns the host version number
	@result		A longword that identifies the version number of the host application. For example,
				0x01230000 would be version 1.2.3. See <CarbonCore/MacTypes.h> for more info on
				the MacOS Versioning Structures, particularly the definition of the NumVersion
				structure.
	@discussion	Normally a plug-in should not call this method. It should use one of the specific
				feature check methods, if available. If no feature check method is available, the
				plug-in should usually use -hostIsFCP, -hostIsFCE, or -hostIsMotion.
*/
- (UInt32)hostVersionNumber
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*---------------------------------------------------
			FEATURE CHECK METHODS 
 ---------------------------------------------------*/

/*!
	@method		formatsFloatRGBABitmapsAsARGB
	@abstract	Indicates whether or not the host application formats 32-bit float RGBA bitmaps as ARGB
	@discussion	If this method returns NO, then all bitmaps and textures will have the correct
				pixel component order.
*/
- (BOOL)formatsFloatRGBABitmapsAsARGB
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		supportsHiddenParameters
	@abstract	Indicates whether or not the host application heeds the flag kFxParameterFlag_HIDDEN
	@discussion	If this method returns NO, then parameter hiding is supported.
*/
- (BOOL)supportsHiddenParameters
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		supportsDisabledParameters
	@abstract	Indicates whether or not the host application heeds the flag kFxParameterFlag_DISABLED
	@discussion	If this method returns NO, then parameter disabling is supported.
*/
- (BOOL)supportsDisabledParameters
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		supportsGroupParameters
	@abstract	Indicates whether or not the host application supports group parameters
	@discussion	If this method returns NO, then group parameters, as well as the
				kFxParameterFlag_COLLAPSED parameter flag, are supported. If it returns YES, then
				the methods -startParameterSubGroup: and -endParameterSubGroup: will be ignored.
*/
- (BOOL)supportsGroupParameters
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		notifiesParameterChangedForGenerators
	@abstract	Indicates whether or not the host application calls the -parameterChanged: method for
				generator effects
	@discussion	In FxPlug 1.0, the -parameterChanged: was part of the FxFilter protocol. In 1.1, it
				was moved into the parent FxBaseEffect protocol. Consequently, host apps that
				support only the FxPlug 1.0 SDK will call the -parameterChanged: method for filters,
				but not for generators. If this method returns NO, then -parameterChanged: will be
				called for all types of effects.
*/
- (BOOL)notifiesParameterChangedForGenerators
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		parameterChangedUsableForAllParameters
	@abstract	Indicates whether or not the -parameterChanged: method is usable for all
				parameter types (rather than only for custom parameters)
	@discussion	If this method returns NO, then -parameterChanged: is usable only for custom
				parameter types (or, more accurately, the FxActionAPI is inaccessible for standard
				parameter types, so you can't use change notification to modify parameter settings).
				If YES, then -parameterChanged is usable for all parameter types.
*/
- (BOOL)parameterChangedUsableForAllParameters
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		upscalesFields
	@abstract	Indicates whether or not the host application vertically upscales single fields 		
				to full-frame dimensions
	@discussion	Motion upscales single fields to full-frame dimensions (and this method returns 		
				YES). Final Cut does not upscale single fields (and this method returns NO).			
*/
- (BOOL)upscalesFields
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		supportsTemporalBitmaps
	@abstract	Indicates whether or not the host application returns trustworthy bitmaps for
				FxTemporalImageAPI and image well parameters
	@discussion	If this method returns NO, then bitmap images returned by the FxTemporalImageAPI,
				and by the -getBitmap: method in the FxParameterRetrievalAPI protocol, may have
				incorrect pixel aspect or pixel size, or other problems. If this is the case, and
				if you need to use imageReference parameters or FxTemporalImageAPI, then you
				should restrict your plug-in to using only textures, by setting the
				canRenderSoftware value to NO in your -frameSetup: method.
*/
- (BOOL)supportsTemporalBitmaps
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		timeBase
	@abstract	Indicates whether the time values used by the host application are relative or
				absolute
	@discussion	If this method returns kFxTimeBase_TIMELINE, then times are absolute frame
				numbers, where zero is the start of the timeline. If it returns kFxTimeBase_CLIP,
				then times are "clip-relative," meaning that zero is the start of the "clip."
				For generators and transitions, the clip is the effect itself. For filters, the
				clip is the video item to which the filter is applied.
				
		<br/>	NOTE: Other FxTimeBase values could be added in the future, so you should not
				assume that the only valid values are kFxTimeBase_TIMELINE and kFxTimeBase_CLIP.
*/
- (FxTimeBase)timeBase
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		glContextPixelFormatAttributes
	@abstract	Returns the list of pixel format attributes used to create the GL context
	@result		An NSArray of NSNumbers, each of which is a CGPixelFormatAttribute value.
	@discussion	This method allows a plug-in to create GL contexts that are compatible with
				those created by the host application. A plug-in typically puts the values
				for each element of the returned array into an C-style zero-terminated array
				of CGPixelFormatAttributes, and passes a pointer to that array to
				CGLChoosePixelFormat(). It then passes the CGLPixelFormatObj returned by
				that function to CGLCreateContext() and then to CGLDestroyPixelFormat().
*/
- (NSArray *)glContextPixelFormatAttributes
__attribute__ ((deprecated("Not supported in FxPlug 4.")));


@end

#endif
