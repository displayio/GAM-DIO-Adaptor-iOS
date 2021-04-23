//
//  DIOAdmobInterscrollerAdapter.m
//  AdmobAdapterForiOS
//
//  Created by Ariel Malka on 12/22/19.
//  Copyright © 2019 Display.io. All rights reserved.
//

#import "DIOAdmobInterscrollerAdapter.h"

#import <DIOSDK/DIOController.h>
#import <DIOSDK/DIOInterscrollerContainer.h>

#import <GoogleMobileAds/GoogleMobileAds.h>

static NSString *const customEventErrorDomain = @"com.google.CustomEvent";

@interface DIOAdmobInterscrollerAdapter () <GADCustomEventBanner>

@end

@implementation DIOAdmobInterscrollerAdapter

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
        DIOInterscrollerView *interScrollerView = [[[[placement lastAdRequest].adProvider.ad view] superview] superview];
        if (interScrollerView == nil || [[placement lastAdRequest].adProvider.ad impressed]) {
            [[placement lastAdRequest].adProvider.ad finish];
            [self requestDioAd:adSize placement:placement];
        } else {
            interScrollerView.frame = CGRectMake(0, 0, adSize.size.width, adSize.size.height);
            [self.delegate customEventBanner:self didReceiveAd:interScrollerView];
        }
        
    } else {
        [self requestDioAd:adSize placement:placement];
    }
    
}

- (void)requestDioAd:(GADAdSize)adSize placement:(DIOPlacement *)placement {
    DIOAdRequest *request2 = [placement newAdRequest];
    
    DIOInterscrollerContainer *container = [[DIOInterscrollerContainer alloc] init];
    
    [container loadWithAdRequest:request2 completionHandler:^(DIOAd *ad){
        NSLog(@"AD LOADED");
        [container view].frame = CGRectMake(0, 0, adSize.size.width, adSize.size.height);
        [self.delegate customEventBanner:self didReceiveAd:[container view]];
    } errorHandler:^(NSError *error) {
        NSLog(@"AD FAILED TO LOAD: %@", error.localizedDescription);
        NSError *error1 = [NSError errorWithDomain:customEventErrorDomain code:kGADErrorInternalError userInfo:nil];
        [self.delegate customEventBanner:self didFailAd:error1];
    }];
}

+ (DIOInterscrollerView*)getInterscrollerViewForTableView:(GADBannerView*)bannerView withInterscrollerSize:(CGSize)interscrollerSize withBaseSize:(GADAdSize)baseSize {
    
    DIOInterscrollerView *dioView = bannerView.subviews[0].subviews[0].subviews[0].subviews[0];
    if (dioView != nil &&  [dioView isKindOfClass:[DIOInterscrollerView class]] ) {
        bannerView.adSize = GADAdSizeFromCGSize(interscrollerSize);
    } else {
        bannerView.adSize = baseSize;
    }
    return dioView;
}

+ (DIOInterscrollerView*)getInterscrollerViewForScrollView:(GADBannerView*)bannerView withInterscrollerSize:(CGSize)interscrollerSize withBaseSize:(GADAdSize)baseSize {
    
    DIOInterscrollerView *dioView = bannerView.subviews[0].subviews[0].subviews[0].subviews[0];
    if (dioView != nil &&  [dioView isKindOfClass:[DIOInterscrollerView class]] ) {
        bannerView.adSize = GADAdSizeFromCGSize(interscrollerSize);
        [dioView setConstraintForScrollView];
    } else {
        bannerView.adSize = baseSize;
    }
    return dioView;
}


@end
