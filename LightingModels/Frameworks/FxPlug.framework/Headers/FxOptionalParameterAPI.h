/*!
	@header		FxOptionalParameterAPI.h

	@abstract	Defines the FxOptionalParameter host API protocols for creating optional
				parameters, and for getting and setting optional parameter values.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */

#import <Foundation/Foundation.h>
#import <FxPlug/FxTypes.h>

/*!
	@protocol   FxOptionalParameterCreationAPI
	@abstract   Defines the methods for creating parameters of optional types. These parameter types
				are not guaranteed to be supported by all host applications.
	@discussion	See discussion of parameter IDs in the header file FxPlug/FxParameterAPI.h.
*/
__attribute__ ((deprecated("Use FxParameterCreationAPI_v5 instead.")))
@protocol FxOptionalParameterCreationAPI

/*!
	@method		addHistogramWithName:parmId:parmFlags:
	@abstract   Creates a histogram parameter.
	@param		name	Name of the parameter in the user interface.
	@param		parmId	Unique identifier for a parameter. Used to retrieve, set, or validate the
						parameter.
	@param		flags	Flags that encode various state values for the parameter.
	@result		Returns YES if the application successfully creates a histogram parameter; NO
				otherwise.
*/
- (BOOL)addHistogramWithName:(NSString *)name
                      parmId:(UInt32)parmId
                   parmFlags:(FxParameterFlags)flags
__attribute__ ((deprecated("Use -addHistogramWithName:parameterID:parameterFlags: from FxParameterCreationAPI_v5 instead.")));

/*!
	@method		addGradientWithName:parmId:parmFlags:
	@abstract   Creates a gradient parameter.
	@param		name	Name of the parameter as it appears in the user interface.
	@param		parmId	Unique identifier for a parameter. Used to retrieve, set, or validate the
				parameter.
	@param		flags	Flags that encode various state values for the parameter.
	@result		Returns YES if the application successfully creates a gradient parameter; NO
				otherwise.
*/
- (BOOL)addGradientWithName:(NSString *)name
					 parmId:(UInt32)parmId
				  parmFlags:(FxParameterFlags)flags
__attribute__ ((deprecated("Use -addGradientWithName:parameterID:parameterFlags: from FxParameterCreationAPI_v5 instead.")));

@end


/*!
	@protocol   FxOptionalParameterRetrievalAPI
	@abstract   Defines the functions the application provides to retrieve parameter values.
*/
__attribute__ ((deprecated("Use FxParameterRetrievalAPI_v6 instead.")))
@protocol FxOptionalParameterRetrievalAPI

/*!
	@method		getHistogramBlackIn:BlackOut:WhiteIn:WhiteOut:Gamma:forChannel:fromParm:atTime:
	@abstract   Gets the Histogram parameter settings.
	@param		blackIn		Pointer for the parameter black in level value.
	@param		blackOut	Pointer for the parameter black out level value.
	@param		whiteIn		Pointer for the parameter white in level value.
	@param		whiteOut	Pointer for the parameter white out level value.
	@param		gamma		Pointer for the parameter gamma level value.
	@param		channel		Specified channel for the histogram information
							(RGB: 0, Red: 1, Green: 2, Blue: 3, Alpha: 4).
	@param		parmId		Parameter identifier assigned upon creation.
	@param		time		Specified time, expressed in canonical frames, to retrieve the
							parameter values.
	@result		Returns YES if the value is successfully retrieved; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
				timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
*/
- (BOOL)getHistogramBlackIn:(double *)blackIn
				   BlackOut:(double *)blackOut
					WhiteIn:(double *)whiteIn
				   WhiteOut:(double *)whiteOut
					  Gamma:(double *)gamma
				 forChannel:(FxHistogramChannel)channel
				   fromParm:(UInt32)parmId
					 atTime:(double)time
__attribute__ ((deprecated("Use -getHistogramBlackIn:BlackOut:WhiteIn:WhiteOut:Gamma:forChannel:fromParameter:atTime: from FxParameterRetrievalAPI_v6 instead.")));

/*!
	@method		getGradientSamples:numSamples:depth:fromParm:atTime:
	@abstract   Gets the Gradient parameter settings.
	@param		samples		Pointer to a buffer of size (4 * numSamples * sampleDepth). It is
							populated with samples of RGBA values across the gradient. The number of
							samples is set by numSamples.
	@param		numSamples  Number of samples from the gradient. More samples provide a more
							accurate representation, but require more time.
	@param		sampleDepth	Number of bytes per channel (1 = 8 bit, 2 = 16 bit float, 4 = 32 bit
							float).
	@param		parmId		Parameter identifier assigned upon creation.
	@param		time		Specified time, expressed in canonical frames, to retrieve the parameter
							values.
	@result		Returns YES if the value is successfully retrieved; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
				timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
*/
- (BOOL)getGradientSamples:(void *)samples
				numSamples:(NSUInteger)numSamples
					 depth:(NSUInteger)sampleDepth
				  fromParm:(UInt32)parmId
					atTime:(double)time
__attribute__ ((deprecated("Use -getGradientSamples:numSamples:depth:fromParameter:atTime: from FxParameterRetrievalAPI_v6 instead.")));

@end

/*
    NOTE: This API is only available to plug-ins built in the FxPlug 3 style and
    later.
 */
__attribute__ ((deprecated("Use FxParameterRetrievalAPI_v6 instead.")))
@protocol FxOptionalParameterRetrievalAPI_v2 <NSObject> // NOTE: This intentionally does not inherit from FxOptionalParameterRetrievalAPI

/*!
	@method		getHistogramBlackIn:BlackOut:WhiteIn:WhiteOut:Gamma:forChannel:fromParm:atFxTime:
	@abstract   Gets the Histogram parameter settings.
	@param		blackIn		Pointer for the parameter black in level value.
	@param		blackOut	Pointer for the parameter black out level value.
	@param		whiteIn		Pointer for the parameter white in level value.
	@param		whiteOut	Pointer for the parameter white out level value.
	@param		gamma		Pointer for the parameter gamma level value.
	@param		channel		Specified channel for the histogram information
							(RGB: 0, Red: 1, Green: 2, Blue: 3, Alpha: 4).
	@param		parmId		Parameter identifier assigned upon creation.
	@param		time		Specified time, expressed in rational time, to retrieve the
							parameter values.
	@result		Returns YES if the value is successfully retrieved; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
				timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
*/
- (BOOL)getHistogramBlackIn:(double *)blackIn
				   BlackOut:(double *)blackOut
					WhiteIn:(double *)whiteIn
				   WhiteOut:(double *)whiteOut
					  Gamma:(double *)gamma
				 forChannel:(FxHistogramChannel)channel
				   fromParm:(UInt32)parmId
                   atFxTime:(FxTime)time
__attribute__ ((deprecated("Use -getHistogramBlackIn:BlackOut:WhiteIn:WhiteOut:Gamma:forChannel:fromParameter:atTime: from FxParameterRetrievalAPI_v6 instead.")));

/*!
	@method		getGradientSamples:numSamples:depth:fromParm:atFxTime:
	@abstract   Gets the Gradient parameter settings.
	@param		samples		Pointer to a buffer of size (4 * numSamples * sampleDepth). It is
							populated with samples of RGBA values across the gradient. The number of
							samples is set by numSamples.
	@param		numSamples  Number of samples from the gradient. More samples provide a more
							accurate representation, but require more time.
	@param		sampleDepth	Number of bytes per channel (1 = 8 bit, 2 = 16 bit float, 4 = 32 bit
							float).
	@param		parmId		Parameter identifier assigned upon creation.
	@param		time		Specified time, expressed in rational time, to retrieve the parameter
							values.
	@result		Returns YES if the value is successfully retrieved; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
				timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
*/
- (BOOL)getGradientSamples:(void *)samples
				numSamples:(NSUInteger)numSamples
					 depth:(NSUInteger)sampleDepth
				  fromParm:(UInt32)parmId
                  atFxTime:(FxTime)time
__attribute__ ((deprecated("Use -getGradientSamples:numSamples:depth:fromParameter:atTime: from FxParameterRetrievalAPI_v6 instead.")));

@end


/*!
@protocol   FxOptionalParameterSettingAPI
@abstract   Defines the functions the application provides to set parameter values.
*/
__attribute__ ((deprecated("Use FxParameterSettingAPI_v5 instead.")))
@protocol FxOptionalParameterSettingAPI

/*!
	@method		setHistogramBlackIn:BlackOut:WhiteIn:WhiteOut:Gamma:forChannel:fromParm:atTime:
	@abstract   Sets the values in a histogram parameter group.
	@param		blackIn		The new black in level value.
	@param		blackOut	The new black out level value.
	@param		whiteIn		The new white in level value.
	@param		whiteOut	The new white out level value.
	@param		gamma		The new gamma value.
	@param		channel		Specified channel for new histogram values
							(RGB: 0, Red : 1, Green: 2, Blue: 3, Alpha: 4).
	@param		parmId		Parameter identifier assigned upon creation.
	@param		time		Specified time, expressed in canonical frames, to set the parameter
							values.
	@result		Returns YES if the values is successfully set; NO if the parameter cannot be found.
	@discussion	Depending on the host application, the time value may be relative to the start of the
				timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
*/
- (BOOL)setHistogramBlackIn:(double)blackIn
				   BlackOut:(double)blackOut
					WhiteIn:(double)whiteIn
				   WhiteOut:(double)whiteOut
					  Gamma:(double)gamma
				 forChannel:(FxHistogramChannel)channel
				   fromParm:(UInt32)parmId
					 atTime:(double)time
__attribute__ ((deprecated("Use -setHistogramBlackIn:BlackOut:WhiteIn:WhiteOut:Gamma:forChannel:fromParameter:atTime: from FxParameterSettingAPI_v5 instead.")));

@end


/*!
 @protocol   FxOptionalParameterSettingAPI
 @abstract   Defines the functions the application provides to set parameter values.
 */
__attribute__ ((deprecated("Use FxParameterSettingAPI_v5 instead.")))
@protocol FxOptionalParameterSettingAPI_v2

/*!
	@method		setHistogramBlackIn:BlackOut:WhiteIn:WhiteOut:Gamma:forChannel:fromParm:atTime:
	@abstract   Sets the values in a histogram parameter group.
	@param		blackIn		The new black in level value.
	@param		blackOut	The new black out level value.
	@param		whiteIn		The new white in level value.
	@param		whiteOut	The new white out level value.
	@param		gamma		The new gamma value.
	@param		channel		Specified channel for new histogram values
 (RGB: 0, Red : 1, Green: 2, Blue: 3, Alpha: 4).
	@param		parmId		Parameter identifier assigned upon creation.
	@param		time		Specified time, expressed in canonical frames, to set the parameter
 values.
	@result		Returns YES if the values is successfully set; NO if the parameter cannot be found.
	@discussion	Depending on the host application, the time value may be relative to the start of the
 timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
 */
- (BOOL)setHistogramBlackIn:(double)blackIn
                   blackOut:(double)blackOut
                    whiteIn:(double)whiteIn
                   whiteOut:(double)whiteOut
                      gamma:(double)gamma
                 forChannel:(FxHistogramChannel)channel
                   fromParm:(UInt32)parmId
                   atFxTime:(FxTime)time
__attribute__ ((deprecated("Use -setHistogramBlackIn:BlackOut:WhiteIn:WhiteOut:Gamma:forChannel:fromParameter:atTime: from FxParameterSettingAPI_v5 instead.")));

@end

