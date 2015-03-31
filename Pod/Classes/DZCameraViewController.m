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
    UIButton* _captureButton;
    UIButton* _toggleCameraButton;
    UIButton* _flashButton;
    UIImageView* _flashChangeView;
    UIImageView* _topToolView;
    UIImageView* _bottomToolView;
    UIButton* _imagePickerButton;
    UIView* _flashChangedBackgroudView;
    UIButton* _backButton;
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

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark device flash 设置
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
- (void) removeFlashChangedView
{
    [_flashChangedBackgroudView removeFromSuperview];
    _flashChangedBackgroudView = nil;
}

- (void) setCameraDeviceFlashModel:(AVCaptureFlashMode)mode
{
    NSError* error = nil;
    [_cameraManager setupDeviceFlashMode:mode error:&error];
    [_flashButton setImage:[UIImage imageNamed:[self buttonImageNameWithFlashMode:mode]] forState:UIControlStateNormal];
}
- (void) flashOn
{
    [self removeFlashChangedView];
    [self setCameraDeviceFlashModel:AVCaptureFlashModeOn];
}

- (void) flashOff
{
    [self removeFlashChangedView];
    [self setCameraDeviceFlashModel:AVCaptureFlashModeOff];
}

- (void) flashAuto
{
    [self removeFlashChangedView];
    [self setCameraDeviceFlashModel:AVCaptureFlashModeAuto];
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark 相机界面初始化 和  视图调整
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

- (void) showChangeFlashModelToolBar:(id)sender
{
    [_flashChangedBackgroudView removeFromSuperview];
    _flashChangedBackgroudView = [[UIView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_flashChangedBackgroudView];
    
    _flashChangeView = [[UIImageView alloc] initWithImage:DZCameraCachedImageByName(@"camera_flash_mode_select_bg")];
    _flashChangeView.userInteractionEnabled = YES;
    [_flashChangedBackgroudView addSubview:_flashChangeView];
    
    UIButton* flashOnBtn = [self buttonWithNormalImage:[self buttonImageNameWithFlashMode:AVCaptureFlashModeOn] highlitedImage:Nil target:self actionr:@selector(flashOn)];
    [_flashChangeView addSubview:flashOnBtn];
    
    UIButton* flashOffBtn = [self buttonWithNormalImage:[self buttonImageNameWithFlashMode:AVCaptureFlashModeOff] highlitedImage:Nil target:self actionr:@selector(flashOff)];
    [_flashChangeView addSubview:flashOffBtn];
    
    UIButton* flashAutoBtn = [self buttonWithNormalImage:[self buttonImageNameWithFlashMode:AVCaptureFlashModeAuto] highlitedImage:Nil target:self actionr:@selector(flashAuto)];
    [_flashChangeView addSubview:flashAutoBtn];
    
    flashOffBtn.exclusiveTouch = YES;
    flashOnBtn.exclusiveTouch = YES;
    flashAutoBtn.exclusiveTouch = YES;
    float btnWidth = 30;
    float btnOffSet = 10;
    
    _flashChangeView.frame = CGRectMake(CGRectGetMinX(_flashButton.frame), CGRectGetMaxY(_flashButton.frame), 44, 30*3 + 10*4);
    float xOffSet = (CGRectGetWidth(_flashChangeView.frame) - btnWidth) /2;
    flashAutoBtn.frame = CGRectMake(xOffSet, btnOffSet, btnWidth, btnWidth);
    flashOnBtn.frame = CGRectMake(xOffSet, CGRectGetMaxY(flashAutoBtn.frame) + btnOffSet, btnWidth, btnWidth);
    flashOffBtn.frame = CGRectMake(xOffSet, CGRectGetMaxY(flashOnBtn.frame) + btnOffSet, btnWidth, btnWidth);
    
    
    UITapGestureRecognizer* tapGestrue = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDismissFlashChangedViewTapRecg:)];
    tapGestrue.numberOfTapsRequired = 1;
    tapGestrue.numberOfTouchesRequired = 1;
    [_flashChangedBackgroudView addGestureRecognizer:tapGestrue];
}

- (void) handleDismissFlashChangedViewTapRecg:(UITapGestureRecognizer*)tapRecg
{
    [self removeFlashChangedView];
}

- (NSString*) buttonImageNameWithFlashMode:(AVCaptureFlashMode)mode
{
    NSString* buttonImageName = nil;
    switch (mode) {
        case AVCaptureFlashModeAuto:
            buttonImageName = @"camera_flash_auto";
            break;
        case AVCaptureFlashModeOff:
            buttonImageName = @"camera_flash_off";
            break;
        case AVCaptureFlashModeOn:
            buttonImageName = @"camera_flash_on";
            break;
        default:
            buttonImageName = @"camera_flash_auto";
            break;
    }
    return buttonImageName;
}


- (void) initTopToolView
{
    _topToolView = [[UIImageView alloc] initWithImage:DZCameraCachedImageByName(@"camera_top_bar_bg")];
    [self.view addSubview:_topToolView];
    _topToolView.userInteractionEnabled = YES;
    AVCaptureFlashMode mode = _cameraManager.deviceInput.device.flashMode;
    NSString* buttonName = [self buttonImageNameWithFlashMode:mode];
    UIButton* btn = [self buttonWithNormalImage:buttonName highlitedImage:nil target:self actionr:@selector(showChangeFlashModelToolBar:)];
    _flashButton = btn;
    
    _flashButton.showsTouchWhenHighlighted = YES;
    _flashButton.adjustsImageWhenHighlighted = YES;
    [_topToolView addSubview:btn];
    
    //
    _toggleCameraButton = [self buttonWithNormalImage:@"camera_rotate" highlitedImage:nil target:self actionr:@selector(toggleCamera:)];
    [_topToolView addSubview:_toggleCameraButton];
    
}

- (void) initBottomToolView
{
    _bottomToolView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"camera_top_bar_bg"]];
    _bottomToolView.userInteractionEnabled = YES;
    [self.view addSubview:_bottomToolView];
    
    _captureButton = [self buttonWithNormalImage:@"camera_take_photo" highlitedImage:@"camera_take_photo_highlighted" target:self actionr:@selector(captureStillImage)];
    [_bottomToolView addSubview:_captureButton];
    
    _imagePickerButton = [self buttonWithNormalImage:@"camera_album" highlitedImage:nil target:self actionr:@selector(selectImageFromAlbum)];
    [_bottomToolView addSubview:_imagePickerButton];
    
    _backButton = [self buttonWithNormalImage:@"navbar_back_btn" highlitedImage:nil target:self actionr:@selector(dismissCurrentViewController)];
    [_bottomToolView addSubview:_backButton];
}
- (void) dismissCurrentViewController
{
    if ([_delegate respondsToSelector:@selector(cameraViewControllerDidUserCancel:)]) {
        [_delegate cameraViewControllerDidUserCancel:self];
    }
}
- (void) viewWillLayoutSubviews
{
    float kPSToolViewHeight960 = CGRectGetHeight(self.view.frame) - kPSCameraPreviewHeight;
    float kPSToolViewHeight1136 = (CGRectGetHeight(self.view.frame) - kPSCameraPreviewHeight ) / 2;
    float btnHeight = 44;
    
    float bottomToolHeight = bDEVICE_MACHINE_SCREEN_1136 ? kPSToolViewHeight1136 : kPSToolViewHeight960;
    float cameraPreviewYOffset = bDEVICE_MACHINE_SCREEN_1136 ? (CGRectGetHeight(self.view.frame) - kPSCameraPreviewHeight) / 2 : 0;
    
    _topToolView.frame = CGRectMake(0,
                                    0,
                                    CGRectGetWidth(self.view.bounds),
                                    bottomToolHeight);
    _bottomToolView.frame = CGRectMake(0,
                                       CGRectGetHeight(self.view.bounds) - bottomToolHeight,
                                       CGRectGetWidth(self.view.bounds),
                                       bottomToolHeight);
    if (!bDEVICE_MACHINE_SCREEN_1136) {
        _topToolView.image = nil;
        _topToolView.backgroundColor = [UIColor clearColor];
    }
    
    float topToolBtnYoffset = (CGRectGetHeight(_topToolView.frame) - btnHeight) / 2;
    _flashButton.frame = CGRectMake(10, topToolBtnYoffset, btnHeight, btnHeight);
    _toggleCameraButton.frame = CGRectMake(CGRectGetWidth(_topToolView.frame) - 10 -btnHeight,
                                           topToolBtnYoffset,
                                           btnHeight,
                                           btnHeight);
    
    
    _captureButton.frame = CGRectMake((CGRectGetWidth(_bottomToolView.frame) - 100)/2,
                                      (CGRectGetHeight(_bottomToolView.frame) - 44)/2,
                                      100,
                                      44);
    _captureButton.imageEdgeInsets = UIEdgeInsetsZero;
    float bottomToolBtnYoff = (CGRectGetHeight(_bottomToolView.frame) - btnHeight ) /2;
    _imagePickerButton.frame = CGRectMake(CGRectGetWidth(_bottomToolView.frame) - 10 - btnHeight,
                                          bottomToolBtnYoff ,
                                          btnHeight,
                                          btnHeight);
    _backButton.frame = CGRectMake(10,
                                   bottomToolBtnYoff,
                                   btnHeight,
                                   btnHeight);
    
    _cameraPreviewView.frame = CGRectMake(0,
                                          cameraPreviewYOffset,
                                          CGRectGetWidth(self.view.bounds),
                                          kPSCameraPreviewHeight);
    
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




- (void) configureTopToolView
{
    if (_cameraManager.deviceInput.device.position == AVCaptureDevicePositionBack) {
        _flashButton.hidden = NO;
    }
    else
    {
        _flashButton.hidden = YES;
    }
    _toggleCameraButton.hidden = ![_cameraManager isSupportedToggleDevice];
}

- (void) toggleCamera:(id)sender
{
    
    if ([_cameraManager isSupportedToggleDevice]) {
        [self disableAllUI];
        [self loadDefaultHodlerAnimation];
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSError* error = nil;
            [_cameraManager toggleCameraDevice:&error];
            dispatch_async(dispatch_get_main_queue(), ^{
                [self removeDefaultHolderAnimation];
                [self configureTopToolView];
                [self enableAllUI];
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
    [_cameraPreviewView addObserver:self forKeyPath:kPSObjectKeyFrame options:NSKeyValueObservingOptionNew context:nil];
    [self.view addSubview:_cameraPreviewView];
    _cameraPreviewView.layer.frame = self.view.bounds;
    _cameraPreviewView.backgroundColor = [UIColor blackColor];
    _cameraPreviewView.contentMode = UIViewContentModeScaleAspectFill;
    _cameraPreviewView.userInteractionEnabled = YES;
    _faceView = [[UIImageView alloc] initWithImage:DZCameraCachedImageByName(@"camera_focus")];
    _faceView.frame = CGRectZero;
    [self.view addSubview:_faceView];
    [self initTopToolView];
    [self initBottomToolView];
    [self initPinchGesture];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark 从相册选择图片
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//- (void) puzzlePickerViewControllerDidCancel:(PSPuzzlePickerViewController *)puzzleViewController
//{
//    [puzzleViewController dismissViewControllerAnimated:YES completion:^{
//        
//    }];
//}
//
//- (void) puzzlePickerViewController:(PSPuzzlePickerViewController *)puzzleViewController didSelectImagesWithDictionary:(NSDictionary *)imagesData
//{
//    [puzzleViewController dismissViewControllerAnimated:NO completion:^{
//        NSArray* images = [imagesData.allValues lastObject];
//        if ([_delegate respondsToSelector:@selector(cameraViewController:didGetImageFromAlbum:)]) {
//            if (images.count) {
//                [_delegate cameraViewController:self didGetImageFromAlbum:images[0]];
//            }
//        }
//    }];
//}
//
//- (void) selectImageFromAlbum
//{
//    PSPuzzlePickerViewController* puzzlePickerViewController = [[PSPuzzlePickerViewController alloc] init];
//    puzzlePickerViewController.wantsShowSelectedImage = NO;
//    puzzlePickerViewController.numberOfWantSelected = 1;
//    puzzlePickerViewController.pickerDelegate = self;
//    [self presentModalViewController:puzzlePickerViewController animated:YES];
//}


#pragma mark -
#pragma mark tools
- (void) disableAllUI
{
    [self setUIEnable:NO];
}

- (void) enableAllUI
{
    [self setUIEnable:YES];
}

- (void) setUIEnable:(BOOL)enable
{
    _captureButton.enabled = enable;
    _toggleCameraButton.enabled = enable;
    _backButton.enabled = enable;
    _imagePickerButton.enabled = enable;
    _flashButton.enabled = enable;
}

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
        [self disableAllUI];
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
                [self enableAllUI];
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
