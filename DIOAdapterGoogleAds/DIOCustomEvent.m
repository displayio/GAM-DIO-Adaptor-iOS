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


static NSString *const customEventErrorDomain = @"DIOCustomEvent";

@interface DIOCustomEvent () <GADMediationBannerAd, GADMediationInterstitialAd>

@end

@implementation DIOCustomEvent
DIOAd *dioAd;
UIView *adView;


id<GADMediationInterstitialAdEventDelegate> interstitialDelegate;
id<GADMediationBannerAdEventDelegate> inlineDelegate;


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
    return Nil;
}

+ (void)setUpWithConfiguration:(GADMediationServerConfiguration *)configuration
             completionHandler:(GADMediationAdapterSetUpCompletionBlock)completionHandler {
    completionHandler(nil);
}

- (void)loadBannerForAdConfiguration:(GADMediationBannerAdConfiguration *)adConfiguration
                   completionHandler:(GADMediationBannerLoadCompletionHandler)completionHandler {
    if (![DIOController sharedInstance].initialized) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:GADErrorInternalError userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    [[DIOController sharedInstance] setMediationPlatform:DIOMediationPlatformAdmob];
    NSString *parameter = adConfiguration.credentials.settings[@"parameter"];

    id params = [NSJSONSerialization JSONObjectWithData:[parameter dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSString* placementID = params[@"placementID"];
    if (!placementID) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:GADErrorInvalidArgument userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    DIOPlacement *placement = [[DIOController sharedInstance] placementWithId:placementID];

    if (!placement) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:GADErrorInvalidArgument userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    DIOAdRequest *request = [placement newAdRequest];
    
    if([placement isKindOfClass: DIOInterscrollerPlacement.class]) {
        UIViewController *topViewController = adConfiguration.topViewController;
        
        if(topViewController == nil) {
            NSError *error = [NSError errorWithDomain:customEventErrorDomain code:GADErrorInternalError userInfo:nil];
            inlineDelegate = completionHandler(nil, error);
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
            adView = [container view];
            adView.frame = CGRectMake(0, 0,
                                      topViewController.view.frame.size.width,
                                      topViewController.view.frame.size.height);
            
            inlineDelegate = completionHandler(self, nil);
            [self handleInlineAdEvents:ad];
        } errorHandler:^(NSError *error) {
            inlineDelegate = completionHandler(nil, error);
        }];
    } else if ([placement isKindOfClass: DIOHeadlinePlacement.class]){
        NSError *error = [NSError errorWithDomain:@"Headline ad unit is not supported" code:GADErrorInternalError userInfo:nil];
        inlineDelegate = completionHandler(nil, error);
    } else if ([placement isKindOfClass: DIOInFeedPlacement.class]
               || [placement isKindOfClass: DIOMediumRectanglePlacement.class]
               || [placement isKindOfClass: DIOBannerPlacement.class]){
        [request requestAdWithAdReceivedHandler:^(DIOAdProvider *adProvider) {
            [adProvider loadAdWithLoadedHandler:^(DIOAd *ad) {
                adView = [ad view];
                if ([placement isKindOfClass: DIOBannerPlacement.class]){
                    adView.frame = CGRectMake(0, 0, 320, 50);
                }
                if ([placement isKindOfClass: DIOMediumRectanglePlacement.class]
                     || [placement isKindOfClass: DIOInFeedPlacement.class]){
                    adView.frame = CGRectMake(0, 0, 300, 250);
                }
                inlineDelegate = completionHandler(self, nil);
                [self handleInlineAdEvents:ad];
            } failedHandler:^(NSError *error){
                inlineDelegate = completionHandler(nil, error);
            }];
        } noAdHandler:^(NSError *error){
            inlineDelegate = completionHandler(nil, error);
        }];
    } else {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:GADErrorInternalError userInfo:nil];
        inlineDelegate = completionHandler(nil, error);
    }
}


- (void)loadInterstitialForAdConfiguration:
(GADMediationInterstitialAdConfiguration *)adConfiguration
                         completionHandler:
(GADMediationInterstitialLoadCompletionHandler)completionHandler {
    dioAd = nil;
    if (![DIOController sharedInstance].initialized) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:GADErrorInternalError userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    [[DIOController sharedInstance] setMediationPlatform:DIOMediationPlatformAdmob];
    
    NSString *parameter = adConfiguration.credentials.settings[@"parameter"];
    
    id params = [NSJSONSerialization JSONObjectWithData:[parameter dataUsingEncoding:NSUTF8StringEncoding] options:0 error:nil];
    NSString* placementID = params[@"placementID"];
    if (!placementID) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:GADErrorInvalidArgument userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    DIOPlacement *placement = [[DIOController sharedInstance] placementWithId:placementID];
    
    if (!placement) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:GADErrorInvalidArgument userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    DIOAdRequest *request = [placement newAdRequest];
    [request requestAdWithAdReceivedHandler:^(DIOAdProvider *adProvider) {
        [adProvider loadAdWithLoadedHandler:^(DIOAd *ad) {
            dioAd = ad;
            interstitialDelegate = completionHandler(self, nil);
        } failedHandler:^(NSError *error){
            completionHandler(nil, error);
        }];
    } noAdHandler:^(NSError *error){
        completionHandler(nil, error);
    }];
}

#pragma mark GADMediationBannerAd implementation
- (nonnull UIView *)view {
    return adView;
}

#pragma mark GADMediationInterstitialAd implementation
- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    if(!dioAd) {
        return;
    }
    [dioAd showAdFromViewController:viewController eventHandler:^(DIOAdEvent event){
        if(interstitialDelegate == nil) {
            return;
        }
        
        switch (event) {
            case DIOAdEventOnShown:
                [interstitialDelegate willPresentFullScreenView];
                [interstitialDelegate reportImpression];
                break;
            case DIOAdEventOnFailedToShow:{
                NSError *error = [NSError errorWithDomain:customEventErrorDomain code:GADErrorInternalError userInfo:nil];
                [interstitialDelegate didFailToPresentWithError:error];
                break;
            }
            case DIOAdEventOnClicked:
                [interstitialDelegate reportClick];
                break;
            case DIOAdEventOnClosed:
            case DIOAdEventOnAdCompleted:
                [interstitialDelegate willDismissFullScreenView];
                [interstitialDelegate didDismissFullScreenView];
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
    if(ad == nil || inlineDelegate == nil) {
        return;
    }
    [ad setEventHandler:^(DIOAdEvent event) {
        switch (event) {
            case DIOAdEventOnShown:
                [inlineDelegate willPresentFullScreenView];
                [inlineDelegate reportImpression];
                [inlineDelegate willDismissFullScreenView];
                [inlineDelegate didDismissFullScreenView];
                break;
            case DIOAdEventOnFailedToShow:{
                NSError *error = [NSError errorWithDomain:customEventErrorDomain code:GADErrorInternalError userInfo:nil];
                [inlineDelegate didFailToPresentWithError:error];
                break;
            }
            case DIOAdEventOnClicked:
                [inlineDelegate reportClick];
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
