/*------------------------------------------------------------
| TLTlsTest.c
|-------------------------------------------------------------
|
| PURPOSE: To provide test driver for SVD functions.
|
| DESCRIPTION:  
|        
| NOTE: See "The Total Least Squares Problem, Computational
|       Aspects and Analysis" by Sabine Van Huffel and
|       Joos Vandewalle.
|
| HISTORY: 01.30.00 Separated from 'TLMatrixMath.c'.
------------------------------------------------------------*/
#include "TLTarget.h"

#include <stdio.h>
#include <stdlib.h>

#include "TLTypes.h"
#include "TLBytes.h"
#include "TLMatrixAlloc.h"
#include "TLOrdinal.h"
#include "TLMatrixMath.h"
#include "TLBuf.h"
#include "TLMemHM.h"
#include "TLList.h"
#include "TLFile.h"
#include "TLFileExtra.h"
#include "TLMatrixOutput.h"
#include "TLMatrixCopy.h"
#include "TLRandom.h"
#include "TLStacks.h"
#include "TLParse.h"
#include "TLTesting.h"
#include "TLPoints.h"
#include "TLVector.h"
#include "TLGeometry.h"
#include "TLTls.h"
#include "TLf64.h"

void    TestTotalLeastSquares();

/*------------------------------------------------------------
| TlsSamples
|-------------------------------------------------------------
|
| PURPOSE: To supply a test case for LineFitTls.
|
| DESCRIPTION: This table holds actual measurements made of
| a real-time clock and a CPU timestamp register at regular
| intervals determined by an external oscillator.
|
| HISTORY: 03.12.00
------------------------------------------------------------*/
f64 
TlsSamples[] =
{
//     Real-Time        Time-Stamp
//     Clock (ms)         Counter
//
//         X                 Y
    952723311030.0,   55374870824464.0,
    952723311030.0,   55374871233784.0,
    952723311110.0,   55374915374193.0,
    952723311140.0,   55374934643985.0,
    952723311160.0,   55374947740931.0,
    952723311180.0,   55374956829927.0,
    952723311190.0,   55374966923559.0,
    952723311200.0,   55374974135831.0,
    952723311220.0,   55374985202783.0,
    952723311240.0,   55374994203833.0,
    952723311260.0,   55375004451953.0,
    952723311270.0,   55375012502409.0,
    952723311290.0,   55375025629923.0,
    952723311300.0,   55375032819379.0,
    952723311320.0,   55375046124155.0,
    952723311330.0,   55375050094781.0,
    952723311350.0,   55375062205677.0,
    952723311370.0,   55375071141405.0,
    952723311380.0,   55375082312865.0,
    952723311401.0,   55375089592591.0,
    952723311411.0,   55375100569941.0,
    952723311431.0,   55375107814445.0,
    952723311451.0,   55375120546997.0,
    952723311461.0,   55375128942133.0,
    952723311481.0,   55375140068329.0,
    952723311491.0,   55375147362909.0,
    952723311511.0,   55375158294733.0,
    952723311521.0,   55375166670113.0,
    952723311541.0,   55375178312601.0,
    952723311551.0,   55375184840579.0,
    952723311571.0,   55375196804037.0,
    952723311591.0,   55375204972217.0,
    952723311611.0,   55375218237033.0,
    952723311621.0,   55375224398121.0,
    952723311641.0,   55375235796559.0,
    952723311651.0,   55375242570437.0,
    952723311671.0,   55375254540475.0,
    952723311691.0,   55375263504269.0,
    952723311701.0,   55375273830729.0,
    952723311721.0,   55375282832229.0,
    952723311741.0,   55375296029491.0,
    952723311751.0,   55375300226379.0,
    952723311771.0,   55375314245411.0,
    952723311781.0,   55375321366991.0,
    952723311801.0,   55375331618103.0,
    952723311811.0,   55375339784039.0,
    952723311831.0,   55375350802623.0,
    952723311851.0,   55375359719579.0,
    952723311871.0,   55375373283203.0,
    952723311881.0,   55375378979787.0,
    952723311901.0,   55375390776969.0,
    952723311911.0,   55375399011457.0,
    952723311931.0,   55375408506193.0,
    952723311941.0,   55375418569215.0,
    952723311961.0,   55375428687495.0,
    952723311971.0,   55375436035265.0,
    952723311991.0,   55375447905291.0,
    952723312001.0,   55375454283587.0,
    952723312021.0,   55375466393055.0,
    952723312041.0,   55375475263849.0,
    952723312051.0,   55375485524047.0,
    952723312071.0,   55375493616275.0,
    952723312091.0,   55375505750299.0,
    952723312101.0,   55375511851255.0,
    952723312122.0,   55375526642851.0,
    952723312132.0,   55375531168723.0,
    952723312152.0,   55375543329019.0,
    952723312162.0,   55375552274225.0,
    952723312182.0,   55375562639363.0,
    952723312192.0,   55375569627265.0,
    952723312222.0,   55375583784979.0,
    952723312232.0,   55375589729731.0,
    952723312252.0,   55375602055607.0,
    952723312262.0,   55375609261859.0,
    952723312282.0,   55375620226199.0,
    952723312292.0,   55375627483397.0,
    952723312312.0,   55375641222107.0,
    952723312322.0,   55375648279071.0,
    952723312342.0,   55375660595175.0,
    952723312362.0,   55375669497253.0,
    952723312372.0,   55375677996701.0,
    952723312392.0,   55375688131769.0,
    952723312412.0,   55375697279497.0,
    952723312422.0,   55375706590485.0,
    952723312442.0,   55375716500419.0
};

/*------------------------------------------------------------
| main
|-------------------------------------------------------------
|
| PURPOSE: To test SVD functions.
|
| DESCRIPTION:
|
| EXAMPLE:  
|
| NOTE: 
|
| ASSUMES: Room exists for the log file on disk.
|
| HISTORY: 12.31.98 Bv From 'BvListTest.c'.
------------------------------------------------------------*/
void
main()
 {
    TheLogFile = fopen( "TLTlsTestLog", "w+" );
    
    printt( (s8*)"***********************************\n" );
    printt( (s8*)"*  B E G I N    T L S    T E S T  *\n" );
    printt( (s8*)"***********************************\n" );

    TestTotalLeastSquares();
    
    printt( (s8*)"***********************************\n" );
    printt( (s8*)"*  B E G I N    T L S    T E S T  *\n" );
    printt( (s8*)"***********************************\n" );

    fclose( TheLogFile );
}

/*------------------------------------------------------------
| TestTotalLeastSquares
|-------------------------------------------------------------
|
| PURPOSE: To test the function 'TotalLeastSquares'.
|
| DESCRIPTION: 
|
| EXAMPLE:  
|
| NOTE:  
|
| ASSUMES: 
|
| HISTORY: 02.27.00 From Van Huffel's test example.
------------------------------------------------------------*/
void
TestTotalLeastSquares()
{
    s32     i, m, n, ok;
    f64     Slope, YIntercept;
    f64*    e;
    f64*    w;
    f64*    r;
    f64*    x;
    f64*    nb;
    f64**   a;
    f64**   v;
    f64*    zx;
    f64*    zy;
    PointSlope      PtSlopeLine;
    General2DLine   GenLine;
    f64             MeanSq, rsq;
    XY      p;
    f64     d;
    f64**   A;
    
    // Testing distance from point to general line.
    {
        // Make a general line that is parallel to the X
        // axis and intersects the Y axis at 3.
        GenLine.A = 0.0;
        GenLine.B = -1.0;
        GenLine.C = 3.0;
        
        // Use the point (3,0).
        p.x = 3.0;
        p.y = 0.0;
        
        // Calculate the distance to the line, the answer
        // should be 3.
        d = DistanceOfPointToGeneralLine( &GenLine, &p );

        // Use the point (0,0).
        p.x = 0.0;
        p.y = 0.0;
        
        // Calculate the distance to the line, the answer
        // should be 3.
        d = DistanceOfPointToGeneralLine( &GenLine, &p );
    
        // Make a general line that is 45 degrees and cuts
        // the origin.
        GenLine.A = 1.0;
        GenLine.B = -1.0;
        GenLine.C = 0.0;
        
        // Use the point (3,3).
        p.x = 3.0;
        p.y = 3.0;
        
        // Calculate the distance to the line, the answer
        // should be 0.
        d = DistanceOfPointToGeneralLine( &GenLine, &p );
        
        // Use the point (1,0).
        p.x = 1.0;
        p.y = 0.0;
        
        // Calculate the distance to the line, the answer
        // should be sqrt(2)/2, .7071...
        d = DistanceOfPointToGeneralLine( &GenLine, &p );
    }
        
    //-------------------------------------------------------------
    
    // Set the number of rows and columns.
    m = 6;
    n = 4;
    
    a = matrix( 1, m, 1, n );
    v = matrix( 1, n, 1, n );
    r = vectorr( 1, m );
    x = vectorr( 1, n - 1 );
    w = vectorr( 1, n );
    e = vectorr( 1, n );
    
    // Assign values for the first test matrix which
    // has 6 rows and 4 columns.
    a[1][1] = 0.80010002;  a[1][2] = 0.39985167;  a[1][3] = 0.60005390;  a[1][4] = 0.89999446;
    a[2][1] = 0.29996484;  a[2][2] = 0.69990689;  a[2][3] = 0.39997269;  a[2][4] = 0.82997570;
    a[3][1] = 0.49994235;  a[3][2] = 0.60003167;  a[3][3] = 0.20012361;  a[3][4] = 0.79011189; 
    a[4][1] = 0.90013643;  a[4][2] = 0.20016919;  a[4][3] = 0.79995025;  a[4][4] = 0.85002662; 
    a[5][1] = 0.39998539;  a[5][2] = 0.80006338;  a[5][3] = 0.49985474;  a[5][4] = 0.99016399; 
    a[6][1] = 0.20002274;  a[6][2] = 0.90007114;  a[6][3] = 0.70009777;  a[6][4] = 1.02994390; 

    // Output the matrix.
    printf( "Original matrix:\n");
    print_matrix( "a", a, m, n );
    
    // Compute the TLS solution.    
    ok = TotalLeastSquares( 
            a,      // IN: A matrix such that there are at least as
                    //     many rows as columns.
                    //
                    //     The matrix is constructed by joining the
                    //     'b' column to the right of the 'A' matrix.
                    //
                    //        Ab is [ A b ]
                    //
                    // OUT: This matrix gets messed up.
                    //
            x,      // IN: A buffer with n - 1 elements.
                    //
                    // OUT: The solution vector, 'x' 
                    //      with n - 1 elements.
                    //
            m,      // Number of rows in matrix 'a'.
                    //
            n,      // Number of columns in matrix 'a'.
                    //
            w,      // IN: Workspace, allocate using...
                    //
                    //     w = vector( 1, n );
                    //
            v,      // IN: Workspace, allocate using... 
                    //
                    //     v = matrix( 1, n, 1, n );
                    //
            r,      // IN: Workspace, allocate using...
                    //
                    //     r = vector( 1, m );
            e );    //
                    // IN: Workspace, allocate using...
                    //
                    //     e = vector( 1, n );
        
    // Output the result vector.
    printf( "\nResult vector:\n" );
    
    print_vector( "x", x, n - 1 );
    
    printf( " COMPARE TO CORRECT RESULT... X = [ 0.500254 0.800251 0.299492 ]\n\n" );
    
    free_vector( e, 1, n );
    free_vector( w, 1, n );
    free_vector( x, 1, n - 1 );
    free_vector( r, 1, m  );
    free_matrix( v, 1, n, 1, n );
    free_matrix( a, 1, m, 1, n );
    
    //-------------------------------------------------------------
    
    printf( "Now fit lines to sampled (X,Y) data using two different methods.\n\n" );
    
    // Calculate how many samples there are in the 'TlsSamples[]'
    // array.
    n = sizeof( TlsSamples ) / ( sizeof( f64) * 2 );
    
    // Allocate a buffer to hold the 'x' and 'y' values.
    nb = (f64*) malloc( 2 * n * sizeof(f64) );
    
    // Allocate working space for the OLS routine.
    zx = (f64*) malloc( n * sizeof(f64) );
    zy = (f64*) malloc( n * sizeof(f64) );
    
    // Separate the 'x' and 'y' values into low and high halves of the
    // buffer 'nb'.
    for( i = 0; i < n; i++ )
    {
        nb[i]   = TlsSamples[i*2];
        nb[i+n] = TlsSamples[(i*2)+1];
    }
    
    // Allocate working space.
    a = matrix( 1, n, 1, 2 );
    r = vectorr( 1, n );
    v = matrix( 1, 2, 1, 2 ); 
        
    // Calculate the line fit.
    ok = LineFitTls( 
            nb,     // IN: The abscissa array.
                    //
            nb+n,   // IN: The ordinate array.
                    //
            n,      // IN: The number of items in 'x' and 'y'.
                    //
            &PtSlopeLine.m, 
                    // OUT: The returned slope in Y = m * X + b.
                    //
            &PtSlopeLine.b,
                    // OUT: The returned y-intercept in Y = m * X + b.
                    //
                    // WORKSPACES: Allocate these structures to hold
                    // intermediate results ...
                    //
            a,      //    a = matrix( 1, n, 1, 2 );
            r,      //    r = vector( 1, n );
            v );    //    v = matrix( 1, 2, 1, 2 ); 
            
    // Free the working space.
    free_vector( r, 1, n  );
    free_matrix( v, 1, 2, 1, 2 );
    free_matrix( a, 1, n, 1, 2 );
 
    printf( "TlsSamples TLS line fit using y = mx + b is m =  %15.12lf  and b =  %15.12lf \n", 
            PtSlopeLine.m,
            PtSlopeLine.b );
    
    // Convert the form of the line from point/slope to general line.           
    PointSlopeToGeneralLine( &PtSlopeLine, &GenLine ); 
    
    // Calculate the mean squared distance from the points to the line.
    MeanSq = 
        MeanSqDistanceOfPointsToGeneralLine( 
            &GenLine,   // The equation of the line.
                        //
            nb,         // The X values, the abscissa array.
                        // 
            nb+n,       // The Y values, the ordinate array.
                        //
            n );        // The number of points.
    
    printf( "\nMeanSq distance of sample points to TLS line is %15.12lf\n\n",
            MeanSq );
        
    // Use and ordinary least squares fit for comparison.
    LineFit(
        nb,         // IN: The abscissa array.
                    //
        nb+n,       // IN: The ordinate array.
                    //
        n,          // IN: The number of items in 'x' and 'y'.
                    //
        &PtSlopeLine.m,     
                    // OUT: The returned slope in Y = m * X + b.
                    //
        &PtSlopeLine.b,     
                    // OUT: The returned y-intercept in Y = m * X + b.
                    //
        &rsq,       // OUT: The returned coefficient of determination; 
                    //      0 < rsq < 1; 
                    //
                    // where:
                    //      If rsq is near 1, then the data are well 
                    //      described by a line.
                    //
                    //      If rsq is near 0, then the data are NOT 
                    //      well described by a line.
                    //
                    //
        zx,         // OUT: Z-scores for x input values.
                    //
        zy );       // OUT: Z-scores for y input values.
    
    printf( "TlsSamples LS line fit using y = mx + b is m =  %15.12lf  and b =  %15.12lf \n", 
            PtSlopeLine.m,
            PtSlopeLine.b );
    
    // Convert the form of the line from point/slope to general line.           
    PointSlopeToGeneralLine( &PtSlopeLine, &GenLine ); 
    
    // Calculate the mean squared distance from the points to the line.
    MeanSq = 
        MeanSqDistanceOfPointsToGeneralLine( 
            &GenLine,   // The equation of the line.
                        //
            nb,         // The X values, the abscissa array.
                        // 
            nb+n,       // The Y values, the ordinate array.
                        //
            n );        // The number of points.
    
    printf( "\nMeanSq distance of sample points to LS line is %15.12lf\n",
            MeanSq );
            
    free( zy );
    free( zx );
    
    free( nb );
}
