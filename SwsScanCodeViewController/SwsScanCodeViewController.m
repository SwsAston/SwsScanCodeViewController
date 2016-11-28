//
//  SwsScanCodeViewController.m
//
//  Created by sws on 6/6/6.
//  Copyright © 666年 sws. All rights reserved.
//

#import "SwsScanCodeViewController.h"
#import <AVFoundation/AVFoundation.h>

#define Animation_Duration 3.0

@interface SwsScanCodeViewController () <AVCaptureMetadataOutputObjectsDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIView *scanView;
@property (weak, nonatomic) IBOutlet UIImageView *scanLineImageView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *lineImageViewTopToView;
@property (weak, nonatomic) IBOutlet UIImageView *bgImageView;

@property (nonnull,strong)  AVCaptureVideoPreviewLayer * preViewLayer;
@property(nonatomic,strong)AVCaptureSession * session;

@end

@implementation SwsScanCodeViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self initUI];
    
    // 真机
//    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
//        
//        [self scanCode];
//    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [self lineAnimation];
    });
}

#pragma mark - InitUI
- (void)initUI {
    
    self.title = @"二维码/条形码";

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:self action:nil];
    
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    rightBtn.frame = CGRectMake(self.view.bounds.size.width - 40, 0, 40, 30);
    [rightBtn setTitle:@"相册" forState:UIControlStateNormal];
    rightBtn.titleLabel.font = [UIFont systemFontOfSize:15];
    [rightBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [rightBtn addTarget:self action:@selector(chooseImage) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *rightButtonItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
    self.navigationItem.rightBarButtonItem = rightButtonItem;
}

#pragma mark - ChooseImage
- (void)chooseImage {
    
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
        
        [self.session stopRunning];

        UIImagePickerController *pickerController = [[UIImagePickerController alloc] init];
        pickerController.view.backgroundColor = [UIColor clearColor];
        pickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        pickerController.delegate = self;
        pickerController.allowsEditing = YES;  // 必须
        [pickerController setModalTransitionStyle:UIModalTransitionStyleCoverVertical];
        
        [self.navigationController presentViewController:pickerController animated:YES completion:nil];
    } else {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"请打开照片权限" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
}

#pragma mark - UIImagePickerControllerDelegate,UINavigationControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    //获取选中的照片
    UIImage *image = info[UIImagePickerControllerEditedImage];
    
    if (!image) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    //初始化  将类型设置为二维码
    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:nil];

    _bgImageView.image = image;
    
    NSArray*features = [detector featuresInImage:[CIImage imageWithCGImage:image.CGImage]];

    [picker dismissViewControllerAnimated:YES completion:^{
        //设置数组，放置识别完之后的数据
        //2.扫描获取的特征组
                //判断是否有数据（即是否是二维码）
        if (features.count >= 1) {
            //取第一个元素就是二维码所存放的文本信息
            CIQRCodeFeature *feature = features[0];
            NSString *scannedResult = feature.messageString;
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"扫描结果" message:scannedResult preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                [self.session startRunning];
                _bgImageView.image = nil;
            }]];
            [self presentViewController:alert animated:YES completion:nil];

        }else{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"扫描结果" message:@"这不是一个二维码" preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                
                [self.session startRunning];
                _bgImageView.image = nil;

            }]];
            [self presentViewController:alert animated:YES completion:nil];
        }
    }];
}

#pragma mark - 扫描
- (void)scanCode {
    
    NSString *mediaType = AVMediaTypeVideo;
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied){
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:@"请打开相机权限" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }]];
        [self presentViewController:alert animated:YES completion:nil];
        
        return;
    }
    
    AVCaptureDevice * device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    AVCaptureDeviceInput * input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
    AVCaptureMetadataOutput * output = [[AVCaptureMetadataOutput alloc] init];
    output.rectOfInterest = CGRectMake(0,0, [UIScreen mainScreen].bounds.size.width,[UIScreen mainScreen].bounds.size.height);
    [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    
    self.session = [[AVCaptureSession alloc] init];
    [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    [self.session addInput:input];
    [self.session addOutput:output];
    
    output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    if (self.preViewLayer) {
        
        [self.preViewLayer removeFromSuperlayer];
    }
    
    self.preViewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.preViewLayer.videoGravity=AVLayerVideoGravityResizeAspectFill;
    self.preViewLayer.frame=self.view.layer.bounds;
    [self.view.layer insertSublayer:self.preViewLayer atIndex:0];
    
    [self.session startRunning];
    

}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
-(void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    if (metadataObjects.count > 0) {
        
        AVMetadataMachineReadableCodeObject * metadataObject = [metadataObjects objectAtIndex : 0 ];
        NSString *stringCode = metadataObject.stringValue;
        
        [self.session stopRunning];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"扫描结果" message:stringCode preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            [self.session startRunning];
        }]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

#pragma mark - Animation
- (void)lineAnimation {
    
    CABasicAnimation *animation = [CABasicAnimation animation];
    animation.keyPath =@"transform.translation.y";
    animation.byValue = @(_scanView.bounds.size.width - 5);
    animation.removedOnCompletion = NO;
    animation.duration = Animation_Duration;
    animation.repeatCount = MAXFLOAT;
    
    [_scanLineImageView.layer addAnimation:animation forKey:nil];
}


@end
