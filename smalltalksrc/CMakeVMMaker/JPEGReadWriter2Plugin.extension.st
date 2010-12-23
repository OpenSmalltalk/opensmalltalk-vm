Extension { #name : #JPEGReadWriter2Plugin }

{ #category : #'*CMakeVMMaker' }
JPEGReadWriter2Plugin classSide >> generateFor: aCMakeVMGenerator internal: aBoolean [

	^ aCMakeVMGenerator 
		generatePlugin: self 
		internal: aBoolean
		extraRules: [:maker |
maker addCrossSources: #(
'Error.c'
'jcapimin.c'
'jcapistd.c'
'jccoefct.c'
'jccolor.c'
'jcdctmgr.c'
'jchuff.c'
'jcinit.c'
'jcmainct.c'
'jcmarker.c'
'jcmaster.c'
'jcomapi.c'
'jcparam.c'
'jcphuff.c'
'jcprepct.c'
'jcsample.c'
'jctrans.c'
'jdapimin.c'
'jdapistd.c'
'jdatadst.c'
'jdatasrc.c'
'jdcoefct.c'
'jdcolor.c'
'jddctmgr.c'
'jdhuff.c'
'jdinput.c'
'jdmainct.c'
'jdmarker.c'
'jdmaster.c'
'jdmerge.c'
'jdphuff.c'
'jdpostct.c'
'jdsample.c'
'jdtrans.c'
'jerror.c'
'jfdctflt.c'
'jfdctfst.c'
'jfdctint.c'
'jidctflt.c'
'jidctfst.c'
'jidctint.c'
'jidctred.c'
'jmemdatadst.c'
'jmemdatasrc.c'
'jmemmgr.c'
'jmemnobs.c'
'jquant1.c'
'jquant2.c'
'jutils.c'
) 
	].

]
