/* joystick & graphics tablet support */

/* module initialization/shutdown */
int joystickInit(void);
int joystickShutdown(void);

int joystickRead(int stickIndex);
/*** tablet support ***/
int tabletGetParameters(int cursorIndex, int result[]);
int tabletRead(int cursorIndex, int result[]);
int tabletResultSize(void);
