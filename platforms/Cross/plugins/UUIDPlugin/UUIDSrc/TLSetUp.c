/*------------------------------------------------------------
| TLSetUp.c
|-------------------------------------------------------------
|
| PURPOSE: To provide set up functions for a Mac application.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 01.27.94
------------------------------------------------------------*/

#include "TLTarget.h"

#ifdef FOR_MACOS

#include <stdio.h>

#include <Traps.h>
#include <OSUtils.h>  // For SysEnvirons.
#include <SegLoad.h>
#include <Resources.h>
#include <Dialogs.h>
#include <Gestalt.h>

#include "TLTypes.h"
#include "TimePPC.h"
#include "TLBit.h"
#include "TLPacking.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLList.h"
#include "TLWin.h"
#include "TLModes.h"
#include "TLByteBuffer.h"
#include "TLFile.h"   
#include "TLMacOSMem.h"
#include "TLLog.h"
#include "TLCursor.h"
#include "TLMenu.h"
#include "TLWin.h"
//#include "TLScrollText.h"
//#include "TLTextEditor.h"
#include "TLRandom.h"
#include "TLSubRandom.h"

#ifdef IS_NETWORK_AWARE
#include "TLNetAccess.h"
#include "TLNetIdle.h"
#endif

#include "TLUUID.h"
#include "TLSetUp.h"

u32             IsForcedExit;
                // Set by 'ForcedExit' so that 'cancel' options
                // are removed.

u32             IsDiskLocked = 0;
                // Set by 'SaveInstalledVolumeCreationDateList'
                // if the disk is locked.

u32             IsTempMemCallsAvailable = 0;
                // If the TempMemCalls feature is available,
                // this will be non-zero.

u32             IsGestaltAvailable;
                // 1 if the Gestalt Toolbox call is available.
                                 
u32             IsSystem7Available;
                // 1 if System 7 functions are is available.
                
u32             IsAppleEventsSupported;
                // 1 if Apple events are supported in this
                // environment.
                
s16             MyResourceFileReferenceNumber;
                // This is the reference number of the 
                // application's resource file.
                 
u32             TypeOfCPU;
                // Contains the type number of the CPU chip:
                // see 'TLSetUp.h' for constants.
                
u32             TypeOfCPUFamily;
                // Identifies the CPU family of the currently
                // running CPU chip: see 'TLSetUp.h' for constants.

u32             MacOSVersion;
                // Identifies the version number of the currently
                // running MacOS.  This number is represented as
                // two byte-long numbers.  For example, if version
                // 6.0.4 is running, then the value is 0x00000604.

u32             QuickDrawVersion;
                // Identifies the version number of the currently
                // running Quickdraw, one of the following values:

u32             IsColorDisplay = 1; //TL make this default to 0 later and add test for color display.
                // 1 if there is at least one color display
                // device attached to the current system.


SysEnvRec       SystemEnvironment;
                // Holds the system environment record:
                //
                // struct SysEnvRec 
                // {
                //      short environsVersion;
                //      short machineType;
                //      short systemVersion;
                //      short processor;
                //      Boolean hasFPU;
                //      Boolean hasColorQD;
                //      short keyBoardType;
                //      short atDrvrVersNum;
                //      short sysVRefNum;
                //  };
                //
                // See p. V-6 of Inside Mac & <OSUtils.h>
                //

/*------------------------------------------------------------
| IdentifyEnvironment
|-------------------------------------------------------------
|
| PURPOSE: To identify the environment in which Ak2 runs.
|
| DESCRIPTION: Sets the variables used to describe the
| environment.
|
|   This routine detects the presence or absence of 
|   MultiFinder and sets flags that will condition how the 
|   event loop behaves. Also verifies that enough memory is 
|   present to run.
|
|   If an error is detected, instead of merely doing an 
|   ExitToShell, which leaves the user with nothing to go on, 
|   alert_user is called, which puts up a simple alert that 
|   just says an error occurred and then calls ExitToShell.  
|   To keep things simple, the alert does not state the 
|   specific cause of the error, but a more informative 
|   alert may be appropriate later.  Since there is no other 
|   cleanup needed at this point if an error is detected, 
|   this form of error-handling is acceptable. If more 
|   sophisticated error recovery is needed, a signal 
|   mechanism, such as is provided by Signals, can be used.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Follows initialization of Toolbox Managers.
|          List system is set up for install check.
|
| HISTORY: 12.19.90 from Sample.inc1.a 
|                   (formerly "Initialize")
|          12.30.90 added AN_TypeOfCPU setting
|          03.04.93 added 68040 identification 
|                   (see also 'sysequ.a')
|          01.26.94 converted from Sage.a
|          12.09.96 converted from 'SysEnvirons' call to
|                   'Gestalt'.
|          08.28.98 Fixed bit test for Apple Events.
|          09.07.98 Added 'IdentifyThePackingOrder'.
|          12.06.98 Added 'SetUpTimePPC()'.
------------------------------------------------------------*/
void
IdentifyEnvironment()
{
    OSErr   err;
    s32     result;
    
    // Identify how binary numbers are stored in memory.
    IdentifyThePackingOrder();
    
    // Save the reference number to the application's 
    // resource file.
    MyResourceFileReferenceNumber = CurResFile();

    // The application starts up in foreground mode.
    IsInForegroundMode = 1;
    
    // Test for 'WaitNextEvent' is available.
    IsWaitNextEventAvailable = IsTrapAvailable( _WaitNextEvent );
 
    // Test for MultiFinder Temp Mem Calls. 
    IsTempMemCallsAvailable =  IsTrapAvailable( _OSDispatch );
    
    // Test for Gestalt Manager.
    // From Inside Mac Volume VI, page 3-32:
    // "...the Gestalt Manager exists only in system 
    //  software versions 6.0.4 and later... "
    IsGestaltAvailable = IsTrapAvailable( _Gestalt );
    
    // If Gestalt Manager is not available.
    if( IsGestaltAvailable == 0 ) 
    {
        // These conditions are implied by the absence of
        // the Gestalt Manager:
        IsSystem7Available     = 0;
        IsAppleEventsSupported = 0;
        
        // Could put more specific CPU identification test here.
        TypeOfCPU              = CPU68000;
        TypeOfCPUFamily        = CPUFamily68000;
        
        // Need to determine MacOS version here.
        // MacOSVersion = ?
        
        // Need to determine the QuickDraw version here.
        // QuickDrawVersion = ?
        
        
        // All done.
        return;
    }
    
    //
    // Gestalt Manager is available for the remainder of the
    // procedure.
    //
    
    // Get the version number of the currently running MacOS.
    if( Gestalt( gestaltSystemVersion, &result ) == noErr )
    {
        MacOSVersion = (u32) result;
    }
    else // Exit application.
    {
        ExitToShell();
    }
    
    // Test for System7 functionality.
    if( MacOSVersion >= 0x0700 )
    {
        IsSystem7Available = 1;
    }
    else // No functions in System 7 are available.
    {
        IsSystem7Available = 0;
    }
    
    // Find out if Apple events are supported.
    if( Gestalt( gestaltAppleEventsAttr, &result ) == noErr )
    { 
        if( result & BitOfByte[ gestaltAppleEventsPresent ] )
        {
            IsAppleEventsSupported = 1;
        }
        else
        {
            IsAppleEventsSupported = 0;
        }
    }
    else // Exit application.
    {
        ExitToShell();
    }
    
    // Find out which QuickDraw version is running.
    if( Gestalt( gestaltQuickdrawVersion, &result ) == noErr )
    {
        switch( result )
        {
            case gestaltOriginalQD: 
                { QuickDrawVersion = QD_1Bit; break; }
            case gestalt8BitQD: 
                { QuickDrawVersion = QD_8Bit; break; }
            case gestalt32BitQD: 
                { QuickDrawVersion = QD_32Bit; break; }
            case gestalt32BitQD11: 
                { QuickDrawVersion = QD_32Bit_11; break; }
            case gestalt32BitQD12: 
                { QuickDrawVersion = QD_32Bit_12; break; }
            case gestalt32BitQD13: 
                { QuickDrawVersion = QD_32Bit_13; break; }
            default:
                { QuickDrawVersion = QD_32Bit; break; }
        }
    }
    else // Exit application.
    {
        ExitToShell();
    }            

/* From 'Gestalt.h':

    The gestaltNativeCPUtype ('cput') selector can be used to determine the
    native CPU type for all Macs running System 7.5 or later.

    The 'cput' selector is not available when running System 7.0 (or earlier)
    on most 68K machines.  If 'cput' is not available, then the 'proc' selector
    should be used to determine the processor type.

    An application should always try the 'cput' selector first.  This is because,
    on PowerPC machines, the 'proc' selector will reflect the CPU type of the
    emulator's "virtual processor" rather than the native CPU type.

    The values specified below are accurate.  Prior versions of the Gestalt
    interface file contained values that were off by one.

    The Quadra 840AV and the Quadra 660AV contain a bug in the ROM code that
    causes the 'cput' selector to respond with the value 5.  This behavior
    occurs only when running System 7.1.  System 7.5 fixes the bug by replacing
    the faulty 'cput' selector function with the correct one.

    The gestaltNativeCPUfamily ('cpuf') selector can be used to determine the
    general family the native CPU is in. This can be helpful for determing how
    blitters and things should be written. In general, it is smarter to use this
    selector (when available) than gestaltNativeCPUtype since newer processors
    in the same family can be handled without revising your code.

    gestaltNativeCPUfamily uses the same results as gestaltNativeCPUtype, but
    will only return certain CPU values.
*/
    // Find what kind of CPU is running.
    if( Gestalt( gestaltNativeCPUtype, &result ) == noErr )
    {
        switch( result )
        {
            case gestaltCPU68000: { TypeOfCPU = CPU68000; break; }
            
            case gestaltCPU68010: { TypeOfCPU = CPU68010; break; }
            
            case gestaltCPU68020: { TypeOfCPU = CPU68020; break; }
            
            case gestaltCPU68030: { TypeOfCPU = CPU68030; break; }

            case 5: // For the Quadra bug.
            case gestaltCPU68040: { TypeOfCPU = CPU68040; break; }
            
            case gestaltCPU601:   { TypeOfCPU = CPU601;   break; }
            
            case gestaltCPU603:   { TypeOfCPU = CPU603;   break; }
            
            case gestaltCPU604:   { TypeOfCPU = CPU604;   break; }
            
            case gestaltCPU603e:  { TypeOfCPU = CPU603e;  break; }

#ifdef gestaltCPU603ev          
            case gestaltCPU603ev: { TypeOfCPU = CPU603ev; break; }
            
            case gestaltCPU750:   { TypeOfCPU = CPU750;   break; }
            
            case gestaltCPU604e:  { TypeOfCPU = CPU604e;  break; }
            
            case gestaltCPU604ev: { TypeOfCPU = CPU604ev; break; }
#endif          
            default:              { TypeOfCPU = CPU601;   break; }
        }
    }
    else // Use the older way.
    {
        // Find what kind of CPU is running.
        err = Gestalt( gestaltProcessorType, &result );
        
        switch( result )
        {
            case gestalt68000: { TypeOfCPU = CPU68000; break; }
            
            case gestalt68010: { TypeOfCPU = CPU68010; break; }
            
            case gestalt68020: { TypeOfCPU = CPU68020; break; }
            
            case gestalt68030: { TypeOfCPU = CPU68030; break; }

            case gestalt68040: { TypeOfCPU = CPU68040; break; }
            
            default:           { TypeOfCPU = 601; break; }
        }
    }
    
    // Determine the native CPU family
    if( TypeOfCPU == CPU68000 || TypeOfCPU == CPU68010 ||
        TypeOfCPU == CPU68020 || TypeOfCPU == CPU68030 ||
        TypeOfCPU == CPU68040 )
    {
        TypeOfCPUFamily = CPUFamily68000;
    }
    else
    {
        TypeOfCPUFamily = CPUFamilyPowerPC;
        
        // Set up the timer functions for the PowerPC 
        // family.
        SetUpTimePPC();
    }
}

/*------------------------------------------------------------
| IsTrapAvailable
|-------------------------------------------------------------
|
| PURPOSE: To test if a given trap is implemented.
|
| DESCRIPTION:  The recommended approach to see if a trap is 
| implemented is to see if the address of the trap routine is 
| the same as the address of the Unimplemented trap. 
|
| Needs to be called after call to 'SysEnvirons' so that it 
| can check if a ToolTrap is out of range of a pre-Mac II ROM.  
|
| It also requires the entire trap word so that a ToolTrap 
| can be distinguished from an OSTrap.
|
|
| EXAMPLE:  ta = IsTrapAvailable(_ShowCursor);
|
| NOTE: See also p.3-13 in 'Programmer's Guide To Multifinder'.
|
| ASSUMES: Follows initialization of Toolbox Managers.
|          Follows call to 'SysEnvirons'.
|          We're running on at least 128k ROMs.
|         
|
| HISTORY: 12.19.90 from SampleMisc.a
|          01.26.94 converted from Sage.a
------------------------------------------------------------*/
u32  
IsTrapAvailable( s16 ATrap )
{
    u32                 Result;
    UniversalProcPtr    ATrapAddress;
    UniversalProcPtr    UnimpAddress;

    Result = 0;
    
    // If this is a Toolbox Trap Word.
    if( ATrap & ToolTrapBitMask )
    { 
        // If on a future machine or on Mac II or better, 
        // test for the new trap. 
        if( SystemEnvironment.machineType == envMachUnknown ||
            SystemEnvironment.machineType >= envMacII ) 
        {
            goto GetToolTrap;
        }
        
        // Test For Exceeding Trap Table: 
        // At this point we know we're on a Mac 512E, Plus, or SE 
        // and need to test the trap number for being in the 
        // range of < $0200.
        //
        ATrap &= 0x03FF;  // mask off the ToolTrap bits.
         
        // If beyond the end of the table, exit with false.
        if(ATrap > 0x01FF)
        {
            return( Result );
        }
         
GetToolTrap:  // Test For New Tool Trap:
        ATrapAddress = NGetTrapAddress((u16)ATrap,ToolTrap);
    }
    else // An Operating System Trap Word.
    {
        ATrapAddress = NGetTrapAddress((u16)ATrap,OSTrap);
    }
    
    UnimpAddress = NGetTrapAddress(_Unimplemented,ToolTrap);
    
    // Compare with the address of the unimplemented trap,
    // and if different, then the trap is implemented.
    if( ATrapAddress != UnimpAddress ) 
    {
        Result = 1;
    }

    return(Result);
}
    
/*------------------------------------------------------------
| MainSetUp
|-------------------------------------------------------------
|
| PURPOSE: To set up a Mac application when it first starts.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.26.94 
|          02.03.94 added 'SetUpDialogs'.
|          02.09.94 added 'TheTextWindowList'.
|          02.22.94 added 'TEFromScrap'.
|          12.28.98 Added 'SetUpNetAccess()' and 'SetUpUUID()'.
------------------------------------------------------------*/
void
MainSetUp() // See 'MainSetUpForPenny' instead for Penny.
{
//  s16         AppFileMessage;
//  s16         CountOfFiles;

    // Set flags used to control configuration-dependent
    // operations.
    IdentifyEnvironment();
    
    // Allocate the memory to the heap.
    MaxApplZone();

    InitGraf( &qd.thePort);
    
    InitFonts();
    
    FlushEvents( everyEvent, 0 );
    
    InitWindows();
    
    InitMenus();
    
    TEInit();
    
    // 'SystemErrorExit' causes an exit to shell on
    // system errors. See p. 343 'Using Mac Toolbox In C'.
    //
    InitDialogs( SystemErrorExit );
    
    InitCursor();
    
    // AppendMenu(NewMenu(4,"\pWindow"),"\pWindow");  
    DrawMenuBar();
    
    SetUpCursors();
    
#ifdef MyClickLoop
    // Set the universal procedure records for window controls.
    VerticalScrollProcedureUPP = 
        NewControlActionProc( VerticalScrollProcedure );
        
    HorizontalScrollProcedureUPP = 
        NewControlActionProc( HorizontalScrollProcedure );
    
    // Make a new Universal Procedure Record for my custom
    // click loop routine.  
    MyClickLoop = 
        NewTEClickLoopProc( ClickLoopWithScrollBarUpdate );
#endif
        
    SetUpTheListSystem(0);
    
    SetUpTheWindowSystem();

    SetUpModeSystem();
    
    SetUpLockedHandleArray();
    
    SetUpRandomNumberGenerator(12314L); // Needed for 'Resample'.
    BeginSubRandomSequence(0); // Needed for 'ResampleSubRandom'.
    
#ifdef IS_NETWORK_AWARE
    // Initialize OpenTransport and do other set up needed
    // for network access.
    SetUpNetAccess( 0,  // LogNetworkActivity,
                    7200 ); // MaxTicksBetweenIncomingData
#endif
    
    // Set up UUID generation so that GUID types will be produced,
    // using a network card node ID if available or defaulting
    // to a randomly generated node ID:
    SetUpUUID(
        UUID_Version_1_DCE,  // Use the normal non-security type.
        UUID_Variant_GUID,   // Use GUID type IDs.
        0,                   // Query network card if available.
        0 );                 // Don't use random node unless 
                             // network card ID is unavailable.
}

/*------------------------------------------------------------
| MainCleanUp
|-------------------------------------------------------------
|
| PURPOSE: To close down a Mac application
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.11.94  
|
------------------------------------------------------------*/
void
MainCleanUp()
{
    CleanUpTheLog();
}

/*------------------------------------------------------------
| SystemErrorExit
|-------------------------------------------------------------
|
| PURPOSE: To exit the application gracefully after a system
|          error.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 01.27.94 
------------------------------------------------------------*/
pascal
void 
SystemErrorExit() 
{
    ExitToShell();
}

#endif // FOR_MACOS

