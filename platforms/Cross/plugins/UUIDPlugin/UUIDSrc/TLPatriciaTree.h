/*------------------------------------------------------------
| TLPatriciaTree.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface Patricia tree functions.
|
| DESCRIPTION: 
|
| HISTORY: 02.22.99 TL
------------------------------------------------------------*/

#ifndef TLPATRICIATREE_H
#define TLPATRICIATREE_H

#ifdef __cplusplus
extern "C"
{
#endif

#define FIRST_BIT_IN_BYTE (1)
            // The bit mask that is used to test the first
            // bit in a byte for key value testing.
            
#define LAST_BIT_IN_BYTE (128)
            // The bit mask that is used to test the last
            // bit in a byte for key value testing.
            
#define NO_KEY_VALUE (0xFBADF00D)
        // Value used to signal the failure to find the key
        // of a (key,value) pair.
        
#define PATNOTES_PER_ALLOCATION_BLOCK (10)
            // Number of PatNode records to allocate in each
            // allocation block.

#define KEYS_PER_ALLOCATION_BLOCK (10)
            // Number of key records to allocate in each
            // allocation block.
            
/*------------------------------------------------------------
| ToBitIndex 
|-------------------------------------------------------------
|
| PURPOSE: To combine a byte offset and bit mask into a single
|          32-bit value.
|
| DESCRIPTION: The byte offset is shifted over 8 bits and then
| logically ORed with the bit-in-byte mask, like this:
|
| BEFORE:
|                      bbbbbbbb bbbbbbbb bbbbbbbb
|   Offset = |........:........:........:........|
|
|                                        mmmmmmmm
|   Mask   = |........:........:........:........|
|
| AFTER:
|             bbbbbbbb bbbbbbbb bbbbbbbb mmmmmmmm
|   Index  = |........:........:........:........|
|
| Bit index values produced by this function can be compared
| as being higher or lower than one another but they can't
| be directly added and subtracted to find the number of bits 
| between bits.
|
| EXAMPLE: 
|               i = ToBitIndex( ByteOffset, Mask );
|
| ASSUMES: ByteOffset fits in a 24-bit field.
|
|           Mask has a single 1 bit set in the lower 8-bits
|           of its field.
|
|           The least-significant mask bit is 00000001 and the
|           most-significant mask bit is 10000000, and the 
|           most-significant-bit is regarded as being higher
|           in memory than the least-significant-bit.
|
| HISTORY: 06.16.01 TL From InsertNameValue.
------------------------------------------------------------*/
#define ToBitIndex( ByteOffset, Mask ) \
            ( ( ( (u32) ByteOffset ) << 8 ) | (u32) Mask )

/*------------------------------------------------------------
| IsTerminalNode
|-------------------------------------------------------------
|
| PURPOSE: To test if a node is a terminal node with respect
|          to another, superior node.
|
| DESCRIPTION: Each node has two subordinate links which
| correspond to the branches taken as the result of testing a
| bit in the key, as diagrammed here for nodes Q, Z and N:
|
|                             Q <--- a superior of Z and N.
|                            / \  
|                 0 branch  /   \  1 branch
|                          /     \  
|  a subordinate of Q---> Z       N <--- a subordinate of Q
|
|
| A terminal node is one that loops upward, either back
| to the same node or a higher one in the tree.
|
|                       T is a terminal node
|                      / \      from Q
|                     Q   |
|                    / \_/ an
|                   /     upward 
|                         branch
|
| To tell whether a branch is toward a terminal node it is
| necessary to examine the key-bit-offset associated with
| each node and compare them.
|
| Each node is associated with a bit in the key at a certain
| offset from the beginning of the key, as shown below:
|
|     1st bit 
|     in a key
|        |
|        v
|       |00000000000001000000000000| <-- bits in a key
|       |------------>|            |
|                key-bit-offset
|                  associated 
|                 with a node.
|
| Key-bit-offsets are assigned from the top of the tree
| downward such that the root of the tree is associated
| with the first bit in the key.
|
| TERMINAL NODE RULE: If the key-bit-offset of a 
| subordinate link is the SAME or LOWER than that of the 
| superior link, then the subordinate is regarded as a 
| terminal node.
|
| This macro returns 1 if the subordinate node is a terminal
| or 0 if not.
|
| Parameters to this macro may be either bit offset or bit 
| index values formed using ToBitIndex(), the result is valid 
| in both cases.
|
| EXAMPLE: 
|               i = IsTerminalNode( Superior, Sub );
|
| ASSUMES: Key-bit-offset values are assigned from the root
| downward in the order from first-to-last bit in the key.
|
| HISTORY: 06.17.01 TL From InsertNameValue.
------------------------------------------------------------*/
#define IsTerminalNode( Superior, Subordinate ) \
            ( Subordinate <= Superior )

typedef struct PatNode  PatNode;
typedef struct PatTree  PatTree;

/*------------------------------------------------------------
| PatNode
|-------------------------------------------------------------
|
| PURPOSE: To organize data held in a single node of a 
|          Patricia tree.
|
| DESCRIPTION: PatNodes are nodes in a binary tree.  
|
| The relationship between a node and its superior and 
| subordinate nodes is shown here in a diagram.
|
|                        Super
|                          |
|                      this node
|                      /       \
|                    Zero       One
| NOTE: 
|
| ASSUMES: All keys in a subtree have the same size.
|
| HISTORY: 02.22.99 TL
|          06.14.01 Added Super field.
------------------------------------------------------------*/
struct PatNode
{
                    ////////////////////////////////////////// 
                    //                                      //
                    //              L I N K S               //
    PatNode*    Super;
                    // The superior node to this one in the
                    // hierarchy or zero if this is the root.
                    //
                    // This is used to make node extraction
                    // easier.
                    //
    PatNode*    Zero;       
                    // The node to travel to next if the bit 
                    // at BitIndex is zero.
                    //
    PatNode*    One;//       
                    // The node to travel to next if the bit 
                    // at BitIndex is one.
                    //
                    ////////////////////////////////////////// 
                    //                                      //
                    //       K E Y   A N D   V A L U E      //
    u8*         Key;//       
                    // Address of the key associated with 
                    // this node.
                    //
                    // NOTE: Dynamically allocated keys are
                    // allocated to be at least 4 bytes long
                    // so that they can be held in free lists
                    // after deallocation -- the first 4
                    // bytes of a key are used as a forward
                    // link to the next free key record.
                    //
    u32         Value;       
                    // Any value associated with the key, in 
                    // a (key,value) pair this is the 'value'.
                    //
                    // If this field holds the bit pattern 
                    // defined by the NO_KEY_VALUE then there 
                    // is no value associated with the key.
                    //                                      //
                    ////////////////////////////////////////// 
                    //                                      //
                    //          B I T   T E S T E D         //
    u32         Offset;     
                    // The byte offset of the key-test-bit
                    // associated with this node. 
                    //
    u8          Mask;       
                    // The byte mask of the key-test-bit.
                    //
                    // This mask has a single 1 bit and all
                    // others set to zero.
                    //
                    // This mask and Offset combine to 
                    // identify the test bit associated
                    // with this node.
                    //
                    ////////////////////////////////////////// 
};

/*------------------------------------------------------------
| PatTree
|-------------------------------------------------------------
|
| PURPOSE: To organize data held in a Patricia tree.
|
| DESCRIPTION:  
|
| NOTE: 
|
| ASSUMES: Every node is a (key,value) pair.
|
| HISTORY: 02.22.99 TL
|          02.07.01 TL Changed data type for NodeStorage from 
|                      Table to Mass to reduce complexity.
|          06.14.01 Added support for deleting keys.
------------------------------------------------------------*/
struct PatTree
{
    //////////////////////////////////////////////////////////
    //                                                      //
    //                    S U B T R E E S                   //
    //                                                      //
    u32         SubTreeCount;
                    // Number of subtrees required to range
                    // from the minimum to the maximum key
                    // size.
                    //
    PatNode**   Roots;      
                    // Array of 'PatNode' addresses that are 
                    // the roots of the family of Patricia 
                    // trees organized by this record: there 
                    // is one subtree for each key size.
                    //
                    // Record 0 refers to the root of the 
                    // tree that has a key size equal to 
                    // 'MinBytesPerKey'; Record 1 refers to 
                    // the root of the tree that has a key 
                    // size equal to 'MinBytesPerKey'+1, 
                    // and so on.
                    //
    //////////////////////////////////////////////////////////
    //                                                      //
    //                      N O D E S                       //
    //                                                      //
    Mass*       NodeStorage;      
                    // General allocation space that holds the
                    // node records of all trees in this family 
                    // of trees.  
                    //
    u32         InUseNodeCount;
                    // The total number of nodes currently being
                    // used on all subtrees in this Patricia
                    // tree, including nodes that serve simply
                    // as physical subtree roots, having no
                    // keys or values associated with them.
                    //
    u32         FreeNodeCount;
                    // The number of nodes held in the free
                    // list.
                    //
    u32*        FreeNodeList;
                    // List of free PatNode records, linked 
                    // via the first four bytes of each record, 
                    // and terminated by a zero.
                    //
    //////////////////////////////////////////////////////////
    //                                                      //
    //                      K E Y S                         //
    //                                                      //
    u32         IsKeysOwned;
                    // Configuration flag set to 1 if the key 
                    // data should be copied into the tree or
                    // 0 if the key data is external to the
                    // tree, being fixed over the life of the
                    // tree.
                    //
    u32         MinBytesPerKey; 
                    // The minimum size of each key in bytes.
                    //
                    // If keys are owned by the tree then the
                    // minimum key field storage size is 4 
                    // bytes even if the nominal size of the
                    // key is less than that.
                    //
    u32         MaxBytesPerKey; 
                    // The maximum size of each key in bytes.
                    //
    u32         MinKeySize; 
                    // How many bytes long the shortest existing 
                    // key is in the tree.
                    //
    u32         MaxKeySize; 
                    // How many bytes long the longest existing 
                    // key is in the tree.
                    //
    Mass**      KeyStorage;       
                    // Array of memory pools for key data, 
                    // for use if keys are copied into the 
                    // tree.
                    //
                    // The memory allocation block sizes are
                    // chosen to be an integral number of
                    // key records to minimize fragmentation.
                    //
    u32         FreeKeyCount;
                    // The number of nodes held in the free
                    // list.
                    //
    u32**       FreeKeyList;       
                    // Array of lists of free key records, 
                    // linked via the first four bytes of
                    // each record, and terminated by a
                    // zero.
                    //
                    // This is only used for keys owned by
                    // the tree.
};

extern Lot* ThePatriciaTreePool;
                // The allocation pool from which all data
                // in Patricia tree functions is allocated.

u8*         AllocateKeyStorage( PatTree*, u8*, u32 );
void        ConvertBitsToString2( u8*, s8*, u32 );
void        DeleteKey( PatTree*, u8*, u32 );
void        DeleteKeyValue( PatTree*, u8*, u32 );
void        DeletePatricia( PatTree* );
void        EmptyPatricia( PatTree* );
void        ExtractPatNode( PatTree*, PatNode*, u32 );
void        FindFirstDifferentBit( u8*, u8*, u32*, u8* );
PatNode*    FindKeyPatricia( PatTree*, u8*, u32 );   
PatNode*    FindHighestOrderTerminalNode( PatNode* );
PatNode*    FindLongestMatchPatricia( PatTree*, u8*, u32, u32* );   
PatNode*    FindMatchPatricia( PatTree*, u8*, u32, u32* );   
void        FreeKeyStorage( PatTree*, u8*, u32 );
void        FreePatNode( PatTree*, PatNode* );
void        FreeSubtree( PatTree*, PatNode* );
PatNode*    InsertKeyValue( PatTree*, u8*, u32, u32 );
PatNode*    InsertNameValue( PatTree*, s8*, u32 );
PatNode*    InsertPatricia( PatTree*, u8*, u32, u32 ); 
void        InsertSubtree( PatTree*, PatNode*, u32 );
u32         IsLeafNode( PatNode* );
u32         IsPhysicalRoot( PatNode* );
u32         LookUpValue( PatTree*, s8* );
u32         LookUpValueByKey( PatTree*, u8*, u32 );
PatNode*    MakePatNode( PatTree*, u32, u8, u8*, u32 );
PatTree*    MakePatricia( u32, u32, u32 );
void        ReinsertSubtree( PatTree*, PatNode*, u32 );
PatNode*    SearchPatricia( PatTree*, u8*, u32 );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // TLPATRICIATREE_H
