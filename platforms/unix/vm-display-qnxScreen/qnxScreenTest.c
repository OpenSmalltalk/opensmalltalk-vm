/* qnxScreenTest.c -- test basic rendering */

/*
 source ./sourceMe.sh   ## in Bash Shell
 $QNX_CC $QNX_CFLAGS -trigraphs $QNX_LDFLAGS -lscreen -o screenTest qnxScreenTest.c 
 scp screenTest qnxuser@192.168.TARGET:/home/qnxuser/bin
## Test on QNX RasPi4 Target
*/


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>  /* sleep() */
#include <errno.h>
#include <screen/screen.h>
#include <sys/keycodes.h>

/* Pixels are kept as 32 bits: uint32_t */
typedef uint32_t pixel_t;
#include "Balloon.h"  /* Squeak Balloon image */

/* Forward declarations */
void handleKeyboardEvent(screen_event_t keyEvent);
void handlePointerEvent(screen_event_t keyEvent); /* mouse events */
static void showBalloons( void *bufPtr );
static void showBalloonAt(void *bufPtr, int left, int top);
static inline void putPixel(void *bufPtr, int x, int y, pixel_t pix);
void printKeyFlags(int flags);
void printModifiers(int modifiers);
void printMouseButtons(int buttons);
void printPCKeys(int keyCode);

#define PROMPT "\n*==> "

/* Global loop control */
int keyValue = 0;
int loopCount = 0;
const int maxLoopCount = 80; /*@@TEST@@*/

screen_context_t screenContext = NULL;
screen_event_t   event;
screen_window_t  window;
screen_session_t keyboardSession;
/* screen_pixmap_t  pixMap; */
/* screen_buffer_t  buffers[2]; */
screen_buffer_t	 buffer;
void* bufPointer; /* buffer pointer */
int   stride;     /* buffer stride (bytes per scan line) */
int   size[2];    /* {width,height} in pixels */
const int alwaysTrue = 1;


int main(void) {
  
  int sessionVisible = SCREEN_PROPERTY_VISIBLE; /* => active */
  int usage          = SCREEN_USAGE_NATIVE;
  int eventType	     = 0;
  int objectType     = 0;

  if (screen_create_context(&screenContext,SCREEN_APPLICATION_CONTEXT) < 0) {
    printf("\nqnx screenTest: Event creation failure with errno %d\n", errno);
    return -1;
  }

  if (screen_create_window_type(&window,
				screenContext,
				(SCREEN_APPLICATION_WINDOW |SCREEN_ROOT_WINDOW)) < 0) {
    printf("\nqnx screenTest: Window creation failure with errno %d\n", errno);
    return -1;
  }

  if (screen_create_window_buffers(window, 1) < 0) {
    printf("\nqnx screenTest: Single buffer creation failure with errno %d\n", errno);
    return -1;
  } 

  /* Render Setup */
  screen_set_window_property_iv(window, SCREEN_PROPERTY_FORMAT,
	(const int[]){ SCREEN_FORMAT_RGBX8888 });
  screen_set_window_property_iv(window, SCREEN_PROPERTY_USAGE,
	(const int[]) { SCREEN_USAGE_READ | SCREEN_USAGE_WRITE });
  screen_get_window_property_iv(window, SCREEN_PROPERTY_BUFFER_SIZE,size);
  screen_get_window_property_pv(window, SCREEN_PROPERTY_BUFFERS, (void **)&buffer);
  screen_get_buffer_property_pv(buffer, SCREEN_PROPERTY_POINTER, &bufPointer);
  screen_get_buffer_property_iv(buffer, SCREEN_PROPERTY_STRIDE,  &stride);

  screen_fill(screenContext,
	      buffer,				/* chartreuse2 */
	      (const int[]){ SCREEN_BLIT_COLOR, 0x0076EE00, SCREEN_BLIT_END });

  screen_set_window_property_iv(window, SCREEN_PROPERTY_VISIBLE, &alwaysTrue);

  screen_flush_blits(screenContext, SCREEN_WAIT_IDLE);
  screen_post_window(window, buffer, 0, NULL, SCREEN_WAIT_IDLE);

  sleep( 1 );

  showBalloons(bufPointer);
  screen_flush_blits(screenContext, SCREEN_WAIT_IDLE);
  screen_post_window(window, buffer, 0, NULL, SCREEN_WAIT_IDLE);

  sleep( 2 ) ; /* let the user see it */
  
  /* Keyboard & Mouse Pointer */
  /* if (screen_create_session_type(&keyboardSession,screenContext,SCREEN_EVENT_KEYBOARD) */
  /*     < 0) { */
  /*   printf("\nqnx screenTest: Keyboard Session creation failure with errno %d\n", errno); */
  /*   return -1; */
  /* } */
  /* screen_set_session_property_iv(keyboardSession, SCREEN_PROPERTY_VISIBLE, &alwaysTrue); */


  /* FOR THE USER */
  
  if (screen_create_event(&event) != 0) {
    printf("\nqnx screenTest: Event creation failure with errno %d\n", errno);
    return -1;
  }

  printf("\nQNX Keyboard test.  Type 'x' to exit\n");
  printf(PROMPT);
  
  while ((keyValue != KEYCODE_X) && (loopCount < maxLoopCount)) {

    if (screen_get_event( screenContext, event, 10000000000) != 0) {
      printf("\nqnx screenTest: screen_get_event() errno %d\n", errno);
      break;
      /* ~0L => Don't wait, else nanoSecs to sleep */
    }

    if (screen_get_event_property_iv(event,SCREEN_PROPERTY_OBJECT_TYPE,&objectType)
	!= 0) {
      printf("\nEvent Object type failure.  Errno = 0x%lx", errno);
      break;
    } else {
      printf("\nEvent Object Type: 0x%lx", objectType);
      switch (objectType) {
      case SCREEN_OBJECT_TYPE_CONTEXT:
	printf(": Context");
	break;
      case SCREEN_OBJECT_TYPE_GROUP:
	printf(": Group");
	break;
      case SCREEN_OBJECT_TYPE_DISPLAY:
	printf(": Display");
	break;
      case SCREEN_OBJECT_TYPE_DEVICE:
	printf(": Device");
	break;
      case SCREEN_OBJECT_TYPE_PIXMAP:
	printf(": Pixmap");
	break;
      case SCREEN_OBJECT_TYPE_SESSION:
	printf(": Session");
	break;
      case SCREEN_OBJECT_TYPE_STREAM:
	printf(": Stream");
	break;
      case SCREEN_OBJECT_TYPE_WINDOW:
	printf(": Window");
	break;
      default:
	break;
      }
    }

    if (objectType == SCREEN_OBJECT_TYPE_WINDOW) {

      loopCount += 1;

      if (screen_get_event_property_iv(event,SCREEN_PROPERTY_TYPE,&eventType) != 0) {
	printf("\nEvent type failure.  Errno = 0x%lx", errno);
	break;
      }
      
      switch (eventType) {

      case SCREEN_EVENT_NONE:
	printf("\nGot NULL Event");
	break;
	
      case SCREEN_EVENT_KEYBOARD:
	/* printf("\nGot KEYBOARD Event"); */
	handleKeyboardEvent(event);
	break;

      case SCREEN_EVENT_POINTER:
	/* printf("\nGot MOUSE POINTER Event"); */
	handlePointerEvent(event);
	break;

      case SCREEN_EVENT_GAMEPAD:
      case SCREEN_EVENT_JOYSTICK:
	printf("\nGot Joystick/Game Event");
	/* handleJoystickEvent(event); */
	break;
      default:
	printf("\nGot UNHANDLED Event Type: 0x%lx", eventType);
	break;
      }
    }
  }

  if (loopCount >= maxLoopCount)
    printf("\nTimeout");
  printf("\nExiting Screen Test\n\n");

  /*  screen_destroy_session( keyboardSession ); */
  screen_destroy_window( window );
  screen_destroy_context( screenContext );
   
  return 0;
}


static void showBalloons( void *bufPtr ) {
  int x, y;

  x = size[0] / 2;
  y = size[1] / 2;
  showBalloonAt(bufPtr,x,y) ;
  showBalloonAt(bufPtr,x+(x/2),y-(y/2)) ;
  showBalloonAt(bufPtr,x+(x/2),y+(y/2)) ;
  showBalloonAt(bufPtr,x-(x/2),y-(y/2)) ;
  showBalloonAt(bufPtr,x-(x/2),y+(y/2)) ;
}
  

static void showBalloonAt(void *bufPtr, int left, int top)
{
  int x, y;
  char *data = balloon_data, pixel[4];
  pixel_t myPixel;
  int balloon_bytes_per_pixel = 4; /* 32 bits */

  /* Center Balloon on x,y point */
  left -= balloon_width_pixels  / 2;
  top  -= balloon_height_pixels / 2;
  for (y = 0; y < balloon_height_pixels; y++) {
    for (x = 0; x < balloon_width_pixels; x++) {
      /* extract RGB values from Balloon data */
      BALLOON_PIXEL( data, pixel );
      /* above side effect: data += balloon_bytes_per_pixel */
      putPixel(bufPtr,
	       left + x,
	       top + y,
	       ((pixel[0] << 16) | (pixel[1] << 8) | pixel[2])); /* RGB */
    }
  }
}

static inline void putPixel(void *bufPtr, int x, int y, pixel_t pix)
{
  if ((x >= 0) && (y >= 0) && (x < size[0]) && (y < size[1])) /* size[width,height] */
    {
      *((pixel_t *)(bufPtr
		    + (x  * 4) /* 4 = (32/8) = (bits-per-pixel/bits-per-byte)  */
		    + (y * stride)))
	= pix;
    }
}

/* KEYBOARD */

void
handleKeyboardEvent(screen_event_t keyEvent) {
/*
Event Type: SCREEN_EVENT_KEYBOARD

    SCREEN_PROPERTY_DEVICE
    SCREEN_PROPERTY_FLAGS
    SCREEN_PROPERTY_KEY_ALTERNATE_SYM
    SCREEN_PROPERTY_KEY_CAP
    SCREEN_PROPERTY_MODIFIERS
    SCREEN_PROPERTY_SCAN
    SCREEN_PROPERTY_SEQUENCE_ID
    SCREEN_PROPERTY_SYM 	  
*/
/* NB: keyValue is global loop flag */
  int keyFlags = 0;
  int keyModifiers = 0;
  int keyCap = 0;
  int keySym = 0;
  int keyScan = 0;

  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_SYM,   &keyValue);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_FLAGS, &keyFlags);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_MODIFIERS, &keyModifiers);

  if ((keyValue > 0x20) && (keyValue < 0x7F))
    printf("\n ASCII '%c' ", keyValue);
  else
    printf("\n");
  printPCKeys(keyValue);  /* NON-ASII, e.g. keypadkeys, home, .. */
  printModifiers(keyModifiers); /* SHIFT, etc. */
  printf(" KeyCode=0x%lx ", keyValue);
  printKeyFlags(keyFlags);

  if (keyFlags & SCREEN_FLAG_CAP_VALID) {
      screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_KEY_CAP, &keyCap);
      printf(" keyCap=0x%lx", keyCap);
  }
  
  if (keyFlags & SCREEN_FLAG_SYM_VALID) {
      screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_SYM, &keySym);
      printf(" keySym=0x%lx", keySym);
  }

  if (keyFlags & SCREEN_FLAG_SCAN_VALID) {
      screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_SCAN, &keyScan);
      printf(" keyScan=0x%lx", keyScan);
  }

  printf(PROMPT);
}

void printKeyFlags(int flags) {
  
  if (flags & SCREEN_FLAG_KEY_DOWN)
    printf("KeyDOWN ");
  else
    printf("KeyUP ");

  if (flags & SCREEN_FLAG_KEY_REPEAT)
    printf("KeyRepeat ");

  if (flags & SCREEN_FLAG_SCAN_VALID)
    printf("KeyScanValid ");

  if (flags & SCREEN_FLAG_SYM_VALID)
    printf("KeySym ");

  if (flags & SCREEN_FLAG_CAP_VALID)
    printf("KeyCap ");

  if (flags & SCREEN_FLAG_DISPLACEMENT_VALID)
    printf("KeyDisplacment ");

  if (flags & SCREEN_FLAG_POSITION_VALID)
    printf("KeyPosition ");

  if (flags & SCREEN_FLAG_SOURCE_POSITION_VALID)
    printf("KeySourcePosition ");

  if (flags & SCREEN_FLAG_SIZE_VALID)
    printf("KeySize ");
}

/* MOUSE POINTER */

void
handlePointerEvent(screen_event_t keyEvent) {
/*
  Event Type: SCREEN_EVENT_POINTER

    SCREEN_PROPERTY_BUTTONS
    SCREEN_PROPERTY_DEVICE
    SCREEN_PROPERTY_MODIFIERS
    SCREEN_PROPERTY_MOUSE_HORIZONTAL_WHEEL
    SCREEN_PROPERTY_MOUSE_WHEEL
    SCREEN_PROPERTY_POSITION
    SCREEN_PROPERTY_SOURCE_POSITION 
*/
/* NB: keyValue is global loop flag */
  int buttons = 0;
  int modifiers = 0;
  int wheelHoriz = 0;
  int wheelVert  = 0;
  int position[2];
  int sourcePosition[2];

  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_BUTTONS, &buttons);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_MODIFIERS, &modifiers);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_POSITION,
			       (int *)&position);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_SOURCE_POSITION,
			       (int *)&sourcePosition);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_MOUSE_HORIZONTAL_WHEEL,
			       &wheelHoriz);
  screen_get_event_property_iv(keyEvent, SCREEN_PROPERTY_MOUSE_WHEEL,
			       &wheelVert);

  printf("\n Mouse Point @ (%ld,%ld) ", position[0], position[1]);
  printMouseButtons(buttons);
  printModifiers(modifiers);
  if (wheelHoriz != 0)
    printf("\n Horizontal wheel clicks = %d", wheelHoriz); 
  if (wheelVert != 0)
    printf("\n Vertical wheel clicks = %d", wheelVert); 
}

void printMouseButtons(int buttons) {
  /* Just a bitmask */
  if (buttons != 0) {
    printf(" MouseButton: ");
    if (1 & buttons) printf("Left ");
    if (2 & buttons) printf("Middle ");
    if (4 & buttons) printf("Right ");
  }
}

void printModifiers(int modifiers) 
{
  if (modifiers & KEYMOD_SHIFT)
    printf("SHIFT ");
  if (modifiers & KEYMOD_CTRL)
    printf("CTRL ");
  if (modifiers & KEYMOD_ALT)
    printf("ALT ");
  if (modifiers & KEYMOD_ALTGR)
    printf("ALTGR ");
  if (modifiers & KEYMOD_SHL3)
    printf("SHL3 ");
  if (modifiers & KEYMOD_MOD6)
    printf("MOD6 ");
  if (modifiers & KEYMOD_MOD7)
    printf("MOD7 ");
  if (modifiers & KEYMOD_MOD8)
    printf("MOD8 ");
  if (modifiers & KEYMOD_SHIFT_LOCK)
    printf("ShiftLock ");
  if (modifiers & KEYMOD_CTRL_LOCK)
    printf("CTRLLock ");
  if (modifiers & KEYMOD_ALT_LOCK)
    printf("ALTLock ");
  if (modifiers & KEYMOD_ALTGR_LOCK)
    printf("ALTGRLock ");
  if (modifiers & KEYMOD_SHL3_LOCK)
    printf("SHL3Lock ");
  if (modifiers & KEYMOD_MOD6_LOCK)
    printf("MOD6Lock ");
  if (modifiers & KEYMOD_MOD7_LOCK)
    printf("MOD7Lock ");
  if (modifiers & KEYMOD_MOD8_LOCK)
    printf("MOD8Lock ");
  if (modifiers & KEYMOD_CAPS_LOCK)
    printf("CapsLock ");
  if (modifiers & KEYMOD_NUM_LOCK)
    printf("NumLock ");
  if (modifiers & KEYMOD_SCROLL_LOCK )
    printf("ScrollLock  ");
}

void printPCKeys(int keyCode)
{
  if ((keyCode > KEYCODE_PC_KEYS) && (keyCode <= KEYCODE_F12)) {
    switch (keyCode) {
    case KEYCODE_PAUSE:
      printf("PAUSE ");
      break;
    case KEYCODE_SCROLL_LOCK:
      printf("SCROLL_LOCK ");
      break;
    case KEYCODE_PRINT:
      printf("PRINT ");
      break;
    case KEYCODE_SYSREQ:
      printf("SYSREQ ");
      break;
    case KEYCODE_BREAK:
      printf("BREAK ");
      break;
    case KEYCODE_ESCAPE:
      printf("ESCAPE ");
      break;
    case KEYCODE_BACKSPACE:
      printf("BACKSPACE ");
      break;
    case KEYCODE_TAB:
      printf("TAB ");
      break;
    case KEYCODE_BACK_TAB:
      printf("BACK_TAB ");
      break;
    case KEYCODE_RETURN:
      printf("RETURN ");
      break;
    case KEYCODE_CAPS_LOCK:
      printf("CAPS_LOCK ");
      break;
    case KEYCODE_LEFT_SHIFT:
      printf("LEFT_SHIFT ");
      break;
    case KEYCODE_RIGHT_SHIFT:
      printf("RIGHT_SHIFT ");
      break;
    case KEYCODE_LEFT_CTRL:
      printf("LEFT_CTRL ");
      break;
    case KEYCODE_RIGHT_CTRL:
      printf("RIGHT_CTRL ");
      break;
    case KEYCODE_LEFT_ALT:
      printf("LEFT_ALT ");
      break;
    case KEYCODE_RIGHT_ALT:
      printf("RIGHT_ALT ");
      break;
    case KEYCODE_MENU:
      printf("MENU ");
      break;
    case KEYCODE_LEFT_HYPER:
      printf("LEFT_HYPER ");
      break;
    case KEYCODE_RIGHT_HYPER:
      printf("RIGHT_HYPER ");
      break;
    case KEYCODE_INSERT:
      printf("INSERT ");
      break;
    case KEYCODE_HOME:
      printf("HOME ");
      break;
    case KEYCODE_PG_UP:
      printf("PG_UP ");
      break;
    case KEYCODE_DELETE:
      printf("DELETE ");
      break;
    case KEYCODE_END:
      printf("END ");
      break;
    case KEYCODE_PG_DOWN:
      printf("PG_DOWN ");
      break;
    case KEYCODE_LEFT:
      printf("LEFT ");
      break;
    case KEYCODE_RIGHT:
      printf("RIGHT ");
      break;
    case KEYCODE_UP:
      printf("UP ");
      break;
    case KEYCODE_DOWN:
      printf("DOWN ");
      break;
    case KEYCODE_NUM_LOCK:
      printf("NUM_LOCK ");
      break;
    case KEYCODE_KP_PLUS:
      printf("KP_PLUS ");
      break;
    case KEYCODE_KP_MINUS:
      printf("KP_MINUS ");
      break;
    case KEYCODE_KP_MULTIPLY:
      printf("KP_MULTIPLY ");
      break;
    case KEYCODE_KP_DIVIDE:
      printf("KP_DIVIDE ");
      break;
    case KEYCODE_KP_ENTER:
      printf("KP_ENTER ");
      break;
    case KEYCODE_KP_HOME:
      printf("KP_HOME ");
      break;
    case KEYCODE_KP_UP:
      printf("KP_UP ");
      break;
    case KEYCODE_KP_PG_UP:
      printf("KP_PG_UP ");
      break;
    case KEYCODE_KP_LEFT:
      printf("KP_LEFT ");
      break;
    case KEYCODE_KP_FIVE:
      printf("KP_FIVE ");
      break;
    case KEYCODE_KP_RIGHT:
      printf("KP_RIGHT ");
      break;
    case KEYCODE_KP_END:
      printf("KP_END ");
      break;
    case KEYCODE_KP_DOWN:
      printf("KP_DOWN ");
      break;
    case KEYCODE_KP_PG_DOWN:
      printf("KP_PG_DOWN ");
      break;
    case KEYCODE_KP_INSERT:
      printf("KP_INSERT ");
      break;
    case KEYCODE_KP_DELETE:
      printf("KP_DELETE ");
      break;
    case KEYCODE_F1:
      printf("F1 ");
      break;
    case KEYCODE_F2:
      printf("F2 ");
      break;
    case KEYCODE_F3:
      printf("F3 ");
      break;
    case KEYCODE_F4:
      printf("F4 ");
      break;
    case KEYCODE_F5:
      printf("F5 ");
      break;
    case KEYCODE_F6:
      printf("F6 ");
      break;
    case KEYCODE_F7:
      printf("F7 ");
      break;
    case KEYCODE_F8:
      printf("F8 ");
      break;
    case KEYCODE_F9:
      printf("F9 ");
      break;
    case KEYCODE_F10:
      printf("F10 ");
      break;
    case KEYCODE_F11:
      printf("F11 ");
      break;
    case KEYCODE_F12:
      printf("F12 ");
      break;
    default:
      break;
    }
  }
}


/* --- E O F --- */
