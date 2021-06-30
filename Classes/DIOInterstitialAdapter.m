//
//  DIOAdmobInterstitialAdapter.m
//  AdmobAdapterForiOS
//
//  Created by Ariel Malka on 7/10/19.
//  Copyright © 2019 Display.io. All rights reserved.
//

#import "DIOInterstitialAdapter.h"

#import <DIOSDK/DIOController.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

static NSString *const customEventErrorDomain = @"com.google.CustomEvent";

@interface DIOInterstitialAdapter () <GADCustomEventInterstitial>

@property (nonatomic, strong) DIOAd *ad;

@end

@implementation DIOInterstitialAdapter

@synthesize delegate;

- (void)requestInterstitialAdWithParameter:(nullable NSString *)serverParameter label:(nullable NSString *)serverLabel request:(GADCustomEventRequest *)request {
    if (![DIOController sharedInstance].initialized) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInternalError userInfo:nil];
        [self.delegate customEventInterstitial:self didFailAd:error];
        return;
    }
    
    [[DIOController sharedInstance] setMediationPlatform:DIOMediationPlatformAdmob];
    
    DIOPlacement *placement = [[DIOController sharedInstance] placementWithId:serverParameter];
    if (!placement) {
        NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInvalidArgument userInfo:nil];
        [self.delegate customEventInterstitial:self didFailAd:error];
        return;
    }
    
    DIOAdRequest *request2 = [placement newAdRequest];
    
    [request2 requestAdWithAdReceivedHandler:^(DIOAdProvider *adProvider) {
        NSLog(@"AD RECEIVED");
        
        [adProvider loadAdWithLoadedHandler:^(DIOAd *ad) {
            NSLog(@"AD LOADED");
            self.ad = ad;
            [self.delegate customEventInterstitialDidReceiveAd:self];
        } failedHandler:^(NSError *error){
            NSLog(@"AD FAILED TO LOAD: %@", error.localizedDescription);
            
            NSError *error1 = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInternalError userInfo:nil];
            [self.delegate customEventInterstitial:self didFailAd:error1];
        }];
    } noAdHandler:^(NSError *error){
        NSLog(@"NO AD: %@", error.localizedDescription);
        
        NSError *error1 = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorMediationNoFill userInfo:nil];
        [self.delegate customEventInterstitial:self didFailAd:error1];
    }];
}

- (void)presentFromRootViewController:(UIViewController *)rootViewController {
    [self.ad showAdFromViewController:rootViewController eventHandler:^(DIOAdEvent event){
        self.ad = nil;
        
        switch (event) {
            case DIOAdEventOnShown:
                NSLog(@"AdEventOnShown");
                [self.delegate customEventInterstitialWillPresent:self];
                break;
                
            case DIOAdEventOnFailedToShow: {
                NSLog(@"AdEventOnFailedToShow");
                
                NSError *error = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInternalError userInfo:nil];
                [self.delegate customEventInterstitial:self didFailAd:error];
                break;
            }

            case DIOAdEventOnClicked:
                NSLog(@"AdEventOnClicked");
                [self.delegate customEventInterstitialWasClicked:self];
                [self.delegate customEventInterstitialWillLeaveApplication:self];
                break;
                
            case DIOAdEventOnClosed:
                NSLog(@"AdEventOnClosed");
                [self.delegate customEventInterstitialDidDismiss:self];
                break;
                
            case DIOAdEventOnAdCompleted:
                NSLog(@"AdEventOnAdCompleted");
                [self.delegate customEventInterstitialDidDismiss:self];
                break;
        }
    }];
}

@end
