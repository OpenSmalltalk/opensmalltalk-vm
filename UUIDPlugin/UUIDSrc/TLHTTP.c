/*------------------------------------------------------------
| TLHTTP.c
|-------------------------------------------------------------
|
| PURPOSE: To support HTTP transactions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 12.12.96 
------------------------------------------------------------*/

#include "TLTarget.h"

#ifdef FOR_MACOS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fp.h> 
#include <OSUtils.h>
#include <OpenTransport.h>
#include <OpenTptInternet.h>

#include "TLTypes.h"
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLStrings.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLListIO.h"
#include "TLStacks.h"
#include "TLParse.h"
#include "TLStacks.h"
#include "TLWin.h"
#include "TLLog.h"
#include "TLModes.h"
#include "TLMenu.h"
#include "TLDate.h"
#include "TLURL.h"
#include "TLDNS.h"
#include "TLNetAccess.h"
#include "TLByteBuffer.h"
#include "TLFile.h"
#include "TLFileExtra.h"

#include "TLHTTP.h"

List*   PendingHTTPRequests = 0;    // List of pending HTTP 
                                    // requests.
                                    //
List*   CompletedHTTPRequests = 0;  // List of HTTP requests that
                                    // have been completed.
                                  
/*------------------------------------------------------------
| CompleteOrRetryHTTPResponse
|-------------------------------------------------------------
| 
| PURPOSE: To validate, complete or retry an HTTP response
|          depending on the nature of the response.
|
| DESCRIPTION: 
|
| HISTORY: 12.17.96
|          01.14.97 fixed attempt to delete response data
|                   that doesn't exist during retry.
|          01.16.97 disabled retry.
------------------------------------------------------------*/
void
CompleteOrRetryHTTPResponse( HTTPRequest* r ) 
{
    // Get the response data if any.
    if( r->Strm && r->Strm->BytesToRead )
    {
        // Save the data in the request record.
        r->Response = GetIncomingDataFromStream( r->Strm );
                                
        // Get the response status code.
        r->ResponseStatus = 
            GetHTTPResponseStatus( r->Response->DataAddress );
    
        // Look for a mismatch between the 'Content-Length'
        // header value, if any, and the actual data received.
        r->IsContentIncomplete =
            IsEntityBodyIncomplete( r->Response->DataAddress,
                                    r->Response->SizeOfData );
    }
    else // No response data.  'ResponseStatus' will already
         // have been set elsewhere.
    {
        r->IsContentIncomplete = 1;
    }
                                                        
    // Handle each status case appropriately.
    switch( r->ResponseStatus )
    {
        // SUCCESS CASES:
        case HTTP_OK:
        case HTTP_Created:
        case HTTP_Accepted:
        case HTTP_SimpleResponse:
        {
            // If the entity-body is incomplete.
            if( r->IsContentIncomplete )
            {
                // Retry to get a complete entity body.
//              goto Retry;
                goto Fail;
            }
            else // We got it all.
            {
                SaveHTTPResponseToGivenFiles( r );
                
                if( r->IsDeleteOnCompletion )
                {
                    // Also closes any open stream.
                    DeleteHTTPRequest( r );
                }
                else
                {                       
                    // Also closes any open stream.
                    MoveHTTPRequestToCompletedList( r );
                }
            }
            break;
        }

        // RETRY CASES:
        case HTTP_NoContent: // May be temporary.
        case HTTP_NotModified:
        case HTTP_NotFound:
        case HTTP_InternalServerError:
        case HTTP_ServiceUnavailable:
#if 0
        {
Retry:
            Note("**** Retry HTTP request. ****\n");
            
            // Delete any response data and try again.
            if( r->Response )
            {
                free( r->Response->BufferAddress );
                                         
                DeleteItem( r->Response );
                                        
                r->Response = 0;
            }
                                        
            r->RetryCount++;
                                        
            break;
        }
#endif                                  
        // FAILURE CASES:
        case HTTP_MovedTemporarily:
        case HTTP_MovedPermanently:
        case HTTP_BadRequest:
        case HTTP_Unauthorized:
        case HTTP_Forbidden:
        case HTTP_NotImplemented:
        case HTTP_BadGateway:
        case HTTP_TimedOut:
        case HTTP_BadURL:
        case HTTP_UnsupportedScheme:
        default:
        {
Fail:
            Note((s8*) "**** Fail HTTP request '%s'\n",
                 r->URL);
            if( r->IsDeleteOnCompletion )
            {
                // Also closes any open stream.
                DeleteHTTPRequest( r );
            }
            else
            {                       
                // Also closes any open stream.
                MoveHTTPRequestToCompletedList( r );
            }
             
            break;
        }       
    }
}

/*------------------------------------------------------------
| DeleteHTTPRequest
|-------------------------------------------------------------
| 
| PURPOSE: To delete an HTTP request and release any open 
|          stream or data associated with it.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.20.96 from 'MoveHTTPRequestToCompletedList'.
------------------------------------------------------------*/
void
DeleteHTTPRequest( HTTPRequest* r )
{   
    // Remove the request from the 'PendingHTTPRequests'
    // list.
    DeleteAllReferencesToData( PendingHTTPRequests, (u8*) r );
    
    // Remove the request from the 'CompletedHTTPRequests'
    // list.
    DeleteAllReferencesToData( CompletedHTTPRequests, (u8*) r );
 
    // If there is a stream, get rid of it.
    if( r->Strm )
    {
        // Close the stream.
        CloseTCPStream( r->Strm );
    }
    
    // Delete any response.
    if( r->Response )
    {
        if( r->Response->DataAddress )
        {
            free( r->Response->DataAddress );
        }
        
        DeleteItem( r->Response );
    }
    
    // Finally, delete the request record itself.
    free( r );
}

/*------------------------------------------------------------
| GetHTTPResponseContentLength
|-------------------------------------------------------------
| 
| PURPOSE: To the content length specified in the header of
|          an HTTP response.
|
| DESCRIPTION:  A negative return value means the length 
| wasn't specified.
|
| EXAMPLE:   
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.17.96
------------------------------------------------------------*/
s32
GetHTTPResponseContentLength( u8* AtResponse, s32 ByteCount )
{
    s32 ContentLengthNameByteCount;
    u8* AtContentLength;
    s8* AtDigits;
    s32 ContentLength;
    
    // Find the 'Content-Length:' header.
    ContentLengthNameByteCount = 
        CountString( (s8*) "Content-Length:" );
        
    AtContentLength = 
        FindBytesInBytes( (u8*) "Content-Length:", 
                          ContentLengthNameByteCount,  
                          AtResponse,  
                          ByteCount ); 
                          
    // If the 'Content-Length' header is missing, return
    // -1.
    if( AtContentLength == 0 ) return( -1 );
    
    // Parse out the content length.
    AtDigits = (s8*) AtContentLength + ContentLengthNameByteCount;
    
    ContentLength = (s32) ParseUnsignedInteger( &AtDigits );
    
    return( ContentLength );
}
 
/*------------------------------------------------------------
| GetHTTPResponseStatus
|-------------------------------------------------------------
| 
| PURPOSE: To get the HTTP response status code from an HTTP
|          response.
|
| DESCRIPTION: An HTTP response may be either simple or full.
| If it is a simple response, the entire response will 
| consist of just an entity body.
|
| If the response is a full response, then one or more header
| lines will be prepended.
|
| The first line of a full response is the status line.
|
| The status line of an HTTP response contains the following:
|
|      HTTP-Version SP Status-Code SP Reason-Phrase CRLF
|
|       "HTTP/" 1*DIGIT "." 1*DIGIT SP 3DIGIT SP CRLF
|
|   eg. "HTTP/1.0 200 OK"
|
| This routine returns the status code or a special code
| that means that the status line is missing and that therefore
| the response is a simple one: 'HTTP_SimpleResponse'.
|
| EXAMPLE:   
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.14.96
------------------------------------------------------------*/
s32
GetHTTPResponseStatus( u8* AtResponse )
{
    s32 status;
    s8* AtDigits;
    
    // If the first five characters are 'HTTP/' then
    // this is a full response.
    if( IsMatchingBytes( AtResponse, (u8*) "HTTP/", 5 ) )
    {
        // Refer to the status digits.
        AtDigits = (s8*) &AtResponse[9];
        
        status = (s32) ParseUnsignedInteger( &AtDigits );
        
        return( status );
    }
    else // A simple response.
    {
        return( HTTP_SimpleResponse );
    }
}

/*------------------------------------------------------------
| GetIPFromURL
|-------------------------------------------------------------
| 
| PURPOSE: To get the IP address of the host in the URL.
|
| DESCRIPTION:  
|
| EXAMPLE:  err = GetIPFromURL( &IP, "http://cnn.com/" );
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.14.96
------------------------------------------------------------*/
OSErr
GetIPFromURL( u32* Remote_IP_Address, s8* URL ) 
{
    OSErr   err;
    s8      Scheme[20];
    s8      User[64];
    s8      Password[64];
    s8      Host[512];
    s8      Port[20];
    s8      Path[512];
    
    // Cut the URL string into parts.
    err = ParseURL( URL, 
                    Scheme, 
                    User, 
                    Password, 
                    Host,
                    Port, 
                    Path );
                    
    if( err ) return( err );
    
    // Look up the IP address for the host name.  May call DNS.
    err = TranslateDomainNameToIPAddress( 
                    Host, 
                    Remote_IP_Address );
                    
    return( err );
}

/*------------------------------------------------------------
| GetURL
|-------------------------------------------------------------
| 
| PURPOSE: To get a web document within a time period.
|
| DESCRIPTION: Returns an 'Item' reference to a dynamic buffer
| holding the document.  Returns 0 if unable to get the
| document within the time limit.
|
| Expects time limit in seconds.
|
| EXAMPLE:  AnItem = GetURL( 60, "http://cnn.com/" );
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.14.96
------------------------------------------------------------*/
Item*
GetURL( s32 SecondsToWait, s8* URL )
{
    Item*   AnItem;
    s8      RequestBuffer[4096];
    s32     WaitTil;
    Stream* s;
    u32     Remote_IP_Address;
    OSErr   err;

    SecondsToWait = SecondsToWait;
    
    // Get the IP address of the host in the URL.
    err = GetIPFromURL( &Remote_IP_Address, URL );
    
    if( err ) return( 0 );
    
    // Make the document request command string.
    err = MakeGetURLRequestString( URL, RequestBuffer );
    
    if( err ) return( 0 );
    
    s = MakeStreamBuffer();
         
    err = OpenStreamEndpointAsTCP( s );
    
    if( err )
    {
        DeleteStreamBuffer( s );
        
        return( 0 );
    }
    
    // Put the request into the stream before we open it
    // so that it will be sent in due course.
    PutOutgoingDataIntoStream( s, 
                               (u8*) RequestBuffer, 
                               CountString( RequestBuffer ) );
    
    // Connect to the remote host.
    err = OpenActiveTCPConnection( s, 
                                   Remote_IP_Address, 
                                   HTTPPort );

    // If couldn't connect then just return.
    if( err )
    {
        CloseTCPStream( s );
        return( 0 );
    }
    
    // Wait for up to 2 minutes while the document is received.
    // After disconnection the endpoint will be unbound.
    WaitTil = TickCount() + 2 * TicksPerMinute;
    
    while( GetEndpointState( s ) != T_UNBND &&
           TickCount() < WaitTil )
    {
        ProcessPendingEvent();
    }
    
    // If the endpoint is unbound then we completed a 
    // transaction.
    // the connection.
    if( GetEndpointState( s ) == T_UNBND )
    {
        // We may have recieved some data.
        AnItem = GetIncomingDataFromStream( s );
    }
    else // Timed out.
    {   
        AnItem = 0; // void received.
    }
    
    // Discard the stream.
    CloseTCPStream( s );

    // Return the result.
    return( AnItem );
}

/*------------------------------------------------------------
| GetURLToJPEGFile
|-------------------------------------------------------------
| 
| PURPOSE: To get a web document within a time period and save
|          the entity body as a jpeg file.
|
| DESCRIPTION: Returns 0 if unable to get the
| document within the time limit.
|
| Expects time limit in seconds.
|
| EXAMPLE:  AnItem = GetURL( 60, "http://cnn.com/" );
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.14.96
------------------------------------------------------------*/
void
GetURLToJPEGFile( s32 SecondsToWait, s8* URL, s8* FileName )
{
    Item*   AnItem;
    s32     ByteCount;
    u8*     AtContent;
    
    SecondsToWait = SecondsToWait;
        
    AnItem = GetURL( 60, URL );

    if( AnItem && AnItem->SizeOfData )
    {
//      SaveBytesToFile( "Test3", AnItem->DataAddress, AnItem->SizeOfData );
    
        AtContent =
            ReferToEntityBodyOfHTTPResponse( AnItem->DataAddress,
                                             AnItem->SizeOfData, 
                                             &ByteCount );
        if( AtContent )
        {
            SaveBytesToFile( FileName, AtContent, ByteCount );
            SetFileType( FileName, (s8*) "JPEG" );
        }
        
        // Free the data buffer.
        free( AnItem->BufferAddress );
    }
    
    // Free the item record itself.
    if( AnItem ) DeleteItem( AnItem );
}

#if 0   
    {
        Item*   AnItem;
        s32     ByteCount;
        u8*     AtContent;
        s8      URLBuffer[256];
        s8      FileNameBuffer[40];
        s8      NumberString[20];
        s32     i;
        
        for( i = 1; i < 22; i++ )
        {
            if( i == 11 || i == 20 ) continue;
            
            ConvertIntegerToString( i, NumberString );

            // Make the URL string.
            URLBuffer[0] = 0;
            AppendStrings( URLBuffer,
                           "http://www.somesite.com",
                           NumberString,
                           ".jpg", 0 );
                           
            // Make file name string.
            FileNameBuffer[0] = 0;
            AppendStrings( FileNameBuffer,
                           "file",
                           NumberString,
                           ".jpg" );
            Note( "%s\n", FileNameBuffer );               
            GetURLToJPEGFile( 60, URLBuffer, FileNameBuffer );
        }              
 
        ExitToShell();
    }
#endif
                            
/*------------------------------------------------------------
| IsEntityBodyIncomplete
|-------------------------------------------------------------
| 
| PURPOSE: To test for a mismatch between the 'Content-Length'
|          header value, if any, and the actual data received.
|
| DESCRIPTION: Returns 1 if the specified content length
| exceeds the length of the body.
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
IsEntityBodyIncomplete( u8* AtResponse, s32 ByteCount )
{
    s32 Status;
    u8* AtBody;
    s32 BodyByteCount;
    s32 ContentLength;
    
    // First check to see if there is a header.
    Status = GetHTTPResponseStatus( AtResponse );
    
    // If there is no header then the body can't be judged
    // incomplete.
    if( Status == HTTP_SimpleResponse )
    {
        return( 0 ); // No specified length so no mismatch.
    }
    
    // Get the content length specified in the header of
    // the response.  A negative value means it wasn't specified.
    ContentLength = 
        GetHTTPResponseContentLength( AtResponse, ByteCount );
        
    if( ContentLength < 0 )
    {
        return( 0 ); // No specified length so no mismatch.
    }
    
    // Find the length of the entity body by locating the 
    // delimiter.
    
    AtBody =
        ReferToEntityBodyOfHTTPResponse( AtResponse,
                                         ByteCount, 
                                         &BodyByteCount );
                                         
    // If the body byte count is less than the specified 
    // length then the body is incomplete.
    if( BodyByteCount < ContentLength )
    {
        return( 1 );
    }
    else
    {
        return( 0 );
    }
}

/*------------------------------------------------------------
| MakeGetURLRequestString
|-----------------------------------------------------------*/
// 
// PURPOSE: To make an HTTP request string to get a given URL.
//
// DESCRIPTION: Mimics the request string produced by Netscape
//              3.01 Gold for the Mac.
//
// Returns 'noErr' if the string was made OK, else some other
// error code.
//
// EXAMPLE: 
//
// err = MakeGetURLRequestString( "http://www.cnn.com/test.htm", 
//                                &Buffer, BufSize );
//
// results in the following being placed in 'Buffer':
// 
//   GET /test.htm HTTP/1.0<CRLF>
//   Connection: Keep-Alive<CRLF>
//   User-Agent: Mozilla/3.01Gold (Macintosh; I; PPC)<CRLF>
//   Host: www.cnn.com<CRLF>
//   Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, */*<CRLF>
//   Accept-Language: en-US<CRLF>
// 
// NOTE: 
// 
// ASSUMES:
// 
// HISTORY:
//------------------------------------------------------------
s32
MakeGetURLRequestString( s8* URL, s8* Buffer )
{
    u32     IsURLBad;
    s8      Scheme[20];
    s8      User[64];
    s8      Password[64];
    s8      Host[512];
    s8      Port[20];
    s8      Path[512];
    s8      CRLFs[3];
    
    // Make the end of line string.
    CRLFs[0] = CarriageReturn;
    CRLFs[1] = LineFeed;
    CRLFs[2] = 0;

    // Cut the URL string into parts.
    IsURLBad = ParseURL( URL, 
                         Scheme, 
                         User, 
                         Password, 
                         Host,
                         Port, 
                         Path );
    
    // Return with an error if there was a parsing problem.                  
    if( IsURLBad ) return( 1 );
    
    // Return with an error if this isn't an 'http' scheme.
    if( IsSchemeHTTP( Scheme ) == 0 ) return( 2 );
    
    // If the host is missing then return with an error.
    if( Host[0] == 0 ) return( 3 );
    
    // Append the strings to the result buffer.
    Buffer[0] = 0; // Empty the buffer first.
    
    AppendStrings( 
        Buffer,   
        (s8*) "GET ", &Path, (s8*) " HTTP/1.0", &CRLFs, 
        (s8*) "Connection: Keep-Alive", &CRLFs,
        (s8*) "User-Agent: Mozilla/3.01Gold (Macintosh; I; PPC)", &CRLFs,
        (s8*) "Host: ", &Host, &CRLFs,
        (s8*) "Accept: image/gif, image/x-xbitmap, image/jpeg, image/pjpeg, */*", &CRLFs, 
        (s8*) "Accept-Language: en-US", &CRLFs,
        &CRLFs, // Two CRLF's in a row signal the end of the request.
        (s8*) 0 ); // <-- 0 terminates parameter list
    
    // Return 0 indicating no error occurred.
    return( 0 );
}

/*------------------------------------------------------------
| MakeHTTPRequestRecord
|-------------------------------------------------------------
| 
| PURPOSE: To make a new HTTP request record.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.16.96 from 'MakeStreamBuffer'.
------------------------------------------------------------*/
HTTPRequest*
MakeHTTPRequestRecord()
{
    HTTPRequest*    Req;
    
    Req = (HTTPRequest*) malloc( sizeof( HTTPRequest ) );
        
    FillBytes( (u8*) Req, (u32) sizeof(HTTPRequest), 0 );
    
    return( Req );
}

/*------------------------------------------------------------
| MoveHTTPRequestToCompletedList
|-------------------------------------------------------------
| 
| PURPOSE: To move an HTTP request to the completed list and
|          release any open stream associated with it.
|
| DESCRIPTION: 
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.17.96 
------------------------------------------------------------*/
void
MoveHTTPRequestToCompletedList( HTTPRequest* r )
{   
    // Remove the request from the 'PendingHTTPRequests'
    // list.
    DeleteAllReferencesToData( PendingHTTPRequests, (u8*) r );
    
    // Insert it in the list of completed requests.
    InsertDataLastInList( CompletedHTTPRequests, (u8*) r );

    // If there is a stream, get rid of it.
    if( r->Strm )
    {
        // Close the stream.
        CloseTCPStream( r->Strm );
    }
    
    // Mark the stream as released.
    r->Strm = 0;
}

/*------------------------------------------------------------
| ManagePendingHTTPRequest
|-------------------------------------------------------------
| 
| PURPOSE: To manage the transfer of a single web document 
|          request.
|
| DESCRIPTION:  
|
| EXAMPLE: 
|
| NOTE:  
| 
| ASSUMES: 
| 
| HISTORY: 12.17.96 from 'ClosePendingStreams'.
------------------------------------------------------------*/
void
ManagePendingHTTPRequest( HTTPRequest*  r ) 
{           
    Stream*     s;
    s32         st;
    s8          Host[256];
    s8          RequestBuffer[4096];
    u32         RemoteIP;
    s32         err;

    // First check to see if the request timed out.
    if( TickCount() > r->TicksWhenTimesOut )
    {
        // Abort the request.
        r->ResponseStatus = HTTP_TimedOut;
                
        // Also closes any open stream.
        MoveHTTPRequestToCompletedList( r );
        
        return;
    }

    // Still time left to get the document.
    
    // Refer to the stream.
    s = r->Strm;
                
    // If there is no stream allocated to this
    // request, make one.
    if( s == 0 )
    {
        r->Strm = MakeStreamBuffer();
                
        // Register the stream with OT and configure
        // it for TCP.  Idle and notifier routines 
        // will do the work
        RequestOpenStreamEndpointAsTCP( r->Strm );
        
        return;
    }

    // There is a stream assigned.

    // Move the process along depending on the state of the endpoint.
    st = GetEndpointState( s );

    switch( st )
    {
        case T_UNINIT:
        {
            // Wait for the endpoint to be configured
            // for TCP.
            return;
        }
                        
        case T_UNBND:
        {
            // Either the document has been recieved
            // and the connection closed or no
            // attempt has been made to get the
            // document.
            if( s->BytesToRead )
            {
                // To complete the reception of a response
                // or set up for a retry depending on the
                // type of the response.
                CompleteOrRetryHTTPResponse( r );
            }
            else // Set up to request a document.
            {
                // If we are waiting to bind don't
                // do anything.
                if( s->IsBindPending )
                {
                    return;
                }
                else // Bind the stream to any
                     // local port.  This proceeds
                     // asynchronously.
                {
                    RequestBindStreamToLocalPort( s, 0, 0, 1 );
                }
            }
                            
            return;
        }
                        
        case T_IDLE: // Ready to make a request.
        {
            // Parse the host from the URL.
            err = ParseDomainNameFromURL( Host, r->URL );
                    
            // If the URL is parsed with an error complete
            // the request with an error.
            if( err )
            {
                r->ResponseStatus = HTTP_BadURL;
                        
                CompleteOrRetryHTTPResponse( r );
                return;
            }
                    
            // Look for the IP address of the host in the
            // local cache.
            RemoteIP = LookUpDomainNameInCache( Host );
            
            // If the IP address was found.
            if( RemoteIP )
            {
                // Make the document request command string.
                err = MakeGetURLRequestString( r->URL, RequestBuffer );
                        
                // An error here comes from not having scheme
                // be 'http'.
                if( err )
                {
                    r->ResponseStatus = HTTP_UnsupportedScheme;
                        
                    CompleteOrRetryHTTPResponse( r );
                    return;
                }
                
                // Put the request into the stream before we 
                // connect to the host so that it will be sent 
                // in due course.
                PutOutgoingDataIntoStream( r->Strm, 
                                           (u8*) RequestBuffer, 
                                           CountString( RequestBuffer ) );
                        
                // Request an active TCP connection be established.
                            
                OTInitInetAddress( &r->Strm->RemoteAddressRequest, 
                                   HTTPPort, 
                                   RemoteIP );
    
                // Enable connection during network idle processing.
                r->Strm->IsActiveConnectionPending = 1;
            }
            else // Request the IP from DNS if not already done so.
            {
                // If a DNS request is already pending for this host.
                if( IsDNSRequestPendingForDomainName( Host ) )
                {
                    return; // Just wait.
                }
                else
                {
                    // Give DNS 3 minutes to add the IP address to
                    // the cache where it will be found on a subsequent pass.
                    r->DNSReq = 
                        RequestDNSToAddDomainNameToCache( 180, Host );
                        
                    // Note that when the DNS request is filled
                    // the reference to the request will be stale.
                    // A check must be made to find the request in
                    // the pending request list before accessing the
                    // DNS request record.
                }
            }
            
            return;
        }
        
        // Any other endpoint state means there is nothing to do
        // but wait.
        default: return;
    }
}

/*------------------------------------------------------------
| ReferToEntityBodyOfHTTPResponse
|-------------------------------------------------------------
| 
| PURPOSE: To refer to the entity body part of an HTTP 
|          response.
|
| DESCRIPTION: Returns the address of the entity body part of 
| an HTTP response and a count of how many bytes there are,
| that is, everything following the header, if there is one.
|
| Returns 0 if the content isn't complete.
|
| EXAMPLE:  AtContent = 
|               ReferToContentOfHTTPResponse( AnItem,
|                                             &Count );
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.15.96
|          12.17.96 added handling for simple responses.
------------------------------------------------------------*/
u8*
ReferToEntityBodyOfHTTPResponse( u8*   AtResponse,
                                 s32   ResponseByteCount, 
                                 s32*  ContentByteCount )
{
    u8* AtContent;
    u8* AtCRLFCRLF;
    u32 ContentLength;
    s32 status;
    
    // Reject empty responses.
    if( AtResponse == 0 || ResponseByteCount == 0 )
    {
        return( 0 );
    }

    // Determine if this is a simple response.
    status = GetHTTPResponseStatus( AtResponse );
    
    // If this is a simple response then there is no header.
    // The entity-body is the entire response.                              
    if( status == HTTP_SimpleResponse )
    {
        *ContentByteCount = ResponseByteCount;
        
        return( AtResponse );
    }
     
    // Find the 'CRLFCRLF' that marks the boundary between 
    // the header and the body. 
 
    AtCRLFCRLF = FindBytesInBytes( (u8*) CRLFCRLF, 4,  
                                   AtResponse,  
                                   ResponseByteCount );  
                                             
    if( AtCRLFCRLF == 0 ) return( 0 );
    
    // Refer to the beginning of the content.
    AtContent = AtCRLFCRLF + 4;
    
    // Compute the content length.
    ContentLength = ResponseByteCount - 
                    ( AtContent - AtResponse );
 
    *ContentByteCount = ContentLength;
                
    // Make sure the nominal byte count doesn't exceed the actual 
    // byte count.
    if( ContentLength > 0 )
    {
        return( AtContent );
    }
    else // Partial content.
    {
        return( 0 );
    }
}

/*------------------------------------------------------------
| RequestURL
|-------------------------------------------------------------
| 
| PURPOSE: To request that a web document be fetched within a 
|          time period.
|
| DESCRIPTION: Use this procedure to submit a request for the
| fetching of a web document asynchonously and optionally
| saving the result to a file.    
|
| This procedure places the request on the 'PendingHTTPRequests'
| list and returns with the address of the request record.
|
| An idle routine handles the process of getting the document.
|
| The status of the request can be read from the request record.
|
| When the request is completed, the request is removed from
| the 'PendingHTTPRequests' list and added to the 
| 'CompletedHTTPRequests' list or optionally deleted after the 
| file is saved.
|
| Expects time limit in seconds.
|
| EXAMPLE:  req = RequestURL( 120,   
|                             "http://cnn.com/",
|                             "ResponseFile",
|                             "EntityBodyFile",     
|                             "TEXT",
|                             "CWIE",
|                             1 );  
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.16.96
------------------------------------------------------------*/
HTTPRequest*
RequestURL( s32 SecondsTillTimeOut, // Maximum time available
                                    // to complete the request.
                                    // 
            s8* URL,                // Reference to the 
                                    // web document.
                                    //
            s8* ResponsePath,       // If non-0, path to
                                    // entire response data.
                                    //
            s8* EntityBodyPath,     // If non-0, path where
                                    // the entity body should
                                    // be saved.
                                    //
            s8* EntityBodyFileType, // If non-0, the 4-digit
                                    // file type to be used
                                    // for the entity body 
                                    // file, eg. "TEXT".
                                    //
            s8* EntityBodyCreator,  // If non-0, the 4-digit
                                    // creator to be used
                                    // for the entity body 
                                    // file, eg. "CWIE".
                                    //
            u32   IsDeleteOnCompletion ) // 1 if the request
                                    // should be deleted after
                                    // saving the result to a
                                    // file.
{
    HTTPRequest*    Req;
    
    // Make a new request record.
    Req = MakeHTTPRequestRecord();

    // Set the request timestamp.
    Req->TicksWhenRequested = TickCount();
    
    // Set the time when this request times out.
    Req->TicksWhenTimesOut = TickCount() + 
                             SecondsTillTimeOut * 60;
    
    // Copy the URL to the request record.
    CopyString( URL, Req->URL );
    
    // Copy the response file path to the request record.
    if( ResponsePath )
    {
        CopyString( ResponsePath, Req->ResponsePath );
    }
    
    // Copy the entity-body file path to the request record.
    if( EntityBodyPath )
    {
        CopyString( EntityBodyPath, Req->EntityBodyPath );
    }
    
    // Copy the entity-body file type to the request record.
    if( EntityBodyFileType )
    {
        CopyString( EntityBodyFileType, Req->EntityBodyFileType );
    }
    
    // Copy the entity-body file creator to the request record.
    if( EntityBodyCreator )
    {
        CopyString( EntityBodyCreator, Req->EntityBodyCreator );
    }
    
    // Set the deletion flag.
    Req->IsDeleteOnCompletion = IsDeleteOnCompletion;
    
    // Add the request to the pending request list.
    InsertDataLastInList( PendingHTTPRequests, (u8*) Req );
    
    // Return the address of the request record.
    return( Req );
}

/*------------------------------------------------------------
| SaveHTTPResponseToGivenFiles
|-------------------------------------------------------------
| 
| PURPOSE: To save the HTTP response received as the result of
|          a request to a one or more files as specified in
|          the request record.
|
| DESCRIPTION: Also sets the file type and creator if given.
|
| EXAMPLE: 
|
| NOTE: 
| 
| ASSUMES: 
| 
| HISTORY: 12.17.96
|          12.20.96 set file type and creator for response
|                   file to default text file made by Code 
|                   Warrior.
------------------------------------------------------------*/
void
SaveHTTPResponseToGivenFiles( HTTPRequest* r )
{
    u8* AtContent;
    s32 ByteCount;
    
    // Save entire response if a filename was given.
    if( r->ResponsePath[0] )
    {
        // The file type will be binary.
        // Could set creator to Norton Disk Editor.
        SaveBytesToFile( r->ResponsePath, 
                         r->Response->DataAddress,
                         r->Response->SizeOfData );
        
        // Set the file type to 'TEXT' as default.
        SetFileType( r->ResponsePath, (s8*) "TEXT" );
 
        // Set the file creator to 'CWIE' as default.
        SetFileCreator( r->ResponsePath, (s8*) "CWIE" );
        
        Note( (s8*) "Saved '%s'.\n", r->ResponsePath );
    }
                                        
    // Save response body if a filename was given.
    if( r->EntityBodyPath[0] )
    {       
        // Locate the beginning of the entity body.
        AtContent =
            ReferToEntityBodyOfHTTPResponse( r->Response->DataAddress,
                                             r->Response->SizeOfData, 
                                             &ByteCount );
                                            
        // Save the body.
        SaveBytesToFile( r->EntityBodyPath, 
                         AtContent,
                         ByteCount );

        Note( (s8*) "Saved '%s'.\n", r->EntityBodyPath );
                                            
        // Set the file type if given.
        if( r->EntityBodyFileType[0] )
        {
            SetFileType( r->EntityBodyPath, 
                         r->EntityBodyFileType );
        }

        // Set the file creator if given.
        if( r->EntityBodyCreator[0] )
        {
            SetFileCreator( r->EntityBodyPath, 
                            r->EntityBodyCreator );
        }
    }
}

#endif // FOR_MACOS

