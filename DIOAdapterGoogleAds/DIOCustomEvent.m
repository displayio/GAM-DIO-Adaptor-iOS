//
//  DisplayIOCustomEvent.m
//  AdmobAdapterForiOS
//
//  Created by Ro Do on 21.08.2023.
//  Copyright © 2023 Display.io. All rights reserved.
//

#import "DIOCustomEvent.h"
#import <DIOSDK/DIOSDK.h>
#include <stdatomic.h>


static NSString *const PARAMETER = @"parameter";
static NSString *const PLACEMENT_ID = @"placementID";

@interface DIOCustomEvent () <GADMediationBannerAd, GADMediationInterstitialAd>

@property(nonatomic, strong) id<GADMediationInterstitialAdEventDelegate> interstitialDelegate;
@property(nonatomic, strong) id<GADMediationBannerAdEventDelegate> inlineDelegate;
@property(nonatomic, strong) DIOAd *dioAd;
@property(nonatomic, strong) UIView *adView;

@end

@implementation DIOCustomEvent

#pragma mark GADMediationAdapter implementation

+ (GADVersionNumber)adSDKVersion {
    NSArray *versionComponents = [[[DIOController sharedInstance] getSDKVersion] componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
    
    return version;
}

+ (GADVersionNumber)adapterVersion {
    NSArray *versionComponents = [[[DIOController sharedInstance] getSDKVersion] componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    
    version.majorVersion = [versionComponents[0] integerValue];
    version.minorVersion = [versionComponents[1] integerValue];
    version.patchVersion = [versionComponents[2] integerValue];
    
    return version;
}

+ (nullable Class<GADAdNetworkExtras>)networkExtrasClass {
    return DIOCustomEvent.class;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
    completionHandler(nil);
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
    if (![DIOController sharedInstance].initialized) {
        NSError *error = [NSError errorWithDomain:DIO_CUSTOM_EVENT code:GADErrorInternalError userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    NSString *parameter = adConfiguration.credentials.settings[PARAMETER];

    id params = [NSJSONSerialization JSONObjectWithData:[parameter dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSString* placementID = params[PLACEMENT_ID];
    if (!placementID) {
        NSError *error = [NSError errorWithDomain:DIO_CUSTOM_EVENT code:GADErrorInvalidArgument userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    DIOPlacement *placement = [[DIOController sharedInstance] placementWithId:placementID];

    if (!placement) {
        NSError *error = [NSError errorWithDomain:DIO_CUSTOM_EVENT code:GADErrorInvalidArgument userInfo:nil];
        completionHandler(nil, error);
        return;
    }

    DIOAdRequest *request;
    
    @try {
        GADCustomEventExtras* extras = adConfiguration.extras;
        NSDictionary* dioCustomEvent = [extras extrasForLabel:DIO_CUSTOM_EVENT];
        if (dioCustomEvent != nil) {
            request = dioCustomEvent[DIO_AD_REQUEST];
        }
    } @catch (NSException *ignored) {
        
    }
   
    if (request == nil) {
        request = [placement newAdRequest];
    } else {
        [placement addAdRequest:request];
    }
    [request setMediationPlatform:DIOMediationPlatformGAM];

    if([placement isKindOfClass: DIOInterscrollerPlacement.class]) {
        UIViewController *topViewController = adConfiguration.topViewController;
        
        if(topViewController == nil) {
            NSError *error = [NSError errorWithDomain:DIO_CUSTOM_EVENT code:GADErrorInternalError userInfo:nil];
            self.inlineDelegate = completionHandler(nil, error);
            return;
        }
        
        DIOInterscrollerPlacement *interscrollerPlacement = (DIOInterscrollerPlacement*)placement;
        
        if(params[@"isReveal"]){
            BOOL isReveal = [[params valueForKey:@"isReveal"] boolValue];
            interscrollerPlacement.reveal = isReveal;
        }
        if(params[@"showHeader"]){
            BOOL showHeader = [[params valueForKey:@"showHeader"] boolValue];
            interscrollerPlacement.showHeader = showHeader;
        }
        if(params[@"showTapHint"]){
            BOOL showTapHint = [[params valueForKey:@"showTapHint"] boolValue];
            interscrollerPlacement.showTapHint = showTapHint;
        }
        
        DIOInterscrollerContainer *container = [[DIOInterscrollerContainer alloc] init];
        [container loadWithAdRequest:request completionHandler:^(DIOAd *ad){
            self.adView = [container view];
            self.adView.frame = CGRectMake(0, 0,
                                      topViewController.view.frame.size.width,
                                      topViewController.view.frame.size.height);
            
            self.inlineDelegate = completionHandler(self, nil);
            [self handleInlineAdEvents:ad];
        } errorHandler:^(NSError *error) {
            self.inlineDelegate = completionHandler(nil, error);
        }];
    } else if ([placement isKindOfClass: DIOHeadlinePlacement.class]){
        NSError *error = [NSError errorWithDomain:@"Headline ad unit is not supported" code:GADErrorInternalError userInfo:nil];
        self.inlineDelegate = completionHandler(nil, error);
    } else if ([placement isKindOfClass: DIOInFeedPlacement.class]
               || [placement isKindOfClass: DIOMediumRectanglePlacement.class]
               || [placement isKindOfClass: DIOBannerPlacement.class]){
        [request requestAdWithAdReceivedHandler:^(DIOAd *ad) {
            self.adView = [ad view];
            if ([placement isKindOfClass: DIOBannerPlacement.class]){
                self.adView.frame = CGRectMake(0, 0, 320, 50);
            }
            if ([placement isKindOfClass: DIOMediumRectanglePlacement.class]
                 || [placement isKindOfClass: DIOInFeedPlacement.class]){
                self.adView.frame = CGRectMake(0, 0, 300, 250);
            }
            self.inlineDelegate = completionHandler(self, nil);
            [self handleInlineAdEvents:ad];
        } noAdHandler:^(NSError *error){
            self.inlineDelegate = completionHandler(nil, error);
        }];
    } else {
        NSError *error = [NSError errorWithDomain:DIO_CUSTOM_EVENT code:GADErrorInternalError userInfo:nil];
        self.inlineDelegate = completionHandler(nil, error);
    }
}


- (void)loadInterstitialForAdConfiguration:
(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
(GADMediationInterstitialLoadCompletionHandler)completionHandler {
    self.dioAd = nil;
    if (![DIOController sharedInstance].initialized) {
        NSError *error = [NSError errorWithDomain:DIO_CUSTOM_EVENT code:GADErrorInternalError userInfo:nil];
        completionHandler(nil, error);
        return;
    }

    NSString *parameter = adConfiguration.credentials.settings[PARAMETER];
    id params = [NSJSONSerialization JSONObjectWithData:[parameter dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSString* placementID = params[PLACEMENT_ID];
    if (!placementID) {
        NSError *error = [NSError errorWithDomain:DIO_CUSTOM_EVENT code:GADErrorInvalidArgument userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    DIOPlacement *placement = [[DIOController sharedInstance] placementWithId:placementID];
    
    if (!placement) {
        NSError *error = [NSError errorWithDomain:DIO_CUSTOM_EVENT code:GADErrorInvalidArgument userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    DIOAdRequest *request;
    
    @try {
        GADCustomEventExtras* extras = adConfiguration.extras;
        NSDictionary* dioCustomEvent = [extras extrasForLabel:DIO_CUSTOM_EVENT];
        if (dioCustomEvent != nil) {
            request = dioCustomEvent[DIO_AD_REQUEST];
        }
    } @catch (NSException *ignored) {
        
    }
   
    if (request == nil) {
        request = [placement newAdRequest];
    } else {
        [placement addAdRequest:request];
    }
    [request setMediationPlatform:DIOMediationPlatformGAM];
    [request requestAdWithAdReceivedHandler:^(DIOAd *ad) {
        self.dioAd = ad;
        self.interstitialDelegate = completionHandler(self, nil);
    } noAdHandler:^(NSError *error){
        completionHandler(nil, error);
    }];
}

#pragma mark GADMediationBannerAd implementation
- (nonnull UIView *)view {
    return self.adView;
}

#pragma mark GADMediationInterstitialAd implementation
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    if(!self.dioAd) {
        return;
    }
    [self.dioAd showAdFromViewController:viewController eventHandler:^(DIOAdEvent event){
        if(self.interstitialDelegate == nil) {
            return;
        }
        
        switch (event) {
            case DIOAdEventOnShown:
                [self.interstitialDelegate willPresentFullScreenView];
                [self.interstitialDelegate reportImpression];
                break;
            case DIOAdEventOnFailedToShow:{
                NSError *error = [NSError errorWithDomain:DIO_CUSTOM_EVENT code:GADErrorInternalError userInfo:nil];
                [self.interstitialDelegate didFailToPresentWithError:error];
                break;
            }
            case DIOAdEventOnClicked:
                [self.interstitialDelegate reportClick];
                break;
            case DIOAdEventOnClosed:
            case DIOAdEventOnAdCompleted:
                [self.interstitialDelegate willDismissFullScreenView];
                [self.interstitialDelegate didDismissFullScreenView];
                break;
            case DIOAdEventOnSwipedOut:
            case DIOAdEventOnSnapped:
            case DIOAdEventOnMuted:
            case DIOAdEventOnUnmuted:
                break;
        }
    }];
}

- (void)handleInlineAdEvents:(DIOAd *)ad {
    if(ad == nil || self.inlineDelegate == nil) {
        return;
    }
    [ad setEventHandler:^(DIOAdEvent event) {
        switch (event) {
            case DIOAdEventOnShown:
                [self.inlineDelegate willPresentFullScreenView];
                [self.inlineDelegate reportImpression];
                [self.inlineDelegate willDismissFullScreenView];
                [self.inlineDelegate didDismissFullScreenView];
                break;
            case DIOAdEventOnFailedToShow:{
                NSError *error = [NSError errorWithDomain:DIO_CUSTOM_EVENT code:GADErrorInternalError userInfo:nil];
                [self.inlineDelegate didFailToPresentWithError:error];
                break;
            }
            case DIOAdEventOnClicked:
                [self.inlineDelegate reportClick];
                break;
            case DIOAdEventOnClosed:
            case DIOAdEventOnAdCompleted:
            case DIOAdEventOnSwipedOut:
            case DIOAdEventOnSnapped:
            case DIOAdEventOnMuted:
            case DIOAdEventOnUnmuted:
                break;
        }
    }];
}

@end
