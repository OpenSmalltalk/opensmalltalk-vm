/*------------------------------------------------------------
| NAME: TLHTTP.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface for HTTP procedures.
|
| DESCRIPTION:  
|
| NOTE: 
|
| HISTORY: 12.13.96
------------------------------------------------------------*/
    
#ifndef _HTTP_H_
#define _HTTP_H_

// HTTP Response status codes:
        // Success
#define HTTP_OK             200
#define HTTP_Created        201
#define HTTP_Accepted       202
#define HTTP_NoContent      204
#define HTTP_SimpleResponse 299 // My code.
        
        // Redirection
#define HTTP_MovedPermanently   301
#define HTTP_MovedTemporarily   302
#define HTTP_NotModified        304

        // Client Error
#define HTTP_BadRequest         400
#define HTTP_Unauthorized       401
#define HTTP_Forbidden          403
#define HTTP_NotFound           404

        // Server Error
#define HTTP_InternalServerError    500
#define HTTP_NotImplemented         501
#define HTTP_BadGateway             502
#define HTTP_ServiceUnavailable     503

        // Error
#define HTTP_TimedOut               600 // My code.
#define HTTP_BadURL                 601 // My code.
#define HTTP_UnsupportedScheme      602 // My code.

// All info about an HTTP request.
typedef struct
{
    s32     ResponseStatus; // The three digit HTTP response
                            // status code: see above.  Zero until
                            // the request is completed, one way or
                            // another.
                            //
    s8      URL[512];       // The URL of the document requested.
                            //
    s8      ResponsePath[256]; // If non-zero, this is where the
                            // complete response should be saved.
                            // This includes both the HTTP
                            // header and the entity-body parts.
                            //
    s8      EntityBodyPath[256]; // If non-zero, this is where the
                            // entity-body part of the response
                            // should be saved.
                            //
    s8          EntityBodyFileType[8]; // If non-zero, this is the 4 byte
                            // file type string to be used for 
                            // the entity body file, eg. "TEXT" 
                            // or "JPEG". Zero-terminated.
                            //
    s8          EntityBodyCreator[8]; // If non-zero, this is the 4 byte
                            // file creator string to be used for 
                            // the entity body file, eg. "CWIE"  
                            // or "MPS ". Zero-terminated.
                            //
    u32         IsDeleteOnCompletion; // 1 if the request should be
                            // deleted after completing the request
                            // and optionally saving the response
                            // to a file.  0 if the request
                            // is to be moved to the 
                            // 'CompletedHTTPRequests' instead.
                            //
    u32         IsContentIncomplete; // 1 if the 'Content-Length'
                            // specified within the response
                            // header exceeds the entity-body data 
                            // received.
                            //
    s32     TicksWhenRequested; // System tick (1/60th sec) time 
                            // when the request is submitted.
                            //
    s32         TicksWhenTimesOut; // System tick time when the request
                            // is aborted.
                            //
    s32         TicksWhenConnected; // System tick time when the remote 
                            // host was most recently connected.
                            //
    s32     TicksWhenDisconnectBegins; // System tick time when the 
                            // remote host most recently began
                            // disconnecting.
                            //
    s32     RetryCount; // Incremented each time a retry is
                            // made: 0 if successful on first try.
                            //
    Item*       Response;   // Refers to a dynamic buffer that
                            // holds the entire response received.
                            //
    Stream*     Strm;       // The stream used for the transmission 
                            // of the data.
                            //
    DNSRequest* DNSReq;     // Reference to a DNS request generated
                            // during the satisfaction of this
                            // HTTP request.
} HTTPRequest;  
    
extern List*    PendingHTTPRequests;   // List of pending HTTP 
                                       // requests.
                                       //
extern List*    CompletedHTTPRequests; // List of HTTP requests that
                                       // have been completed.
    
/* -------------------PROTOTYPES----------------------------- */

void            CompleteOrRetryHTTPResponse( HTTPRequest* );
void            DeleteHTTPRequest( HTTPRequest* );
s32             GetHTTPResponseContentLength( u8*, s32 );
s32             GetHTTPResponseStatus( u8* );
OSErr           GetIPFromURL( u32*, s8* );
Item*           GetURL( s32, s8* );
void            GetURLToJPEGFile( s32, s8*, s8* );
u32             IsEntityBodyIncomplete( u8*, s32 );
s32             MakeGetURLRequestString( s8*, s8* );
HTTPRequest*    MakeHTTPRequestRecord();
void            ManagePendingHTTPRequest( HTTPRequest* );
void            MoveHTTPRequestToCompletedList( HTTPRequest* );
u8*             ReferToEntityBodyOfHTTPResponse( u8*, s32, s32* );
HTTPRequest*    RequestURL( s32, s8*, s8*, s8*, s8*, s8*, u32 );
void            SaveHTTPResponseToGivenFiles( HTTPRequest* );

#endif
