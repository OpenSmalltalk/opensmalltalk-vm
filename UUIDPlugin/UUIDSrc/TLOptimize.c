/*------------------------------------------------------------
| TLOptimize.c
|-------------------------------------------------------------
|
| PURPOSE: To hold function optimization functions.
|
| HISTORY:  03.29.96 
------------------------------------------------------------*/

#include "TLTarget.h"

#include <stdlib.h>
#include <stdio.h>

#if macintosh
#include <QuickDraw.h>
#include <TextEdit.h>
#endif

#include "TLTypes.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLItems.h"
#include "TLVector.h"
#include "TLList.h"
#include "TLMatrixAlloc.h"
#include "TLSubRandom.h"
#include "TLRandom.h"
#include "TLWin.h"
//#include "TLLog.h"

#include "TLOptimize.h"

// Globals used by 'FindGradientMinimum'.
f64*    FGM_X;              // The independent variable.
f64*    FGM_DimSum;         // Working buffer, dynamic.
f64*    FGM_Base;           // Current origin of search.
f64*    FGM_Direction;      // Current direction of search from
                            // current origin.
s32     FGM_DimCount;       // Number of X dimensions.
s32     FGM_HiY;            // Vertex index of highest Y value.
f64     FGM_MinXi;          // The smallest valid value for any X[i].  
                            // This is application specific.

f64     (*FGM_FofX)( f64* ); // The objective function without
                             // derivative calculation.
                           
f64     (*FGM_FofXd)( f64*, f64*, f64* ); 
                           // The objective function with 
                           // derivative calculation.

// Globals used by 'FindSimplexMinimum'.
f64**   FSM_Vertex;         // The data of the vertex matrix.
f64*    FSM_Y;              // Evaluation result at each vertex.
f64*    FSM_DimSum;         // Working buffer, dynamic.
f64*    FSM_TrialPoint;     // Trial point buffer, dynamic. 
s32     FSM_DimCount;       // Number of X dimensions.
s32     FSM_HiY;            // Vertex index of highest Y value.
f64     (*FSM_FofX)(f64*); // The objective function.

// Globals used by 'FindRandomMultiDimensionalMinimum'.
f64*    FRMD_X;
s32     FRMD_DimCount;

/*------------------------------------------------------------
| FindGradientMinimum
|-------------------------------------------------------------
|
| PURPOSE: To use conjugate gradients to find a local 
|          minimum of a function.
|
| DESCRIPTION: This routine uses the general univariate 
| minimizers 'FindRoughGlobalMinimum' and 
| 'FindParabolicMinimum2' to minimize along the gradient line.  
|
| EXAMPLE: 
|
| NOTE: See also 'cg.c'. 
|
| ASSUMES: X is positive and solution is positive.
|          No part of X, X[i], can be less than the constant
|          held in 'FGM_MinXi' -- application specific.
|
| HISTORY: 05.19.97 from 'Advanced Algorithms For 
|                         Neural Nets', 'HiX'.
------------------------------------------------------------*/
f64 
FindGradientMinimum(
    s32     MaxIter,        // Iteration limit.
    f64     MaximumSatisfactoryY, // Quit if Y drops this low.
    f64     Epsilon,        // Smallest difference recognized 
                            // as a difference, but greater 
                            // than machine precision.
    f64     Tolerance,      // Convergence tolerance.
    f64     (*FofX)( f64* ),// Objective function of X without
                            // derivative calculation.
                            //
    f64     (*FofXd)( f64*, f64*, f64* ), 
                            // Objective function of X that 
                            // calculates the first and second
                            // derivatives at X.
                            //
    s32     DimCount,       // Number of dimensions in X.
    f64*    X,              // In/out of independent variable
    f64     StartY,         // Input of starting function value
    f64*    Base,           // Work vector DimCount long, 
                            // current origin point for search
                            //
    f64*    Direction,      // Work vector DimCount long, 
                            // current search direction 
                            // gradient.
                            //
    f64*    g,              // Work vector DimCount long, 
                            // g term of CG recurrence 
                            // relation.
                            //
    f64*    h,              // Work vector DimCount long, 
                            // h term of CG recurrence 
                            // relation.
                            //
    f64*    deriv2 )        // Work vector DimCount long, 
                            // 2nd derivative of current 
                            // point.
{
    s32  i, iter, IsQuit, ConvergenceCounter, PoorCJCounter;
    
    f64 fval, BestY, high, scale;
    f64 t1, t2, t3, y1, y2, y3;
    f64 LengthOfDirection, dot1, dot2;
    f64 PreviousBestY, toler, gam, improvement;

    // StartY is just a placeholder but the compiler complains
    // if it is not used. 
    StartY = StartY;

    // Set the smallest valid value for any X[i].  
    // This is application specific.
    FGM_MinXi = 1.e-10;
    
    // Make global reference to data needed by objective functions.
    FGM_X         = X;
    FGM_Base      = Base;
    FGM_Direction = Direction;
    FGM_DimCount  = DimCount;
    FGM_FofX      = FofX;
    FGM_FofXd     = FofXd;

    // Initialize that the user has not pressed ESCape.
    // Evaluate the function and, more importantly, its derivatives, 
    // at the starting point.  
    //
    // This call to FofX puts the gradient into Direction, but
    // we flip its sign to get the downhill search direction.
    //
    // Also initialize the CG algorithm by putting that vector in 
    // g and h.

    IsQuit = 0;
    
    BestY = (*FofXd)( X, Direction, deriv2 );
    
    PreviousBestY = 1.e30;
    
    for( i = 0; i < DimCount; i++ )
    {
        Direction[i] = -Direction[i];
    }
        
    CopyItems( Direction, g, DimCount );
    CopyItems( Direction, h, DimCount );

    // Main loop.  For safety we impose a limit on iterations.
    // There are two counters that have somewhat similar purposes.
    //
    // The first, ConvergenceCounter, counts how many times an iteration
    // failed to reduce the function value to the user's tolerance level.
    //
    // We require failure several times in a row before termination.
    //
    // The second, 'PoorCJCounter', has a generally higher 
    // ConfusionRejectCutoff.
    //
    // It keeps track of poor improvement, and imposes successively small
    // limits on Gamma, thus forcing the algorithm back to steepest
    // descent if CJ is doing poorly.
 
    ConvergenceCounter = 0;
    PoorCJCounter = 0;

    for( iter = 0; iter < MaxIter; iter++ ) 
    {
        // Do we satisfy user yet?
        if( BestY < MaximumSatisfactoryY )
        {     
            break;
        }

        // Convergence check

        // If the function is small.
        if( PreviousBestY <= 1.0 )
        {   
            // Work on absolutes.               
            toler = Tolerance;                            
        }
        else // But if it is large.
        {
            // Keep things relative.
            toler = Tolerance * PreviousBestY;
        }             

        // If little improvement.
        if( (PreviousBestY - BestY) <= toler ) 
        {  
            // Increment the convergence counter.
            ConvergenceCounter++;
            
            // Quit if no big improvement three
            // times in a row.
            if( ConvergenceCounter >= 3 )
            {      
                break;
            }                      
        }
        else // If a lot of improvement.
        {
            // Reset the convergence counter.    
            ConvergenceCounter = 0;
        }         

        // Here we do a few quick things for housekeeping.
        // We save the Base for the linear search in 'Base', which lets us
        // parameterize from t=0.
        // We find the greatest second derivative.  This makes an excellent
        // scaling factor for the search direction so that the initial global
        // search for a trio containing the minimum is fast.  Because this is so
        // stable, we use it to bound the generally better but unstable Newton scale.
        // We also compute the length of the search vector and its dot product with
        // the gradient vector, as well as the directional second derivative.
        // That lets us use a sort of Newton's method to help  us scale the
        // initial global search to be as fast as possible.  In the ideal case,
        // the 't' parameter will be exactly equal to 'scale', the center point
        // of the call to 'FindRoughGlobalMinimum'.

        dot1 = dot2 = LengthOfDirection = 0.0;        // For finding directional derivs


        // For scaling FindRoughGlobalMinimum
        high = 1.e-4;                         

        for( i = 0; i < DimCount; i++) 
        {
            // We step out from here.
            Base[i] = X[i];                 
            
            // Keep track of second derivatives for linear search 
            // via FindRoughGlobalMinimum
            if( deriv2[i] > high )
            {            
                high = deriv2[i];
            }
            
            // Directional first derivative.
            dot1 += Direction[i] * g[i];        
            
            // Directional second derivative.
            dot2 += Direction[i] * Direction[i] * deriv2[i]; 
            
            // Accumulate the length of the search vector.
            LengthOfDirection += Direction[i] * Direction[i];  
        }

        // Calculate length of the search vector.
        LengthOfDirection = sqrt ( LengthOfDirection );             

        // The search direction is in 'Direction' and the maximum 
        // second derivative is in 'high'. 
        //
        // That stable value makes a good approximate scaling factor.
        // The ideal Newton scaling factor is numerically unstable.
        //
        // So compute the Newton ideal, then bound it to be near the 
        // less ideal but far more stable maximum second derivative.
        //
        // Pass the first function value, corresponding to t=0, to 
        // the routine in *y2 and flag this by using a negative 'npts'.

        // Newton's ideal but unstable scale.
        scale = dot1 / dot2;
        
        // Less ideal but more stable heuristic.             
        high = 1.5 / high;
        
        // Subjectively keep it realistic.          
        if( high < 1.e-4)
        {                 
            high = 1.e-4;
        }

        // This is truly pathological.
        if( scale < 0.0 )
        {   
            // So stick with old reliable.  
            scale = high;
        }             
        else // Bound the Newton scale to be close to the stable scale.
             // Bound it both above and below.
        {
            if( scale < 0.1 * high )
            {   
                scale = 0.1 * high;
            }          
            else 
            {
                if( scale > 10.0 * high )
                {  
                    scale = 10.0 * high;
                }
            }
        }

        y2 = PreviousBestY = BestY;

        FindRoughGlobalMinimum( 0.0, 
                                2.0 * scale, 
                                3, 
                                0, 
                                MaximumSatisfactoryY,
                                FindLineMinimum, 
                                &t1, 
                                &y1, 
                                &t2,
                                &y2, 
                                &t3, 
                                &y3,
                                1 ); // First point is known.
                                    
        // good enough already?
        if( y2 < MaximumSatisfactoryY ) 
        { 
            // If global caused improvement.
            if( y2 < BestY ) 
            {   
                // Implement that improvement.            
                for( i = 0; i < DimCount; i++ ) 
                {         
                    X[i] = Base[i] + t2 * Direction[i];
                    
                    // Limit it away from zero
                    if( X[i] < FGM_MinXi )
                    {   
                        X[i] = FGM_MinXi;             
                    }
                }
                
                BestY = y2;
            }
            else // Else revert to starting point.
            {                                    
                CopyItems( Base, X, DimCount );
            }
            
            break;
        }

        // We just used a crude global strategy to find three points that
        // bracket the minimum.  Refine using Brent's method.
        //
        // If we are possibly near the end, as indicated by the 
        // 'ConvergenceCounter' being nonzero, then try extra hard.
 
        if( ConvergenceCounter )
        {
            BestY = FindParabolicMinimum2( 20, 
                                           MaximumSatisfactoryY, 
                                           Epsilon, 
                                           1.e-7,
                                           FindLineMinimum, 
                                           &t1, 
                                           &t2, 
                                           &t3, 
                                           y2 );
        }
        else // Not near the end so search more coarsely.
        {
            BestY = FindParabolicMinimum2( 10, 
                                           MaximumSatisfactoryY, 
                                           1.e-6, 
                                           1.e-5,
                                           FindLineMinimum, 
                                           &t1, 
                                           &t2, 
                                           &t3, 
                                           y2 );
        }
#if 0
        if( ConvergenceCounter )
        {
            BestY = FindParabolicMinimum(  
                        FindLineMinimum, 
                        t1, 
                        t2, 
                        t3, 
                        Tolerance,
                        &t2 );
        }
        else // Not near the end so search more coarsely.
        {
            BestY = FindParabolicMinimum(  
                        FindLineMinimum, 
                        t1, 
                        t2, 
                        t3, 
                        .00001,
                        &t2 );
        }
#endif
        // We just completed the global and refined search.
        //
        // Update the current point to reflect the minimum obtained.
        // Then evaluate the error and its derivatives there: the linear 
        // optimizers only evaluated the error, not its derivatives.
        //
        // If the user pressed ESCape during FindGradientMinimum, BestY 
        // will be returned negative.

        for( i = 0; i < DimCount; i++ ) 
        {
            X[i] = Base[i] + t2 * Direction[i];
            
            // Limit it away from zero
            if( X[i] < FGM_MinXi )
            {   
                // Application specific lower limit on parts of X.  
                X[i] = FGM_MinXi;             
            }
        }

        improvement = (PreviousBestY - BestY) / PreviousBestY;

        // Do we satisfy user yet?
        if( BestY < MaximumSatisfactoryY )
        {     
            break;
        }
        
        // Need derivs now.
        fval = (*FofXd)( X, Direction, deriv2 );
        
        // Flip the sign to get negative gradient.
        for( i = 0; i < DimCount; i++ )
        {                         
            Direction[i] = -Direction[i];
        }                        
        
        // If user pressed ESCape.
        if( fval < 0.0 ) 
        {                                 
            IsQuit = 1;
            break;
        }

//      Note( "t=%lf f=%le improvement=%lf%%",
//            t2 / scale, fval, 100.0 * improvement );
 
        gam = Gamma( DimCount, g, Direction );

        // Limit gamma to non-negative values less than or equal
        // to 10.
        if( gam < 0.0 )
        {
            gam = 0.0;
        }
        else
        {
            if( gam > 10.0 )
            {                
                gam = 10.0;
            }
        }

        // Count how many times we got poor improvement in a row.
        if( improvement < 0.001 )
        {    
            PoorCJCounter++;
        }        
        else // Got good improvement this time.
        {                            
            PoorCJCounter = 0;
        }

        // If several times.
        if( PoorCJCounter >= 2 ) 
        { 
            // limit Gamma.
            if( gam > 1.0)
            {             
                gam = 1.0;
            }
        }

        // If too many times
        if( PoorCJCounter >= 6 ) 
        { 
            // set Gamma to 0 to use steepest descent (gradient).
            PoorCJCounter = 0;
             
            gam = 0.0; 
        }

        // Compute next search direction that is conjugate to the 
        // current direction as much as possible so that back-tracking 
        // is minimized.
        //
        // Uses recurrence procedure explained on page 422 of 
        // 'Numerical Recipies in C'. 
  
        for( i = 0; i < DimCount; i++ ) 
        {
            g[i] = Direction[i];
        
            h[i] = g[i] + gam * h[i];
        
            Direction[i] = h[i];
        }

    } // Main loop

    if( IsQuit )
    {
        return -BestY;
    }
    else
    { 
        return BestY;
    }
}

/*------------------------------------------------------------
| FindLineMinimum
|-------------------------------------------------------------
|
| PURPOSE: To evaluate the objective function at a point 
|          relative to the current base and in the current
|          search direction.
|
| DESCRIPTION: This routine is called by 
|              'FindGradientMinimum'. 
|
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: FGM_X, FGM_DimCount, FGM_Base, FGM_Direction,
|          FGM_MinXi, FGM_FofX.
|
| HISTORY: 05.19.97 from 'Advanced Algorithms For 
|                         Neural Nets'.
------------------------------------------------------------*/
f64 
FindLineMinimum( f64 t )
{
    s32 i;
    
    // Calculate a new X point relative to the current origin
    // in the current search direction.
    for( i = 0; i < FGM_DimCount; i++ ) 
    {
        FGM_X[i] = FGM_Base[i] + t * FGM_Direction[i];
        
        // Limit the parts of X to a certain minimum size.
        if( FGM_X[i] < FGM_MinXi )
        {
            FGM_X[i] = FGM_MinXi;
        }
    }
    
    // Call the multidimensional objective function without
    // calculating derivatives.
    return( (*FGM_FofX)( FGM_X ) );
}

/*------------------------------------------------------------
| FindLocalMinimum
|-------------------------------------------------------------
|
| PURPOSE: To find the x value that produces the minimum
|          y value of a given function found by stepping
|          from a starting x.
|
| DESCRIPTION: Given a concave function and a starting 'x'
| value, this procedure walks down the slope step-by-step
| until the 'x' value is found that produces the least 'y'
| value.
|  
| 'Tolerance' is used as the step size.
|
| If no minimum is found after a given number of iterations,
| then the best value is returned.
|
| EXAMPLE:  
|
| f64 MyFunc(f64 X) ( return( 4.004+X^2 ) );
|
| ymin = FindLocalMinimum(
|                          MyFunc,  // FofX
|                          0,       // X
|                          .0001,   // Tolerance
|                          100,     // MaxIterations
|                          &xmin ); // Result X min
|
| NOTE:  
|
| ASSUMES: Function is locally concave.
|
| HISTORY:  08.01.96 from 'FindRandomMinimum'.
|           08.03.96 added 'Tolerance'; changed to pseudo-
|                    random from subrandom.
|           08.06.96 added 'StepFactor' for speed.
------------------------------------------------------------*/
f64    
FindLocalMinimum( f64 (*FofX)(f64), 
                  f64  X, 
                  f64  Tolerance, 
                  s32   MaxIter,
                  f64* xmin )
{   
    s32     i;
    f64    BestX, BestY, NewX, NewY;
    f64 Step, TurnCount, StepFactor;
    
    // Make step initially positive tolerance.
    Step = Tolerance;
    StepFactor = 1.0;
    TurnCount = 0; 
    
    // Compute an initial best value and save the x value.  
    BestX = X;
    BestY = (*FofX)(BestX);
    
    // For each iteration.
    for( i = 1; i < MaxIter; i++ )
    {
        // Try a new point.
        NewX = BestX + Step * StepFactor;
        NewY = (*FofX)(NewX);
    
        // If this point is better, save it.
        if( NewY < BestY )
        {
            BestY = NewY;
            BestX = NewX;
            
            // Increase the step size.
            StepFactor++;
        }
        else // Try reducing step size or walking the other way.
        {
            // If the StepFactor is greater than 1.0
            // reduce it to 1.0 and try again.
            if( StepFactor > 1.0 )
            {
                StepFactor = 1.0;
            }
            else
            {
                // Only change directions once.
                if( TurnCount )
                {
                    goto Done;
                }
            
                // Reverse directions.
                Step = -Step;
                TurnCount++;
            }
        }
    }

Done:

    *xmin = BestX;

    return( BestY );
}

/*------------------------------------------------------------
| FindParabolicMinimum
|-------------------------------------------------------------
|
| PURPOSE: To find the minimum x value of a given function.
|
| DESCRIPTION: Given a function Ÿ, and a bracketing triplet of
| x values (abscissas) XLo, XMid, XHi (such that XMid is 
| between XLo and XHi, and Ÿ(XMid) is less than both Ÿ(XLo) 
| and Ÿ(XHi)), this procedure isolates the minimum to a 
| fractional precision of about Tolerance using Brent's method.
|  
| The abscissa (x value) of the minimum is returned in *xmin,
| and the ordinate (y value) of the minimum is returned
| as the function return value.
|
| EXAMPLE:  
|
| f64 MyFunc(f64 X) ( return( 4.004+X^2 ) );
|
| ymin = FindParabolicMinimum(
|                          MyFunc,  // FofX
|                          -5,      // XLo
|                          1,       // XMid
|                          5,       // XHi
|                          .01,     // Tolerance
|                          &xmin ); // Result X min
|
| NOTE: See "Numerical Recipes In C", page 402 for details of 
|       algorithm.
|
| ASSUMES: The given function is roughly parabolic. 
|
| HISTORY:  05.23.92 
|           03.29.96 converted from Mathematica, updated to
|                    "Numerical Recipes In C".
------------------------------------------------------------*/
f64    
FindParabolicMinimum(  f64 (*FofX)(f64), 
                       f64  XLo, 
                       f64  XMid, 
                       f64  XHi, 
                       f64  Tolerance,
                       f64* xmin )
{   
    s32 iter;
    f64 a,b,d,etemp,fu,fv,fw,fx,p,q,r,tol1,tol2,u,v,w,x,xm;
    f64 e=0.0; // This will be the distance moved on the
                // step before last.
    f64 MaxIterations;
    f64 Golden;
    f64 Zeps;
               
    MaxIterations = 100; 
    Golden        = .381966; // Golden ratio.
    Zeps          = 1.0e-10; 
         // a small number which protects against trying
         // to acheive fractional accuracy for a minimum
         // that happens to be exactly zero. 
         //
    
    // 'a' and 'b' must be in ascending order, but inputs 
    // need not be.
    a = XLo;
    b = XHi;
    if( XLo > XHi )
    {
        a = XHi;
        b = XLo;
    }
    
    x = w = v = XMid;
    fw = fv = fx = (*FofX)(x);
    
    // Main loop.
    for( iter = 1; iter <= MaxIterations; iter++ )
    {
        // printf( "Iter: %d x= %f",iter,x); 
        
        xm = 0.5 * (a + b);
             
        tol1 = Tolerance * fabs(x) + Zeps;
        tol2 = 2.0 * tol1;
        
        // Test for done here.
        if( fabs(x - xm) <= ( tol2 - 0.5*(b - a) ) )
        {
            *xmin = x; // Return the result.
            return( fx );
        }
        
        // Construct a trial parabolic fit.
        if( fabs(e) > tol1 )
        {
            r = (x-w) * (fx-fv);
            q = (x-v) * (fx-fw);
            p = (x-v) * q - (x-w)*r;
            q = 2.0 * (q-r);
    
            if( q > 0 )
            {
                p = -p;
            }
            else
            {
                q = fabs(q);
            }
            
            etemp = e;
            e = d;
     
            // These conditions determine the acceptability
            // of the the parabolic fit.
            if( fabs(p) >= fabs(0.5 * q * etemp ) || 
                p <= q * (a-x) || 
                p >= q * (b-x) )
            {
                // Here we take the golden section step into
                // the larger of the two segments.
                e = ( x >= xm ? a-x : b-x );
                d = Golden * e;
            }
            else // Take the parabolic step.
            {
                d = p / q; 
                u = x + d;

                if( u - a < tol2 || b - u < tol2 )
                {
                    d = ( xm-x >= 0.0 ? fabs(tol1) : -fabs(tol1));
                }
            }
        }
        else
        {
            // Here we take the golden section step into
            // the larger of the two segments.
            e = ( x >= xm ? a-x : b-x );
            d = Golden * e;
        }
            
        // Arrive here with 'd' computed either from
        // parabolic fit, or else from golden section.
    
        if( fabs(d) >= tol1 )
        {
            u = x + d;
        }
        else
        {
            u = x + ( d >= 0.0 ? fabs(tol1) : -fabs(tol1) );
        }
        
        fu = (*FofX)(u); // This is the one function
                         // evaluation per iteration, and
                         // now we have to decide what to do
                         // with our function evaluation.
                      
        // printf( "fu= %f  u= %f", fu, u ); 
     
        if( fu <= fx )
        { 
            if( u >= x )
            {
                a = x;
            }
            else
            {
                b = x;
            }
            v = w;
            w = x;
            x = u;
             
            fv = fw; 
            fw = fx; 
            fx = fu; 
        }
        else  
        { 
            if( u < x )
            { 
                a = u;
            } 
            else
            {
                b = u;
            }   
        
            if( fu <= fw || w == x )
            {
                v = w; 
                w = u; 
                fv = fw; 
                fw = fu;
            }
            else
            {
                if( fu <= fv || v == x || v == w )
                {
                    v = u; 
                    fv = fu;
                }
            }
        }
    }
        
    printf("Exceeded MaxIterations in FindParabolicMinimum.");
    *xmin = x;
    
    return( fx );
}

/*------------------------------------------------------------
| FindParabolicMinimum2
|-------------------------------------------------------------
|
| PURPOSE: To use Brent's method to find a local minimum of a 
|          univariate function.
|
| DESCRIPTION: This is given three points such that the center 
| has lesser function value than its neighbors.  It 
| iteratively refines the interval. 
|
| If the objective function drops to MaximumSatisfactoryY or 
| smaller, execution will terminate.     
|
| EXAMPLE: 
|
| NOTE: See also 'FindParabolicMinimum' for another version
|       of this algorithm.
|
| ASSUMES: 
|
| HISTORY: 05.15.97 from 'Advanced Algorithms For Neural
|                         Networks'.
------------------------------------------------------------*/
f64 
FindParabolicMinimum2(
    s32   itmax,            // Iteration limit
    f64  MaximumSatisfactoryY, // Quit if crit drops this low
    f64  eps,               // Small, but greater than machine precision
    f64  tol,               // Brent's tolerance (>= sqrt machine precision)
    f64  (*criter) (f64), // Criterion function
    f64* x1,                // Lower X value, input and output
    f64* x2,                // Middle (best), input and output
    f64* x3,                // And upper, input and output
    f64  y  )               // Function value at x2
{
    s32  iter, IsQuit;
    f64 prevdist, step, xlow, xmid, xhigh, tol1, tol2;
    f64 xbest, xsecbest, xthirdbest, BestY, fsecbest, fthirdbest;
    f64 numer, denom, testdist, xrecent, frecent, t1, t2;
//  s8   msg[160];

    // Initialize prevdist, the distance moved on the previous 
    // step, to 0 so that the 'if( fabs(  prevdist )  >  tol1)' 
    // encountered on the first iteration below will fail, 
    // forcing a golden section the first time.  Also 
    // initialize step to 0 to avoid a zealous compiler 
    // from pointing out that it was referenced before 
    // being set.

    prevdist = step = 0.0;

    // We always keep the minimum bracketed between xlow 
    // and xhigh. xbest has the min function ordinate so far 
    // (or latest if tie).  xsecbest and xthirdbest are the 
    // second and third best.

    xbest = xsecbest = xthirdbest = *x2;
    xlow  = *x1;
    xhigh = *x3;

    BestY = fsecbest = fthirdbest = y;


    // Main loop.  For safety we impose a limit on iterations.
    
    for( iter=0; iter<itmax; iter++) 
    {

//      sprintf( msg, 
//               "%.9lf %.9lf %.9lf :  %.6lf %.6lf %.6lf",
//               xlow, xbest, xhigh, 
//               BestY, fsecbest, fthirdbest );
//               
//      write_progress( msg );

        // Do we satisfy user yet?
        if( BestY < MaximumSatisfactoryY )   
        {
            break;
        }

        xmid = 0.5 * (xlow + xhigh);
        tol1 = tol * (fabs(  xbest ) + eps);
        tol2 = 2. * tol1;

        // The following convergence test simultaneously 
        // makes sure xhigh and xlow are close relative to tol2, 
        // and that xbest is near the midpoint.
 
        if( fabs(  xbest - xmid )  <=  (tol2 - 0.5 * (xhigh - xlow)))
        {
            break;
        }

        // Avoid refining function to limits of precision
        if( (iter >= 2)  &&  ((fthirdbest - BestY) < eps))
        {
            break;
        }

        // If we moved far enough try parabolic fit.
        if( fabs(  prevdist )  >  tol1) 
        {  
            // Temps for the parabolic estimate.
            t1 = (xbest - xsecbest) * (BestY - fthirdbest); 
            t2 = (xbest - xthirdbest) * (BestY - fsecbest);
            
            numer = (xbest - xthirdbest) * t2  -  
                    (xbest - xsecbest)   * t1;
            
            // Estimate will be numer / denom.   
            denom = 2. * (t1 - t2);  
            
             // Will soon verify interval is shrinking.
            testdist = prevdist;
            
            // Save for next iteration.  
            prevdist = step;            

            // Avoid dividing by zero.
            if( denom != 0.0 )
            {
                // This is the parabolic estimate to min.
                step = numer / denom;
            } 
            else
            {
                // Assures failure of next test.
                step = 1.e30;
            }       
            
            // If shrinking and within known bounds.
            if( ( fabs( step ) < fabs( 0.5 * testdist ) ) && 
                (step + xbest > xlow)                     && 
                (step + xbest < xhigh) ) 
            {           
                // Then we can use the parabolic estimate.
                xrecent = xbest + step; 
                
                
                // If we are very close to known bounds then stabilize. 
                if( ( xrecent - xlow  <  tol2 )  ||  
                    ( xhigh - xrecent <  tol2 ) ) 
                {    
                    if( xbest < xmid )
                    {
                        step = tol1;
                    }
                    else
                    {
                        step = -tol1;
                    }
                }
            }
            else // Parabolic estimate poor, so use golden section.
            {  
                // Poor so use.
                prevdist = (xbest >= xmid)  ?  xlow - xbest  :  xhigh - xbest;
                     
                step = .3819660 * prevdist;
            }
        }
        else // prevdist did not exceed tol1: we did not move far enough
             // to justify a parabolic fit.  Use golden section.
        { 
            prevdist = (xbest >= xmid)  ?  xlow - xbest  :  xhigh - xbest;
            
            step = .3819660 * prevdist;
        }

        // In order to numerically justify another trial we must move a
        // decent distance.
        if( fabs( step ) >= tol1 )
        {     
            xrecent = xbest + step;
        }
        else 
        {                                
            if( step > 0.)
            {
                xrecent = xbest + tol1;
            }
            else
            {
                xrecent = xbest - tol1;
            }
        }

        // At long last we have a trial point 'xrecent'.  
        // Evaluate the function.
 
        frecent = criter( xrecent );

        if( frecent < 0.0 ) 
        {
            IsQuit = 1;
            break;
        }
        
        // If we improved...
        if( frecent <= BestY ) 
        {   
            // Shrink the (xlow,xhigh) interval by replacing the 
            // appropriate endpoint.
            if( xrecent >= xbest )
            {
                xlow = xbest;
            }        
            else
            {
                xhigh = xbest;
            }
            
            // Update x and f values for best, second and third best.
            xthirdbest = xsecbest; 
            xsecbest   = xbest;      
            xbest      = xrecent;
            fthirdbest = fsecbest;
            fsecbest   = BestY;
            BestY      = frecent;
        }
        else // We did not improve.
        {   
            // Shrink the (xlow,xhigh) interval by replacing the 
            // appropriate endpoint.            
            if( xrecent < xbest )
            { 
                xlow = xrecent;
            }  
            else
            {
                xhigh = xrecent;
            }
            
            // If we at least beat the second best or we had a duplication
            // we can update the second and third best, though not the best.
            //
            // Recall that we started iters with best, sec and third all equal.
            if( (frecent <= fsecbest) || (xsecbest == xbest) ) 
            {  
                xthirdbest = xsecbest; 
                xsecbest   = xrecent;      
                fthirdbest = fsecbest;  
                fsecbest   = frecent;     
            }
            else 
            {
                // Oh well.  Maybe at least we can beat the third best or rid
                // ourselves of a duplication, which is how we start the 
                // iterations.
                if( (frecent <= fthirdbest) || 
                    (xthirdbest == xbest)   || 
                    (xthirdbest == xsecbest) ) 
                {  
                    xthirdbest = xrecent; 
                    fthirdbest = frecent; 
                }
            }
        }
    }
 
    *x1 = xlow;
    *x2 = xbest;
    *x3 = xhigh;

    // Why this?
//  if( IsQuit ) BestY = -BestY;
    
    return( BestY );
}

/*------------------------------------------------------------
| FindSimplexMinimum
|-------------------------------------------------------------
|
| PURPOSE: To find the minimum of a multidimensional function.
|
| DESCRIPTION: Multidimensional minimization of a function
| where 'x[1....DimCount]' is a vector in 'DimCount' 
| dimensions, by the downhill simplex method of Nelder and 
| Mead.  
|
| The matrix 'Vertex[1...DimCount+1][1...DimCount]' is input.  
| 
| Its DimCount+1 rows are DimCount-dimensional vectors which 
| are the vertices of the starting simplex.  
|
| Also input is the vector 'y[1..DimCount+1]', whose components 
| must be pre-initialized to the values of the function 
| evaluated at the DimCount+1 vertices(rows) of 'Vertex'.
|
| 'Tolerance' is the fractional convergence tolerance to be 
| acheived in the function value.  
|
| On output, 'Vertex' and 'y' will have been reset to 
| DimCount+1 new points all within 'Tolerance' of a minimum 
| function value, and 'EvalCount' gives the number of function 
| evaluations taken.
|
| EXAMPLE:  
|
| f64 MyFunc(f64* X) ( return( SumItems( X, ItemCount) ) );
|
| ymin = FindSimplexMinimum(
|                          MyFunc,  // FofX
|                          Vertex,  // Vertex
|                          Ys,      // Y vector
|                          .01 );   // Tolerance
|
| NOTE: See "Numerical Recipes In C", page 411 for details of 
|       algorithm.
|
| ASSUMES: 
|
| HISTORY: 03.30.96 Copied from "Numerical Recipes In C".
|          04.01.96 Tested using 'TestFindSimplexMinimum' OK.
------------------------------------------------------------*/

s32 // 'EvalCount' is returned.    
FindSimplexMinimum( f64    (*FofX)(f64*),
                    Matrix* Vertex,
                    Vector* Y,
                    f64    Tolerance )
{
    s32     i,j,LoY,NextHiY,VertexCount;
    f64     rtol,sum,ysave,ytry,t;
    f64     MaxIterations;
    s32     EvalCount;
    
    // Set the upper limit on evaluations.
    MaxIterations = 5000; 

    // Clear the evaluation counter.
    EvalCount = 0;
    
    // Get the number of dimensions.
    FSM_DimCount = Vertex->ColCount;
    
    // Set the vertex count.
    VertexCount = FSM_DimCount+1;
    
    // Refer to the matrix data.
    FSM_Vertex = (f64**) Vertex->a;
    
    // Refer to the evaluation result for each vertex.
    FSM_Y = Y->Y;
    
    // Refer to the objective function.
    FSM_FofX = FofX;
    
    // Allocate a buffer to hold vertex sums.
    FSM_DimSum = MakeItems( FSM_DimCount, 0 );
    
    // Make a buffer for the trial point.
    FSM_TrialPoint = MakeItems( FSM_DimCount, 0 );
    
    // For each dimension
    for( j = 0; j < FSM_DimCount; j++ )
    {
        sum = 0;
        
        // For each vertex
        for( i = 0; i < VertexCount; i++ )
        {
            sum += FSM_Vertex[i][j];
        }
        
        // Accumulate the dimension sum.
        FSM_DimSum[j] = sum;
    }
    
    while(1)
    {
        LoY = 0; // Set default, update in the following loop.
        
        // First we must determine which point is the highest
        // (worst), next-highest, and lowest (best), by 
        // looping over the points in the simplex.
        
        if( FSM_Y[0] > FSM_Y[1] )
        {
            FSM_HiY = 0;
            NextHiY = 1;
        }
        else
        {
            FSM_HiY = 1;
            NextHiY = 0;
        } 
        
        for( i = 0; i < VertexCount; i++ )
        {
            if( FSM_Y[i] <= FSM_Y[LoY] )
            { 
                LoY = i;
            }
            
            if( FSM_Y[i] > FSM_Y[ FSM_HiY ] )
            {
                NextHiY = FSM_HiY;
                FSM_HiY=i;
            }
            else
            {
                if( FSM_Y[i] > FSM_Y[NextHiY] && i != FSM_HiY ) 
                {
                    NextHiY = i;
                }
            }
        }
        
        // Compute the fractional range from highest to lowest
        // and return if satisfactory.
        rtol = fabs( FSM_Y[FSM_HiY] - FSM_Y[LoY] );
        
//      rtol = 2.0 * fabs( FSM_Y[FSM_HiY] - FSM_Y[LoY] ) / 
//             ( fabs( FSM_Y[FSM_HiY] ) + fabs( FSM_Y[LoY] ) );
// This can produce division by very small number and mess things
// up.

        if( rtol < Tolerance )
        {
            // If returning, put best point and value in 
            // slot 0.
            t = FSM_Y[0]; 
            FSM_Y[0] = FSM_Y[LoY]; 
            FSM_Y[LoY] = t;
            
            for( i = 0; i < FSM_DimCount; i++ ) 
            {
                t = FSM_Vertex[0][i];
                FSM_Vertex[0][i] = FSM_Vertex[LoY][i];
                FSM_Vertex[LoY][i] = t;
            }
            
            goto Done; // Clean up.
        }
        
        if( EvalCount >= MaxIterations )
        {
            printf( "NMAX exceeded" );
            
            // But do we bail here?
        }
        
        EvalCount += 2;
        
        // Begin a new iteration.  First extrapolate by a 
        // factor -1 through the face of the simplex across
        // from the high point, i.e., reflect the simplex
        // from the high point.
        
        ytry = TrySimplex(-1.0);
        
        if( ytry <= FSM_Y[LoY] )
        {
            // Gives a result better than the best point, so
            // try an additional extrapolation by a factor 2.
            ytry = TrySimplex(2.0);
            
        }
        else
        {
            if( ytry >= FSM_Y[NextHiY] )
            {
                // The reflected point is worse than the
                // second-highest, so look for an intermediate
                // lower point, i.e., do a one-dimensional
                // contraction.
                
                ysave = FSM_Y[FSM_HiY];
                ytry = TrySimplex(0.5);
                
                if( ytry >= ysave )
                {
                    // Can't seem to get rid of that high point.
                    // Better contract around the lowest (best)
                    // point.
                    
                    for( i = 0; i < VertexCount; i++ )
                    {
                        if( i != LoY )
                        {
                            for( j = 0; j < FSM_DimCount; j++ )
                            {
                                FSM_Vertex[i][j]  = 
                                FSM_TrialPoint[j] =
                                    0.5 * 
                                    ( FSM_Vertex[i][j] + 
                                      FSM_Vertex[LoY][j] );
                            }
                            
                            FSM_Y[i] = (*FofX)(FSM_TrialPoint);
                            
                            // The test procedure may normalize the point.
                            // Update the copy of the point in the vertex.
                            for( j = 0; j < FSM_DimCount; j++ )
                            {
                                FSM_Vertex[i][j] = FSM_TrialPoint[j];
                            }
                        }
                    }
                    
                    EvalCount += FSM_DimCount; // Keep track of function
                                               // evaluations.

                    // For each dimension
                    for( j = 0; j < FSM_DimCount; j++ )
                    {
                        sum = 0;
        
                        // For each vertex
                        for( i = 0; i < VertexCount; i++ )
                        {
                            sum += FSM_Vertex[i][j];
                        }
        
                        // Accumulate the dimension sum.
                        FSM_DimSum[j] = sum;
                    }
    
                }
            }
            else
            {
                --(EvalCount); // Correct the evaluation count.
            }
        }
    }
    
Done:
    
    free( FSM_DimSum );
    free( FSM_TrialPoint );
    
    return( EvalCount );
}

/*------------------------------------------------------------
| FindSubRandomMinimum
|-------------------------------------------------------------
|
| PURPOSE: To find the minimum x value of a given function.
|
| DESCRIPTION: Given a function Ÿ, and a bracketing triplet of
| x values (abscissas) XLo, XMid, XHi (such that XMid is 
| between XLo and XHi, and Ÿ(XMid) is less than both Ÿ(XLo) 
| and Ÿ(XHi)), this procedure isolates the minimum to a 
| fractional precision of about Tolerance by subrandomly
| sampling from the interval and choosing the best.
|  
| The abscissa (x value) of the minimum is returned in *xmin,
| and the ordinate (y value) of the minimum is returned
| as the function return value.
|
| EXAMPLE:  
|
| f64 MyFunc(f64 X) ( return( 4.004+X^2 ) );
|
| ymin = FindSubRandomMinimum(
|                          MyFunc,  // FofX
|                          -5,      // XLo
|                          1,       // XMid
|                          5,       // XHi
|                          .01,     // Tolerance
|                          &xmin ); // Result X min
|
| NOTE:  
|
| ASSUMES:  
|
| HISTORY:  07.27.96 from 'FindParabolicMinimum'.
------------------------------------------------------------*/
f64    
FindSubRandomMinimum(  f64 (*FofX)(f64), 
                       f64  XLo, 
                       f64  XMid, 
                       f64  XHi, 
                       f64  MaxIterations,
                       f64* xmin )
{   
    s32 i, MaxIter;
    f64 Lo, Hi, BestX, BestY, NewX, NewY;
               
    // 'Lo' and 'Hi' must be in ascending order, but inputs 
    // need not be.
    Lo = XLo;
    Hi = XHi;
    if( XLo > XHi )
    {
        Lo = XHi;
        Hi = XLo;
    }
    
    BestX = XMid;
    BestY = (*FofX)(BestX);
    
    // Main loop.
    MaxIter = (s32) MaxIterations;
    for( i = 0; i < MaxIter; i++ )
    {
        // printf( "Iter: %d x= %f",iter,x); 
        
        NewX = SubRandomValueFromRange(Lo, Hi);
        NewY = (*FofX)(NewX);
        
        if( NewY < BestY )
        {
            BestY = NewY;
            BestX = NewX;
        }
    }

    *xmin = BestX;

    return( BestY );
}

/*------------------------------------------------------------
| FindRandomMinimum
|-------------------------------------------------------------
|
| PURPOSE: To find the x value that produces the minimum
|          y value of a given function.
|
| DESCRIPTION: Given a function Ÿ, and bracketing x values
| Lo and Hi this procedure isolates the minimum by 
| randomly sampling from potential ranges and then
| randomly sampling the range, saving the best x.
|  
| Each time a better x is found, it is saved as a potential
| boundary.  Thus there is a tendency to search the best
| areas more intensely without eliminating any part of the
| initial range.  This reduces the required number of 
| iterations to reach the same precision.
|
| Tolerance limits how close boundaries can approach one
| another.
|
| EXAMPLE:  
|
| f64 MyFunc(f64 X) ( return( 4.004+X^2 ) );
|
| ymin = FindRandomMinimum(
|                          MyFunc,  // FofX
|                          -5.,     // Lo
|                          5.,      // Hi
|                          .0001,
|                          100,     // MaxIterations
|                          &xmin ); // Result X min
|
| NOTE: Maybe this algorithm mimics the way the market 
|       searches for prices.
|
| ASSUMES: 'Lo' and 'Hi' in ascending order. 
|
| HISTORY:  08.01.96 from 'FindSubRandomMinimum'.
|           08.03.96 added 'Tolerance'; changed to pseudo-
|                    random from subrandom.
|           09.14.96 added '=' to test of min range size.
------------------------------------------------------------*/
f64    
FindRandomMinimum(  f64 (*FofX)(f64), 
                    f64  Lo, 
                    f64  Hi, 
                    f64  Tolerance, 
                    s32   MaxIter,
                    f64* xmin )
{   
    s32     i;
    f64    BestX, BestY, NewX, NewY, A, B;
    f64*    Bounds;
    s32     BoundsCount;
    
    // Make a buffer large enough to hold the best boundaries.
    Bounds = MakeItems( MaxIter, 0 );
    
    // Put the given boundaries into the buffer. 
    Bounds[0] = Lo;
    Bounds[1] = Hi;
    
    // Compute an initial best value and save the x value.  
    BestX = (Hi - Lo)/2.;
    BestY = (*FofX)(BestX);
    
    // Add the middle bound too.
    Bounds[2] = BestX;
    BoundsCount = 3;
    
    // For each iteration.
    for( i = 1; i < MaxIter; i++ )
    {
    
AnotherBound:

        // Randomly draw a boundaries from the buffer.
        A = Bounds[ RandomInteger( BoundsCount ) ];
        B = Bounds[ RandomInteger( BoundsCount ) ];
        
        // Assign 'A' and 'B' to the high and low extremes.
        if( A < B )
        {
            Lo = A;
            Hi = B;
        }
        else
        {
            Lo = B;
            Hi = A;
        }
        
        // If the range is not more than the tolerance, choose 
        // other bounds.
        if( (Hi - Lo) <= Tolerance )
        {
            goto AnotherBound;
        }
        
        // Sample the range.
        NewX = RandomValueFromRange(Lo, Hi);
        NewY = (*FofX)(NewX);
        
        // If this is an improvement, save it.
        if( NewY < BestY )
        {
            BestY = NewY;
            BestX = NewX;
            
            // Add a new bound to the buffer.
            Bounds[BoundsCount] = NewX;
            BoundsCount++;
        }
    }

    *xmin = BestX;

    free( Bounds );
    
    return( BestY );
}

/*------------------------------------------------------------
| FindRandomMultiDimensionalMinimum
|-------------------------------------------------------------
|
| PURPOSE: To find the x value that produces the minimum
|          y value of a given function.
|
| DESCRIPTION: Given a function Ÿ, and bracketing x values
| Lo and Hi this procedure isolates the minimum by 
| randomly sampling from potential ranges and then
| randomly sampling the range, saving the best x.
|  
| Each time a better x is found, it is saved as a potential
| boundary.  Thus there is a tendency to search the best
| areas more intensely without eliminating any part of the
| initial range.  This reduces the required number of 
| iterations to reach the same precision.
|
| Tolerance limits how close boundaries can approach one
| another.
|
| EXAMPLE:  
|
| f64 Lo[2];
| f64 Hi[2];
| f64 xmin[2];
| s32  DimCount;
|
| DimCount = 2;
|
| Lo[0] = 0.; Lo[1] = 0.;
| Hi[0] = 1.; Hi[1] = 1.;
| 
| f64 MyFunc() ( return( FRMD_X[0] * FRMD_X[1] - .5 ) );
|
| ymin = FindRandomMultiDimensionalMinimum(
|                          MyFunc,  // FofX
|                          Lo,      // Lo
|                          Hi,      // Hi
|                          .0001,   // Tolerance
|                          100,     // MaxIterations
|                          xmin,    // Result X min
|                          DimCount ); 
|
| NOTE: Allocates working memory equal to MaxIter *
|       DimCount * sizeof(f64). 
|
| ASSUMES: Each 'Lo' less than cooresponding 'Hi'.
|          Less than 100 dimensions. 
|
| HISTORY: 07.31.96 from 'FindRandomMinimum'.
------------------------------------------------------------*/
f64    
FindRandomMultiDimensionalMinimum(  
    f64    (*FofX)(), 
    f64*   Lo, 
    f64*   Hi, 
    f64    Tolerance, 
    s32    MaxIter,
    f64*   xmin,
    s32    DimCount )
{   
    s32     i, d;
    f64     BestX[100], BestY, NewX[100], NewY, A, B, lo, hi;
    Matrix* Bnds;
    f64**   Bound;
    s32     BoundsCount;
    s32     BoundsMax;
    
    // Make global reference to data needed by objective functions.
    FRMD_DimCount = DimCount;
  
    // Calculate the maximum number of boundaries to be tracked.
    BoundsMax = min( 1000, MaxIter );
    
    // Allocate array for best boundary values, one row per
    // dimension.
    Bnds = MakeMatrix( (s8*) "", DimCount, BoundsMax );
    
    // Refer to the matrix data.
    Bound = (f64**) Bnds->a;
    
    // Put the given boundaries into the buffer.
    for( i = 0; i < DimCount; i++ )
    {
        Bound[i][0] = Lo[i];
        Bound[i][1] = Hi[i];
        
        // Compute initial best value in middle of the given 
        // range.
        BestX[i] = (Hi[i] - Lo[i])/2.;
        
        // Add the middle bound too.
        Bound[i][2] = BestX[i];
    }
    
    // Track the number of boundaries in the buffer.
    BoundsCount = 3;
    
    // Compute an initial best value in the middle of the given
    // range.
    FRMD_X        = BestX;
    BestY = (*FofX)(BestX);
    FRMD_X        = NewX;
    
    // For each iteration.
    for( i = 1; i < MaxIter; i++ )
    {
        // For each dimension.
        for( d = 0; d < DimCount; d++ )
        {
        
AnotherBound:

            // Randomly draw a boundaries from the buffer.
            A = Bound[d][ RandomInteger( BoundsCount ) ];
            B = Bound[d][ RandomInteger( BoundsCount ) ];
        
            // Assign 'A' and 'B' to the high and low extremes.
            if( A < B )
            {
                lo = A;
                hi = B;
            }
            else
            {
                lo = B;
                hi = A;
            }
        
            // If the range is not more than the tolerance, choose 
            // other bounds.
            if( (hi - lo) <= Tolerance )
            {
                goto AnotherBound;
            }
        
            // Sample the range.
            NewX[d] = RandomValueFromRange(lo, hi);
        }
        
        // Try a new set of parameters.
        NewY = (*FofX)(NewX);
        
        // If this is an improvement, save it.
        if( NewY < BestY )
        {
            BestY = NewY;

printf( "Y = %lf   ", BestY );
            
            // For each dimension.
            for( d = 0; d < DimCount; d++ )
            {
                BestX[d] = NewX[d];
                
printf( "X[%d] = %lf   ", d, BestX[d] );
            
                // Add a new bound to the buffer.
                Bound[d][BoundsCount] = NewX[d];
            }
            
printf( "\n" );
            
            BoundsCount++;
        }
    }

    // Return the results.
    
    // For each dimension.
    for( d = 0; d < DimCount; d++ )
    {
        xmin[d] = BestX[d];
    }
    
    DeleteMatrix( Bnds );
    
    return( BestY );
}

/*------------------------------------------------------------
| FindRoughGlobalMinimum
|-------------------------------------------------------------
|
| PURPOSE: To check equispaced intervals to find rough global 
|          minimum of a univariate function.
|
| DESCRIPTION: This is called with a lower and upper bound for 
| the domain to be searched.  If the function is still 
| decreasing at one of these endpoints the search will 
| continue beyond the specified endpoint.
|                         
| The total interval is equally divided into npts-1 
| subintervals.
|
| These subintervals will be spaced arithmetically or 
| logarithmically according to log_space.
|                                                                    
| If the objective function drops to 'MaximumSatisfactoryY' 
| or smaller, execution will terminate as soon as a local 
| minimum is found.  Global search stops.
| 
| Three points will be returned.  The center point, (x2,y2), 
| will have smaller function value (y2) than its neighbors.  
| In pathological cases they may be equal.
|                                                    
| If IsFirstPointKnown == 1, that means the user is 
| inputting f(low) in *y2.  That sometimes saves a function 
| evaluation.
|                                                               
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 05.15.97 from 'Advanced Algorithms For Neural
|                         Networks'.
------------------------------------------------------------*/
void
FindRoughGlobalMinimum(
    f64   LoX,              // Lower limit for search
    f64   HiX,              // Upper limit
    s32   npts,             // Number of points to try
    s32   log_space,        // Space by log?
    f64   MaximumSatisfactoryY, // Quit global if crit drops this low
    f64   (*FofX) (f64),    // Criterion function
    f64*  x1,
    f64*  y1,               // Lower X value and function there
    f64*  x2,
    f64*  y2,               // Middle (best)
    f64*  x3,               // And upper
    f64*  y3,
    u32   IsFirstPointKnown )                
{
    s32  i, ibest, turned_up;
    f64 x, y, rate, previous;
 
    if( log_space )
    {
        rate = exp( log(HiX / LoX) / (npts - 1) );
    }
    else
    {
        rate = (HiX - LoX) / (npts - 1);
    }

    x = LoX;

    previous  = 0.0; // Avoids "use before set" compiler warnings
    ibest     = -1;  // For proper MaximumSatisfactoryY escape
    turned_up = 0;   // Must know if function increased after min

    for( i = 0; i < npts; i++ ) 
    {

        if( i || ! IsFirstPointKnown )
        {
            y = (*FofX)( x );
        }
        else
        {
            y = *y2;
        }

        if( y < 0.0 ) 
        {
            if( ! turned_up )
            {
                return; // return 1;
            }
            
            y = -y;
        }

//      sprintf( msg, "%d: %.4lf %.5lf", i, x, y );
//      write_progress( msg );

        // Keep track of best here.
        if( (i == 0)  ||  (y < *y2) ) 
        {  
            ibest = i;
            *x2 = x;
            *y2 = y;
            
            // Function value to its left.
            *y1 = previous; 
            
            // Flag that min is not yet bounded.
            turned_up = 0;  
        }
        else // Didn't improve.
        {
            if( i == (ibest+1) ) 
            { 
                // This point may be the right neighbor of the best.
                *y3 = y; 
                
                // Flag that min is bounded.
                turned_up = 1;          
            }
        }

        // Keep track for left neighbor of best.
        previous = y;                

        // Done if good enough and both neighbors found.
        if( (*y2 <= MaximumSatisfactoryY)  &&  
            (ibest > 0 )  &&  turned_up )
        {
            break;
        }

        if( log_space )
        {
            x *= rate;
        }
        else
        { 
            x += rate;
        }
    }

    // At this point we have a minimum (within LoX,HiX) at (x2,y2).
    // Compute x1 and x3, its neighbors.
    // We already know y1 and y3 unless the minimum is at an endpoint.

    if( log_space ) 
    {
        *x1 = *x2 / rate;
        *x3 = *x2 * rate;
    }
    else 
    {
        *x1 = *x2 - rate;
        *x3 = *x2 + rate;
    }

    // Normally we would now be done.  However, the careless user 
    // may have given us a bad x range (LoX,HiX) for the global 
    // search.
    // If the function was still decreasing at an endpoint, bail 
    // out the user by continuing the search.

    // Must extend to the right (larger x).
    if( ! turned_up ) 
    { 
        // Endless loop goes as long as necessary.
        while(1) 
        {       
            *y3 = (*FofX)( *x3 );

            // Why this?
            if( *y3 < 0.0 )
            {
                return; // return(1)
            }

//          sprintf( msg, "R: %.4lf %.5lf", *x3, *y3 );
//          write_progress( msg );

            // If function increased we are done.
            if( *y3 > *y2 )
            {  
                break;
            }
            
            // Give up if flat.
            if( (*y1 == *y2) && (*y2 == *y3) )
            { 
                break;
            }

            // Shift all points.
            *x1 = *x2;      
            *y1 = *y2;
            *x2 = *x3;
            *y2 = *y3;

            // Step further each time.
            rate *= 3.0;     
            
            // And advance to new frontier.
            if( log_space )
            {
                *x3 *= rate;
            }
            else // Linear space.
            {
                *x3 += rate;
            }
        }
    }
    else 
    {
        // Must extend to the left, smaller x.
        if( ibest == 0 ) 
        {  
            // Endless loop goes as long as necessary.
            while(1) 
            {             
                *y1 = (*FofX)( *x1 );

                // Why this?
                if( *y1 < 0.0)
                {
                    return; // return( 1 );
                }

//          sprintf( msg, "L: %.4lf %.5lf", *x1, *y1 );
//          write_progress( msg );

                // If function increased we are done.
                if( *y1 > *y2 )
                {
                    break;
                }
                
                // Give up if flat.
                if( (*y1 == *y2)  &&  (*y2 == *y3) )
                { 
                    break;
                }
                
                // Shift all points.
                *x3 = *x2;      
                *y3 = *y2;
                *x2 = *x1;
                *y2 = *y1;

                // Step further each time.
                rate *= 3.0;     

                // And advance to new frontier.
                if( log_space )
                {   
                    *x1 /= rate;
                }
                else
                { 
                    *x1 -= rate;
                }
            }
        }
    }
}

/*------------------------------------------------------------
| Gamma
|-------------------------------------------------------------
|
| PURPOSE: To compute the Gamma term for the conjugate
|          gradient recurrence relation:
|
|          h    = g    + Gamma * h
|           i+1    i+1            i
|
| DESCRIPTION: Uses the formula found on the bottom of page
| 422 of 'Numerical Recipies in C':
|
|                    ( g    - g ) . g
|                       i+1    i     i+1
|           Gamma = -------------------- 
|                        g  .  g
|                         i     i
| EXAMPLE: 
|
| NOTE:  
|
| ASSUMES: Grad is neg gradient.
|
| HISTORY: 05.20.97 from 'Advanced Algorithms For 
|                         Neural Nets'.
------------------------------------------------------------*/
f64 
Gamma( s32 DimCount, f64* g0, f64* g1 )
{
    s32  i;
    f64 denom, numer;

    numer = 0;
    denom = 0;

    // Calculate the dot products of the vectors that form
    // the numerator and the denominator.
    for( i = 0; i < DimCount; i++ ) 
    {
        numer += (g1[i] - g0[i]) * g1[i];  

        denom += g0[i] * g0[i];
    }

    // Should never happen (means gradient is zero!)
    if( denom == 0.0 )
    {
        return( 0.0 );
    }
    else
    {
        return( numer / denom );
    }
}

/*------------------------------------------------------------
| TrySimplex 
|-------------------------------------------------------------
|
| PURPOSE: To test the fitness of a simplex transformation. 
|
| DESCRIPTION: This is a subroutine used by 
| 'FindSimplexMinimum'. 
| 
| Extrapolates by a factor 'fac' through the face of the
| simplex across from the high point, tries it, and
| replaces the high point if the new point is better.
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: The global variables starting with 'FSM_'.
|
| HISTORY:  04.01.96 
------------------------------------------------------------*/
f64
TrySimplex( f64 fac )
{
    s32     j;
    f64 fac1, fac2, ytry;
    
    fac1 = (1.0-fac) / FSM_DimCount;
    
    fac2 = fac1 - fac;
    
    for( j = 0; j < FSM_DimCount; j++ )
    {
        FSM_TrialPoint[j] = FSM_DimSum[j] * fac1 - 
                            FSM_Vertex[FSM_HiY][j] * fac2;
    }
    
    ytry = (*FSM_FofX)( FSM_TrialPoint ); // Evaluate the function 
                                          // at the trial point.
    if( ytry < FSM_Y[ FSM_HiY ] )
    {
        // If it's better than the highest, then replace
        // the highest.
        
        FSM_Y[ FSM_HiY ] = ytry;
        
        for( j=0; j < FSM_DimCount; j++ )
        {
            FSM_DimSum[j] += FSM_TrialPoint[j] - 
                             FSM_Vertex[ FSM_HiY ][j];
            
            FSM_Vertex[FSM_HiY][j] = FSM_TrialPoint[j];
        }
    }
    
    return( ytry );
}

#ifdef TEST_OPTIMIZE
 
/*------------------------------------------------------------
| bessj0 
|-------------------------------------------------------------
|
| PURPOSE: To calculate the Bessel function J0(x) for any
|          real x.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE: From p. 232 of 'Numerical Recipes in C'.
|
| ASSUMES: 
|
| HISTORY:  04.01.96 
------------------------------------------------------------*/
f64
bessj0( f64 x )
{
    f64 ax,z;
    f64 xx,y,ans,ans1,ans2;
    
    if( (ax = fabs(x)) < 8.0 ) // Direct rational fit.
    {
        y = x*x;
        ans1 = 57568490574.0 + 
               y * (-13362590354.0 + 
               y * ( 651619640.7 +
               y * (-11214424.18 +
               y * (77392.33017 +
               y * (-184.9052456)))));
               
        ans2 = 57568490411.0 +
               y * (1029532985.0 +
               y * (9494680.718 +
               y * (59272.64853 +
               y * (267.8532712 +
               y * 1.0))));
        ans = ans1/ ans2;
    }
    else
    {
        // Fitting function (6.5.9).
        z = 8.0/ax;
        y = z * z;
        xx = ax - 0.785398164;
        
        ans1 = 1.0 + y * (-0.1098628627e-2 +
                     y * (0.2734510407e-4 +
                     y * (-0.2073370639e-5 +
                     y * 0.2093887211e-6)));
                     
        ans2 = -0.156249995e-1 +
               y * (0.1430488765e-3 +
               y * (-0.6911147651e-5 +
               y * (0.7621095161e-6 -
               y * 0.934935152e-7 )));
        
        ans = sqrt( 0.636619772/ax ) * 
              (cos(xx) * ans1-z*sin(xx)*ans2);
    }
    
    return( ans );
}

/*------------------------------------------------------------
| TestFindSimplexMinimum 
|-------------------------------------------------------------
|
| PURPOSE: To test the 'FindSimplexMinimum' function.
|
| DESCRIPTION: This test is adapted from p. 172 of 
| 'Numerical Recipes Example Book'. 
|
|        The minimum value should be (.5,.6,.7).
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY:  04.01.96 
------------------------------------------------------------*/
f64
func( f64* x)
{
    return( .06 - bessj0( (x[0]-0.5) * (x[0]-0.5) + 
                          (x[1]-0.6) * (x[1]-0.6) +
                          (x[2]-0.7) * (x[2]-0.7) ) );
}

void 
TestFindSimplexMinimum()
{
    s32     i, j, nfunc;
    Vector* x;
    Vector* y;
    Matrix* p;
    f64**   P;
    
    x = MakeVector( 3, 0, 0 );
    y = MakeVector( 4, 0, 0 );
    p = MakeMatrix( (s8*) "", 4, 3 );
    P = (f64**) p->a;
    
    for( i = 0; i < 4; i++ )
    {
        for( j = 0; j < 3; j++ )
        {
            x->X[j] =
            P[i][j] = (i == (j+1) ? 1.0 : 0.0 );
        }
        
        y->Y[i] = func( x->X );
    }
    
    nfunc = FindSimplexMinimum( func, p, y, 1.0e-20 );
    
    printf( "\nNumber of function evaluations: %3d\n", nfunc );
    printf( "Vertices of final 3-d simplex and \n");
    printf( "function values a the the vertices:\n\n");
    printf( "%3s %10s %12s %12s %14s\n\n",
            "i","x[i]","y[i]","z[i]","function");
    
    for( i = 0; i < 4; i++ )
    {
        printf( "%3d ", i );
        
        for( j = 0; j < 3; j++ )
        {
            printf( "%12.6f ", P[i][j] );
        }
        
        printf( "%12.6f\n", y->Y[i] );
        
    }
    
    printf( "\nTrue minimum is at (0.5,0.6,0.7) \n");
    
    DeleteMatrix( p );
    free( x );
    free( y );
}

#endif // TEST_OPTIMIZE
