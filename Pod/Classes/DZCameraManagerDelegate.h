//
//  DZCameraManagerDelegate.h
//  Pods
//
//  Created by stonedong on 15/3/31.
//
//

#import <Foundation/Foundation.h>
@class AVCaptureSession;
@class DZCameraManager;
@protocol DZCameraManagerDelegate <NSObject>
/**
 *  相机视频流获取到了图片后回调改函数
 *
 *  @param manager  相机管理者
 *  @param image    捕获到的图片
 *  @param faceRect 检测到的人脸的Frame，如果没有检测到人脸返回CGRectZero
 */
- (void) cameraManager:(DZCameraManager*)manager
         videoGetImage:(UIImage*)image
       didDetectroFace:(CGRect)faceRect;

/**
 *  相机拍照后的回调
 *
 *  @param manager 相机管理者
 *  @param image   拍照所得图片
 *  @param error   出错后返回的错误码
 */
- (void) cameraManager:(DZCameraManager *)manager
     captureStillImage:(UIImage*)image
             withError:(NSError*)error;
@end
