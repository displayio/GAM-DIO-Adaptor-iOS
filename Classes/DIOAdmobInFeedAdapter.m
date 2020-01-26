//
//  DIOAdmobInFeedAdapter.m
//  AdmobAdapterForiOS
//
//  Created by Ariel Malka on 7/16/19.
//  Copyright © 2019 Display.io. All rights reserved.
//

#import "DIOAdmobInFeedAdapter.h"

#import <DIOSDK/DIOController.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

static NSString *const customEventErrorDomain = @"com.google.CustomEvent";

@interface DIOAdmobInFeedAdapter () <GADCustomEventBanner>

@end

@implementation DIOAdmobInFeedAdapter

@synthesize delegate;

- (void)requestBannerAd:(GADAdSize)adSize parameter:(nullable NSString *)serverParameter label:(nullable NSString *)serverLabel request:(nonnull GADCustomEventRequest *)request {
    if (![DIOController sharedInstance].initialized) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInternalError userInfo:nil];
        [self.delegate customEventBanner:self didFailAd:error];
        return;
    }
    
    [[DIOController sharedInstance] setMediationPlatform:DIOMediationPlatformAdmob];

    DIOPlacement *placement = [[DIOController sharedInstance] placementWithId:serverParameter];
    if (!placement) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInvalidArgument userInfo:nil];
        [self.delegate customEventBanner:self didFailAd:error];
        return;
    }
    
    /*
     * Hack to handle automatic refresh
     */
    if ([placement hasPendingAdRequests]) {
        [[[placement lastAdRequest].adProvider.ad view] removeFromSuperview];
        [[placement lastAdRequest].adProvider.ad finish];
    }
    
    DIOAdRequest *request2 = [placement newAdRequest];
    
    [request2 requestAdWithAdReceivedHandler:^(DIOAdProvider *adProvider) {
        NSLog(@"AD RECEIVED");
        
        [adProvider loadAdWithLoadedHandler:^(DIOAd *ad) {
            NSLog(@"AD LOADED");

            [ad view].frame = CGRectMake(0, 0, adSize.size.width, adSize.size.height);
            [self.delegate customEventBanner:self didReceiveAd:[ad view]];
        } failedHandler:^(NSError *error){
            NSLog(@"AD FAILED TO LOAD: %@", error.localizedDescription);
            
            NSError *error1 = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInternalError userInfo:nil];
            [self.delegate customEventBanner:self didFailAd:error1];
        }];
    } noAdHandler:^(NSError *error){
        NSLog(@"NO AD: %@", error.localizedDescription);
        
        NSError *error1 = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorMediationNoFill userInfo:nil];
        [self.delegate customEventBanner:self didFailAd:error1];
    }];
}

@end
