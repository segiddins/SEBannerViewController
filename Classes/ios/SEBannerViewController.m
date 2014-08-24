//
//  SEBannerViewController.m
//  SEBannerViewController
//
//  Created by Samuel E. Giddins on 07.02.13.
//  Copyright (c) 2013 Slader. All rights reserved.
//

#import "SEBannerViewController.h"

#ifdef COCOAPODS_POD_AVAILABLE_AdMob
#define AdMobAvailable
#define GADBannerViewAvailable
#import <AdMob/GADBannerView.h>
#endif

#ifdef COCOAPODS_POD_AVAILABLE_Google_Mobile_Ads_SDK
#define DFPAvailable
#define AdMobAvailable
#define GADBannerViewAvailable
#import <Google-Mobile-Ads-SDK/DFPBannerView.h>
@import CoreLocation;
#endif

NSString *SEBannerViewActionDidFinishNotification = @"SEBannerViewActionDidFinishNotification";
NSString *SEBannerViewActionWillBeginNotification = @"SEBannerViewActionWillBeginNotification";

NSString *SEStringFromAdNetworkType(SEAdNetworkType adNetworkType)
{
    switch (adNetworkType) {
    case SEAdNetworkiAd:
        return @"iAd";
    case SEAdNetworkAdMob:
        return @"AdMob";
    case SEAdNetworkGoogleDFP:
        return @"DFP";
    }
}

@interface SEBannerViewController () <ADBannerViewDelegate>

@property (nonatomic) UIView *bannerView;

#ifdef DFPAvailable

@property (nonatomic) DFPBannerView *DFPBannerView;

@property (nonatomic) CLLocationManager *locationManager;

#endif

@property (nonatomic) UIViewController *contentController;

@property (nonatomic, getter=isGADLoaded) BOOL GADLoaded;

@property (nonatomic, getter=isAdHidden) BOOL adHidden;

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
        _enabled = YES;

#ifdef DFPAvailable
        _locationManager = [[CLLocationManager alloc] init];
#endif
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self addChildViewController:self.contentController];
    [self.view addSubview:self.contentController.view];
    [self.contentController didMoveToParentViewController:self];
    [self.view layoutIfNeeded];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
#ifdef DFPAvailable
    [self.locationManager stopMonitoringSignificantLocationChanges];
#endif
}

- (void)setEnabled:(BOOL)enabled
{
    if (_enabled == enabled) {
        return;
    }

    _enabled = enabled;
    if (!enabled) {
        [self deleteBanner];
#ifdef DFPAvailable
        [self.locationManager stopMonitoringSignificantLocationChanges];
#endif
    }
}

- (void)showBanner
{
    self.adHidden = NO;
    if (!_bannerView && self.isEnabled) {
        switch (self.adNetwork) {
        case SEAdNetworkiAd: {
            if ([ADBannerView instancesRespondToSelector:@selector(initWithAdType:)]) {
                _bannerView = [[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
            } else {
                _bannerView = [[ADBannerView alloc] init];
            }
            [(ADBannerView *)_bannerView setDelegate:self];
            break;
        }
        case SEAdNetworkAdMob: {
#ifdef AdMobAvailable
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
        case SEAdNetworkGoogleDFP: {
#ifdef DFPAvailable
            [self.locationManager startMonitoringSignificantLocationChanges];
            self.DFPBannerView = [[DFPBannerView alloc] initWithAdSize:kGADAdSizeSmartBannerPortrait];
            self.DFPBannerView.adUnitID = self.DFPAdUnitID;
            self.DFPBannerView.rootViewController = self;
            self.DFPBannerView.delegate = self;
            self.DFPBannerView.validAdSizes = @[
                [NSValue valueWithBytes:&kGADAdSizeSmartBannerPortrait objCType:@encode(GADAdSize)],
                [NSValue valueWithBytes:&kGADAdSizeSmartBannerPortrait objCType:@encode(GADAdSize)],
            ];
            GADRequest *request = [GADRequest request];
            CLLocation *location = self.locationManager.location;
            [request setLocationWithLatitude:location.coordinate.latitude
                                   longitude:location.coordinate.longitude
                                    accuracy:sqrt(location.horizontalAccuracy * location.verticalAccuracy)];
            request.testDevices = @[ GAD_SIMULATOR_ID ];
            self.bannerView = self.DFPBannerView;
            [self.DFPBannerView loadRequest:request];
#endif
            break;
        }
        }
        [self.view addSubview:self.bannerView];
    }
    [self layoutBannerView];
}

- (void)deleteBanner
{
    if (_bannerView) {
        [(id)_bannerView setDelegate:nil];
        [_bannerView removeFromSuperview];
        _bannerView = nil;
        [self layoutBannerView];
    }
}

- (void)hideBanner
{
    self.adHidden = YES;
    [self layoutBannerView];
}

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_6_0
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return [_contentController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}
#endif

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return [_contentController preferredInterfaceOrientationForPresentation];
}

- (NSUInteger)supportedInterfaceOrientations
{
    return [_contentController supportedInterfaceOrientations];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    [self layoutBannerView];
}

- (void)layoutBannerView
{
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
        case SEAdNetworkGoogleDFP: {
#ifdef DFPAvailable
            self.DFPBannerView.adSize = kGADAdSizeSmartBannerPortrait;
#endif
            break;
        }
        }
    } else {
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
        case SEAdNetworkGoogleDFP: {
#ifdef DFPAvailable
            self.DFPBannerView.adSize = kGADAdSizeSmartBannerLandscape;
#endif
            break;
        }
        }
    }
    bannerFrame = _bannerView.frame;
#else
// If configured to support iOS >= 6.0 only, then we want to avoid currentContentSizeIdentifier as it is deprecated.
// Fortunately all we need to do is ask the banner for a size that fits into the layout area we are using.
// At this point in this method contentFrame=self.view.bounds, so we'll use that size for the layout.

#ifdef DFPAvailable
    if (contentFrame.size.width < contentFrame.size.height) {
        self.DFPBannerView.adSize = kGADAdSizeSmartBannerPortrait;
    } else {
        self.DFPBannerView.adSize = kGADAdSizeSmartBannerLandscape;
    }
#endif

    bannerFrame.size = [_bannerView sizeThatFits:contentFrame.size];
#endif

    if (!self.isAdHidden && ((self.adNetwork == SEAdNetworkiAd && ((ADBannerView *)_bannerView).bannerLoaded) || self.GADLoaded)) {
        contentFrame.size.height -= bannerFrame.size.height;
        bannerFrame.origin.y = contentFrame.size.height;
    } else {
        bannerFrame.origin.y = contentFrame.size.height;
    }

    _contentController.view.frame = contentFrame;
    _bannerView.frame = bannerFrame;
}

#pragma mark - ADBannerView Delegate

- (void)bannerViewDidLoadAd:(ADBannerView *)banner
{
    [self didRecieveAd];
}

- (void)bannerView:(ADBannerView *)banner didFailToReceiveAdWithError:(NSError *)error
{
    [self failureWithError:error];
}

- (BOOL)bannerViewActionShouldBegin:(ADBannerView *)banner willLeaveApplication:(BOOL)willLeave
{
    [self adWillShow];
    return YES;
}

- (void)bannerViewActionDidFinish:(ADBannerView *)banner
{
    [self adDidFinish];
}

#pragma mark - GADBannerView Delegate

#ifdef GADBannerViewAvailable

- (void)adView:(GADBannerView *)view didFailToReceiveAdWithError:(GADRequestError *)error
{
    _GADLoaded = NO;
    [self failureWithError:error];
}

- (void)adViewDidDismissScreen:(GADBannerView *)adView
{
    [self adDidFinish];
}

- (void)adViewDidReceiveAd:(GADBannerView *)view
{
    _GADLoaded = YES;
    [self didRecieveAd];
}

- (void)adViewWillDismissScreen:(GADBannerView *)adView
{
}

- (void)adViewWillLeaveApplication:(GADBannerView *)adView
{
    [self adDidFinish];
}

- (void)adViewWillPresentScreen:(GADBannerView *)adView
{
    [self adWillShow];
}

#endif

#pragma mark - Generic Delegate

- (void)failureWithError:(NSError *)error
{
    NSLog(@">>> Error loading ad: %@", error);
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutBannerView];
    }];
}

- (void)didRecieveAd
{
    [UIView animateWithDuration:0.25 animations:^{
        [self layoutBannerView];
    }];
}

- (void)adDidFinish
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SEBannerViewActionDidFinishNotification object:self.bannerView];
}

- (void)adWillShow
{
    [[NSNotificationCenter defaultCenter] postNotificationName:SEBannerViewActionWillBeginNotification object:self.bannerView];
    if (self.adWillShowBlock) self.adWillShowBlock(self, self.bannerView);
}

- (void)dealloc
{
    [(id)_bannerView setDelegate:nil];
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
