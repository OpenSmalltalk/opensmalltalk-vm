/*------------------------------------------------------------
| TLVector.c
|-------------------------------------------------------------
|
| PURPOSE: To provide vector functions.
|
| HISTORY: 03.28.95 separated from 'Datum.c'.
------------------------------------------------------------*/

#include "TLTarget.h"  

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "TLTypes.h"
#include "TLBytes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLStrings.h"
#include "TLStacks.h"
#include "TLParse.h" 
#include "TLf64.h"
#include "TLVector.h"

/*------------------------------------------------------------
| ChopVector
|-------------------------------------------------------------
|
| PURPOSE: To replace all numbers in a vector with a 
|          magnitude less than 10^-10 with zero.
|
| DESCRIPTION:  
|
| EXAMPLE:    ChopVector( V, 100 );
|
| NOTE: From p. 541 of Mathematica.
|
| ASSUMES:  
|           
| HISTORY: 03.28.96 from 'SumItems'.
------------------------------------------------------------*/
void
ChopVector( Vector* V )
{
    if( V->IsX )
    {
//TBD       ChopItems( V->X, V->ItemCount );
    }
    
    if( V->IsY )
    {
//TBD       ChopItems( V->Y, V->ItemCount );
    }
}       

/* ------------------------------------------------------------
| ConvertVectorToPolar
|-------------------------------------------------------------
|
| PURPOSE: To convert a Cartesian-form vector of (x,y) pairs
|          to a Polar-form vector of (distance,angle) pairs.
|
| DESCRIPTION:  
|
| The two complex number forms are related by the following:
|
|                   x = m Cos(a),
|                   y = m Sin(a),
|           x^2 + y^2 = m^2.
|
|    Hence     x + iy = m( Cos(a) + i Sin(a) )
|
|              m = Sqrt(x^2 + y^2)
|              a = ArcCos( x/m )
|                = ArcSin( y/m )
| EXAMPLE:  
|
| NOTE:
|
| ASSUMES: Input vector is in Cartesian form.
|          Both X and Y parts of the vector exist.
|
| HISTORY:  04.02.96 from 'ConvertToPolar'.
|           04.08.96 converted to use 'atan2'.
------------------------------------------------------------- */
void    
ConvertVectorToPolar( Vector* V )
{
    f64 Modulus;
    f64 Argument;
    f64 x;
    f64 y;
    f64*    X;
    f64*    Y;
    u32     i, ItemCount;
    
    if( V->IsPolar ) return;
    
    X = V->X;
    Y = V->Y;
    
    ItemCount = V->ItemCount;
    
    for(i = 0; i < ItemCount; i++)
    {
        x = X[i];
        y = Y[i];
        
        Modulus = sqrt(x*x + y*y);
    
        Argument = atan2( y, x ); 
        
        X[i] = Modulus; // Distance.
        Y[i] = Argument; // Angle.
    }   
    
    // Mark this as being in polar form.
    V->IsPolar = 1;     
}

/*------------------------------------------------------------
| DuplicateVector
|-------------------------------------------------------------
|
| PURPOSE: To make a copy of a vector.
|
| DESCRIPTION: 
|
| EXAMPLE: d = DuplicateVector( V, n );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 03.25.96 
------------------------------------------------------------*/
Vector*
DuplicateVector( Vector* V )
{
    Vector* NewV;
    
    // Copy the data.
    NewV = MakeVector( V->ItemCount, V->X, V->Y );

    // Copy the status fields.
    NewV->IsX = V->IsX;
    NewV->IsY = V->IsY;
    NewV->IsPolar = V->IsPolar;
    NewV->Pad = V->Pad;
    
    return( NewV );
}

/*------------------------------------------------------------
| ExtentOfVector
|-------------------------------------------------------------
|
| PURPOSE: To find the range of values in a vector.
|
| DESCRIPTION: Returns the low and high values of each 
|              existing dimension.
|
| EXAMPLE: ExtentOfVector( V, &LoX, &HiX, &LoY, &HiY );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 02.02.96 
------------------------------------------------------------*/
#if 0
void
ExtentOfVector( Vector* V, 
                f64* AtLoX, f64* AtHiX,
                f64* AtLoY, f64* AtHiY )
{
    if( V->IsX )
    {
//TBD       ExtentOfItems( V->X, V->ItemCount, AtLoX, AtHiX );
    }
    
    if( V->IsY )
    {
//TBD       ExtentOfItems( V->Y, V->ItemCount, AtLoY, AtHiY );
    }
}
#endif

/*------------------------------------------------------------
| LoadVector
|-------------------------------------------------------------
|
| PURPOSE: To load a vector from an ASCII file.
|
| DESCRIPTION: Reads the data previously written to a file
| using the 'SaveVector' procedure.  Returns the address of
| a dynamically allocated vector or 0 if the file can't be
| opened.
|
| EXAMPLE: MyVector = LoadVector( "C:TestFile.DAT" );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.28.96 from 'LoadArray'.
|          04.25.96 fixed item count bug.
------------------------------------------------------------*/
#if 0
Vector*
LoadVector( s8* AFileName )
{
    FILE*   AFile;
    s16     ByteCount;
    s8      ABuffer[MaxLineBuffer];
    u32     c;
    Vector* V;
    s8*     AtTextDatum;
    s32     ItemCount, IsX, IsY, IsPolar, Pad;
    f64*    X;
    f64*    Y;
    
    // Open the file.
    AFile = OpenFileTL(AFileName, ReadAccess);

    // Make sure it opened OK.
    if(AFile == 0)
    {
        return(0);
    }
    
    // Get the vector parameters.
    fscanf( AFile, 
             "%d %d %d %d %d\n", 
             &ItemCount,
             &IsX,
             &IsY,
             &IsPolar,
             &Pad );
    
    // Make a new vector record.
    V = MakeVector( (u32) ItemCount, 0, 0 );
    
    // Update the parameters.
    V->IsX = (u8) IsX;
    V->IsY = (u8) IsY;
    V->IsPolar = (u8) IsPolar;
    V->Pad = (u8) Pad;
    
    // Load the data values, 2 per line.
    X = V->X;
    Y = V->Y;

ReadLine:
    
    ByteCount = ReadMacTextLine(AFile, ABuffer);
        
    if( ByteCount == -1 ) goto Done;
    
    c = CountDataInString( (s8*) &ABuffer );

    // If there is data in this line then convert it
    // to binary and put it in the vector.
    if( c == 2 )
    {
        AtTextDatum = (s8*) &ABuffer;
            
        *X++ = GetFirstDatumInString( AtTextDatum );
                
        AtTextDatum += CountOfBytesParsed;
            
        *Y++ = GetFirstDatumInString( AtTextDatum );
                
        ItemCount--; // Account for each X,Y item.
    }
    
    goto ReadLine;
    
Done:
        
    if( ItemCount )
    {
        Debugger(); // CellCount mismatch.
    }
    
    CloseFile( AFile );
    
    return( V );
}
#endif // TBD
/*------------------------------------------------------------
| MakeVector
|-------------------------------------------------------------
|
| PURPOSE: To make a new vector.
|
| DESCRIPTION: Allocates a new vector record with room for
| 'ItemCount' complex 'f64' numbers.  
|
| If 'X' and/or 'Y' parameters are non-zero, then the items 
| referenced are copied to the new vector record.
|
| EXAMPLE: v = MakeVector( n, 0, 0 );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 03.28.96 from 'DuplicateVector'
------------------------------------------------------------*/
Vector*
MakeVector( u32 ItemCount, f64* X, f64* Y )
{
    Vector* V;
    u32     RecordSize;
    u32     ByteCount;
    
    // Calculate the size of the overall record.
    RecordSize = sizeof(Vector) +
                 ItemCount * 2 * sizeof( f64 );
                 
    // Allocate the new vector record.
    V = (Vector*) malloc( RecordSize );
    
    // Save the item count.
    V->ItemCount = (u32) ItemCount;
    
    // Clear the pad field.
    V->Pad = 0;
    
    // Default to Cartesian form.
    V->IsPolar = 0;
    
    // Default to having both 'X' and 'Y' values.
    V->IsX = 1;
    V->IsY = 1;
    
    // Refer to where the real and imaginary parts will
    // be stored.
    V->X = (f64*) ( ( (s8*) V) + sizeof( Vector ) );
    V->Y = &V->X[ItemCount];
    
    // If there are real values to store, store them.
    if( X != 0 )
    {
        ByteCount = ItemCount * sizeof(f64);
    
        memcpy( (void*) V->X, (void*) X, ByteCount );
        
    }
    
    // If there are imaginary values to store, store them.
    if( Y != 0 )
    {
        ByteCount = ItemCount * sizeof(f64);
    
        memcpy( (void*) V->Y, (void*) Y, ByteCount );
    }
    
    // Return the vector.
    return( V );
}

/*------------------------------------------------------------
| MeanSlopeOfVector
|-------------------------------------------------------------
|
| PURPOSE: To find the mean slope of every pairing of XY
|          points in a vector.
|
| DESCRIPTION: Exhaustively pairs each point and averages the
| mean slope.
|
| EXAMPLE:  
|
| NOTE:
|
| ASSUMES: Input vector is in Cartesian form.
|          Both X and Y parts of the vector exist.
|
| HISTORY:  04.08.96 from 'DistanceOfEachToEach'.
-------------------------------------------------------------*/
f64 
MeanSlopeOfVector( Vector* V )
{
    f64 x1, x2, dx, dy, slope;
    f64 y1, y2;
    f64*    X;
    f64*    Y;
    s32     i, j, ItemCount;
    s32     LastItem, SlopeCount;
    
    X = V->X;
    Y = V->Y;
    
    ItemCount = (s32) V->ItemCount;

    // While there are results to produce.
    LastItem = ItemCount - 1;
    slope = 0;
    SlopeCount = 0;
    for( i = 0; i < LastItem; i++ )
    {
        // Get the first point
        x1 = X[i];
        y1 = Y[i];
        
        for( j = i+1; j < ItemCount; j++ )
        {
            // Get the second point.
            x2 = X[j];
            y2 = Y[j];
    
            dx = x1 - x2;
            dy = y1 - y2;
            
            if( dx != 0 )
            {
                slope += dy / dx;
                SlopeCount++;
            }
        }
    }
    
    // Calculate the mean slope.
    slope /= SlopeCount;
    
    return( slope );
 }

/*------------------------------------------------------------
| NormalizeVector
|-------------------------------------------------------------
|
| PURPOSE: To normalize the X and Y parts separately.
|
| DESCRIPTION: Scales values by the mean.
|
| EXAMPLE: NormalizeVector( V );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.02.96 
------------------------------------------------------------*/
void
NormalizeVector( Vector* V )
{
    if( V->IsX )
    {
//TBD       NormalizeItems( V->X, V->ItemCount );
    }
    
    if( V->IsY )
    {
//TBD       NormalizeItems( V->Y, V->ItemCount );
    }
}

/*------------------------------------------------------------
| SaveVector
|-------------------------------------------------------------
|
| PURPOSE: To save a vector to an ASCII file.
|
| DESCRIPTION: Saves values two per line, X Y.
|
| EXAMPLE: SaveVector( AVector, ItemCount, "C:TestFile.DAT" );
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 03.05.96 from 'SaveArray'.
|          03.28.96 revised for X and Y.
------------------------------------------------------------*/
#if 0 // TBD
void
SaveVector( Vector* V, s8* AFileName )
{
    FILE*   AFile;
    s8*     AtNumberString;
    u32     i;
    f64 v;
    
    // Open the file.
    AFile = ReOpenFile( AFileName );
    
    // Save the vector parameters.
    fprintf( AFile, 
             "%d %d %d %d %d\n", 
             V->ItemCount,
             (u32) V->IsX,
             (u32) V->IsY,
             (u32) V->IsPolar,
             (u32) V->Pad );
    
    // Save the data cell values, 2 per line, X then Y.

    // For each item.
    for( i = 0; i < V->ItemCount; i++ )
    {
        // Get the X value.
        v = V->X[i];
        
        // Test for not a number.
        if( V->IsX == 0 || ISNAN(v) || v == NoNum )
        {
            AtNumberString = (s8*) "NaN";
        }
        else
        {
            UseFixedPointFormat = 0;
            UseScientificFormat = 0;
            
            AtNumberString = 
                ConvertNumberToString( (Number) v );
        }
        
        // Save X value.    
        fprintf(AFile,"%s ",AtNumberString);
            
        // Get the Y value.
        v = V->Y[i];
        
        // Test for not a number.
        if( V->IsY == 0 || ISNAN(v) || v == NoNum )
        {
            AtNumberString = (s8*) "NaN";
        }
        else
        {
            UseFixedPointFormat = 0;
            UseScientificFormat = 0;
            
            AtNumberString = 
                ConvertNumberToString( (Number) v );
        }
        
        // Save Y value.    
        fprintf(AFile,"%s\n",AtNumberString);
    }                   
        
    CloseFile(AFile);
    
    /* Set the file to an MPW document for now. */
#if macintosh
    SetFileType(AFileName,(s8*) "TEXT");
    SetFileCreator(AFileName,(s8*) "MPS ");
#endif // macintosh
}
#endif

/*------------------------------------------------------------
| ShuffleVector
|-------------------------------------------------------------
|
| PURPOSE: To randomly shuffle the locations of values
|          in a vector.
|
| DESCRIPTION: If X and Y parts are both existing, then the
| XY pairs are kept as a unit.  Otherwise, shuffles either
| the X or Y part that exists.
|
| EXAMPLE: ShuffleVector( V );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.03.96 
|          04.11.96 Changed to use pseudo-random selection
|                   to avoid regularity of sub-random method.
------------------------------------------------------------*/
#if 0
void
ShuffleVector( Vector* V )
{
    s32     a, b, i, ItemCount;
    f64 v;
    f64*    X;
    f64*    Y;
    
    ItemCount = (s32) V->ItemCount;
    
    if( V->IsX && V->IsY )
    {
        // Shuffle X and Y pairs as a unit.
        X = V->X;
        Y = V->Y;
        
        for( i = 0; i < ItemCount; i++ )
        {
// TBD          a = RandomInteger( ItemCount );
// TBD          b = RandomInteger( ItemCount );
        
            v = X[a]; X[a] = X[b]; X[b] = v;
            v = Y[a]; Y[a] = Y[b]; Y[b] = v;
        }
    }
    else // Either X or Y part needs to be shuffled.
    {
        if( V->IsX )
        {
            X = V->X;
        
            for( i = 0; i < ItemCount; i++ )
            {
//TBD               a = RandomInteger( ItemCount );
//TBDS              b = RandomInteger( ItemCount );
        
                v = X[a]; X[a] = X[b]; X[b] = v;
            }
        }
        
        if( V->IsY )
        {
            Y = V->Y;
        
            for( i = 0; i < ItemCount; i++ )
            {
                a = RandomInteger( ItemCount );
                b = RandomInteger( ItemCount );
        
                v = Y[a]; Y[a] = Y[b]; Y[b] = v;
            }
        }
    }
}
#endif

/*------------------------------------------------------------
| SubtractVector
|-------------------------------------------------------------
|
| PURPOSE: To subtract one vector from another.
|
| DESCRIPTION: Subtract vector 'B' from vector 'A', leaving
| the result in 'A'.
|
| EXAMPLE: SubtractVector( A, B );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.03.96 
------------------------------------------------------------*/
void
SubtractVector( Vector* A, Vector* B )
{
    u32     i, ItemCount;
    f64*    a;
    f64*    b;
    
    ItemCount = A->ItemCount;
    
    if( A->IsX && B->IsX )
    {
        // Subtract the X parts.
        a = A->X;
        b = B->X;
        
        for( i = 0; i < ItemCount; i++ )
        {
            a[i] -= b[i];
        }
    }
    
    if( A->IsY && B->IsY )
    {
        // Subtract the Y parts.
        a = A->Y;
        b = B->Y;
        
        for( i = 0; i < ItemCount; i++ )
        {
            a[i] -= b[i];
        }
    }
}   

/*------------------------------------------------------------
| SumOfVector
|-------------------------------------------------------------
|
| PURPOSE: To find the sums of the X and Y parts separately.
|
| DESCRIPTION: Returns the sums of each existing dimension.
|
| EXAMPLE: SumOfVector( V, &Xsum, &Ysum );
|
| NOTE: 
|
| ASSUMES:  
|           
| HISTORY: 04.02.96 
------------------------------------------------------------*/
#if 0 // TBD
void
SumOfVector( Vector* V, f64* XSum, f64* YSum )
{
    if( V->IsX )
    {
        *XSum = SumItems( V->X, V->ItemCount );
    }
    
    if( V->IsY )
    {
        *YSum = SumItems( V->Y, V->ItemCount );
    }
}

#endif
