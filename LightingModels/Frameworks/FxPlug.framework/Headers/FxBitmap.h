/*!
	@header		FxBitmap.h

	@abstract	Defines the FxBitmap class.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */

#ifndef __FX_BITMAP_H__
#define __FX_BITMAP_H__

#import <FxPlug/FxImage.h>

/*!
	@class      FxBitmap
	@abstract   RAM-based image for software rendering.
	@discussion	This subclass of FxImage is defined by an FxImageInfo structure. Introduced in 
                FxImage version 0.
*/
@interface FxBitmap : FxImage <NSCopying>
{
@private
	struct FxBitmapPriv *_bitmapPriv
__attribute__ ((deprecated("Not supported in FxPlug 4")));
}

/*!
    @method		initWithInfo:andRowBytes:andData:
    @abstract	Initalizes with the given FxImageInfo and pixel buffer.
    @param		imageInfo	The FxImageInfo that defines the image.
    @param		rowBytes	bytes per row, including any padding
    @param		data		A pointer to the pixel buffer.
    @result		The initialized FxBitmap.
    @discussion	The sender owns the pixel buffer and is responsible for deallocating it. Introduced
                in FxImage version 0.
*/
- (id)initWithInfo:(FxImageInfo)imageInfo
          rowBytes:(NSUInteger)rowBytes
           andData:(void *)data
__attribute__ ((deprecated("Not supported in FxPlug 4")));

/*!
	@method		dataPtr
	@abstract	Returns a pointer to the pixel buffer for FxBitmap. Introduced in FxImage version 0.
	@result		The data pointer.
*/
- (void *)dataPtr
__attribute__ ((deprecated("Not supported in FxPlug 4")));

/*!
	@method		rowBytes
	@abstract	Returns the offset in bytes between the start of two rows. Introduced in FxImage
                version 0.
	@result		The offset in bytes between pixel[x,y] and pixel[x,y+1].
	@discussion	Effects should avoid overwriting padded scanlines created by Final Cut.
*/
- (NSUInteger)rowBytes
__attribute__ ((deprecated("Not supported in FxPlug 4")));

@end

#endif
