//
//  DZCameraManager.m
//  Pods
//
//  Created by stonedong on 15/3/31.
//
//

#import "DZCameraManager.h"
#import "AVCamUtilities.h"
#import <DZGeometryTools.h>
NSString* const DZCameraManagerErrorDomain = @"DZCameraManagerErrorDomain";

typedef struct {
    BOOL didDetectorFace;
    BOOL didCaptureStillImage;
}DZCameraManagerDeleteResponse;


@interface DZCameraManager ()<AVCaptureVideoDataOutputSampleBufferDelegate>
{
    dispatch_queue_t _videoProcessingQueue;
    CIDetector* _appleFaceDetector;
    
    DZCameraManagerDeleteResponse _delegaetResonse;
    
}
+ (AVCaptureDevice*) videoCameraWithPosition:(AVCaptureDevicePosition) position;

@end
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark 获取设备，此处将IOS设备的所有视频设备链接做了缓存。有待验证，重新启动的时候，连接是否失效。
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static inline NSDictionary* PSAVCaptureDevices()
{
    static NSDictionary* devicesKeyValues = Nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableDictionary* dic = [NSMutableDictionary new];
        NSArray* devices = [AVCaptureDevice devices];
        for (AVCaptureDevice* device in devices) {
            [dic setObject:device forKey:@(device.position)];
        }
        devicesKeyValues = dic;
    });
    return devicesKeyValues;
}

inline AVCaptureDevice* PSVideoCameraFront()
{
    return [DZCameraManager videoCameraWithPosition:AVCaptureDevicePositionFront];
}

inline AVCaptureDevice* PSVideoCameraBack()
{
    return [DZCameraManager videoCameraWithPosition:AVCaptureDevicePositionFront];
}




@implementation DZCameraManager
@synthesize delegate = _delegate;
@synthesize deviceInput = _deviceInput;
@synthesize session = _session;
@synthesize isRunning = _isRunning;
@synthesize isPaused = _isPaused;
@synthesize orientation = _orientation;
@synthesize stillImageOutput = _stillImageOutput;
@synthesize videoDataOutput = _videoDataOutput;
@synthesize filterID = _filterID;
@synthesize detectFaceRealTime = _detectFaceRealTime;

//
+ (AVCaptureDevice*) videoCameraWithPosition:(AVCaptureDevicePosition) position
{
    NSDictionary* devices = PSAVCaptureDevices();
    return devices[@(position)];
}

- (void) dealloc
{
    [self destroySession];
}

- (void) setDelegate:(id<DZCameraManagerDelegate>)delegate
{
    _delegate = delegate;
    _delegaetResonse.didDetectorFace = [_delegate respondsToSelector:@selector(cameraManager:videoGetImage:didDetectroFace:)];
    _delegaetResonse.didCaptureStillImage = [_delegate respondsToSelector:@selector(cameraManager:captureStillImage:withError:)];
}

- (AVCaptureDevice*) setupCaptureDeviceWithPostion:(AVCaptureDevicePosition)position
                                             error:(NSError* __autoreleasing*)error
{
    
    AVCaptureDevice* device = [DZCameraManager videoCameraWithPosition:position];
    if (!device) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:DZCameraManagerErrorDomain
                                         code:DZCameraErrorCodeDeviceError
                                     userInfo:@{NSLocalizedDescriptionKey:@"初始化设备错误！"}];
        }
        return nil;
    }
    //
    if ([device hasFlash]) {
        if ([device lockForConfiguration:error]) {
            if ([device isFlashModeSupported:AVCaptureFlashModeAuto]) {
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
        else
        {
            return nil;
        }
    }
    if ([device hasTorch]) {
        if ([device lockForConfiguration:error]) {
            if ([device isTorchModeSupported:AVCaptureTorchModeOff]) {
                [device setTorchMode:AVCaptureTorchModeOff];
            }
            [device unlockForConfiguration];
        }
        else
        {
            return Nil;
        }
    }
    //
    if ([device respondsToSelector:@selector(setSubjectAreaChangeMonitoringEnabled:)]) {
        if ([device lockForConfiguration:error]) {
            [device setSubjectAreaChangeMonitoringEnabled:YES];
            [device unlockForConfiguration];
        }
        else
        {
            return nil;
        }
    }
    
    //
    
    return device;
    //
}

- (BOOL) setupCaptureSessionWithPositon:(AVCaptureDevicePosition)position
                                  error:(NSError *__autoreleasing *)error
{
    AVCaptureDevice* device = [self setupCaptureDeviceWithPostion:position
                                                            error:error];
    if (!device) {
        return NO;
    }
    //
    _deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:device
                                                          error:error];
    if (*error) {
        return NO;
    }
    //
    _stillImageOutput =[[AVCaptureStillImageOutput alloc] init];
    NSDictionary *outputSettings = @{ AVVideoCodecJPEG: AVVideoCodecKey};
    [_stillImageOutput setOutputSettings:outputSettings];
    //
    //
    _session = [[AVCaptureSession alloc] init];
    if ([_session canAddInput:_deviceInput]) {
        [_session addInput:_deviceInput];
    }
    else
    {
        if (error != NULL) {
            *error = [NSError errorWithDomain:DZCameraManagerErrorDomain
                                         code:DZCameraErrorCodeDeviceError
                                     userInfo:@{NSLocalizedDescriptionKey:@"初始化设备失败！"}];
        }
        return NO;
    }
    
    if ([_session canAddOutput:_stillImageOutput]) {
        [_session addOutput:_stillImageOutput];
    }
    else
    {
        if (error != NULL) {
            *error = [NSError errorWithDomain:DZCameraManagerErrorDomain
                                         code:DZCameraErrorCodeDeviceError
                                     userInfo:@{NSLocalizedDescriptionKey:@"初始化设备失败！"}];
        }
        return NO;
    }
    [_session setSessionPreset:AVCaptureSessionPresetPhoto];
    //
    _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
    _videoDataOutput.alwaysDiscardsLateVideoFrames = YES;
    NSDictionary* videoSettings = @{(id)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
    [_videoDataOutput setVideoSettings:videoSettings];
    
    _videoProcessingQueue = dispatch_queue_create("com.tencent.qqpicshow.video.processing", NULL);
    
    [_videoDataOutput setSampleBufferDelegate:self
                                        queue:_videoProcessingQueue];
    if ([_session canAddOutput:_videoDataOutput]) {
        [_session addOutput:_videoDataOutput];
    }
    else
    {
        if (error != NULL) {
            *error = [NSError errorWithDomain:DZCameraManagerErrorDomain
                                         code:DZCameraErrorCodeDeviceError
                                     userInfo:@{NSLocalizedDescriptionKey:@"初始化设备失败！"}];
        }
        return NO;
    }
    
    [self setFilterID:@(0)];
    
    NSArray* connections = [_videoDataOutput connections];
    for (AVCaptureConnection*  each in connections) {
        if ([each isVideoOrientationSupported]) {
            [each setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
    }
    return YES;
}

- (void) destroySession
{
    [_session removeInput:_deviceInput];
    [_session removeOutput:_stillImageOutput];
    [_session removeOutput:_videoDataOutput];
    [_session stopRunning];
    _session = nil;
    _videoProcessingQueue = nil;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Session control
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) startRunning
{
    [_session startRunning];
    _isRunning = YES;
    _isPaused = NO;
}

- (void) stopRunning
{
    [_session stopRunning];
    _isRunning = NO;
    
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark Camera Buffer Delegate
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


- (void) captureOutput:(AVCaptureOutput *)captureOutput
 didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
        fromConnection:(AVCaptureConnection *)connection
{
    if (_isPaused) {
        return;
    }
    @autoreleasepool {
        
        UIImage* outputImage;
        CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
        /*Lock the image buffer*/
        CVPixelBufferLockBaseAddress(imageBuffer,0);
        /*Get information about the image*/
        uint8_t *baseAddress = (uint8_t *)CVPixelBufferGetBaseAddress(imageBuffer);
        size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
        size_t width = CVPixelBufferGetWidth(imageBuffer);
        size_t height = CVPixelBufferGetHeight(imageBuffer);
        /*Create a CGImageRef from the CVImageBufferRef*/
        CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
        CGContextRef newContext = CGBitmapContextCreate(baseAddress, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
        CGImageRef tempImage = CGBitmapContextCreateImage(newContext);
        /*We release some components*/
        CGContextRelease(newContext);
        CGColorSpaceRelease(colorSpace);
        /*We unlock the  image buffer*/
        CVPixelBufferUnlockBaseAddress(imageBuffer,0);
        outputImage = [UIImage imageWithCGImage:tempImage];
        
        CGImageRelease(tempImage);
        
        
        if (_detectFaceRealTime) {
            CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
            CIImage* image = [[CIImage alloc] initWithCGImage:outputImage.CGImage
                                                      options:(__bridge NSDictionary *)(attachments)];
            NSDictionary *imageOptions = nil;
            enum {
                PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
                PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
                PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
                PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
                PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
                PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
                PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
                PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
            };
            
            //检测出来的头像 关于y方向 中心轴对称
            imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:PHOTOS_EXIF_0ROW_TOP_0COL_LEFT]
                                                       forKey:CIDetectorImageOrientation];
            NSArray* features = [_appleFaceDetector
                                 featuresInImage:image
                                 options:imageOptions
                                 ];
            
            
            if (features.count) {
                for (CIFaceFeature* each  in features) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        NSLog(@"image %f %f",outputImage.size.width, outputImage.size.height);
                        NSLog(@"face is %f %f %f %f",each.bounds.origin.x, each.bounds.origin.y ,each.bounds.size.width, each.bounds.size.height);
                        
                        CGPoint centerPoint = CGRectGetCenter(each.bounds);
                        CGRect faceRect = each.bounds;
                        faceRect = CGRectMake(each.bounds.origin.x,
                                              outputImage.size.height - centerPoint.y - CGRectGetHeight(each.bounds)/2,
                                              CGRectGetWidth(each.bounds),
                                              CGRectGetHeight(each.bounds));
                        
                        [_delegate cameraManager:self videoGetImage:outputImage
                                 didDetectroFace:faceRect];
                    });
                }
                
            }
            else
            {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [_delegate cameraManager:self videoGetImage:outputImage
                             didDetectroFace:CGRectZero];
                });
            }
        }
        else
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [_delegate cameraManager:self videoGetImage:outputImage
                         didDetectroFace:CGRectZero];
            });
        }
    }
}
- (AVCaptureVideoOrientation) currentCaptureVideoOrientation
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    switch (deviceOrientation) {
        case UIDeviceOrientationFaceDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIDeviceOrientationFaceUp:
            return AVCaptureVideoOrientationPortrait;
        case UIDeviceOrientationLandscapeLeft:
            return AVCaptureVideoOrientationLandscapeLeft;
        case UIDeviceOrientationLandscapeRight:
            return AVCaptureVideoOrientationLandscapeRight;
        case UIDeviceOrientationPortrait:
            return AVCaptureVideoOrientationPortrait;
        case UIDeviceOrientationPortraitUpsideDown:
            return AVCaptureVideoOrientationPortraitUpsideDown;
        case UIDeviceOrientationUnknown:
            return AVCaptureVideoOrientationPortrait;
            break;
            
        default:
            return AVCaptureVideoOrientationPortrait;
    }
    
}
- (void) captureStillImage
{
    [self pause];
    AVCaptureConnection* stillImageConnection = [AVCamUtilities
                                                 connectionWithMediaType:AVMediaTypeVideo
                                                 fromConnections:_stillImageOutput.connections];
    if ([stillImageConnection isVideoOrientationSupported]) {
        [stillImageConnection setVideoOrientation:[self currentCaptureVideoOrientation]];
    }
    [_stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (error) {
            if (_delegaetResonse.didCaptureStillImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate cameraManager:self captureStillImage:Nil withError:error];
                });
            }
        }
        else
        {
            NSData* data = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
            UIImage* image = [UIImage imageWithData:data];
            if (_delegaetResonse.didCaptureStillImage) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [_delegate cameraManager:self captureStillImage:image withError:nil];
                });
            }
        }
        [self startRunning];
    }];
}

- (BOOL) isSupportedToggleDevice
{
    return PSAVCaptureDevices().count > 1;
}

- (BOOL) toggleCameraDevice:(NSError *__autoreleasing *)error
{
    AVCaptureDevicePosition position = [_deviceInput device].position;
    AVCaptureDevicePosition descPosition = AVCaptureDevicePositionBack;
    switch (position) {
        case AVCaptureDevicePositionBack:
            descPosition = AVCaptureDevicePositionFront;
            break;
        case AVCaptureDevicePositionFront:
            descPosition = AVCaptureDevicePositionBack;
            break;
        default:
            descPosition = AVCaptureDevicePositionBack;
            break;
    }
    
    AVCaptureDevice* device = [self setupCaptureDeviceWithPostion:descPosition error:error];
    if (*error) {
        return NO;
    }
    AVCaptureDeviceInput* input = [AVCaptureDeviceInput deviceInputWithDevice:device error:error];
    if (*error) {
        return NO;
    }
    [_session beginConfiguration];
    [_session removeInput:_deviceInput];
    if ([_session canAddInput:input]) {
        [_session addInput:input];
        _deviceInput  = input;
    }
    else
    {
        
        if (error != NULL) {
            *error = [NSError errorWithDomain:DZCameraManagerErrorDomain
                                         code:DZCameraErrorCodeDeviceError
                                     userInfo:@{NSLocalizedDescriptionKey:@"初始化设备失败！"}];
        }
        return NO;
    }
    [_session commitConfiguration];
    NSArray* connections = [_videoDataOutput connections];
    for (AVCaptureConnection*  each in connections) {
        if ([each isVideoOrientationSupported]) {
            [each setVideoOrientation:AVCaptureVideoOrientationPortrait];
        }
        if (descPosition == AVCaptureDevicePositionFront) {
            if ([each isVideoMirroringSupported]) {
                [each setVideoMirrored:YES];
            }
        }
    }
    return YES;
}

- (BOOL) setupDeviceFlashMode:(AVCaptureFlashMode)mode error:(NSError *__autoreleasing *)error
{
    if ([_deviceInput.device lockForConfiguration:error]) {
        [_deviceInput.device setFlashMode:mode];
        [_deviceInput.device unlockForConfiguration];
        return YES;
    }
    else
    {
        if (error != NULL) {
            *error = [NSError errorWithDomain:DZCameraManagerErrorDomain code:DZCameraErrorCodeDeviceError userInfo:@{NSLocalizedDescriptionKey:@"设备枷锁失败!"}];
        }
        return NO;
    }
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark 设置人脸检测
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (BOOL) detectFaceRealTime
{
    @synchronized(self)
    {
        return _detectFaceRealTime;
    }
}
- (void) setDetectFaceRealTime:(BOOL)detectFaceRealTime
{
    @synchronized(self)
    {
        _detectFaceRealTime = detectFaceRealTime;
        if (_detectFaceRealTime) {
            NSDictionary *detectorOptions = [[NSDictionary alloc]
                                             initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
            _appleFaceDetector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                    context:nil
                                                    options:detectorOptions];
        }
        else{
            _appleFaceDetector = nil;
        }
    }
}


#pragma mark 设置实时滤镜
- (NSNumber*) filterID
{
    return  Nil;
}

- (void) setFilterID:(NSNumber *)filterID
{
    
}

- (void) pause
{
    _isPaused = YES;
}
@end
