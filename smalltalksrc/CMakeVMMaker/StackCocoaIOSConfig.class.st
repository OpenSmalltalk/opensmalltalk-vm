"
This is a concrete class which generates a StackVM for Mac using the Cocoa library

Fore more information, check the class comments of all the superclasses.

"
Class {
	#name : #StackCocoaIOSConfig,
	#superclass : #CogFamilyCocoaIOSConfig,
	#category : #'CMakeVMMaker-IOS'
}

{ #category : #settings }
StackCocoaIOSConfig >> compilerFlagsRelease [ 
	^#(
	'-g0' '-O0' '-DNDEBUG' '-DDEBUGVM=0'
	'-fomit-frame-pointer'
	'-fdefer-pop -fdelayed-branch -fguess-branch-probability -fcprop-registers -fif-conversion -fif-conversion2 -ftree-ccp -ftree-dce -ftree-dominator-opts -ftree-dse -ftree-ter -ftree-lrs -ftree-sra -ftree-copyrename -ftree-fre -ftree-ch -funit-at-a-time -fmerge-constants'
	'-fthread-jumps -fcrossjumping -foptimize-sibling-calls -fcse-follow-jumps  -fcse-skip-blocks -fgcse  -fgcse-lm -fexpensive-optimizations -frerun-cse-after-loop -fcaller-saves -fpeephole2 -fschedule-insns  -fschedule-insns2 -fsched-interblock  -fsched-spec -fregmove -fstrict-aliasing -fstrict-overflow -fdelete-null-pointer-checks -freorder-blocks -freorder-functions -falign-functions -falign-jumps -falign-loops  -falign-labels -ftree-vrp -ftree-pre'
	'-finline-functions -funswitch-loops -fgcse-after-reload')
]

{ #category : #'source files' }
StackCocoaIOSConfig >> coreSources [ 
	^ #(
		'gcc3x-interp.c'
		)
]

{ #category : #accessing }
StackCocoaIOSConfig >> executableName [
	^ 'StackVM'
]

{ #category : #'source generation' }
StackCocoaIOSConfig >> interpreterClass [
	^ StackInterpreter
]

{ #category : #accessing }
StackCocoaIOSConfig >> pluginsDir [ 
	^'${srcDir}/plugins'
]

{ #category : #'source generation' }
StackCocoaIOSConfig >> prepareForGeneration [
	^ self prepareForStackVMGeneration

]

{ #category : #accessing }
StackCocoaIOSConfig >> srcDir [ 
	"Answer the value of srcDir"

	^ srcDir ifNil: [ srcDir := (self topDir / self srcDirName) fullName ]
]

{ #category : #plugins }
StackCocoaIOSConfig >> versionExternalPlugins [ 
	^Array 
		with: #ThreadedIA32FFIPlugin
		with: #IA32ABIPlugin
]
