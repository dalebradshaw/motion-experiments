/*!
	@header		FxGenerator.h
	@abstract	Defines the FxGenerator protocol.
	@discussion	This header file is the starting point for developing a generator plug-in.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */

#ifndef __FX_GENERATOR_H__
#define __FX_GENERATOR_H__

#import <FxPlug/FxBaseEffect.h>
#import <FxPlug/FxTypes.h>
#import <FxPlug/FxImage.h>

/*!
	@protocol	FxGenerator
	@abstract   Specifies the methods a generator plug-in needs to implement.
	@discussion	This protocol inherits from the parent protocol FxBaseEffect, whose methods must be
				implemented by any type of plug-in.
*/

__attribute__ ((deprecated("Use FxTileableEffect instead.")))
@protocol FxGenerator <FxBaseEffect>


/*!
	@method		frameSetup:hardware:software:
	@abstract   Determines the type of output image the plug-in requires. Called before
				renderOutput:.
	@param		renderInfo			FxRenderInfo structure that defines the render request.
	@param		canRenderHardware	Set to YES if the frame can be rendered in hardware.
	@param		canRenderSoftware	Set to YES if the frame can be rendered in software.
	@result		YES if frame setup is successful; NO otherwise. 
*/ 
- (BOOL)frameSetup:(FxRenderInfo)renderInfo
          hardware:(BOOL *)canRenderHardware
          software:(BOOL *)canRenderSoftware
__attribute__ ((deprecated("Not supported in FxPlug 4")));

/*!
	@method		frameCleanup
	@abstract   Asks the plug-in to clean up any memory allocated in frameSetup:. Called after
				renderOutput:.
	@result		YES if the cleanup is successful; NO otherwise.
*/
- (BOOL)frameCleanup
__attribute__ ((deprecated("Not supported in FxPlug 4")));

/*!
	@method		renderOutput:withInfo:
	@abstract	Renders output from a plug-in image.
	@param		output		Target image for final output.
	@param		renderInfo	Information about the render type the application is currently
							requesting.
	@result		YES if the ouput image is correctly populated and processing is successful; NO
				otherwise.
*/ 
- (BOOL)renderOutput:(FxImage *)output
            withInfo:(FxRenderInfo)renderInfo
__attribute__ ((deprecated("Use -renderDestinationImage:sourceImages:pluginState:atTime:error: from FxTileableEffect instead.")));

@end

#endif
