Extension { #name : #B3DAcceleratorPlugin }

{ #category : #'*CMakeVMMaker' }
B3DAcceleratorPlugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |

	maker ifMac: [
		maker addPlatformSources:
			#( 'sqMacOpenGL.c' 'sqMacOpenGLInfo.c')
		].
	
	maker 
		addCrossSources: #( 'sqOpenGLRenderer.c' ) 
	
	].
		
		




]
