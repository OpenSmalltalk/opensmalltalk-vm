/*------------------------------------------------------------
| TLFortran.c
|-------------------------------------------------------------
|
| PURPOSE: To supply C functions equivalent to Fortran 
|          functions.
|
| DESCRIPTION:   
|        
| NOTE: 
|
| HISTORY: 02.17.00 From "Numerical Recipes in C", 2nd Ed.
------------------------------------------------------------*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#include "NumTypes.h"


/*------------------------------------------------------------
| DSIGNFromFortran
|-------------------------------------------------------------
|
| PURPOSE: To combine the magnitude of 'a' with the sign of
|          'b'.
|
| DESCRIPTION: Computes the result 'r',
|
|            r = fabs( a ) * s , where s is +1 if b >= 0
|                                           -1 otherwise.
|
| This macro does the same thing and is faster...
|
|     #define SIGN(a,b) ((b) >= 0.0 ? fabs(a) : -fabs(a))
|
| EXAMPLE:  
|                                          
| NOTE:
|
| ASSUMES:  
|           
| HISTORY: 02.29.00 From definition found at
|                   http://cclib.nsu.ru/projects/gnudocs/iso/
|                      gnudocs/g77/g77_298.html#SEC301.
------------------------------------------------------------*/
f64
DSIGNFromFortran( f64 a, f64 b )
{
    if( b >= 0.0 )
    {
        return( fabs( a ) );
    }
    else
    {
        return( -fabs( a ) );
    }
}
