/*------------------------------------------------------------
| NAME: TLDNS.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for domain name procedures.
|
| DESCRIPTION:  
|
| NOTE: 
|
| HISTORY: 12.14.96
------------------------------------------------------------*/
    
#ifndef _DNS_H_
#define _DNS_H_

// Open Transport Internet service provider info.

typedef struct
{                           
    InetSvcRef  ref;                // provider reference
                                    //
    u32         complete;           // 1 when asynch operation has completed
                                    //
    OTResult    result;             // result code
                                    //
    void *      cookie;             // cookie
} InternetService; // Was named 'TMyOTInetSvcInfo'.

// DNS request status codes.
#define DNS_NoService               0
#define DNS_OpeningService          1
#define DNS_WaitingForResponse      2

// All info about a DNS request.
typedef struct
{
    s32     Status;         // Defined above.
                            //
    s8      DomainName[256];// The domain name requested.
                            //
    u32     IP_Address;     // The IP address result.
                            //
    s32     TicksWhenRequested; // System tick (1/60th sec) time 
                            // when the request is submitted.
                            //
    s32     TicksWhenTimesOut; // System tick time when the request
                            // is aborted.
                            //
    InternetService Svc;    // The internet service record used
                            // to get the IP address.
                            //
    InetHostInfo    HInfo;  // This is where OT returns up to
                            // 10 IP addresses for the domain.
} DNSRequest;   

extern  List*   PendingDNSRequests; // List of outstanding DNS requests.

extern  List*   DomainNameCache;    // List of all known
                                    // domain names found using
                                    // DNS.

                                
/* -------------------PROTOTYPES----------------------------- */

OSErr   GetLocalHostDomainName( CStr255 );

OSErr   GetLocalHostIPAddress( u32* );

OSErr   GetLocalHostIPAddressString( s8* );

pascal 
void    InternetServiceNotifier( void*, OTEventCode, OTResult, void* );

u32     IsDNSRequestPendingForDomainName( s8* );

u32     IsDottedDecimalDomainName( s8* );

u32     LookUpDomainNameInCache( s8* );

DNSRequest* MakeDNSRequestRecord();

void    ManagePendingDNSRequest( DNSRequest* );

OSErr   OpenInternetService( InternetService* );

DNSRequest* RequestDNSToAddDomainNameToCache( s32, s8* );
OSErr   TranslateDomainNameToIPAddress( s8* , u32* );

OSErr   TranslateDottedDecimalToIPAddress( s8*, u32* );
OSErr   TranslateIPAddressToDomainName( u32, CStr255 );

OSErr   WaitForInternetService( InternetService *, s32 );

                               

#endif
