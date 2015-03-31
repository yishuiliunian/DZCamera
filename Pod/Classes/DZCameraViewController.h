//
//  DZCameraViewController.h
//  Pods
//
//  Created by stonedong on 15/3/31.
//
//

#import <UIKit/UIKit.h>
#import "DZCameraManager.h"
#import "DZCameraViewControllerDelegate.h"
@interface DZCameraViewController : UIViewController
/**
 *  委托
 */
@property (nonatomic, weak) id<DZCameraViewControllerDelegate> delegate;
/**
 *  相机设备管理者
 */
@property (nonatomic, strong, readonly) DZCameraManager* cameraManager;
/**
 *  渲染视频流的界面
 */
@property (nonatomic, strong, readonly) UIView* cameraPreviewView;
/**
 *  默认在渲染视频流的界面上的占位图片
 */
@property (nonatomic, strong) UIImage* placeHolderImage;
/**
 *  通过相机的位置初始化相机界面
 *
 *  @param position 相机的位置，前置或者后置，还是其他
 *
 *  @return 相机界面的实例
 */
- (instancetype) initWithCameraDevicePosition:(AVCaptureDevicePosition)position;
@end
