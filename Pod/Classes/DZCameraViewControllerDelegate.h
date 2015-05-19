//
//  DZCameraViewControllerDelegate.h
//  Pods
//
//  Created by stonedong on 15/3/31.
//
//

#import <Foundation/Foundation.h>
@class DZCameraViewController;
@protocol DZCameraViewControllerDelegate <NSObject>
@optional

/**
 * 将要拍照
 * @param  cameraViewController 相机视图
 * @return void
 */
- (void) cameraViewControllerWillCaptureImage:(DZCameraViewController*)cameraViewController;

/**
 * 将要初始化相机操作，这是个好事的操作
 * @param  cameraViewController 相机视图
 * @return void
 */


- (void) cameraViewControllerWillSetupSession:(DZCameraViewController *)cameraViewController;

/**
 * 初始化相机功能完成
 * @param  cameraViewController 相机视图
 * @return void
 */
- (void) cameraViewControllerDidSetupSession:(DZCameraViewController *)cameraViewController error:(NSError*)error;

/**
 * 拍照出错
 * @param  error 如果出错，这个存储错误
 * @return void
 */

- (void) cameraViewController:(DZCameraViewController *)cameraViewController getImageError:(NSError*)error;
/**
 * 当相机展示视图的frame发生改变的时候将会发送该消息
 * @param  camerViewController 相机视图控制器
 @param cameraPreview 预览视图
 * @return void
 */
- (void) cameraViewController:(DZCameraViewController*)camerViewController didLayoutCameraPreView:(UIView*)cameraPreview;

/**
 * 用户取消获取图片
 * @param   camerViewController 相机视图控制器
 * @return void
 */
- (void) cameraViewControllerDidUserCancel:(DZCameraViewController*)cameraViewController;


/**
 * 用户从相机获取了图片
 * @param   camerViewController 相机视图控制器
 @param 相机拍摄的图片
 * @return void
 */
- (void) cameraViewController:(DZCameraViewController *)cameraViewController didGetImageFromCamera:(UIImage*)image;




@end
