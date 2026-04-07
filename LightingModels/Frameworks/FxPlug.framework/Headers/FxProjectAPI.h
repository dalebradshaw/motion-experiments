/*!
 @header        FxProjectAPI.h
 @abstract      Defines the FxProjectAPI protocols to get information about the project in which
                your plug-in instance is running.
 */
/* Copyright © 2020-2021 Apple Inc. All rights reserved. */

#ifndef FxProjectAPI_h
#define FxProjectAPI_h

#import <Foundation/Foundation.h>

/*!
    @protocol   FxProjectAPI
    @abstract   Methods you use to get information about the project in which your plug-in instance
                is running.
 */

@protocol FxProjectAPI

/*!
    @method     -mediaFolderURL:error:
    @abstract   Provides the security-scoped URL for a plug-in data folder within a project’s media folder.
    @discussion Use this method to get the URL for a plug-in-specific directory within the media
                folder of a Motion project. The mediaURL will be nil if the user has not saved the
                project or the user did not select the “Collect Media” feature when saving.
                A sandboxed plug-in needs to add the appropriate entitlements to use security-scoped
                bookmarks to use this URL.
    @result     Returns YES if the mediaURL exists and your plug-in can write to it. Returns NO if
                the host can't retrieve the mediaURL or some other error occurred while retrieving it.
*/
- (BOOL)mediaFolderURL:(NSURL**)mediaURL
                 error:(NSError**)error;

/*!
    @method     -documentID:error:
    @abstract   Provides the document ID number of the host’s project.
    @discussion Use this method to get the document ID number of the host application's project.
    @result     Returns YES if the documentID exists. Returns NO if the host can’t retrieve the
                documentID or some other error occurred while retrieving it.
*/
- (BOOL)documentID:(NSUInteger*)documentID
             error:(NSError**)error;

@end


#endif /* FxProjectAPI_h */
