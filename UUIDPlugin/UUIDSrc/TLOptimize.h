/*------------------------------------------------------------
| FILE: TLOptimize.h
|-------------------------------------------------------------
|
| PURPOSE: To provide interface to optimization functions.
|
| DESCRIPTION: 
|
| NOTE: 
|
| HISTORY: 03.24.96 
------------------------------------------------------------*/

// Globals used by 'FindRandomMultiDimensionalMinimum'.
extern f64*     FRMD_X;
extern s32      FRMD_DimCount;

f64     FindGradientMinimum( s32, f64, f64, f64,    
                             f64 (*)( f64* ),   
                             f64 (*)( f64*, f64*, f64* ), 
                             s32, f64*, f64,
                             f64*, f64*, f64*, f64*, f64* );

f64     FindLineMinimum( f64 );

f64     FindLocalMinimum( 
            f64 (*)(f64), f64, f64, s32, f64*);
                  
f64     FindParabolicMinimum(  
            f64 (*)(f64), f64, f64, f64, f64, f64* );
            
f64     FindParabolicMinimum2( s32, f64, f64, f64,              
                 f64  (*) (f64), 
                 f64*, f64*, f64*, f64 );            

f64     FindRandomMinimum(   
            f64 (*)(f64), f64, f64, f64, s32, f64* );

void    FindRoughGlobalMinimum( f64, f64, s32, s32, f64, 
            f64 (*) (f64), f64*, f64*, f64*, f64*, 
            f64*, f64*, u32   );

s32     FindSimplexMinimum( 
            f64 (*)(f64*), Matrix*, Vector*, f64 );
            
f64     FindSubRandomMinimum( 
            f64 (*)(f64), f64, f64, f64, f64, f64* );

f64     Gamma( s32, f64*, f64* );

f64     FindRandomMultiDimensionalMinimum(  
            f64 (*)(), f64*, f64*, f64, s32, f64*, s32 );
            
f64     TrySimplex( f64 );

#define TEST_OPTIMIZE

#ifdef TEST_OPTIMIZE
f64     bessj0( f64 );
f64     func( f64* );
void    TestFindSimplexMinimum();
#endif
