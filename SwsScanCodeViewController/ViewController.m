//
//  ViewController.m
//
//  Created by sws on 6/6/6.
//  Copyright © 666年 sws. All rights reserved.
//

#import "ViewController.h"
#import "SwsScanCodeViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    
    [super viewDidLoad];
    UIImage *image = [UIImage imageNamed:@"1480316050.png"];
    UIImageWriteToSavedPhotosAlbum(image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
}

- (void)image: (UIImage *) image didFinishSavingWithError: (NSError *) error contextInfo: (void *) contextInfo {
    NSString *msg = nil ;
    if(error != NULL){
        
        msg = @"保存图片失败" ;
    }else{
        
        msg = @"保存图片成功" ;
    }
    NSLog(@"%@",msg);
}

- (IBAction)scan:(UIButton *)sender {
    
    SwsScanCodeViewController *vc = [[SwsScanCodeViewController alloc] init];
    [self.navigationController pushViewController:vc animated:YES];
}

@end
