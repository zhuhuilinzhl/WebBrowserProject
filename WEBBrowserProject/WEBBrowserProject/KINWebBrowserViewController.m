//
//  KINWebBrowserViewController.m
//  YunNanTong
//
//  Created by 唐海洋 on 16/8/9.
//  Copyright © 2016年 唐海洋. All rights reserved.
//

#import "KINWebBrowserViewController.h"
//#import "TUSafariActivity.h"//这两个头文件暂时用不到
//#import "ARChromeActivity.h"

static void *KINWebBrowserContext = &KINWebBrowserContext;

@interface KINWebBrowserViewController ()<UIAlertViewDelegate,WKScriptMessageHandler>

@property (nonatomic, assign) BOOL previousNavigationControllerToolbarHidden, previousNavigationControllerNavigationBarHidden;
@property (nonatomic, strong) UIBarButtonItem *backButton, *forwardButton, *refreshButton, *stopButton, *fixedSeparator, *flexibleSeparator;
@property (nonatomic, strong) NSTimer *fakeProgressTimer;
@property (nonatomic, strong) UIPopoverController *actionPopoverController;
@property (nonatomic, assign) BOOL uiWebViewIsLoading;
@property (nonatomic, strong) NSURL *uiWebViewCurrentURL;
@property (nonatomic, strong) NSURL *URLToLaunchWithPermission;
@property (nonatomic, strong) UIAlertView *externalAppPermissionAlertView;

//@property (nonatomic, strong)NetWorkingManager *request;

@end

@implementation KINWebBrowserViewController


#pragma mark - Static Initializers
+ (KINWebBrowserViewController *)webBrowser {
    KINWebBrowserViewController *webBrowserViewController = [KINWebBrowserViewController webBrowserWithConfiguration:nil];
    return webBrowserViewController;
}

+ (KINWebBrowserViewController *)webBrowserWithConfiguration:(WKWebViewConfiguration *)configuration {
    KINWebBrowserViewController *webBrowserViewController = [[self alloc] initWithConfiguration:configuration];
    return webBrowserViewController;
}

+ (UINavigationController *)navigationControllerWithWebBrowser {
    KINWebBrowserViewController *webBrowserViewController = [[self alloc] initWithConfiguration:nil];
    return [KINWebBrowserViewController navigationControllerWithBrowser:webBrowserViewController];
}

+ (UINavigationController *)navigationControllerWithWebBrowserWithConfiguration:(WKWebViewConfiguration *)configuration {
    KINWebBrowserViewController *webBrowserViewController = [[self alloc] initWithConfiguration:configuration];
    return [KINWebBrowserViewController navigationControllerWithBrowser:webBrowserViewController];
}

+ (UINavigationController *)navigationControllerWithBrowser:(KINWebBrowserViewController *)webBrowser {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:webBrowser action:@selector(doneButtonPressed:)];
    [webBrowser.navigationItem setRightBarButtonItem:doneButton];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webBrowser];
    return navigationController;
}


#pragma mark - Initializers
- (id)init {
    return [self initWithConfiguration:nil];
}

- (id)initWithConfiguration:(WKWebViewConfiguration *)configuration {
    self = [super init];
    if(self) {
        if([WKWebView class]) {
            if(configuration) {
                self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
            }
            else {
                self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero];
            }
        }
        
        self.actionButtonHidden = NO;
        self.showsURLInNavigationBar = NO;
        self.showsPageTitleInNavigationBar = YES;
        
        self.externalAppPermissionAlertView = [[UIAlertView alloc] initWithTitle:@"Leave this app?" message:@"This web page is trying to open an outside app. Are you sure you want to open it?" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Open App", nil];
        
    }
    return self;
}

#pragma mark - View Lifecycle
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.previousNavigationControllerToolbarHidden = self.navigationController.toolbarHidden;
    self.previousNavigationControllerNavigationBarHidden = self.navigationController.navigationBarHidden;
    
    if(self.wkWebView) {
        __weak typeof(self) weakSelf = self;
        [self.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
            //__strong typeof(weakSelf) strongSelf = weakSelf;
            
            NSLog(@"old agent ----- :%@", result);
            NSString *userAgent = result;
            if ([userAgent hasSuffix:@"xyApp"]) {
               //
            }
            else{
                NSString *newUserAgent = [userAgent stringByAppendingString:@" xyApp"];
                NSDictionary *dictionary = [NSDictionary dictionaryWithObjectsAndKeys:newUserAgent, @"UserAgent", nil];
                [[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
            }
            
             dispatch_async(dispatch_get_main_queue(), ^{
                   [weakSelf customWkwebView];
                 
             });
        }];

    }
    
    // 进度条
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [self.progressView setTrackTintColor:[UIColor colorWithWhite:1.0f alpha:0.0f]];
    [self.progressView setFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height-self.progressView.frame.size.height, self.view.frame.size.width, self.progressView.frame.size.height)];
    [self.progressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
}

-(void)customWkwebView
{
    //
    WKWebViewConfiguration *configuretionCustom = [[WKWebViewConfiguration alloc] init];
    configuretionCustom.preferences = [[WKPreferences alloc]init];
    configuretionCustom.preferences.minimumFontSize = 10;
    configuretionCustom.preferences.javaScriptEnabled = true;
    configuretionCustom.processPool = [[WKProcessPool alloc]init];
    // 通过js与webview内容交互配置
    configuretionCustom.userContentController = [[WKUserContentController alloc] init];
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    //OC注册供JS调用的方法
    [configuretionCustom.userContentController addScriptMessageHandler:self name:@"nativeLogin"];
    // 默认是不能通过JS自动打开窗口的，必须通过用户交互才能打开
    configuretionCustom.preferences.javaScriptCanOpenWindowsAutomatically = YES;
    // 注意这里很重要
    self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 64, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height-64) configuration:configuretionCustom];
    [self.wkWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
    [self.wkWebView setNavigationDelegate:self];
    [self.wkWebView setUIDelegate:self];
    [self.wkWebView setMultipleTouchEnabled:YES];
    [self.wkWebView setAutoresizesSubviews:YES];
    [self.wkWebView.scrollView setAlwaysBounceVertical:YES];
    [self.view addSubview:self.wkWebView];
    
    [self.wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:KINWebBrowserContext];
    
    
    // After this point the web view will use a custom appended user agent
    //            [strongSelf.wkWebView evaluateJavaScript:@"navigator.userAgent" completionHandler:^(id result, NSError *error) {
    //                DLog(@"new agent -------- :%@", result);
    //            }];
    
//        NSString *urlStrigone = [NSString stringWithFormat:@"%@",self.newsListObject.LinkUrl];
//        NSString *urlStrigtwo = [urlStrigone stringByReplacingOccurrencesOfString:@" " withString:@""];
//        NSString *urlStrigthree = [urlStrigtwo stringByReplacingOccurrencesOfString:@" " withString:@""];
        [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];

}
-(void)initData
{
    //self.request = [[NetWorkingManager alloc]init];
}

#pragma mark --
-(void)setSubView
{
//    if (self.LoginVCBOOL) {
//      //  个人中心过来的
//    self.LoginVCBOOL = NO;
//    }
//    else{
//       [self setBarRightWithImageName:@"webShare.png" selector:@selector(navRightBtnTapped:)];
//    }
    
    
}

//-(void)navRightBtnTapped:(id)sender
//{
//    
//    [self shareTapped];
//}
//
//#pragma mark -- 分享
//-(void)shareTapped
//{
//    ShareManager *shareMgr = [ShareManager shareManager];
//    ShareInfo *shareInfo = [[ShareInfo alloc]init];
//    shareInfo.thumbnail = _newsListObject.ImgUrl; // 图片
//    shareInfo.title = _newsListObject.Title; // title
//    shareInfo.url = _newsListObject.LinkUrl; //
//    shareInfo.subTitle = _newsListObject.Meno; // 描述
//    shareInfo.type = ShareTypeImageText;
//    
//    [shareMgr shareInfo:shareInfo controller:self finish:^(BOOL ret, id obj) {
//        if (ret) {
//            // 分享完成调接口
//            [self.request appShareRequestWithContentId:self.newsListObject.Id Channel:[obj integerValue] success:^(id responseObject)  {
//                // 分享请求成功
//                [self.view hideCustomIndicator];
//                [self.view makeToast:@"分享完成"];
//                
//            } failure:^(NSError *error) {
//                // 分享请求失败、无法给出提示语
//                
//                [self.view hideCustomIndicator];
//                
//            }];
//            
//        }
//        else {
//            [self.view makeToast:@"分享失败！"];
//        }
//        
//    }];
//    
//}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //[self setBarthemeColor];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    [self.navigationController setToolbarHidden:NO animated:YES];
    // 添加进度条
    [self.navigationController.navigationBar addSubview:self.progressView];
    //
    [self updateToolbarState];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:self.previousNavigationControllerNavigationBarHidden animated:animated];
    [self.navigationController setToolbarHidden:self.previousNavigationControllerToolbarHidden animated:animated];
    [self.progressView removeFromSuperview];
}

#pragma mark - WKNavigationDelegate
#pragma mark ---- 11111111类似 UIWebView 的 -webView: shouldStartLoadWithRequest: navigationType:
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if(webView == self.wkWebView) {
        
        NSURL *URL = navigationAction.request.URL;
        if(![self externalAppRequiredToOpenURL:URL]) {
            if(!navigationAction.targetFrame) {
                [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@",URL]]]];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        else if([[UIApplication sharedApplication] canOpenURL:URL]) {
            [self launchExternalAppWithURL:URL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark ---- 222222开始加载WKWebView时调用的方法、类似UIWebView的 -webViewDidStartLoad:
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if(webView == self.wkWebView) {
        [self updateToolbarState];
        if([self.delegate respondsToSelector:@selector(webBrowser:didStartLoadingURL:)]) {
            [self.delegate webBrowser:self didStartLoadingURL:self.wkWebView.URL];
        }
    }
}

#pragma mark -- 555555结束加载WKWebView时调用的方法类似 UIWebView 的 －webViewDidFinishLoad:
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if(webView == self.wkWebView) {
        [self updateToolbarState];
        if([self.delegate respondsToSelector:@selector(webBrowser:didFinishLoadingURL:)]) {
            [self.delegate webBrowser:self didFinishLoadingURL:self.wkWebView.URL];
        }
    }
    // 传参数
//    NSString *getClientMsgString = [NSString stringWithFormat:@"%@",[self getAppIdProjectIdAppKeyClientIdToken]];
//    
//    [self.wkWebView evaluateJavaScript:[NSString stringWithFormat:@"getClientMsg('%@')",getClientMsgString] completionHandler:^(id _Nullable response, NSError * _Nullable error) {
//        //DLog(@"传参数 ---- response: %@ error: %@", response, error);
//    }];
    
    
}

#pragma mark --加载WKWebView失败时调用的方法、类似 UIWebView 的- webView:didFailLoadWithError:
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(webView == self.wkWebView) {
        [self updateToolbarState];
        if([self.delegate respondsToSelector:@selector(webBrowser:didFailToLoadURL:error:)]) {
            [self.delegate webBrowser:self didFailToLoadURL:self.wkWebView.URL error:error];
        }
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(webView == self.wkWebView) {
        [self updateToolbarState];
        if([self.delegate respondsToSelector:@selector(webBrowser:didFailToLoadURL:error:)]) {
            [self.delegate webBrowser:self didFailToLoadURL:self.wkWebView.URL error:error];
        }
    }
}


#pragma mark - WKScriptMessageHandler
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    // 方法名
    NSString *methods = [NSString stringWithFormat:@"%@:", message.name];
    //DLog(@"方法名-----%@",methods);
    if ([message.name isEqualToString:@"nativeLogin"]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(CustomrefreshWeb) name:@"refreshWeb" object:nil];
//            userLoginRatViewController *loginVC = [[userLoginRatViewController alloc]init];
//            loginVC.pointsBOOL = YES;
//            loginVC.hidesBottomBarWhenPushed = YES;
//            [self.navigationController pushViewController:loginVC animated:YES];

        });
    }
}

#pragma mark -- 通知刷新界面
-(void)CustomrefreshWeb
{
//    NSString *urlStrigone = [NSString stringWithFormat:@"%@",self.newsListObject.LinkUrl];
//    NSString *urlStrigtwo = [urlStrigone stringByReplacingOccurrencesOfString:@" " withString:@""];
//    NSString *urlStrigthree = [urlStrigtwo stringByReplacingOccurrencesOfString:@" " withString:@""];
    [self.wkWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
}

// ** js－－Confirm框弹出要调用 */
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL result))completionHandler{
//    DLog(@"Confirm框弹出要调用---%@",message);
//    [UIAlertConfirm confirmWithTitle:message cancel:@"取消" confirm:@"确认" finish:^(BOOL ret, id obj) {
//        //
//        userLoginRatViewController *loginVC = [[userLoginRatViewController alloc]init];
//        loginVC.hidesBottomBarWhenPushed = YES;
//        loginVC.typeVC = YES;
//        [self.navigationController pushViewController:loginVC animated:YES];
//        
//    }];
//    completionHandler(1);
}

#pragma mark - WKUIDelegate  没有尺寸
- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

#pragma mark -- 获取appId、projectId、appKey、clientId、token
//-(NSString *)getAppIdProjectIdAppKeyClientIdToken
//{
//    NSString *token = [NSString stringWithFormat:@"%@",[[NSUserDefaults standardUserDefaults] objectForKey:TOKEN]];
//    //
//    NSInteger appId = [[[NSUserDefaults standardUserDefaults] objectForKey:@"appId"] integerValue];
//    NSString *appKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"appKey"];
//    //
//    NSString *MsgSting = [NSString stringWithFormat:@"%@,%ld,%d,%@,%@",token,(long)appId,Projectid,appKey,[GeTuiSdk clientId]];
//    
//    return MsgSting;
//    
//}

#pragma mark - Public Interface

// 设置导航栏图片字体颜色－progressView《进度条》
- (void)setTintColor:(UIColor *)tintColor {
    _tintColor = tintColor;
    [self.progressView setTintColor:tintColor];
    [self.navigationController.navigationBar setTintColor:tintColor];
    
}
// 设置toolBar图片字体颜色
-(void)setToolBarTintColor:(UIColor *)toolBarTintColor
{
    [self.navigationController.toolbar setTintColor:toolBarTintColor];
}

// 设置背景颜色
- (void)setBarTintColor:(UIColor *)barTintColor {
    _barTintColor = barTintColor;
    [self.navigationController.navigationBar setBarTintColor:barTintColor];
    [self.navigationController.toolbar setBarTintColor:barTintColor];
}

- (void)setActionButtonHidden:(BOOL)actionButtonHidden {
    _actionButtonHidden = actionButtonHidden;
    [self updateToolbarState];
}

#pragma mark - Toolbar State 底部的toolBar
- (void)updateToolbarState {
    
    BOOL canGoBack = self.wkWebView.canGoBack;
    BOOL canGoForward = self.wkWebView.canGoForward;
    
    [self.backButton setEnabled:canGoBack];
    [self.forwardButton setEnabled:canGoForward];
    
    if(!self.backButton) {
        [self setupToolbarItems];
    }
    
    NSArray *barButtonItems;
    if(self.wkWebView.loading || self.uiWebViewIsLoading) {
        barButtonItems = @[self.backButton, self.fixedSeparator, self.forwardButton, self.fixedSeparator, self.stopButton, self.flexibleSeparator];
        
        if(self.showsURLInNavigationBar) {
            NSString *URLString;
            if(self.wkWebView) {
                URLString = [self.wkWebView.URL absoluteString];
            }
        
            
            URLString = [URLString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
            URLString = [URLString stringByReplacingOccurrencesOfString:@"https://" withString:@""];
            URLString = [URLString substringToIndex:[URLString length]-1];
            self.navigationItem.title = URLString;
        }
    }
    else {
        barButtonItems = @[self.backButton, self.fixedSeparator, self.forwardButton, self.fixedSeparator, self.refreshButton, self.flexibleSeparator];
        
        if(self.showsPageTitleInNavigationBar) {
            if(self.wkWebView) {
                self.navigationItem.title = self.wkWebView.title;
            }
            
        }
    }
    
    if(!self.actionButtonHidden) {
        // 隐藏toolBar右边的功能按钮
        NSMutableArray *mutableBarButtonItems = [NSMutableArray arrayWithArray:barButtonItems];
        [mutableBarButtonItems addObject:self.actionButton];
        barButtonItems = [NSArray arrayWithArray:mutableBarButtonItems];
    }
    
    [self setToolbarItems:barButtonItems animated:YES];
    self.tintColor = self.tintColor;
    self.barTintColor = self.barTintColor;

}
#pragma mark -- 设置底部toolBar的Items
- (void)setupToolbarItems {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    
    self.refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshButtonPressed:)];
    self.stopButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop target:self action:@selector(stopButtonPressed:)];
    
    UIImage *backbuttonImage = [UIImage imageWithContentsOfFile: [bundle pathForResource:@"backbutton" ofType:@"png"]];
    self.backButton = [[UIBarButtonItem alloc] initWithImage:backbuttonImage style:UIBarButtonItemStylePlain target:self action:@selector(backButtonPressed:)];
    
    UIImage *forwardbuttonImage = [UIImage imageWithContentsOfFile: [bundle pathForResource:@"forwardbutton" ofType:@"png"]];
    self.forwardButton = [[UIBarButtonItem alloc] initWithImage:forwardbuttonImage style:UIBarButtonItemStylePlain target:self action:@selector(forwardButtonPressed:)];
    self.actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(actionButtonPressed:)];
    self.fixedSeparator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    self.fixedSeparator.width = 50.0f;
    self.flexibleSeparator = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
}

#pragma mark - Done Button Action
- (void)doneButtonPressed:(id)sender {
    [self dismissAnimated:YES];
}
#pragma mark - UIBarButtonItem Target Action Methods
//
- (void)backButtonPressed:(id)sender {
    
    if(self.wkWebView) {
        [self.wkWebView goBack];
    }
   
    [self updateToolbarState];
}
//
- (void)forwardButtonPressed:(id)sender {
    if(self.wkWebView) {
        [self.wkWebView goForward];
    }
   
    [self updateToolbarState];
}

- (void)refreshButtonPressed:(id)sender {
    if(self.wkWebView) {
        [self.wkWebView stopLoading];
        [self.wkWebView reload];
    }
    
}

- (void)stopButtonPressed:(id)sender {
    if(self.wkWebView) {
        [self.wkWebView stopLoading];
    }
    
}

#pragma mark -- 这个好像是我们不会用到的那个功能按钮的点击事件
- (void)actionButtonPressed:(id)sender {
    NSURL *URLForActivityItem;
    NSString *URLTitle;
    if(self.wkWebView) {
        URLForActivityItem = self.wkWebView.URL;
        URLTitle = self.wkWebView.title;
    }
    if (URLForActivityItem) {
        dispatch_async(dispatch_get_main_queue(), ^{
//            TUSafariActivity *safariActivity = [[TUSafariActivity alloc] init];
//            ARChromeActivity *chromeActivity = [[ARChromeActivity alloc] init];
//            
//            NSMutableArray *activities = [[NSMutableArray alloc] init];
//            [activities addObject:safariActivity];
//            [activities addObject:chromeActivity];
//            if(self.customActivityItems != nil) {
//                [activities addObjectsFromArray:self.customActivityItems];
//            }
//            
//            UIActivityViewController *controller = [[UIActivityViewController alloc] initWithActivityItems:@[URLForActivityItem] applicationActivities:activities];
            
            if([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                if(self.actionPopoverController) {
                    [self.actionPopoverController dismissPopoverAnimated:YES];
                }
                //self.actionPopoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
                [self.actionPopoverController presentPopoverFromBarButtonItem:self.actionButton permittedArrowDirections: UIPopoverArrowDirectionAny animated:YES];
            }
            else {
                //[self presentViewController:controller animated:YES completion:NULL];
            }
        });
    }
}


#pragma mark - Estimated Progress KVO (WKWebView)
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView) {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        
        // Once complete, fade out UIProgressView
        if(self.wkWebView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - External App Support
- (BOOL)externalAppRequiredToOpenURL:(NSURL *)URL {
    NSSet *validSchemes = [NSSet setWithArray:@[@"http", @"https"]];
    return ![validSchemes containsObject:URL.scheme];
}

- (void)launchExternalAppWithURL:(NSURL *)URL {
    self.URLToLaunchWithPermission = URL;
    if (![self.externalAppPermissionAlertView isVisible]) {
        [self.externalAppPermissionAlertView show];
    }
    
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView == self.externalAppPermissionAlertView) {
        if(buttonIndex != alertView.cancelButtonIndex) {
            [[UIApplication sharedApplication] openURL:self.URLToLaunchWithPermission];
        }
        self.URLToLaunchWithPermission = nil;
    }
}

#pragma mark - Dismiss
- (void)dismissAnimated:(BOOL)animated {
    if([self.delegate respondsToSelector:@selector(webBrowserViewControllerWillDismiss:)]) {
        [self.delegate webBrowserViewControllerWillDismiss:self];
    }
    [self.navigationController dismissViewControllerAnimated:animated completion:nil];
}

#pragma mark - Interface Orientation
- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}
- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Dealloc
- (void)dealloc {
    
    [self.wkWebView setNavigationDelegate:nil];
    [self.wkWebView setUIDelegate:nil];
    if ([self isViewLoaded]) {
        [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    }
    
}

@end

@implementation UINavigationController(KINWebBrowser)

- (KINWebBrowserViewController *)rootWebBrowser {
    UIViewController *rootViewController = [self.viewControllers objectAtIndex:0];
    return (KINWebBrowserViewController *)rootViewController;
}


@end
