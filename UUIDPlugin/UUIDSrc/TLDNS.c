/*------------------------------------------------------------
| TLDNS.c
|-------------------------------------------------------------
|
| PURPOSE: To support provide domain name system functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 12.14.96 
------------------------------------------------------------*/
#include "TLTarget.h"

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>
#include <fp.h>
#include <OpenTransport.h>
#include <OpenTptInternet.h>

#include "TLTypes.h"         
#include "TLMacOSMem.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemOS.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLParse.h"
#include "TLList.h"
#include "TLWin.h"
#include "TLModes.h"
#include "TLStrings.h"
#include "TLDyString.h"
#include "TLLog.h"
#include "TLNetAccess.h"
#include "TLNumber.h"

#include "TLDNS.h"

List*   DomainNameCache = 0;    // List of all known
                                // domain names found using
                                // DNS.
                                //
List*   PendingDNSRequests = 0; // List of outstanding DNS 
                                // requests.

/*------------------------------------------------------------
| GetLocalHostDomainName
|-------------------------------------------------------------
| 
| PURPOSE: To get this Mac's domain name, if any.
|
| DESCRIPTION: 
|
|   Exit:   function result = error code.
|           name = domain name of this Mac, as a C-format 
|           string.
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
------------------------------------------------------------*/
OSErr 
GetLocalHostDomainName( CStr255 name )
{
    u32     addr;
    s16     len;
    OSErr   err;

    err = noErr;
    
    err = GetLocalHostIPAddress( &addr );
    
    if( err != noErr ) 
    {
        return( err );
    }
    
    err = TranslateIPAddressToDomainName( addr, name );
    
    if( err != noErr )
    {
        return( err );
    }
    
    // Trim off any trailing '.'.
    len = strlen(name);
    
    if( name[len-1] == '.' ) 
    {
        name[len-1] = 0;
    }
    
    return( noErr );
}

/*------------------------------------------------------------
| GetLocalHostIPAddress
|-------------------------------------------------------------
| 
| PURPOSE: To get this Mac's IP address.
|
| DESCRIPTION: 
|
|   Exit:   function result = error code.
|           *addr = the IP address of this Mac.
|           
|   With Open Transport, if the Mac has more than one IP 
|   interface, the IP address of the default interface is 
|   returned.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
------------------------------------------------------------*/
OSErr 
GetLocalHostIPAddress( u32 *addr )
{
    InetInterfaceInfo   ifaceInfo;
    InternetService     svcInfo;
    OSErr               err, giveTimeErr;
    u32                 myAddr;
    
    err         = noErr;
    giveTimeErr = noErr;
    
    err = OTInetGetInterfaceInfo( &ifaceInfo, 
                                  kDefaultInetInterface );
                                      
    if( err == kOTNotFoundErr ) 
    {
        // If OT is not loaded, the OTInetGetInterfaceInfo 
        // call fails with error kOTNotFoundErr. In this 
        // case, we open an inet services endpoint 
        // temporarily just to force OT to load, and we try 
        // the call again.
        err = OpenInternetService( &svcInfo );
            
        if( err != noErr )
        {
            return( err );
        }
            
        err = OTInetGetInterfaceInfo( &ifaceInfo, 
                                      kDefaultInetInterface );

        OTCloseProvider( svcInfo.ref );
    }
        
    if( err != noErr ) 
    {
        return( err );
    }
        
    myAddr = ifaceInfo.fAddress;
    
    *addr = myAddr;
    
    return( noErr );
}

/*------------------------------------------------------------
| GetLocalHostIPAddressString
|-------------------------------------------------------------
| 
| PURPOSE: To get this Mac's IP address as a dotted-decimal 
|          string.
|
| DESCRIPTION: 
|
|   Exit:   function result = error code.
|
|           addrStr = this Mac's IP address, as a C-format 
|               string. You must allocate at least 16 bytes 
|               for this string. The returned string has max 
|               length 15.
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          12.04.96 renamed from 'NetGetMyAddrStr'.
------------------------------------------------------------*/
OSErr 
GetLocalHostIPAddressString( s8 *addrStr )
{
    u32     addr;
    OSErr   err;
    
    err = GetLocalHostIPAddress( &addr );
    
    if( err != noErr ) 
    {
        return( err );
    }
    
    sprintf( (char*) addrStr, 
             "%ld.%ld.%ld.%ld",
             (addr >> 24) & 0xff,
             (addr >> 16) & 0xff,
             (addr >> 8) & 0xff,
             addr & 0xff );
        
    return( noErr );
}

/*------------------------------------------------------------
| InternetServiceNotifier
|-------------------------------------------------------------
| 
| PURPOSE: To be Open Transport notifier proc for an Internet 
|          services provider.
|
| DESCRIPTION: 
|
|   Entry:  svcIfno = pointer to MyOTInetSvcInfo struct.
|           code    = OT event code.
|           result  = OT result.
|           cookie  = OT cookie.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          11.25.96 was named 'MyOTInetSvcNotifyProc'.
|          08.20.97 changed type of first parameter to be
|                   compatible with prototypes from Apple.
------------------------------------------------------------*/
pascal void 
InternetServiceNotifier( void*       SvcInfo, 
                         OTEventCode code,
                         OTResult    result, 
                         void*       cookie )
{
    InternetService *svcInfo;
    
    // Refer to the service info.
    svcInfo = (InternetService*) SvcInfo;
    
Note( (s8*) "InternetServiceNotifier code(%d) result(%d)\n",
      (s32) code, (s32) result );
    switch( code ) 
    {
        case T_OPENCOMPLETE:
            // Call to open a provider has completed.
        
        case T_DNRSTRINGTOADDRCOMPLETE:
        
        case T_DNRADDRTONAMECOMPLETE:
        
            svcInfo->complete = 1;
            svcInfo->result   = result; 
            svcInfo->cookie   = cookie;
            break;
    }
}

/*------------------------------------------------------------
| LookUpIPAddressInCache
|-------------------------------------------------------------
| 
| PURPOSE: To find the IP address associated with a domain
|          name by searching the cache.
|
| DESCRIPTION: If the domain name is in dotted-decimal format
| (eg. "23.43.144.3") a simple translation is performed, 
| otherwise a search is made for a matching domain name in 
| the cache.
|
| Doesn't use the DNS service to resolve an unknown names.
|
| Returns 0 if name not found.
|
| EXAMPLE: IP = LookUpIPAddressInCache( "cnn.com" );
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.17.96 from 'TranslateDomainNameToIPAddress'.
------------------------------------------------------------*/
u32 
LookUpDomainNameInCache( s8 *Host )
{
    Item*               AnItem;
    OSErr               err;
    s32                 HostByteCount;
    u32                 IP_Address;
    
    // First check to see if the domain name is in dotted
    // decimal form.
    if( IsDottedDecimalDomainName( Host ) )
    {
        err = 
            TranslateDottedDecimalToIPAddress( Host, &IP_Address );
    
        // If there was a translation error, return 0.
        if( err )
        {
            return( 0 ); 
        }
        else // Return the IP address.
        {
            return( IP_Address );
        }
    }

    // Count bytes in the host name.
    HostByteCount = CountString( Host );
    
    // Then search the cache to see if the domainName is 
    // already known.
    if( DomainNameCache )
    {
        AnItem = FindFirstMatchingItem( 
                    DomainNameCache, 
                    0,              // FieldOffset 
                    HostByteCount,  // FieldWidth
                    (u8*) Host );
        
        // If a match was found.
        if( AnItem && AnItem->SizeOfData == HostByteCount )
        {   
            // The IP address is kept in the 'SizeOfBuffer'
            // field.     
            IP_Address = AnItem->SizeOfBuffer;
            
            // Advance the item to the beginning of the
            // cache so that most commonly requested
            // names will be found first.
            if( DomainNameCache->FirstItem != AnItem )
            {
                ExtractItemFromList( DomainNameCache, 
                                     AnItem );
                                     
                InsertItemFirstInList( DomainNameCache, 
                                       AnItem );
            }

            return( IP_Address );
        }
        else // Not found.
        {
            return( 0 );
        }
    }
    else // No cache, no IP.
    {
        return( 0 );
    }
}

/*------------------------------------------------------------
| IsDNSRequestPendingForDomainName
|-------------------------------------------------------------
| 
| PURPOSE: To test if DNS request is pending for a given 
|          domain name.
|
| DESCRIPTION: Returns true if it is.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 01.06.97
------------------------------------------------------------*/
u32  
IsDNSRequestPendingForDomainName( s8* DomainName )
{
    DNSRequest* r;
        
    // If there are any pending requests.
    if( PendingDNSRequests->ItemCount )
    {
        // Make a pass through the list.
        ReferToList( PendingDNSRequests );
        
        while( TheItem )
        {
            // Refer to the data as a request.
            r = (DNSRequest*) TheDataAddress;
            
            // Is the name in this record the one?
            if( IsMatchingStrings( DomainName, 
                                   r->DomainName ) )
            {
                // Revert to the prior list if any.
                RevertToList();
                
                // Return the flag.
                return( 1 );
            }
            
            ToNextItem();
        }
        
        RevertToList();
    }
    
    // Return not found flag.
    return( 0 );
}

/*------------------------------------------------------------
| IsDottedDecimalDomainName
|-------------------------------------------------------------
| 
| PURPOSE: To test if a domain name is in dotted decimal
|          (eg. "23.42.234.12") format.
|
| DESCRIPTION: Returns true if it is.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.14.96
------------------------------------------------------------*/
u32  
IsDottedDecimalDomainName( s8* ADomainName )
{
    u8  AByte;
    
    while( *ADomainName )
    {
        AByte = *ADomainName++;
        
        if( AByte != '.' && IsDigit( AByte ) == 0 )
        {
            return( 0 );
        }
    }

    return( 1 );
}

/*------------------------------------------------------------
| MakeDNSRequestRecord
|-------------------------------------------------------------
| 
| PURPOSE: To make a new DNS request record.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.16.96 from 'MakeHTTPRequestRecord'.
------------------------------------------------------------*/
DNSRequest*
MakeDNSRequestRecord()
{
    DNSRequest* r;
    
    r = (DNSRequest*) malloc( sizeof( DNSRequest ) );
        
    FillBytes( (u8*) r, (u32) sizeof(DNSRequest), 0 );
    
    return( r );
}

/*------------------------------------------------------------
| ManagePendingDNSRequest
|-------------------------------------------------------------
| 
| PURPOSE: To manage the progress of an asynchronous DNS
|          request.
|
| DESCRIPTION:  
| Times out after the given limit.
|
| EXAMPLE: 
|           
|       RequestDNSToAddDomainNameToCache( 120, "cnn.com" );
|
|
| NOTE: 
| 
| ASSUMES: Given request record is in the list
|          'PendingDNSRequests'.
| 
| HISTORY: 12.17.96 from 'TranslateDomainNameToIPAddress'.
------------------------------------------------------------*/
void 
ManagePendingDNSRequest( DNSRequest* r ) 
{
    OSErr   err;
    Item*   AnItem;
    
    // First check to see if the request timed out.
    if( TickCount() > r->TicksWhenTimesOut )
    {
        // Clear the request.
ClearRequest:
                
        // Close any open service provider.
        if( r->Svc.ref )
        {               
            // Close the service provider and delete it.
            OTCloseProvider( r->Svc.ref );
                
            r->Svc.ref = 0;
        }
        
        // Remove the request from the 'PendingDNSRequests'
        // list.
        DeleteAllReferencesToData( PendingDNSRequests, (u8*) r );
        
        // Free the request record.
        free( r );
        
        return;
    }
    
    // Still time to get the name.
 
    // Move the process along depending on where it is now.
    switch( r->Status )
    {
        // If we need to open the DNS provider.
        case DNS_NoService:
        {
            r->Status = DNS_OpeningService;
            
            r->Svc.complete = 0;
    
            // Request the opening of the service provider.
            err = OTAsyncOpenInternetServices( 
                    kDefaultInternetServicesPath, 
                    0, 
                    InternetServiceNotifier, 
                    &r->Svc );
              
            if( err != noErr )
            {
                // Not able to start the operation.
                r->Status = DNS_NoService;
            }
            
            return;
        }
        
        case DNS_OpeningService:
        {
            // Check to see if the service is open.
            if( r->Svc.complete )
            {   
                // Get the endpoint reference.
                r->Svc.ref = r->Svc.cookie;
                
                r->Svc.complete = 0;
Note((s8*) " r->DomainName %s \n", r->DomainName );             
                // Ask DNR to resolve the domain name.
                err = OTInetStringToAddress( r->Svc.ref, 
                                             (char*) r->DomainName, 
                                             &r->HInfo );
Note( (s8*) "   DNS_OpeningService err(%d)\n", err );                                        
                // If no error then we wait.
                if( err == noErr )
                {
                    r->Status = DNS_WaitingForResponse;
                }
                
                // If there was an error starting then try 
                // this again later.
            }
            
            return;
        }
        
        case DNS_WaitingForResponse:
        {
            // Check to see if the response was received.
            if( r->Svc.complete && r->Svc.result == noErr )
            {
                // Add the domain name and IP to the cache. 
                AnItem =
                    InsertDataFirstInList( 
                        DomainNameCache,
                        (u8*) DuplicateString( r->DomainName ) );
                               
                AnItem->SizeOfData = CountString( r->DomainName );
                
                // This is where the IP address is saved.
                AnItem->SizeOfBuffer = r->HInfo.addrs[0];
                
                // Then clear the pending request.
                goto ClearRequest;
            }
            
            // Reject bad domain names.
            if( r->Svc.complete && r->Svc.result == kOTBadNameErr )
            {
                Note( (s8*) "DNS: Bad domain name %s\n", r->DomainName );
                
                // Then clear the pending request.
                goto ClearRequest;
            }           
            
            return;
        }
    }
}

/*------------------------------------------------------------
| OpenInternetService
|-------------------------------------------------------------
| 
| PURPOSE: To open an Internet services provider.
|
| DESCRIPTION: 
|
|   Entry:  svcInfo = pointer to InternetService struct for 
|               this provider.
|   
|   Exit:   function result = error code.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          11.25.96 renamed from 'MyOTOpenInetServices'.
------------------------------------------------------------*/
OSErr 
OpenInternetService( InternetService *svcInfo )
{
    OSErr err;

    svcInfo->complete = 0;
    
    err = OTAsyncOpenInternetServices( 
              kDefaultInternetServicesPath, 
              0, 
              InternetServiceNotifier, 
              svcInfo );
              
    if( err != noErr )
    {
        // Not able to start the operation.
        return( err );
    }
    
    // Wait up to 30 seconds for this service request
    // to complete.
    err = WaitForInternetService( svcInfo, 60 * 30 );
    
    if( err == noErr )
    {
        // Set the provider reference if there are no errors.
        svcInfo->ref = svcInfo->cookie;
    }
    
    return( err );
}

/*------------------------------------------------------------
| RequestDNSToAddDomainNameToCache
|-------------------------------------------------------------
| 
| PURPOSE: To ask DNS to get the IP address of a domain name
|          and then add it to the cache asynchronously.
|
| DESCRIPTION: Submits a request that may in due time result
| in a domain name:IP address entry being added to the domain
| name cache.
|
| Relies on notifier and idle routines for completion.
|
| Times out after the given limit.
|
| EXAMPLE: 
|           
|       RequestDNSToAddDomainNameToCache( 120, "cnn.com" );
|
|
| NOTE: 
| 
| ASSUMES: Domain name isn't in the cache already and no
|          request is already pending for the host.
| 
| HISTORY: 12.17.96 from 'TranslateDomainNameToIPAddress'.
------------------------------------------------------------*/
DNSRequest* 
RequestDNSToAddDomainNameToCache( s32 SecondsTilTimeOut, 
                                  s8* Host )
{
    DNSRequest*     r;
    
    // Makes a new request record.
    r = MakeDNSRequestRecord();

    // Timestamp the request.
    r->TicksWhenRequested = TickCount();
    
    // Compute the time out point.
    r->TicksWhenTimesOut = TickCount() +
                           SecondsTilTimeOut * 60;
                           
    // Copy the domain name string to the request record.
    CopyString( Host, r->DomainName );
    
    // Set the status that no internet service has been
    // assigned.
    r->Status = DNS_NoService;
    
    // Add the record to the request list for subsequent
    // processing.
    InsertDataFirstInList( PendingDNSRequests, (u8*) r );
    
    return( r );
}

/*------------------------------------------------------------
| TranslateDomainNameToIPAddress
|-------------------------------------------------------------
| 
| PURPOSE: To translate a domain name to an IP address.
|
| DESCRIPTION: Translates a host/domain name in either
| named ("cnn.com") or dotted ("23.43.144.3") format into
| a 32-bit IP address.
|
| Maintains a cache of all requested domain names.
|
| Uses DNS service to resolve an unknown names.
|
| Returns 0 if OK else error code.
|
| If DNS service is required will wait until response is
| received or 30 seconds which ever comes first.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          12.14.96 revised.
|          12.17.96 factored out 'LookUpIPAddressInCache'.
------------------------------------------------------------*/
OSErr 
TranslateDomainNameToIPAddress( 
    s8  *Host, 
    u32 *IP_Address )
{
    Item*               AnItem;
    OSErr               err;
    InetHostInfo        hInfoOT;
    InternetService     svcInfo;
    s32                 HostByteCount;
    
    // First try cache look up.
    *IP_Address = LookUpDomainNameInCache( Host );

    // Return on success.
    if( *IP_Address ) 
    {
        return( noErr );
    }
    
    // Count bytes in the host name.
    HostByteCount = CountString( Host );
        
    // Otherwise use DNS to find the IP address for the domain.
    err = OTInetStringToHost( (char*) Host, IP_Address );
        
    if( err != noErr ) 
    {
        err = OpenInternetService( &svcInfo );
            
        if( err == kEINVALErr || 
            err == -3198 ) // '-3198' isn't defined in IM OT or
                           // any of the OT .h files.
        {
            return( netDNRErr );
        }
            
        if( err != noErr ) 
        {
            return( err );
        }
            
        svcInfo.complete = 0;
            
        err = OTInetStringToAddress( svcInfo.ref, 
                                     (char*) Host, 
                                     &hInfoOT );
            
        if( err == noErr ) 
        {
            // Wait up to 30 seconds for this service request
            // to complete.
            err = WaitForInternetService( &svcInfo, 60 * 30 );
        }
            
        OTCloseProvider( svcInfo.ref );
            
        if( err != noErr ) 
        {
            return( err );
        }
            
        // Get the first IP address of possibly 10 assigned to
        // the same domain name.
        *IP_Address = hInfoOT.addrs[0];
    }
    
    // Add the domain name to the cache.    
    AnItem =
        InsertDataFirstInList( DomainNameCache,
                               (u8*) DuplicateString( Host ) );
                               
    AnItem->SizeOfData   = HostByteCount;
    
    AnItem->SizeOfBuffer = *IP_Address;
    
    
    return( noErr );
}

/*------------------------------------------------------------
| TranslateDottedDecimalToIPAddress
|-------------------------------------------------------------
| 
| PURPOSE: To convert a domain name in dotted decimal
|          (eg. "23.42.234.12") format to a 32-bit IP address.
|
| DESCRIPTION: Returns 0 if OK, non-zero otherwise.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: Domain name consists only of periods and digits.
| 
| HISTORY: 12.14.96 from 'GetLocalHostIPAddressString'.
|          01.13.97 fixed error where wrong part of string
|                   was converted to integer.
------------------------------------------------------------*/
OSErr
TranslateDottedDecimalToIPAddress( s8*  ADomainName, 
                                   u32* IP_Address ) 
{
    u32     b[4];
    s8*     AtDot;
    s8*     AtDigits;
    s32     i;
    
    // Refer to the first set of digits.
    AtDigits = ADomainName;
    
    for( i = 0; i < 3; i++ )
    {
        // Find the first period.
        AtDot = FindByteInString( '.', AtDigits );

        // If no period then return error.
        if( AtDot == 0 ) return( 1 );
    
        // Replace the period with a zero temporarily so that
        // the preceding digits can be converted.
        *AtDot = 0;
    
        // Convert the first set of digits to binary.
        b[i] = ConvertStringToInteger( AtDigits );
    
        // Restore the period.
        *AtDot = '.';
    
        // Refer to the next set of digits.
        AtDigits = AtDot + 1;
    }
    
    // Convert the last set of digits to binary.
    b[3] = ConvertStringToInteger( AtDigits );

    // Assemble the bytes into a 32-bit word.
    *IP_Address = (b[0] << 24) | 
                  (b[1] << 16) | 
                  (b[2] <<  8) | 
                   b[3];
                   
    return( 0 );
}
                 
/*------------------------------------------------------------
| TranslateIPAddressToDomainName
|-------------------------------------------------------------
| 
| PURPOSE: To translate an IP address to a domain name.
|
| DESCRIPTION: 
|
|   Entry:  addr = IP address.
|   
|   Exit:   function result = error code.
|           name = domain name, as a C-format string.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          12.05.96 revised.
------------------------------------------------------------*/
OSErr 
TranslateIPAddressToDomainName( u32 addr, CStr255 name )
{
    InternetService svcInfo;
    
    OSErr   err;
    
    err = OpenInternetService( &svcInfo );
        
    if( err != noErr ) 
    {
        return( err );
    }
        
    svcInfo.complete = 0;
        
    err = OTInetAddressToName( svcInfo.ref, addr, name );
        
    if( err == noErr )
    {
        // Wait for up to 30 seconds.
        err = WaitForInternetService( &svcInfo, 30 * 60 );
    }
        
    OTCloseProvider( svcInfo.ref );
        
    return( err );  
}

/*------------------------------------------------------------
| WaitForInternetService
|-------------------------------------------------------------
| 
| PURPOSE: To wait for an asynchronous Open Transport Internet 
|          services call to complete or for time to run out.
|
| DESCRIPTION: Expects time limit in ticks, that is 1/60th of
| a second.
|
|   Entry:  svcInfo = pointer to InternetService struct.
|   
|   Exit:   function result = error code.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          11.25.96 replaced 'GiveTime' with 
|                   'ProcessPendingEvent'.  Pulled out
|                   return on 'GiveTime' error.
|                   Renamed from 'MyOTInetSvcWait'.
------------------------------------------------------------*/
OSErr 
WaitForInternetService( InternetService *svcInfo, s32 MaxWait )
{
    s32     WaitTil;
    
    WaitTil = TickCount() + MaxWait;
     
    while( !svcInfo->complete && TickCount() < WaitTil )
    {
        ProcessPendingEvent();
    }
    
    if( TickCount() > WaitTil )
    {
        return( kETIMEDOUTErr );
    }
        
    return( svcInfo->result );
}

