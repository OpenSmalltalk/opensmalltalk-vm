/*------------------------------------------------------------
| TLPatriciaTree.c
|-------------------------------------------------------------
|
| PURPOSE: To provide high-speed string search functions for
|          dictionary look-up using the Patricia tree method.
|
| DESCRIPTION: The Patricia tree method was invented by 
| D. R. Morrison: PATRICIA stands for "Practical Algorithm To
| Retrieve Information Coded In Alphanumeric".
|
| This Patricia Tree based symbol table scheme is compact and 
| fast. It's generally useful for (key,value) lookup tables 
| or dictionary applications.  The key can be any length and 
| any type of byte string.  The 'value' field is a 32-bit 
| field.  Keys may be stored internally or externally from 
| the lookup table: external keys may overlap in memory to 
| support longest-string-match compression applications.  
|
| The code is written in C and compiles for drivers or 
| applications. 
|
| The lookup table memory allocation minimizes fragmentation 
| by allocating keys and tree nodes in blocks, maintaining 
| deleted keys and nodes in place on free lists for rapid 
| reuse.
|
| HISTORY: 02.22.99 From 'Algorithms' by Sedgwick, 2nd Ed.
|                   p. 253.
|          02.07.01 Changed allocation of node records from
|                   TLTable to TLMassMem to reduce complexity.
|                   Retested.
|          06.14.01 Added key deletion capability with 
|                   free record recycling.
|          06.19.01 Errors were found in these Patricia Tree 
|                   functions. The errors were traced back 
|                   to an error in the algorithm published by 
|                   Sedgewick in the 2nd edition of 'Algorithms'. 
|
|                   A corrected algorithm in the 3rd edition 
|                   was applied, translating it to 
|                   non-recursive form.  A (key,value) deletion 
|                   function was developed and added.
| 
|                   New unit test programs for the Patricia 
|                   Tree functions were written and run to 
|                   test the corrected routines -- several 
|                   million record insertions and deletions 
|                   were run with full error checking
|                   and tree validation after each change to 
|                   the symbol table.
|          06.23.01 Added support for memory allocation 
|                   failure.
------------------------------------------------------------*/


#include "TLTarget.h"

#ifndef FOR_DRIVER

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#endif // FOR_DRIVER

#include "NumTypes.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLStrings.h"
#include "TLMemHM.h"
#include "TLMassMem.h"
#include "TLStacks.h"

#include "TLPatriciaTree.h"

#ifndef max
#define max(x,y)      ((x)>(y)?(x):(y))
#endif

Lot*    ThePatriciaTreePool = 0;
                // The allocation pool from which all data
                // in Patricia tree functions is allocated.
 
/*------------------------------------------------------------
| AllocateKeyStorage 
|-------------------------------------------------------------
|
| PURPOSE: To allocate storage for a key value to be inserted
|          into a Patricia tree, and initialize it to a 
|          given key value.
|
| DESCRIPTION:  
|
| Use the companion function FreeKeyStorage() to deallocate
| storage for a key
|
| Returns the address of the key storage field to use
|
| EXAMPLE: 
| 
|    AtKey = AllocateKeyStorage( P, Key, KeySize );
|
| ASSUMES:  
|
|     The length of the key field is not greater than the 
|     maximum key size of the look-up table set by 
|     MakePatricia().
|
| HISTORY: 06.11.01 TL From InsertNameValue.
|          06.19.01 Fixed to allocate at least 4 bytes for
|                   the key field so that it can be placed
|                   on the free list.
------------------------------------------------------------*/
    // OUT: Address of the key field or zero if allocation
u8* //      failed.
AllocateKeyStorage( 
    PatTree* P, 
                 // Tree where the key will be inserted.
                 //
    u8*      Key, 
                 // The key to be inserted: any byte field
                 // can serve as a key.  
                 //
    u32      KeySize )
                 // Size of the key in bytes.
{
    u32 i;
    u8* AtKey;
    
    // If keys are owned by this tree.
    if( P->IsKeysOwned )
    {
        // Calculate the subtree index for this 
        // key size.
        i = KeySize - P->MinBytesPerKey;

        // If there are any free key fields.
        if( P->FreeKeyList[i] )
        {
            // Remove the first free record from the free 
            // list.

            // Refer to the first free record.
            AtKey = (u8*) P->FreeKeyList[i];
            
            // Update the first free record.
            P->FreeKeyList[i] = (u32*) 
                *(P->FreeKeyList[i]);
                
            // Account for the key being removed from
            // the list.
            P->FreeKeyCount -= 1;
        }
        else // Need to allocate a new key record.
        {
            // Allocate space for the key field in the
            // key storage space of the look-up table.
            //
            // Allocate at least enough room for the
            // the free list link.
            AtKey = (u8*) 
                AllocateMS( P->KeyStorage[i], 
                            max( KeySize, sizeof(u32*)) );
        }
        
        // If the key fields are valid.
        if( Key && AtKey )
        {   
            // Copy the key into the space allocated.
            CopyBytes( Key, AtKey, KeySize );
        }
    }
    else // Key storage is not owned by this tree.
    {
        // The key storage location is the given
        // address.
        AtKey = Key;
    }
    
    // Return the address of the key field or zero on failure.
    return( AtKey );
}

/*------------------------------------------------------------
| ConvertBitsToString2
|-------------------------------------------------------------
| 
| PURPOSE: To convert binary number to a Low-Order First 
|          binary ASCII string.
| 
| DESCRIPTION:  
| 
| EXAMPLE:   
|
|     u8    Bits;
|     s8    StringBuf[20];
|
|     Bits = 8;
|
|     ConvertBitsToString2( &Bits, &StringBuf, 8 );
|
|     Results in "0001" in 'StringBuf'.
|            
| HISTORY: 02.17.97
|          02.01.01 Copied from ConvertBitsToString so that
|                   TLBitField.h doesn't need to be included.
------------------------------------------------------------*/
void
ConvertBitsToString2( u8* B, s8* A, u32 BitCount )
{
    u8   BitBuffer;
    u32  BitsInBuffer;
    
    // Clear the bit buffer count.
    BitsInBuffer = 0;  
        
    // For each bit.
    while( BitCount-- )
    {
        // If bit buffer is empty.
        if( BitsInBuffer == 0 )
        {
            // Load the buffer
            BitBuffer = *B++;
            
            BitsInBuffer = 8;
        }
        
        // Test the lowest order bit remaining in the
        // buffer.
        if( BitBuffer & 1 )
        {
            // Output a '1' to the string.
            *A++ = '1';
        }
        else
        {
            // Output a '0' to the string.
            *A++ = '0';
        }
        
        // Consume the low-order bit.
        BitBuffer = (u8) ( BitBuffer >> 1 );
        BitsInBuffer--;
    }
    
    // Append a string terminator.
    *A = 0;
}

/*------------------------------------------------------------
| DeleteKeyValue
|-------------------------------------------------------------
|
| PURPOSE: To delete a (key,value) pair from a Patricia tree.
|
| DESCRIPTION: All deletions to a Patricia tree come through
| this general routine.
|
| ASSUMES:  
|
| HISTORY: 06.14.01 Added NumberOfNodes counter.
------------------------------------------------------------*/
void
DeleteKeyValue( 
    PatTree*    P,      
                    // The tree holding the key.
                    // 
    u8*         Key,    
                    // The address of the key to delete.
                    //
    u32         KeySize )
                    // Number of bytes in the key.
{
    PatNode* N;
    
    // Look up the node for the key in the tree.
    //
    // OUT: Node address or zero if not found.
    N = FindKeyPatricia( 
            P,          
                // The tree to be searched. 
                // 
            Key,        
                // The value of the key to look for.
                //
            KeySize );   
                // How many bytes are in the key.
 
    // If a node was found.
    if( N )
    {
        // Extract the node from the tree so that the logic of 
        // the tree is preserved.
        ExtractPatNode( P, N, KeySize );
        
        // Free the PatNode record so that it can be reused.
        FreePatNode( P, N );
        
        // Free the storage used for the key so it can
        // may be reused.
        FreeKeyStorage( 
            P, 
                 // Tree where the key will be inserted.
                 //
            N->Key, 
                 // The key to be inserted: any byte field
                 // can serve as a key.  
                 //
            KeySize );
                 // Size of the key in bytes.
    }
}

/*------------------------------------------------------------
| DeletePatricia
|-------------------------------------------------------------
|
| PURPOSE: To deallocate all storage used by a Patricia tree.
|
| DESCRIPTION: 
|
| EXAMPLE:      DeletePatricia( P );
|
| HISTORY: 02.22.99 TL
|          02.07.01 TL Replaced DeleteTable with DeleteMass.
|          06.14.01 Added deletion of separate key data.
|          06.23.01 Revised to delete a partially constructed
|                   Patricia tree to handle memory allocation
|                   failure during MakePatricia().
------------------------------------------------------------*/
void
DeletePatricia( PatTree* P ) 
{
    u32 i;

    // If the whole tree is missing.
    if( P == 0 )
    {
        // Just return.
        return;
    }
    
    // If there is a Roots array for the tree.
    if( P->Roots )
    {   
        // Free the root array.
        FreeMemoryHM( P->Roots );
    }
    
    // If there is a node storage pool.
    if( P->NodeStorage )
    {
        // Delete the pool of node records.
        DeleteMass( P->NodeStorage );
    }
    
    // If the key memory is owned by the table.
    if( P->IsKeysOwned )
    {
        // If there are any key storage pools.
        if( P->KeyStorage )
        {
            // For each subtree.
            for( i = 0; i < P->SubTreeCount; i++ )
            {
                // If there is a key storage pool for this 
                // subtree.
                if( P->KeyStorage[i] )
                {
                    // Delete the pool of key records.
                    DeleteMass( P->KeyStorage[i] );
                }
            }
            
            // Free the key pool array.
            FreeMemoryHM( P->KeyStorage );
        }
        
        // If there is an array of free key lists.
        if( P->FreeKeyList )
        {
            // Free the array of free key lists.
            FreeMemoryHM( P->FreeKeyList );
        }
    }

    // Free the tree record itself.
    FreeMemoryHM( P );
}

/*------------------------------------------------------------
| EmptyPatricia
|-------------------------------------------------------------
|
| PURPOSE: To restore a possibly non-empty Patricia Tree to
|          it's initial empty state.
|
| DESCRIPTION: 
|
| EXAMPLE:      EmptyPatricia( P );
|
| HISTORY: 03.10.99 TL From 'DeletePatricia()'.
|          02.07.01 TL Changed EmptyTable to EmptyMass.
|                      Changed FillBytes to memset.
|          06.14.01 Changed memset to ZeroBytes.
|          06.15.01 Added clean up of key storage if any.
------------------------------------------------------------*/
void
EmptyPatricia( PatTree* P ) 
{
    u32 SubTreeCount;
    u32 BytesForRoots;
    u32 i;
    
    // Get the number of subtrees required to accomodate all 
    // of the key sizes supported.
    SubTreeCount = P->SubTreeCount;
    
    // Calculate how many bytes will hold root node 
    // addresses: four bytes per record.
    BytesForRoots = SubTreeCount << 2;
    
    // Empty the node storage pool.
    EmptyMass( P->NodeStorage );
    
    // Reset the in-use node count to zero.
    P->InUseNodeCount = 0;
    
    // Reset the free node count to zero.
    P->FreeNodeCount = 0;
    
    // Mark the free node list as empty.
    P->FreeNodeList = 0;
    
    // Clear the size of the shortest key existing in the
    // tree.
    P->MinKeySize = 0;
    
    // Clear the size of the longest key size existing 
    // in the tree.
    P->MaxKeySize = 0;
    
    // If key memory is owned by this tree.
    if( P->IsKeysOwned )
    {
        // For each subtree.
        for( i = 0; i < P->SubTreeCount; i++ )
        {
            // Empty the key storage pool for the i'th 
            // subtree. 
            EmptyMass( P->KeyStorage[i] );
        }
                
        // Reset the free key count to zero.
        P->FreeKeyCount = 0;
        
        // Zero the array of free list head addresses.
        ZeroBytes( (u8*) P->FreeKeyList, BytesForRoots );
    }
    
    // Zero the array of subtree root nodes.
    ZeroBytes( (u8*) P->Roots, BytesForRoots );
}

/*------------------------------------------------------------
| ExtractPatNode
|-------------------------------------------------------------
|
| PURPOSE: To extract the node from the tree so that the logic 
|          of the tree is preserved.
|
| DESCRIPTION:  
|
| EXAMPLE:     ExtractPatNode( P, N );
|
| HISTORY: 06.14.01 TL
|          06.18.01 Revised for Super link usage.
|          06.19.01 Revised downward link from superior to
|                   not lose information when extracting Q.
------------------------------------------------------------*/
void
ExtractPatNode( 
    PatTree* P,
                // The tree holding the node.
                // 
    PatNode* Q, // The root node of the subtree which holds
                // (key,value) pairs to be inserted into the
                // Patricia tree.
                //
                // The key fields will not be reallocated
                // when putting them into P.
                //
    u32      KeySize )
                // Size of the key in bytes.
{
    PatNode* Super;
    PatNode* T;
    PatNode* N;
    PatNode* Z;
    u32      SubTreeIndex;

    // Refer to the superior of Q as 'Super'.
    Super = Q->Super;
      
    // If Q has a superior node.
    if( Super )
    {
        // Look below Q for the highest order terminal node.
        T = FindHighestOrderTerminalNode( Q );
        
        // If the terminal node is not above Q.
        if( ToBitIndex( Q->Offset, Q->Mask ) <=
            ToBitIndex( T->Offset, T->Mask ) )
        {
            // Then use the superior of Q as the terminal
            // node.
            T = Super;
        }
        
        // If Q is a Zero subordinate.
        if( Super->Zero == Q )
        {
            Super->Zero = T;
        }
        
        // If Q is a One subordinate.
        if( Super->One == Q )
        {
            // Follow the path to a terminal node of
            // order Super or above.
            Super->One = T;
        }
    }
    else // Q is the root of its subtree.
    {
        // Calculate the index of the subtree in the family 
        // of trees of this Patricia tree.
        SubTreeIndex = KeySize - P->MinBytesPerKey;

        // Mark the subtree as having no nodes.
        P->Roots[SubTreeIndex] = 0;
    }
    
    //
    // Reinsert the subordinates of Q with different 
    // node records then delete the extra subtrees.
    //
            
    // Refer to the subordinates of Q as Z and N.
    //
    //        Q
    //     0 / \ 1
    //      Z   N
    //
    Z = Q->Zero;
    N = Q->One;
    
    // If Z is a proper subordinate of Q.
    if( Z->Super == Q )
    {
        // Mark Z as having no superior.
        Z->Super = 0;
        
        // Reinsert the (key,value) pairs of subtree Z.
        ReinsertSubtree( 
            P,
                // The tree holding the node.
                // 
            Z,  // The root node of the subtree which holds
                // (key,value) pairs to be inserted into the
                // Patricia tree.
                //
                // The key fields will not be reallocated
                // when putting them into P.
                //
            KeySize );
                // Size of the key in bytes.
    }
    
    // If N is a proper subordinate of Q.
    if( N->Super == Q )
    {
        // Mark N as having no superior.
        N->Super = 0;
        
        // Insert N and its subtree.
        ReinsertSubtree( 
            P,
                // The tree holding the node.
                // 
            N,  // The root node of the subtree which holds
                // (key,value) pairs to be inserted into the
                // Patricia tree.
                //
                // The key fields will not be reallocated
                // when putting them into P.
                //
            KeySize );
                // Size of the key in bytes.
    }
}

/*------------------------------------------------------------
| FindHighestOrderTerminalNode
|-------------------------------------------------------------
|
| PURPOSE: To find the highest order terminal node referenced
|          by the nodes of a subtree, that is, the node with
|          the smallest bit index value.
|
| DESCRIPTION:  
|
| EXAMPLE:     T  = FindHighestTerminalInSubtree( R );
|
| ASSUMES: The key fields should not be deallocated.
|
| HISTORY: 06.19.01  
------------------------------------------------------------*/
PatNode*
FindHighestOrderTerminalNode( PatNode* R )
                                        // The root node of 
                                        // the subtree to be 
                                        // scanned.
{
    u32         StackBuffer[100];
    u32         IndexT, HiIndex;
    Stack       S;
    PatNode*    Q;
    PatNode*    HiNode;
    PatNode*    N;
    PatNode*    Z;
    
    // Start with a bit index value for the best found that
    // is impossibly big.
    HiIndex = 0xFFFFFFFF;
    
    // Make a stack for traversing the tree.
    MakeStaticStack( &S, (u32*) &StackBuffer, 100 );
        
    // Push the root onto the stack.
    Push( &S, (u32) R );

    // As long as there is a value on the stack.
    while( S.StackIndex )
    {
        // Pop the top item off as the current node, 'Q'.
        Q = (PatNode*) Pull( &S );
    
        // Refer to the subordinates of Q as Z and N.
        //
        //        Q
        //     0 / \ 1
        //      Z   N
        //
        Z = Q->Zero;
        N = Q->One;
    
        // If Z is a proper subordinate of Q.
        if( Z->Super == Q )
        {
            // Push Z onto the stack.
            Push( &S, (u32) Z );
        }
        else // Z is a terminal node.
        {
            // Calculate the bit index of the terminal node.
            IndexT = ToBitIndex( Z->Offset, Z->Mask );
    
            // If the bit index is lower than the best found
            // so far.
            if( IndexT < HiIndex )
            {
                // Then a higher order terminal node has been 
                // found.
                
                // Regard Z as the new highest order terminal
                // node.
                HiIndex = IndexT;
                HiNode  = Z;
            }
        }
    
        // If N is a proper subordinate of Q.
        if( N->Super == Q )
        {
            // Push N onto the stack.
            Push( &S, (u32) N );
        }
        else // N is a terminal node.
        {
            // Calculate the bit index of the terminal node.
            IndexT = ToBitIndex( N->Offset, N->Mask );
    
            // If the bit index is lower than the best found
            // so far.
            if( IndexT < HiIndex )
            {
                // Then a higher order terminal node has been 
                // found.
                
                // Regard N as the new highest order terminal
                // node.
                HiIndex = IndexT;
                HiNode  = N;
            }
        }
    }
    
    // Return the highest order terminal node.
    return( HiNode );
}   

/*------------------------------------------------------------
| FindKeyPatricia
|-------------------------------------------------------------
|
| PURPOSE: To search a Patricia tree for a matching
|          key value with the same length as the 
|          given key.
|
| DESCRIPTION: Returns the node of the matching node or zero 
| if no match was found.  
|
| No attempt is made to match beyond the size of KeySize as
| is done in FindMatchPatricia(), an optimization for 
| longest-match processing applications but which may cause
| buffer overrun problems if not carefully handled.
|
| ASSUMES: If the key represents a number then the bytes are 
|          ordered in memory from LSB to MSB.
|
| HISTORY: 02.24.01 TL From 'FindMatchPatricia'.
|          06.16.01 Factored out IsMatchingBytes.
------------------------------------------------------------*/
                            // OUT: Returns the node with the
                            // matching key or zero if
PatNode*                    // no match was found.
FindKeyPatricia( 
    PatTree*    P,          // The tree to be searched. 
                            // 
    u8*         Key,        // The value of the key to look for.
                            //
    u32         KeySize )   // How many bytes are in the key.
{
    u32         IsMatching;
    PatNode*    N;
     
    // Look for a matching node.
    N = SearchPatricia( 
            P,         // The tree to be searched.  
                       // 
            Key,       // The value of the key to look for.
                       //
            KeySize ); // How many bytes are in the key.

    // If a node was found.
    if( N )
    {
        // Compare the key found to the search key.
        //
        // Returns: 1 if they match or 0 if not.
        IsMatching = IsMatchingBytes( Key, N->Key, KeySize );

        // If the keys match exactly.
        if( IsMatching )
        {
            // Return the node found.
            return( N );
        }
    }
    
    // Signal that no match was found.
    return( 0 );
}

/*------------------------------------------------------------
| FindLongestMatchPatricia
|-------------------------------------------------------------
|
| PURPOSE: To search a Patricia tree for the longest matching
|          key value up to and including the length of the 
|          given key.
|
| DESCRIPTION: Returns the node of the longest matching node
| or zero if no match was found.  Returns the length of the
| match found in 'KeySizeFound'.
|
| Returns the length of the match found in 'KeySizeFound'
| which may exceed the size given: this is to speed up
| longest string match applications.
|
| ASSUMES: Minimum key size for the tree is 1 byte.
|
| HISTORY: 02.23.99 TL
|          03.01.99 Sped up comparison.
|          06.16.01 Added logic to make sure that key buffers
|                   are not exceeded when making comparisons.
------------------------------------------------------------*/
                            // OUT: Returns the node with the
                            // longest matching key or zero if
PatNode*                    // no match was found.
FindLongestMatchPatricia( 
    PatTree*    P,          // The tree to be searched. 
                            // 
    u8*         Key,        // The value of the key to look for.
                            //
    u32         KeySize,    // How many bytes are in the key.
                            // 
    u32*        KeySizeFound )   
                            // OUT: How many bytes match up
                            // to the first mismatching byte
                            // which may be beyond 'KeySize'; 
                            // only set if a match is found.
{
    u32         MinKeySize;
    u32         MaxKeySize;
    u32         MaxSupportedKeySize;
    u32         MatchSize;
    u32         i;
    PatNode*    N;
    u8*         A;
    u8*         B;
    
    // Get range of key sizes actually held in the table.
    MinKeySize = P->MinKeySize;
    MaxKeySize = P->MaxKeySize;
    
    // Get the maximum supported key size.
    MaxSupportedKeySize = P->MaxBytesPerKey;
    
    // If no keys are held in the tree.
    if( MinKeySize == 0 )
    {
        // Just return zero.
        return( 0 );
    }
    
    // If the given key is smaller than the smallest
    // existing.
    if( KeySize < MinKeySize )
    {
        // Then there is no match.
        return( 0 );
    }
    
    // If the given key is smaller than maximum existing.
    if( KeySize < MaxKeySize )
    {
        // Reduce the search maximum to the key size..
        MaxKeySize = KeySize;
    }
    
    // Until a match is found.
    while( MinKeySize <= KeySize )
    {
        // Look for a matching node.
        N = SearchPatricia( 
                P,         // The tree to be searched.  
                           // 
                Key,       // The value of the key to look for.
                           //
                KeySize ); // How many bytes are in the key.

        // If a node was found.
        if( N )
        {
            // Refer to the key of the node found as 'A'.
            A = N->Key;
            
            // Refer to the search key as 'B'.
            B = Key;
            
            // If the addresses of the keys are the same.
            if( A == B )
            {
                // Then the keys match over the given length.
                
                // Return the size of the key found.
                *KeySizeFound = KeySize;
                
                // Return the node found.
                return( N );
            }
            
            // While the bytes match and the current bytes
            // are within key buffers.
            for( i = 0; 
                 ( *A == *B ) && ( i < MaxSupportedKeySize ); 
                 i++ )
            {
                // Advance to the next byte.
                A++;
                B++;
            }
            
            // Calculate the number of bytes matching.
            MatchSize = B - Key;
            
            // If the keys match over the entire length.
            if( MatchSize >= KeySize )
            {
                // Return the size of the key found if any.
                *KeySizeFound = MatchSize;
                
                // Return the node found if any.
                return( N );
            }
        }
        
        // Reduce the key size and try again.
        KeySize--;
    }
    
    // Signal that no match was found.
    return( 0 );
}
        
/*------------------------------------------------------------
| FindMatchPatricia
|-------------------------------------------------------------
|
| PURPOSE: To search a Patricia tree for a matching key value 
|          with the same length as the given key.
|
| DESCRIPTION: Returns the address of the matching node or 
| zero if no match was found.  
|
| Returns the length of the match found in 'KeySizeFound'
| which may exceed the size given: this is to speed up
| longest string match applications.
|
| HISTORY: 03.01.99 TL From 'FindLongestMatchPatricia'.
|          06.16.01 Added logic to make sure that key buffers
|                   are not exceeded when making comparisons.
------------------------------------------------------------*/
                            // OUT: Returns the node with the
                            // matching key or zero if
PatNode*                    // no match was found.
FindMatchPatricia( 
    PatTree*    P,          // The tree to be searched. 
                            // 
    u8*         Key,        // The value of the key to look for.
                            //
    u32         KeySize,    // How many bytes are in the key.
                            // 
    u32*        KeySizeFound )   
                            // OUT: How many bytes match up
                            // to the first mismatching byte
                            // which may be beyond 'KeySize'; 
                            // only set if a match is found.
{
    u32         MatchSize, m, i ;
    u32         MaxSupportedKeySize;
    PatNode*    N;
    u8*         A;
    u8*         B;
    
    // Get the maximum supported key size.
    MaxSupportedKeySize = P->MaxBytesPerKey;
    
    // Look for a matching node.
    N = SearchPatricia( 
            P,         // The tree to be searched.  
                       // 
            Key,       // The value of the key to look for.
                       //
            KeySize ); // How many bytes are in the key.

    // If a node was found.
    if( N )
    {
        // Refer to the key of the node found as 'A'.
        A = N->Key;
        
        // Refer to the search key as 'B'.
        B = Key;
        
        // If the addresses of the keys are the same.
        if( A == B )
        {
            // Then the keys match over the given length.
            
            // Return the size of the key found.
            *KeySizeFound = KeySize;
            
            // Return the node found.
            return( N );
        }
        
        // If the first byte of the keys differ.
        if( *A != *B )
        {
            // Return no match.
            return( 0 );
        }
    
        // Calculate the index of the middle byte of the key.
        m = KeySize >> 1;
        
        // If the middle byte of the keys differ.
        if( A[ m ] != B[ m ] )
        {
            // Return no match.
            return( 0 );
        }
        
        // While the bytes match and the current bytes
        // are within key buffers.
        for( i = 0; 
             ( *A == *B ) && ( i < MaxSupportedKeySize ); 
             i++ )
        {
            // Advance to the next byte.
            A++;
            B++;
        }
        
        // Calculate the number of bytes matching.
        MatchSize = B - Key;
        
        // If the keys match over the entire length.
        if( MatchSize >= KeySize )
        {
            // Return the size of the key found.
            *KeySizeFound = MatchSize;
            
            // Return the node found.
            return( N );
        }
    }
    
    // Signal that no match was found.
    return( 0 );
}

/*------------------------------------------------------------
| FreeKeyStorage 
|-------------------------------------------------------------
|
| PURPOSE: To deallocate storage for a key value being removed
|          from a Patricia tree.
|
| DESCRIPTION:  
|
| This is the companion function to AllocateKeyStorage().
|
| EXAMPLE: 
| 
|              FreeKeyStorage( P, Key, KeySize );
|
| ASSUMES:  
|
|     The length of the key field is not greater than 
|     the maximum key size of the look-up table set by
|     MakePatricia().
|
| HISTORY: 06.11.01 TL From InsertNameValue.
------------------------------------------------------------*/
void
FreeKeyStorage( 
    PatTree* P, 
                 // Tree where the key will be inserted.
                 //
    u8*      Key, 
                 // The key to be inserted: any byte field
                 // can serve as a key.  
                 //
    u32      KeySize )
                 // Size of the key in bytes.
{
    u32 i;
    
    // If keys are owned by this tree.
    if( P->IsKeysOwned )
    {
        // Calculate the subtree index for this 
        // key size.
        i = KeySize - P->MinBytesPerKey;

        // Insert this key record into the free list.
        {
            // Link to the current first record.
            *( (u32*) Key ) = (u32) P->FreeKeyList[i];
            
            // Now make the input key record the first one
            // in the free list.
            // Update the first free record.
            P->FreeKeyList[i] = (u32*) Key;
            
            // Account for the key added to the list.
            P->FreeKeyCount += 1;
        }
    }
}

/*------------------------------------------------------------
| FindFirstDifferentBit
|-------------------------------------------------------------
|
| PURPOSE: To find the bit offset of the first different bit
|          in keys A and B.
|
| DESCRIPTION:
|
| ASSUMES: Keys are known to differ.
|
|          The least-significant-bit of a byte is regarded
|          as first.
|
| HISTORY: 06.16.01 TL Factored out of InsertPatricia.
------------------------------------------------------------*/
void
FindFirstDifferentBit(
    u8*  KeyA,
            // Address of key A.
            //
    u8*  KeyB,
            // Address of key B.
            //
    u32* OffsetReturned,
            // OUT: Byte offset from the beginning of the
            // keys where the first difference was found
            // when searching from the least-significant-byte
            // to the most.
            //
    u8*  MaskReturned )
            // OUT: Bit mask of the least significant 
            // different bit in the byte at Key[Offset].
{
    u8  ByteA, ByteB, Mask;
    u8* OriginalKeyA;

    // Preserve the starting address of KeyA.
    OriginalKeyA = KeyA;
    
    // Until a byte-wise difference is found.
    while( *KeyA == *KeyB )
    {
        // Advance to the next byte.
        KeyA++;
        KeyB++;
    }
    
    // Return the offset of the first different byte.
    *OffsetReturned = KeyA - OriginalKeyA;
    
    // Get the byte that differs from each key.
    ByteA = *KeyA;
    ByteB = *KeyB;

    // Regard the least-significant-bit as the first bit
    // in the byte.
    Mask = FIRST_BIT_IN_BYTE; 

    // Until a bit-wise difference is found.
    while( ( ByteA & Mask ) == ( ByteB & Mask ) )
    {
        // Shift the mask to the left, from LSB to MSB. 
        Mask <<= 1;
    }

    // Return the mask of the least-significant-different-bit.
    *MaskReturned = Mask;
}

/*------------------------------------------------------------
| FreePatNode
|-------------------------------------------------------------
|
| PURPOSE: To deallocate a PatNode record for a Patricia 
|          tree so it can be reused.
|
| DESCRIPTION:  
|
| This is the companion function to AllocatePatNode().
|
| EXAMPLE:     FreePatNode( P, N );
|
| HISTORY: 02.22.99 TL
|          06.14.01 Replaced memset with ZeroBytes and added
|                   free list.
------------------------------------------------------------*/
void
FreePatNode( PatTree* P, PatNode* N )
{
    // Link to the current first record.
    *( (u32*) N ) = (u32) P->FreeNodeList;

    // Now make the input record the first one in the free 
    // list.
    P->FreeNodeList = (u32*) N;
    
    // Increment the count of free nodes.
    P->FreeNodeCount += 1;
    
    // Decrement the count of in-use nodes.
    P->InUseNodeCount -= 1;
}

/*------------------------------------------------------------
| FreeSubtree
|-------------------------------------------------------------
|
| PURPOSE: To deallocate the PatNode records of a subtree
|          so that they can be reused.
|
| DESCRIPTION:  
|
| The PatNode of the root of the given subtree will be freed 
| along with any proper subordinates of the root.
|
| A "proper subordinate" is one that doesn't loop back toward
| the root.
|
| EXAMPLE:     FreeSubtree( P, R );
|
| ASSUMES: The key fields should not be deallocated.
|
| HISTORY: 06.14.01  
------------------------------------------------------------*/
void
FreeSubtree( 
    PatTree* P,
                // The tree holding the node.
                // 
    PatNode* R )// The root node of the subtree which holds
                // (key,value) pairs to be inserted into the
                // Patricia tree.
                //
                // The key fields will not be reallocated
                // when putting them into P.
{
    u32         StackBuffer[100];
    Stack       S;
    PatNode*    Q;
    PatNode*    N;
    PatNode*    Z;
    
    // Make a stack for traversing the tree.
    MakeStaticStack( &S, (u32*) &StackBuffer, 100 );
        
    // Push the root onto the stack.
    Push( &S, (u32) R );

    // As long as there is a value on the stack.
    while( S.StackIndex )
    {
        // Pop the top item off as the current node, 'Q'.
        Q = (PatNode*) Pull( &S );
    
        // Refer to the subordinates of Q as Z and N.
        //
        //        Q
        //     0 / \ 1
        //      Z   N
        //
        Z = Q->Zero;
        N = Q->One;
    
        // If Z is a proper subordinate of Q.
        if( Z->Super == Q )
        {
            // Push Z onto the stack.
            Push( &S, (u32) Z );
        }
    
        // If N is a proper subordinate of Q.
        if( N->Super == Q )
        {
            // Push N onto the stack.
            Push( &S, (u32) N );
        }
        
        // Free the current record.
        FreePatNode( P, Q );
    }
}   

/*------------------------------------------------------------
| InsertKeyValue
|-------------------------------------------------------------
|
| PURPOSE: To insert a (key,value) pair into a key-indexed
|          look-up table.
|
| DESCRIPTION: This procedure inserts a (key,value) pair
| into a look-up table so that later the value associated with
| the key can be found by supplying the key.
|
| If the key is already found in the table then the old
| value associated with the key is replaced with the new
| value.
|
| The key field is copied into the table so the original key
| buffer need not be preserved after inserting the key into 
| the table.  The key field is held in the general allocation
| space of the look-up table and is freed when the look-up
| table as a whole is deallocated.
|
| Use the companion function LookUpValueByKey() to fetch the
| value of a (key,value) pair in a look-up table.
|
| Returns the address of the node record for the (key,value)
| pair or zero if unable to insert the key and value.
|
| EXAMPLE: 
| 
|    InsertKeyValue( MyLookUpTable, AtKey, KeySize, 1234 );
|
| ASSUMES:  
|
|     The length of the key field is not greater than 
|     the maximum key size of the look-up table set by
|     MakePatricia().
|
|     If the key represents a number then the bytes are
|     ordered in memory from LSB to MSB.
|
| HISTORY: 06.11.01 TL From InsertNameValue.
|          06.14.01 Factored out AllocateKeyStorage.
------------------------------------------------------------*/
PatNode*
InsertKeyValue( 
    PatTree* P, 
                 // Address of the look-up table into which 
                 // the (key,value) pair is to be inserted.
                 //
    u8*      Key, 
                 // The key field to be inserted, any binary
                 // bytes can serve as a key.  
                 //
                 // If the IsKeysOwned field of this tree is
                 // non-zero then this key field is copied 
                 // into the look-up table so it need 
                 // not be preserved separately.  Otherwise,
                 // the key field given here is simply 
                 // referenced by the lookup table so it 
                 // must remain constant over the life of
                 // the (key,value) pair.
                 //
    u32      KeySize,
                 // Size of the key in bytes.
                 //
    u32      Value )
                 // The 32-bit value to be associated with 
                 // the key.
{
    PatNode* N;
    u8*      AtKey;
        
    // Look to see if the name is already in the table.
    N = FindKeyPatricia( 
            P,            
                // The tree to be searched. 
                // 
            Key,         
                // The value of the key to look for.
                //
            KeySize );   
                // How many bytes are in the key.
    
    // If the key is already in the table.
    if( N )
    {
        // Then just update the value.
        N->Value = Value;
    }
    else // The key is not already in the table.
    {
        // Make a key field to be used by the tree, 
        // allocating separate storage or not depending
        // on whether the tree owns its key storage.
        //
        // OUT: Address of the key field or zero if 
        //      allocation failed.
        AtKey =
            AllocateKeyStorage( 
                P,  // Tree where the key will be inserted.
                    //
                Key,// 
                    // The key to be inserted: any byte 
                    // field can serve as a key.  
                    //
                KeySize );
                    // Size of the key in bytes.
        
        // If a key field was allocated.
        if( AtKey )
        { 
            // Insert a new record into the look-up index.
            N = InsertPatricia( 
                    P,        
                        // The tree where the key should be
                        // inserted.
                        // 
                    AtKey,  
                        // The address of the key to insert.
                        //
                    KeySize,
                        // How many bytes are in the key.
                        //
                    Value );
                        // Any value associated with the key,
                        // in this case the address of the
                        // Field record for the named field.
        }
        else // Key allocation failure.
        {
            N = 0; // Debugger();
        }
    }
    
    // Return the node record address of the (key,value) pair,
    // or zero on failure.
    return( N );
}

/*------------------------------------------------------------
| InsertNameValue
|-------------------------------------------------------------
|
| PURPOSE: To insert a (name,value) pair into a string-indexed
|          look-up table.
|
| DESCRIPTION: This procedure inserts a (name,value) pair
| into a look-up table so that later the value associated with
| the name can be found by name.
|
| If the name is already found in the table then the old
| value associated with the name is replaced with the new
| value.
|
| The name string is copied into the table so the Name buffer
| need not be preserved after inserting the name into the
| table.  The name string is held in the general allocation
| space of the look-up table and is freed when the look-up
| table as a whole is deallocated.
|
| Use the companion function LookUpValue() to fetch the
| value of a (name,value) pair in a look-up table.
|
| Returns the address of the node record for the (name,value)
| pair.
|
| EXAMPLE: 
| 
|     InsertNameValue( MyLookUpTable, "SomeName", 1234 );
|
| ASSUMES:  
|
|     The length of the name string Name is not greater than 
|     the maximum key size of the look-up table set by
|     MakePatricia().
|
| HISTORY: 02.24.01 TL  
|          06.11.01 Factored out InsertKeyValue().
------------------------------------------------------------*/
PatNode*
InsertNameValue( 
    PatTree* LookUpTable, 
             // Address of the look-up table into which the
             // the (name,value) pair is to be inserted.
             //
    s8*      Name, 
             // The name string to be inserted, a zero-
             // terminated string.  This string is copied 
             // into the look-up table so it need not be 
             // preserved separately.
             //
    u32      Value )
             // The 32-bit value to be associated with the
             // name.
{
    u32      KeySize;
    PatNode* N;
     
    // Calculate the number of bytes in the name string
    // without the terminal zero.
    KeySize = CountString( Name );
    
    // Treat the bytes of the name as a binary key and
    // insert the (key,value) pair into the look up
    // table.
    N = InsertKeyValue( 
            LookUpTable, 
                 // Address of the look-up table into which 
                 // the (key,value) pair is to be inserted.
                 //
            (u8*) Name, 
                 // The key field to be inserted, any binary
                 // bytes can serve as a key.  This field is 
                 // copied into the look-up table so it need 
                 // not be preserved separately.
                 //
            KeySize,
                 // Size of the key in bytes.
                 //
            Value );
                 // The 32-bit value to be associated with 
                 // the key.
     
    // Return the node record address of the (name,value) 
    // pair.
    return( N );
}

/*------------------------------------------------------------
| InsertPatricia
|-------------------------------------------------------------
|
| PURPOSE: To insert a new key into a Patricia tree.
|
| DESCRIPTION: All additions to a Patricia tree come through
| this general insertion routine.
|
| Returns the node associated with the key.
|
| ASSUMES: The value at 'Key' is constant over the life of
|          the Patricia tree that refers to it.  
|
| HISTORY: 02.22.99 TL From 'patriciainsert' in 'Algorithms'.
|          03.03.99 Inlined the key match routine.
|          06.14.01 Added NumberOfNodes counter and Super
|                   linkage.
|          06.15.01 Restricted Offset -- to never go negative,
|                   this was an error.
|          06.16.01 Revised to distinguish between physical 
|                   and logical root nodes to support insertion 
|                   of new nodes as the logical root while 
|                   leaving the physical root fixed.  This
|                   change comes from the 3rd Edition of
|                   'Algorithms', fixing an error in earlier
|                   editions.
------------------------------------------------------------*/
PatNode*
InsertPatricia( 
    PatTree*    P,      // The tree where the key should be
                        // inserted.
                        // 
    u8*         Key,    // The address of the key to insert.
                        //
    u32         KeySize,// How many bytes are in the key.
                        //
    u32         Value ) // Any value associated with the key. 
{
    u8          Mask;
    u32         Offset;
    u32         IndexS, IndexQ, Index1stDiff;
    u32         IsNewNodeOnZeroBranch;
    u32         SubTreeIndex;
    u32         IsMatching;
    PatNode*    N;
    PatNode*    Q;
    PatNode*    R;
    PatNode*    S;
    PatNode*    K;
    
    // Calculate the index of the subtree in the family of
    // trees based on the key size.
    SubTreeIndex = KeySize - P->MinBytesPerKey;
    
    // Get the root node record as R.    
    R = P->Roots[ SubTreeIndex ];
    
    // If no root node exists.
    if( R == 0 )
    {
        // Then make a new node for the root of the subtree.
        K = MakePatNode( 
                P,
                    // The Patricia tree where the new node
                    // should be allocated.
                    //
                KeySize - 1, 
                    // The byte offset of the key-test-bit  
                    // associated with the new node.
                    //
                LAST_BIT_IN_BYTE,      
                    // The byte mask of the key-test-bit.
                    //
                    // This mask has a single 1 bit and all
                    // others set to zero.
                    //
                Key,       
                    // Address of the key associated with 
                    // the new node.  This address must
                    // remain good over the life of the
                    // node.
                    //
                Value ); 
                    // Any value associated with the key, in 
                    // a (key,value) pair this is the 'value'.
                    //
                    // If this field holds the bit pattern 
                    // defined by the NO_KEY_VALUE then there 
                    // is no value associated with the key.
        
        // Insert the node as the root of the tree.
        P->Roots[ SubTreeIndex ] = K;
        
        // Since the root has no superior, set the value of
        // the superior link to zero.
        K->Super = 0;
        
        // Make the node point to itself.
        K->Zero = K;
        K->One  = K;
                
        // Go finish up through the common exit.
        goto CommonExit;
    }
    
    //
    // Otherwise, a root node for the tree already exists.
    // 
     
    // Look for the given key in the tree.  This always returns
    // a node here even if not the exact one we're searching for.
    N = SearchPatricia( 
            P,          // The node where the search begins, 
                        // the root of the tree.    
                        // 
            Key,        // The value of the key to look for.
                        //
            KeySize );  // How long the key is.

    // Compare the key found to the search key.
    //
    // OUT: 1 if they match or 0 if not.
    IsMatching = IsMatchingBytes( Key, N->Key, KeySize );

    // If the keys match exactly.
    if( IsMatching )
    {
        // Update the value associated with the node found.
        N->Value = Value;
    
        // Return the node address.
        return( N );
    }
        
    //
    // The found node, 'N', differs from the search key.
    //
    //
    // Compare the search key with the key associated with
    // node N to find the offset of the first bit that
    // differs.
    FindFirstDifferentBit(
        N->Key,
            // Address of a key.
            //
        Key,//
            // Address of another key known to differ from the
            // first one.
            //
        &Offset,
            // OUT: Byte offset from the beginning of the
            // keys where the first difference was found
            // when searching from the least-significant-byte
            // to the most.
            //
        &Mask );
            // OUT: Bit mask of the least significant 
            // different bit in the byte at Key[Offset].
            
    // Make a new node record K.
    K = MakePatNode( 
            P,
                // The Patricia tree where the new node
                // should be allocated.
                //
            Offset,   
                // The byte offset of the key-test-bit  
                // associated with the new node.
                //
            Mask,       
                // The byte mask of the key-test-bit.
                //
                // This mask has a single 1 bit and all
                // others set to zero.
                //
            Key,       
                // Address of the key associated with 
                // the new node.  This address must
                // remain good over the life of the
                // node.
                //
            Value ); 
                // Any value associated with the key, in 
                // a (key,value) pair this is the 'value'.
                //
                // If this field holds the bit pattern 
                // defined by the NO_KEY_VALUE then there 
                // is no value associated with the key.
            
    // Combine the byte offset and bit mask of the first
    // different bit into a single index number that can
    // compared to others to gauge relative bit offsets in
    // the key.
    Index1stDiff = ToBitIndex( Offset, Mask );

    // Calculate the branch that should terminate in the
    // new node by testing the key-test-bit against the
    // key associated with the node.
    IsNewNodeOnZeroBranch = ( Key[Offset] & Mask ) == 0;
     
    //
    // Search from the root to the insertion point for the 
    // new node.
    //
    
    // Start at the root by initializing the search cursor Q.
    Q = R;
    
    // Get the key-test-bit mask and offset of the root.
    Mask   = Q->Mask;
    Offset = Q->Offset;

    // Calculate the key-test-bit index of the root.
    IndexQ = ToBitIndex( Offset, Mask );
    
    // If the root the key-bit-offset of the new node is lower 
    // than the key-bit-offset of the root node.
    if( Index1stDiff < IndexQ )
    {
        // Then insert the new node as the root, making
        // the current root a subordinate.
        P->Roots[ SubTreeIndex ] = K;
    
        // Since the root has no superior, set the value of
        // the superior link to zero.
        K->Super = 0;
        
        // Make K the superior of the old root node.
        R->Super = K;
        
        // If the new node is found via a zero branch.
        if( IsNewNodeOnZeroBranch )
        {
            // Then link the node to itself via the Zero
            // branch.
            K->Zero = K;
            
            // And link the old root via the One branch.
            K->One = R;
        }
        else
        {
            // Then link the node to itself via the One
            // branch.
            K->One = K;
            
            // And link the old root via the Zero branch.
            K->Zero = R;
        }
        
        // Finish via the common exit.
        goto CommonExit;
    }
    
    //
    // At this point it is known that the new node will
    // be inserted somewhere below the existing root node.
    //
    
    // For the search below, refer to either subordinate of 
    // Q as S, regardless of whether the Zero branch or the 
    // One branch is taken:
    //
    //                 Q
    //                / \  
    //             0 /   \ 1
    //              /     \  
    //             S   or  S
    //

    // Until the insertion point is found.
    while( 1 )
    {
        // If the test bit is set to 1.
        if( Mask & Key[ Offset ] )
        {
            // Get the One-branch subordinate node.
            S = Q->One;
        }
        else // The test bit value is zero.
        {
            // Get the Zero-branch subordinate node.
            S = Q->Zero;
        }
    
        // If S is not a subordinate of Q.
        if( S->Super != Q )
        {
            // Then the insertion point has been found.
            break;
        }
        
        // Calculate the bit index of the subordinate node.
        IndexS = ToBitIndex( S->Offset, S->Mask );

        // If S is a subordinate of Q but it has key-test-bit
        // after that of the node being inserted.
        if( Index1stDiff < IndexS )
        {
            // Then the insertion point has been found.
            break;
        }

        // Refer to the subordinate as the current node.
        Q      = S;
        Mask   = S->Mask;
        Offset = S->Offset;
    }
        
    // Insert the new node as the subordinate of Q and the 
    // superior of S.
            
    // Link the new node to its immediate superior 
    // held in Q.
    K->Super = Q;

    // If the superior of S was Q.
    if( S->Super == Q )
    {
        // Then make the superior of S be K.
        S->Super = K;
    }

    // If the subordinate of Q was reached via the
    // One branch.
    if( Mask & Key[ Offset ] )
    {
        // Then link from the superior to the new
        // node via the One branch.
        Q->One = K;
    }
    else // Subordinate is on the Zero branch.
    {
        // Then link from the superior to the new
        // node via the One branch.
        Q->Zero = K;
    }

    // If the new node is found via a zero branch.
    if( IsNewNodeOnZeroBranch )
    {
        // Then link the node to itself via the Zero
        // branch.
        K->Zero = K;

        // And link the old subordinate via the One 
        // branch.
        K->One = S;
    }
    else // New node is found via the one branch
         // from itself.
    {
        // Then link the node to itself via the One
        // branch.
        K->One = K;

        // And link the old subordinate via the Zero 
        // branch.
        K->Zero = S;
    }
      
/////////////    
CommonExit://
/////////////  

    // Account for the node added to the tree.
    P->InUseNodeCount += 1;
    
    // Return the new node.
    return( K );
}

/*------------------------------------------------------------
| InsertSubtree
|-------------------------------------------------------------
|
| PURPOSE: To insert the (key,value) pairs of a subtree into
|          a Patricia tree.
|
| DESCRIPTION:  
|
| The (key,value) pair of the root of the given subtree will 
| be inserted along with any proper subordinates of the root.
|
| A "proper subordinate" is one that doesn't loop back toward
| the root.
|
| EXAMPLE:     InsertSubtree( P, Q, 12 );
|
| ASSUMES: The key fields addresses of the subtree should 
|          simply be copied into the target tree without
|          reallocating any space.
|
| HISTORY: 06.14.01  
------------------------------------------------------------*/
void
InsertSubtree( 
    PatTree* P,
                // The tree holding the node.
                // 
    PatNode* R, // The root node of the subtree which holds
                // (key,value) pairs to be inserted into the
                // Patricia tree.
                //
                // The key fields will not be reallocated
                // when putting them into P.
                //
    u32      KeySize )
                // Size of the key in bytes.
{
    u32         StackBuffer[100];
    Stack       S;
    PatNode*    Q;
    PatNode*    N;
    PatNode*    Z;
    
    // Make a stack for traversing the tree.
    MakeStaticStack( &S, (u32*) &StackBuffer, 100 );
        
    // Push the root onto the stack.
    Push( &S, (u32) R );

    // As long as there is a value on the stack.
    while( S.StackIndex )
    {
        // Pop the top item off as the current node, 'Q'.
        Q = (PatNode*) Pull( &S );
    
        // Insert the (key,value) pair of Q into tree.
        InsertPatricia( 
            P,          // The tree where the key should be
                        // inserted.
                        // 
            Q->Key,     // The address of the key to insert.
                        //
            KeySize,    // How many bytes are in the key.
                        //
            Q->Value ); // Any value associated with the key. 
        
        // Refer to the subordinates of Q as Z and N.
        //
        //        Q
        //     0 / \ 1
        //      Z   N
        //
        Z = Q->Zero;
        N = Q->One;
    
        // If Q has a Zero-branch subordinate.
        if( Z->Super == Q )
        {
            // Push Z onto the stack.
            Push( &S, (u32) Z );
        }

        // If Q has a One-branch subordinate.
        if( N->Super == Q )
        {
            // Push N onto the stack.
            Push( &S, (u32) N);
        }
    }
}   

/*------------------------------------------------------------
| IsLeafNode
|-------------------------------------------------------------
|
| PURPOSE: To test a node in a Patricia tree to determine if
|          it is a leaf node, having one or more branches
|          that point upwards.
|
| DESCRIPTION: Only leaf nodes have keys associated with them.
|
| A "proper subordinate" is one that doesn't loop back toward
| the root.
|
| Returns 1 if the node is a leaf or 0 if not.
|
| EXAMPLE:     IsLeaf = IsLeafNode( Q );
|
| HISTORY: 06.14.01  
------------------------------------------------------------*/
    // OUT: 1 if the node is a leaf or 0 if not.
u32 //
IsLeafNode( PatNode* Q )
                     // Address of a node in a Patricia Tree.
{
    u32         IndexQ, IndexZ, IndexN;
    PatNode*    N;
    PatNode*    Z;
  
    // Refer to the subordinates of Q as Z and N.
    //
    //        Q
    //     0 / \ 1
    //      Z   N
    //
    Z = Q->Zero;
    N = Q->One;

    // Calculate the key bit "offsets" for all three nodes.
    IndexQ = ToBitIndex( Q->Offset, Q->Mask );
    IndexZ = ToBitIndex( Z->Offset, Z->Mask );
    IndexN = ToBitIndex( N->Offset, N->Mask );
    
    // If Z is not a proper subordinate of Q.
    if( IndexZ >= IndexQ )
    {
        // Then this is a leaf node.
        //
        // Return 1 to indicate that this is a leaf.
        return(1);
    }

    // If N is not a proper subordinate of Q.
    if( IndexN < IndexQ )
    {
        // Then this is a leaf node.
        //
        // Return 1 to indicate that this is a leaf.
        return(1);
    }
    
    // Both subordinates refer to nodes lower in the 
    // tree, that is, away from the root, so this is
    // not a leaf node.
    
    // Return 0 to indicate that the node is not a leaf.
    return(0);  
}   

/*------------------------------------------------------------
| IsPhysicalRoot
|-------------------------------------------------------------
|
| PURPOSE: To test a node in a Patricia tree to determine if
|          it is the physical root node of a subtree.
|
| DESCRIPTION: Each subtree has a physical root node which
| refers to a logical root node.
|
| If a node has no key address and links to itself via the
| One path then it is regarded as a physical root node.
|
| Returns 1 if the node is a physical root node or 0 if not.
|
| EXAMPLE:     IsPhys = IsPhysicalRoot( Q );
|
| HISTORY: 06.16.01  
------------------------------------------------------------*/
    // OUT: 1 if the node is a physical root or 0 if not.
u32 //
IsPhysicalRoot( PatNode* Q )
                     // Address of a node in a Patricia Tree.
{
    // If the node has no key and links to itself via the
    // One path.
    if( Q->Key == 0 && Q->One == Q )
    {   
        // Return 1 to signal that this is a physical root.
        return(1);
    }
    else // This node doesn't have the properties that
         // distinguish a physical root node from other
         // types of nodes.
    {
        // Return 0 to indicate that the node is not a 
        // physical root.
        return(0);  
    }
}   

/*------------------------------------------------------------
| LookUpValue
|-------------------------------------------------------------
|
| PURPOSE: To fetch the value of a (name,value) pair that is
|          held in a string-indexed look-up table.
|
| DESCRIPTION: If the given name is found in the look-up table
| then the value associated with the name is returned.
|
| If the name is not found then the code NO_KEY_VALUE is 
| returned.
|
| EXAMPLE: 
| 
|     InsertNameValue( MyLookUpTable, "SomeName", 1234 );
|
|     Value = LookUpValue( MyLookUpTable, "SomeName" );
|
| ASSUMES:  
|
|     The length of the name string Name is not greater than 
|     the maximum key size of the look-up table set by
|     MakePatricia().
|
| HISTORY: 02.24.01 TL  
|          06.11.01 Factored out LookUpValueByKey().
------------------------------------------------------------*/
u32
LookUpValue( 
    PatTree* LookUpTable, 
             // Address of the look-up table holding the
             // (name,value) pair.
             //
    s8*      Name ) 
             // The name string used to look up the value.
{
    u32      KeySize;
    u32      Value;
    
    // Calculate the number of bytes in the name string
    // without the terminal zero.
    KeySize = CountString( Name );
    
    Value =
        LookUpValueByKey( 
            LookUpTable, 
                 // Address of the look-up table holding the
                 // (name,value) pair.
                 //
            (u8*) Name, 
                 // The key field to be found, any binary
                 // bytes can serve as the key.
                 //
            KeySize );
                 // Size of the key in bytes.

    // Return the value associated with the name or
    // NO_KEY_VALUE if the key is not found in the
    // table.
    return( Value );
}

/*------------------------------------------------------------
| LookUpValueByKey
|-------------------------------------------------------------
|
| PURPOSE: To fetch the value of a (key,value) pair that is
|          held in a key-indexed look-up table.
|
| DESCRIPTION: If the given key is found in the look-up table
| then the value associated with the key is returned.
|
| If the key is not found then the code NO_KEY_VALUE is 
| returned.
|
| EXAMPLE: 
| 
|     InsertNameValue( MyLookUpTable, "SomeName", 1234 );
|
|     Value = LookUpValue( MyLookUpTable, "SomeName" );
|
| ASSUMES:  
|
|     The length of the key field is not greater than 
|     the maximum key size of the look-up table set by
|     MakePatricia().
|
|     If the key represents a number then the bytes are 
|     ordered in memory from LSB to MSB.
|
| HISTORY: 06.11.01 TL From LookUpValue().
------------------------------------------------------------*/
u32
LookUpValueByKey( 
    PatTree* LookUpTable, 
                 // Address of the look-up table holding the
                 // (key,value) pair.
                 //
    u8*      Key, 
                 // The key field to be found, any binary
                 // bytes can serve as a key. 
                 //
    u32      KeySize )
                 // Size of the key in bytes.
{
    PatNode* N;
    
    // Look to see if the name is already in the table.
    N = FindKeyPatricia( 
            LookUpTable,            
                // The tree to be searched. 
                // 
            Key,// The value of the key to look for.
                //
            KeySize );   
                // How many bytes are in the key.
    
    // If the key is in the table.
    if( N )
    {
        // Return the value associated with the key.
        return( N->Value );
    }
    else // If the key was not found.
    {
        // Return a code to signal missing key.
        return( NO_KEY_VALUE );
    }
}

/*------------------------------------------------------------
| MakePatNode
|-------------------------------------------------------------
|
| PURPOSE: To allocate a new PatNode record for a Patricia 
|          tree.
|
| DESCRIPTION: Allocates a new PatNode record and fills it 
| with zeros.
|
| Use the companion function FreePatNode() to deallocate
| a record allocated by this function.
|
| Returns the address of the new record.
|
| EXAMPLE:     
|
|       N = MakePatNode( P, Offset, Mask, Key, Value );
|
| ASSUMES: Link fields will be set later when the node is
|          inserted into the tree.
|
| HISTORY: 02.22.99 TL
|          06.14.01 Replaced memset with ZeroBytes and added
|                   free list.
|          06.17.01 Added setting of key-test-bit, key and
|                   value fields in the new node record.
------------------------------------------------------------*/
PatNode*
MakePatNode( 
    PatTree*    P,
                    // The Patricia tree where the new node
                    // should be allocated.
                    //
    u32         Offset,   
                    // The byte offset of the key-test-bit  
                    // associated with the new node.
                    //
    u8          Mask,       
                    // The byte mask of the key-test-bit.
                    //
                    // This mask has a single 1 bit and all
                    // others set to zero.
                    //
    u8*         Key,       
                    // Address of the key associated with 
                    // the new node.  This address must
                    // remain good over the life of the
                    // node.
                    //
    u32         Value )     
                    // Any value associated with the key, in 
                    // a (key,value) pair this is the 'value'.
                    //
                    // If this field holds the bit pattern 
                    // defined by the NO_KEY_VALUE then there 
                    // is no value associated with the key.
{
    PatNode*    N;
    
    // If there are any free PatNode records in this
    // tree. 
    if( P->FreeNodeList )
    {
        // Remove the first free record from the free 
        // list.

        // Refer to the first free record.
        N = (PatNode*) P->FreeNodeList;
        
        // Update the first free record.
        P->FreeNodeList = (u32*) *(P->FreeNodeList);
        
        // Decrement the count of free nodes.
        P->FreeNodeCount -= 1;
    }
    else // Need to allocate a new key record.
    {
        // Allocate space for the node record in the
        // node storage space of the tree.
        N = (PatNode*) 
            AllocateMS( P->NodeStorage, sizeof( PatNode ) );
    }

    // Fill the new record with zeros.
    ZeroBytes( (u8*) N, sizeof( PatNode ) );
    
    // Save the key-test-bit-offset, key and value fields.
    N->Offset = Offset;
    N->Mask   = Mask;
    N->Key    = Key;
    N->Value  = Value;
    
    // Return the address of the new record.
    return( N );
}

/*------------------------------------------------------------
| MakePatricia
|-------------------------------------------------------------
|
| PURPOSE: To make a new, empty Patricia tree.
|
| DESCRIPTION: Returns the address of the new tree or zero
| if unable to allocate a new tree.
|
| EXAMPLE: To make a Patricia tree that can hold keys from
| 1 to 5 bytes in length:
|
|                P = MakePatricia( 1, 5, 1 );
|
| HISTORY: 02.22.99 TL
|          02.07.01 TL Replaced MakeTable with MakeMass.
|          06.14.01 Added separate mass memory allocation
|                   pool for key data and free lists to
|                   recycle block and key data.
|                   Added IsKeysOwned parameter.
|          06.16.01 Revised to make a physical root node for
|                   each subtree which refers to the logical
|                   root node -- this is to support insertion 
|                   of new nodes as the logical root while 
|                   leaving the physical root fixed.  This
|                   change comes from the 3rd Edition of
|                   'Algorithms', fixing an error in earlier
|                   editions.
|          06.23.01 Added return of 0 on allocation failure.
------------------------------------------------------------*/
PatTree* // OUT: Address of a new tree or zero on failure.
MakePatricia(
    u32     MinBytesPerKey,  
                // The minimum size of each key in bytes.
                //
    u32     MaxBytesPerKey,  
                // The maximum size of each key in bytes.
                //
    u32     IsKeysOwned )    
                // Configuration flag set to 1 if the key 
                // data should be copied into the tree or
                // 0 if the key data is external to the
                // tree, being fixed over the life of the
                // tree.
                //
                // Owned key storage is dynamically allocated
                // and freed by the Patricia tree functions.
                //
                // Owned keys are non-overlapping in storage
                // but external keys may overlap.
{
    PatTree*    P;
    u32         BytesForRoots;
    u32         KeyFieldSize;
    u32         i;
    
    // Allocate a new record.
    P = (PatTree*) 
        AllocateMemoryAnyPoolHM( 
            ThePatriciaTreePool, 
            sizeof( PatTree ) );

    // If unable to allocate the tree.
    if( P == 0 )
    {
        // Just return zero to signal failure.
        return(0);
    }
    
    // Zero this new PatTree record.
    ZeroBytes( (u8*) P, sizeof( PatTree ) );
    
    // Save the key length limits.
    P->MinBytesPerKey = MinBytesPerKey;
    P->MaxBytesPerKey = MaxBytesPerKey;
    
    // Save the key ownership configuration.
    P->IsKeysOwned = IsKeysOwned;
    
    // Calculate how many subtrees are required to 
    // accomodate all of the key sizes given.
    P->SubTreeCount = ( MaxBytesPerKey - MinBytesPerKey ) + 1;
    
    // Calculate how many bytes will hold root node 
    // addresses: four bytes per record.
    BytesForRoots = P->SubTreeCount << 2;
    
    // Allocate a table to hold the root node records 
    // addresses: use a single block for all records.
    P->Roots = (PatNode**)  
        AllocateMemoryAnyPoolHM( 
            ThePatriciaTreePool, 
            BytesForRoots );
            
    // If unable to allocate the roots for the tree.
    if( P->Roots == 0 )
    {
        // Free the partially constructed tree.
        DeletePatricia( P );
        
        // And return zero to signal failure.
        return(0);
    }
            
    // Zero the array of subtree root nodes.
    ZeroBytes( (u8*) P->Roots, BytesForRoots );
    
    // Allocate a pool to hold the node records: node records
    // will be allocated in blocks of 10 at a time.
    P->NodeStorage =
        MakeMass( 
            100000000,
                    // MaximumStorageCapacity,
                    // The most amount of memory space that 
                    // can be set aside to hold this mass 
                    // memory pool.
                    //
            sizeof( PatNode ) * PATNOTES_PER_ALLOCATION_BLOCK, 
                    // FirstMassBlockSize,
                    // The size of the data storage field
                    // of the first mass memory block made when 
                    // this mass memory pool is first made.
                    //
            sizeof( PatNode ) * PATNOTES_PER_ALLOCATION_BLOCK );
                    // NextMassBlockSize,
                    // The minimum size of the data storage 
                    // field of a mass memory block: blocks may 
                    // be larger if the required data block is 
                    // larger.
                    
    // If unable to allocate the node storage pool for the tree.
    if( P->NodeStorage == 0 )
    {
        // Free the partially constructed tree.
        DeletePatricia( P );
        
        // And return zero to signal failure.
        return(0);
    }
                     
    // If key memory is owned by this tree.
    if( IsKeysOwned )
    {
        // Allocate an array of mass storage pools, one for
        // each key size.
        P->KeyStorage = (Mass**)  
            AllocateMemoryAnyPoolHM( 
                ThePatriciaTreePool, 
                BytesForRoots );
                
        // If unable to allocate the key storage pool array for 
        // the tree.
        if( P->KeyStorage == 0 )
        {
            // Free the partially constructed tree.
            DeletePatricia( P );
            
            // And return zero to signal failure.
            return(0);
        }
        
        // Zero the array of key storage pools.
        ZeroBytes( (u8*) P->KeyStorage, BytesForRoots );
 
        // For each potential subtree.
        for( i = 0; i < P->SubTreeCount; i++ )
        {
            // Calculate the effective key storage field size,
            // subject to the minimum size being four bytes to
            // accomodate the free list.
            KeyFieldSize = max( 4, MinBytesPerKey + i );
            
            // Allocate a pool to hold the key data.
            P->KeyStorage[i] =
                MakeMass( 
                    100000000,
                        // MaximumStorageCapacity,
                        // The most amount of memory space that 
                        // can be set aside to hold this mass 
                        // memory pool.
                        //
                    KeyFieldSize * KEYS_PER_ALLOCATION_BLOCK, 
                        // FirstMassBlockSize,
                        // The size of the data storage field
                        // of the first mass memory block made when 
                        // this mass memory pool is first made.
                        //
                    KeyFieldSize * KEYS_PER_ALLOCATION_BLOCK );
                        // NextMassBlockSize,
                        // The minimum size of the data storage 
                        // field of a mass memory block: blocks may 
                        // be larger if the required data block is 
                        // larger.
                        
            // If unable to allocate the key storage pool for 
            // the subtree.
            if( P->KeyStorage[i] == 0 )
            {
                // Free the partially constructed tree.
                DeletePatricia( P );
                
                // And return zero to signal failure.
                return(0);
            }
        }
        
        // Allocate an array to hold the list heads of
        // free list chains for each subtree.
        P->FreeKeyList = (u32**)  
            AllocateMemoryAnyPoolHM( 
                ThePatriciaTreePool, 
                BytesForRoots );
                
        // If unable to allocate the array. 
        if( P->FreeKeyList == 0 )
        {
            // Free the partially constructed tree.
            DeletePatricia( P );
            
            // And return zero to signal failure.
            return(0);
        }
                
        // Zero the array of free list head addresses.
        ZeroBytes( (u8*) P->FreeKeyList, BytesForRoots );
    }
    
    // Set the tree to it's empty state.
    EmptyPatricia( P );
    
    // Return the address of the new record.
    return( P );
}

/*------------------------------------------------------------
| ReinsertSubtree
|-------------------------------------------------------------
|
| PURPOSE: To reinsert the (key,value) pairs of a subtree 
|          into a Patricia tree.
|
| DESCRIPTION: This is used to re-insert the subtrees that
| are found beneath nodes being deleted from a Patricia tree.
|
|
| EXAMPLE:     ReinsertSubtree( P, Q, 12 );
|
| ASSUMES: The key fields addresses of the subtree should 
|          simply be copied into the target tree without
|          reallocating any space.
|
|          OK to use a different PatNode record so long as
|          the (key,value) association is maintained.
|          
|          The path to the subtree has been removed before
|          reinserting it.
|
| HISTORY: 06.19.01 From InsertSubTree().
------------------------------------------------------------*/
void
ReinsertSubtree( 
    PatTree* P,
                // The tree holding the node.
                // 
    PatNode* R, // The root node of the subtree which holds
                // (key,value) pairs to be reinserted into 
                // the Patricia tree.
                //
                // The key fields will not be reallocated
                // when putting them into P.
                //
    u32      KeySize )
                // Size of the key in bytes.
{
    u32         StackBuffer[100];
    Stack       S;
    PatNode*    Q;
    PatNode*    N;
    PatNode*    Z;
    
    // Make a stack for traversing the tree.
    MakeStaticStack( &S, (u32*) &StackBuffer, 100 );
        
    // Push the root onto the stack.
    Push( &S, (u32) R );

    // As long as there is a value on the stack.
    while( S.StackIndex )
    {
        // Pop the top item off as the current node, 'Q'.
        Q = (PatNode*) Pull( &S );
    
        // Insert the (key,value) pair of Q into tree.
        InsertPatricia( 
            P,          // The tree where the key should be
                        // inserted.
                        // 
            Q->Key,     // The address of the key to insert.
                        //
            KeySize,    // How many bytes are in the key.
                        //
            Q->Value ); // Any value associated with the key. 
        
        // Refer to the subordinates of Q as Z and N.
        //
        //        Q
        //     0 / \ 1
        //      Z   N
        //
        Z = Q->Zero;
        N = Q->One;
    
        // If Q has a Zero-branch subordinate.
        if( Z->Super == Q )
        {
            // Push Z onto the stack.
            Push( &S, (u32) Z );
        }

        // If Q has a One-branch subordinate.
        if( N->Super == Q )
        {
            // Push N onto the stack.
            Push( &S, (u32) N);
        }
        
        // Free the current record.
        FreePatNode( P, Q );
    }
}   

/*------------------------------------------------------------
| SearchPatricia
|-------------------------------------------------------------
|
| PURPOSE: To search a Patricia tree for a key value.
|
| DESCRIPTION: Returns the node of the closest matching node
| or zero if no nodes for the given key size exist in the
| tree.
|
| After you get the return value from this routine make sure
| to compare the key in the resulting node to the search key 
| to determine if they match.
|
| ASSUMES: The given key size is one supported in the tree.
|
| HISTORY: 02.22.99 TL From 'patriciasearch' in 'Algorithms'.
|          06.16.01 Revised using description in 3rd edition
|                   of 'Algorithms' book, factored out
|                   ToBitIndex() as a macro.
|          06.17.01 Changed to use Super link to distinguish
|                   subordinate nodes from insubordinate ones.
------------------------------------------------------------*/
PatNode*
SearchPatricia( 
    PatTree*    P,        // The tree to be searched.   
                          // 
    u8*         Key,      // The value of the key to look for.
                          //
    u32         KeySize ) // How many bytes are in the key.
{
    u32         SubTreeIndex;
    PatNode*    Q;
    PatNode*    S;
   
    // Calculate the index of the tree in the family of
    // trees based on the key size.
    SubTreeIndex = KeySize - P->MinBytesPerKey;
    
    // Get the address of the root node record.     
    Q = P->Roots[ SubTreeIndex ];

    // If there is no  root node.
    if( Q == 0 )
    {
        // Return zero to indicate that the key wasn't 
        // found because no keys of the given length are 
        // in the tree.
        return( 0 );
    }
    
    // Refer to either subordinate of Q as S, regardless
    // of whether the Zero branch or the One branch is
    // taken:
    //
    //                 Q
    //                / \  
    //             0 /   \ 1
    //              /     \  
    //             S   or  S
    //
    
    // Until a non-downward branch is found -- nodes may loop 
    // back on themselves as well as to higher order nodes.
    while( 1 )
    {
        // If the test bit is set to 1.
        if( Key[ Q->Offset ] & Q->Mask )
        {
            // Refer to the One-branch node.
            S = Q->One;
        }
        else // The test bit value is zero.
        {
            // Refer to the Zero-branch node.
            S = Q->Zero;
        }
        
        // If S is a subordinate of Q.
        if( S->Super == Q )
        {
            // Refer to the subordinate as the current node.
            Q = S;
        }
        else // S is insubordinate of Q.
        {            
            // Return the terminal node address, the one 
            // found at the end of an insubordinate branch.
            return( S );
        }
    }
}

