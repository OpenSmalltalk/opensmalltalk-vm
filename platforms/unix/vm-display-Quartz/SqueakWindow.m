@implementation SqueakWindow

- (BOOL) isOpaque		{ return YES; }
- (BOOL) canBecomeKeyWindow	{ return YES; }

- (void) setIcon
{
  /////////////xxxxxxxxxxxxxxxxxxxxxxxxxx REMOVE
  icon= [[NSImage alloc] initWithContentsOfFile: @"transp.icns"];
  if (icon)
    [NSApp setApplicationIconImage: icon];
}

- (NSImage *) dockImage
{
  NSBitmapImageRep *rep= [NSBitmapImageRep alloc];
  if ([rep initWithFocusedViewRect: topRect])
    {
      NSImage *image= [[NSImage alloc] init];
      [image addRepresentation: rep];
      if (icon)
	{
	  [image lockFocus];
	  [icon drawInRect: NSMakeRect(0, 0, [image size].width, [image size].height)
		fromRect:   NSMakeRect(0, 0, [icon size].width, [icon size].height)
		operation:  NSCompositeSourceOver
		fraction:   1.0];
	  [image unlockFocus];
	}
      return image;
    }
  return nil;
}

- (void) performMiniaturize: (id)sender
{
  if (!glActive)
    [super performMiniaturize: sender];
}

- (void) miniaturize: (id)sender
{
  NSImage *image= [self dockImage];
  if (image)
    [self setMiniwindowImage: image];
  [image release];
  [super miniaturize: sender];
}


@end
