//
//  squeakProxy.h
//  SqueakObjectiveC
//
//  Created by John M McIntosh on 01/02/09.
//  Copyright 2009 Corporate Smalltalk Consulting Ltd. All rights reserved.
/* 
 MIT License
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 The end-user documentation included with the redistribution, if any, must include the following acknowledgment: 
 "This product includes software developed by Corporate Smalltalk Consulting Ltd (http://www.smalltalkconsulting.com) 
 and its contributors", in the same place and form as other third-party acknowledgments. 
 Alternately, this acknowledgment may appear in the software itself, in the same form and location as other 
 such third-party acknowledgments.
 */
//


#import <objc/runtime.h>
#import "sq.h"


extern struct VirtualMachine* interpreterProxy;

/* Protocol * foo1 = @protocol(CLLocationManagerDelegate);	
 Protocol * foo2 = @protocol(NSCoding);	
 Protocol * foo3 = @protocol(NSCopying);	
 Protocol * foo4 = @protocol(NSDecimalNumberBehaviors);	
 Protocol * foo5 = @protocol(NSFastEnumeration);	
 Protocol * foo6 = @protocol(NSLocking);	
 Protocol * foo7 = @protocol(NSMutableCopying);	
 Protocol * foo8 = @protocol(NSObject);	
 Protocol * foo9 = @protocol(NSURLAuthenticationChallengeSender);	
 Protocol * foo10 = @protocol(NSURLProtocolClient);	
 Protocol * foo11 = @protocol(UIAccelerometerDelegate);	
 Protocol * foo12 = @protocol(UIAlertViewDelegate);	
 Protocol * foo13 = @protocol(UIApplicationDelegate);	
 Protocol * foo14 = @protocol(UIImagePickerControllerDelegate);	
 Protocol * foo15 = @protocol(UINavigationBarDelegate);	
 Protocol * foo16 = @protocol(UINavigationControllerDelegate);	
 Protocol * foo17 = @protocol(UIPickerViewDataSource);	
 Protocol * foo18 = @protocol(UIPickerViewDelegate);	
 Protocol * foo19 = @protocol(UISearchBarDelegate);	
 Protocol * foo20 = @protocol(UIScrollViewDelegate);	
 Protocol * foo21 = @protocol(UITabBarControllerDelegate);
 Protocol * foo22 = @protocol(UITabBarDelegate);	
 Protocol * foo23 = @protocol(UITableViewDataSource);	
 Protocol * foo24 = @protocol(UITableViewDelegate);	
 Protocol * foo25 = @protocol(UITextFieldDelegate);	
 Protocol * foo26 = @protocol(UITextInputTraits);	
 Protocol * foo27 = @protocol(UITextViewDelegate);	
 Protocol * foo28 = @protocol(UIWebViewDelegate);	*/

@interface SqueakProxy : NSObject
{
	sqInt sem;
	Protocol* __unsafe_unretained protocol;
	NSInvocation* __weak invocation;
	NSConditionLock* lockForSqueak;
	NSMutableDictionary *sigs;
	id	target;
	sqInt	callbackid;
	BOOL	isCarbonVM;
}
- (instancetype) initWithSemaphore: (sqInt) squeakSem protocolNSString: (NSString *) nameString target: (id) aTarget;
- (void) setReturnValue: (void*) pointer;
- (BOOL) isDataTypeAware;
- (void) setIsCarbonVM;

@property (nonatomic,assign) sqInt sem;
@property (nonatomic,unsafe_unretained) Protocol* protocol;
@property (weak, nonatomic) NSInvocation* invocation;
@property (nonatomic) NSConditionLock* lockForSqueak;
@property (nonatomic) NSMutableDictionary *sigs;
@property (nonatomic,strong) id target;
@property (nonatomic,assign) sqInt callbackid;
@end
