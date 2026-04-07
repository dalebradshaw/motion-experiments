/*!
	@header		FxTexture.h

	@abstract	Defines the FxTexture class.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */

#ifndef __FX_TEXTURE_H__
#define __FX_TEXTURE_H__

#import <FxPlug/FxImage.h>
#if TARGET_OS_IPHONE
#import <OpenGLES/ES2/gl.h>
#else
#import <OpenGL/gl.h>
#import <OpenGL/glext.h>
#import <OpenGL/CGLCurrent.h>
#endif

/*!
	@class FxTexture
	@abstract VRAM-based image used for hardware-accelerated rendering.
	@discussion	This subclass of FxImage is defined by an FxImageInfo structure.
	
				NOTE: The designated initializers of the FxTexture class is 
                -initWithInfo:textureId:andTarget:. Sending -init to an
				FxTexture raises an exception.
*/
@interface FxTexture : FxImage <NSCopying>
{
@private
	struct FxTexturePriv *_texturePriv
__attribute__ ((deprecated("Not supported in FxPlug 4")));
}

/*!
	@method		initWithInfo:andTextureId:
	@abstract	Initializes using the given FxImageInfo structure and texture ID. Introduced in
                FxImage version 1.
	@param		imageInfo	The FxImageInfo that defines the image.
    @param      textureId   The OpenGL texture ID for the texture you're wrapping in an FxTexture
    @param      target      The OpenGL texture target (for example, GL_TEXTURE_RECTANGLE_ARB)
                            that was used in creating the texture you're wrapping in an FxTexture
	@result		The initialized FxTexture.
	@discussion	The sender owns the GLtexture passed to this method and is responsible for
				deallocating it.
*/
- (id)initWithInfo:(FxImageInfo)imageInfo
         textureId:(GLuint)textureId
         andTarget:(GLuint)target
__attribute__ ((deprecated("Not supported in FxPlug 4")));

/*!
	@method		textureId
	@abstract	The ID of the GLtexture wrapped by the FxTexture. Introduced in FxImage version 0.
	@result		The GLtexture ID.
*/
- (GLuint)textureId
__attribute__ ((deprecated("Not supported in FxPlug 4")));

/*!
	@method		target
	@abstract	Returns the target of the FxTexture. Introduced in FxImage version 0.
	@result		GL texture target ID.
*/
- (GLenum)target
__attribute__ ((deprecated("Not supported in FxPlug 4")));

/*!
	@method		bind
	@abstract	Binds the texture object. Introduced in FxImage version 0.
*/
- (void)bind
__attribute__ ((deprecated("Not supported in FxPlug 4")));

/*!
	@method		enable
	@abstract	Enables the texture for rendering. Introduced in FxImage version 0.
*/
- (void)enable
__attribute__ ((deprecated("Not supported in FxPlug 4")));

/*!
	@method		disable
	@abstract	Disables the texture for rendering. Introduced in FxImage version 0.
*/
- (void)disable
__attribute__ ((deprecated("Not supported in FxPlug 4")));

/*!
	@method		getTextureCoords:right:bottom:top:
	@abstract	Gets the texture bounds.
	@param		left	Pointer to the left value.
	@param		right	Pointer to the right value.
	@param		bottom	Pointer to the bottom value.
	@param		top		Pointer to the top value.
	@discussion	The sender can set any of the pointers to NULL if the value of a particular
				coordinate is not of interest. Introduced in FxImage version 0.
*/
- (void)getTextureCoords:(double *)left
                   right:(double *)right
                  bottom:(double *)bottom
                     top:(double *)top
__attribute__ ((deprecated("Not supported in FxPlug 4")));

/*!
	@method		draw
	@abstract	Draws the texture to the GL Context. Introduced in FxImage version 0.
*/
- (void)draw
__attribute__ ((deprecated("Not supported in FxPlug 4")));

@end

#endif
