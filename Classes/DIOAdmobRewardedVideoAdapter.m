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

@interface DIOAdmobRewardedVideoAdapter () <GADMRewardBasedVideoAdNetworkAdapter>

@property (nonatomic, strong) DIOAd *ad;
@property (nonatomic, strong) NSString *placementID;
@property (nonatomic, weak) id<GADMRewardBasedVideoAdNetworkConnector> rewardBasedVideoAdConnector;

@end

@implementation DIOAdmobRewardedVideoAdapter

+ (NSString *)adapterVersion {
    return @"2.7.0";
}

- (instancetype)initWithRewardBasedVideoAdNetworkConnector:(id<GADMRewardBasedVideoAdNetworkConnector>)connector {
    if (!connector) {
        return nil;
    }

    if (self = [super init]) {
        self.rewardBasedVideoAdConnector = connector;
        self.placementID = [connector.credentials objectForKey:GADCustomEventParametersServer];
    }
    
    return self;
}

- (void)setUp {
    [self.rewardBasedVideoAdConnector adapterDidSetUpRewardBasedVideoAd:self];
}

+ (Class<GADAdNetworkExtras>)networkExtrasClass {
    return nil;
}

- (void)presentRewardBasedVideoAdWithRootViewController:(UIViewController *)viewController {
    [self.ad showAdFromViewController:viewController eventHandler:^(DIOAdEvent event){
        self.ad = nil;
        
        switch (event) {
            case DIOAdEventOnShown:
                NSLog(@"AdEventOnShown");
                [self.rewardBasedVideoAdConnector adapterDidOpenRewardBasedVideoAd:self];
                break;
                
            case DIOAdEventOnFailedToShow: {
                NSLog(@"AdEventOnFailedToShow");
                NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInternalError userInfo:nil];
                [self.rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:error];
                break;
            }
                
            case DIOAdEventOnClicked:
                NSLog(@"AdEventOnClicked");
                [self.rewardBasedVideoAdConnector adapterDidGetAdClick:self];
                break;
                
            case DIOAdEventOnClosed:
                NSLog(@"AdEventOnClosed");
                [self.rewardBasedVideoAdConnector adapterDidCloseRewardBasedVideoAd:self];
                break;
                
            case DIOAdEventOnAdCompleted:
                NSLog(@"AdEventOnAdCompleted");
                
                [self.rewardBasedVideoAdConnector adapterDidCompletePlayingRewardBasedVideoAd:self];
                [self.rewardBasedVideoAdConnector adapter:self didRewardUserWithReward:nil];
                
                break;
        }
    }];
}

- (void)requestRewardBasedVideoAd { 
    if (![DIOController sharedInstance].initialized) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInternalError userInfo:nil];
        [self.rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:error];
        return;
    }
    
    [[DIOController sharedInstance] setMediationPlatform:DIOMediationPlatformAdmob];
    
    DIOPlacement *placement;
    @try {
        placement = [[DIOController sharedInstance] placementWithId:self.placementID];
    } @catch (NSException *exception) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInvalidArgument userInfo:nil];
        [self.rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:error];
        return;
    }

    DIOAdRequest *request = [placement newAdRequest];

    [request requestAdWithAdReceivedHandler:^(DIOAdProvider *adProvider) {
        NSLog(@"AD RECEIVED");
        
        [adProvider loadAdWithLoadedHandler:^(DIOAd *ad) {
            NSLog(@"AD LOADED");
            
            self.ad = ad;
            [self.rewardBasedVideoAdConnector adapterDidReceiveRewardBasedVideoAd:self];
        } failedHandler:^(NSString *message){
            NSLog(@"AD FAILED TO LOAD: %@", message);
            
            NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInternalError userInfo:nil];
        [self.rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:error];
        }];
    } noAdHandler:^{
        NSLog(@"NO AD");
        
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorNoFill userInfo:nil];
        [self.rewardBasedVideoAdConnector adapter:self didFailToLoadRewardBasedVideoAdwithError:error];
    }];
}

- (void)stopBeingDelegate {
    // ???
}

@end
