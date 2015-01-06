//
//  sqSqueakIPhoneApplication+Network.m
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 09/02/09.
//  Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
//
// This example code comes from https://devforums.apple.com/message/26334#26334
// Also see http://developer.apple.com/iphone/library/samplecode/Reachability/listing2.html

#import "sqSqueakIPhoneApplication+Network.h"
	
	
@implementation UIApplication (NetworkExtensions)

// fast wi-fi connection
+(BOOL)hasActiveWiFiConnection
{
	SCNetworkReachabilityFlags     flags;
	SCNetworkReachabilityRef     reachabilityRef;
	BOOL                              gotFlags;
	
	reachabilityRef   = SCNetworkReachabilityCreateWithName(CFAllocatorGetDefault(), [@"0.0.0.0" UTF8String]);
	gotFlags          = SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
	CFRelease(reachabilityRef);
	
	if (!gotFlags)
	{
		return NO;
	}
	
	if( flags & kSCNetworkReachabilityFlagsIsWWAN )
	{
		return NO;
	}
	
	if( flags & kSCNetworkReachabilityFlagsReachable )
	{
		return YES;
	}
	
	return NO;
}

// any type of internet connection (edge, 3g, wi-fi)
+(BOOL)hasNetworkConnection
{
	SCNetworkReachabilityFlags     flags;
	SCNetworkReachabilityRef     reachabilityRef;
	BOOL                              gotFlags;
	
	reachabilityRef     = SCNetworkReachabilityCreateWithName(CFAllocatorGetDefault(), [@"www.apple.com" UTF8String]);
	gotFlags          = SCNetworkReachabilityGetFlags(reachabilityRef, &flags);
	CFRelease(reachabilityRef);
	
	if (!gotFlags || (flags == 0) )
	{
		return NO;
	}
	
	return YES;
}

@end
