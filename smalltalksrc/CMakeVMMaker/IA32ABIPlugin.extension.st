Extension { #name : #IA32ABIPlugin }

{ #category : #'*CMakeVMMaker' }
IA32ABIPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

		maker addCrossSources:
			#( 'ia32abicc.c')
	].

]
