/*------------------------------------------------------------
| TLHuffman.c
|-------------------------------------------------------------
|
| PURPOSE: To provide data compression functions using the
|          Huffman method.
|
| HISTORY: 07.03.96 from the disk in the book "The Data
|                   Compression Book, 2nd Ed." by Nelson & 
|                   Gailly.
------------------------------------------------------------*/
 
#include "TLTarget.h" // Include this first.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "TLTypes.h"
#include "TLBytes.h"
#include "TLBytesExtra.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLBitIO.h"
#include "TLList.h"
#include "TLFile.h"

#include "TLHuffman.h"

// These working buffers are used by 'CompressBytesToFile',
// 'CompressBytesToBuffer', 'ExpandBytesFromFile' and
// 'ExpandBytesFromBuffer'.
u32  HuffCounts[256];
NODE HuffNodes[514];
CODE HuffCodes[257];
   
/*------------------------------------------------------------
| build_tree
|
| PURPOSE: To convert byte frequencies to a Huffman tree.
|
| DESCRIPTION: Building the Huffman tree is fairly simple.  
| All of the active nodes are scanned in order to locate the 
| two nodes with the minimum weights.  These two weights are 
| added together and assigned to a new node.  The new node 
| makes the two minimum nodes into its 0 child and 1 child.  
| The two minimum nodes are then marked as inactive. This 
| process repeats until there is only one node left, which is 
| the root node.  The tree is done, and the root node is 
| passed back to the calling routine.
|
| Node 513 is used here to arbitrarily provide a node with a 
| guaranteed maximum value.  It starts off being min_1 and 
| min_2.  After all active nodes have been scanned, I can tell 
| if there is only one active node left by checking to see if 
| min_1 is still 513. 
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 07.29.98 TL Revised to use pointers rather than
|                      array indices for speed.
------------------------------------------------------------*/
s16 
build_tree( NODE* nodes )
{
    s16     next_free;
    s16     i;
    s16     min_1;
    s16     min_2;
    u16     Min1NodeCount;
    u16     Min2NodeCount;
    u16     TheNodeCount;
    NODE*   TheNode;
    NODE*   Min1Node;
    NODE*   Min2Node;
    NODE*   Node513;
    NODE*   NextFreeNode;
    
    // Fill in the uncompressed byte codes.
    TheNode = nodes;
    for( i = 0; i < 256; i++ )
    {
        TheNode->UncompressedByte = (u16) i;
        TheNode++;
    }
    
    Node513 = &nodes[ 513 ];
    Node513->count = 0xffff;
    
    for( next_free = END_OF_STREAM + 1 ; ; next_free++ ) 
    {
        NextFreeNode = &nodes[ next_free ];

        min_1 = 513;
        min_2 = 513;
        Min1Node = Node513;
        Min2Node = Node513;
        Min1NodeCount = 0xffff;
        Min2NodeCount = 0xffff;
        
        for( i = 0 ; i < next_free ; i++ )
        {
            TheNode = &nodes[i];
            
            TheNodeCount = TheNode->count;
            
            if( TheNodeCount != 0 ) 
            {
                if( TheNodeCount < Min1NodeCount )
                {
                    min_2 = min_1;
                    Min2Node = Min1Node;
                    Min2NodeCount = Min1NodeCount;

                    min_1 = i;
                    Min1Node = TheNode;
                    Min1NodeCount = TheNodeCount;
                } 
                else 
                {
                    if( TheNodeCount < Min2NodeCount )
                    {
                        min_2 = i;
                        Min2Node = TheNode;
                        Min2NodeCount = TheNodeCount;
                    }
                }
            }
        }
            
        if( min_2 == 513 )
        {
            break;
        }
        
        NextFreeNode->count = (u16) ( Min1NodeCount + Min2NodeCount );
                               
        Min1Node->saved_count = Min1NodeCount;
        
        Min1Node->count = 0;
        
        Min2Node->saved_count = Min2NodeCount;
        
        Min2Node->count = 0;
        
        NextFreeNode->child_0 = min_1;
        NextFreeNode->child_0_node = Min1Node;
        
        NextFreeNode->child_1 = min_2;
        NextFreeNode->child_1_node = Min2Node;
    }
    
    next_free--;
    
    nodes[ next_free ].saved_count = nodes[ next_free ].count;
    
    return( next_free );
}

#ifdef SLOW_WAY
s16 
build_tree(NODE * nodes )
{
    s16 next_free;
    s16 i;
    s16 min_1;
    s16 min_2;

    nodes[ 513 ].count = 0xffff;
    
    for( next_free = END_OF_STREAM + 1 ; ; next_free++ ) 
    {
        min_1 = 513;
        min_2 = 513;
        
        for( i = 0 ; i < next_free ; i++ )
        {
            if( nodes[ i ].count != 0 ) 
            {
                if( nodes[ i ].count < nodes[ min_1 ].count ) 
                {
                    min_2 = min_1;
                    min_1 = i;
                } 
                else 
                {
                    if( nodes[ i ].count < nodes[ min_2 ].count )
                    {
                        min_2 = i;
                    }
                }
            }
        }
            
        if( min_2 == 513 )
        {
            break;
        }
        
        nodes[ next_free ].count = 
            nodes[ min_1 ].count + nodes[ min_2 ].count;
                               
        nodes[ min_1 ].saved_count = nodes[ min_1 ].count;
        
        nodes[ min_1 ].count = 0;
        
        nodes[ min_2 ].saved_count =  nodes[ min_2 ].count;
        
        nodes[ min_2 ].count = 0;
        
        nodes[ next_free ].child_0 = min_1;
        nodes[ next_free ].child_0_node = &nodes[min_1];
        
        nodes[ next_free ].child_1 = min_2;
        nodes[ next_free ].child_1_node = &nodes[min_2];
    }
    
    next_free--;
    
    nodes[ next_free ].saved_count = nodes[ next_free ].count;
    
    return( next_free );
}
#endif

/*------------------------------------------------------------
| compress_data
|
| PURPOSE:  
|
| DESCRIPTION: Once the tree gets built, and the CODE table 
| is built, compressing the data is a breeze. 
| 
| Each byte is read in, and its corresponding Huffman code 
| is sent out.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
compress_data( FILE *input, BIT_FILE *output, CODE *codes )
{
    s16 c;

    while ( ( c = (s16) getc( input ) ) != EOF )
    {
        OutputBits( output, 
                    (u32) codes[ c ].code,
                    codes[ c ].code_bits );
    }
                    
    OutputBits( output, 
                (u32) codes[ END_OF_STREAM ].code,
                codes[ END_OF_STREAM ].code_bits );
}

/*------------------------------------------------------------
| CompressBytesToBuffer
|-------------------------------------------------------------
| PURPOSE: To compress a buffer to another buffer.
|
| DESCRIPTION:  
|
| The frequency counts of all the bytes in the input buffer 
| are tabulated.  The counts are all stored in a 32-bit 
| integers, so the next step is scale them down to single 
| byte counts in the NODE array.
|  
| After the counts are scaled, the Huffman decoding tree is 
| built on top of the NODE array.  Another routine walks 
| through the tree to build a table of codes, one per symbol.
| 
| Finally, when the codes are all ready, compressing the data 
| is a simple matter.  
| 
| Returns number of bytes output to the target buffer.  
| The actual stream of bits written to the target buffer 
| begins on a byte boundary and is padded out to a full byte 
| at the end.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: Target buffer is large enough for the compressed
|          result. 
|
| HISTORY: 07.28.98 From 'CompressBytesToFile'.
------------------------------------------------------------*/
u32 
CompressBytesToBuffer( u8* From, u8* To, u32 Count )
{
    u32*    Counts;
    NODE*   nodes;
    CODE*   codes;
    s16     root_node;
    u8      c;
    u32     i;
    u8      mask;
    s16     rack; 
    u32     m;
    u32     code;
    u32     OutputByteCount;
    u8*     TargetAddressOnEntry;
    
    // Save the target buffer address so that 'To' can be
    // used as a memory cursor.
    TargetAddressOnEntry = To;
    
    // Refer to the global working storage using local 
    // variables for speed.
    Counts = HuffCounts;
    nodes  = HuffNodes;
    codes  = HuffCodes;

    // Count how many of each type of byte there are.
    CountBytes( From, Count, Counts );

    // Rescale the counts to fit in a byte.
    scale_counts( Counts, nodes );
    
    // Save the scaled byte counts to the target buffer.
    for( i = 0 ; i < 256 ; i++ ) 
    {
        *To++ = (u8) nodes[ i ].count;
    }
    
    // Build the coding tree based on byte frequency.
    root_node = build_tree( nodes );
    
    // Convert the coding tree to code numbers.
    convert_tree_to_code( nodes, codes, 0, 0, root_node );

    // Initialize the mask and accumulator.
    rack = 0;
    mask = 0x80;
    
    // For each byte in the buffer.
    for( i = 0; i < Count; i++ )
    {
        // Get a byte from the source buffer.
        c = *From++;
        
        // Transfer the code bits cooresponding to the byte.
 
        // From 'OutputBits'.
        m = 1U << ( ((u32) codes[ c ].code_bits) - 1 );
    
        code = codes[ c ].code;
        
        while( m ) 
        {
            if( m & code )
            {
                rack |= mask;
            }
            
            mask >>= 1;
        
            if( mask == 0 ) 
            {
                // Transfer the byte.
                *To++ = (u8) rack;
                
                // Reset the bit accumulator.
                rack = 0;
                mask = 0x80;
            }
        
            m >>= 1;
        }
    }
       
    // Add the end of stream marker.                

    // From 'OutputBits'.
    m = 1U << ( ((u32) codes[ END_OF_STREAM ].code_bits) - 1 );

    code = codes[ END_OF_STREAM ].code;
    
    while( m ) 
    {
        if( m & code )
        {
            rack |= mask;
        }
        
        mask >>= 1;
    
        if( mask == 0 ) 
        {
            // Transfer the byte.
            *To++ = (u8) rack;
            
            // Reset the bit accumulator.
            rack = 0;
            mask = 0x80;
        }
    
        m >>= 1;
    }
    
    // If a fractional byte remains to be output.
    if( mask != 0x80 )
    {
        // Transfer the byte.
        *To++ = (u8) rack;
    }
    
    // Calculate the number of bytes output.
    OutputByteCount = (u32) ( To - TargetAddressOnEntry );

    // Return the number of output bytes.
    return( OutputByteCount );
}

/*------------------------------------------------------------
| CompressBytesToFile
|
| PURPOSE: To compress a buffer and save it at the current
|          position of a given file.
|
| DESCRIPTION:  
|
| The frequency counts of all the bytes in the input buffer 
| are tabulated.  The counts are all stored in a 32-bit 
| integers, so the next step is scale them down to single 
| byte counts in the NODE array.
|  
| After the counts are scaled, the Huffman decoding tree is 
| built on top of the NODE array.  Another routine walks 
| through the tree to build a table of codes, one per symbol.
| 
| Returns number of bytes written to the file.  The actual
| stream of bits written to the file must begin on a byte 
| boundary and is padded out to a full byte at the end.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 07.06.96 
|          07.28.98 Added return of bytes written.
------------------------------------------------------------*/
u32 
CompressBytesToFile( BIT_FILE* output, u8* Buf, u32 Count )
{
    u32*    Counts;
    NODE*   nodes;
    CODE*   codes;
    s16     root_node;
    u8      c;
    u32     i;
    u8      mask;
    s16     rack; 
    FILE*   file;
    u32     m;
    u32     code;
    u32     BytesWritten;
    u32     FilePositionOnEntry, FilePositionOnExit;
    
    // Get the file position before writing anything to the file.
    FilePositionOnEntry = GetFilePosition( output->file );
    
    // Refer to the global working storage using local variables
    // for speed.
    Counts = HuffCounts;
    nodes  = HuffNodes;
    codes  = HuffCodes;

    // Count how many of each type of byte there are.
    CountBytes( Buf, Count, Counts );

    // Rescale the counts to fit in a byte.
    scale_counts( Counts, nodes );
    
    // Save the scaled byte counts to the file.
    for( i = 0 ; i < 256 ; i++ ) 
    {
        putc( (u8) nodes[ i ].count, output->file );
    }
    
    // Build the coding tree based on byte frequency.
    root_node = build_tree( nodes );
    
    // Convert the coding tree to code numbers.
    convert_tree_to_code( nodes, codes, 0, 0, root_node );

    // Get the bit file fields for speed.
    mask = output->mask;
    rack = output->rack;
    file = output->file;
    
    // For each byte in the buffer.
    for( i = 0; i < Count; i++ )
    {
        // Get a byte from the buffer.
        c = *Buf++;
        
        // Write out the code bits cooresponding to the byte.
 
        // From 'OutputBits'.
        m = (u32) ( 1L << ( ((u32) codes[ c ].code_bits) - 1 ) );
    
        code = codes[ c ].code;
        
        while( m ) 
        {
            if( m & code )
            {
                rack |= mask;
            }
            
            mask >>= 1;
        
            if( mask == 0 ) 
            {
                putc( (u8) rack, file );
            
                rack = 0;
                mask = 0x80;
            }
        
            m >>= 1;
        }
    }
    
    // Put back the bit file fields.
    output->mask = mask;
    output->rack = rack;
   
    // Add the end of stream marker.                
    OutputBits( output, 
                (u32) codes[ END_OF_STREAM ].code,
                codes[ END_OF_STREAM ].code_bits );
    
    // If a fractional byte remains to be output.
    if( output->mask != 0x80 )
    {
        // Write it to the file.
        putc( (u8) output->rack, output->file );
        
        // Clear the output buffer.
        output->rack = 0;
        output->mask = 0x80;
    }
    
    // Get the file position after writing everything.
    FilePositionOnExit = GetFilePosition( output->file );

    // Calculate the number of bytes written.
    BytesWritten = FilePositionOnExit - FilePositionOnEntry;

    // Return the number of bytes written.
    return( BytesWritten );
}

/*------------------------------------------------------------
| CompressFile
|
| PURPOSE:  
|
| DESCRIPTION: CompressFile is the compression routine called 
| by MAIN-C.C.  It looks for a single additional argument to 
| be passed to it from the command line:  "-d".  If a "-d" is 
| present, it means the user wants to see the model data 
| dumped out for debugging purposes.
|
| This routine works in a fairly straightforward manner.  
| First, it has to allocate storage for three different 
| arrays of data.
|
| Next, it counts all the bytes in the input file.  The 
| counts are all stored in long int, so the next step is 
| scale them down to single byte counts in the NODE array.
|  
| After the counts are scaled, the Huffman decoding tree is 
| built on top of the NODE array.  Another routine walks 
| through the tree to build a table of codes, one per symbol. 
| Finally, when the codes are all ready, compressing the file 
| is a simple matter.  After the file is compressed, the 
| storage is freed up, and the routine returns.
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
CompressFile( FILE *input, BIT_FILE *output )
{
    u32 *counts;
    NODE *nodes;
    CODE *codes;
    s16  root_node;

    counts = (u32 *) calloc( 256, sizeof( u32 ) );
    
    nodes = (NODE *) calloc( 514, sizeof( NODE ) );
    
    codes = (CODE *) calloc( 257, sizeof( CODE ) );
    
    count_bytes( input, counts );
    
    scale_counts( counts, nodes );
    
    output_counts( output, nodes );
    
    root_node = build_tree( nodes );
    
    convert_tree_to_code( nodes, codes, 0, 0, root_node );
    
    compress_data( input, output, codes );
    
    free( (char *) counts );
    free( (char *) nodes );
    free( (char *) codes );
}

/*------------------------------------------------------------
| convert_tree_to_code
|
| PURPOSE:  
|
| DESCRIPTION: Since the Huffman tree is built as a decoding 
| tree, there is no simple way to get the encoding values for 
| each symbol out of it.  This routine recursively walks 
| through the tree, adding the child bits to each code until 
| it gets to a leaf.  When it gets to a leaf, it stores the 
| code value in the CODE element, and returns. 
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
convert_tree_to_code( NODE *nodes, 
                      CODE *codes, 
                      u16 code_so_far, 
                      s16 bits, 
                      s16 node )
{
    if( node <= END_OF_STREAM ) 
    {
        codes[ node ].code = code_so_far;
        codes[ node ].code_bits = bits;
        return;
    }
    
    code_so_far <<= 1;
    
    bits++;
    
    convert_tree_to_code( nodes, 
                          codes, 
                          code_so_far, 
                          bits,
                          nodes[ node ].child_0 );
                          
    convert_tree_to_code( nodes, 
                          codes, 
                          (u16) ( code_so_far | 1 ),
                          bits, 
                          nodes[ node ].child_1 );
}

/*------------------------------------------------------------
| count_bytes
|
| PURPOSE: To counts the frequency of occurence of every byte 
| in the input file.
|
| DESCRIPTION: It marks the place in the input stream where it
| started, counts up all the bytes, then returns to the place 
| where it started.  
|
| In most C implementations, the length of a file cannot 
| exceed an u32, so this routine should always work.
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
count_bytes( FILE *input, u32 *counts )
{
    s32 input_marker;
    s16 c;

    input_marker = ftell( input );
    
    while( ( c = (s16) getc( input )) != EOF )
    {
        counts[ c ]++;
    }
    
    fseek( input, input_marker, 0 );
}

/*------------------------------------------------------------
| expand_data
|
| PURPOSE:  
|
| DESCRIPTION: Expanding compressed data is a little harder 
| than the compression phase.  As each new symbol is decoded, 
| the tree is traversed, starting at the root node, reading a 
| bit in, and taking either the child_0 or child_1 path.  
| Eventually, the tree winds down to a leaf node, and the 
| corresponding symbol is output.  
|
| If the symbol is the END_OF_STREAM symbol, it doesn't get 
| written out, and instead the whole process terminates. 
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
expand_data( BIT_FILE *input, 
             FILE *output, 
             NODE *nodes, 
             s16 root_node )
{
    int node;

    for( ; ; ) 
    {
        node = root_node;
        
        do 
        {
            if( InputBit( input ) )
            {
                node = nodes[ node ].child_1;
            }
            else
            {
                node = nodes[ node ].child_0;
            }
        } while ( node > END_OF_STREAM );
        
        if( node == END_OF_STREAM )
            break;
        
        // Trap error.  
        if( ( putc( (u8) node, output ) ) != node )
        {
            Debugger();
        }
     }
}

/*------------------------------------------------------------
| ExpandBytesFromBuffer
|
| PURPOSE: To expand a buffer that has been compressed with 
|          order 0 Huffman coding.
|
| DESCRIPTION: Read in the counts that have been stored in 
| the compressed buffer, then builds the Huffman tree.  
|
| The data can then be expanded by fetching in a bit at a 
| time from the compressed buffer. 
| 
| Returns the number of bytes in the output buffer.
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: Output buffer is large enough for the result.
|
| HISTORY: 07.28.98 from 'ExpandBytesFromFile'.
------------------------------------------------------------*/
u32 
ExpandBytesFromBuffer( u8* From, u8* To )
{
    NODE*   nodes;
    s16     root_node;
    s16     node;
    s16     value;
    u8      mask;
    s16     rack; 
    u8*     TargetAddressOnEntry;
    u16     i;
    u32     OutputByteCount;
    
    // Save the target buffer address so that 'To' can be
    // used as a memory cursor.
    TargetAddressOnEntry = To;
    
    // Refer to the global working storage using a local 
    // variable for speed.
    nodes  = HuffNodes;
    
    // Read the byte frequency counts from the source.
    for( i = 0 ; i < 256 ; i++ ) 
    {
        nodes[ i ].count = *From++;
    }
    
    nodes[ END_OF_STREAM ].count = 1;
    
    // Build the coding tree based on byte frequency.
    root_node = build_tree( nodes );
    
    // Initialize the mask and accumulator.
    rack = 0;
    mask = 0x80;

    while(1) 
    {
        node = root_node;
        
        do 
        {
            // From 'InputBit'.
            if( mask == 0x80 ) 
            {
                // Get a byte from the source buffer.
                rack = *From++;
            }
    
            // Get the bit, unshifted: non-zero means 1.
            value = (s16) ( rack & mask );
    
            mask >>= 1;
    
            if( mask == 0 )
            {
                mask = 0x80;
            }

            if( value )
            {
                node = nodes[ node ].child_1;
            }
            else
            {
                node = nodes[ node ].child_0;
            }
            
        } while( node > END_OF_STREAM );
        
        if( node == END_OF_STREAM )
        {
            // Calculate the number of bytes output.
            OutputByteCount = (u32)
                ( To - TargetAddressOnEntry );

            // Return the number of output bytes.
            return( OutputByteCount );
        }
        
        // Save the byte in the buffer.
        *To++ = (u8) node;
    }
}

/*------------------------------------------------------------
| ExpandBytesFromFile
|
| PURPOSE: To expand a file that has been compressed with 
|          order 0 Huffman coding.
|
| DESCRIPTION: Read in the counts that have been stored in 
| the compressed file, then build the Huffman tree.  
|
| The data can then be expanded by reading in a bit at a time 
| from the compressed file. 
| 
| Finally, the node array is freed and the routine returns.
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 07.06.96 from 'ExpandFile'.
------------------------------------------------------------*/
void 
ExpandBytesFromFile( BIT_FILE* input, u8* Buf )
{
    NODE    *nodes;
    s16     root_node;
    s16     node;
    s16     value;
    u8      mask;
    s16     rack; // The input character from 'getc'.
    FILE*   file;

    // Refer to the global working storage using a local 
    // variable for speed.
    nodes  = HuffNodes;
    
    // Read the byte frequency counts from the file.
    input_counts( input, nodes );
    
    root_node = build_tree( nodes );
    
    // Get the bit file fields for speed.
    mask = input->mask;
    rack = input->rack;
    file = input->file;
    while(1) 
    {
        node = root_node;
        
        do 
        {
            // From 'InputBit'.
            if( mask == 0x80 ) 
            {
                rack = (s16) getc( file );
            }
    
            // Get the bit, unshifted: non-zero means 1.
            value = (s16) ( rack & mask );
    
            mask >>= 1;
    
            if( mask == 0 )
            {
                mask = 0x80;
            }

            if( value )
            {
                node = nodes[ node ].child_1;
            }
            else
            {
                node = nodes[ node ].child_0;
            }
        } while ( node > END_OF_STREAM );
        
        if( node == END_OF_STREAM )
        {
            break;
        }
        
        // Save the byte in the buffer.
        *Buf++ = (u8) node;
     }
     
    // Put back the bit file fields.
    input->mask = mask;
    input->rack = rack;
}

/*------------------------------------------------------------
| ExpandFile
|
| PURPOSE: To expand a file that has been compressed with 
|          order 0 Huffman coding.
|
| DESCRIPTION: This routine has a simpler job than that of 
| the Compression routine.  All it has to do is read in the 
| counts that have been stored in the compressed file, then 
| build the Huffman tree.  The data can then be expanded
| by reading in a bit at a time from the compressed file. 
| 
| Finally, the node array is freed and the routine returns.
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
ExpandFile( BIT_FILE* input, FILE* output )
{
    NODE *nodes;
    s16  root_node;

    nodes = (NODE *) calloc( 514, sizeof( NODE ) );
    
    input_counts( input, nodes );
    
    root_node = build_tree( nodes );
    
    expand_data( input, output, nodes, root_node );
    
    free( (char *) nodes );
}

/*------------------------------------------------------------
| input_counts
|
| PURPOSE: To read the symbol weights written to a file by
|          'output_counts'.
|
| DESCRIPTION:  
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
input_counts( BIT_FILE *input, NODE *nodes )
{
    s16 i;
     
    for( i = 0 ; i < 256 ; i++ ) 
    {
        nodes[ i ].count = (u16) getc( input->file );
    }
    
    nodes[ END_OF_STREAM ].count = 1;
}

/*------------------------------------------------------------
| output_counts
|
| PURPOSE:  
|
| DESCRIPTION: In order for the compressor to build the same 
| model, I have to store the symbol counts in the compressed 
| file so the expander can read them in. 
|
| Just writes out 256 values without attempting to optimize 
| would be much simpler, but would hurt compression quite a 
| bit on small files.
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
output_counts( BIT_FILE *output, NODE *nodes )
{
    s16 i;

    for( i = 0 ; i < 256 ; i++ ) 
    {
        putc( (u8) nodes[ i ].count, output->file );
    }
}

/*------------------------------------------------------------
| scale_counts
|
| PURPOSE:  
|
| DESCRIPTION: In order to limit the size of my Huffman codes 
| to 16 bits, I scale my counts down so they fit in an 
| unsigned char, and then store them all as initial weights 
| in my NODE array.  The only thing to be careful of is to 
| make sure that a node with a non-zero count doesn't get 
| scaled down to 0.  Nodes with values of 0 don't get codes. 
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 07.29.98 TL Revised to use pointers for speed.
------------------------------------------------------------*/
void 
scale_counts( u32 *counts, NODE* nodes )
{
    u32   max_count;
    s16   i;
    u32*  AtCount;
    NODE* AtNode;

    // Find the maximum count in the given set of counts.
    max_count = 0;
    
    AtCount = counts;
    
    for( i = 0 ; i < 256; i++ )
    {
        if( *AtCount > max_count )
        {
            max_count = *AtCount;
        }
        
        AtCount++;
    }
    
    // When would this ever be true?  Empty stream?
    if( max_count == 0 ) 
    {
        *counts = 1;
        max_count = 1;
    }
    
    // Compute the scaling factor.
    max_count = max_count / 255;
    max_count = max_count + 1;
    
    // For each count and node.
    AtCount = counts;
    AtNode  = nodes;
    for( i = 0 ; i < 256; i++ ) 
    {
        AtNode->count = (u16) ( *AtCount / max_count );
        
        if( AtNode->count == 0 && *AtCount != 0 )
        {
            AtNode->count = 1;
        }
        
        // Advance to next count and node.
        AtCount++;
        AtNode++;
    }
    
    nodes[ END_OF_STREAM ].count = 1;
}

/*------------------------------------------------------------
| print_char
|
| PURPOSE:  
|
| DESCRIPTION: The print_model routine uses this function to 
| print out node numbers. The catch is, if it is a printable 
| character, it gets printed out as a character.  Makes the 
| debug output a little easier to read.
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
print_char( s16 c )
{
    if( c >= 0x20 && c < 127 )
    {
        printf( "'%c'", c );
    }
    else
    {
        printf( "%3d", c );
    }
}

/*------------------------------------------------------------
| print_model
|
| PURPOSE:  
|
| DESCRIPTION: If the -d command line option is specified, 
| this routine is called to print out some of the model 
| information after the tree is built.
|
| Note that this is the only place that the saved_count 
| NODE element is used for anything at all, and in this 
| case it is just for diagnostic information.  By the time 
| I get here, and the tree has been built, every active 
| element will have 0 in its count.
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  
------------------------------------------------------------*/
void 
print_model( NODE *nodes, CODE *codes )
{
    s16 i;

    for( i = 0 ; i < 513 ; i++ ) 
    {
        if( nodes[ i ].saved_count != 0 ) 
        {
            printf( "node=" );
            print_char( i );
            printf( "  count=%3d", nodes[ i ].saved_count );
            printf( "  child_0=" );
            print_char( nodes[ i ].child_0 );
            printf( "  child_1=" );
            print_char( nodes[ i ].child_1 );
            
            if( codes && i <= END_OF_STREAM ) 
            {
                printf( "  Huffman code=" );
                    FilePrintBinary( stdout, 
                                     codes[ i ].code, 
                                     codes[ i ].code_bits );
            }
            printf( "\n" );
        }
    }
}
