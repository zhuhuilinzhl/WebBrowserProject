//
//  KINWebBrowserViewController.h
//  YunNanTong
//
//  Created by 唐海洋 on 16/8/9.
//  Copyright © 2016年 唐海洋. All rights reserved.
//

//#import "BasePageViewController.h"
#import <WebKit/WebKit.h>

@class KINWebBrowserViewController;

/*
 
 UINavigationController+KINWebBrowserWrapper category enables access to casted KINWebBroswerViewController when set as rootViewController of UINavigationController
 
 */
@interface UINavigationController(KINWebBrowser)

// Returns rootViewController casted as KINWebBrowserViewController
- (KINWebBrowserViewController *)rootWebBrowser;

@end

@protocol KINWebBrowserDelegate <NSObject>

@optional
- (void)webBrowser:(KINWebBrowserViewController *)webBrowser didStartLoadingURL:(NSURL *)URL;
- (void)webBrowser:(KINWebBrowserViewController *)webBrowser didFinishLoadingURL:(NSURL *)URL;
- (void)webBrowser:(KINWebBrowserViewController *)webBrowser didFailToLoadURL:(NSURL *)URL error:(NSError *)error;
- (void)webBrowserViewControllerWillDismiss:(KINWebBrowserViewController*)viewController;

@end

@interface KINWebBrowserViewController : UIViewController <WKNavigationDelegate, WKUIDelegate, UIWebViewDelegate>

////////－－－－ 自定义－－－－－－／／／／／
@property (nonatomic, copy)NSString *urlString;
//@property (nonatomic,strong)newsListObjectModel *newsListObject;
//@property (nonatomic, assign)BOOL LoginVCBOOL;

#pragma mark - Public Properties

@property (nonatomic, weak) id <KINWebBrowserDelegate> delegate;

// The main and only UIProgressView
@property (nonatomic, strong) UIProgressView *progressView;

// The web views
// Depending on the version of iOS, one of these will be set
@property (nonatomic, strong) WKWebView *wkWebView;

- (id)initWithConfiguration:(WKWebViewConfiguration *)configuration NS_AVAILABLE_IOS(8_0);

#pragma mark - Static Initializers

/*
 Initialize a basic KINWebBrowserViewController instance for push onto navigation stack
 
 Ideal for use with UINavigationController pushViewController:animated: or initWithRootViewController:
 
 Optionally specify KINWebBrowser options or WKWebConfiguration
 */

+ (KINWebBrowserViewController *)webBrowser;
+ (KINWebBrowserViewController *)webBrowserWithConfiguration:(WKWebViewConfiguration *)configuration NS_AVAILABLE_IOS(8_0);

/*
 Initialize a UINavigationController with a KINWebBrowserViewController for modal presentation.
 
 Ideal for use with presentViewController:animated:
 
 Optionally specify KINWebBrowser options or WKWebConfiguration
 */

+ (UINavigationController *)navigationControllerWithWebBrowser;

+ (UINavigationController *)navigationControllerWithWebBrowserWithConfiguration:(WKWebViewConfiguration *)configuration NS_AVAILABLE_IOS(8_0);


@property (nonatomic, strong) UIBarButtonItem *actionButton;
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIColor *toolBarTintColor;
@property (nonatomic, strong) UIColor *barTintColor;
@property (nonatomic, assign) BOOL actionButtonHidden;
@property (nonatomic, assign) BOOL showsURLInNavigationBar;
@property (nonatomic, assign) BOOL showsPageTitleInNavigationBar;

//Allow for custom activities in the browser by populating this optional array
@property (nonatomic, strong) NSArray *customActivityItems;

@end
