//
//  sqSqueakIPhoneApplication+Network.h
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 09/02/09.
//  Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
//
// This example code comes from https://devforums.apple.com/message/26334#26334


#import <Foundation/Foundation.h>
#import <SystemConfiguration/SCNetworkReachability.h>


@interface UIApplication (NetworkExtensions)

+(BOOL)hasActiveWiFiConnection;     // fast wi-fi connection
+(BOOL)hasNetworkConnection;     // any type of internet connection (edge, 3g, wi-fi)

@end
