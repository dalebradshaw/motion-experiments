/*!
	@header		Fx3DAPI.h
	@abstract	Defines the Fx3DAPI host API protocol.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */

#import <FxPlug/FxTypes.h>
#import <FxPlug/FxTexture.h>
#import <FxPlug/FxParameterAPI.h>

/*!
	@protocol   Fx3DAPI
	@abstract   Defines the methods the host application provides to get information about the
				3D environment, including camera and object transforms.
*/
__attribute__ ((deprecated("Use Fx3DAPI_v5 instead.")))
@protocol Fx3DAPI

/*!
	@method		cameraMatrixAtTime:
	@abstract   Gets the 4x4 camera transform matrix.
	@param		time	Specified time, expressed in canonical frames, to retrieve the
						matrix value.
	@result		An NSData object that wraps 16 double floating-point values. Those values
				can be retrieved with a call to [theData getBytes:&anArrayOf16Doubles];
*/
- (NSData*)cameraMatrixAtTime:(double)time
__attribute__ ((deprecated("Use matrix methods from Fx3DAPI_v5 instead.")));

/*!
	@method		layerMatrixAtTime:
	@abstract   Gets the 4x4 layer transform matrix.
	@param		time	Specified time, expressed in canonical frames, to retrieve the
						matrix value.
	@result		An NSData object that wraps 16 double floating-point values. Those values
				can be retrieved with a call to [theData getBytes:&anArrayOf16Doubles];
*/
- (NSData*)layerMatrixAtTime:(double)time
__attribute__ ((deprecated("Use matrix methods from Fx3DAPI_v5 instead.")));

/*!
	@method		focalLengthAtTime:
	@abstract   Gets the focal length.
	@param		time	Specified time, expressed in canonical frames, to retrieve the
						matrix value.
	@result		The value of the focal length.
*/
- (double)focalLengthAtTime:(double)time
__attribute__ ((deprecated("Use -focalLengthAtTime:error from Fx3DAPI_v5 instead.")));

/*!
	@method		is3D
	@abstract   Indicates whether or not the effect's layer is in 3D.
	@result		YES if the layer is 3D, NO otherwise.
*/
- (BOOL)is3D
__attribute__ ((deprecated("Use methods in Fx3DAPI_v5 instead.")));

@end


/*!
    @constant   kFxPropertyKey_DrawsInScreenSpace   Tells the host application that your plug-in
                                                    draws in screen space - it is always directly
                                                    in front of the camera and facing the camera
*/
#define kFxPropertyKey_DrawsInScreenSpace   @"TransformsFromLocalToScreenSpace"



/*!
  @protocol   Fx3DAPI_v2
  @abstract   Defines the methods the host application provides to get information about the
              3D environment, including camera and object transforms.
*/
__attribute__ ((deprecated("Use Fx3DAPI_v5 instead.")))
@protocol Fx3DAPI_v2 <Fx3DAPI>

/*!
    @method		worldToFilmMatrix:
    @abstract   Gets the 4x4 world to film matrix.
    @result		An NSData object that wraps 16 double floating-point values. Those values
                can be retrieved with a call to [theData getBytes:&anArrayOf16Doubles];
 */
- (NSData*)worldToFilmMatrix
__attribute__ ((deprecated("Use matrix methods from Fx3DAPI_v5 instead.")));

/*!
    @method		worldToObjectMatrix:
    @abstract   Gets the 4x4 world to object matrix.
    @result		An NSData object that wraps 16 double floating-point values. Those values
                can be retrieved with a call to [theData getBytes:&anArrayOf16Doubles];
 */
- (NSData*)worldToObjectMatrix
__attribute__ ((deprecated("Use matrix methods from Fx3DAPI_v5 instead.")));

/*!
    @method		worldToEyeMatrix:
    @abstract   Gets the 4x4 world to eye matrix.
    @result		An NSData object that wraps 16 double floating-point values. Those values
                can be retrieved with a call to [theData getBytes:&anArrayOf16Doubles];
 */
- (NSData*)worldToEyeMatrix
__attribute__ ((deprecated("Use matrix methods from Fx3DAPI_v5 instead.")));

/*!
    @method		focalLengthAtTime:
    @abstract   Gets the focal length.
    @param		time	Specified time, expressed in canonical frames, to retrieve the
                        matrix value.
    @result		The value of the focal length.
 */
- (double)focalLengthAtTime:(double)time
__attribute__ ((deprecated("Use -focalLengthAtTime:error from Fx3DAPI_v5 instead.")));

/*!
    @method		isUsingCamera
    @abstract   Indicates whether or not the object or group is using a camera ( 2d ) 
    @result		YES if the object or group is, NO otherwise.
 */
- (BOOL)isUsingCamera
__attribute__ ((deprecated("Use methods from Fx3DAPI_v5 instead.")));

@end


/*!
  @protocol   Fx3DAPI_v3
  @abstract   Defines the methods the host application provides to get information about the
              3D environment, including camera and object transforms.

    NOTE: This API is only available to plug-ins built in the FxPlug 3 style and later.

*/
__attribute__ ((deprecated("Use Fx3DAPI_v5 instead.")))
@protocol Fx3DAPI_v3 <Fx3DAPI_v2>

/*!
    @method		focalLengthAtTime:
    @abstract   Gets the focal length.
    @param		time	Specified time, expressed as an FxTime, to retrieve the
                        matrix value.
    @result		The value of the focal length.
 */
- (double)focalLengthAtFxTime:(FxTime)time
__attribute__ ((deprecated("Use -focalLengthAtTime:error from Fx3DAPI_v5 instead.")));

@end

/*!
 @protocol   Fx3DAPI_v4
 @abstract   Defines the methods the host application provides to get information about the
 3D environment, including camera and object transforms.
 
 NOTE: This API is only available to plug-ins built in the FxPlug 4 style and later.
        It intentionally does not inherit from earlier versions and is a completely new API.
 
 */
__attribute__ ((deprecated("Use Fx3DAPI_v5 instead.")))
@protocol Fx3DAPI_v4

/*!
    @method		worldToFilmMatrix:
    @abstract   Gets the 4x4 world to film matrix.
    @result		An NSData object that wraps 16 double floating-point values. Those values
                can be retrieved with a call to [theData getBytes:&anArrayOf16Doubles];
 */
- (NSData*)worldToFilmMatrix
__attribute__ ((deprecated("Use matrix methods from Fx3DAPI_v5 instead.")));

/*!
    @method		worldToObjectMatrix:
    @abstract   Gets the 4x4 world to object matrix.
    @result		An NSData object that wraps 16 double floating-point values. Those values
                can be retrieved with a call to [theData getBytes:&anArrayOf16Doubles];
 */
- (NSData*)worldToObjectMatrix
__attribute__ ((deprecated("Use matrix methods from Fx3DAPI_v5 instead.")));

/*!
    @method		worldToEyeMatrix:
    @abstract   Gets the 4x4 world to eye matrix.
    @result		An NSData object that wraps 16 double floating-point values. Those values
                can be retrieved with a call to [theData getBytes:&anArrayOf16Doubles];
 */
- (NSData*)worldToEyeMatrix
__attribute__ ((deprecated("Use matrix methods from Fx3DAPI_v5 instead.")));


/*!
    @method		isUsingCamera
    @abstract   Indicates whether the object or group is using a 3D camera
    @result		YES if the object or group is, NO otherwise.
 */
- (BOOL)isUsingCamera
__attribute__ ((deprecated("Use matrix methods from Fx3DAPI_v5 instead.")));

/*!
     @method        focalLengthAtTime:
     @abstract      Gets the focal length.
     @param         time    Specified time, expressed as a CMTime, to retrieve the
                            matrix value.
     @result        The value of the focal length.
 */
- (double)focalLengthAtTime:(CMTime)time
__attribute__ ((deprecated("Use -focalLengthAtTime:error from Fx3DAPI_v5 instead.")));


@end

/*!
     @protocol   Fx3DAPI_v5
     @abstract   Defines the methods the host application provides to get information about the
     3D environment, including camera and object transforms.
     
     NOTE: This API is only available to plug-ins built in the FxPlug 4.1 style and later.
     It intentionally does not inherit from earlier versions and is a completely new API.
 */
@protocol Fx3DAPI_v5

/*!
     @method        focalLengthAtTime:error:
     @abstract      Gets the focal length.
     @param         time    Specified time, expressed as a CMTime, to retrieve the focal length.
     @param         error   Description of the problem if you are unable to retrieve the value.
     @result        The value of the focal length.
     @description   The reported focal length is in millimeters and has an equivalent vertical field
                    of view of a lens of that focal length on a 35mm camera.
 */
- (double)focalLengthAtTime:(CMTime)time
                      error:(NSError**)error;

/*!
    @method		layerMatrixAtTime:error
    @abstract   Gets the 4x4 layer matrix, which is equivalent to the model matrix for the object
                that the effect is applied to.
    @param      time    Specified time, expressed as a CMTime, to retrieve the matrix.
    @param      error   Description of the problem if you are unable to retrieve the matrix.
    @result		An FxMatrix44 containing the matrix.
 */
- (FxMatrix44*)layerMatrixAtTime:(CMTime)time
                           error:(NSError**)error;

/*!
    @method     viewMatrixAtTime:error
    @abstract   Gets the 4x4 view matrix.
    @param      time    Specified time, expressed as a CMTime, to retrieve the matrix.
    @param      error   Description of the problem if you are unable to retrieve the matrix.
    @result		An FxMatrix44 containing the matrix.
 */
- (FxMatrix44*)viewMatrixAtTime:(CMTime)time
                          error:(NSError**)error;

/*!
    @method     metalProjectionMatrixAtTime:error
    @abstract   Gets the 4x4 Metal projection matrix.
    @param      time    Specified time, expressed as a CMTime, to retrieve the matrix.
    @param      error   Description of the problem if you are unable to retrieve the matrix.
    @result		An FxMatrix44 containing the matrix.
 */
- (FxMatrix44*)metalProjectionMatrixAtTime:(CMTime)time
                                     error:(NSError**)error;

/*!
    @method     frustumLeft:right:bottom:top:near:far:atTime:error
    @abstract   Describes the bounds of the viewing solid for generating a projection matrix.
    @param      left    The x coordinate for the left vertical clipping plane.
    @param      right   The x coordinate for the right vertical clipping plane.
    @param      bottom  The y coordinate for the bottom horizontal clipping plane.
    @param      top     The y coordinate for the top horizontal clipping plane.
    @param      near    The z distance to the near depth clipping plane. Value must be positive.
    @param      far     The z distance to the far depth clipping plane. Value must be positive.
    @param      time    Specified time, expressed as a CMTime, to retrieve the matrix.
    @param      error   Description of the problem if you are unable to retrieve the matrix.
    @result		YES if the the frustum was retrieved, NO otherwise.
 */
- (BOOL)frustumLeft:(double*)left
              right:(double*)right
             bottom:(double*)bottom
                top:(double*)top
               near:(double*)near
                far:(double*)far
             atTime:(CMTime)time
              error:(NSError**)error;

@end
