/*!
	@header		FxTimingAPI.h
	@abstract	Defines the FxTimingAPI protocol.
	@discussion	Defines the FxTimingAPI host-API protocol.
*/

/* Copyright © 2005-2021 Apple Inc. All rights reserved. */



/*!
	@protocol   FxTimingAPI
	@abstract   Defines the methods provided by the host to allow a plug-in to query the
				timing properties of its input image(s), image parameters, effect, timeline,
				and in/out points.
	@discussion	This protocol was added in FxPlug framework version 1.2.
*/
__attribute__ ((deprecated("Use FxTimingAPI_v4 instead.")))
@protocol FxTimingAPI


/*!
    @const      kFxDuration_Undefined
	@abstract	A special duration value that indicates an undefined duration.
	@discussion	This value is returned by the method -durationTime:ofImageParameter:
				if the given image parameter has not yet been assigned a value.
*/
#define kFxDuration_Undefined			-1.0


/************************************************/
#pragma mark Clip Start Times
/************************************************/

/*!
	@method		startTimeOfInputToFilter:
	@abstract   Returns the start time of the given filter's image input clip.
	@param		filter			The plug-in object.
	@result		The clip's start time, expressed in timeline frames.
*/
- (double)startTimeOfInputToFilter:(id<FxFilter>)filter
__attribute__ ((deprecated("Use -startTimeOfInputToFilter: from FxTimingAPI_v4 instead.")));

/*!
	@method		startTimeOfInputAToTransition:
	@abstract   Returns the start time of the given transition's image input A clip.
	@param		transition		The plug-in object.
	@result		The clip's start time, expressed in timeline frames.
*/
- (double)startTimeOfInputAToTransition:(id<FxTransition>)transition
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		startTimeOfInputBToTransition:
	@abstract   Returns the start time of the given transition's image input B clip.
	@param		transition		The plug-in object.
	@result		The clip's start time, expressed in timeline frames.
*/
- (double)startTimeOfInputBToTransition:(id<FxTransition>)transition
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		startTimeOfImageParm:forEffect:
	@abstract   Returns the start time of the clip assigned to the given image parameter
				for the given effect.
	@param		parmId			The ID of the image parameter.
	@param		effect			The plug-in object.
	@result		The clip's start time, expressed in timeline frames.
	@discussion	This method is only meaningful if the image parameter has been
				assigned a value. To determine whether or not it has, you should first call
				-durationOfImageParm:forEffect:. If the return value is
				kFxDuration_Undefined, then the image parameter has not yet been connected.
*/
- (double)startTimeOfImageParm:(UInt32)parmId
					 forEffect:(id<FxBaseEffect>)effect
__attribute__ ((deprecated("Use -startTime:ofImageParameter: from FxTimingAPI_v4 instead.")));


/************************************************/
#pragma mark Clip Durations
/************************************************/

/*!
	@method		durationOfInputToFilter:
	@abstract   Returns the duration of the given filter's image input clip.
	@param		filter			The plug-in object.
	@result		The clip's duration, expressed in timeline frames.
*/
- (double)durationOfInputToFilter:(id<FxFilter>)filter
__attribute__ ((deprecated("Use -durationTimeOfInputToFilter: from FxTimingAPI_v4 instead.")));

/*!
	@method		durationOfInputAToTransition:
	@abstract   Returns the duration of the given transition's image input A clip.
	@param		transition		The plug-in object.
	@result		The clip's duration, expressed in timeline frames.
*/
- (double)durationOfInputAToTransition:(id<FxTransition>)transition
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		durationOfInputBToTransition:
	@abstract   Returns the duration of the given transition's image input B clip.
	@param		transition		The plug-in object.
	@result		The clip's duration, expressed in timeline frames.
*/
- (double)durationOfInputBToTransition:(id<FxTransition>)transition
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		durationOfImageParm:forEffect:
	@abstract   Returns the duration of the clip assigned to the given image parameter
				for the given effect.
	@param		parmId			The ID of the image parameter.
	@param		effect			The plug-in object.
	@result		The clip's duration, expressed in timeline frames, or the special value
				kFxDuration_Undefined if the image is empty.
*/
- (double)durationOfImageParm:(UInt32)parmId
					forEffect:(id<FxBaseEffect>)effect
__attribute__ ((deprecated("Use -durationTime:ofImageParameter: from FxTimingAPI_v4 instead.")));


/************************************************/
#pragma mark Input Field Order
/************************************************/

/*!
	@method		fieldOrderForInputToFilter:
	@abstract   Return the field order of the filter input.
	@param		filter			The plug-in object.
	@result		An FxFieldOrder value (kFxFieldOrder_PROGRESSIVE, kFxFieldOrder_TOP_FIRST,
				or kFxFieldOrder_LOWER_FIRST).
*/
-(FxFieldOrder)fieldOrderForInputToFilter:(id<FxFilter>)filter
__attribute__ ((deprecated("Use -fieldOrderForInputToFilter: from FxTimingAPI_v4 instead.")));

/*!
	@method		fieldOrderForInputAToTransition
	@abstract   Return the field order of the transition's first input.
	@param		transition			The plug-in object.
	@result		An FxFieldOrder value (kFxFieldOrder_PROGRESSIVE, kFxFieldOrder_TOP_FIRST,
				or kFxFieldOrder_LOWER_FIRST).
*/
-(FxFieldOrder)fieldOrderForInputAToTransition:(id<FxTransition>)transition
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		fieldOrderForInputBToTransition
	@abstract   Return the field order of the transition's second input.
	@param		transition			The plug-in object.
	@result		An FxFieldOrder value (kFxFieldOrder_PROGRESSIVE, kFxFieldOrder_TOP_FIRST,
				or kFxFieldOrder_LOWER_FIRST).
*/
-(FxFieldOrder)fieldOrderForInputBToTransition:(id<FxTransition>)transition
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		fieldOrderForImageParm:forEffect:
	@abstract   Return the field order of the image parameter.
	@param		effect			The plug-in object.
	@result		An FxFieldOrder value (kFxFieldOrder_PROGRESSIVE, kFxFieldOrder_TOP_FIRST,
				or kFxFieldOrder_LOWER_FIRST).
	@discussion	This method is only meaningful if the image parameter has been
				assigned a value. To determine whether or not it has, you should first call
				-durationOfImageParm:forEffect:. If the return value is
				kFxDuration_Undefined, then the image parameter has not yet been connected.
*/
-(FxFieldOrder)fieldOrderForImageParm:(UInt32)parmId
							forEffect:(id<FxBaseEffect>)effect
__attribute__ ((deprecated("Not supported in FxPlug 4.")));


/************************************************/
#pragma mark Frame Rate
/************************************************/

/*!
	@method		timelineFpsNumeratorForEffect:
	@abstract   Return the numerator of frame rate of the timeline on which the given effect
				has been applied.
	@param		effect			The plug-in object.
	@result		The numerator of the frame rate.
	@discussion	For example, for 29.97-fps video, you might see 1001 for the numerator, and
				30000 for the denominator.
*/
- (NSUInteger)timelineFpsNumeratorForEffect:(id<FxBaseEffect>)effect
__attribute__ ((deprecated("Use -timelineFpsNumeratorForEffect: from FxTimingAPI_v4 instead.")));

/*!
	@method		timelineFpsDenominatorForEffect:
	@abstract   Return the denominator of frame rate of the timeline on which the given effect
				has been applied.
	@param		effect			The plug-in object.
	@result		The denominator of the frame rate.
	@discussion	For example, for 29.97-fps video, you might see 1001 for the numerator, and
				30000 for the denominator.
*/
- (NSUInteger)timelineFpsDenominatorForEffect:(id<FxBaseEffect>)effect
__attribute__ ((deprecated("Use -timelineFpsDenominatorForEffect: from FxTimingAPI_v4 instead.")));


/************************************************/
#pragma mark Timeline In and Out Points
/************************************************/
/*!
	@method		inPointOfTimelineForEffect:
	@abstract   Returns the In Point of the timeline on which the given effect has been
				applied.
	@param		effect			The plug-in object.
	@result		The In time, expressed in timeline frames.
*/
- (double)inPointOfTimelineForEffect:(id<FxBaseEffect>)effect
__attribute__ ((deprecated("Use -inPointTimeOfTimelineForEffect: from FxTimingAPI_v4 instead.")));

/*!
	@method		outPointOfTimelineForEffect:
	@abstract   Returns the Out Point of the timeline on which the given effect has been
				applied.
	@param		effect			The plug-in object.
	@result		The Out time, expressed in timeline frames.
*/
- (double)outPointOfTimelineForEffect:(id<FxBaseEffect>)effect
__attribute__ ((deprecated("Use -outPointTimeOfTimelineForEffect: from FxTimingAPI_v4 instead.")));


/************************************************/
#pragma mark Effect Start and Duration
/************************************************/

/*!
	@method		startTimeForEffect:
	@abstract   Returns the start time of the given effect.
	@param		effect			The plug-in object.
	@result		The effect's start time, expressed in timeline frames.
*/
- (double)startTimeForEffect:(id<FxBaseEffect>)effect
__attribute__ ((deprecated("Use -startTimeForEffect: from FxTimingAPI_v4 instead.")));

/*!
	@method		durationForEffect:
	@abstract   Returns the duration of the given effect.
	@param		effect			The plug-in object.
	@result		The effect's duration, expressed in timeline frames.
*/
- (double)durationForEffect:(id<FxBaseEffect>)effect
__attribute__ ((deprecated("Use -durationTimeForEffect: from FxTimingAPI_v4 instead.")));


/************************************************/
#pragma mark Conversion TO Timeline Frames
/************************************************/

/*!
	@method		timelineTimeFromInputTime:forFilter:
	@abstract   Returns a number of timeline frames, converted from clip frames of the filter's
				image input.
	@param		time			A time, expressed in clip frames.
	@param		filter			The plug-in object.
	@result		The converted time, in timeline frames.
	@discussion	The time argument and return value are floating-point frame numbers. For example,
				the first frame or field of the clip would be expressed as 0.0. The second field
				of interlaced video would be expressed as 0.5.
*/
- (double)timelineTimeFromInputTime:(double)time
						  forFilter:(id<FxFilter>)filter
__attribute__ ((deprecated("Use -timelineTime:fromInputTime: from FxTimingAPI_v4 instead.")));

/*!
	@method		timelineTimeFromInputATime:forTransition:
	@abstract   Returns a number of timeline frames, converted from clip frames of the transition's
				image input A.
	@param		time			A time, expressed in clip frames.
	@param		transition		The plug-in object.
	@result		The converted time, in timeline frames.
	@discussion	The time argument and return value are floating-point frame numbers. For example,
				the first frame or field of the clip would be expressed as 0.0. The second field
				of interlaced video would be expressed as 0.5.
*/
- (double)timelineTimeFromInputATime:(double)time
					   forTransition:(id<FxTransition>)transition
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		timelineTimeFromInputBTime:forTransition:
	@abstract   Returns a number of timeline frames, converted from clip frames of the transition's
				image input B.
	@param		time			A time, expressed in clip frames.
	@param		transition		The plug-in object.
	@result		The converted time, in timeline frames.
	@discussion	The time argument and return value are floating-point frame numbers. For example,
				the first frame or field of the clip would be expressed as 0.0. The second field
				of interlaced video would be expressed as 0.5.
*/
- (double)timelineTimeFromInputBTime:(double)time
					   forTransition:(id<FxTransition>)transition
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		timelineTimeFromImageTime:forParmId:forEffect:
	@abstract   Returns a number of timeline frames, converted from clip frames of the given
				image parameter in the given effect.
	@param		time			A time, expressed in clip frames.
	@param		parmId			The parameter ID of the image parameter.
	@param		effect			The plug-in object.
	@result		The converted time, in timeline frames.
	@discussion	The time argument and return value are floating-point frame numbers. For example,
				the first frame or field of the clip would be expressed as 0.0. The second field
				of interlaced video would be expressed as 0.5.
*/
- (double)timelineTimeFromImageTime:(double)time
                          forParmId:(UInt32)parmId
                          forEffect:(id<FxBaseEffect>)effect
__attribute__ ((deprecated("Use -timelineTime:fromImageTime:forParameterID: from FxTimingAPI_v4 instead.")));


/************************************************/
#pragma mark Conversion FROM Timeline Frames
/************************************************/

/*!
	@method		inputTimeForFilter:fromTimelineTime:
	@abstract   Returns a time, expressed as a frame number in the time frame of the filter's
				image input, converted from timeline frames.
	@param		filter			The plug-in object.
	@param		time			A time, expressed in timeline frames.
	@result		The converted time, in clip frames.
	@discussion	The time argument and return value are floating-point frame numbers. For example,
				the first frame or field of the clip would be expressed as 0.0. The second field
				of interlaced video would be expressed as 0.5.
*/
- (double)inputTimeForFilter:(id<FxFilter>)filter
			fromTimelineTime:(double)time
__attribute__ ((deprecated("Use -inputTime:fromTimelineTime: from FxTimingAPI_v4 instead.")));

/*!
	@method		inputATimeForTransition:fromTimelineTime:
	@abstract   Returns a time, expressed as a frame number in the time frame of the transition's
				image input A, converted from timeline frames.
	@param		transition		The plug-in object.
	@param		time			A time, expressed in timeline frames.
	@result		The converted time, in clip frames.
	@discussion	The time argument and return value are floating-point frame numbers. For example,
				the first frame or field of the clip would be expressed as 0.0. The second field
				of interlaced video would be expressed as 0.5.
*/
- (double)inputATimeForTransition:(id<FxTransition>)transition
				 fromTimelineTime:(double)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		inputBTimeForTransition:fromTimelineTime:
	@abstract   Returns a time, expressed as a frame number in the time frame of the transition's
				image input B, converted from timeline frames.
	@param		transition		The plug-in object.
	@param		time			A time, expressed in timeline frames.
	@result		The converted time, in clip frames.
	@discussion	The time argument and return value are floating-point frame numbers. For example,
				the first frame or field of the clip would be expressed as 0.0. The second field
				of interlaced video would be expressed as 0.5.
*/
- (double)inputBTimeForTransition:(id<FxTransition>)transition
				 fromTimelineTime:(double)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

/*!
	@method		inputTimeForParmId:forEffect:fromTimelineTime:
	@abstract   Returns a time, expressed as a frame number in the time frame of the given image
				parameter, converted from timeline frames.
	@param		parmId			The parameter ID of the image parameter.
	@param		effect			The plug-in object.
	@param		time			A time, expressed in timeline frames.
	@result		The converted time, in clip frames.
	@discussion	The time argument and return value are floating-point frame numbers. For example,
				the first frame or field of the clip would be expressed as 0.0. The second field
				of interlaced video would be expressed as 0.5.
*/
- (double)imageTimeForParmId:(UInt32)parmId
				   forEffect:(id<FxBaseEffect>)effect
			fromTimelineTime:(double)time
__attribute__ ((deprecated("Use -imageTime:forParameterID:fromTimelineTime: from FxTimingAPI_v4 instead.")));


@end


/*!
    @protocol       FxTimingAPI_v2
    @abstract       Extends the FxTimingAPI with addition transition-related methods.
    @discussion     This API was added in FxPlug 2.0.
*/
__attribute__ ((deprecated("Use FxTimingAPI_v4 instead.")))
@protocol FxTimingAPI_v2 <FxTimingAPI>


/*!
 @method     transitionTimeFractionAtTime:
 @abstract   Returns the time fraction of the transition (i.e. percent done) for a given
             timeline time
 @param      time        The timeline time for which you wish to get the transition time fraction
 */
-(double) transitionTimeFractionAtTime:(double)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

@end


/*
    NOTE: This API is only available to plug-ins built in the FxPlug 3 style and later.
 */
__attribute__ ((deprecated("Use FxTimingAPI_v4 instead.")))
@protocol FxTimingAPI_v3 <FxTimingAPI_v2>

- (void)frameDuration:(FxTime*)duration
__attribute__ ((deprecated("Use -frameDuration: from FxTimingAPI_v4 instead.")));

- (void)sampleDuration:(FxTime*)duration
__attribute__ ((deprecated("Use -sampleDuration: from FxTimingAPI_v4 instead.")));

- (void)startFxTimeForEffect:(FxTime*)startTime
__attribute__ ((deprecated("Use -startTimeForEffect: from FxTimingAPI_v4 instead.")));

- (void)durationFxTimeForEffect:(FxTime*)duration
__attribute__ ((deprecated("Use -durationTimeForEffect: from FxTimingAPI_v4 instead.")));

- (void)startFxTimeOfInputAToTransition:(FxTime*)startTime
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

- (void)startFxTimeOfInputBToTransition:(FxTime*)startTime
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

- (void)durationFxTimeOfInputAToTransition:(FxTime*)duration
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

- (void)durationFxTimeOfInputBToTransition:(FxTime*)duration
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

- (void)startFxTimeOfInputToFilter:(FxTime*)startTime
__attribute__ ((deprecated("Use -startTimeOfInputToFilter: from FxTimingAPI_v4 instead.")));

- (void)durationFxTimeOfInputToFilter:(FxTime*)duration
__attribute__ ((deprecated("Use -durationTimeOfInputToFilter: from FxTimingAPI_v4 instead.")));

- (void)startFxTime:(FxTime*)startTime
       ofImageParam:(UInt32)parmId
__attribute__ ((deprecated("Use -startTime:ofImageParameter: from FxTimingAPI_v4 instead.")));

- (void)durationFxTime:(FxTime*)duration
           ofImageParm:(UInt32)parmId
__attribute__ ((deprecated("Use -durationTime:ofImageParameter: from FxTimingAPI_v4 instead.")));

- (void)inPointFxTimeOfTimelineForEffect:(FxTime*)inPoint
__attribute__ ((deprecated("Use -inPointTimeOfTimelineForEffect: from FxTimingAPI_v4 instead.")));

- (void)outPointFxTimeOfTimelineForEffect:(FxTime*)outPoint
__attribute__ ((deprecated("Use -outPointTimeOfTimelineForEffect: from FxTimingAPI_v4 instead.")));

- (void)timelineFxTime:(FxTime*)timelineTime
         fromInputTime:(FxTime)time
__attribute__ ((deprecated("Use -timelineTime:fromInputTime: from FxTimingAPI_v4 instead.")));

- (void)timelineFxTime:(FxTime*)timelineTime
        fromInputATime:(FxTime)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

- (void)timelineFxTime:(FxTime*)timelineTime
        fromInputBTime:(FxTime)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

- (void)timelineFxTime:(FxTime*)timelineTime
         fromImageTime:(FxTime)time
             forParmId:(UInt32)parmId
__attribute__ ((deprecated("Use -timelineTime:fromImageTime:forParameterID: from FxTimingAPI_v4 instead.")));

- (void)inputFxTime:(FxTime*)inputTime
   fromTimelineTime:(FxTime)time
   __attribute__ ((deprecated("Use -inputTime:fromTimelineTime: from FxTimingAPI_v4 instead.")));

- (void)inputAFxTime:(FxTime*)inputTime
    fromTimelineTime:(FxTime)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

- (void)inputBFxTime:(FxTime*)inputTime
    fromTimelineTime:(FxTime)time
__attribute__ ((deprecated("Not supported in FxPlug 4.")));

- (void)imageFxTime:(FxTime*)imageTime
          forParmId:(UInt32)parmId
   fromTimelineTime:(FxTime)time
__attribute__ ((deprecated("Use -imageTime:forParameterID:fromTimelineTime: from FxTimingAPI_v4 instead.")));

@end

/****************************************************/

/*
 NOTE: This API is only available to plug-ins built in the FxPlug 4 style and later.
 */
#if !STUDIO_LITE

/*!
	@protocol   FxTimingAPI_v4
	@abstract   A protocol that defines the methods provided by the host, so a plug-in can
                query the timing properties of its input.
	@discussion	Using the FxTimingAPI, your plug-in can query the timing properties of its input
                image or images, image parameters, effect, timeline, and in or out points.
                Note: This version of the API is only available to plug-ins built in the FxPlug 4
                style and later, and it intentionally doesn't inherit from previous versions.
*/
@protocol FxTimingAPI_v4

/*!
	@method		frameDuration:
	@abstract   Provides the native frame duration of the object to which the effect is applied.
	@param		duration       The frame duration time, expressed in CMTime.
    @discussion Motion provides the frame duration of the project. Final Cut Pro provides the frame
                duration of the clip to which the effect is applied, not the frame duration for the
                timeline. Note that the value that the host provides is unaffected by any retiming
                the host may do and is always the native frame duration (before retiming) of the
                clip to which the effect is applied. To determine the timeline’s frame duration,
                divide the value from @c -timelineFpsDenominatorForEffect: by
                @c -timelineFpsNumeratorForEffect:.
*/
- (void)frameDuration:(CMTime*)duration;

/*!
	@method		sampleDuration:
	@abstract   Provides the native sample duration of the object to which the effect is applied.
	@param		duration       The sample duration time, expressed in CMTime.
    @discussion Motion provides the sample duration of the project. Final Cut Pro provides the
                sample duration of the clip to which the effect is applied, not the sample duration
                for the timeline. Note that in Final Cut Pro, the sample duration is equal to the
                object’s native frame duration for progressive clips, but half of the frame duration
                for interlaced clips.
*/
- (void)sampleDuration:(CMTime*)duration;

/*!
	@method		startTimeForEffect:
	@abstract   Provides the start time for the effect.
	@param		startTime       The start time for the effect, expressed in CMTime.
    @discussion In Motion, this is the time the effect starts relative to timeline time, but in
                Final Cut Pro this is the time the effect starts relative to the input object’s
                native start time. For example, if an object’s head is trimmed by 2 seconds and the
                effect starts at the head of the template, then -startTimeForEffect: will return 2
                seconds. This value changes when the user retimes the clip in Final Cut Pro, so a
                200-percent increase in speed halves the start time to 1 second.
*/
- (void)startTimeForEffect:(CMTime*)startTime;

/*!
	@method		durationTimeForEffect:
	@abstract   Provides the duration time for the effect.
	@param		duration        The duration time for the effect, expressed in CMTime.
    @discussion In Motion, the value this method provides specifies the duration of the effect in
                the project. In Final Cut Pro, because the effects you use in a template don’t need
                to cover the whole effect source clip, this value represents the duration of the
                effect inside the template, not the duration of the template when the user applies
                it to a clip on the timeline. However, in most use-cases the effect duration is
                equal to the template duration.

*/
- (void)durationTimeForEffect:(CMTime*)duration;

/*!
	@method		startTimeOfInputToFilter:
	@abstract   Provides the start time of the filter's image input clip.
	@param		startTime		The start time of the clip, in CMTime.
    @discussion In Motion, this value represents the start time of the clip to which the user
                applies the effect, relative to the timeline time. This start time accounts for any
                trimming or retiming. It is the start time on the timeline of the first visible
                frame of the object.
                In Final Cut Pro, this value represents the start time of the object relative to its
                native start, after retiming or trimming. For example, if the user trimmed the
                clip’s head by 10 seconds, then the start time is 10 seconds. If the user then
                retimes the clip by 200-percent, the start time is 5 seconds.
*/
- (void)startTimeOfInputToFilter:(CMTime*)startTime;

/*!
	@method		durationTimeOfInputToFilter:
	@abstract   Provides the duration of the filter's image input clip.
	@param		duration		The duration of the clip, in CMTime.
    @discussion In Motion, the value represents the duration of the object to which the user applies
                the effect, after retiming and trimming. In other words, this value is the duration
                of the visible frames. In Final Cut Pro, the value represents the duration of the
                object to which the user applies the effect template, regardless of the length of
                the Effect Source inside the template.
*/
- (void)durationTimeOfInputToFilter:(CMTime*)duration;

/*!
	@method		startTime:ofImageParameter:
	@abstract   Provides the start time of the clip the user assigned to the given image parameter
				for the effect.
    @param      startTime           The start time of the clip, in CMTime.
	@param		parameterID			The ID of the image parameter.
    @discussion In Motion, startTime represents the native start time of the image well input,
                relative to timeline time.
*/
- (void)startTime:(CMTime*)startTime
 ofImageParameter:(UInt32)parameterID;

/*!
	@method		durationTime:ofImageParameter:
	@abstract   Provides the duration of the clip the user assigns to the given image parameter
				for the effect.
    @param      duration            The duration of the clip, in CMTime.
	@param		parameterID			The ID of the image parameter.
    @discussion In Motion, duration represents the duration of the the image well input after the
                user has trimmed or retimed it.
*/
- (void)durationTime:(CMTime*)duration
    ofImageParameter:(UInt32)parameterID;

/*!
	@method		inPointTimeOfTimelineForEffect:
	@abstract   Provides the in point of the timeline on which the user applies the effect.
	@param		inPoint			The in time, in CMTime.
*/
- (void)inPointTimeOfTimelineForEffect:(CMTime*)inPoint;

/*!
	@method		outPointTimeOfTimelineForEffect:
	@abstract   Provides the out point of the timeline on which the user applies the effect.
	@param		outPoint		The out time, in CMTime.
*/
- (void)outPointTimeOfTimelineForEffect:(CMTime*)outPoint;

/*!
	@method		timelineTime:fromInputTime:
	@abstract   Converts from input time of the filter's image input to timeline time.
	@param		timelineTime	The converted time, in CMTime.
	@param		time			The time of the input, in CMTime.
    @discussion In Motion, this timeline time and input time are always equal. In Final Cut Pro,
                this will provides the calculated timeline time for any given input time.
*/
- (void)timelineTime:(CMTime*)timelineTime
       fromInputTime:(CMTime)time;

/*!
	@method		timelineTime:fromImageTime:forParameterID:
	@abstract   Converts from image time of the given parameter to timeline time.
	@param		timelineTime	The converted time, in CMTime.
	@param		time			The parameter's time, in CMTime.
    @param      parameterID     The ID of the parameter.
*/
- (void)timelineTime:(CMTime*)timelineTime
       fromImageTime:(CMTime)time
      forParameterID:(UInt32)parameterID;

/*!
	@method		inputTime:fromTimelineTime:
	@abstract   Converts from timeline time to time of the filter's image input.
	@param		inputTime	    The converted time, in CMTime.
	@param		time			The timeline time, in CMTime.
    @discussion In Motion, this timeline time and input time are always equal. In Final Cut Pro,
                this method provides the calculated input time for any given timeline time.
*/
- (void)inputTime:(CMTime*)inputTime
 fromTimelineTime:(CMTime)time;

/*!
	@method		imageTime:fromParameterID:fromTimelineTime:
	@abstract   Converts from timeline time of the given parameter to image time.
	@param		imageTime	    The converted time, in CMTime.
    @param      parameterID     The ID of the parameter.
    @param      time            The parameter's time, in CMTime.
*/
- (void)imageTime:(CMTime*)imageTime
   forParameterID:(UInt32)parameterID
 fromTimelineTime:(CMTime)time;

/*!
	@method		fieldOrderForInputToFilter:
	@abstract   Return the field order of the filter input.
	@param		filter			The plug-in object.
	@result		An FxFieldOrder value (@c kFxFieldOrder_PROGRESSIVE, @c kFxFieldOrder_TOP_FIRST,
				or @c kFxFieldOrder_LOWER_FIRST).
    @discussion This method’s value refers to the field order of the input clip to which the user
                applies the effect, not the field order of the timeline.
*/
-(FxFieldOrder)fieldOrderForInputToFilter:(id<FxTileableEffect>)filter;

/*!
	@method		timelineFpsNumeratorForEffect:
	@abstract   Provides the numerator of the timeline's frame rate where the user applies the
                effect.
	@param		effect			The plug-in object.
	@result		The numerator of the frame rate.
	@discussion	You can use the numerator value with the companion denominator value to determine
                frames per second, or frame duration, of the timeline. For example, for 29.97 fps
                timelines, you might see values such as 30000 for the numerator, and 1001 for the
                denominator.
*/
- (NSUInteger)timelineFpsNumeratorForEffect:(id<FxTileableEffect>)effect;

/*!
	@method		timelineFpsDenominatorForEffect:
	@abstract   Provides the denominator of the timeline's frame rate where the user applies the
                effect.
	@param		effect			The plug-in object.
	@result		The denominator of the frame rate.
	@discussion	You can use the denominator value with the companion numerator value to determine
                frames per second, or frame duration, of the timeline. For example, for 29.97 fps
                timelines, you might see values such as 30000 for the numerator, and 1001 for the
                denominator.
*/
- (NSUInteger)timelineFpsDenominatorForEffect:(id<FxTileableEffect>)effect;

@end
#endif // !STUDIO_LITE
