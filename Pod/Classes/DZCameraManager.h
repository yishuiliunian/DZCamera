//
//  DZCameraManager.h
//  Pods
//
//  Created by stonedong on 15/3/31.
//
//

#import <Foundation/Foundation.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "DZCameraManagerDelegate.h"
//
extern  NSString* const DZCameraManagerErrorDomain ;

typedef enum {
    DZCameraErrorCodeDeviceError = -8001,
}DZCameraErrorCode;


//
@protocol DZCameraManagerDelegate;
@interface DZCameraManager : NSObject
//
@property (nonatomic, weak) id<DZCameraManagerDelegate> delegate;
//
@property (nonatomic, strong, readonly) AVCaptureSession* session;
@property (nonatomic, assign, readonly) AVCaptureVideoOrientation orientation;
@property (nonatomic, strong, readonly) AVCaptureStillImageOutput* stillImageOutput;
@property (nonatomic, strong, readonly) AVCaptureVideoDataOutput* videoDataOutput;
@property (nonatomic, strong, readonly) AVCaptureDeviceInput* deviceInput;
@property (nonatomic, assign, readonly) BOOL isRunning;
@property (nonatomic, assign, readonly) BOOL isPaused;

//是否实时监测人脸,建议再启动session后，延时0.5s左右设置，这样可以加快启动速度。
@property (atomic, assign) BOOL detectFaceRealTime;

//设置实时滤镜，默认使用滤镜0，无任何效果
@property (atomic, strong) NSNumber* filterID;

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark method
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
/**
 *设备初始化（类初始化与设备初始化分离，以提高相应速度），此处设备初始化，可以放入后台线程中执行。
 *
 *
 *@param position  设备类型，前置摄像头，或者后置摄像头
 *@param error 错误指针，如果出错，将会给该指针赋值，将错误传给调用者。
 *@return 是否初始化成功
 **/
- (BOOL) setupCaptureSessionWithPositon:(AVCaptureDevicePosition)position  error:(NSError**)error;


/**
 * 注销设备
 *
 **/
- (void) destroySession;


/**
 * 启动视频输出
 *
 **/

- (void) startRunning;

/**
 * 停止视频输出
 *
 **/
- (void) stopRunning;

/**
 * 捕获静态图片
 *
 **/
- (void) captureStillImage;

/**
 * 是否支持摄像头切换
 *
 * @return 是否支持摄像头切换
 */
- (BOOL) isSupportedToggleDevice;

/**
 * 切换摄像头
 @param  error 失败的错误类型
 @return BOOL 是否成功切换摄像头
 */
- (BOOL) toggleCameraDevice:(NSError**)error;

/**
 * 设置摄像头闪光灯的类型
 * @param  mode 闪光灯类型
 @param error 如果失败，表示失败的原因。
 * @return 是否设置成功
 */
- (BOOL) setupDeviceFlashMode:(AVCaptureFlashMode)mode error:(NSError**)error;


- (void) pause;
@end
