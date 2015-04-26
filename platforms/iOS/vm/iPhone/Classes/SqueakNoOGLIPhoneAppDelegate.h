//
//  SqueakNoOGLIPhoneAppDelegate.h
//  SqueakNoOGLIPhone
//
//  Created by John M McIntosh on 5/15/08.
/*
Some of this code was funded via a grant from the European Smalltalk User Group (ESUG)
 Copyright (c) 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
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

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import "SqueakUIView.h"
#import "SqueakUIController.h"
#import "sqSqueakAppDelegate.h"
#import	"sqiPhoneScreenAndWindow.h"

@interface SqueakNoOGLIPhoneAppDelegate : sqSqueakAppDelegate <UIApplicationDelegate,UIScrollViewDelegate,UIAccelerometerDelegate,CLLocationManagerDelegate> {
	IBOutlet UIWindow *window;
	IBOutlet SqueakUIView *mainView;				//This is the squeak screen surface
	IBOutlet SqueakUIController *viewController;	//This controler manages the ability to do orientation
	UIScrollView *scrollView;						//This scroll view wrapps the mainView
	sqiPhoneScreenAndWindow *screenAndWindow;
}
- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView;
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration;
- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application;      // try to clean up as much memory as possible. next step is to terminate app
- (void) zoomToOrientation:(UIInterfaceOrientation)o animated:(BOOL)animated;

@property (nonatomic,strong) UIWindow *window;
@property (nonatomic,strong) SqueakUIView *mainView;
@property (nonatomic,strong) UIScrollView *scrollView;
@property (nonatomic,strong) SqueakUIController *viewController;
@property (nonatomic,strong) sqiPhoneScreenAndWindow *screenAndWindow;
@end

