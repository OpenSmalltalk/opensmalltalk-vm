/*------------------------------------------------------------
| TLVector.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to vector functions.
|
| DESCRIPTION: 
|        
| NOTE: 
|
| HISTORY: 03.28.96 
------------------------------------------------------------*/

#ifndef _VECTOR_H
#define _VECTOR_H

#ifdef __cplusplus
extern "C"
{
#endif

/************************************************************/
/*                A   V E C T O R   R E C O R D             */
/************************************************************/
//
// This record is used to refer to a list of complex
// numbers.  Space is allocated for both 'X' and 'Y' parts
// but one or more may be empty as indicated by 'IsX' and
// 'IsY' flags.
//
// These records are dynamically allocated, with the number
// data appended to this record.
//
// For example, to get the 'X' part of the first item in
// the vector:
//
//        FirstXPart = V->X[0];
//
// To get the 'Y' part of the first item in the vector:
//
//        FirstYPart = V->Y[0];
//
// Free using 'free'.
//
typedef struct 
{
    u32     ItemCount; // How many data items can follow.
                       //               
    u8      IsX;       // Non-zero if there are X/real/modulus
                       // values.
                       //
    u8      IsY;       // Non-zero if there are Y/imaginary/
                       // argument values.
                       //
    u8      IsPolar;   // Non-zero if the values are in polar
                       // form, else in Cartesian form.
                       //
    u8      Pad;       // Used to make 8-byte aligned.
                       //
    f64*    X;         // Where the 'x' coordinate/real part/
                       // modulus is stored in this record.
                       //     
    f64*    Y;         // Where the 'y' coordinate/imaginary 
                       // part/argument is stored in this
                       // record.
                       //
    // The vector data is stored here, real part first.
} Vector;

void        AddToVector( Vector*, f64, f64 );
void        ChopVector( Vector* );
void        ConvertVectorToPolar( Vector* );

Vector*     DuplicateVector( Vector* );
void        ExtentOfVector( Vector*, f64*, f64*, f64*, f64* );
Vector*     LoadVector( s8* );
Vector*     MakeVector( u32, f64*, f64* );
f64         MeanSlopeOfVector( Vector* );
void        NormalizeVector( Vector* );

void        SaveVector( Vector* , s8* );
void        ShuffleVector( Vector* );
void        SubtractVector( Vector*, Vector* );
void        SumOfVector( Vector*, f64*, f64* );
void        ZeroVector( Vector* );

#ifdef __cplusplus
} // extern "C"
#endif

#endif // _VECTOR_H
