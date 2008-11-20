//
//  sqMacMainObjCSparkle.m
//  SqueakVMUNIXPATHSSparkle
//
//  Created by John M McIntosh on 18/11/08.
//  Copyright 2008 Corporate Smalltalk Consulting Ltd. All rights reserved.
//
/* MIT License
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
#import <Cocoa/Cocoa.h>
#import "sq.h"
#import "sqMacMainObjCSparkle.h"
#import	<Sparkle/Sparkle.h>

@interface soundAtom : NSObject {
}
@end

@implementation soundAtom

// Use this to override the default behavior for Sparkle prompting the user about automatic update checks.
- (BOOL)updaterShouldPromptForPermissionToCheckForUpdates:(SUUpdater *)bundle{
	return NO;
};

// Implement this if you want to do some special handling with the appcast once it finishes loading.
- (void)updater:(SUUpdater *)updater didFinishLoadingAppcast:(SUAppcast *)appcast{};


// Sent when a valid update is found by the update driver.
- (void)updater:(SUUpdater *)updater didFindValidUpdate:(SUAppcastItem *)update{};

// Sent when a valid update is not found.
- (void)updaterDidNotFindUpdate:(SUUpdater *)update{};

// Sent immediately before installing the specified update.
- (void)updater:(SUUpdater *)updater willInstallUpdate:(SUAppcastItem *)update{};

// Return YES to delay the relaunch until you do some processing; invoke the given NSInvocation to continue.
- (BOOL)updater:(SUUpdater *)updater shouldPostponeRelaunchForUpdate:(SUAppcastItem *)update untilInvoking:(NSInvocation *)invocation {
return NO;
};
// Called immediately before relaunching.
- (void)updaterWillRelaunchApplication:(SUUpdater *)updater{};

// This method allows you to provide a custom version comparator.
// If you don't implement this method or return nil, the standard version comparator will be used.
- (id <SUVersionComparison>)versionComparatorForUpdater:(SUUpdater *)updater {
return nil;
};

@end;


sqInt convertNSDateToSqueakTime(NSDate *givenDate);

static SUUpdater * squeakSparkleUpdater= NULL;

void *setupSqueakSparkleUpdater (void) {
	if (squeakSparkleUpdater) 
		return squeakSparkleUpdater;
	/* NSBundle * bundleForUpdate;
	bundleForUpdate = [NSBundle mainBundle ];
	squeakSparkleUpdater =	[SUUpdater updaterForBundle: bundleForUpdate]; */
	squeakSparkleUpdater = [SUUpdater sharedUpdater];
	//[squeakSparkleUpdater setDelegate: [soundAtom new]];
	return squeakSparkleUpdater;
}

void setAutomaticallyChecksForUpdates(sqInt automaticallyChecksSqueak){
	BOOL automaticallyChecks = automaticallyChecksSqueak;
	[squeakSparkleUpdater setAutomaticallyChecksForUpdates: automaticallyChecks];
}

sqInt automaticallyChecksForUpdates(void){
	return [squeakSparkleUpdater automaticallyChecksForUpdates];
}

void setUpdateCheckInterval(double intervalSqueak) {
	NSTimeInterval automaticallyChecks = intervalSqueak;
	[squeakSparkleUpdater setUpdateCheckInterval: automaticallyChecks];
	
}

double updateCheckInterval(void) {
	return (double) [squeakSparkleUpdater updateCheckInterval];
	
}

void checkForUpdates(void){
	return [squeakSparkleUpdater checkForUpdates: nil];
}



void setSendsSystemProfile(sqInt sendsSystemProfileSqueak){
	BOOL sendsSystemProfile = sendsSystemProfileSqueak;
	[squeakSparkleUpdater setSendsSystemProfile: sendsSystemProfile];
}

sqInt sendsSystemProfile(void){
	return [squeakSparkleUpdater sendsSystemProfile];
}

void setFeedURL(char *feedURLSqueak, sqInt length){
	NSURL * feedURL;
	NSString * string;
	
	string = [[NSString alloc] initWithBytes: feedURLSqueak length: length encoding: NSUTF8StringEncoding];
	feedURL = [[NSURL alloc] initWithString: string];
	[squeakSparkleUpdater setFeedURL: feedURL];
	[feedURL release];
	[string release];
}

char * feedURL(void){
	NSURL * feedURL;
	NSString * string;
	
	feedURL = [squeakSparkleUpdater feedURL];
	string = [feedURL absoluteString];
	return (char *) [string cStringUsingEncoding:   NSUTF8StringEncoding];
}

void setAutomaticallyDownloadsUpdates(sqInt automaticallyDownloadsUpdatesSqueak){
	BOOL automaticallyDownloadsUpdates = automaticallyDownloadsUpdatesSqueak;
	[squeakSparkleUpdater setAutomaticallyDownloadsUpdates: automaticallyDownloadsUpdates];
}

sqInt automaticallyDownloadsUpdates(void){
	return [squeakSparkleUpdater automaticallyDownloadsUpdates];
}

void checkForUpdatesInBackground(void){
	return [squeakSparkleUpdater checkForUpdatesInBackground];
}

void checkForUpdateInformation(void){
return [squeakSparkleUpdater checkForUpdateInformation];
}


sqInt lastUpdateCheckDate(void) {
	NSDate *aNSDate;
	aNSDate = [squeakSparkleUpdater lastUpdateCheckDate];
	return convertNSDateToSqueakTime(aNSDate);
}

void resetUpdateCycle(void) {
	[squeakSparkleUpdater resetUpdateCycle];
}

sqInt updateInProgress(void) {
	sqInt	returnValue = [squeakSparkleUpdater updateInProgress];
	return returnValue;
}



sqInt convertNSDateToSqueakTime(NSDate *givenDate)
{
	//IM
	NSTimeInterval dateDifference;
	static NSDate *squeakEpoch=NULL;
	
	if (!givenDate) 
		return 0;
	
	if (squeakEpoch == NULL) {
		NSDateComponents *comps = [NSDateComponents new];
		NSCalendar *calenderEnglishUSA = [[NSCalendar alloc] initWithCalendarIdentifier: NSGregorianCalendar]; //Use USA english calender versus user choosen china calender
		//NSTimeZone* zone =[NSTimeZone timeZoneForSecondsFromGMT: 0];
		//[calenderEnglishUSA setTimeZone: zone];  THIS appears not to be needed?
		[comps setYear: 1901];
		[comps setMonth: 1];
		[comps setDay: 1];
		[comps setHour: 0];
		[comps setMinute: 0];
		[comps setSecond: 0];
		
		squeakEpoch = [calenderEnglishUSA  dateFromComponents: comps];
		[squeakEpoch retain];
		[comps release];
		[calenderEnglishUSA release];
	}
	
	/* Squeak epoch is Jan 1, 1901.  Unix epoch is Jan 1, 1970 */
	dateDifference = [givenDate timeIntervalSinceDate: squeakEpoch];
	return (sqInt) (usqInt) dateDifference;
}

