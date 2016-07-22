#ifndef SQ_WIN32_PREFS_H
#define SQ_WIN32_PREFS_H

#define ID_PREF_FIRST 0x0010

#define ID_ABOUT 0x0010
#define ID_DEFERUPDATES 0x0020
#define ID_SHOWCONSOLE 0x0030
#define ID_DBGPRINTSOCKET 0x0040
#define ID_DYNAMICCONSOLE 0x0050
#define ID_REDUCECPUUSAGE 0x0060
#define ID_3BUTTONMOUSE 0x0070
#define ID_DEFAULTPRINTER 0x0080
#define ID_SHOWALLOCATIONS 0x0090
#define ID_REDUCEBACKGROUNDCPU 0x00A0
#define ID_1BUTTONMOUSE 0x00B0
#define ID_DIRECTSOUND 0x00C0

#define ID_FILEACCESS 0x00D0
#define ID_IMAGEWRITE 0x00E0
#define ID_SOCKETACCESS 0x00F0

#define ID_DBGPRINTSTACK 0x0100
#define ID_PRIORITYBOOST 0x0110

#define ID_USEOPENGL 0x0120
#define ID_CASEFILES 0x0130
#define ID_PRINTALLSTACKS 0x0140
#define ID_DUMPPRIMLOG 0x0150

#define ID_PREF_LAST 0x0150

void TrackPrefsMenu(void);
void CreatePrefsMenu(void);
void HandlePrefsMenu(int);
void LoadPreferences(void);
int prefsEnableAltF4Quit(void);
int prefsEnableF2Menu(void);

#if COGVM
# define NICKNAME "Cog"
#elif STACKVM
# define NICKNAME "Stack"
#else
# define NICKNAME "Interpreter"
#endif
#if SPURVM
# define NICKNAME_EXTRA " Spur VM "
#else
# define NICKNAME_EXTRA " VM "
#endif

#define VM_VERSION_TEXT TEXT(NICKNAME) TEXT(NICKNAME_EXTRA) TEXT(VM_VERSION) \
		TEXT(" (release) from ") TEXT(__DATE__) TEXT("\n") \
		TEXT("Compiler: ") TEXT(COMPILER) TEXT(VERSION)
#endif
