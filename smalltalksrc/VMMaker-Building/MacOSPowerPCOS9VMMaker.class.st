"
A VMMaker subclass to suit Mac OS
"
Class {
	#name : #MacOSPowerPCOS9VMMaker,
	#superclass : #VMMaker,
	#category : #'VMMaker-Building'
}

{ #category : #initialisation }
MacOSPowerPCOS9VMMaker class >> isActiveVMMakerClassFor: platformName [
	"Does this class claim to be that properly active subclass of VMMaker for this platform?"

	^platformName = 'Mac OS'" and: [Smalltalk platformSubtype = 'PowerPC'] <- this used to be used but prevents any attempt to do the crossplatform generation thang. How can we handle that bit properly?"
]

{ #category : #initialize }
MacOSPowerPCOS9VMMaker >> createCodeGenerator [
	"Set up a CCodeGenerator for this VMMaker - Mac OS uses the global struct and local def of the
	 structure.  The global struct/loca def regime appears to be about 10% faster than the default
	 regime for Smalltalk-intensive macro benchmarks for both the Intel and gcc 4.0 compiler on x86.
	 eem 12/10/2008 14:34 2.16 GHz Intel Core Duo MacBook Pro Mac OS X 10.4.11"
	^CCodeGeneratorGlobalStructure new initialize;
		globalStructDefined: true;
		structDefDefine: '1';
		"structDefDefine: 'defined(PPC) || defined(_POWER) || defined(__powerpc__) || defined(__ppc__)';"
		logger: logger;
		yourself
]
