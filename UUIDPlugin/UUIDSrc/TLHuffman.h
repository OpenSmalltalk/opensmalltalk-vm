/*------------------------------------------------------------
| TLHuffman.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to data compression 
|          functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 07.03.96 
|          08.19.97 added C++ support.
------------------------------------------------------------*/

#ifndef _HUFFMAN_H
#define _HUFFMAN_H

#ifdef __cplusplus
extern "C"
{
#endif

/*------------------------------------------------------------
| NODE
|
| PURPOSE: The NODE structure is a node in the Huffman 
|          decoding tree. 
|
| DESCRIPTION: It has a count, which is its weight in the 
| tree, and the node numbers of its two children.  The 
| saved_count member of the structure is only there for 
| debugging purposes, and can be safely taken out at any time.  
| It just holds the intial count for each of the symbols, 
| since the count member is continually being modified as 
| the tree grows 
| 
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 07.29.98 TL Added address of child nodes to
|                      speed traversal on decompress.
------------------------------------------------------------*/
typedef struct tree_node 
{
    u16 UncompressedByte; // The uncompressed byte this node
                          // stands for.
    u16 count;
    u16 saved_count;
    s16 child_0;
    s16 child_1;
    struct tree_node* child_0_node; 
    struct tree_node* child_1_node; 
} NODE;

/*------------------------------------------------------------
| CODE
|
| PURPOSE: The CODE structure is for encoding.
|
| DESCRIPTION: A Huffman tree is set up for decoding, not 
| encoding.  When encoding, I first walk through the tree and 
| build up a table of codes for each symbol.  The codes are 
| stored in this CODE structure.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY: 08.19.97 commented out the 'code' following 
|                   'struct' because C++ compiler complained.
------------------------------------------------------------*/
typedef struct // code <--- that causes problems under C++.
{
    u16 code;
    s16 code_bits;
} CODE;


// The special EOS symbol is 256, the first available symbol 
// after all of the possible bytes.  When decoding, reading 
// this symbol indicates that all of the data has been read in.
//
#define END_OF_STREAM 256

// These working buffers are used by 'CompressBytesToFile',
// 'CompressBytesToBuffer', 'ExpandBytesFromFile' and
// 'ExpandBytesFromBuffer'.
extern u32  HuffCounts[];
extern NODE HuffNodes[];
extern CODE HuffCodes[];

s16     build_tree( NODE* );
void    compress_data( FILE*, BIT_FILE*, CODE* );
u32     CompressBytesToBuffer( u8*, u8*, u32 );
u32     CompressBytesToFile( BIT_FILE*, u8*, u32 );
void    CompressFile( FILE*, BIT_FILE* );
void    convert_tree_to_code( NODE*, CODE*, u16, s16, s16 );
void    count_bytes( FILE*, u32* );
void    expand_data( BIT_FILE* , FILE*, NODE*, s16 );
u32     ExpandBytesFromBuffer( u8*, u8* );
void    ExpandBytesFromFile( BIT_FILE*, u8* );
void    ExpandFile( BIT_FILE*, FILE* );
void    input_counts( BIT_FILE*, NODE* );
void    output_counts( BIT_FILE*, NODE* );
void    print_char( s16 c );
void    print_model( NODE*, CODE* );
void    scale_counts( u32*, NODE* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _HUFFMAN_H
