//
//  DZCameraDecoratorBaseViewController.h
//  Pods
//
//  Created by stonedong on 15/3/31.
//
//

#import <UIKit/UIKit.h>
#import "DZCameraViewController.h"
typedef enum {
    DZCameraAnimationTypeTrasition,
    DZCameraAnimationTypeViewAnimation
}DZCameraAnimationType;

/**
 *  获取照片后的回调
 *
 *  @param decoratorViewController 装饰者实例
 *  @param image                   获取到的图片
 *
 *  @return void
 */
@class DZCameraDecoratorBaseViewController;
typedef void (^DZCameraDecoratorGetImageBlock)(DZCameraDecoratorBaseViewController* decoratorViewController, UIImage* image);


/**
 *  动画结束后的回调
 *
 *  @param void void
 *
 *  @return void
 */
typedef void(^DZAnimationCompletionBlock)(void);





@interface DZCameraDecoratorBaseViewController : UIViewController <DZCameraViewControllerDelegate>
{
    DZCameraViewController* _cameraViewController;
    DZCameraDecoratorGetImageBlock _getImageBlock;
}
/**
 *  当前在装饰者上面的视图控制器
 */
@property (nonatomic, strong, readonly) UIViewController* currentViewController;
/**
 *  装饰者装饰的CameraViewController
 */
@property (nonatomic, strong, readonly) DZCameraViewController* cameraViewController;
/**
 *  回调
 */
@property (nonatomic, strong) DZCameraDecoratorGetImageBlock getImageBlock;
/**
 *  在CameraViewController上的占位图片
 */
@property (nonatomic, strong) UIImage* placeHolderImage;

//设置是否实时人脸检测
@property (nonatomic, assign) BOOL needRealTimeDetectFace;


/**
 * 添加CameraViewController
 *
 * @return void
 */
- (void) addCameraViewController;

/**
 * 删除 CameraViewController
 *
 * @return void
 */
- (void) removeCameraViewController;


/**
 * 配置添加CameraViewController 的时候的动画效果，在子类化实现该方法的时候，一定要调用block;
 * @param  block 动画完成后的block
 * @return void
 */
- (void) configureAddCameraViewControllerCompletionAnimation:(DZAnimationCompletionBlock)block;
/**
 * 配置删除CameraViewController 的时候的动画效果，在子类化实现该方法的时候，一定要调用block;
 * @param  block 动画完成后的block
 * @return void
 */
- (void) configureRemoveCameraViewControllerCompletionAnimation:(DZAnimationCompletionBlock)block;

/**
 * 添加CameraViewController之后的会调用改函数，如果要再添加完成后添加一些自定义的内容在这里面添加
 * @return void
 */
- (void) didRemoveCameraViewController;

/**
 * 删除CameraViewController之后的会调用改函数，如果要再添加完成后添加一些自定义的内容在这里面添加
 * @return void
 */
- (void) didAddCameraViewController;


/**
 *   切换到下一个视图
 *
 *  @param viewController  将要切换的视图
 *  @param animation       是否使用动画
 *  @param completionBlock 动画结束后的回调
 */
- (void) pushNextViewController:(UIViewController*)viewController withAnimation:(BOOL)animation completion:(DZAnimationCompletionBlock)completionBlock;

/**
 *   从其他试图返回到拍照界面
 *
 *  @param animation       是否使用动画
 *  @param completionBlock 动画结束后的回调
 */
- (void) popToCameraViewControllerWithAnimation:(BOOL)animation completion:(DZAnimationCompletionBlock)completionBlock;
@end