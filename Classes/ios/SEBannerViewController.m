//
//  SEBannerViewController.m
//  SEBannerViewController
//
//  Created by Samuel E. Giddins on 07.02.13.
//  Copyright (c) 2013 Slader. All rights reserved.
//

#import "SEBannerViewController.h"
#ifdef COCOAPODS_POD_AVAILABLE_AdMob
#import <AdMob/GADBannerView.h>
#endif

NSString *SEBannerViewActionDidFinishNotification = @"SEBannerViewActionDidFinishNotification";
NSString *SEBannerViewActionWillBeginNotification = @"SEBannerViewActionWillBeginNotification";

@interface SEBannerViewController () <ADBannerViewDelegate>

@property (nonatomic, retain) UIView *bannerView;

@property (nonatomic, retain) UIViewController *contentController;

@property (nonatomic, assign, getter=isGADLoaded) BOOL GADLoaded;

@end

@implementation SEBannerViewController

+ (instancetype)bannerViewControllerWithContentViewController:(UIViewController *)contentViewController adNetwork:(SEAdNetworkType)adNetwork
{
    return [[self alloc] initWithContentViewController:contentViewController adNetwork:adNetwork];
}

- (instancetype)initWithContentViewController:(UIViewController *)contentController adNetwork:(SEAdNetworkType)adNetwork
{
    self = [super init];
    if (self) {
        _contentController = contentController;
        _adNetwork = adNetwork;
    }
    return self;
}

- (void)loadView {
    UIView *contentView = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self addChildViewController:_contentController];
    [contentView addSubview:_contentController.view];
    [_contentController didMoveToParentViewController:self];
    self.view = contentView;
}

- (void)showBanner
{
    if (!_bannerView) {
        switch (self.adNetwork) {
            case SEAdNetworkiAd: {
                if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
                    _bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
                }
                else {
                    _bannerView = [[ADBannerView alloc] init];
                }
                [(ADBannerView *)_bannerView setDelegate : self];
                break;
            }
           case SEAdNetworkAdMob: {
#ifdef COCOAPODS_POD_AVAILABLE_AdMob
               _bannerView = [[GADBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
               [(GADBannerView *)_bannerView setAdUnitID:self.adMobPublisherID];
               [(GADBannerView *)_bannerView setRootViewController:self];
               GADRequest *request = [GADRequest request];
               request.keywords = self.adKeywords;
               [(GADBannerView *)_bannerView setDelegate:self];
               [(GADBannerView *)_bannerView loadRequest:request];
#endif
               break;
           }
        }
    }
    [self.view addSubview:_bannerView];
    [self.view setNeedsLayout];
}

- (void)deleteBanner
{
    if (_bannerView) {
        [(id)_bannerView setDelegate : nil];
        [_bannerView removeFromSuperview];
        _bannerView = nil;
    }
}

- (void)hideBanner
{
    [_bannerView removeFromSuperview];
    [self.view setNeedsLayout];
    [self.view layoutIfNeeded];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return [_contentController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}
#endif

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return [_contentController preferredInterfaceOrientationForPresentation];
}

- (NSUInteger)supportedInterfaceOrientations {
    return [_contentController supportedInterfaceOrientations];
}

- (void)viewDidLayoutSubviews {
    CGRect contentFrame = self.view.bounds, bannerFrame = CGRectZero;

    if (!_bannerView || self.view != _bannerView.superview) {
        _contentController.view.frame = contentFrame;
        return;
    }
#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
    // If configured to support iOS <6.0, then we need to set the currentContentSizeIdentifier in order to resize the banner properly.
    // This continues to work on iOS 6.0, so we won't need to do anything further to resize the banner.
    if (contentFrame.size.width < contentFrame.size.height) {
        switch (self.adNetwork) {
            case SEAdNetworkAdMob: {
#ifdef COCOAPODS_POD_AVAILABLE_AdMob
                ((GADBannerView *)_bannerView).adSize = kGADAdSizeSmartBannerPortrait;
#endif
                break;
            }
            case SEAdNetworkiAd: {
                ((ADBannerView *)_bannerView).currentContentSizeIdentifier = ADBannerContentSizeIdentifierPortrait;
                break;
            }
        }
    }
    else {
        switch (self.adNetwork) {
            case SEAdNetworkAdMob: {
#ifdef COCOAPODS_POD_AVAILABLE_AdMob
                ((GADBannerView *)_bannerView).adSize = kGADAdSizeSmartBannerLandscape;
#endif
                break;
            }
            case SEAdNetworkiAd: {
                ((ADBannerView *)_bannerView).currentContentSizeIdentifier = ADBannerContentSizeIdentifierLandscape;
                break;
            }
        }
    }
    bannerFrame = _bannerView.frame;
#else
    // If configured to support iOS >= 6.0 only, then we want to avoid currentContentSizeIdentifier as it is deprecated.
    // Fortunately all we need to do is ask the banner for a size that fits into the layout area we are using.
    // At this point in this method contentFrame=self.view.bounds, so we'll use that size for the layout.
    bannerFrame.size = [_bannerView sizeThatFits:contentFrame.size];
#endif

    if ((self.adNetwork == SEAdNetworkiAd && ((ADBannerView *)_bannerView).bannerLoaded)) {
        contentFrame.size.height -= bannerFrame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
    }
    else {
        bannerFrame.origin.y = contentFrame.size.height;
    }

    _contentController.view.frame = contentFrame;
    _bannerView.frame = bannerFrame;
}

#pragma mark - ADBannerView Delegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner {
    [self didRecieveAd];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error {
    [self failureWithError:error];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave {
    [self adWillShow];
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner {
    [self adDidFinish];
}

#pragma mark - GADBannerView Delegate

#ifdef COCOAPODS_POD_AVAILABLE_AdMob

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error {
    _GADLoaded = NO;
    [self failureWithError:error];
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView {
    [self adDidFinish];
}

- (void)adViewDidReceiveAd:(GADBannerView *)view {
    _GADLoaded = YES;
    [self didRecieveAd];
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView {

}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
    [self adDidFinish];
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView {
    [self adWillShow];
}

#endif

#pragma mark - Generic Delegate

- (void)failureWithError:(NSError *)error {
    NSLog(@">>> Error loading ad: %@", error);
    [UIView animateWithDuration:0.25 animations: ^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}

- (void)didRecieveAd {
    [UIView animateWithDuration:0.25 animations: ^{
        [self.view setNeedsLayout];
        [self.view layoutIfNeeded];
    }];
}

- (void)adDidFinish {
    [[NSNotificationCenter defaultCenter] postNotificationName:SEBannerViewActionDidFinishNotification object:self.bannerView];
}

- (void)adWillShow {
    [[NSNotificationCenter defaultCenter] postNotificationName:SEBannerViewActionWillBeginNotification object:self.bannerView];
    if (self.adWillShowBlock) self.adWillShowBlock(self, self.bannerView);
}

- (void)dealloc {
    [(id)_bannerView setDelegate : nil];
}

@end

@implementation UIViewController (SEBannerViewController)

- (SEBannerViewController *)bannerViewController
{
    id next = self;
    do {
        if ([next isKindOfClass:[SEBannerViewController class]])
            return next;
    } while ((next = [next parentViewController]));
    return nil;
}

@end
