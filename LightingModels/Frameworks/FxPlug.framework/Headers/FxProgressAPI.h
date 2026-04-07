/*!
	@header		FxProgressAPI.h
	@abstract	Defines the host-API protocol for handling progress updates and user
				cancellation.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */

#import <Foundation/Foundation.h>
#import <FxPlug/FxTypes.h>


/*!
	@protocol   FxProgressAPI
	@abstract   Defines the methods provided by the host application to let a plug-in
				report progress and to support user cancellation.
	@discussion	NOTE: Some host applications may not implement this protocol.
*/
__attribute__ ((deprecated("Not supported in FxPlug 4.")))
@protocol FxProgressAPI

/*!
	@method		userHasCancelled
	@abstract	Indicates whether or not the user has cancelled.
	@result		YES if the user has cancelled. NO otherwise.
	@discussion	A plug-in should call this method (or the -updateProgress method)
				periodically (say, once every tenth of a second) during a slow
				render. If the user cancels, the method returns YES, and the
				plug-in should then abort the rest of the render and return NO
				from its render method.
*/
- (BOOL)userHasCancelled
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		updateProgress:
	@abstract	Indicates whether or not the user has cancelled.
	@param		percentDone		A floating-point number between 0.0 and 100.0,
								indicating the progress of the render operation.
	@result		YES if the user has cancelled. NO otherwise.
	@discussion	A plug-in should call this method (or the -userHasCancelled method)
				periodically (say, once every tenth of a second) during a slow
				render. If the user cancels, the method returns YES, and the
				plug-in should then abort the rest of the render, and return NO
				from its render method.
*/
- (BOOL)updateProgress:(float)percentDone
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

@end
