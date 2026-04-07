/*!
	@header		FxBaseEffect.h
	
	@abstract	Defines the FxBaseEffect protocol.
	@discussion	This header defines the parent protocol inherited by all effect protocols:
				FxGenerator, FxFilter, and FxTransition.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */

#ifndef __FX_BASEEFFECT_H__
#define __FX_BASEEFFECT_H__

#import <FxPlug/FxTypes.h>
#import <FxPlug/FxImage.h>


/*!
	@protocol	FxBaseEffect
	@abstract   Specifies the methods that all plug-ins need to implement.
*/

__attribute__ ((deprecated("Use FxTileableEffect instead.")))
@protocol FxBaseEffect

/*!
	@method		variesOverTime
	@abstract   Specifies whether a plug-in produces different images (animation) over time using
				the same set of parameters.
	@result		Returns YES if the plug-in produces changing images without changing parameters; NO
				otherwise.
	@discussion	This hint is used to determine whether a rendered output image with a particular
				set of parameter values can be cached and reused for other frames that have
				identical parameter values.
*/
- (BOOL)variesOverTime
__attribute__ ((deprecated("Use kFxPropertyKey_VariesWhenParamsAreStatic property key from FxTileableEffect instead.")));

/*!
	@method		addParameters
	@abstract   Adds all parameters to the host application that the plug-in requires to function
				properly.
	@result		Returns YES if all parameters are successfully added; NO otherwise.
*/
- (BOOL)addParameters
__attribute__ ((deprecated("Use -addParametersWithError: from FxTileableEffect instead.")));

/*!
	@method		properties
	@abstract   Defines the plug-in's properties
	@result		An NSDictionary defining the plug-in's properties.
	@discussion	A host application will assume default values for any missing keys. The currently
				supported keys are:
				
		<br/>	- kFxPropertyKey_MayRemapTime ("MayRemapTime"): A Boolean NSNumber indicating
				  whether or not this plug-in may try to sample its input image(s) at any time
				  other than the output time.
		<br/>
		<br/>	- kFxPropertyKey_PreservesAlpha ("PreservesAlpha"): A Boolean NSNumber indicating
				  whether or not this plug-in promises to leave the alpha channel values of its
				  input image(s) untouched.
		<br/>	
		<br/>	- kFxPropertyKey_PixelIndependent ("PixelIndependent"): A Boolean NSNumber
				  indicating whether or not each pixel of this plug-in's output image depends only
				  on the value of the corresponding pixel in the input image(s) and on no other
				  pixels. This flag is used for performance optimization and for determining whether
				  or not the plug-in can operate on single fields as well as complete interleaved
				  frames.
        <br/>
                  Note that you should never have a value in both the static and dynamic properties 
                  dictionaries. If it's found in the static dictionary, the application host 
                  won't check the dynamic dictionary.
*/
- (NSDictionary *)properties
__attribute__ ((deprecated("Use -properties:error: from FxTileableEffect instead.")));

@optional

/*!
	@method		parameterChanged:
	@abstract   Reports on a change to a plug-in parameter value made by the end user. The plug-in
				can then set other parameter values based on this change.
	@param		parmId		Parameter id of the value that changed.
	@result		Returns YES if all changes are successfully handled; NO otherwise.
	@discussion	If you need to get the current time in this method (e.g. for getting or setting
				parameter values or flags), you can use the -currentTime method in the
				FxCustomParameterActionAPI (see FxCustomParameterUI.h).
				
		<br/>	NOTE: This method was omitted from the FxGenerator protocol in the FxPlug 1.0 SDK.
				In FxPlug 1.0 hosts, a generator will not receive this notification when a parameter
				value changes. To determine whether or not this method will be called for
				generators, use the FxHostCapabilities method -notifiesParameterChangedForGenerators.
*/
- (BOOL)parameterChanged:(UInt32)parmId
__attribute__ ((deprecated("Use -parameterChanged:atTime:error: from FxTileableEffect instead.")));

/*!
    @method     finishInitialSetup
    @abstract   Allows the filter to do any setup between the time it was added to the timeline
                and the first time it renders.
    @param      error       A pointer to an NSError which your plugin should fill in if any problems
                            occur during execution of this method.
    @result     Return YES if your plugin successfully completed setup, and NO if it did not. If
                you return NO, your plugin should also return an NSError* filled out with 
                information to be presented to the user in an error alert.
    @discussion If your plug-in implements this method, it will be called after -initWithAPIManager:
                and -addParameters (if you don't use dynamic parameters), but before the first
                render. You can do any setup of initial conditions you need to, or analyze any
                data you need to in this method.
*/
- (BOOL)finishInitialSetup:(NSError**)error
__attribute__ ((deprecated("Use -finishInitialSetup: from FxTileableEffect instead.")));

/*!
    @method     numberOfFramesToScheduleAtRenderTime:forParam:
    @abstract   Allows the filter to tell the host application how many frames it will need from an
                image well parameter at a given render time.
    @param      time    The time of the render
                paramID The ID of the parameter whose input times the host would like
    @result     Return the number of frames your plug-in needs from that parameter at that render 
                time.
    @discussion If your plug-in implements this method, it will be followed by a call to
                -schedule:frames:forParam:forRenderAtTime:. Both will be called before the plug-in's
                -renderOutput: method is called.
*/
- (NSUInteger)numberOfFramesToScheduleAtRenderTime:(FxTime)time
                                          forParam:(UInt32)paramID
__attribute__ ((deprecated("Use -scheduleInputs:withPluginState:atTime:error: from FxTileableEffect instead.")));

/*!
    @method     schedule:frames:forParam:forRenderAtTime:
    @abstract   Allows the filter to tell the host application which frames it will need from an
                image well parameter at a given render time.
    @param      numFrames   The number of frames you are expected to return
                frameTimes  A C array of FxTimes for you to fill out with the times of the frames
                            your plug-in will need to render
                paramID     The ID of the parameter whose input times the host would like
                renderTime  The time of the upcoming render
    @discussion If your plug-in implements this method, it will be called with an already allocated
                array of frameTimes. Your plug-in will need to fill in the array with the times
                it needs from the given parameter in order to render its output. Note that if your
                plug-in is using rational time, the array will be an array of *pointers* to CMTimes.
*/
- (void)schedule:(NSUInteger)numFrames
          frames:(FxTime[])frameTimes
        forParam:(UInt32)paramID
 forRenderAtTime:(FxTime)renderTime
 __attribute__ ((deprecated("Use -scheduleInputs:withPluginState:atTime:error: from FxTileableEffect instead.")));

/*!
    @method     dynamicPropertiesAtTime:withError:
    @abstract   Allows a plug-in to change its properties at run-time based on its parameters or
                other factors.
    @param      time    The time of the render
                error   If an error occurs, return the reason in this parameter.
    @result     A dictionary containing only the properties that your plug-in can change dynamically.
    @discussion Note that you should keep the list of dynamically varying properties to a minimum
                as the host applications check the properties frequently and it is expensive to 
                construct NSDictionaries frequently. Also, you should never have a value in both
                the static and dynamic properties dictionaries. If it's found in the static
                dictionary, the application host won't check the dynamic dictionary.
*/
- (NSDictionary*)dynamicPropertiesAtTime:(FxTime)time
                               withError:(NSError**)err
__attribute__ ((deprecated("Dynamic properties are not supported in FxPlug 4")));

@end


/**** PROPERTIES KEYS ***/

/*!
	@const		kFxPropertyKey_MayRemapTime
	@abstract	Key for properties dictionary
	@discussion	The value for this key is a Boolean NSNumber indicating whether or not this plug-in
				may try to sample its input image(s) at any time other than the output time. The
				default value is YES.
*/
#define kFxPropertyKey_MayRemapTime				@"MayRemapTime"

/*!
	@const		kFxPropertyKey_PreservesAlpha
	@abstract	Key for properties dictionary
	@discussion	The value for this key is a Boolean NSNumber indicating whether or not this plug-in
				promises to leave the alpha channel values of its input image(s) untouched. The
				default value is NO.
*/
#define kFxPropertyKey_PreservesAlpha			@"PreservesAlpha"

/*!
	@const		kFxPropertyKey_PixelIndependent
	@abstract	Key for properties dictionary
	@discussion	The value for this key is a Boolean NSNumber indicating whether or not each pixel of
				this plug-in's output image depends only on the value of the corresponding pixel in
				the input image(s) and on no other pixels. This flag is used for performance
				optimization and for determining whether or not the plug-in can operate on single
				fields as well as complete interleaved frames. The default value is NO.
*/
#define kFxPropertyKey_PixelIndependent			@"PixelIndependent"


/*!
    @const		kFxPropertyKey_IsThreadSafe
    @abstract	Key for properties dictionary
    @discussion	the value for this key is a Boolean NSNumber indicating if this effect can be called
                concurrently on multiple threads without issue
 */
#define kFxPropertyKey_IsThreadSafe             @"IsThreadSafe"

/*!
    @const		kFxPropertyKey_UsesRationalTime
    @abstract	Whether your plug-in wants rational times or times as double precision floating 
                point frames
    @discussion	the value for this key is a Boolean NSNumber indicating if this effect can use
                times that are represented as a rational number or whether it needs the old-style
                double precision floating point values that represent the frame number.
 */
#define kFxPropertyKey_UsesRationalTime         @"UsesRationalTime"

/*!
    @const      kFxPropertyKey_UsesLumaChroma
    @abstract   A key that determines whether your plug-in uses luminance or chrominance values
    @discussion When this boolean NSNumber is set to YES the host application will ensure that
                images passed to the plug-in are in the widest gamut available.
 */
#define kFxPropertyKey_UsesLumaChroma           @"UsesLumaChroma"

/*!
    @const      kFxPropertyKey_UsesNonmatchingTextureLayout
    @abstract   Whether your plug-in uses textures with one pixel layout as if they were
                a different pixel layout, such as putting 4:2:2 pixels into an RGBA buffer.
    @discussion If you use a single pixel in a texture to store more than 1 pixel, set this flag
                to YES. Otherwise set it to NO. In FxPlug 3 the default is YES, whereas in
                FxPlug 4 the default is NO.
 */
#define kFxPropertyKey_UsesNonmatchingTextureLayout @"UsesNonmatchingTextureLayout"

#endif
