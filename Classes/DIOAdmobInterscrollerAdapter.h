//
//  DIOAdmobInterscrollerAdapter.h
//  AdmobAdapterForiOS
//
//  Created by Ariel Malka on 12/22/19.
//  Copyright © 2019 Display.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>
#import <DIOSDK/DIOInterscrollerView.h>


NS_ASSUME_NONNULL_BEGIN

@interface DIOAdmobInterscrollerAdapter : NSObject

+ (DIOInterscrollerView*)getInterscrollerViewForTableView:(GADBannerView*)bannerView withInterscrollerSize:(CGSize)interscrollerSize withBaseSize:(GADAdSize)baseSize;

+ (DIOInterscrollerView*)getInterscrollerViewForScrollView:(GADBannerView*)bannerView withInterscrollerSize:(CGSize)interscrollerSize withBaseSize:(GADAdSize)baseSize;

@end

NS_ASSUME_NONNULL_END
