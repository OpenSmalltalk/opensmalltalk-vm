/*------------------------------------------------------------
| TLEthernet.c
|-------------------------------------------------------------
|
| PURPOSE: To provide Ethernet functions.
|
| DESCRIPTION:  
|
| NOTE: 
|
| ASSUMES: Availability of Open Transport.
|
| HISTORY:   2/6/96 rkubota (1) initialized the index variable 
|                   to 0 in main
|          12.08.98 From 'ShowOTEnetAddr.c', example code
|                   from Apple.
|          12.28.98 Added 'IS_NETWORK_AWARE' so that UUID
|                   generator can still be used without
|                   requiring the use of OpenTransport.
------------------------------------------------------------*/

#include <stdio.h>

#if macintosh

#include <Types.h>
#include <Memory.h>
#include <Resources.h>
#include <Events.h>

#endif // macintosh

#include "TLTypes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"

#ifdef IS_NETWORK_AWARE
#include <OpenTransport.h> // open transport files          
#include <OpenTptLinks.h>
#include <OpenTptInternet.h>
#include "TLNetAccess.h"
#endif

#include "TLEthernet.h"


#ifdef IS_NETWORK_AWARE
EndpointRef     gEndpoint1;

/*------------------------------------------------------------
| DoBindENET
|-------------------------------------------------------------
|
| PURPOSE: To bind to any Ethernet endpoint.
|
| DESCRIPTION: In this case we bind to enet protocol type 
| 0x8888.  An Address8022 variable is used for expediency 
| but a Type 1 Ethernet address is the protocol used.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: 
|
| HISTORY: 12.08.98
------------------------------------------------------------*/
OSStatus 
DoBindENET()
{
    OSStatus        osStatus;
    TBind           gRequestInfo;
    Address8022     
    theAddr = 
    { 
        AF_8022, 
        { 0, 0, 0, 0, 0, 0 }, 
        0x8888,
        { 0, 0, 0, 0, 0}
    };
    
    // finish bind information
    gRequestInfo.addr.buf = (u8*) &theAddr;
    
    // family type + Ethernet + type field
    // Don't use sizeof(theAddr) since we are binding to 
    // type 1 Ethernet address, not to an 802.2 address.
    gRequestInfo.addr.len = 10; 
    
    gRequestInfo.addr.maxlen = 0;           
    gRequestInfo.qlen = 0;
    
    // Attempt to bind to an endpoint.
    osStatus = OTBind( gEndpoint1, &gRequestInfo, NULL );
    
    // If there was a binding error.
    if( osStatus )
    {
        // printf("\nCould not bind an endpoint, error = %d\n", osStatus);
        // CloseOpenTransport();
        return( -4 );
    }
    
    return( osStatus );
}

/*------------------------------------------------------------
| GetEthernetAddress
|-------------------------------------------------------------
|
| PURPOSE: To get the Ethernet address of a given slot.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: OpenTransport has been activated.
|
| HISTORY: 12.08.98
------------------------------------------------------------*/
OSStatus 
GetEthernetAddress( s8* /* slotName */, Address8022* A )
{
    OSStatus        osStatus;
    TBind           returnInfo;
    
    returnInfo.addr.buf = (u8*) A;
    // family type + 6 bytes for Ethernet + type
    returnInfo.addr.maxlen = 10;            
    returnInfo.qlen = 0;
    
    osStatus = OTGetProtAddress( gEndpoint1, &returnInfo, NULL );

#if 0 // Debug only.    
    if( osStatus == kOTNoError )
    {
        if( slotName[0] != 0x00 )
            printf("\nAddress for PCI Slot %s => ", slotName);
        else
            printf("\nAddress for Ethernet Built-In => ");
        
        printf( "%02x.", (u16) A->fHWAddr[0] );
        printf( "%02x.", (u16) A->fHWAddr[1] );
        printf( "%02x.", (u16) A->fHWAddr[2] );
        printf( "%02x.", (u16) A->fHWAddr[3] );
        printf( "%02x.", (u16) A->fHWAddr[4] );
        printf( "%02x",  (u16) A->fHWAddr[5] );
    }
    else
        printf( "\n\nCould not get the Ethernet address, error = %d\n\n", osStatus );
#endif
    
    return( osStatus );
}

#endif // IS_NETWORK_AWARE
 
/*------------------------------------------------------------
| GetAnyEthernetAddress
|-------------------------------------------------------------
|
| PURPOSE: To get any Ethernet address attached to the 
|          computer.
|
| DESCRIPTION: Returns the 6-byte Ethernet address and set
| the return flag to '1' if a valid address is returned.
|
| EXAMPLE: 
|
| NOTE: 
|
| ASSUMES: OpenTransport has been activated using 
|          'SetUpNetAccess()'.
|
| HISTORY: 12.08.98
|          12.18.98 Tested.
------------------------------------------------------------*/
#ifdef IS_NETWORK_AWARE
u32  
GetAnyEthernetAddress( u8* A )
{
    OSStatus        err;
    OTPortRecord    devicePortRecord;
    Boolean         foundAPort;
    u32             index;
    u32             IsFound;
    Address8022     
    theReturnAddr = 
    { 
        AF_8022, 
        { 0, 0, 0, 0, 0, 0 }, 
        0x8888,
        { 0, 0, 0, 0, 0}
    };
    
    // Set the success flag to '0' by default.
    IsFound = 0;
    
    // Start with the first OpenTransport port.
    index = 0;

    // So long as OpenTransport is set up.
    while( IsOpenTransportSetUp )
    {
        //
        // For each OpenTransport port.
        //
     
        // Find a port given an index number.
        foundAPort = OTGetIndexedPort( &devicePortRecord, index );
        
        // If a port was found.
        if( foundAPort )
        {
            // If the port is an Ethernet port.
            if( (devicePortRecord.fCapabilities & kOTPortIsDLPI) &&
                (devicePortRecord.fCapabilities & kOTPortIsTPI) &&
                (kOTEthernetDevice == OTGetDeviceTypeFromPortRef( devicePortRecord.fRef ) ) )
            {
                // Open an endpoint for the port.
                gEndpoint1 = 
                    OTOpenEndpoint(
                        OTCreateConfiguration( devicePortRecord.fPortName), 
                        (OTOpenFlags) 0, 
                        0, 
                        &err );
        
                // If the endpoint was opened properly.
                if( err == kOTNoError )
                {
                    // Bind the endpoint so that the address can be
                    // obtained.
                    err = DoBindENET();
                    
                    // If the endpoint was bound properly.
                    if( err == kOTNoError )
                    {
                        // Get the Ethernet address of the given slot.
                        GetEthernetAddress( devicePortRecord.fSlotID,
                                            &theReturnAddr );
                        
                        // Copy the 6-byte Ethernet address to the return buffer.
                        CopyBytes( (u8*) &theReturnAddr.fHWAddr,
                                   A,
                                   6 );
                        
                        // Set the success flag to '1'
                        IsFound = 1;
                                 
                        // Unbind the endpoint.
                        OTUnbind( gEndpoint1 );
                    }
                    
                    // Close the entpoint.
                    OTCloseProvider( gEndpoint1 );
                    
                    // Skip any remaining ports.
                    goto Done;
                }   
            }
            
            // Advance to the next OpenTransport port.
            index++;
        }   
    }

Done:
    
    // Return the result status.
    return( IsFound );
    
}

#else // Not network aware.

u32  
GetAnyEthernetAddress( u8* /* A */ )
{
    // Return the result status.
    return( 0 );
}
    
#endif // IS_NETWORK_AWARE

