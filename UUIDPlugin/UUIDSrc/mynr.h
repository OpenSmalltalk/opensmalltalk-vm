 /* for cg.c */ 
typedef struct 
{
  s32   n; 
  f64* p; 
  f64* xi; 
  f64  (*nfunc)(); 
  void* func_arg; 
} f1dim2_arg; 

f64     brent();     
f64     brent2();    
f64     brent_a();   
void    dlinmin();  
f64     dbrent();    
f64     df1dim();   
void    dfpmin(); 
void    dfpmin_a(); 
void    dfpmin2(); 
// f64  diagonal_product();
f64     f1dim();    
f64     f1dim2();   
void    frprmn();   
void    frprmn_a();     
f64     improve_hessin(); 
f64     improve_hessin3(); 
f64     luimprove_hessin(); 
void    linmin();   
void    linmin2();  
void    linmin_a();     
void    mnbrak();   
void    mnbrak2();  

void    pos_eigs(); 
void    report_eigs(); 
void    report_eigs2(); 
void    scale_eigs_by_pow_sqrt_lambda(); 


