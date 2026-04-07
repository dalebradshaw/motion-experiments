/*!
	@header		FxCustomParameterUI.h
	@abstract	Defines the plug-in protocol and host-API protocol for Custom Parameter View
				support.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */

#import <Cocoa/Cocoa.h>
#import <FxPlug/FxTypes.h>

/*!
	@protocol   FxCustomParameterViewHost
	@abstract   Defines the methods a plug-in needs to implement to associate a custom NSView with
				one of its parameters.
	@discussion	An FxPlug that wants to present custom UI for one or more of its parameters must
				conform to the FxCustomParmeterViewHost protocol. This protocol allows the plug-in
				to provide a subclass of NSView. It is up to the plug-in to handle NSEvents in its
				custom view(s). When an event in a custom view necessitates a change to the value
				of the associated parameter, the plug-in then uses methods in the host API
				FxCustomParameterActionAPI to tell the host application to change the parameter
				value. Note that only FxPlug 3 and earlier plug-ins should implement this protocol.
                If you're writing an FxPlug 4, use the "v2" or later protocol.
*/
__attribute__ ((deprecated("Use FxCustomParameterViewHost_v2 instead.")))
@protocol FxCustomParameterViewHost

/*!
	@method		createViewForParm:
	@abstract   Provides an NSView to be associated with the given parameter.
	@param		parmId	The ID of the parameter to be associated with the custom UI.
	@result		An NSView or subclass of NSView.
	@discussion	This plug-in method is called by the host application during the parameter-list
				setup sequence, once for each plug-in parameter that has the
				kFxParameterFlag_CUSTOM_UI parameter flag set. The view may be created dynamically,
				or, more commonly, retrieved from a NIB file in the plug-in's resources directory.
		<br/>
				NOTE: The object returned by this method should not be autoreleased. It should be
				allocated by the method, and will be released by the caller. The implementation
				may look something like this:
		<br/>
				if ( parmId == kMyViewParmID )
					return [[MyView alloc] init];
*/
- (NSView *)createViewForParm:(UInt32)parmId NS_RETURNS_RETAINED
__attribute__ ((deprecated("Use -createViewForParameterID: from FxCustomParameterViewHost_v2 instead.")));

@end

// FxPlug 4 and later should implement this protocol
@protocol FxCustomParameterViewHost_v2

/*!
	@method		createViewForParameterID:
	@abstract   Provides an NSView to be associated with the given parameter.
	@param		parameterID -  The ID of the parameter to be associated with the custom UI.
	@result		An NSView or subclass of NSView.
	@discussion	This plug-in method is called by the host application during the parameter-list
				setup sequence, once for each plug-in parameter that has the
				@c kFxParameterFlag_CUSTOM_UI parameter flag set. The view may be created
                dynamically, or, more commonly, retrieved from a NIB file in the plug-in's resources
                directory.
 
				NOTE: The object returned by this method should not be autoreleased. It should be
				allocated by the method, and will be released by the caller. The implementation
				may look something like this:
<pre>@textblock
if ( parmId == kMyViewParmID )
return [[MyView alloc] init];
@/textblock</pre>
*/
- (NSView *)createViewForParameterID:(UInt32)parameterID NS_RETURNS_RETAINED;

@end




/*!
	@protocol   FxCustomParameterActionAPI
	@abstract   Defines the methods the host application provides to support a custom parameter
				view.
	@discussion	Because custom-parameter views may get user events at any time, this protocol
				provides methods to prepare the host application for parameter changes or other
				actions at arbitrary times.
				
				NOTE: It is NOT safe to set or get parameter values at arbitrary times outside of a
				startAction:/endAction: pair. For example, when a custom-parameter view receives a
				keyDown event, it may want to change its parameter value. It would then call the
				following sequence:
				
<pre>@textblock
id <FxCustomParameterActionAPI> actionAPI = [apiManager apiForProtocol:FxCustomParameterActionAPI];
id <FxParameterSettingAPI> settingAPI = [apiManager apiForProtocol:FxParameterSettingAPI];
double time = [actionAPI currentTime];
  
[actionAPI startAction:self];
[settingAPI setCustomParameterValue:myObject toParm:myParameterID];
[actionAPI endAction:self];
@/textblock</pre>
*/
__attribute__ ((deprecated("Use FxCustomParameterActionAPI_v4 instead.")))
@protocol FxCustomParameterActionAPI

/*!
	@method		startAction:
	@abstract   Prepares the host to access parameters.
	@param		sender	The view class that implements this protocol. Typically passed as self.
                It is important to note that OSC plug-ins (implementing FxOnScreenControl) should 
                not use startAction / endAction, as the host is already aware that parameters are 
                likely to change.
*/
- (void)startAction:(id)sender
__attribute__ ((deprecated("Use -startAction: from FxCustomParameterActionAPI_v4 instead.")));

/*!
	@method		endAction:
	@abstract   Tells the host application that the plug-in is done accessing parameters.
	@param		sender	The view class that implements this protocol. Typically passed as self.
                It is important to note that OSC plug-ins (implementing FxOnScreenControl) should 
                not use startAction / endAction, as the host is already aware that parameters are 
                likely to change.
*/
- (void)endAction:(id)sender
__attribute__ ((deprecated("Use -endAction: from FxCustomParameterActionAPI_v4 instead.")));

/*!
	@method		currentTime
	@abstract   Returns the current time, expressed in canonical frames.
	@result		The current time, expressed as a floating-point frame number, in canonical
				frames.
	@discussion	This is useful when a custom parameter view needs to set a parameter value in
				response to a user event. Depending on the host application, the time value
				may be relative to the start of the timeline or to the start of the clip. See
				the header file FxPlug/FxHostCapabilities.h
*/
- (double)currentTime
__attribute__ ((deprecated("Use -currentTime: from FxCustomParameterActionAPI_v4 instead.")));





@end
__attribute__ ((deprecated("Use FxCustomParameterActionAPI_v4 instead.")))
@protocol FxCustomParameterActionAPI_v2  <FxCustomParameterActionAPI>


/*!
    @method     documentBounds
    @abstract   Returns an NSRect containing the boundaries of the current sequence.
    @discussion This is useful in the case where an FxPlug needs to know the sequence 
                dimensions, rather than the inputs' boundaries. 
*/
- (NSRect)documentBounds
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

@end


/*
    NOTE: This API is only available to plug-ins built in the FxPlug 3 style and later.
 */
__attribute__ ((deprecated("Use FxCustomParameterActionAPI_v4 instead.")))
@protocol FxCustomParameterActionAPI_v3  <FxCustomParameterActionAPI_v2>

- (void)currentFxTime:(FxTime*)outTime
__attribute__ ((deprecated("Use -currentTime: from FxCustomParameterActionAPI_v4 instead.")));

@end


/*!
    @protocol   FxCustomParameterActionAPI_v4
 	@abstract   Defines the methods the host application provides to support a custom parameter
				view.
	@discussion	Because custom-parameter views may get user events at any time, this protocol
				provides methods to prepare the host application for parameter changes or other
				actions at arbitrary times.
 
				NOTE: It is NOT safe to set or get parameter values at arbitrary times outside of a
				startAction:/endAction: pair. For example, when a custom-parameter view receives a
				keyDown event, it may want to change its parameter value. It would then call the
				following sequence:
 
<pre>@textblock
id <FxCustomParameterActionAPI> actionAPI = [apiManager apiForProtocol:FxCustomParameterActionAPI];
id <FxParameterSettingAPI> settingAPI = [apiManager apiForProtocol:FxParameterSettingAPI];
CMTime time = [actionAPI currentTime];
 
[actionAPI startAction:self];
[settingAPI setCustomParameterValue:myObject toParameter:myParameterID atTime:time];
[actionAPI endAction:self];
@/textblock</pre>
 
                This protocol is only available to FxPlug 4 and later plug-ins.
 */
@protocol FxCustomParameterActionAPI_v4

/*!
	@method		startAction:
	@abstract   Prepares the host to access parameters.
	@param		sender	The view class that implements this protocol. Typically passed as self.
    @discussion It is important to note that OSC plug-ins (implementing @c FxOnScreenControl) should
                not use @c startAction / @c endAction, as the host is already aware that parameters
                are likely to change.
*/
- (void)startAction:(id)sender;

/*!
	@method		endAction:
	@abstract   Tells the host application that the plug-in is done accessing parameters.
	@param		sender	The view class that implements this protocol. Typically passed as self.
    @discussion It is important to note that OSC plug-ins (implementing @c FxOnScreenControl) should
                not use @c startAction / @c endAction, as the host is already aware that parameters
                are likely to change.
*/
- (void)endAction:(id)sender;

/*!
	@method		currentTime
	@abstract   Returns the current time, expressed as a rational time.
	@result		The current time, expressed as a rational time.
	@discussion	This is useful when a custom parameter view needs to set a parameter value in
				response to a user event. Depending on the host application, the time value
				may be relative to the start of the timeline or to the start of the clip. See
				the header file FxPlug/FxHostCapabilities.h
*/
- (CMTime)currentTime;

@end
