//
//  SEBannerViewController.h
//  SladerReader
//
//  Created by Samuel E. Giddins on 07.02.13.
//  Copyright (c) 2013 Slader. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

typedef NS_ENUM(NSInteger, SEAdNetworkType) {
    SEAdNetworkiAd = 1,
    SEAdNetworkAdMob,
    SEAdNetworkGoogleDFP,
};

extern NSString *SEBannerViewActionDidFinishNotification;
extern NSString *SEBannerViewActionWillBeginNotification;

extern NSString *SEStringFromAdNetworkType(SEAdNetworkType adNetworkType);

@interface SEBannerViewController : UIViewController <ADBannerViewDelegate>

@property (nonatomic, getter=isEnabled) BOOL enabled;

@property (nonatomic, readonly) SEAdNetworkType adNetwork;

@property (nonatomic) NSArray *adKeywords;

@property (nonatomic, copy) NSString *adMobPublisherID;

@property (nonatomic, copy) NSString *DFPAdUnitID;

@property (nonatomic, copy) void (^adWillShowBlock)(SEBannerViewController *bannerViewController, id bannerView);

+ (instancetype)bannerViewControllerWithContentViewController:(UIViewController *)contentViewController adNetwork:(SEAdNetworkType)adNetwork;

- (void)deleteBanner;
- (void)hideBanner;
- (void)showBanner;

@end

@interface UIViewController (SEBannerViewController)

@property (readonly) SEBannerViewController *bannerViewController;

@end