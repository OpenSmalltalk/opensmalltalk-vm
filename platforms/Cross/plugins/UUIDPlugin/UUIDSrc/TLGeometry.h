/*------------------------------------------------------------
| TLGeometry.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to geometry functions.
|
| DESCRIPTION: 
|        
| NOTE: See 
|
|      1. 'Line' and 'Polar' in 'Mathematics Dictionary' by 
|         James 
|
|      2. 'Calculus and Analytic Geometry, 6th ed." by 
|         Thomas/Finney, p. 17 
|
|      3. 'Handbook of Mathematics' by Bronshtein and 
|          Semendyayev, p. 199.
|
|      4. 'CRC Standard Math Tables,  23rd ed', p. 369. 
|
| HISTORY: 04.02.96 
|          02.25.00 Changed 'GeneralLine' --> 'General2DLine'.
------------------------------------------------------------*/

#ifndef TLGEOMETRY_H
#define TLGEOMETRY_H

// The general 2D line equation is:
//
//     A * x + B * y + C = 0 
//
//                      where both 'A' and 'B' are never 0.
//
//                 solving for x:
//
//                          -(B * y + C)
//                      x = ---------------
//                                A
//
//                     if y == 0 then, the x intercept is
//
//                           -C
//                     x = ----- 
//                           A
//
//                 solving for y:
//
//                          -(A * x + C)
//                     y = ---------------
//                                B
//
//                     if x == 0 then, the y intercept is
//
//                          -C
//                     y = ----- 
//                           B
typedef struct
{
    f64 A; 
    f64 B;
    f64 C;
} General2DLine;

// A line, 'L', in Hessian normal form is:
//
//                |     \
//                |      \       
//                |   90°/\   
//                |      \/\             
//                |      /  \
//                |   + /    \  L 
//                |  r /      \ 
//                | - / \       
//                |  /   a  +      
//                | /     \        
//                |/ a     |         
//    ------------O----------------------- X
//               .|        |
//              . |  OR   /
//             .  |      a  -
//            .   |     /
//           . <--------
//          .     |    
//
//          x * cos( a ) + y * sin( a ) - r = 0
//
//                 solving for x:
//
//                             -( sin(a) * y - r )
//                        x = ---------------------
//                                   cos(a)
//
//                  solving for y:
//
//                             -( cos(a) * x - r )
//                        y = ---------------------
//                                   sin(a)
//          where either:
//
//              1. 'a' is the positive, counter-clockwise
//                  angle from the X axis to the
//                  normal to the line 'L', and 'r' is 
//                  the distance from the origin to 
//                  the nearest point on line 'L'.
//
//             OR
//
//              2. 'a' is the negative, clockwise
//                  angle from the X axis to the
//                  normal to the line 'L', and 'r' is 
//                  the distance from the line 'L' to the
//                  origin, the sign of 'r' being '-'.
typedef struct
{
    f64 r; // Radius Vector
    f64 a; // Vectorial Angle 
} HessianLine;

typedef struct
{
    f64 b; // Y intercept: x == 0.
    f64 m; // slope
} PointSlope;

typedef struct
{
    XY  a;  
    XY  b;  
} TwoPoints;

typedef struct
{
    XY  min;
    XY  max;
} Rectangle2; // 'Rectangle' collides with Win32 type.

f64     DistanceOfPointsToHessianLine( HessianLine*, Vector*, f64* );
f64     DistanceOfPointToGeneralLine( General2DLine*, XY* );
f64     DistanceOfPointToHessianLine( HessianLine*, XY* );
f64     FindXonGeneralLineGivenY( General2DLine*, f64 );
f64     FindYonGeneralLineGivenX(  General2DLine*, f64 );
void    GeneralLineToHessianLine( General2DLine*, HessianLine* ); 
void    GeneralLineToPointSlope( General2DLine*, PointSlope* ); 
void    HessianLineToGeneralLine( HessianLine*, General2DLine* );
void    HessianLineToPointSlope( HessianLine*, PointSlope* );
s32     IntersectLineAndRectangle( General2DLine*, Rectangle2*, TwoPoints* );
u32     IntersectLineAndSegment( General2DLine*, TwoPoints*, XY* );
u32     IntersectTwoLines( General2DLine*, General2DLine*, XY* );

// NearestPointOnLine
f64     MeanSqDistanceOfPointsToGeneralLine( 
            General2DLine*, f64*, f64*, u32 );

void    PointSlopeToGeneralLine( PointSlope*, General2DLine* );
void    PointSlopeToHessianLine( PointSlope*,  HessianLine* );
void    ReflectVectorAboutLine( HessianLine*, Vector*, Vector* );
void    TestLineConversions();
void    TestReflectVectorAboutLine();
void    TwoPointLineToGeneralLine( TwoPoints*, General2DLine* );

#endif // TLGEOMETRY_H
