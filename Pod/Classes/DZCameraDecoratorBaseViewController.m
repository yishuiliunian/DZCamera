//
//  DZCameraDecoratorBaseViewController.m
//  Pods
//
//  Created by stonedong on 15/3/31.
//
//

#import "DZCameraDecoratorBaseViewController.h"

const float kDZAnimationDefaultDuration = 0.25;

@implementation DZCameraDecoratorBaseViewController
@synthesize getImageBlock = _getImageBlock;
@synthesize needRealTimeDetectFace = _needRealTimeDetectFace;
@synthesize currentViewController = _currentViewController;
@synthesize placeHolderImage = _placeHolderImage;


- (void) setPlaceHolderImage:(UIImage *)placeHolderImage
{
    _placeHolderImage = placeHolderImage;
    _cameraViewController.placeHolderImage = placeHolderImage;
}

- (void) didRemoveCameraViewController
{
    
}

- (void) removeCameraViewController
{
    [_cameraViewController willMoveToParentViewController:nil];
    [_cameraViewController removeFromParentViewController];
    [self configureRemoveCameraViewControllerAnimation:^{
        [_cameraViewController.view removeFromSuperview];
        
    }];
    [_cameraViewController didMoveToParentViewController:Nil];
    [self didRemoveCameraViewController];
    _cameraViewController = nil;
}

- (void) configureAddCameraViewControllerAnimation:(DZAnimationCompletionBlock)block
{
    block();
}

- (void) configureRemoveCameraViewControllerAnimation:(DZAnimationCompletionBlock)block
{
    block();
}

- (void) didAddCameraViewController
{
    
}
- (void) addCameraViewController
{
    _cameraViewController = [[DZCameraViewController alloc] init];
    _cameraViewController.placeHolderImage = _placeHolderImage;
    _cameraViewController.delegate = self;
    [_cameraViewController willMoveToParentViewController:self];
    [self addChildViewController:_cameraViewController];
    [self.view addSubview:_cameraViewController.view];
    [self configureAddCameraViewControllerAnimation:^{
        
        _cameraViewController.view.frame = self.view.bounds;
        
    }];
    [_cameraViewController didMoveToParentViewController:self];
    _currentViewController = _cameraViewController;
    [self didAddCameraViewController];
}

- (void) initCameraViewController
{
    [self addCameraViewController];
}

- (void) setNeedRealTimeDetectFace:(BOOL)needRealTimeDetectFace
{
    _needRealTimeDetectFace = needRealTimeDetectFace;
    if (_needRealTimeDetectFace) {
        double delayInSeconds = 0.5;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            _cameraViewController.cameraManager.detectFaceRealTime = YES;
        });
    }
    else
    {
        _cameraViewController.cameraManager.detectFaceRealTime = NO;
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initCameraViewController];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark CameraViewController delegate
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) cameraViewControllerDidUserCancel:(DZCameraViewController *)cameraViewController
{
    [self dismissModalViewControllerAnimated:YES];
}


- (void) cameraViewController:(DZCameraViewController *)cameraViewController didGetImageFromCamera:(UIImage*)image
{
    if (_getImageBlock) {
        _getImageBlock(self, image);
    }
}

- (void) cameraViewController:(DZCameraViewController *)cameraViewController didGetImageFromAlbum:(UIImage*)image
{
    if (_getImageBlock) {
        _getImageBlock(self, image);
    }
}

#pragma -
#pragma 界面逻辑控制

- (void) pushNextViewController:(UIViewController *)viewController withAnimation:(BOOL)animation completion:(DZAnimationCompletionBlock)completionBlock
{
    if (_currentViewController != _cameraViewController) {
        return;
    }
    [self removeCameraViewController];
    [viewController willMoveToParentViewController:self];
    [self addChildViewController:viewController];
    [self.view addSubview:viewController.view];
    viewController.view.frame = self.view.frame;
    
    
    void(^animationBlock)(void) = ^(void) {
#warning 这里需要对动画进行处理
    };
    
    void(^finishAnimationBlock)(void) = ^(void) {
        [viewController didMoveToParentViewController:self];
        _currentViewController = viewController;
        if (completionBlock) {
            completionBlock();
        }
    };
    if (animation) {
        [UIView animateWithDuration:kDZAnimationDefaultDuration animations:animationBlock completion:^(BOOL finished) {
            finishAnimationBlock();
        }];
    }
    else
    {
        animationBlock();
        finishAnimationBlock();
    }
}

- (void) popToCameraViewControllerWithAnimation:(BOOL)animation completion:(DZAnimationCompletionBlock)completionBlock
{
    
    if (_currentViewController == _cameraViewController) {
        return;
    }
    [_currentViewController willMoveToParentViewController:Nil];
    void(^animationBlock)(void) = ^(void) {
        
    };
    
    void(^finishAnimationBlock)(void) = ^(void) {
        [_currentViewController.view removeFromSuperview];
        [_currentViewController removeFromParentViewController];
        [_currentViewController didMoveToParentViewController:nil];
        [self addCameraViewController];
        if (completionBlock) {
            completionBlock();
        }
    };
    if (animation) {
        [UIView animateWithDuration:kDZAnimationDefaultDuration animations:animationBlock completion:^(BOOL finished) {
            finishAnimationBlock();
        }];
    }
    else
    {
        animationBlock();
        finishAnimationBlock();
    }
}

- (void) cameraViewControllerWillSetuDZession:(DZCameraViewController *)cameraViewController
{
    
}

- (void) cameraViewControllerWillCaptureImage:(DZCameraViewController *)cameraViewController
{
    
}

- (void) cameraViewControllerDidSetuDZession:(DZCameraViewController *)cameraViewController error:(NSError *)error
{
    
}


@end
