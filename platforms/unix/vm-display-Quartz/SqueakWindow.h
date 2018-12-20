// -*- ObjC -*-

@interface SqueakWindow : NSWindow
{
  NSImage *icon;
}
- (BOOL) isOpaque;
- (BOOL) canBecomeKeyWindow;
- (void) setIcon;
- (void) performMiniaturize: (id)sender;
- (void) miniaturize: (id)sender;
@end
