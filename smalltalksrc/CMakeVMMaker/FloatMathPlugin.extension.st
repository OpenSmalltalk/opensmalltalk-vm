Extension { #name : #FloatMathPlugin }

{ #category : #'*CMakeVMMaker' }
FloatMathPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |
			
			maker addCrossSources: #(
				'acos.c' 'acosh.c' 'asin.c' 'asinh.c' 'atan.c' 'atan2.c' 'atanh.c'
				'copysign.c' 'cos.c' 'cosh.c' 'exp.c' 'expm1.c' 'finite.c' 'fmod.c'
				'hypot.c' 'isnan.c' 'k_cos.c' 'k_rem_pio2.c' 'k_sin.c' 'k_tan.c' 'ldexp.c'
				'log.c' 'log10.c' 'log1p.c' 'modf.c' 'pow.c' 'rem_pio2.c' 'rint.c'
				'scalb.c' 'scalbn.c' 'sin.c' 'sinh.c' 'sqrt.c' 'tan.c' 'tanh.c' ).
	"On windoze, lib should be built without optimizations?"
	
	maker puts:'
if (${WIN32})
	add_definitions(-Werror-implicit-function-declaration -O0)	
else(${WIN32})
	add_definitions(-DNO_ISNAN)
endif (${WIN32})'.

	].
		
		




]
