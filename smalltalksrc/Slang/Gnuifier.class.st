"
My instances automate the translation of a Squeak interpreter for use with GCC.  In the specified FileDirectory, I copy 'interp.c' to 'interp.c.old'; translate a gnuified interpreter back into 'interp.c'; and save a working copy of sqGnu.h.

To gnuify an interpreter, try something like one of the following:

	(Gnuifier on: 
		((FileDirectory default 
			directoryNamed: 'src') 
				directoryNamed: 'vm') pathName) gnuify

	(Gnuifier on: 
		'powercow X:Users:werdna:Desktop:squeak:Squeak3.2a-4599 Folder:src:vm') gnuify


Structure:
 directory		FileDirectory -- specifying where I should do my gnuification

I can attempt to undo my damage with #deGnuify.
"
Class {
	#name : #Gnuifier,
	#superclass : #Object,
	#instVars : [
		'directory',
		'interpreterFilename',
		'shouldCleanupOldFile'
	],
	#category : #'Slang-PostProcessing'
}

{ #category : #'as yet unclassified' }
Gnuifier class >> on: aFilePathStringOrDirectory [

	^self new setDirectory: aFilePathStringOrDirectory asFileReference
]

{ #category : #'as yet unclassified' }
Gnuifier >> copyFrom: inFileStream to: outFileStream [

"convert interp.c to use GNU features"

|  inData |

	Cursor read showWhile:
		[inData := inFileStream upToEnd withSqueakLineEndings].
	Cursor write showWhile:
		[outFileStream nextPutAll: inData].
	outFileStream close
]

{ #category : #'as yet unclassified' }
Gnuifier >> deGnuify [
	"Gnuifier is canged to great a gnu2-interp.c so no degnuification is necessary."
	self shouldNotImplement
]

{ #category : #'as yet unclassified' }
Gnuifier >> doCleanupOldFile [
	
	self doCleanupOldFile: true
]

{ #category : #'as yet unclassified' }
Gnuifier >> doCleanupOldFile: aBoolean [
	shouldCleanupOldFile := aBoolean
]

{ #category : #'as yet unclassified' }
Gnuifier >> gnuify [
	"This Gnuifier produces a file compatible with gcc 3.x and gcc 4.x.
	 We label the gnuified VM so one can identify the valid gcc version.
	 The script run on Wndows, platforms/win32/misc/gnuify, produces
	 something compatible with gcc 2.95 (gack)."
	(directory asFileReference / ('gcc3x-', interpreterFilename)) 
		ensureDelete.

	self
		gnuifyFrom: (directory asFileReference / interpreterFilename)
		to: 			(VMMaker forceNewFileNamed: directory / ('gcc3x-', interpreterFilename)).
	
	self shouldCleanupOldFile
		ifTrue: [ (directory / interpreterFilename) ensureDelete ]
]

{ #category : #'as yet unclassified' }
Gnuifier >> gnuifyFrom: inputFile to: outFileStream [

	"convert interp.c to use GNU features"

	| inData beforeInterpret inInterpret inInterpretVars beforePrimitiveResponse inPrimitiveResponse |
	inData := inputFile contents withInternalLineEndings.

	"print a header"
	outFileStream
		nextPutAll: '/* This file has been post-processed for GNU C */';
		cr;
		cr;
		cr.

	beforeInterpret := true. "whether we are before the beginning of interpret()"
	inInterpret := false. "whether we are in the middle of interpret"
	inInterpretVars := false. "whether we are in the variables of interpret"
	beforePrimitiveResponse := true. "whether we are before the beginning of primitiveResponse()"
	inPrimitiveResponse := false. "whether we are inside of primitiveResponse"
	UIManager default
		displayProgress: 'Gnuifying'
		from: 1
		to: (inData occurrencesOf: Character cr)
		during: [ :bar | 
			| lineNumber |
			lineNumber := 0.
			inData linesDo: [ :inLine | 
				| outLine extraOutLine |
				bar value: (lineNumber := lineNumber + 1).
				outLine := inLine. "print out one line for each input line; by default, print out the line that was input, but some rules modify it"
				extraOutLine := nil. "occasionally print a second output line..."
				beforeInterpret
					ifTrue: [ 
						inLine = '#include "sq.h"' ifTrue: [ 
							outLine := '#include "sqGnu.h"' ].
						(inLine beginsWith: 'interpret(void)') ifTrue: [ "reached the beginning of interpret"
							beforeInterpret := false.
							inInterpret := true.
							inInterpretVars := true ] ]
					ifFalse: [ 
						inInterpretVars
							ifTrue: [ 
								(inLine findString: 'register struct foo * foo = &fum;') > 0 
									ifTrue: [ 
									outLine := 'register struct foo * foo FOO_REG = &fum;' ].
								(inLine findString: ' localIP;') > 0 ifTrue: [ 
									outLine := '	register char* localIP IP_REG;' ].
								(inLine findString: ' localFP;') > 0 ifTrue: [ 
									outLine := '	register char* localFP FP_REG;' ].
								(inLine findString: ' localSP;') > 0 ifTrue: [ 
									outLine := '	register char* localSP SP_REG;' ].
								(inLine findString: ' currentBytecode;') > 0 ifTrue: [ 
									outLine := '	register sqInt currentBytecode CB_REG;' ].
								inLine isEmpty ifTrue: [ "reached end of variables"
									inInterpretVars := false.
									outLine := '    JUMP_TABLE;'.
									extraOutLine := '\#if MULTIPLEBYTECODESETS\	if(!asserta((sizeof(jumpTable)/sizeof(jumpTable[0])) >= 512))\		error("bytecode jumpTable too small");\#endif\'
										                withCRs ] ]
							ifFalse: [ 
								inInterpret
									ifTrue: [ "working inside interpret(); translate the switch statement"
										(inLine beginsWith: '		case ') ifTrue: [ 
											| tokens |
											tokens := inLine findTokens: '	 :'.
											outLine := '		CASE(' , tokens second , ')'.
											tokens size > 2 ifTrue: [ 
												(tokens allButFirst: 2) do: [ :token | 
													outLine := outLine , ' ' , token ] ] ].
										inLine = '			break;' ifTrue: [ outLine := '			BREAK;' ].
										inLine = '}' ifTrue: [ "all finished with interpret()" 
											inInterpret := false ] ]
									ifFalse: [ 
										beforePrimitiveResponse
											ifTrue: [ 
												(inLine beginsWith: 'primitiveResponse(') ifTrue: [ "into primitiveResponse we go"
													beforePrimitiveResponse := false.
													inPrimitiveResponse := true.
													extraOutLine := '    PRIM_TABLE;' ] ]
											ifFalse: [ 
												inPrimitiveResponse ifTrue: [ 
													inLine = '	switch (primitiveIndex) {' ifTrue: [ 
														extraOutLine := outLine.
														outLine := '	PRIM_DISPATCH;' ].
													inLine = '	switch (GIV(primitiveIndex)) {' ifTrue: [ 
														extraOutLine := outLine.
														outLine := '	PRIM_DISPATCH;' ].
													(inLine beginsWith: '	case ') ifTrue: [ 
														| caseLabel |
														caseLabel := (inLine findTokens: '	 :') second.
														outLine := '	CASE(' , caseLabel , ')' ].
													inLine = '}' ifTrue: [ inPrimitiveResponse := false ] ] ] ] ] ].

				outFileStream
					nextPutAll: outLine;
					cr.
				extraOutLine ifNotNil: [ 
					outFileStream
						nextPutAll: extraOutLine;
						cr ] ] ].

	outFileStream close
]

{ #category : #'as yet unclassified' }
Gnuifier >> initialize [
	super initialize.
	shouldCleanupOldFile := false
]

{ #category : #'as yet unclassified' }
Gnuifier >> interpreterFilename: aString [
	interpreterFilename := aString
]

{ #category : #'as yet unclassified' }
Gnuifier >> setDirectory: aFileDirectory [

	directory := aFileDirectory
]

{ #category : #'as yet unclassified' }
Gnuifier >> shouldCleanupOldFile [
	
	^ shouldCleanupOldFile
]
