Extension { #name : #SurfacePlugin }

{ #category : #'*CMakeVMMaker' }
SurfacePlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |
			maker set: #sources toString: ''. "remove default source file"
			maker addCrossSources: #('SurfacePlugin.c')
		]
		



]
