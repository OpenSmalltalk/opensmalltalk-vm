/*------------------------------------------------------------
| TLComplexNumber.c
|-------------------------------------------------------------
|
| PURPOSE: To define complex number functions.
|
| DESCRIPTION: A Complex is a pair of 12-byte, 
| 68881 Extended format floating point numbers.  
|
| A complex number can be in one of two forms: 
|
|               Cartesian or Polar
|
| Cartesian Form:
|
|            (x,iy)  where x is the real part and 
|                          y is the imaginary part
|
| Polar Form:
|
|            (m,a)  where m is the modulus or length of the
|                           vector
|                         a is the argument or angle of the
|                           vector
|
| The two forms are related by the following identities:
|
|                   x = m Cos(a),
|                   y = m Sin(a),
|           x^2 + y^2 = m^2.
|
|    Hence     x + iy = m( Cos(a) + i Sin(a) )
|         
| Euler Interpretation of the Polar Form:
|
|    The numbers held in Polar form can be interpreted in 
| another way using Euler's formula:
|
|              Cos(a) + i Sin(a) = e^(i a)
|
|    Hence     x + iy = m( Cos(a) + i Sin(a) ) = m e^(i a)
| 
|    (See p. 474 of "Handbook of Mathematics" by Bronshtein
|     and Semendyayev.)
|
| EXAMPLE:  
|
| NOTE: Most of the explanation below comes from the excellent 
| section on complex numbers in "Advanced Algebra" by Hawkes,
| 1905 edition.
|
| ASSUMES: 
|
| HISTORY:  06.24.93
|           03.28.96 revised.
------------------------------------------------------------- */

#include "TLTarget.h"
#include <stdio.h>

#include "TLTypes.h"
#include "TLBytes.h"
#include "TLf64.h"
#include "TLItems.h"
#include "TLVector.h"
#include "TLPoints.h"
#include "TLGeometry.h"

#include "TLComplexNumber.h"

/*------------------------------------------------------------
| ComplexAdd
|-------------------------------------------------------------
|
| PURPOSE: To add a complex number to another.
|
| DESCRIPTION: Result is accumulated at the address of the 
| first given complex number.
|
|     Rule: To add complex numbers, add the real and
|           imaginary parts separately.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Numbers are in Cartesian form.
|
| HISTORY:  06.24.93
-------------------------------------------------------------*/
void    
ComplexAdd( CX* Accumulator, CX* Amount )
{
    Accumulator->a += Amount->a;
    Accumulator->b += Amount->b;
}

/*------------------------------------------------------------
| ComplexSubtract
|-------------------------------------------------------------
|
| PURPOSE: To subtract a complex number from another.
|
| DESCRIPTION: Result is accumulated at the address of the 
| first given complex number.
|
|    Rule: To subtract complex numbers, subtract the real 
|          and imaginary parts separately.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Numbers are in Cartesian form.
|
| HISTORY:  06.24.93
 -------------------------------------------------------------*/
void    
ComplexSubtract( CX* Accumulator, CX* Amount )
{
    Accumulator->a -= Amount->a;
    Accumulator->b -= Amount->b;
}

/*------------------------------------------------------------
| ComplexMultiply
|-------------------------------------------------------------
|
| PURPOSE: To multiply a complex number by another.
|
| DESCRIPTION: Result is accumulated at the address of the 
| first given complex number.
|
|      Rule: To multiply the complex numbers a+ib by c+id,
|            proceed as if they were real binomials, keeping
|            in mind the laws of multiplying imaginaries.
|
|            Thus         a + ib
|                         c + id
|            --------------------
|            ac + icb + iad + (i)^2bd = ac - bd + i(cb + ad)
|
| EXAMPLE:  
|
| NOTE:
|
| ASSUMES: Numbers are in Cartesian form.
|
| HISTORY:  06.24.93
------------------------------------------------------------- */
void    
ComplexMultiply( CX* Accumulator, CX*  Amount )
{
    f64  RealTerm;
    f64  ImaginaryTerm;
    
    RealTerm = Accumulator->a * Amount->a -
               Accumulator->b * Amount->b;
    
    ImaginaryTerm = Amount->a      * Accumulator->b +
                    Accumulator->a * Amount->b;
                    
    Accumulator->a = RealTerm;
    Accumulator->b = ImaginaryTerm;
}

/*------------------------------------------------------------
| ComplexConjugate
|-------------------------------------------------------------
|
| PURPOSE: To calculate the conjugate of a complex number.
|
| DESCRIPTION: Result is held at the address of the given 
| complex number.
|
| Complex numbers that differ only in the sign of their
| imaginary parts are called conjugate complex numbers, or 
| conjugate imaginaries.
|
| Theorem: The sum and the product of conjugate complex 
|          numbers are real numbers.
|
|   Thus    a + ib + a - ib  = 2a
|           (a + ib)(a - ib) = a^2 + b^2
|
| EXAMPLE:  
|
| NOTE:
|
| ASSUMES: Numbers are in Cartesian form.
|
| HISTORY:  06.24.93
------------------------------------------------------------- */
void    
ComplexConjugate( CX* Amount )
{
    Amount->b *= -1.0;
}

/*------------------------------------------------------------
| ComplexDivide
|-------------------------------------------------------------
|
| PURPOSE: To divide a complex number by another.
|
| DESCRIPTION: Result is accumulated at the address of the 
| first given complex number.
|
| The quotient of two complex numbers may be expressed as a
| single complex number.
|
|      Rule: To express the quotient (a+ib)/(c+id) in the 
|            form of x+iy, rationalize the denominator, 
|            using as a rationalizing factor the conjugate of
|            the denominator.
|
|      Thus  a + ib   a + ib    c - id
|           ------- = ------ * --------
|            c + id   c + id    c - id
|
|                      ac + bd - i(ad - bc)
|                   = ----------------------
|                          c^2 + d^2
|
|                       ac + bd        (ad - bc)
|                   = ----------- - i -----------
|                      c^2 + d^2       c^2 + d^2
|          
|
| EXAMPLE:  
|
| NOTE:
|
| ASSUMES: Numbers are in Cartesian form.
|
| HISTORY:  06.24.93
------------------------------------------------------------- */
void    
ComplexDivide( CX* Accumulator, CX* Amount )
{
    f64  Denominator;
    f64  RealTerm;
    f64  ImaginaryTerm;
    f64  a;
    f64  b;
    f64  c;
    f64  d;
    
    a = Accumulator->a;
    b = Accumulator->b;
    c = Amount->a;
    d = Amount->b;
    
    Denominator = c*c + d*d;
    
    RealTerm = (a*c + b*d)/Denominator;
    
    ImaginaryTerm = -((a*d - b*c)/Denominator);
                    
    Accumulator->a = RealTerm;
    Accumulator->b = ImaginaryTerm;
}

/*------------------------------------------------------------
| ComplexPowerPolar
|-------------------------------------------------------------
|
| PURPOSE: To raise a complex number to a real power.
|
| DESCRIPTION: Result is held at the address of the 
| given complex number.
|
| It is easier to raise a complex number to a power when the
| number is in polar form.
|
| DeMoivre's Theorem: 
|
| [m ( Cos(a) + iSin(a) ]^n = m^n ( Cos(n a) + i Sin(n a) )
|
| Rule: The modulus of the nth power of a number is the nth
|       power of its modulus.  The argument of the nth power
|       of a number is n times the argument.
|
| EXAMPLE:  
|
| NOTE: Faster and more accurate than ComplexPower due
|       to lack of form conversion roundoff.
|
| ASSUMES: 'Amount' is in Polar form.
|
| HISTORY:  06.24.93
------------------------------------------------------------- */
void
ComplexPowerPolar( CX* Amount, f64 Power )
{
    Amount->a  = pow( Amount->a, Power );
    Amount->b *= Power;
}

/*------------------------------------------------------------
| ComplexPower
|-------------------------------------------------------------
|
| PURPOSE: To raise a complex number to a real power.
|
| DESCRIPTION: Result is held at the address of the 
| given complex number.
|
| It is easier to raise a complex number to a power when the
| number is in polar form.
|
| DeMoivre's Theorem: 
|
| [m ( Cos(a) + iSin(a) ]^n = m^n ( Cos(n a) + i Sin(n a) )
|
| Rule: The modulus of the nth power of a number is the nth
|       power of its modulus.  The argument of the nth power
|       of a number is n times the argument.
|
| The given number is in Cartesion form but is converted
| to polar form to apply DeMoivre's Theorem, and then
| converted back to Cartesian form.
|
| EXAMPLE:  
|
| NOTE: Slower and less accurate than ComplexPowerPolar due
|       to form conversion roundoff.
|
| ASSUMES: f64 is in Cartesian form.
|
| HISTORY:  06.24.93
------------------------------------------------------------- */
void
ComplexPower( CX* Amount, f64 Power )
{
    ConvertToPolar( Amount );
    
    ComplexPowerPolar( Amount, Power );
    
    ConvertToCartesian( Amount );
}

/*------------------------------------------------------------
| ComplexRootPolar
|-------------------------------------------------------------
|
| PURPOSE: To find the root a complex number to a real power.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: Finish as needed.
|
| ASSUMES: Amount is in Polar form.
|
| HISTORY: 03.28.96
------------------------------------------------------------- */
void
ComplexRootPolar( CX* Amount , f64 Power )
{
    printf( "ComplexRootPolar is a stub.\n" );
    Amount = Amount;
    Power = Power;
}

/*------------------------------------------------------------
| ConvertToCartesian
|-------------------------------------------------------------
|
| PURPOSE: To convert a Polar-form complex number into
|          a Cartesian-form complex number.
|
| DESCRIPTION: Result is held at the address of the given 
| complex number.
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
| ASSUMES: f64 is in Polar form.
|
| HISTORY:  06.24.93
------------------------------------------------------------- */
void    
ConvertToCartesian( CX* Amount )
{
    f64  Modulus;
    f64  Argument;
    
    Modulus  = Amount->a;
    Argument = Amount->b;

    Amount->a = Modulus * cos(Argument);
    Amount->b = Modulus * sin(Argument);
}

/*------------------------------------------------------------
| ConvertToPolar
|-------------------------------------------------------------
|
| PURPOSE: To convert a Cartesian-form complex number into
|          a Polar-form complex number.
|
| DESCRIPTION: Result is held at the address of the given 
| complex number.
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
| ASSUMES: Numbers in Cartesian form.
|
| HISTORY:  06.24.93
|           04.06.96 converted to use 'atan2' which computes
|                    the quadrant correctly.
------------------------------------------------------------- */
void    
ConvertToPolar( CX* A )
{
    f64 Modulus;
    f64 Argument;
    f64 x;
    f64 y;
    
    x = A->a;
    y = A->b;
    
    Modulus = sqrt(x*x + y*y);
    
    Argument = atan2( y, x );
                    
    A->a = Modulus;
    A->b = Argument;
}

/*------------------------------------------------------------
| IsSamePolarPoint
|-------------------------------------------------------------
|
| PURPOSE: To test if two points in polar coordinates refer
|          to the same point.
|
| DESCRIPTION: In polar coordinates each point has many
| ways of referring to the same point.  
|
| If the two points convert to the same rectangular 
| coordinate, within the 'Chop' tolerance, then this 
| procedure returns '1', otherwise returns '0'.
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 'r1/r2' refer to radius vector, 'a1/a2' refer to
|          the vectorial angle.
|           
| HISTORY: 04.06.96 
------------------------------------------------------------*/
u32  
IsSamePolarPoint( RA* a, RA* b )
{
    f64 aa, ar, ba, br;
    f64 x1, y1, x2, y2;
    
    aa = a->a;
    ar = a->r;
    ba = b->a;
    br = b->r;
    
    x1 = ar * cos( aa );
    y1 = ar * sin( aa );
    
    x2 = br * cos( ba );
    y2 = br * sin( ba );

    if( Eq( x1, x2 ) && Eq( y1, y2 ) )
    {
        return( 1 );
    }
    else
    {
        return( 0 );
    }
}

/*------------------------------------------------------------
| ValidateSamePolarPoint
|-------------------------------------------------------------
|
| PURPOSE: To compare two polar coordinates and trap 
|          differences larger than the Chop tolerance.
|
| DESCRIPTION:  
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: 
|           
| HISTORY: 04.06.96 
------------------------------------------------------------*/
void
ValidateSamePolarPoint( RA* a, RA* b )
{
     if( ! IsSamePolarPoint( a, b ) )
     {
        Debugger();
        printf( "ValidateSamePolarPoint Error.\n" );
     }
} 
