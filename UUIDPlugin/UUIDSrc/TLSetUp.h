/*------------------------------------------------------------
| NAME: TLSetUp.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to Mac set up functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 03.13.94 from Ak2Setup.h
------------------------------------------------------------*/
#ifndef _SETUP_H_
#define _SETUP_H_


#define     EnvironsVersion 1   
            /* This controls the version of SysEnvirons used. */

#define     ToolTrapBit     11              
            /* this bit is on for Tool traps */
            
#define     ToolTrapBitMask 1<<ToolTrapBit  
            /* mask to test ToolTrap bit */

/*               
rUserAlert          EQU 129         ; error alert for user
SuspendResume       EQU 1           ; the suspend/resume event number of an OSEvent
NoEvents            EQU 0           ; no events mask
ExtremeNeg          EQU -32768      ; for wide open rects and regions, see AdjustCursor
ExtremePos          EQU 32767-1     ; -1 is because of a bug in regions, see AdjustCursor
DITopLeft           EQU $00500070   ; position of Disk Init dialogs
*/

/* This is the minimum result from the following equation:
*
*   ApplLimit - ApplZone = minimum heap size
*
* for the application to run. It will insure that enough 
* memory will be around for reasonable-sized scraps, FKEYs, 
* etc. to exist with the application, and still give the 
* application some 'breathing room'. To derive this number, 
* we ran under a MultiFinder partition that was our requested 
* minimum size, as given in the 'SIZE' resource.
*/

#define MinHeap 50*1024 /*  minimum heap size in bytes */

/* This is the minimum exceptable result from PurgeSpace, 
* when called at initialization time, for the application to 
* run. This number acts as a double-check to insure that there 
* really is enough memory for the application to run, including 
* what has been taken up already by pre-loaded resources, 
* the scrap, code, and other sundry memory blocks.
*/
#define MinSpace 8*1024     /* minimum stack space in bytes */

extern u32      IsDiskLocked;
                // Set by 'SaveInstalledVolumeCreationDateList'
                // if the disk is locked.

extern u32      IsForcedExit;
                // Set by 'ForcedExit' so that 'cancel' options
                // are removed.

extern u32      IsTempMemCallsAvailable;
                // If the TempMemCalls feature is available,
                // this will be non-zero.

extern u32      IsGestaltAvailable;
                // 1 if the Gestalt Toolbox call is available.
                                 
extern u32      IsSystem7Available;
                // 1 if System 7 functions are is available.
                
extern u32      IsAppleEventsSupported;
                // 1 if Apple events are supported in this
                // environment.

extern s16      MyResourceFileReferenceNumber;
                // This is the reference number of the 
                // application's resource file.
                 
extern u32      TypeOfCPU;
                // Identifies the type number of the currently
                // running CPU chip, one of the following values:
enum             
{
    CPU68000    = 68000,        // Various 68k CPUs...
    CPU68010    = 68010,
    CPU68020    = 68020,
    CPU68030    = 68030,
    CPU68040    = 68040,
    CPU601      = 0x0101,       // IBM 601                                              */
    CPU603      = 0x0103,
    CPU604      = 0x0104,
    CPU603e     = 0x0106,
    CPU603ev    = 0x0107,
    CPU750      = 0x0108,       // Also 740 - "G3".
    CPU604e     = 0x0109,
    CPU604ev    = 0x010A        // Mach 5, 250Mhz and up.
};
                 
extern u32      TypeOfCPUFamily;
                // Identifies the CPU family of the currently
                // running CPU chip, one of the following values:
enum
{
    CPUFamily68000   = 0,
    CPUFamilyPowerPC = 1
};
                 
extern u32      MacOSVersion;
                // Identifies the version number of the currently
                // running MacOS.  This number is represented as
                // two byte-long numbers.  For example, if version
                // 6.0.4 is running, then the value is 0x00000604.
                
extern u32      QuickDrawVersion;
                // Identifies the version number of the currently
                // running Quickdraw, one of the following values:

// QuickDraw version number interpretation is as follows:
// The high-order byte gives the major revision number and the
// low-order byte gives the minor revision.  
//
// Major revisions are:
//
//    0 - Original QuickDraw
//    1 - 8-bit Color QuickDraw
//    2 - 32-bit QuickDraw with direct-pixel capability.
// 
enum
{
    QD_1Bit      = 0,      
    QD_8Bit      = 0x100,
    QD_32Bit     = 0x200,
    QD_32Bit_11  = 0x210,
    QD_32Bit_12  = 0x220,
    QD_32Bit_13  = 0x230
};

extern u32      IsColorDisplay;
                // 1 if there is at least one color display
                // device attached to the current system.

extern SysEnvRec    SystemEnvironment;
                /* Holds the system environment record:
                 *
                 * struct SysEnvRec 
                 * {
                 *      short environsVersion;
                 *      short machineType;
                 *      short systemVersion;
                 *      short processor;
                 *      Boolean hasFPU;
                 *      Boolean hasColorQD;
                 *      short keyBoardType;
                 *      short atDrvrVersNum;
                 *      short sysVRefNum;
                 *  };
                 *
                 * See p. V-6 of Inside Mac & <OSUtils.h>
                 */

void        IdentifyEnvironment();
u32         IsTrapAvailable(s16);
void        MainCleanUp();
void        MainSetUp();
pascal void SystemErrorExit();






#endif
