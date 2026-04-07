/*!
	@header		FxImage.h
	
	@abstract	Defines the FxImage class.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */

#ifndef __FX_IMAGE_H__
#define __FX_IMAGE_H__

#import <FxPlug/FxTypes.h>
#import <FxPlug/FxMatrix.h>
#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

/*!
    @constant   kFxImage_V1
    @discussion Version 1 of the FxImage class. Introduced in FxPlug 2.0. Host applications 
                implementing earlier versions of FxImage will return 0 for the version.
*/
#define kFxImage_V1  1

/*!
    @constant   kFxImage_CurrentVersion
    @discussion The current highest version of the FxImage class.
*/
#define kFxImage_CurrentVersion  kFxImage_V1




/*!
	@enum FxImageType
	@discussion Identifies the type of an image. Introduced with FxImage Version 0.
	@constant kFxImageType_UNKNOWN	Unknown image type. (You should never encounter this.)
	@constant kFxImageType_BITMAP	RAM-based bitmap image.
	@constant kFxImageType_TEXTURE	OpenGL-based texture image.
*/
enum {
	kFxImageType_UNKNOWN = 0,
	kFxImageType_BITMAP = 1,
	kFxImageType_TEXTURE = 2
};
typedef NSUInteger FxImageType;

/*!
	@enum FxPixelFormat
	@discussion	The format of the pixels for an image.
				
				NOTES:
				
                Introduced with FxImage version 0.
	@constant	kFxPixelFormat_RGBA	RGB+A pixels with component order R,G,B,A.
	@constant	kFxPixelFormat_ARGB	RGB+A pixels with component order A,R,G,B.
*/
enum {
	kFxPixelFormat_RGBA = 0,
	kFxPixelFormat_ARGB = 2,
};
typedef NSUInteger FxPixelFormat;


/*!
	@enum FxImageOrigin
	
	@constant kFxImageOrigin_BOTTOM_LEFT	Right-handed "bottom-up" coordinate system where Y
											values increase upwardly.
	@constant kFxImageOrigin_TOP_LEFT		Left-handed "top-down" coordinate system where Y 			
											values increase downwardly.
	@discussion Identifies the orientation of an image's coordinate system. Images in Motion have
				a bottom-left origin. Images in Final Cut have a top-left origin. Introduced
                in FxImage version 0.
*/
enum {
	kFxImageOrigin_BOTTOM_LEFT = 0,
	kFxImageOrigin_TOP_LEFT = 2
};
typedef NSUInteger FxImageOrigin;


/*!
	@enum FxImageColorInfo

	@constant kFxImageColorInfo_RGB_LINEAR										RGB linear (not gamma corrected)
	@constant kFxImageColorInfo_RGB_GAMMA_VIDEO									RGB at video gamma (2.2)
	@discussion Identifies some color properties of an FxImage. These include the color space, and
                gamma level. Introduced in FxImage version 0.
*/
enum {
	kFxImageColorInfo_RGB_LINEAR = 0,
	kFxImageColorInfo_RGB_GAMMA_VIDEO = 2
};
typedef NSUInteger FxImageColorInfo;

/*!
 @const		kFxPropertyKey_DesiredProcessingColorInfo
 @abstract	Key for properties dictionary
 @discussion	The value for this key is an NSNumber indicating the colorspace
				that the plug-in would like to process in. This color space is
				expressed as an FxImageColorInfo enum. If a plug-in specifies this,
				and the host supports it, all inputs will be in this colorspace,
				and the output must also be in this colorspace. This may not
				be supported by all hosts, so the plug-in should still check
				the colorInfo of its input and output images.
 */
#define kFxPropertyKey_DesiredProcessingColorInfo	@"DesiredProcessingColorInfo"

/*!
 +    @typedef    FxColorPrimaries
 +    @discussion An enum that represents a set of color primaries
 +*/

enum {
    kFxColorPrimaries_Rec709 = 0,
    kFxColorPrimaries_Rec2020
};
typedef NSUInteger FxColorPrimaries;


/*!
	@typedef	FxImageInfo
	@abstract	Structure that defines the parameters of an image.
	@field		width			The width of the image in pixels.
	@field		height			The height of the image in pixels.
	@field		depth			The depth of each pixel component. Must be 8 for UInt8, 16 for float
								16, or 32 for float 32.
	@field		activeChannels	The number of channels in the image. Should always be 4.
	@field		imageType		The type (bitmap or texture) of the image.
	@field		origin			The orientation of the image's coordinate system (top-down or
								bottom-up).
	@field		pixelFormat		The format of each pixel (ARGB or RGBA).
	@field		isPremultiplied	YES if the RGB values are premultiplied by the alpha. Should always
								be YES.
	@field		pixelAspect		The ratio of the width of each pixel to its height (e.g. 1.0 =
								Square Pixel, 0.9 = NTSC DV, etc.).
	@discussion	The FxImageInfo structure describes an image and is used to create a new image.
                Introduced in FxImage version 0.
*/
typedef struct
{
	NSUInteger			 width;
	NSUInteger			 height;
	NSUInteger			 depth;
	NSUInteger			 activeChannels;
	FxImageType		     imageType;
	FxImageOrigin	     origin;
	FxPixelFormat        pixelFormat;
	BOOL				 isPremultiplied;
	double				 pixelAspect;
} FxImageInfo
__attribute__ ((deprecated("Not supported in FxPlug 4. Use FxImageTile.")));



/*!
    @enum   FxPixelTransformSupport
 
    @constant   kFxPixelTransform_Scale                 Handles only (non-uniform) scaling - this is 
                                                        the minimum required
    @constant   kFxPixelTransform_ScaleTranslate        Handles non-uniform scaling, and arbitrary 
                                                        translation
    @constont   kFxPixelTransform_Full                  Handles full perspective transforms
*/
enum {
    kFxPixelTransform_Scale             = 1,
    kFxPixelTransform_ScaleTranslate    = 3,
    kFxPixelTransform_Full              = 6
};
typedef NSUInteger FxPixelTransformSupport
__attribute__ ((deprecated("FxPlug 4 must support pixel transforms.")));

/*!
    @constant   kFxPropertyKey_PixelTransformSupport    Tells the host app which type of pixel
                                                        transformations your plug-in supports
*/
#define kFxPropertyKey_PixelTransformSupport  @"PixelTransformSupport"




/*!
	@class FxImage
	@abstract The parent class of FxBitmap and FxTexture.
*/
@interface FxImage : NSObject <NSCopying>
{
@private
	struct FxImagePriv	*_imagePriv
__attribute__ ((deprecated("Not supported in FxPlug 4.")));
}

/*!
	@method		imageInfo
	@abstract	Returns the FxImageInfo structure that describes the image. Introduced in FxImage 
                version 0.
	@result		The FxImageInfo structure.
*/
- (FxImageInfo)imageInfo
__attribute__ ((deprecated("Not supported in FxPlug 4. Use FxImageTile.")));

/*!
	@method		width
	@abstract	Returns the width of the image. Introduced in FxImage version 0.
	@result		The width of the image in pixels.
*/
- (NSUInteger)width
__attribute__ ((deprecated("Use tilePixelBounds in FxImageTile.")));

/*!
	@method		height
	@abstract	Returns the height of the image. Introduced in FxImage version 0.
	@result		The height of the image in pixels.
*/
- (NSUInteger)height
__attribute__ ((deprecated("Use tilePixelBounds in FxImageTile.")));

/*!
	@method		depth
	@abstract	Returns the depth of the image in bits per pixel. Introduced in FxImage version 0.
	@result		The depth of the image.
*/
- (NSUInteger)depth
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		bytes
	@abstract	Return the number of bytes per pixel component. Introduced in FxImage version 0.
	@discussion	Returns 1 (8 bits), 2 (16 bits), or 4 (32 bits).
*/
- (NSUInteger)bytes
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		imageType
	@abstract	Returns the type of the image. Introduced in FxImage version 0.
	@result		The type of the image (i.e., kFxImageType_BITMAP or kFxImageType_TEXTURE).
*/
- (FxImageType)imageType
__attribute__ ((deprecated("Not supported in FxPlug 4. Use FxImageTile type.")));

/*!
	@method		origin
	@abstract	Returns the orientation of the image. Introduced in FxImage version 0.
	@result		The FxImageOrigin value (kFxImageOrigin_BOTTOM_LEFT or kFxImageOrigin_TOP_LEFT).
	@discussion	The image origin value defines whether the Y axis increases upwardly or downwardly.
*/
- (FxImageOrigin)origin
__attribute__ ((deprecated("Use imageOrigin in FxImageTile.")));

/*!
	@method		pixelFormat
	@abstract	Returns the pixel format of the image. Introduced in FxImage version 0.
	@result		The FxPixelFormat value.
*/
- (FxPixelFormat)pixelFormat
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		isPremultiplied
	@abstract	Indicates whether the image's RGB values are premultiplied by its Alpha values.
                Introduced in FxImage version 0.
	@result		YES if premultiplied; NO otherwise.
*/
- (BOOL)isPremultiplied
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		pixelAspect
	@abstract	Returns the pixel aspect ratio of the image. Introduced in FxImage version 0.
	@result		The pixel aspect ratio of the image. For example, this method returns 0.9 for an
				NTSC DV image.
*/
- (double)pixelAspect
__attribute__ ((deprecated("Not supported in FxPlug 4. Use pixelTransform in FxImageTile.")));

/*!
	@method		fieldOrder
	@abstract	Returns the field order of the image stream. Introduced in FxImage version 0.
	@result		The field order (kFxFieldOrder_PROGRESSIVE,	kFxFieldOrder_UPPER_FIRST, or
				kFxFieldOrder_LOWER_FIRST).
	@discussion	This method was introduced in FxPlug 1.2. You should check to see if it is
				implemented before calling it:
		@textblock
				if ( [theFxImage respondsToSelector:@selector(fieldOrder)] )
		@/textblock 
*/
- (FxFieldOrder)fieldOrder
__attribute__ ((deprecated("Use fieldOrder in FxImageTile.")));

/*!
	@method		setFieldOrder:
	@abstract	Sets the field order of the image stream. Introduced in FxImage version 0.
	@param		fieldOrder	The field order of the image stream
							(kFxFieldOrder_PROGRESSIVE,	kFxFieldOrder_UPPER_FIRST, or
							kFxFieldOrder_LOWER_FIRST).
	@discussion	This method was introduced in FxPlug 1.2. You should check to see if it is
				implemented before calling it:
		@textblock
				if ( [theFxImage respondsToSelector:@selector(setFieldOrder:)] )
		@/textblock 
*/
- (void)setFieldOrder:(FxFieldOrder)fieldOrder
__attribute__ ((deprecated("Use fieldOrder in FxImageTile.")));

/*!
	@method		field
	@abstract	Returns the field identifier of the image. Introduced in FxImage version 0.
	@result		The field identifier of the image (kFxField_NONE, kFxField_UPPER, or
				kFxField_LOWER).
	@discussion	This method was introduced in FxPlug 1.2. You should check to see if it is
				implemented before calling it:
		@textblock
				if ( [theFxImage respondsToSelector:@selector(field)] )
		@/textblock 
*/
- (FxField)field
__attribute__ ((deprecated("Use field in FxImageTile.")));

/*!
	@method		setField:
	@abstract	Sets the field identifier of the image. Introduced in FxImage version 0.
	@param		field	The field identifier of the image (kFxField_NONE, kFxField_UPPER,
						or kFxField_LOWER).
	@discussion	This method was introduced in FxPlug 1.2. You should check to see if it is
				implemented before calling it:
		@textblock
				if ( [theFxImage respondsToSelector:@selector(setField:)] )
		@/textblock 
*/
- (void)setField:(FxField)field
__attribute__ ((deprecated("Use field in FxImageTile.")));

/*!
	@method		colorInfo
	@abstract	Returns the color properties of the image. Introduced in FxImage version 0.
	@discussion	This method was introduced in FxPlug 1.2.2. You should check to see if it is
				implemented before calling it:
		@textblock
				if ( [theFxImage respondsToSelector:@selector(colorInfo)] )
		@/textblock 
 
                In Motion while running under Leopard, this method will return 
                kFxImageColorInfo_RGB_GAMMA_DEFAULT_MACINTOSH_DISPLAY indicating that images are 
                in Gamma 1.8. But under SnowLeopard, it will return 
                kFxImageColorInfo_RGB_GAMMA_VIDEO indicating Gamma 2.2.
*/
- (FxImageColorInfo)colorInfo
__attribute__ ((deprecated("Not supported in FxPlug 4.")));


/*!
	@method		setColorInfo
	@abstract	Sets the color properties of the image. Introduced in FxImage version 0.
	@discussion	This method was introduced in FxPlug 1.2.2. You should check to see if it is
				implemented before calling it:
		@textblock
				if ( [theFxImage respondsToSelector:@selector(setColorInfo)] )
		@/textblock 
*/
- (void)setColorInfo:(FxImageColorInfo)colorInfo
__attribute__ ((deprecated("Not supported in FxPlug 4.")));


/*!
    @method     colorSpace
    @abstract   Returns a CGColorSpaceRef that matches the color space used in creating the image.
    @discussion The return value is a CGColorSpaceRef that contains a colorspace which matches
                the value returned from -colorInfo. Usually, this will be a linear RGB colorspace
                with Rec 709 primaries.
                This method was introduced in FxPlug 2.0. 
*/
- (CGColorSpaceRef)colorSpace
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
    @method     FxColorPrimaries
    @abstract   Returns an enum describing the color space of the image.
*/
- (FxColorPrimaries)fxColorPrimaries
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
    @method     bounds
    @abstract   Returns the floating point bounding rectangle of the image in its own coordinate 
                space. In other words, this is the full-sized, square-pixel dimensions of the image.
                So if you have an NTSC DV image which has 720 x 480 pixels with a pixel aspect
                ratio of 10/11, the bounds will be (654.54... x 480).
                Introduced in FxImage version 1.
    @discussion This method was introduced in FxPlug 2.0. You should check to see if it is
				implemented before calling it:
		@textblock
				if ( [theFxImage respondsToSelector:@selector(bounds)] )
		@/textblock
*/
- (CGRect)bounds
__attribute__ ((deprecated("Use tilePixelBounds in FxImageTile.")));

/*!
    @method     dod
    @abstract   Returns the domain of definition for this image. The width and height of this 
                rectangle will be equal to the number of pixels across or down the image.
                Introduced in FxImage version 1.
    @discussion This method was introduced in FxPlug 2.0. You should check to see if it is
				implemented before calling it:
		@textblock
				if ( [theFxImage respondsToSelector:@selector(dod)] )
		@/textblock
*/
- (FxRect)dod
__attribute__ ((deprecated("Use imagePixelBounds in FxImageTile.")));

/*!
    @method     pixelTransform
    @discussion Returns the pixel transform of the image. Introduced in FxImage version 1, in 
                FxPlug version 2.0.
*/
- (FxMatrix44*)pixelTransform
__attribute__ ((deprecated("Use pixelTransform in FxImageTile.")));

/*!
    @method     inversePixelTransform
    @discussion Returns the inverse pixel transform of the image. Introduced in FxImage version 1,
                in FxPlug version 2.0.
*/
- (FxMatrix44*)inversePixelTransform
__attribute__ ((deprecated("Use inversePixelTransform in FxImageTile.")));

/*!
    @method     version
    @discussion Returns which version of the FxImage class is currently being used. Introduced in 
                FxImage version 1, in FxPlug version 2.0.
*/
- (NSUInteger)version
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
    @method     eyeType
    @abstract   Returns the eyeType of the image stream. Introduced in FxImage version 4.
    @result     The eye type (kFxEyeType_MONO, kFxEyeType_LEFT, kFxEyeType_RIGHT).
    @discussion Since this method was introduced in FxPlug 4.0, you should check to see if it is
                implemented before calling it:
        @textblock
                if ( [theFxImage respondsToSelector:@selector(eyeType)] )
        @/textblock
 */
- (FxEyeType)eyeType
__attribute__ ((deprecated("Use eyeType in FxImageTile.")));
@end

#endif
