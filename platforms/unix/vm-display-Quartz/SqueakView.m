@implementation SqueakView

- (BOOL) isOpaque		{ return YES; }
- (BOOL) isFlipped		{ return YES; }
- (BOOL) acceptsFirstResponder	{ return YES; }
- (BOOL) becomeFirstResponder	{ return YES; }
- (BOOL) resignFirstResponder	{ return NO; }

- (void) renewGState
{
  printf("\nRENEW GSTATE\n\n");
  [super renewGState];
}

static NSRange inputMark;
static NSRange inputSelection;
static int     inputCharCode;

- (id) initWithFrame: (NSRect)frame
{
  id result= [super initWithFrame: frame];
  if (self == result)
    [self registerForDraggedTypes:
	    [NSArray arrayWithObjects:
		       NSFilenamesPboardType, nil]];
  inputCharCode=  -1;
  inputMark=	  NSMakeRange(NSNotFound, 0);
  inputSelection= NSMakeRange(0, 0);
  return result;
}


- (void) setFrame: (NSRect)rect
{
  lock(display);
  [super setFrame: rect];
  if ([self inLiveResize])
    {
#    if (RESIZE_IN_TITLE)
      display_winSetName(shortImageName);
#    endif
    }
  else
    if ([self qdPort])
      updatePix();
  unlock(display);
}


- (void) drawRect: (NSRect)rect		// view already has focus
{
  printf("drawRect:\n");
  if ([self inLiveResize])
    {
      [[NSColor whiteColor] set];
      NSRectFill(rect);
      drawImage([[NSGraphicsContext currentContext] graphicsPort], 0);
    }
  else
    {
      if (!pixBase)
	{
	  printf("drawRect: calling updatePix\n");
	  assert([self qdPort]);
	  updatePix();
	}
      fullDisplayUpdate();
    }
}

- (void) viewWillStartLiveResize
{
  captureImage(1);
  [win setShowsResizeIndicator: YES];
  
#if (RESIZE_IN_TITLE)
  showExtent= 1;
  display_winSetName(shortImageName);
#endif
  pixWidth= 0;
  pixHeight= 0;
}

- (void) viewDidEndLiveResize
{
  releaseImage(1);
  [win setShowsResizeIndicator: NO];
#if (RESIZE_IN_TITLE)
  showExtent= 0;
  display_winSetName(shortImageName);
#endif
  updatePix();
  fullDisplayUpdate(); // gets rid of the resize icon if window didn't resize
}


- (int) draggingEntered: (id<NSDraggingInfo>)info
{
  if ((dragCount == 0) // cannot drag again until previous drag completes
      && ([info draggingSourceOperationMask] & NSDragOperationCopy))
    {
      int count= [[[info draggingPasteboard]
		    propertyListForType: NSFilenamesPboardType] count];
      noteMousePoint([info draggingLocation]);
      noteDragEvent(SQDragEnter, dragCount= count);
      return NSDragOperationCopy;
    }
  return NSDragOperationNone;
}

- (int) draggingUpdated: (id<NSDraggingInfo>)info
{
  noteMousePoint([info draggingLocation]);
  noteDragEvent(SQDragMove, dragCount);
  return NSDragOperationCopy;
}

- (void) draggingExited: (id<NSDraggingInfo>)info
{
  noteMousePoint([info draggingLocation]);
  noteDragEvent(SQDragLeave, dragCount);
  dragCount= 0;
}

- (BOOL) performDragOperation: (id<NSDraggingInfo>)info
{
  NSPasteboard *pboard= [info draggingPasteboard];
  noteMousePoint([info draggingLocation]);
  if ([[pboard types] containsObject: NSFilenamesPboardType])
    {
      NSArray *files= [pboard propertyListForType: NSFilenamesPboardType];
      int i;
      if (uxDropFileCount)
	{
	  assert(uxDropFileNames);
	  for (i= 0;  i < uxDropFileCount;  ++i)
	    free(uxDropFileNames[i]);
	  free(uxDropFileNames);
	  uxDropFileNames= 0;
	}
      if ((  (!(uxDropFileCount= [files count])))
	  || (!(uxDropFileNames= (char **)malloc(uxDropFileCount * sizeof(char *)))))
	{
	  uxDropFileCount= 0;
	  return NO;
	}
      for (i= 0;  i < uxDropFileCount;  ++i)
	uxDropFileNames[i]= strdup([[files objectAtIndex: i] cString]);
    }
  noteDragEvent(SQDragDrop, uxDropFileCount);
  dragCount= 0;

  return YES;	// under some duress, I might add (see sqUxDragDrop.c)
}


enum { KeyMapSize= 32 };

typedef struct
{
  int keyCode;
  int keyChar;
} KeyMapping;

static KeyMapping keyMap[KeyMapSize];

static int keyMapSize=	   0;
static int inputCharCode= -1;

static int addToKeyMap(int keyCode, int keyChar)
{
  if (keyMapSize > KeyMapSize) { fprintf(stderr, "keymap overflow\n");  return -1; }
  keyMap[keyMapSize++]= (KeyMapping){ keyCode, keyChar };
  return keyChar;
}

static int indexInKeyMap(int keyCode)
{
  int i;
  for (i= 0;  i < keyMapSize;  ++i)
    if (keyMap[i].keyCode == keyCode)
      return i;
  return -1;
}

static int findInKeyMap(int keyCode)
{
  int idx= indexInKeyMap(keyCode);
  return (idx >= 0) ? keyMap[idx].keyChar : -1;
}

static int removeFromKeyMap(int keyCode)
{
  int idx= indexInKeyMap(keyCode);
  int keyChar= -1;
  if (idx < 0) { fprintf(stderr, "keymap underflow\n");  return -1; }
  keyChar= keyMap[idx].keyChar;
  for (; idx < keyMapSize - 1;  ++idx)
    keyMap[idx]= keyMap[idx + 1];
  --keyMapSize;
  return keyChar;
}


// the following (to @end) must be installed in the first responder

- (int) composeKeyDown: (NSEvent *)event
{
  int keyCode= [event keyCode];
  inputCharCode= -1;

  if (modifierState & CommandKeyBit)
    inputCharCode= qz2sqKey(event);
  else
    {
      if ([event isARepeat])
	{
	  int keyChar= findInKeyMap(keyCode);
	  //printf("%d REP keyCode %x -> keyChar %x\n", keyMapSize, keyCode, keyChar);
	  return keyChar;
	}
      else
	{
	  [self interpretKeyEvents: [NSArray arrayWithObject: event]];
	  if (inputCharCode < 0)
	    inputCharCode= qz2sqKey(event);
	}
    }

  if (inputCharCode >= 0)
    {
      //printf("%d ADD keyCode %x -> keyChar %x\n", keyMapSize, keyCode, inputCharCode);
      addToKeyMap(keyCode, inputCharCode);
    }

  return inputCharCode;
}

- (int) composeKeyUp: (NSEvent *)event
{
  int keyCode= [event keyCode];
  int keyChar= removeFromKeyMap(keyCode);
  //printf("%d DEL keyCode %x -> charCode %x\n", keyMapSize, keyCode, keyChar);
  return keyChar;
}

- (void) insertText: (NSString *)text
{
  //printf("insertText\n");
  inputMark= NSMakeRange(NSNotFound, 0);
  inputSelection= NSMakeRange(0, 0);
  if ([text length])
    {
      UInt8 buf[4];
      CFIndex nUsed;
      if (CFStringGetBytes((CFStringRef)text, CFRangeMake(0, CFStringGetLength((CFStringRef)text)),
			   kCFStringEncodingMacRoman, 0, FALSE,
			   buf, sizeof(buf), &nUsed))
	inputCharCode= buf[0];
    }
}

// ParagraphEditor's map looks like this:
// 
//   0	noop cursorHome noop noop cursorEnd noop noop noop
//   8	backspace noop noop cursorPageUp cursorPageDown crWithIndent noop noop
//  16	noop noop noop noop noop noop noop noop
//  24	noop noop noop offerMenuFromEsc cursorLeft cursorRight cursorUp cursorDown
// 127  forwardDelete

- (void) doCommandBySelector: (SEL)aSelector
{
  // why doesn't @selector() reduce to a constant??
# define encode(c, s)  if (aSelector == @selector(s)) inputCharCode= c
  // my (subjective) approximation of usage frequency...
       encode(  8, deleteBackward:);
  else encode( 13, insertNewline:);
  else encode(  9, insertTab:);
  else encode( 28, moveLeft:);
  else encode( 29, moveRight:);
  else encode( 30, moveUp:);
  else encode( 31, moveDown:);
  else encode( 11, pageUp:);
  else encode( 12, pageDown:);
  else encode(  1, moveToBeginningOfDocument:);
  else encode(  4, moveToEndOfDocument:);
  else encode(127, deleteForward:);
  else encode( 27, _cancelKey:);
  else
    printf("doCommandBySelector: %s\n", sel_getName(aSelector));
# undef encode
}

- (void) setMarkedText: (id)aString selectedRange: (NSRange)selRange
{
  inputMark= NSMakeRange(0, 1);
  inputSelection= NSMakeRange(NSNotFound, 0);
}

- (void)		 unmarkText						{ inputMark= NSMakeRange(NSNotFound, 0); }
- (BOOL)		 hasMarkedText						{ return inputMark.location != NSNotFound; }
- (long)		 conversationIdentifier					{ return (long)self; }
- (NSAttributedString *) attributedSubstringFromRange: (NSRange)theRange	{ return nil; }
- (NSRange)		 markedRange						{ return inputMark; }
- (NSRange)		 selectedRange						{ return inputSelection; }
- (NSRect)		 firstRectForCharacterRange: (NSRange)theRange		{ return NSMakeRect(0,0, 0,0); }
- (unsigned int)	 characterIndexForPoint: (NSPoint)thePoint		{ return 0; }
- (NSArray *)		 validAttributesForMarkedText				{ return nil; }

@end
