/*------------------------------------------------------------
| TLEthernet.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to Ethernet functions.
|
| DESCRIPTION:  
|
| NOTE: 
|
| HISTORY: 12.08.98 From 'ShowOTEnetAddr.c', example code
|                   from Apple.
|          12.28.98 Added 'IS_NETWORK_AWARE' so that UUID
|                   generator can still be used without
|                   requiring the use of OpenTransport.
------------------------------------------------------------*/

#ifndef _TLETHERNET_H_
#define _TLETHERNET_H_

#ifdef IS_NETWORK_AWARE

struct Address8022
{
    OTAddressType   fAddrFamily;
    u8              fHWAddr[k48BitAddrLength];
    u16             fSAP;
    u8              fSNAP[k8022SNAPLength];
};

typedef struct Address8022 Address8022;


OSStatus DoBindENET();
OSStatus GetEthernetAddress( s8*, Address8022* );

#endif // IS_NETWORK_AWARE

u32      GetAnyEthernetAddress( u8* );

#endif
