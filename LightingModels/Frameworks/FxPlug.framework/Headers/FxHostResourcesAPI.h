/*!
    @header     FxHostResourcesAPI.h

    @abstract   Defines the FxHostResources API for obtaining tracked resources from the host.

*/

/* Copyright © 2010-2021 Apple Inc. All rights reserved. */

#ifndef __FX_HOST_RESOURCES_API_H__
#define __FX_HOST_RESOURCES_API_H__

/*!
    @protocol   FxHostResourcesAPI
    @abstract   Methods that allow the host to allocate and track resources
    @discussion These methods allow the host to allocate resources such as memory, OpenGL
                textures and PBuffers, and allows the host to spawn threads to do work
                for a plugin.
*/
__attribute__ ((deprecated("Not supported in FxPlug 4.")))
@protocol FxHostResourcesAPI

/* RAM Allocation */

/*!
    @method         allocateMemory:clear:clearWith:error:
    @abstract       Allocates a block of RAM, possibly filling it with a particular value
    @param          numBytes        The number of bytes to allocate
    @param          clear           Whether to clear the allocated bytes
    @param          fillByte        The byte with which to clear the newly allocated memory
    @param          outError        An error describing what went wrong if anything.
    @discussion     Returns a pointer to the newly allocated (and possibly filled) memory
                    if it was able to successfully allocate it. If not, it returns NULL and
                    sets outError to an NSError describing what went wrong.
    
*/
- (void*)allocateMemory:(size_t)numBytes
                  clear:(BOOL)clear
              clearWith:(UInt8)fillByte
                  error:(NSError**)outError
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
    @method         freeMemory:error:
    @abstract       Frees a block of memory allocated with -allocateMemory:clear:clearWith:error:
    @param          ptr         A pointer to the memory to be freed
    @param          outError    A pointer to an NSError to be filled out if an error occurs
    @discussion     Returns void, but will set outError to something meaningful if there were
                    any errors freeing the block of memory.
*/
- (void)freeMemory:(void*)ptr
             error:(NSError**)outError
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
    @method         trackExternalAllocation:
    @abstract       Lets the host keep track of memory it did not allocate
    @param          numBytes        The number of bytes allocated externally
    @discussion     If you have allocated memory without using the FxHostResourcesAPI, let
                    the host app know. This is useful if you are integrating a library which
                    can't easily be ported to use the FxHostResourcesAPI for memory allocation.
                    Likewise, when you free memory, call this method with a negative value to
                    let the host app know you've freed it.
*/
- (void)trackExternalAllocation:(size_t)numBytes
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/* VRAM Allocation */

/*!
    @method     createTexture:withDOD:GLTarget:level:internalFormat:width:height:border:format:type:pixels:andError:
    @abstract   Allocates an OpenGL texture with the desired characteristics
    @discussion If successful, texture points to an FxTexture with the desired characteristics.
                If it fails, outError will contain information about what went wrong.
*/
- (void)createTexture:(FxTexture**)texture
              withDOD:(FxRect)dod
             GLTarget:(GLenum)target
                level:(GLint)level
       internalFormat:(GLenum)internalFormat
                width:(GLsizei)width
               height:(GLsizei)height
               border:(GLint)border
               format:(GLenum)format
                 type:(GLenum)type
               pixels:(const GLvoid*)pixels
               origin:(FxImageOrigin)origin
     pixelAspectRatio:(double)pixelAspectRatio
             andError:(NSError**)outError
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
    @method     deleteTexture:error:
    @abstract   Deletes a texture that the host allocated for you
    @param      texture     The texture you want to delete
    @param      outError    Any errors which occurred during deletion of the texture
    @discussion If successful, *outError will be NULL, otherwise it will point to an error
                describing what went wrong.
*/
- (void)deleteTexture:(FxTexture*)texture
                error:(NSError**)outError
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
    @method     createPBuffer:error:
    @abstract   Creates a host-tracked pBuffer for your plugin to use
    @param      pBufferID       Receives the ID of the newly allocated pBuffer
    @param      outError        If allocation fails, contains a description of what went wrong
    @discussion If allocation is successful, pBufferID will contain the ID of the pBuffer the
                host application created. Otherwise, outError will describe what went wrong.
*/
- (void)createPBuffer:(GLuint*)pBufferID
           withTarget:(GLenum)target
                error:(NSError**)outError
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
    @method     deletePBuffer:error:
    @abstract   Destroys a host-tracked pBuffer
    @param      pBufferID       The ID of the buffer to delete
    @param      outError        If deletion fails, describes what went wrong
    @discussion If successful, *outError will be NULL, otherwise it will contain a description
                of what went wrong during deletion.
*/
- (void)deletePBuffer:(GLuint)pBufferID
                error:(NSError**)outError
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/* Threading */

/*!
    @method     numberOfCores
    @abstract   The number of active cores
    @result     Returns the number of cores the machine can use to process on
*/
- (NSUInteger)numberOfCores
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
    @method     performSelector:withObject:onThreads:waitUntilDone:error:
    @abstract   Performs a method on multiple threads, possibly waiting until it completes
    @param      selector        The selector of the method you want performed on multiple threads
                object          The object you want to perform the selector on
                onThreads       The number of threads you want to perform the selector on
                wait            Whether you want to wait until the selector has been performed on 
                                all threads before continuing
    @param      outError        Any errors which occurred while attempting to execute the selector
    @discussion If successful, *outError will be NULL, otherwise it will point to an error
                describing what went wrong.
*/
- (void)performSelector:(SEL)selector
               onTarget:(id)target
             withObject:(id)object
              onThreads:(NSInteger)numThreads
          waitUntilDone:(BOOL)wait
                  error:(NSError**)outError
__attribute__ ((deprecated("Not supported in FxPlug 4.")));
@end


/*!
    @protocol   FxHostResourcesClient
    @abstract   Plugins should implement this if they want the host to request that they free
                memory in low-memory situations.
*/
__attribute__ ((deprecated("Not supported in FxPlug 4.")))
@protocol FxHostResourcesClient

/*!
    @method         freeMemory:
    @param          requestedBytes      The number of bytes the host app wants your plugin to free
    @discussion     Your plugin should implement this method. The host will call it if memory gets
                    tight and we need to free up some temp/cache memory. When called, the host
                    would like you to free up at least requestedBytes, if possible. Return the 
                    number of bytes actually freed.
*/
- (size_t)freeMemory:(size_t)requestedBytes
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

@end



#endif // __FX_HOST_RESOURCES_API_H__
