//
//  DIOAdmobRewardedVideoAdapter.m
//  AdmobAdapterForiOS
//
//  Created by rdorofeev on 9/5/19.
//  Copyright © 2019 Display.io. All rights reserved.
//

#import "DIOAdmobRewardedVideoAdapter.h"

#import <DIOSDK/DIOController.h>

static NSString *const customEventErrorDomain = @"com.google.CustomEvent";
static NSString *const versionString = @"4.5.1";


@interface DIOAdmobRewardedVideoAdapter () <GADMediationAdapter>

@property (nonatomic, strong) DIOAd *ad;
@property (nonatomic, strong) NSString *placementID;
@property(nonatomic, weak) id<GADMediationRewardedAdEventDelegate> delegate;

@end

@implementation DIOAdmobRewardedVideoAdapter

+ (GADVersionNumber)adapterVersion {
    NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    if (versionComponents.count >= 3) {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        version.patchVersion = [versionComponents[2] integerValue];
        
    }
    return version;
}
+ (GADVersionNumber)adSDKVersion {
    NSArray *versionComponents = [versionString componentsSeparatedByString:@"."];
    GADVersionNumber version = {0};
    if (versionComponents.count >= 3) {
        version.majorVersion = [versionComponents[0] integerValue];
        version.minorVersion = [versionComponents[1] integerValue];
        version.patchVersion = [versionComponents[2] integerValue];
    }
    return version;
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return nil;
}

- (void)loadRewardedInterstitialAdForAdConfiguration:(nonnull GADMediationRewardedAdConfiguration *)adConfiguration
                                   completionHandler:(nonnull GADMediationRewardedLoadCompletionHandler) completionHandler{
    
    self.placementID = adConfiguration.credentials.settings[@"parameter"];
    if (![DIOController sharedInstance].initialized) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInternalError userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    [[DIOController sharedInstance] setMediationPlatform:DIOMediationPlatformAdmob];
    
    DIOPlacement *placement = [[DIOController sharedInstance] placementWithId:self.placementID];
    if (!placement) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInvalidArgument userInfo:nil];
        completionHandler(nil, error);
        return;
    }
    
    DIOAdRequest *request = [placement newAdRequest];
    
    [request requestAdWithAdReceivedHandler:^(DIOAdProvider *adProvider) {
        NSLog(@"AD RECEIVED");
        
        [adProvider loadAdWithLoadedHandler:^(DIOAd *ad) {
            NSLog(@"AD LOADED");
            
            self.ad = ad;
            self.delegate = completionHandler(self, nil);
            
        } failedHandler:^(NSError *error){
            NSLog(@"AD FAILED TO LOAD: %@", error.localizedDescription);
            
            NSError *error1 = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInternalError userInfo:nil];
            completionHandler(nil, error1);
        }];
    } noAdHandler:^(NSError *error){
        NSLog(@"NO AD: %@", error.localizedDescription);
        
        NSError *error1 = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorNoFill userInfo:nil];
        completionHandler(nil, error1);
    }];
}

- (void)presentFromViewController:(nonnull UIViewController *)viewController {
    [self.ad showAdFromViewController:viewController eventHandler:^(DIOAdEvent event){
        self.ad = nil;
        
        switch (event) {
            case DIOAdEventOnShown:
                NSLog(@"AdEventOnShown");
                [self.delegate willPresentFullScreenView];
                [self.delegate reportImpression];
                break;
                
            case DIOAdEventOnFailedToShow: {
                NSLog(@"AdEventOnFailedToShow");
                NSError *error3 = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorNoFill userInfo:nil];
                [self.delegate didFailToPresentWithError:error3];
                break;
            }
                
            case DIOAdEventOnClicked:
                NSLog(@"AdEventOnClicked");
                [self.delegate reportClick];
                break;
                
            case DIOAdEventOnClosed:
                NSLog(@"AdEventOnClosed");
                [self.delegate willDismissFullScreenView];
                [self.delegate didEndVideo];
                [self.delegate didDismissFullScreenView];
                break;
                
            case DIOAdEventOnAdCompleted:
                NSLog(@"AdEventOnAdCompleted");
                [self.delegate didEndVideo];
                
                break;
        }
    }];
}

@end
