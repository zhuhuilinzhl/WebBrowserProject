//
//  ViewController.m
//  WEBBrowserProject
//
//  Created by 朱 on 2017/3/2.
//  Copyright © 2017年 朱会林. All rights reserved.
//

#import "ViewController.h"
#import "KINWebBrowserViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
}

- (IBAction)clickBtnAction:(id)sender {
    KINWebBrowserViewController *linkVC = [KINWebBrowserViewController webBrowser];
    //http://www.baidu.com  @"http://hy.hzgh.org/"
    linkVC.urlString = @"http://www.baidu.com";
   // [linkVC setDelegate:self];
    // 设为No才可以设置title
    linkVC.showsPageTitleInNavigationBar = NO;
    // 设置导航栏的title
    linkVC.title = @"标题";
    // 隐藏toolBar右边的功能按钮
    linkVC.actionButtonHidden = YES;
    // 设置导航栏图片字体颜色－progressView《进度条》
    linkVC.tintColor = [UIColor redColor];
    
    [self.navigationController pushViewController:linkVC animated:YES];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
