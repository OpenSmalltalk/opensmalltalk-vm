/*------------------------------------------------------------
| TLPatriciaTreeTest.c
|-------------------------------------------------------------
|
| PURPOSE: To test and demonstrate the use of Patricia tree
|          functions.
|
| DESCRIPTION:
|
| NOTE: 
|
| HISTORY: 02.23.99 From 'TLTableTest.c'.
------------------------------------------------------------*/
#include "TLTarget.h" // Include this first.

#ifndef FOR_DRIVER

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>

#endif // FOR_DRIVER
     
#include "TLTypes.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLAscii.h"
#include "TLDyString.h"
#include "TLStrings.h"
#include "TLList.h"
#include "TLTesting.h"
#include "TLRandom.h"  
#include "TLMassMem.h" 
#include "TLStacks.h"

#include "TLPatriciaTree.h"

// Define the following symbol to run these tests separately
// as a standalone program, making the 'main()' routine 
// included.
#define FOR_MAIN    1

void    DumpPatNode( PatNode*, u32 );
void    DumpPatriciaTree( PatTree* );
#ifdef FOR_MAIN
u32     main();
#else
u32     PatriciaTreeTest_main();
#endif
u32     ValidatePatriciaTree( PatTree* );
u32     Test_DeleteKeyValue();
u32     Test_DeleteKeyValue2();
u32     Test_DeleteKeyValue3();
u32     Test_DeletePatricia();
u32     Test_InsertKeyValue();
u32     Test_InsertKeyValue2();
u32     Test_MakePatricia();
u32     TestPatriciaTree();
void    TestPatriciaTree2();
 
// Test order is important: validity of later tests depends on earlier ones. 
TestRecord    
PatriciaTreeTestSequence[] =
{
    { Test_MakePatricia,       (s8*) "Test_MakePatricia"    }, 
    { Test_DeletePatricia,     (s8*) "Test_DeletePatricia"  }, 
    { Test_InsertKeyValue,     (s8*) "Test_InsertKeyValue"  }, 
    { Test_InsertKeyValue2,    (s8*) "Test_InsertKeyValue2" }, 
    { Test_DeleteKeyValue,     (s8*) "Test_DeleteKeyValue"  },
    { Test_DeleteKeyValue2,    (s8*) "Test_DeleteKeyValue2" },
    { Test_DeleteKeyValue3,    (s8*) "Test_DeleteKeyValue3" },
    { 0, 0 } // This terminates the list.
};

/*------------------------------------------------------------
| DumpPatNode
|-------------------------------------------------------------
|
| PURPOSE: To output a description of a Patricia tree node to  
|          the log for debugging.
|
| DESCRIPTION: Outputs the node to standard output, like this:
|
|      Node( 1031205 ) 0( 123123 ) 1( 1231231 ) Value( 243432 )
|         Bit( 0000000000001000000000000000 )
|         Key( 1010101111101010101000010010 )
|
| EXAMPLE:     
|
| ASSUMES: Keys are less than 10 bytes long.
|
| HISTORY: 02.23.99 TL From 'DumpTable()'.
|          02.07.01 TL Changed FillBytes to memset.
|          06.18.01 Added Super link dump.
------------------------------------------------------------*/
void
DumpPatNode( 
    PatNode*    N,          // The node to be dumped.
                            //
    u32         KeySize )   // How many bytes of the key to
                            // dump.
{
    s8  BitMapString[132];
    u8  MaskBits[132];
    
    // Print the first line.
    printt( "Node( %lx ) S( %lx ) 0( %lx ) 1( %lx ) Value( %lx )\n",
                (u32) N,
                (u32) N->Super,
                (u32) N->Zero,
                (u32) N->One,
                (u32) N->Value );
    
    // If the key size is less than 10 bytes long.
    if( KeySize < 10 )
    {
        // Make a bit image of the mask bit: first zero the whole
        // buffer.
        ZeroBytes( (u8*) MaskBits, 132 );
        
        // Set the bit in the buffer.
        MaskBits[ N->Offset ] |= N->Mask;

        // Convert the mask bitmap to a string.
        ConvertBitsToString2( 
            (u8*) MaskBits, 
            BitMapString, 
            KeySize << 3 );

        // Print the second line.
        printt( "    Bit( %s )\n", BitMapString );
     
        // Convert the key bitmap to a string.
        ConvertBitsToString2( 
            (u8*) N->Key, 
            BitMapString, 
            KeySize << 3 );

        // Print the third line.
        printt( "    Key( %s )\n", BitMapString );
    }
    
    printt( "\n" );  
}

/*------------------------------------------------------------
| DumpPatriciaTree
|-------------------------------------------------------------
|
| PURPOSE: To output a description of a Patricia tree to  
|          the log for debugging.
|
| DESCRIPTION: Outputs the nodes in the order in which they
| were added to the tree.
|
| Tree( 4230324 ) KeySizes( 1 - 4 )
|
|      Node( 1031205 ) 0( 123123 ) 1( 1231231 ) Value( 243432 )
|         Bit( 00000001 )
|         Key( 10101011 )
|
|      Node( 1031205 ) 0( 123123 ) 1( 1231231 ) Value( 243432 )
|         Bit( 00001000 )
|         Key( 10111011 )
|
| ASSUMES: Keys are less than ten bytes long.
|
|          Mass memory is used for PatNode storage.
|
|          Separate mass memory are is used for PatNodes and
|          for key data.
|
| HISTORY: 02.23.99 TL From 'DumpTable()'.
|          02.07.01 TL Revised from Table record traversal
|                      to record traversal within mass mem
|                      blocks.
|          06.15.01 Revised to traverse from root rather than
|                   via the physical storage allocation.
------------------------------------------------------------*/
void
DumpPatriciaTree( PatTree*  P )
{
    PatNode*    Q;
    u32         KeySize;
    u32         StackBuffer[100];
    Stack       S;
    u32         SubTreeIndex;
    
    // Print the first line.
    printt( "Tree( %lx ) KeySizes( %ld - %ld )=============\n",
            (u32) P,
            (u32) P->MinBytesPerKey,
            (u32) P->MaxBytesPerKey );
     
    // Make a stack for traversing the tree.
    MakeStaticStack( &S, (u32*) &StackBuffer, 100 );
      
    // For every subtree, one for each key size.
    for( KeySize = P->MinBytesPerKey;
         KeySize <= P->MaxBytesPerKey;
         KeySize++ )
    {
        // Calculate the index of the subtree in the family 
        // of trees of this Patricia tree.
        SubTreeIndex = KeySize - P->MinBytesPerKey;

        // Refer to the root node for this key size.
        Q = P->Roots[ SubTreeIndex ];
        
        // If there is a root.
        if( Q )
        {
            // Push the root onto the stack.
            Push( &S, (u32) Q );
            
            // As long as there is a value on the stack.
            while( S.StackIndex )
            {
                // Pop the top item off as the current
                // node, 'Q'.
                Q = (PatNode*) Pull( &S );
                
                // Dump the node to the log.
                DumpPatNode( 
                    Q,          
                        // The node to be dumped.
                        //
                    KeySize );
                        // How many bytes of the key to
                        // dump.
                                 
                //        Q
                //     0 / \ 1
                //      Z   N
            
                // If Q has a Zero-branch subordinate.
                if( Q->Zero->Super == Q )
                {
                    // Push Z onto the stack.
                    Push( &S, (u32) Q->Zero );
                }
                
                // If Q has a One-branch subordinate.
                if( Q->One->Super == Q )
                {
                    // Push N onto the stack.
                    Push( &S, (u32) Q->One );
                }
            }
        }
    }
}       

/*------------------------------------------------------------
| Test_DeleteKeyValue
|-------------------------------------------------------------
|
| PURPOSE: To test the DeleteKeyValue() function using
|          a known sequence of keys of fixed size.
|
| DESCRIPTION: 
| 
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 06.18.01
------------------------------------------------------------*/
u32 
Test_DeleteKeyValue()
{
    u32         KeySize;
    u32         i, j, k, Value;
    PatTree*    P;
    u32         IsKeysOwned;
    Buf         Keys;
    u32         Before;
    u32         KeyBufSize;
    u32         MinBytesPerKey;
    u32         MaxBytesPerKey;
    u32         Trials;
    u8*         Key;
    u32         status;
    u32         InUseNodeCount;
    u32         KeysToInsert;
    
    // Specify the range of key sizes to be tested.
    MinBytesPerKey = 1;
    MaxBytesPerKey = 1;
    
    // Set the number of keys to insert and delete on each pass.
    KeysToInsert = 256;
            
    // Specify how many trials should be made.
    Trials = 10000; 
    
    // Keep separate key storage.
    IsKeysOwned = 1;
    
    // Set the key size to 1 byte.
    KeySize = 1;
     
    // Specify the size of the buffer to hold the source of 
    // random key values, in bytes.
    KeyBufSize = KeysToInsert * KeySize;
    
    // Allocate a 64K buffer to hold the key values.
    AllocateBuf( &Keys, KeyBufSize );

    // Fill the key buffer with keys 0 - 255.
    for( i = 0; i < KeysToInsert; i++ )
    {
        // Use the key offset as the key value.
        Keys.Lo[i] = (u8) i;
    }
    
    // Note how much memory is being used before
    // allocating the Patricia tree.
    Before = TheTotalBytesInUseHM;

    // Make a new Patricia tree.
    P = MakePatricia(
            MinBytesPerKey,  
                // The minimum size of each key in bytes.
                //
            MaxBytesPerKey,  
                // The maximum size of each key in bytes.
                //
            IsKeysOwned );
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
    
    // For 10,000 sets of 256 key.
    for( j = 0; j < Trials; j++ )
    {
        // Every 100 trials.
        if( (j % 100) == 0 )
        {
            // Report the beginning of the trial.
            printt( "Trial %d\n", j );
        }
        
        // Randomly shuffle the keys.
        ShuffleBytes( Keys.Lo, KeysToInsert );
        
        // Insert keys starting with the StartKey.
        for( i = 0; i < KeysToInsert; i++ )
        {
            // Refer to the key.
            Key = Keys.Lo + i;
        
            // Insert the key with the trial number as the value.
            InsertKeyValue( 
                P,  //
                    // Address of the look-up table into which 
                    // the (key,value) pair is to be inserted.
                    //
                Key,//
                    // The key field to be inserted, any binary
                    // bytes can serve as a key.  This field is 
                    // copied into the look-up table so it need 
                    // not be preserved separately.
                    //
                KeySize,
                    // Size of the key in bytes.
                    //
                (u32) *Key );
                    // The 32-bit value to be associated with 
                    // the key.
                    //
                    // Use the key as the value.
        }
        
        // Randomly shuffle the keys.
        ShuffleBytes( Keys.Lo, KeysToInsert );
        
        // Delete keys in a random order different from that
        // which they were inserted.
        for( i = 0; i < KeysToInsert; i++ )
        {
            // Refer to the key.
            Key = Keys.Lo + i;
            
            // Note how many in-use nodes are in the tree.
            InUseNodeCount = P->InUseNodeCount;
            
            // Delete the key.
            DeleteKeyValue( 
                P,  //     
                    // The tree where the key should be 
                    // inserted.
                Key,//
                    // The address of the key to insert.
                    //
                KeySize );
                    // Number of bytes in the key.
            
            // If the number of in-use nodes in the tree is
            // not one less than it was.
            if( P->InUseNodeCount != (InUseNodeCount - 1) )
            {
                return(2);
            }
            
            // Test the validity of the tree after making the
            // deletion.
            status = ValidatePatriciaTree(P);
            
            // If the tree is invalid then status will be non-zero.
            if( status )
            {
                // Return the failure code.
                return( status * 1000 );
            }
                         
            // Look for the remaining keys that should still 
            // be in the tree.
            for( k = i + 1; k < KeysToInsert; k++ )
            {
                // Refer to the key.
                Key = Keys.Lo + k;
            
                // Look up the value associated with the key, it
                // should be the same as the key.
                Value =
                    LookUpValueByKey( 
                        P,   //
                             // Address of the look-up table holding the
                             // (name,value) pair.
                             //
                        Key, //
                             // The key field to be inserted, any binary
                             // bytes can serve as a key.  This field is 
                             // copied into the look-up table so it need 
                             // not be preserved separately.
                             //
                        KeySize );
                             // Size of the key in bytes.
            
                // If the value found is not the same as the key.
                if( Value != (u32) (*Key) )
                {
                    return(3);
                }
            }
        }
        
        // If any keys remain in the tree.
        if( P->InUseNodeCount )
        {
            return(4);
        }
    }
    
    // Deallocate the Patricia tree.
    DeletePatricia( P ); 
    
    // If the number of bytes in use in the memory
    // pool is not the same as before.
    if( TheTotalBytesInUseHM != Before )
    {
        return(4);
    }
    
    // Free the key buffer.
    FreeBuf( &Keys );

    return(0);
}   

/*------------------------------------------------------------
| Test_DeleteKeyValue2
|-------------------------------------------------------------
|
| PURPOSE: To test the DeleteKeyValue() function using
|          a known sequence of keys of fixed size.
|
| DESCRIPTION: This is the same test as Test_DeleteKeyValue
| except for being 2 byte keys instead of 1.
| 
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 06.18.01 From Test_DeleteKeyValue.
------------------------------------------------------------*/
u32 
Test_DeleteKeyValue2()
{
    u32         KeySize;
    u32         i, j, k, Value;
    PatTree*    P;
    u32         IsKeysOwned;
    Buf         Keys;
    u32         Before;
    u32         KeyBufSize;
    u32         MinBytesPerKey;
    u32         MaxBytesPerKey;
    u32         Trials;
    u8*         Key;
    u32         status;
    u32         InUseNodeCount;
    u32         KeysToInsert;
    
    // Note how much memory is being used before
    // allocating the Patricia tree.
    Before = TheTotalBytesInUseHM;
     
    // Specify the range of key sizes to be tested.
    MinBytesPerKey = 2;
    MaxBytesPerKey = 2;
    
    // Set the number of keys to insert and delete on each pass.
    KeysToInsert = 256 * 256;
            
    // Specify how many trials should be made.
    Trials = 10000; 
    
    // Keep separate key storage.
    IsKeysOwned = 1;
    
    // Set the key size to 2 bytes.
    KeySize = 2;
     
    // Specify the size of the buffer to hold the source of 
    // random key values, in bytes.
    KeyBufSize = KeysToInsert * KeySize;
    
    // Allocate a 64K buffer to hold the key values.
    AllocateBuf( &Keys, KeyBufSize );

    // Fill the key buffer with keys.
    for( i = 0; i < KeysToInsert; i++ )
    {
        // Use the key index as the key value, saving keys
        // in LSB -> MSB order.
        Keys.Lo[i*KeySize]       = (u8) i;
        Keys.Lo[(i*KeySize) + 1] = (u8) (i>>8);
    }
    
    // Make a new Patricia tree.
    P = MakePatricia(
            MinBytesPerKey,  
                // The minimum size of each key in bytes.
                //
            MaxBytesPerKey,  
                // The maximum size of each key in bytes.
                //
            IsKeysOwned );
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
    
    // For 10,000 sets of 256 key.
    for( j = 0; j < Trials; j++ )
    {
        // Every 100 trials.
        if( (j % 100) == 0 )
        {
            // Report the beginning of the trial.
            printt( "Trial %d\n", j );
        }
        
        // Randomly shuffle the keys.
        ShufflePairs( (u16*) Keys.Lo, KeysToInsert );
        
        // Insert keys starting with the StartKey.
        for( i = 0; i < KeysToInsert; i++ )
        {
            // Every 100 insertions.
            if( (i % 100) == 0 )
            {
                // Report the beginning of the trial.
                printt( "    Insertion %d\n", i );
            }

            // Refer to the key.
            Key = Keys.Lo + (i * KeySize);
        
            // Insert the key with the trial number as the value.
            InsertKeyValue( 
                P,  //
                    // Address of the look-up table into which 
                    // the (key,value) pair is to be inserted.
                    //
                Key,//
                    // The key field to be inserted, any binary
                    // bytes can serve as a key.  This field is 
                    // copied into the look-up table so it need 
                    // not be preserved separately.
                    //
                KeySize,
                    // Size of the key in bytes.
                    //
                (u32) ( Key[1] << 8 | Key[0] ) );
                    // The 32-bit value to be associated with 
                    // the key.
                    //
                    // Use the key as the value.
        }
        
        // Randomly shuffle the keys.
        ShufflePairs( (u16*) Keys.Lo, KeysToInsert );
        
        // Delete keys in a random order different from that
        // which they were inserted.
        for( i = 0; i < KeysToInsert; i++ )
        {
            // Every 100 deletions.
            if( (i % 100) == 0 )
            {
                // Report the beginning of the trial.
                printt( "    Deletion %d\n", i );
            }
        
            // Refer to the key.
            Key = Keys.Lo + (i * KeySize);
            
            // Note how many in-use nodes are in the tree.
            InUseNodeCount = P->InUseNodeCount;
            
            // Delete the key.
            DeleteKeyValue( 
                P,  //     
                    // The tree where the key should be 
                    // inserted.
                Key,//
                    // The address of the key to insert.
                    //
                KeySize );
                    // Number of bytes in the key.
            
            // If the number of in-use nodes in the tree is
            // not one less than it was.
            if( P->InUseNodeCount != (InUseNodeCount - 1) )
            {
                return(2);
            }
            
            // Test the validity of the tree after making the
            // deletion.
            status = ValidatePatriciaTree(P);
            
            // If the tree is invalid then status will be non-zero.
            if( status )
            {
                // Return the failure code.
                return( status * 1000 );
            }
                         
            // Look for the remaining keys that should still 
            // be in the tree.
            for( k = i + 1; k < KeysToInsert; k++ )
            {
                // Refer to the key.
                Key = Keys.Lo + (k * KeySize);
            
                // Look up the value associated with the key, it
                // should be the same as the key.
                Value =
                    LookUpValueByKey( 
                        P,   //
                             // Address of the look-up table holding the
                             // (name,value) pair.
                             //
                        Key, //
                             // The key field to be inserted, any binary
                             // bytes can serve as a key.  This field is 
                             // copied into the look-up table so it need 
                             // not be preserved separately.
                             //
                        KeySize );
                             // Size of the key in bytes.
            
                // If the value found is not the same as the key.
                if( Value != (u32) ( Key[1] << 8 | Key[0] ) )
                {
                    return(3);
                }
            }
        }
        
        // If any keys remain in the tree.
        if( P->InUseNodeCount )
        {
            return(4);
        }
    }
    
    // Deallocate the Patricia tree.
    DeletePatricia( P ); 
    
    // Free the key buffer.
    FreeBuf( &Keys );
    
    // If the number of bytes in use in the memory
    // pool is not the same as before.
    if( TheTotalBytesInUseHM != Before )
    {
        return(4);
    }

    return(0);
}   

/*------------------------------------------------------------
| Test_DeleteKeyValue3
|-------------------------------------------------------------
|
| PURPOSE: To test the DeleteKeyValue() function using
|          a pseudo-random sequences of keys of various
|          sizes.
|
| DESCRIPTION: 
| 
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 06.18.01
------------------------------------------------------------*/
u32 
Test_DeleteKeyValue3()
{
    u32         KeySize;
    u32         i, j;
    PatTree*    P;
    u32         IsKeysOwned;
    Buf         Keys;
    u32         Before;
    u32         KeyBufSize;
    u32         MinBytesPerKey;
    u32         MaxBytesPerKey;
    u32         Trials;
    u8*         Key;
    u32         KeysToInsert;
    u32         KeyOffset;
    
    // Note how much memory is being used before
    // allocating the Patricia tree.
    Before = TheTotalBytesInUseHM;
     
    // Specify the range of key sizes to be tested.
    MinBytesPerKey = 1;
    MaxBytesPerKey = 32;
    
    // Don't duplicate keys for this test.
    IsKeysOwned    = 0;
    
    // Specify the size of the buffer to hold the source
    // of random key values, in bytes.
    KeyBufSize = 64 * 1024;
    
    // Allocate a 64K buffer to hold the key values.
    AllocateBuf( &Keys, KeyBufSize );

    // Make a new Patricia tree.
    P = MakePatricia(
            MinBytesPerKey,  
                // The minimum size of each key in bytes.
                //
            MaxBytesPerKey,  
                // The maximum size of each key in bytes.
                //
            IsKeysOwned );
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

    // Set the number of keys to insert and delete on
    // each pass.
    KeysToInsert = 10000;
            
    // Specify how many trials should be made.
    Trials = 100; 
    
    // For 100,000 sets of random keys.
    for( j = 0; j < Trials; j++ )
    {
        // Report the beginning of the trial.
        printt( "Trial %d\n", j );
        
        // Initialize the random number generator.
        SetUpRandomNumberGenerator( RandomSeedForTest + j );
        
        // Fill the key buffer with random bytes.       
        RandomBytes( Keys.Lo, KeyBufSize );
        
        // Insert up to 10,000 randomly selected keys into the 
        // tree.
        //
        // If a key is found in the tree before inserting it
        // then the value remains as it was originally set.
        //
        // For each trial.
        for( i = 0; i < KeysToInsert; i++ )
        {
            // Every 1000 insertions.
            if( (i % 1000) == 0 )
            {
                // Report the beginning of the trial.
                printt( "    Insertion %d\n", i );
            }
        
            // Pick a random key size.
            KeySize = 
                 RandomIntegerFromRange( 
                    MinBytesPerKey, 
                    MaxBytesPerKey );

            // Pick a random key offset in the key buffer.
            KeyOffset = 
                RandomIntegerFromRange( 
                    0, 
                    KeyBufSize - ( KeySize + 1 ) );
            
            // Refer to the key.
            Key = Keys.Lo + KeyOffset;
        
            // Insert the key with the trial number as the value.
            InsertKeyValue( 
                P, 
                     // Address of the look-up table into which 
                     // the (key,value) pair is to be inserted.
                     //
                Key, 
                     // The key field to be inserted, any binary
                     // bytes can serve as a key.  This field is 
                     // copied into the look-up table so it need 
                     // not be preserved separately.
                     //
                KeySize,
                     // Size of the key in bytes.
                     //
                i );
                     // The 32-bit value to be associated with 
                     // the key.
        }
        
        // Initialize the random number generator.
        SetUpRandomNumberGenerator( RandomSeedForTest + j );
        
        // Fill the key buffer with random bytes.       
        RandomBytes( Keys.Lo, KeyBufSize );

        // Delete keys in the table using the same sequence
        // of keys inserted above. 
        //
        // For each trial.
        for( i = 0; i < KeysToInsert; i++ )
        {
            // Every 1000 insertions.
            if( (i % 1000) == 0 )
            {
                // Report the beginning of the trial.
                printt( "    Deletion %d\n", i );
            }
        
            // Pick a random key size.
            KeySize = 
                 RandomIntegerFromRange( 
                    MinBytesPerKey, 
                    MaxBytesPerKey );

            // Pick a random key offset in the key buffer.
            KeyOffset = 
                RandomIntegerFromRange( 
                    0, 
                    KeyBufSize - ( KeySize + 1 ) );
            
            // Refer to the key.
            Key = Keys.Lo + KeyOffset;
            
            // Delete the key.
            DeleteKeyValue( 
                P,  //     
                    // The tree where the key should be 
                    // inserted.
                Key,//
                    // The address of the key to insert.
                    //
                KeySize );
                    // Number of bytes in the key.
        }
        
        // At this point all keys should have been deleted from
        // the tree.
        //
        // If there are any nodes still in use.
        if( P->InUseNodeCount )
        {
            return(2);
        }
    }
    
    // Deallocate the Patricia tree.
    DeletePatricia( P ); 
    
    // Free the key buffer.
    FreeBuf( &Keys );

    // If the number of bytes in use in the memory
    // pool is not the same as before.
    if( TheTotalBytesInUseHM != Before )
    {
        return(4);
    }
    
    return(0);
}   

/*------------------------------------------------------------
| Test_DeletePatricia
|-------------------------------------------------------------
|
| PURPOSE: To test the DeletePatricia() function.
|
| DESCRIPTION: 
| 
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 06.17.01
------------------------------------------------------------*/
u32 
Test_DeletePatricia()
{
    u32         KeySize;
    PatTree*    P;
    u32         IsKeysOwned;
    u32         Before;
    
    // For keys not owned and not owned.
    for( IsKeysOwned = 0; IsKeysOwned <= 1; IsKeysOwned++ )
    {
        // For key sizes ranging from 1 to 1024 bytes.
        for( KeySize = 1; KeySize <= 1024; KeySize++ )
        {
            // Get the memory pool allocation count
            // before making the Patricia tree.
            Before = TheTotalBytesInUseHM;
            
            // Make a new Patricia tree.
            P = MakePatricia(
                    1,  
                        // The minimum size of each key in 
                        // bytes.
                        //
                    KeySize,  
                        // The maximum size of each key in 
                        // bytes.
                        //
                    IsKeysOwned );
                        // Configuration flag set to 1 if the 
                        // key data should be copied into the 
                        // tree or 0 if the key data is 
                        // external to the tree, being fixed 
                        // over the life of the tree.
                        //
                        // Owned key storage is dynamically 
                        // allocated and freed by the Patricia 
                        // tree functions.
                        //
                        // Owned keys are non-overlapping in 
                        // storage but external keys may 
                        // overlap.
            
            // Deallocate the Patricia tree.
            DeletePatricia( P );  
            
            // If the number of bytes in use in the memory
            // pool is not the same as before.
            if( TheTotalBytesInUseHM != Before )
            {
                return(1);
            }
        }
    } 
    
    return(0); 
}

/*------------------------------------------------------------
| Test_InsertKeyValue
|-------------------------------------------------------------
|
| PURPOSE: To test the InsertKeyValue() function.
|
| DESCRIPTION: 
| 
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 06.17.01
------------------------------------------------------------*/
u32 
Test_InsertKeyValue()
{
    u32         KeySize;
    u32         i, Value;
    PatTree*    P;
    PatNode*    N;
    u32         IsKeysOwned;
    Buf         Keys;
    u32         KeyCount;
    u32         Before;
    
    // For keys not owned and not owned.
    for( IsKeysOwned = 0; IsKeysOwned <= 1; IsKeysOwned++ )
    {
        // For key sizes ranging from 1 to 2 bytes.
        for( KeySize = 1; KeySize <= 2; KeySize++ )
        {
            // If there is one byte per key.
            if( KeySize == 1 )
            {
                // Then there are 256 different keys.
                KeyCount = 256;
            }
            else // There are two bytes per key.
            {
                // So there are 256 * 256 different keys.
                KeyCount = 256 * 256;
            }
            
            // Note how much memory is being used before
            // allocating any.
            Before = TheTotalBytesInUseHM;
            
            // Allocate a buffer to hold the key values.
            AllocateBuf( &Keys, KeyCount * KeySize );
            
            // Generate key values using the offset of the 
            // key value AS the key value.
            // 
            // For each key value.
            for( i = 0; i < KeyCount; i++ )
            {
                // If there is one byte per key.
                if( KeySize == 1 )
                {
                    // Set the key value to the key offset.
                    Keys.Lo[i] = i;
                }
                else // There are two bytes per key.
                {
                    // Save the low byte first.
                    Keys.Lo[i*2] = (u8) i & 0xff;
                    
                    // Followed by the high byte.
                    Keys.Lo[(i*2)+1] = (u8) ( (i>>8) & 0xff );
                }
            }
    
            // Make a new Patricia tree.
            P = MakePatricia(
                    KeySize,  
                        // The minimum size of each key in bytes.
                        //
                    KeySize,  
                        // The maximum size of each key in bytes.
                        //
                    IsKeysOwned );
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
                        
            // Insert every possible key value into the tree.
            // 
            // For each key value.
            for( i = 0; i < KeyCount; i++ )
            {
                // Insert key i into the tree.
                N = InsertKeyValue( 
                        P, 
                             // Address of the look-up table into which 
                             // the (key,value) pair is to be inserted.
                             //
                        Keys.Lo + (i * KeySize ), 
                             // The key field to be inserted, any binary
                             // bytes can serve as a key.  This field is 
                             // copied into the look-up table so it need 
                             // not be preserved separately.
                             //
                        KeySize,
                             // Size of the key in bytes.
                             //
                        i );
                             // The 32-bit value to be associated with 
                             // the key.
                
                // If unable to insert the (key,value) pair.
                if( N == 0 )
                {
                    return(1);
                }
            }
            
            // Look up every possible key value in the tree.
            // 
            // For each key value.
            for( i = 0; i < KeyCount; i++ )
            {
                // Look up the value of the i'th key.                            
                Value =
                     LookUpValueByKey( 
                        P, 
                             // Address of the look-up table holding the
                             // (name,value) pair.
                             //
                        Keys.Lo + (i * KeySize ), 
                             // The key field to be inserted, any binary
                             // bytes can serve as a key.  This field is 
                             // copied into the look-up table so it need 
                             // not be preserved separately.
                             //
                        KeySize );
                             // Size of the key in bytes.
                
                // If the value was not found.
                if( Value != i )
                {
                    return(4);
                }
            }
            
            // Deallocate the Patricia tree.
            DeletePatricia( P );    
            
            // Free the key buffer.
            FreeBuf( &Keys );
        }
        
        // If the number of bytes in use in the memory
        // pool is not the same as before.
        if( TheTotalBytesInUseHM != Before )
        {
            return(5);
        }
    }
}

/*------------------------------------------------------------
| Test_InsertKeyValue2
|-------------------------------------------------------------
|
| PURPOSE: To test the InsertKeyValue() function using
|          pseudo-random sequences of keys of various sizes.
|
| DESCRIPTION: 
| 
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 06.18.01 Ran 37 million key insertion test and
|                   passed OK.
------------------------------------------------------------*/
u32 
Test_InsertKeyValue2()
{
    u32         KeySize;
    u32         i, Value;
    PatTree*    P;
    PatNode*    N;
    u32         IsKeysOwned;
    Buf         Keys;
    u32         Before;
    u32         KeyBufSize;
    u32         MinBytesPerKey;
    u32         MaxBytesPerKey;
    u32         Trials;
    u32         KeyOffset;
    u8*         Key;
    u32         KeysInserted;
    u32         KeysFound;
    u32         status;
    u32         j;
    u32         KeyInsertionPasses;
    
    // Specify the range of key sizes to be tested.
    MinBytesPerKey = 1;
    MaxBytesPerKey = 32;
    
    // Don't duplicate keys for this test.
    IsKeysOwned    = 0;
    
    // Set the number of key insertion passes to 10,000.
    KeyInsertionPasses = 10000;
    
    // Specify the size of the buffer to hold the source
    // of random key values, in bytes.
    KeyBufSize = 64 * 1024;
            
    // Allocate a 64K buffer to hold the key values.
    AllocateBuf( &Keys, KeyBufSize );

    // Note how much memory is being used before
    // allocating the Patricia tree.
    Before = TheTotalBytesInUseHM;

    // Specify how many trials should be made.
    Trials = 10; 
    
    // For 10 sets of 10000 random keys.
    for( j = 0; j < Trials; j++ )
    {
        // Report the beginning of the trial.
        printt( "Trial %d\n", j );
        
        // Make a new Patricia tree.
        P = MakePatricia(
                MinBytesPerKey,  
                    // The minimum size of each key in bytes.
                    //
                MaxBytesPerKey,  
                    // The maximum size of each key in bytes.
                    //
                IsKeysOwned );
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

        // Start counters with no keys inserted or found.
        KeysInserted = 0;
        KeysFound    = 0;
        
        // Initialize the random number generator.
        SetUpRandomNumberGenerator( RandomSeedForTest + j );
        
        // Fill the key buffer with random bytes.       
        RandomBytes( Keys.Lo, KeyBufSize );
        
        // Insert up to 10,000 randomly selected keys into the 
        // tree.
        //
        // If a key is found in the tree before inserting it
        // then the value remains as it was originally set.
        //
        // For each trial.
        for( i = 0; i < KeyInsertionPasses; i++ )
        {
            // Every 1000 insertions.
            if( (i % 1000) == 0 )
            {
                // Report the beginning of the trial.
                printt( "    Insertion %d\n", i );
            }
        
            // Pick a random key size.
            KeySize = 
                 RandomIntegerFromRange( 
                    MinBytesPerKey, 
                    MaxBytesPerKey );

            // Pick a random key offset in the key buffer.
            KeyOffset = 
                RandomIntegerFromRange( 
                    0, 
                    KeyBufSize - ( KeySize + 1 ) );
            
            // Refer to the key.
            Key = Keys.Lo + KeyOffset;
        
            // Regarding the trial number as the value of the
            // key, look up the value currently associated
            // with the selected key.
            Value =
                LookUpValueByKey( 
                    P, 
                         // Address of the look-up table holding the
                         // (name,value) pair.
                         //
                    Key, 
                         // The key field to be inserted, any binary
                         // bytes can serve as a key.  This field is 
                         // copied into the look-up table so it need 
                         // not be preserved separately.
                         //
                    KeySize );
                         // Size of the key in bytes.

            // If no value is associated with the key.
            if( Value == NO_KEY_VALUE )
            {
                // Insert the key with the trial number as the value.
                N = InsertKeyValue( 
                        P, 
                         // Address of the look-up table into which 
                         // the (key,value) pair is to be inserted.
                         //
                        Key, 
                         // The key field to be inserted, any binary
                         // bytes can serve as a key.  This field is 
                         // copied into the look-up table so it need 
                         // not be preserved separately.
                         //
                        KeySize,
                         // Size of the key in bytes.
                         //
                        i );
                         // The 32-bit value to be associated with 
                         // the key.

                // Test the validity of the tree after making the
                // insertion.
                status = ValidatePatriciaTree( P );
                
                // If the tree is invalid then status will be non-zero.
                if( status )
                {
                    // Return the failure code.
                    return( status * 1000 );
                }
                         
                // Account for the new key inserted.
                KeysInserted += 1;
            }
        }
        
        // Initialize the random number generator.
        SetUpRandomNumberGenerator( RandomSeedForTest + j );
        
        // Fill the key buffer with random bytes.       
        RandomBytes( Keys.Lo, KeyBufSize );

        // Look for keys in the table using the same sequence
        // of keys inserted above.  Every key should be found
        // and the values associated with the key should be
        // equal to or less than the current trial number.
        //
        // For each trial.
        for( i = 0; i < KeyInsertionPasses; i++ )
        {
            // Pick a random key size.
            KeySize = 
                 RandomIntegerFromRange( 
                    MinBytesPerKey, 
                    MaxBytesPerKey );

            // Pick a random key offset in the key buffer.
            KeyOffset = 
                RandomIntegerFromRange( 
                    0, 
                    KeyBufSize - ( KeySize + 1 ) );
            
            // Refer to the key.
            Key = Keys.Lo + KeyOffset;
        
            // Regarding the trial number as the value of the
            // key, look up the value currently associated
            // with the selected key.
            Value =
                LookUpValueByKey( 
                    P, 
                         // Address of the look-up table holding the
                         // (name,value) pair.
                         //
                    Key, 
                         // The key field to be inserted, any binary
                         // bytes can serve as a key.  This field is 
                         // copied into the look-up table so it need 
                         // not be preserved separately.
                         //
                    KeySize );
                         // Size of the key in bytes.

            // If no value is associated with the key.
            if( Value == NO_KEY_VALUE )
            {
                return(2);
            }
            
            // If the value exceeds the insertion pass number.
            if( Value > i )
            {
                return(3);
            }
            
            // If the value equals the trial number.
            if( Value == i )
            {
                // Then account for the key found.
                KeysFound += 1;
            }
        }

        // If the keys inserted doesn't equal the number
        // of keys found.
        if( KeysInserted != KeysFound )
        {
            return(4);
        } 
        
        // Deallocate the Patricia tree.
        DeletePatricia( P ); 
        
        // If the number of bytes in use in the memory
        // pool is not the same as before.
        if( TheTotalBytesInUseHM != Before )
        {
            return(5);
        }
    }
    
    // Free the key buffer.
    FreeBuf( &Keys );

    return(0);
}   

/*------------------------------------------------------------
| Test_MakePatricia
|-------------------------------------------------------------
|
| PURPOSE: To test the MakePatricia() function.
|
| DESCRIPTION: 
| 
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 06.17.01
------------------------------------------------------------*/
u32 
Test_MakePatricia()
{
    u32         KeySize;
    PatTree*    P;
    u32         IsKeysOwned;
    
    // For keys not owned and not owned.
    for( IsKeysOwned = 0; IsKeysOwned <= 1; IsKeysOwned++ )
    {
        // For key sizes ranging from 1 to 32 bytes.
        for( KeySize = 1; KeySize <= 32; KeySize++ )
        {
            // Make a new Patricia tree.
            P = MakePatricia(
                    1,  
                        // The minimum size of each key in 
                        // bytes.
                        //
                    KeySize,  
                        // The maximum size of each key in 
                        // bytes.
                        //
                    IsKeysOwned );
                        // Configuration flag set to 1 if the 
                        // key data should be copied into the 
                        // tree or 0 if the key data is 
                        // external to the tree, being fixed 
                        // over the life of the tree.
                        //
                        // Owned key storage is dynamically 
                        // allocated and freed by the Patricia 
                        // tree functions.
                        //
                        // Owned keys are non-overlapping in 
                        // storage but external keys may 
                        // overlap.
                        
            // If the smallest key size is larger than the 
            // largest.
            if( P->MinBytesPerKey > P->MaxBytesPerKey )
            {
                return(1);
            }
            
            // If the number of subtrees is not the same
            // as the number of different key sizes.
            if( P->SubTreeCount != KeySize )
            {
                return(2);
            }
            
            // If the array of subtree roots has not been
            // allocated.
            if( P->Roots == 0 )
            {
                return(3);
            }
            
            // If a node storage pool has not been allocated.
            if( P->NodeStorage == 0 )
            {
                return(4);
            }
            
            // If the in-use node count is not zero.
            if( P->InUseNodeCount != 0 )
            {
                return(5);
            }
            
            // If the free node count is not zero.
            if( P->FreeNodeCount != 0 )
            {
                return(6);
            }
            
            // If the free node list is not empty. 
            if( P->FreeNodeList != 0 )
            {
                return(7);
            }
            
            // If the key ownership status isn't as specified.
            if( P->IsKeysOwned != IsKeysOwned )
            {
                return(8);
            }
            
            // If the minimum number of bytes per key isn't 1.
            if( P->MinBytesPerKey != 1 )
            {
                return(9);
            }
            
            // If the maximum number of bytes per key isn't 
            // KeySize.
            if( P->MaxBytesPerKey != KeySize )
            {
                return(10);
            }
            
            // If the smallest existing key in the tree is
            // anything other than zero.
            if( P->MinKeySize )
            {
                return(11);
            }
            
            // If the largest existing key in the tree is
            // anything other than zero.
            if( P->MaxKeySize )
            {
                return(12);
            }
            
            // If keys are owned by the tree
            if( IsKeysOwned )
            {
                // If the key storage is not allocated.
                if( P->KeyStorage == 0 )
                {
                    return(13);
                }
                
                // If the free key count is not zero.
                if( P->FreeKeyCount )
                {
                    return(15);
                }
                
                // If the free key list heads are not allocated.
                if( P->FreeKeyList == 0 )
                {
                    return(16);
                }
            }
            
            // Deallocate the Patricia tree.
            DeletePatricia( P );  
        }
    } 
    
    return(0); 
}

/*------------------------------------------------------------
| TestPatriciaTree2
|-------------------------------------------------------------
|
| PURPOSE: To validate the 'FindLongestMatchPatricia'
|          function.
|
| DESCRIPTION: This known inserts keys into a Patricia tree 
| and then searches for the longest matches among the keys.
| 
| EXAMPLE:     
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 02.24.99 From 'TestPatriciaTree'.
------------------------------------------------------------*/
void
TestPatriciaTree2()
{
    u32         MinBytesPerKey;
    u32         MaxBytesPerKey;
    u32         i, j;
    PatTree*    P;
    PatNode*    N[21];
    PatNode*    F;
    u32         S;
    u8*         Y[21];
    u8*         Z[21];
    u32         IsKeysOwned;

    // Test this routine without copying keys into the tree.
    IsKeysOwned = 0;
        
    // Define the keys to be inserted into the tree.
    Y[0]  = (u8*) "A";
    Y[1]  = (u8*) "B";
    Y[2]  = (u8*) "C";
    Y[3]  = (u8*) "D";
    Y[4]  = (u8*) "E";
    Y[5]  = (u8*) "AB";
    Y[6]  = (u8*) "BC";
    Y[7]  = (u8*) "CD";
    Y[8]  = (u8*) "DE";
    Y[9]  = (u8*) "ABC";
    Y[10] = (u8*) "BCD";
    Y[11] = (u8*) "CDE";
    Y[12] = (u8*) "ABCD";
    Y[13] = (u8*) "BCDA";
    Y[14] = (u8*) "CDAB";
    Y[15] = (u8*) "DABC";
    Y[16] = (u8*) "ABCDE";
    Y[17] = (u8*) "BCDEA";
    Y[18] = (u8*) "CDEAB";
    Y[19] = (u8*) "DEABC";
    Y[20] = (u8*) "EABCD";
    
    // Set up the search strings.
    Z[0]  = (u8*) "AX";  
    Z[1]  = (u8*) "BX"; 
    Z[2]  = (u8*) "CX";
    Z[3]  = (u8*) "DX";
    Z[4]  = (u8*) "EX";
    Z[5]  = (u8*) "ABX";
    Z[6]  = (u8*) "BCX";
    Z[7]  = (u8*) "CDX";
    Z[8]  = (u8*) "DEX";
    Z[9]  = (u8*) "ABCX";
    Z[10] = (u8*) "BCDX";
    Z[11] = (u8*) "CDEX";
    Z[12] = (u8*) "ABCDX";
    Z[13] = (u8*) "BCDAX";
    Z[14] = (u8*) "CDABX";
    Z[15] = (u8*) "DABCX";
    Z[16] = (u8*) "ABCDEX";
    Z[17] = (u8*) "BCDEAX";
    Z[18] = (u8*) "CDEABX";
    Z[19] = (u8*) "DEABCX";
    Z[20] = (u8*) "XXXXXX";
    
    // Specify the range of key sizes to be tested.
    MinBytesPerKey = 1;
    MaxBytesPerKey = 6;
    
    // Make a new Patricia tree.
    P = MakePatricia(
            MinBytesPerKey,  
                // The minimum size of each key in bytes.
                //
            MaxBytesPerKey,
                // The maximum size of each key in bytes.
                //
            IsKeysOwned );
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

    // For all the keys.
    for( i = 0; i < 21; i++ )
    {
        // Insert key into the tree.
        N[i] = 
            InsertPatricia( 
                P, 
                Y[i],  
                CountString( (s8*) Y[i] ),  
                i );  
    }
    
    // Tell the user what's going to happen.
    printt( "Testing Longest Match:\n\n" );
    
    // For every search key.
    for( i = 0; i < 21; i++ )
    {
        // Search for the longest matching key in the tree.
        F = FindLongestMatchPatricia( 
                P, 
                Z[i], 
                CountString( (s8*) Z[i] ), 
                &S ); 
                 
        // If a match was found.
        if( F )
        {
            // If the node found isn't the right one.
            if( F != N[i] )
            {
                Debugger();
            }
            
            // Print the search key.
            printt( "Key [%s] LongestMatch[", (s8*) Z[i] );
            
            // Output the matching characters.
            for( j = 0; j < S; j++ )
            {
                printt( "%c", (s8) F->Key[j] );
            }
            
            // Print the end of the line.
            printt( "]\n" );
        }
        else // No match.
        {
            // If there is a matching node.
            if( i != 20 )
            {
                Debugger();
            }
            
            // Print the search key.
            printt( "Key [%s] NO MATCH\n", (s8*) Z[i] );
        }
    }
    
    // Deallocate the Patricia tree.
    DeletePatricia( P );    
}

/*------------------------------------------------------------
| PatriciaTreeTest_main
|-------------------------------------------------------------
|
| PURPOSE: To test Patricia Tree functions.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Room exists for the log file on disk.
|
| HISTORY: 06.15.01
------------------------------------------------------------*/
#ifdef FOR_MAIN
u32
main()
#else
u32
PatriciaTreeTest_main()
#endif
{
    u32 OverallResult;
    u32 i;
    
    // Open the test log file.
    //
    // Don't print to file, just to display for very long
    // test run.
    TheLogFile = 0; //fopen( "testlog.txt", "w" );
    
    // Report the beginning of all the API tests.
    printt( "===============\n" );
    printt( "BEGIN ALL TESTS\n" );
    printt( "===============\n" );
    
    // Start with the overall result code set to zero.
    OverallResult = 0;
 
    // Run this sequence over and over with different
    // random seeds -- this will run for a very long time,
    // probably until this test is stopped.
    for( i = 0; i < 1000000; i++ )
    {
        // Run a test sequence and accumulate the result.
        OverallResult |= 
            RunTestSequence( 
                PatriciaTreeTestSequence,
                "PatriciaTreeTestSequence" );
        
        // Try a different random number seed.  
        RandomSeedForTest++;
    }
    
// Put other test sequences here.
//          
//    OverallResult |= 
//      RunTestSequence( 
//          "AnotherTestSequence", 
//          AnotherTestSequence );

    printt( "=======================================\n" );
    printt( "END ALL TESTS\n" );
    printt( "=======================================\n" );
    
    // If any of the test sequences resulted in an error.
    if( OverallResult )
    {
        printt( "SUMMARY: At least one test failed.\n" );
    }
    else
    {
        printt( "SUMMARY: All tests passed OK.\n" );
    }
    
    printt( "=======================================\n" );
    
//    fclose( TheLogFile );
    
    // Return the overall result.
    return( OverallResult );
}

/*------------------------------------------------------------
| ValidatePatriciaTree
|-------------------------------------------------------------
|
| PURPOSE: To validate the integrity of a Patricia tree.
|
| DESCRIPTION: This routine is a data unit test routine for
| a Patricia tree.
|
| Tests the following conditions:
|
| 1. MinBytesPerKey <= MaxBytesPerKey.
|
| 2. MinBytesPerKey != 0.
|
| 3. MaxBytesPerKey != 0.
|
| 4. Every branch out of a node must refer to another node.
|
| 5. The Offset fields of every node must not exceed the key 
|    size for that node.
|
| 6. The bit index of all subordinates of the root node 
|    must be less than the index of the root node.
|
| 7. The count of nodes found while traversing the tree
|    matches InUseNodeCount.
|
| 8. The count of free nodes found on the FreeNodeList matches
|    the value of FreeNodeCount.
|
| 9. The count of free keys found on the FreeKeyList's matches
|    the value of FreeKeyCount.
|
| Returns a status code: 0 OK, any other number is error 
| identified with the bad section number.
|
| HISTORY: 02.23.99 TL
|          02.07.01 TL Revised to return a status code.
|          06.14.01 Made stack allocation static and added
|                   tests 7 through 9.
|          06.15.01 Added test 10.
------------------------------------------------------------*/
u32
ValidatePatriciaTree( PatTree*  P )
{
    PatNode*    N;
    PatNode*    Q;
    PatNode*    R;
    PatNode*    Z;
    u32         i;
    u32         IndexR, IndexQ, IndexZ, IndexN;
    u32         StackBuffer[100];
    Stack       S;
    u32         MeasuredFreeNodeCount;
    u32         MeasuredFreeKeyCount;
    u32         MeasuredInUseNodeCount;
    u32*        AtFreeItem;
    u32         SubTreeIndex;
    u8          Mask;
    
    
    // Initialize the testing counters to zero.
    MeasuredFreeNodeCount  = 0;
    MeasuredFreeKeyCount   = 0;
    MeasuredInUseNodeCount = 0;
     
    // Make a stack for traversing the tree.
    MakeStaticStack( &S, (u32*) &StackBuffer, 100 );
        
    // If the smallest key size is larger than the largest.
    if( P->MinBytesPerKey > P->MaxBytesPerKey )
    {
        return(1);
    }
    
    // If the minimum key size is zero.
    if( P->MinBytesPerKey == 0 )
    {
        return(2);
    }
    
    // If the maximum key size is zero.
    if( P->MaxBytesPerKey == 0 )
    {
        return(3);
    }
    
    // For every subtree, one for each key size.
    for( i = P->MinBytesPerKey;
         i <= P->MaxBytesPerKey;
         i++ )
    {
        // Calculate the index of the subtree in the family 
        // of trees of this Patricia tree.
        SubTreeIndex = i - P->MinBytesPerKey;

        // Refer to the root node for this key size.
        R = P->Roots[ SubTreeIndex ];
        
        // If there is a root.
        if( R )
        {
            // Calculate the root bit index.
            IndexR = ToBitIndex( R->Offset, R->Mask );
            
            // Push the root onto the stack.
            Push( &S, (u32) R );
            
            // As long as there is a value on the stack.
            while( S.StackIndex )
            {
                // Pop the top item off as the current
                // node, 'Q'.
                Q = (PatNode*) Pull( &S );
                
                // If the node address is invalid.
                if( Q == 0 )
                {
                    return(4);
                }
                
                // If the node is not the root and it
                // has a zero superior link.
                if( Q->Super == 0 && Q != R )
                {
                    return(5);
                }
                
                // If the test bit offset is beyond the
                // end of the current key.
                if( (u32) (Q->Offset + 1) > i )
                {
                    return(6);
                }
                
                // Get the Mask field.
                Mask = Q->Mask;
                
                // If the Mask field is zero.
                if( Mask == 0 )
                {
                    return(7);
                }
                
                // If the Mask field doesn't have a single bit set.
                if( Mask != 1  && Mask != 2  &&
                    Mask != 4  && Mask != 8  &&
                    Mask != 16 && Mask != 32 && 
                    Mask != 64 && Mask != 128 )
                {
                    return(8);
                }
                                
                // Count the node as being in the tree.
                MeasuredInUseNodeCount += 1;
                
                // Calculate the current bit index.
                IndexQ = ToBitIndex( Q->Offset, Q->Mask );
                
                // Refer to the zero node as 'Z'.
                Z = Q->Zero;
                
                // Refer to the one node as 'N'.
                N = Q->One;
                
                //        Q
                //     0 / \ 1
                //      Z   N
            
                // If either branch refers to an invalid node address
                if( Z == 0 || N == 0 )
                {
                    return(8);
                }
                
                // Calculate the zero bit index.
                IndexZ = ToBitIndex( Z->Offset, Z->Mask );
                
                // Calculate the one bit index.
                IndexN = ToBitIndex( N->Offset, N->Mask );
            
                // If Z isn't the root node and it's
                // index is less than the root node.
                if( Z != R && IndexZ < IndexR )
                {
                    return(9);
                }
            
                // If N isn't the root node and it's
                // index is less than the root node.
                if( N != R && IndexN < IndexR )
                {
                    return(10);
                }
                
                // If Z and N are both subordinates of Q and they
                // are the same node.
                if( ( Z->Super == Q ) && ( N->Super == Q ) && Z == N )
                {
                    return(11);
                }
                
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
                    Push( &S, (u32) N );
                }
            }
        }
        
        // If key memory is owned by this tree.
        if( P->IsKeysOwned )
        {
            // Count up the number of keys in the free list
            // for this subtree.
            AtFreeItem = P->FreeKeyList[SubTreeIndex];
            while( AtFreeItem )
            {
                MeasuredFreeKeyCount += 1;
                AtFreeItem = (u32*) *AtFreeItem;
            }
        }
    }
    
    // If the measured in-use node count doesn't match
    // the tally maintained in the PatTree record.
    if( MeasuredInUseNodeCount != P->InUseNodeCount )
    {
        return(12);
    }
    
    // Count up the number of free nodes on the list.
    AtFreeItem = P->FreeNodeList;
    while( AtFreeItem )
    {
        MeasuredFreeNodeCount += 1;
        AtFreeItem = (u32*) *AtFreeItem;
    }
    
    // If the measured free node count doesn't match
    // the tally maintained in the PatTree record.
    if( MeasuredFreeNodeCount != P->FreeNodeCount )
    {
        return(13);
    }
    
    // If key memory is owned by this tree.
    if( P->IsKeysOwned )
    {
        // If the measured free key count doesn't match
        // the free key count.
        if( MeasuredFreeKeyCount != P->FreeKeyCount )
        {
            return(14);
        }
    }
    
    // Return zero to signal that tree is valid.
    return( 0 );
}       


