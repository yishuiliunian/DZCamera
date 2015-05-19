//
//  DZCameraViewController.m
//  Pods
//
//  Created by stonedong on 15/3/31.
//
//

#import "DZCameraViewController.h"
#import "DZCameraManager.h"
#import <DZGeometryTools.h>
#import "UIImage+PSTools.h"
#import <DZImageCache.h>

UIImage* DZCameraCachedImageByName(NSString* name) {
    static NSBundle* bunlde = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString* path = [[NSBundle mainBundle] pathForResource:@"DZCamera" ofType:@"bundle"];
         bunlde = [NSBundle bundleWithPath:path];
    });
    return [DZImageShareCache cachedImageForName:name inBundle:bunlde];

}


static NSString* const kPSObjectKeyFrame = @"frame";
static float const kPSCameraPreviewHeight = 426;
@interface DZCameraViewController () <DZCameraManagerDelegate>
{
    //这些是相机的一些控件
    UIImageView* _faceView;
    //
    BOOL _isShowAnimation;
    //
    AVCaptureDevicePosition _devicePosition;
    BOOL _willFirstAppear;
}

@end
@implementation DZCameraViewController
@synthesize cameraManager = _cameraManager;
@synthesize cameraPreviewView = _cameraPreviewView;
@synthesize delegate = _delegate;

@synthesize placeHolderImage = _placeHolderImage;

- (instancetype) initWithCameraDevicePosition:(AVCaptureDevicePosition)position
{
    self = [super init];
    if (self) {
        _devicePosition = position;
    }
    return self;
}

- (UIButton*) buttonWithNormalImage:(NSString*)normalName highlitedImage:(NSString*)highlightedName target:(id)target actionr:(SEL)selector
{
    UIButton* btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:DZCameraCachedImageByName(normalName) forState:UIControlStateNormal];
    [btn setImage:DZCameraCachedImageByName(highlightedName) forState:UIControlStateHighlighted];
    [btn addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];
    btn.exclusiveTouch = YES;
    btn.showsTouchWhenHighlighted = YES;
    btn.imageEdgeInsets = UIEdgeInsetsMake(5, 5, 5, 5);
    return btn;
}

- (void) dealloc
{
    [_cameraPreviewView removeObserver:self forKeyPath:kPSObjectKeyFrame];
    [_cameraManager destroySession];
    _cameraManager = nil;
}



- (void) dismissCurrentViewController
{
    if ([_delegate respondsToSelector:@selector(cameraViewControllerDidUserCancel:)]) {
        [_delegate cameraViewControllerDidUserCancel:self];
    }
}
- (void) viewWillLayoutSubviews
{
    
    [super viewWillLayoutSubviews];
    _cameraPreviewView.frame = self.view.bounds;
    
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) cameraManager:(DZCameraManager *)manager captureStillImage:(UIImage *)image withError:(NSError *)error
{
    if ([_delegate respondsToSelector:@selector(cameraViewController:didGetImageFromCamera:)]) {
        if (image) {
            [_delegate cameraViewController:self didGetImageFromCamera:image];
        }
    }
}

- (void) captureStillImage
{
    if ([_delegate respondsToSelector:@selector(cameraViewControllerWillCaptureImage:)]) {
        [_delegate cameraViewControllerWillCaptureImage:self];
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        [_cameraManager captureStillImage];
    });
}



- (void) toggleCamera:(id)sender
{
    
    if ([_cameraManager isSupportedToggleDevice]) {
        [self loadDefaultHodlerAnimation];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError* error = nil;
            [_cameraManager toggleCameraDevice:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self removeDefaultHolderAnimation];
            });
        });
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        _isShowAnimation = NO;
        _devicePosition = AVCaptureDevicePositionBack;
        _willFirstAppear = YES;
    }

    return self;
}

- (void) blurPreviewContents
{
    UIImage* baseImage = [UIImage imageWithCGImage:(__bridge CGImageRef)(_cameraPreviewView.layer.contents)];
    UIImage* image = [baseImage applyBlurWithRadius:35 tintColor:nil saturationDeltaFactor:0.5 maskImage:nil];
    _cameraPreviewView.layer.contents = (__bridge id)(image.CGImage);
}

- (void) cameraManager:(DZCameraManager *)manager
         videoGetImage:(UIImage*)image
       didDetectroFace:(CGRect)faceRect
{
    
    if (_isShowAnimation) {
        return;
    }
    _cameraPreviewView.layer.contents = (__bridge id)(image.CGImage);
    
    if (!(CGRectIsEmpty(faceRect) && !CGRectIsNull(faceRect) && !CGRectIsInfinite(faceRect))) {
        CGRect viewFaceRect = CGRectZero;
        CGSize imageSize = image.size;
        viewFaceRect = CGRectMake(CGRectGetMinX(faceRect)/imageSize.width * CGRectGetWidth(_cameraPreviewView.frame),
                                  CGRectGetMinY(faceRect)/imageSize.height * CGRectGetHeight(_cameraPreviewView.frame) + CGRectGetMinY(_cameraPreviewView.frame),
                                  CGRectGetWidth(faceRect)/ imageSize.width * CGRectGetWidth(_cameraPreviewView.frame),
                                  CGRectGetHeight(faceRect)/imageSize.height * CGRectGetHeight(_cameraPreviewView.frame));
        if ((CGRectIsEmpty(viewFaceRect) || CGRectIsNull(viewFaceRect) || CGRectIsInfinite(viewFaceRect)))
        {
            return;
        }
        
        _faceView.frame = viewFaceRect;
    }
    else
    {
        _faceView.frame = CGRectZero;
    }
}

- (void)viewDidLoad
{
    
    [super viewDidLoad];
    _cameraManager = [[DZCameraManager alloc] init];
    _cameraManager.delegate = self;
    //
    [_cameraPreviewView removeObserver:self forKeyPath:kPSObjectKeyFrame];
    
    _cameraPreviewView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    _cameraPreviewView.layer.masksToBounds = YES;
    [_cameraPreviewView addObserver:self forKeyPath:kPSObjectKeyFrame options:NSKeyValueObservingOptionNew context:nil];
    [self.view addSubview:_cameraPreviewView];
    _cameraPreviewView.layer.frame = self.view.bounds;
    _cameraPreviewView.backgroundColor = [UIColor blackColor];
    _cameraPreviewView.contentMode = UIViewContentModeScaleAspectFill;
    _cameraPreviewView.userInteractionEnabled = YES;
    _faceView = [[UIImageView alloc] initWithImage:DZCameraCachedImageByName(@"camera_focus")];
    _faceView.frame = CGRectZero;
    [self.view addSubview:_faceView];
    [self initPinchGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark -



#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark package display
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////


#pragma mark -

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if (_willFirstAppear) {
        if ([_delegate respondsToSelector:@selector(cameraViewControllerWillSetupSession:)]) {
            [_delegate cameraViewControllerWillSetupSession:self];
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError* error;
            [_cameraManager setupCaptureSessionWithPositon:AVCaptureDevicePositionBack error:&error];
            [_cameraManager startRunning];
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([_delegate respondsToSelector:@selector(cameraViewControllerDidSetupSession:error:)]) {
                    [_delegate cameraViewControllerDidSetupSession:self error:error];
                }
            });
        });
        _willFirstAppear = !_willFirstAppear;
    }
    if (!_cameraManager.isRunning ) {
        [_cameraManager startRunning];
    }
}

- (void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [_cameraManager stopRunning];
}

#pragma mark -

#pragma mark Observer

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:_cameraPreviewView] && [keyPath isEqualToString:kPSObjectKeyFrame] ) {
        if ([self.delegate respondsToSelector:@selector(cameraViewController:didLayoutCameraPreView:)]) {
            [self.delegate cameraViewController:self didLayoutCameraPreView:_cameraPreviewView];
        }
    }
}



- (void) loadDefaultHodlerAnimation
{
    _isShowAnimation = YES;
    UIImage* baseImage = [UIImage imageWithCGImage:(__bridge CGImageRef)(_cameraPreviewView.layer.contents)];
    float blurRadius = 35;
    if (!baseImage) {
        if (_placeHolderImage) {
            baseImage = _placeHolderImage;
            blurRadius = 10;
        }
        else
        {
            baseImage = DZCameraCachedImageByName(@"Default@2x");
            blurRadius = 15;
        }
    }
    UIImage* image = [baseImage applyBlurWithRadius:blurRadius tintColor:nil saturationDeltaFactor:0.5 maskImage:nil];
    _cameraPreviewView.layer.contents = (__bridge id)(image.CGImage);
    CABasicAnimation* animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    animation.fromValue = @(0.5f);
    animation.toValue = @(1.0f);
    animation.duration = 1;
    animation.autoreverses = YES;
    animation.repeatCount = 4;
    [_cameraPreviewView.layer addAnimation:animation forKey:@"flashBlur"];
}

- (void) removeDefaultHolderAnimation
{
    [_cameraPreviewView.layer removeAnimationForKey:@"flashBlur"];
    _isShowAnimation = NO;
}

//
#pragma mark- 手势

- (void) initPinchGesture
{
    UIPinchGestureRecognizer* pG = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinchGesture:)];
    [self.view addGestureRecognizer:pG];
}
- (void) handlePinchGesture:(UIPinchGestureRecognizer*)pg{
    if (pg.state == UIGestureRecognizerStateChanged) {
        NSLog(@"pg scale is %f",pg.scale);
        NSLog(@"factor is %f", _cameraManager.deviceInput.device.videoZoomFactor);
        
        float currentFactor = _cameraManager.deviceInput.device.videoZoomFactor;
        float scale = pg.scale;
        float maxFactor  = MIN(_cameraManager.deviceInput.device.activeFormat.videoMaxZoomFactor,3);
        float aimFactor = scale * currentFactor;
        if (aimFactor < 1) {
            aimFactor = 1;
        }
        if (aimFactor > maxFactor) {
            aimFactor = maxFactor;
        }
        [_cameraManager.deviceInput.device lockForConfiguration:nil];
        [_cameraManager.deviceInput.device cancelVideoZoomRamp];
        [_cameraManager.deviceInput.device rampToVideoZoomFactor:aimFactor withRate:25];
        [_cameraManager.deviceInput.device unlockForConfiguration];
    }
}
@end
