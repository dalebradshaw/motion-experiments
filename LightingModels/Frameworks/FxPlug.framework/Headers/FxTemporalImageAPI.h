/*!
	@header		FxTemporalImageAPI.h

	@abstract	Defines the FxTemporalImageAPI host-API protocol.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */

#ifndef __FX_TEMPORAL_IMAGE_API_H__
#define __FX_TEMPORAL_IMAGE_API_H__

#import <Foundation/Foundation.h>
#import <FxPlug/FxBitmap.h>
#import <FxPlug/FxTexture.h>

#pragma mark -

/*!
	@protocol		FxTemporalImageAPI
	@abstract		Defines the methods the host application provides to access an input image at a
					specific time.
	@discussion		Usually the only plug-in that needs to use this host API is an FxFilter that
					does "retiming," i.e. a filter whose output depends on input frames at times
					other than the output time.

					<br/>NOTE: A plug-in that uses this API should set the value for the
					kFxPropertyKey_MayRemapTime key, in the NSDictionary its -properties method
					returns.
*/
__attribute__ ((deprecated("Not supported in FxPlug 4.")))
@protocol FxTemporalImageAPI

/*!
	@method		getInputBitmap:withInfo:atTime:
	@abstract   Gets a bitmap image from the immediate input, including leading filters.
	@param		image		Variable for a pointer to a bitmap. (NOTE: this bitmap must be released
							by the sender when processing is complete.)
	@param		renderInfo  Information about the requested image, including quality, scale, and
							bitdepth.
	@param		time		Specified time, expressed in canonical frames, to get the image.
	@result		Returns YES if the input bitmap is retrieved successfully; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
				timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
*/	
- (BOOL)getInputBitmap:(FxBitmap **)image
			  withInfo:(FxRenderInfo)renderInfo
				atTime:(double)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		getInputTexture:withInfo:atTime:
	@abstract   Gets a texture image from immediate input, including leading filters.
	@param		image		Variable for a pointer to a texture.   (NOTE: this texture must be
							released by the sender when processing is complete.)
	@param		renderInfo  Information about the requested image, including quality, scale, and
							bitdepth.
	@param		time		Specified time, expressed in canonical frames, to get the image.
	@result		Returns YES if the input texture is retrieved successfully; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
				timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
*/
- (BOOL)getInputTexture:(FxTexture **)image
			   withInfo:(FxRenderInfo)renderInfo
				 atTime:(double)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		getSourceBitmap:withInfo:atTime:
	@abstract   Gets a bitmap image from source footage, ignoring leading filters.
	@param		image		Variable for a pointer to a bitmap.   (NOTE: this bitmap must be
							released by the sender when processing is complete).
	@param		renderInfo  Information about the requested image, including quality, scale, and
							bitdepth.
	@param		time		Specified time, expressed in canonical frames, to get the image.
	@result		Returns YES if the input bitmap is retrieved successfully; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
				timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
*/
- (BOOL)getSourceBitmap:(FxBitmap **)image
			   withInfo:(FxRenderInfo)renderInfo
				 atTime:(double)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		getSourceTexture:withInfo:atTime:
	@abstract   Gets a texture image from source footage, ignoring leading filters.
	@param		image		Variable for a pointer to a texture.   (NOTE: this texture must be
							released by the sender when processing is complete).
	@param		renderInfo  Information about the requested image, including quality, scale, and
							bitdepth.
	@param		time		Specified time, expressed in canonical frames, to get the image.
	@result		Returns YES if the input texture is retrieved successfully; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
				timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
*/
- (BOOL)getSourceTexture:(FxTexture **)image
				withInfo:(FxRenderInfo)renderInfo
				  atTime:(double)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

@end


/*
    NOTE: This API is only available to plug-ins built in the FxPlug 3 style and later.
 */
__attribute__ ((deprecated("Not supported in FxPlug 4.")))
@protocol FxTemporalImageAPI_v2 <FxTemporalImageAPI>

/*!
	@method		getInputBitmap:withInfo:atFxTime:
	@abstract   Gets a bitmap image from the immediate input, including leading filters.
	@param		image		Variable for a pointer to a bitmap. (NOTE: this bitmap must be released
                            by the sender when processing is complete.)
	@param		renderInfo  Information about the requested image, including quality, scale, and
                            bitdepth.
	@param		time		Specified time, expressed in rational time, to get the image.
	@result		Returns YES if the input bitmap is retrieved successfully; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
                timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
 */
- (BOOL)getInputBitmap:(FxBitmap **)image
              withInfo:(FxRenderInfo)renderInfo
              atFxTime:(FxTime)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		getInputTexture:withInfo:atFxTime:
	@abstract   Gets a texture image from immediate input, including leading filters.
	@param		image		Variable for a pointer to a texture.   (NOTE: this texture must be
                            released by the sender when processing is complete.)
	@param		renderInfo  Information about the requested image, including quality, scale, and
                            bitdepth.
	@param		time		Specified time, expressed in rational time, to get the image.
	@result		Returns YES if the input texture is retrieved successfully; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
                timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
 */
- (BOOL)getInputTexture:(FxTexture **)image
               withInfo:(FxRenderInfo)renderInfo
               atFxTime:(FxTime)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		getSourceBitmap:withInfo:atFxTime:
	@abstract   Gets a bitmap image from source footage, ignoring leading filters.
	@param		image		Variable for a pointer to a bitmap.   (NOTE: this bitmap must be
                            released by the sender when processing is complete).
	@param		renderInfo  Information about the requested image, including quality, scale, and
                            bitdepth.
	@param		time		Specified time, expressed in rational time, to get the image.
	@result		Returns YES if the input bitmap is retrieved successfully; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
                timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
 */
- (BOOL)getSourceBitmap:(FxBitmap **)image
               withInfo:(FxRenderInfo)renderInfo
               atFxTime:(FxTime)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		getSourceTexture:withInfo:atFxTime:
	@abstract   Gets a texture image from source footage, ignoring leading filters.
	@param		image		Variable for a pointer to a texture.   (NOTE: this texture must be
                            released by the sender when processing is complete).
	@param		renderInfo  Information about the requested image, including quality, scale, and
                            bitdepth.
	@param		time		Specified time, expressed in rational time, to get the image.
	@result		Returns YES if the input texture is retrieved successfully; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
                timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
 */
- (BOOL)getSourceTexture:(FxTexture **)image
                withInfo:(FxRenderInfo)renderInfo
                atFxTime:(FxTime)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

@end

#pragma mark -

/*!
	@protocol		FxTemporalTransitionImageAPI
	@abstract		Defines the methods the host application provides to access an input image at a
					specific time, from a transition.
	@discussion		Usually the only plug-in that needs to use this host API is an FxTransition
					that does "retiming," i.e. a filter whose output depends on input frames at
					times other than the output time.
					
					NOTE: A plug-in that uses this API should set the value for the
					kFxPropertyKey_MayRemapTime key, in the NSDictionary its -properties method
					returns.
*/
__attribute__ ((deprecated("Not supported in FxPlug 4.")))
@protocol FxTemporalTransitionImageAPI

/*!
	@enum FxTransitionInput
	@discussion Constants used to identify one of the two inputs to a transition.
	@constant kFxTransitionInput_A	The first transition input.
	@constant kFxTransitionInput_B	The second transition input.
*/
enum {
	kFxTransitionInput_A = 0,
	kFxTransitionInput_B = 1
};
typedef NSUInteger FxTransitionInput;

/*!
	@method		getTransitionInputImage:forInput:withFiltersApplied:withImageType:withInfo:atTime:
	@abstract   Gets an image from the transition's A or B input.
	@param		image			Variable for a pointer to an FxBitmap or FxTexture. (NOTE: the
								object must be released by the sender when processing is complete.)
	@param		whichInput		Which transition input (kFxTransitionInput_A or
								kFxTransitionInput_B).
	@param		applyFilters	YES if leading filters are to be applied, NO for raw source
								footage.
	@param		imageType		Which subclass of FxImage to use (kFxImageType_Bitmap or
								kFxImageType_Texture).
	@param		renderInfo		Information about the requested image, including quality, scale,
								and bitdepth.
	@param		time			Specified time, expressed in canonical frames, to get the image.
	@result		Returns YES if the input bitmap is retrieved successfully; NO otherwise.
	@discussion	Depending on the host application, the time value may be relative to the start of the
				timeline or to the start of the clip. See the header file FxPlug/FxHostCapabilities.h.
*/	
- (BOOL)getTransitionInputImage:(FxImage **)image
					   forInput:(FxTransitionInput)whichInput
				   applyFilters:(BOOL)applyFilters
				  withImageType:(FxImageType)imageType
					   withInfo:(FxRenderInfo)renderInfo
						 atTime:(FxTime)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

@end

#endif
