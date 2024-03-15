//
//  DisplayIOCustomEvent.h
//  AdmobAdapterForiOS
//
//  Created by Ro Do on 21.08.2023.
//  Copyright © 2023 Display.io. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GoogleMobileAds/GoogleMobileAds.h>

NS_ASSUME_NONNULL_BEGIN

static NSString *const DIO_CUSTOM_EVENT = @"DIOCustomEvent";
static NSString *const DIO_AD_REQUEST = @"dioAdRequest";

@interface DIOCustomEvent : GADCustomEventExtras <GADMediationAdapter, GADAdNetworkExtras>



@end

NS_ASSUME_NONNULL_END
