// -*- ObjC -*-

@interface Squeak : NSApplication
- (void) applicationDidFinishLaunching: (NSNotification *)note;
- (void) applicationDidChangeScreenParameters: (NSNotification *)note;
- (void) unhideAllApplications: (id)sender;
- (BOOL) windowShouldClose: (id)sender;
- (void) maybeTerminate: (id)sender;
- (void) terminate: (id)sender;
- (void) performEnableKeys: (id)sender;
- (void) performDisableKeys: (id)sender;
@end
