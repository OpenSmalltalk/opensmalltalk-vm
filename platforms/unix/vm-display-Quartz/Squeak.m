#import <Cocoa/Cocoa.h>

@implementation Squeak


+ (void) initialize
{
  NSMutableDictionary *dict;
  NSUserDefaults *defaults;

  defaults= [NSUserDefaults standardUserDefaults];
  dict= [NSMutableDictionary dictionary];
    
  [dict setObject: @"YES" forKey: @"AppleDockIconEnabled"];
  [defaults registerDefaults: dict];
}


static char *documentName= 0;


-(BOOL) application: (NSApplication *) theApplication
	openFile:    (NSString *)      filename
{
  if (fromFinder)
    documentName= strdup([filename cString]);
  return YES;
}


-(void) applicationDidFinishLaunching: (NSNotification *)note
{
  int fds[2];

  // this saves an awful lot of tedious mutex contention (and besides
  // is essentially free, since there's no way to avoid writing a
  // socket to inform aio of the availability of the event)
#if 0
  if (socketpair(AF_UNIX, SOCK_STREAM, 0, fds) != 0)
    {
      perror("socketpair");
      exit(1);
    }
  osXfd= fds[0];
  stXfd= fds[1];
#else
  if (pipe(fds))
    {
      perror("pipe");
      exit(1);
    }
  stXfd= fds[0];
  osXfd= fds[1];
#endif
  aioEnable(stXfd, 0, 0);
  aioHandle(stXfd, evtHandler, AIO_RX);
#if (!USE_SPINLOCK)
  {
    pthread_mutexattr_t attr;
    pthread_mutexattr_init(&attr);
#  ifndef NDEBUG
    pthread_mutexattr_settype(&attr, PTHREAD_MUTEX_ERRORCHECK);
#  endif
    if (pthread_mutex_init(&displayMx, &attr))
      {
	perror("pthread_mutex_init");
	exit(1);
      }
    pthread_mutexattr_destroy(&attr);
  }
#endif

  if (fromFinder)
    {
      char *ptr= 0;
      strncpy(resourcePath, argVec[0], sizeof(resourcePath));	// .app/Contents/MacOS/squeak
      if ((ptr= strrchr(resourcePath, '/')))
	{
	  *ptr= '\0';						// .app/Contents/MacOS
	  if ((ptr= strrchr(resourcePath, '/')))
	    {
	      *ptr= '\0';						// .app/Contents
	      strcpy(ptr, "/Resources/");				// .app/Contents/Resources/
	    }
	  else
	    resourcePath[0]= '\0';
	}
      else
	resourcePath[0]= '\0';
    }

  imgInit();

  // vmPath has been set to the realpath() of the VM, which might be
  // bogus (since the more cultivated OS X user will make it a symlink
  // to /usr/local/bin/squeak).  put it back where it should be.  note
  // that we would also like to pick up the sources file from
  // resourcePath/SqueakV*.sources, but I guess the stupid image is
  // going to look for it in the vmPath.  ho hum.
  {
    char *ptr;
    assert(strlen(argVec[0]) < MAXPATHLEN);
    strcpy(vmPath, argVec[0]);
    if ((ptr= strrchr(vmPath, '/')))
      ptr[1]= '\0';
  }

  setUpDisplay();
  printf("fullScreenFlag %d\n", getFullScreenFlag());
  setUpWindow(fullscreen= getFullScreenFlag());

  [NSThread
    detachNewThreadSelector: @selector(interpret:)
    toTarget:		     self
    withObject:		     nil];
}


- (void) interpret: (id)context
{
  [[NSAutoreleasePool alloc] init];	// running in new thread
  interpret();
  (void)recordMouseEvent;
  (void)recordKeyboardEvent;
  (void)recordDragEvent;
}


- (void) applicationDidChangeScreenParameters: (NSNotification *)note
{
  //xxx this one might be tricky in the absence of appWillChangeScreenParams:
  fprintf(stderr, "\nDISPLAY PARAMETERS CHANGED\n\n");
  //  lock(display);
  pixWidth= pixHeight= pixDepth= 0;
  setUpDisplay();
  //setUpWindow(getFullScreenFlag());
  updatePix();
  //  unlock(display);
  //setUpMenus();
  fullDisplayUpdate();
}


- (void) unhideAllApplications: (id)sender
{
  [super unhideAllApplications: sender];
  [win orderFront: self]; // so that unhinding once more will reveal the Sq window
}


- (BOOL) windowShouldClose: (id)sender
{
  return NO;
}


- (void) terminate: (id)sender
{
  [super terminate: sender];
  exit(0);
}

- (void) maybeTerminate: (id)sender
{
  switch (NSRunAlertPanel(@"Really quit?",
			  @"All changes since your last save will be lost.\n\nIf you want to save your changes, press `Cancel' and then choose `save and quit' from the background menu in the Squeak window.",
			  @"Quit",
			  @"Cancel",
			  nil))
    {
    case NSAlertDefaultReturn:	[self terminate: self];
    }
}


- (void) performAbout: (id)sender
{
  extern char *getVersionInfo(int verbose);
  char *info= getVersionInfo(1);
  NSPanel *panel= NSGetInformationalAlertPanel(@"About Squeak",
					       @"%s",
					       @"Dismiss",
					       nil,
					       nil,
					       info);
  NSRect frame= [panel frame];
  frame.size.width *= 1.5;
  [panel setFrame: frame display: NO];
  [NSApp runModalForWindow: panel];
  [panel close];
  free(info);
}



//xxx why does rebuilding the menu lose boldface on the Apple menu item???

- (void) performEnableKeys:  (id)sender	{ cmdKeys= 1;  setUpMenus(); }
- (void) performDisableKeys: (id)sender	{ cmdKeys= 0;  setUpMenus(); }


- (void) windowWillMove: (NSNotification *)note
{
  //xxx FIXME SOON: there are other ways to enter this (and ways other than
  // noteEvent to escape from it)
  inModalLoop= 1;
}


- (NSSize) windowWillResize: (NSWindow *)sender toSize: (NSSize)size
{
  return glActive ? [sender frame].size : size;
}


- (void) windowDidResize: (NSNotification *)note
{
  reframeRenderers();
}


-(void) sendEvent: (NSEvent *)event
{
  int	  type=     [event type];
  NSPoint loc=      [event locationInWindow];
  NSWindow *evtWin= [event window];
#if 0
  NSPoint loc=      (fullscreen
		     ? [NSEvent mouseLocation]	//xxx should use deltas
		     : [event locationInWindow]);
#endif

  if (evtWin && ((NSWindow *)win != [event window]))
    {
      [super sendEvent: event];
      return;
    }

  switch (type)
    {
#     define down buttonState |= qz2sqButton([event buttonNumber])
#     define move
#     define up	  buttonState &= ~qz2sqButton([event buttonNumber])

#     define recordEvent(delta)					\
      if (fullscreen || NSPointInRect(loc, [view frame]))	\
	{							\
	  noteMousePoint(loc);					\
	  delta;						\
	  modifierState= qz2sqModifiers([event modifierFlags]);	\
	  noteMouseEvent();					\
	}							\
      else							\
	[super sendEvent: event]	// don't track outside window

    case NSLeftMouseDown: case NSOtherMouseDown: case NSRightMouseDown:
      if ((!active) || NSPointInRect(loc, resizeRect))
	[super sendEvent: event];	// first click, or start resize
      else
	recordEvent(down);
      break;

    case NSLeftMouseDragged: case NSRightMouseDragged: case NSOtherMouseDragged:
      if (!(buttonState & qz2sqButton([event buttonNumber])))
	{
	  [super sendEvent: event];	// already tracking window move
	  break;
	}
      // fall through...
    case NSMouseMoved:
      recordEvent(move);
      break;

    case NSLeftMouseUp: case NSOtherMouseUp: case NSRightMouseUp:
      recordEvent(up);
      break;

#     undef recordEvent
#     undef down
#     undef move
#     undef up

    case NSKeyDown:
      {
	int keyCode;
	modifierState= qz2sqModifiers([event modifierFlags]);
	keyCode= [view composeKeyDown: event]; //qz2sqKey(event);
	if (keyCode >= 0)
	  {
	    if (cmdKeys)
	      {
		if ((modifierState == CommandKeyBit) || (modifierState == CommandKeyBit + ShiftKeyBit))
		  switch (keyCode)
		    {
		    case '?': [NSApp showHelp: self];			keyCode= -1; break;
		    case 'h': [NSApp hide: self];			keyCode= -1; break;
		    case 'k': [NSApp performDisableKeys: self];		keyCode= -1; break;
		    case 'm': [win   performMiniaturize: self];		keyCode= -1; break;
		    case 'q': [NSApp maybeTerminate: self];		keyCode= -1; break;
		    }
		else if (modifierState == CommandKeyBit + OptionKeyBit)
		  switch (keyCode)
		    {
		    case 'h': [NSApp hideOtherApplications: self];	keyCode= -1; break;
		    }
	      }
	    if (keyCode >= 0)
	      {
		if (![event isARepeat])
		  noteKeyboardEvent(keyCode, EventKeyDown, modifierState);
		noteKeyboardEvent(keyCode, EventKeyChar, modifierState);
		recordKeystroke(keyCode);			/* DEPRECATED */
	      }
	    else // key up not interesting
	      [view composeKeyUp: event];
	  }
      }
      break;

    case NSKeyUp:
      {
	int keyCode;
	modifierState= qz2sqModifiers([event modifierFlags]);
	keyCode= [view composeKeyUp: event]; //qz2sqKey(event);
	if (keyCode >= 0)
	  {
	    noteKeyboardEvent(keyCode, EventKeyUp, modifierState);
	    //accentMap= 0;
	  }
      }
      break;

    case NSScrollWheel:
      {
	int keyCode= ([event deltaY] >= 0.0) ? 30 : 31;
	noteKeyboardEvent(keyCode, EventKeyDown, modifierState);
	noteKeyboardEvent(keyCode, EventKeyChar, modifierState);
	noteKeyboardEvent(keyCode, EventKeyUp,   modifierState);
      }
      break;

    case NSAppKitDefined:
      switch ([event subtype])
	{
	case NSApplicationActivatedEventType:
	  active= 1;
	  break;

	case NSApplicationDeactivatedEventType:
	  active= 0;
	  break;
	  // case NSScreenChangedEventType: //xxx this means the window
	  // changed to a different physical screen, which is useless
	  // info (we'd far rather be informed that the current screen's
	  // depth has changed)
	}
      //DPRINTF(("AppKitDefinedEvent subtype %d\n", [event subtype]));
      [super sendEvent: event];
      break;

      // case NSFlagsChanged:
      // case NSApplicationDefined: break;
      // case NSPeriodic: break;
      // case NSCursorUpdate: break;

    default: // almost always NSSystemDefined
      //DPRINTF(("Event type %d subtype %d\n", [event type], [event subtype]));
      [super sendEvent: event];
    }
}


@end // Squeak
