/*------------------------------------------------------------
| TLComplexNumber.h
|-------------------------------------------------------------
|
| PURPOSE: To define the interface to complex number functions.
|
| DESCRIPTION: A Complex is a pair of f64 floating point 
| numbers.  
|
| A complex number can be in one of two forms: 
|
|               Cartesian and Polar
|
| Cartesian Form:
|
|            (x,iy)  where x is the real part and 
|                          y is the imaginary part
|
| Polar (or Trigonometric) Form:
|
|            (m,a)  where m is the modulus or length of the
|                           vector
|                         a is the argument or angle of the
|                           vector
|
| The above two forms are related by the following identities:
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
| NOTE: For an excellent introduction to complex numbers see
| "Advanced Algebra" by Hawkes.
|
| ASSUMES: DataSize.h has been loaded.
|
| HISTORY:  06.23.93 
|           03.28.96 moved complex type defs to 'DataSize.h'
-------------------------------------------------------------*/
#ifndef _COMPLEX_H
#define _COMPLEX_H

void    ComplexAdd( CX*, CX* );
void    ComplexSubtract( CX*, CX* );
void    ComplexMultiply( CX*, CX* );
void    ComplexDivide( CX*, CX* );
void    ComplexPower( CX*, f64 ); 
void    ComplexRoot( CX*, f64 );  

void    ComplexConjugate( CX* ); 

void    ComplexAddPolar( CX*, CX* );
void    ComplexSubtractPolar( CX*, CX* );
void    ComplexMultiplyPolar( CX*, CX* );
void    ComplexDividePolar( CX*, CX* );

void    ComplexConjugatePolar( CX* ); 


void    ComplexPowerPolar( CX*, f64 ); 
void    ComplexRootPolar( CX*, f64 ); 

void    ConvertToPolar( CX* );
void    ConvertToCartesian( CX* );

u32     IsSamePolarPoint( RA*, RA* );
void    ValidateSamePolarPoint( RA*, RA* );

#endif
