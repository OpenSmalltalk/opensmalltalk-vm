/*------------------------------------------------------------
| TLNetAsyncNT.c
|-------------------------------------------------------------
|
| PURPOSE: To provide network idle functions
|
| DESCRIPTION: This is work in progress and has not been
|              tested.
|        
| HISTORY: 12.07.96 pulled out of 'NetAccess.c'.
------------------------------------------------------------*/

#include "TLTarget.h"  

#if defined(FOR_WINNT) | defined(FOR_WIN98) | defined(FOR_WIN2000)  

#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <stdio.h>

#include "TLTypes.h" 
#include "TLAscii.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStacks.h"
#include "TLParse.h"
#include "TLList.h"
#include "TLWin.h"
#include "TLLog.h"
#include "TLDate.h"

#include "TLNetNT.h"
#include "TLNetAsyncNT.h"

// This is where data is initially received.  It is big
// enough to hold the largest data unit that TCP can send.
#define SizeOfRecieveBuffer (64*1024)
 
Item* TheCurrentStreamItem = 0;
        // The item record in TheStreamList that refers to
        // the current stream that should be operated.
   
/*------------------------------------------------------------
| HandleAsynchronousNetworkOperations
|-------------------------------------------------------------
| 
| PURPOSE: To process pending network operations.
|
| DESCRIPTION: This function should be called frequently.
|
| This procedure does a small amount of work and then 
| returns.
|
| Handles asynchronous operations for streams.  
|
| In general, female operations are done before male
| operations to avoid deadlock conditions.
|
| ASSUMES: 
| 
| HISTORY: 11.19.96 reformatted.
|          12.05.96 pulled out code for closing connections:
|                   now handled by the notifier.
|          12.07.96 added many async operations.
|          08.21.00 Deleted HTTP, DNS and active TCP support
|                   to quickly port to NT.
|          08.23.00 Added general network health monitor and
|                   connect/disconnect functions.
|          09.09.00 Name changed from NetIdle.
------------------------------------------------------------*/
void
HandleAsynchronousNetworkOperations( f64 MaxTime )
    // MaxTime is the maximum amount of time that can be
    // spent in this function, in seconds.
{
    f64 TimeAtEntry, TimeAtExit, TimeForEachStream;
    f64 CurrentTime, EndTimeForThisStream;
    
    // Read the CPU timestamp register in seconds.
    TimeAtEntry = ReadTimeStampInSeconds();
    
    // Calculate the time after which no more work can be
    // done by this routine.
    TimeAtExit = TimeAtEntry + MaxTime;

    // If asynchronous network operations are enabled and
    // there are active streams.
    while( IsAsynchronousNetOperationsEnabled &&
           TheStreamList->ItemCount ) 
    {
        // Read the current time in seconds.
        CurrentTime = ReadTimeStampInSeconds();
        
        // If all time available has been used up.
        if( CurrentTime > TimeAtExit ) 
        {
            // Then just return.
            return;
        }
            
        // Calculate the maximum amount of time to allot to 
        // each active stream.  The proportion of time
        // diminishes to zero as time expires.
        TimeForEachStream = 
            ( TimeAtExit - CurrentTime ) / 
            (f64) TheStreamList->ItemCount;
    
        // Calculate the time limit for the stream.
        EndTimeForThisStream = CurrentTime + TimeForEachStream;
        
        // If the general network connection is active.
        if( IsNetworkConnected )
        {
            // Detect general network interface failure if no 
            // data  has arrived on any socket in the last 10 
            // seconds.
            if( IsIncomingDataLate() )
            {
                // Abort all open streams.
//              AbortAllOpenStreams();
                
                // Disconnect the general network connection.
                IsNetworkConnected = 0; 
            }
 
            // If there is a current stream selected.
            if( TheCurrentStreamItem )
            {
                // Do some work with the current stream.
                OperateStreamUntilTimeLimit( 
                    (Stream*) 
                    TheCurrentStreamItem->DataAddress,
                        // The stream that work should be
                        // done for.
                        //
                    EndTimeForThisStream );
                        // The time after which the stream
                        // should not do any more work.
                        
                // Advance to the next stream so more work
                // can be done on the next pass: this is
                // a zero-terminated linked list.
                TheCurrentStreamItem = 
                    TheCurrentStreamItem->NextItem;
            }
            else // No current stream is selected.
            {
                // If there are streams in the stream list.
                if( TheStreamList->ItemCount )
                {
                    // Select the first stream.
                    TheCurrentStreamItem = 
                        TheStreamList->FirstItem;
                }
            }
        }
        else
        {
            // Make the general network connection to the OS 
            // network driver.
            IsNetworkConnected = ConnectToNetwork();
        }
    }
}   
  
/*------------------------------------------------------------
| OperateStream
|-------------------------------------------------------------
| 
| PURPOSE: To do a bit of work for the given stream.
|
| DESCRIPTION: This procedure does a small amount of work and 
| then returns.
|
| Handles both synchronous and asynchronous operations for 
| a stream.  
|
| ASSUMES: Stream is in the goal operating state.
| 
| HISTORY: 09.17.00 Factored out of 
|                   OperateStreamUntilTimeLimit.
------------------------------------------------------------*/
void
OperateStream( 
    Stream* S, 
        // The stream that work should be done for.
        //
    f64 TimeAtExit )
        // TimeAtExit is the deadline beyond which work
        // should not be done for the stream, in CPU 
        // timestamp seconds.
{
    u32      IsInProgress;
    int      addr_len;
    struct   sockaddr_in client_addr;
    ASocket* AcceptSocket;
    
    // Depending on the operating state.
    switch( S->State )
    {
        case UNINITIALIZED:
        {
            // Initialize needed sockets of the stream.
            InitializeSocketsOfStream( S );
        
            break;
        }
            
        case INITIALIZED:
        {
            // Do some work toward binding all sockets 
            // needed for a stream.
            BindSocketsOfStream( S );
        
            break;
        }
            
        case BOUND:
        {
            // If the goal state is to be receiving data.
            if( S->GoalState == RECEIVE )
            {
                // If the protocol is TCP.
                if( S->Protocol == TCP )
                {
                    // Then a connection is required.
        
                    // If the connection logic is for
                    // the other end to initiate the 
                    // connection.
                    if( S->ConnectionLogic == FEMALE )
                    {
                        // Move to the listening mode.
                        S->State = LISTEN;
                    }
                    else // This end should initiate
                         // the connection.
                    {
                        // Move to the MALE connection mode.
                        S->State = CONNECT;
                    }
                }
                else // Not TCP.
                {
                    // If the protocol is UDP.
                    if( S->Protocol == UDP )
                    {
                        // Then no connection is required.
                        
                        // Move to the receiving mode.
                        S->State = RECEIVE;
                    }
                }
            }
            else // Goal state is not to be receiving
                 // data.
            {
                ; // Implement other modes later as
                  // needed.
            }
            
            break;
        }   
            
        case LISTEN:
        {
            // Listen to the socket using a maximum queue 
            // length of 1 for incoming connection requests.
            S->LinkSocket.LastResult = 
                listen( S->LinkSocket.S, (s32) 1 );
            
            // If a valid connection request is not pending.
            if( S->LinkSocket.LastResult == SOCKET_ERROR )
            {
                // Cope with a listen error condition.
                IsInProgress = OnListenError( S );
                
                // If a listen is in progress.
                if( IsInProgress )
                {
                    // Stay in the LISTEN state until it
                    // completes.
                    ;
                }
                else // An error occurred which ends the 
                     // current connection attempt.
                {
                    // Regress the stream to the UNINITIALIZED
                    // state.
                    
                    // Close the listening socket.
                    AbortSocket( &S->LinkSocket );
                    
                    // Mark the socket as missing.
                    S->LinkSocket.S = 0;
                    
                    // Enter the origin state so that another
                    // connection can be made later.
                    S->State = UNINITIALIZED;
                }
            }
            else // A valid connection request has been 
                 // received.
            {
                // Enter the state of making a particular 
                // connection.
                S->State = ACCEPT;
                
                // Use the input timer to limit the amount time 
                // that will be allowed to make a pending 
                // connection.
                S->LastInputTime = ReadTimeStampInSeconds();
            }
            
            break;
        }
        
        case ACCEPT:
        {
            // Calculate the size of the client address record 
            // that will be used in the accept() call.
            addr_len = sizeof( client_addr );

            // If data is received on the link socket.
            if( S->IsLinkSocketUsedForData )
            {
                // Refer to the link socket as the accept
                // socket.
                AcceptSocket = &S->LinkSocket;
            }
            else // The data socket should be used.
            {
                // Refer to the data socket as the accept
                // socket.
                AcceptSocket = &S->DataSocket;
            }
            
            // Attempt to complete the pending connection, 
            // but don't block.
            AcceptSocket->LastResult = 
                accept( S->LinkSocket.S, 
                        (struct sockaddr*) &client_addr, 
                        &addr_len );

            // If unable to complete the connection.
            if( AcceptSocket->LastResult == INVALID_SOCKET )
            {
                // Cope with an accept error condition.
                IsInProgress = OnAcceptError( S );
                
                // If an accept is in progress.
                if( IsInProgress )
                {
                    // Just return to try to accept again later.
                    ;
                }
                else // An error occurred which ends the current
                     // connection attempt.
                {
                    // Regress the stream to the UNINITIALIZED
                    // state.
                    
                    // Close the listening socket.
                    AbortSocket( &S->LinkSocket );
                    
                    // Mark the socket as missing.
                    S->LinkSocket.S = 0;
                    
                    // Enter the origin state so that another
                    // connection can be made later.
                    S->State = UNINITIALIZED;
                }
            }
            else // A valid connection was made.
            {
                // Transition to the main duty mode.
                S->State = S->GoalState;
            }
            
            break;
        }
        
        case SEND:
        {
            // Send some data from working buffers.
            SendSomePendingDataForStream( 
                S,  // The stream that work should be 
                    // done for.
                    //
                TimeAtExit );
                    // TimeAtExit is the deadline 
                    // beyond which reading should not 
                    // be done for the stream, in CPU 
                    // timestamp seconds.
            
            break;
        }
        
        case RECEIVE:
        {
            // Read some data into working buffers.
            ReadSomePendingDataForStream( 
                S,  // The stream that work should be 
                    // done for.
                    //
                TimeAtExit );
                    // TimeAtExit is the deadline 
                    // beyond which reading should not 
                    // be done for the stream, in CPU 
                    // timestamp seconds.
            
            break;
        }
        
        case SEND_AND_RECEIVE:
        {
            // Read some data into working buffers.
            ReadSomePendingDataForStream( 
                S,  // The stream that work should be 
                    // done for.
                    //
                TimeAtExit );
                    // TimeAtExit is the deadline 
                    // beyond which reading should not 
                    // be done for the stream, in CPU 
                    // timestamp seconds.
                    
            // Send some data from working buffers.
            SendSomePendingDataForStream( 
                S,  // The stream that work should be 
                    // done for.
                    //
                TimeAtExit );
                    // TimeAtExit is the deadline 
                    // beyond which reading should not 
                    // be done for the stream, in CPU 
                    // timestamp seconds.
                    
            break;
        }
    }
}

/*------------------------------------------------------------
| OperateStreamUntilTimeLimit
|-------------------------------------------------------------
| 
| PURPOSE: To do a bit of work for the given stream.
|
| DESCRIPTION: This procedure does a small amount of work and 
| then returns.
|
| Handles asynchonous operations for a stream.  
|
| ASSUMES: Stream is active and is TCP protocol.
| 
| HISTORY: 09.09.00 Factored out of 
|                   HandleAsynchronousNetworkOperations.
|          09.13.00 Fleshed out send and receive.
|          09.17.00 Factored out OperateStream and 
|                   MoveStreamToOperatingState.
|          09.24.00 Revised to use OperateStream.
------------------------------------------------------------*/
void
OperateStreamUntilTimeLimit( 
    Stream* S,
        // The stream that work should be done for.
        //
    f64 TimeAtExit )
        // TimeAtExit is the deadline beyond which work
        // should not be done for the stream, in CPU 
        // timestamp seconds.
{
    // If the stream is inactive.
    if( S->IsActive == 0 )
    {
        // Just return.
        return;
    }
    
    // While time remains to do work with this stream.
    while( ReadTimeStampInSeconds() < TimeAtExit ) 
    {
        // Do some work for the stream.
        OperateStream( S, TimeAtExit );
    }
}   
    
/*------------------------------------------------------------
| ReadSomePendingDataForStream
|-------------------------------------------------------------
| 
| PURPOSE: To recieve some pending data for a stream and
|          buffer it in the IncomingData buffer list.
|
| DESCRIPTION: Returns if no more data is currently available.
|
| Handles asynchonous read operations for a stream.  
|
| ASSUMES: 
|
|   Stream is active.
|
|   If protocol is TCP then the stream is connected.
| 
|   Operates during 'HandleAsynchronousNetworkOperations()' only.
|
|   Input protocol may be UDP or TCP.
|
| HISTORY: 12.07.96 pulled out of 
|                   'HandleAsynchronousNetworkOperations'.
|          01.16.97 fixed confusion of normal data with
|                   expedited data.
|          08.22.00 Revised for NT.09.13.00 from 
|                   AppendDataToBufferList to avoid extra
|                   data motion.
|          09.24.00 Revised.
------------------------------------------------------------*/
void
ReadSomePendingDataForStream( 
    Stream* S,  
        // The stream that should be read.
        //
    f64 TimeAtExit )
        // TimeAtExit is the deadline beyond which reading 
        // should not be done for the stream, in CPU 
        // timestamp seconds.
{
    Item*    ABufferItem;
    u32      BytesToRead;
    u8*      ABuffer;
    u8*      AfterDataInBuffer;
    u32      BytesAvailableInLastBuffer;
    u32      BytesToReadThisPass;
    s32      BytesJustRead;
    ASocket* ReadSocket;
    
    // If data should be read on the link socket.
    if( S->IsLinkSocketUsedForData )
    {
        // Refer to the link socket as the one through
        // which data should come.
        ReadSocket = &S->LinkSocket;
    }
    else // The data socket should be used.
    {
        // Refer to the data socket as the one through
        // which data should come.
        ReadSocket = &S->DataSocket;
    }
    
    // While time remains to do work with this stream.
    while( ReadTimeStampInSeconds() < TimeAtExit ) 
    {
        // Test for available bytes to read from
        // network layer.
        ReadSocket->LastResult = 
            ioctlsocket( 
                ReadSocket->S, 
                (s32) FIONREAD, 
                &BytesToRead ); 
        
        // If there was an error checking for data. 
        if( ReadSocket->LastResult )  
        {
            // Get the specific error.
            S->DataSocket.LastError = WSAGetLastError(); 
        
            // Return on a data test error.
            return;
        }
        else // The test for data was OK.
        {
            // If there are no bytes to read right now.
            if( BytesToRead == 0 )
            {
                // Then just return.
                return;
            }
            
            // If there is no buffer list. 
            if( S->IncomingData == 0 )
            {
                // Make a list for incoming data.
                S->IncomingData = MakeList();
            }
                
            // Refer to the buffer list.
            ReferToList( S->IncomingData );
            
            // Refer to the last buffer in the list.
            ToLastItem();
            
            // If there is no last buffer or the buffer
            // is full.
            if( ( TheItem == 0 ) ||
                ( TheItem->SizeOfBuffer == TheItem->SizeOfData ) )
            {
                // Allocate a new data buffer.
                ABuffer = (u8*) malloc( SizeOfStreamDataBuffer );
                
                // Insert the buffer in the list.  This sets the
                // buffer and data address to the same value.
                ABufferItem = 
                    InsertDataLastInList( TheList, ABuffer );

                // Set the buffer size.
                ABufferItem->SizeOfBuffer = SizeOfStreamDataBuffer;
                
                // Initially there will be no data.
                ABufferItem->SizeOfData = 0; 
            }

            // Refer to the last buffer in the list.
            ToLastItem();
            
            // Calculate the position where new data should be
            // put in the buffer.
            AfterDataInBuffer = TheDataAddress + TheDataSize;
            
            // Calculate the space available in the buffer.
            BytesAvailableInLastBuffer = 
                TheItem->SizeOfBuffer - TheItem->SizeOfData;

            // Use the minimum of the bytes available for 
            // reading and the space available.
            BytesToReadThisPass =
                min( BytesToRead, BytesAvailableInLastBuffer );
                    
            // Recieve data bytes to the buffer.
            ReadSocket->LastResult = 
                recv( ReadSocket->S, 
                        // The socket where the data should come 
                        // from.
                        //
                      AfterDataInBuffer, 
                        // The buffer for the incoming data.
                        //
                      BytesToReadThisPass,
                        // The most bytes that should be read.
                        //
                      (u32) 0 );    
                        // Special options flag:
                        // 
                        // 0 - nothing special.
                        //
                        // 1 - MSG_OOB, process out-of-band 
                        //     data.
                        //
                        // 2 - MSG_PEEK, peek at incoming 
                        //     message.
                        //
                        // 3 - MSG_DONTROUTE, send without 
                        //     using routing tables.

            // If a recv() error has occurred.
            if( ReadSocket->LastResult == SOCKET_ERROR )
            {
                // Respond to the specific error.
                ReadSocket->LastError = OnRecvError( S );
                
                // Signal that no data was read on the last
                // attempt.
                ReadSocket->WasDataRead = 0;
                
                // Return on a read error.
                return;
            }
            else // No error occurred.
            {
                // Clear the recv error field.
                ReadSocket->LastError = 0;
                
                // The recv result is the number of bytes
                // actually read.
                BytesJustRead = ReadSocket->LastResult;
                
                // Keep track of how many bytes we have received.   
                if( BytesJustRead > 0 ) 
                {
                    // Signal that data was read on the last attempt.
                    ReadSocket->WasDataRead = 1;
                
                    // Account for the bytes received for this
                    // data buffer. 
                    TheItem->SizeOfData += BytesJustRead;
                    
                    // Account for the bytes read on this
                    // socket.
                    ReadSocket->BytesReadSoFar += BytesJustRead;
                    
                    // Account for the bytes received for this
                    // stream.
                    S->TotalBytesReceived += BytesJustRead;
                    
                    // Note what time data last came in.
                    NoticeIncomingData( S );
                }
                else // No bytes were read but there was no error.
                {
                    // Signal that data was read on the last attempt.
                    ReadSocket->WasDataRead = 0;
                }
            }
        }
    }
}

/*------------------------------------------------------------
| SendSomePendingDataForStream
|-------------------------------------------------------------
| 
| PURPOSE: To recieve some pending data for a stream and
|          buffer it in the IncomingData buffer list.
|
| DESCRIPTION: Returns if no more data is currently available.
|
| Handles asynchonous read operations for a stream.  
|
| ASSUMES: 
|
|   Stream is active.
|
|   If protocol is TCP then the stream is connected.
| 
|   Operates during 'HandleAsynchronousNetworkOperations()' only.
|
|   Input protocol may be UDP or TCP.
|
| HISTORY: 12.07.96 pulled out of 
|                   'HandleAsynchronousNetworkOperations'.
|          01.16.97 fixed confusion of normal data with
|                   expedited data.
|          08.22.00 Revised for NT.09.13.00 from 
|                   AppendDataToBufferList to avoid extra
|                   data motion.
------------------------------------------------------------*/
void
SendSomePendingDataForStream( 
    Stream* S,  
        // The stream that should be read.
        //
    f64 TimeAtExit )
        // TimeAtExit is the deadline beyond which reading 
        // should not be done for the stream, in CPU 
        // timestamp seconds.
{
    S = S;
    TimeAtExit = TimeAtExit;
#if 0
    s32 status ;
    u32 BytesToRead;
 
    // While time remains to do work with this stream.
    while( ReadTimeStampInSeconds() < TimeAtExit ) 
    {
        // If the stream is connected TCP or UDP.
        if( ( ( S->Protocol == TCP ) && S->IsConnected ) ||
            S->Protocol == UDP )
        {
            // Test for available bytes to read from
            // network layer.
            S->DataSocket.LastResult = 
                ioctlsocket( 
                    S->DataSocket.S, 
                    (s32) FIONREAD, 
                    &BytesToRead ); 
            
            // If there was an error checking for data. 
            if( S->DataSocket.LastResult )  
            {
                // Get the specific error.
                S->DataSocket.LastError = WSAGetLastError(); 
            
                // Return on a data test error.
                return;
            }
            else // The test for data was OK.
            {
                // If there are no bytes to read right now.
                if( BytesToRead == 0 )
                {
                    // Then just return.
                    return;
                }
                
                // If there is no buffer list. 
                if( S->IncomingData == 0 )
                {
                    // Make a list for incoming data.
                    S->IncomingData = MakeList();
                }
                
                // Refer to the buffer list.
                ReferToList( S->IncomingData );
                
                // Refer to the last buffer in the list.
                ToLastItem();
                
                // If there is no last buffer or the buffer
                // is full.
                if( ( TheItem == 0 ) ||
                    ( TheItem->SizeOfBuffer == TheItem->SizeOfData ) )
                {
                    // Allocate a new data buffer.
                    ABuffer = (u8*) malloc( SizeOfStreamDataBuffer );
                    
                    // Insert the buffer in the list.  This sets the
                    // buffer and data address to the same value.
                    ABufferItem = 
                        InsertDataLastInList( TheList, ABuffer );

                    // Set the buffer size.
                    ABufferItem->SizeOfBuffer = SizeOfStreamDataBuffer;
                    
                    // Initially there will be no data.
                    ABufferItem->SizeOfData = 0; 
                }

                // Refer to the last buffer in the list.
                ToLastItem();
                
                // Calculate the position where new data should be
                // put in the buffer.
                AfterDataInBuffer = TheDataAddress + TheDataSize;
                
                // Calculate the space available in the buffer.
                BytesAvailableInLastBuffer = 
                    TheItem->SizeOfBuffer - TheItem->SizeOfData;
    
                // Use the minimum of the bytes available for 
                // reading and the space available.
                BytesToReadThisPass =
                    min( BytesToRead, BytesAvailableInLastBuffer );
                    
                // Recieve data bytes to the buffer.
                S->DataSocket.LastResult = 
                    recv( S->DataSocket, 
                            // The socket where the data should come 
                            // from.
                            //
                    AfterDataInBuffer, 
                            // The buffer for the incoming data.
                            //
                    BytesToReadThisPass,
                            // The most bytes that should be read.
                            //
                    0 );    // Special options flag:
                            // 
                            // 0 - nothing special.
                            //
                            // 1 - MSG_OOB, process out-of-band 
                            //     data.
                            //
                            // 2 - MSG_PEEK, peek at incoming 
                            //     message.
                            //
                            // 3 - MSG_DONTROUTE, send without 
                            //     using routing tables.

                // If a recv() error has occurred.
                if( S->DataSocket.LastResult == SOCKET_ERROR )
                {
                    // Respond to the specific error.
                    S->DataSocket.LastError = OnRecvError( S );
                    
                    // Signal that no data was read on the last
                    // attempt.
                    S->DataSocket.WasDataRead = 0;
                    
                    // Return on a read error.
                    return;
                }
                else // No error occurred.
                {
                    // Clear the recv error field.
                    S->DataSocket.LastError = 0;
                    
                    // The recv result is the number of bytes
                    // actually read.
                    BytesJustRead = S->DataSocket.LastResult;
                    
                    // Keep track of how many bytes we have received.   
                    if( BytesJustRead > 0 ) 
                    {
                        // Signal that data was read on the last attempt.
                        S->DataSocket.WasDataRead = 1;
                    
                        // Account for the bytes received for this
                        // data buffer. 
                        TheItem->SizeOfData += BytesJustRead;
                        
                        // Account for the bytes read on this
                        // socket.
                        S->DataSocket.BytesReadSoFar += BytesJustRead;
                        
                        // Account for the bytes received for this
                        // stream.
                        S->TotalBytesReceived += BytesJustRead;
                        
                        // Note what time data last came in.
                        NoticeIncomingData( S );
                    }
                    else // No bytes were read but there was no error.
                    {
                        // Signal that data was read on the last attempt.
                        S->DataSocket.WasDataRead = 0;
                    }
                }
            }
        }
        else // Not connected.
        {
            // Just return.
            return;
        }
    }
#endif
}
 
#endif // defined(FOR_WINNT) | defined(FOR_WIN98) | defined(FOR_WIN2000)  
