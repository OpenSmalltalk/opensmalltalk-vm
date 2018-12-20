'From Squeak3.2gamma of 15 January 2002 [latest update: #4881] on 11 July 2002 at 6:06:32 am'!
AsyncFile subclass: #PseudoTTY
	instanceVariableNames: 'inputBuffer outputBuffer ioError '
	classVariableNames: 'AsyncFileError '
	poolDictionaries: ''
	category: 'Communications-Endpoints'!
!PseudoTTY commentStamp: '<historical>' prior: 0!
I am a very particular kind of AsyncFile connected to the `master' half of a pseudo TTY (pty).  My purpose in life is to provide communication with a process (in the fork+exec sense) that is connected to the `slave' half of the pty.  (Writing to a master pty causes the data to appear on the slave's stdin, and anything written to the slave's stdout/stderr is available for subsequent reading on the master pty.)

You create me by sending my class

	command: programNameString arguments: arrayOfArgumentStrings

which will spawn a new process running the named program with the given arguments.  You can subsequently send me #nextPut: (or #nextPutAll:) to send stuff to the stdin of the program, and #upToEnd to retrieve data that the program writes to its stdout or stderr.  You can also send me #close which will shut down the program (by sending it SIGTERM followed shortly thereafter by SIGKILL if it's being stubborn) and both halves of the pseudo tty.

The spawned program runs in a new session, will be its own session and process group leader and will have the slave half of the pty as its controlling terminal.  (In plain English this means that the program will behave exactly as if it were being run from login, in particular: shells will enable job control, screen-oriented programs like Emacs will work properly, the user's login tmode settings will be inherited, intr/quit/etc. characters will be cooked into the corresponding signals, and window geometry changes will be propagated to the program.  Neat, huh? ;-)

Note that you need both the AsynchFile and PseudoTTY plugins in order for any of this to work.

Note also that I am really intended to be used by a ProcessEndpoint as part of a ProtocolStack (along with a terminal emulator and a TeletypeMorph to provide interaction with the subprocess).
!


!PseudoTTY methodsFor: 'initialize-release' stamp: 'ikp 7/10/2002 21:58'!
close
	"Close the master half of the pty.  The subprocess should exit (EOF on stdin) although badly written programs might start looping."

	fileHandle isNil ifTrue: [^self].
	self primClosePts: fileHandle.
	fileHandle _ nil.
	Smalltalk unregisterExternalObject: semaphore.
	ioError _ AsyncFileError.
	semaphore signal.	"wake up waiters"
	semaphore _ nil! !

!PseudoTTY methodsFor: 'initialize-release' stamp: 'ikp 7/11/2002 02:47'!
command: programName arguments: argumentArray
	"Create a pseudo tty and then spawn programName with its stdin, out and err connected to the slave end of the pty."

	| semaIndex |
	"AsyncFile"
	name _ programName.
	writeable _ true.
	semaphore _ Semaphore new.
	semaIndex _ Smalltalk registerExternalObject: semaphore.
	"PseudoTTY"
	inputBuffer _ ByteArray new: 8192.
	outputBuffer _ ByteArray new: 1.
	ioError _ 0.
	fileHandle _ self
		forkAndExecWithPts: programName
		arguments: (argumentArray isNil
			ifTrue: [#()]
			ifFalse: [argumentArray])
		semaIndex: semaIndex.
	fileHandle isNil ifTrue: [
		Smalltalk unregisterExternalObject: semaphore.
		semaphore _ nil.
		ioError _ AsyncFileError.
		^nil].
	Processor yield.
	semaphore signal.
	^self! !


!PseudoTTY methodsFor: 'accessing' stamp: 'ikp 7/11/2002 01:36'!
name
	"Answer the name of the program."

	^name! !


!PseudoTTY methodsFor: 'input/output' stamp: 'ikp 7/7/2002 02:56'!
ioError
	"Return the last error code received during read/write.  If this is ever non-zero it means the subprocess has probably died."

	^ioError! !

!PseudoTTY methodsFor: 'input/output' stamp: 'ikp 7/7/2002 06:22'!
isConnected

	^fileHandle notNil and: [ioError == 0]! !

!PseudoTTY methodsFor: 'input/output' stamp: 'ikp 7/7/2002 06:16'!
nextPut: aCharacterOrInteger
	"Send a single character to the stdin of my subprocess."

	fileHandle isNil ifTrue: [^self].
	outputBuffer at: 1 put: aCharacterOrInteger asInteger.
	self
		primWriteStart: fileHandle
		fPosition: -1
		fromBuffer: outputBuffer
		at: 1
		count: 1! !

!PseudoTTY methodsFor: 'input/output' stamp: 'ikp 7/7/2002 06:16'!
nextPutAll: aStringOrByteArray
	"Send an entire string to the stdin of my subprocess."

	fileHandle isNil ifTrue: [^self].
	self
		primWriteStart: fileHandle
		fPosition: -1
		fromBuffer: aStringOrByteArray
		at: 1
		count: aStringOrByteArray size! !

!PseudoTTY methodsFor: 'input/output' stamp: 'ikp 7/7/2002 13:28'!
noteWindowSize: aPoint

	self primWindowSize: fileHandle cols: aPoint x rows: aPoint y! !

!PseudoTTY methodsFor: 'input/output' stamp: 'ikp 7/9/2002 06:15'!
peekUpToEnd
	"Answer everything the subprocess has written to stdout or stderr since the last send of #upToEnd.  Note that stuff written to stderr might arrive earlier than stuff written to stdout if the former is unbuffered and the latter line buffered in the subprocess's stdio library."

	| n |
	self isConnected ifFalse: [^nil].
	n _ self
			primReadResult: fileHandle
			intoBuffer: inputBuffer
			at: 1
			count: inputBuffer size.
	^(self isConnected and: [n > 0])
		ifTrue: [inputBuffer copyFrom: 1 to: n]
		ifFalse: [nil]! !

!PseudoTTY methodsFor: 'input/output' stamp: 'ikp 7/7/2002 21:28'!
upToEnd
	"Answer everything the subprocess has written to stdout or stderr since the last send of #upToEnd.  Note that stuff written to stderr might arrive earlier than stuff written to stdout if the former is unbuffered and the latter line buffered in the subprocess's stdio library."

	| n |
	[self isConnected and: [(n _ self startRead: inputBuffer size;
			primReadResult: fileHandle
			intoBuffer: inputBuffer
			at: 1
			count: inputBuffer size) == Busy]]
		whileTrue: [self waitForCompletion].
	(self isConnected and: [n > 0])
		ifTrue: [^inputBuffer copyFrom: 1 to: n]
		ifFalse: [ioError _ AsyncFileError.  ^nil]		"subprocess has died or closed stdout"! !


!PseudoTTY methodsFor: 'private' stamp: 'ikp 7/10/2002 22:57'!
forkAndExecWithPts: aCommand arguments: argArray semaIndex: semaIndex
	"Run aCommand as an inferior process and connect its std{in,out,err} to the receiver through a pseudo tty."

	^self primForkAndExec: aCommand arguments: argArray semaIndex: semaIndex! !

!PseudoTTY methodsFor: 'private' stamp: 'ikp 7/7/2002 03:07'!
startRead: count
	"Indicate interest in receiving more data from stdout/stderr of the subprocess."

	self
		primReadStart: fileHandle
		fPosition: -1
		count: count! !


!PseudoTTY methodsFor: 'primitives' stamp: 'ikp 7/7/2002 05:11'!
primClosePts: fHandle
	"Kill the process whose pts is associated with our pty."

	<primitive: 'primPtyClose' module: 'PseudoTTYPlugin'>
	^nil! !

!PseudoTTY methodsFor: 'primitives' stamp: 'ikp 7/10/2002 21:48'!
primForkAndExec: command arguments: arguments semaIndex: semaIndex
	"Fork and exec command with the given arguments connecting the new process to a slave tty created from the receiver (which is the master half of a pseudo tty)."

	<primitive: 'primPtyForkAndExec' module: 'PseudoTTYPlugin'>
	^nil! !

!PseudoTTY methodsFor: 'primitives' stamp: 'ikp 7/7/2002 06:41'!
primWindowSize: fHandle cols: cols rows: rows
	"Set the size of the terminal connected to the pty."

	<primitive: 'primPtyWindowSize' module: 'PseudoTTYPlugin'>
	^nil! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PseudoTTY class
	instanceVariableNames: ''!

!PseudoTTY class methodsFor: 'class initialization' stamp: 'ikp 7/7/2002 02:25'!
initialize
	"Can't rely on Error because the compiler finds the global before the class var.  Ho hum."
	"PseudoTTY initialize"

	AsyncFileError _ -2! !


!PseudoTTY class methodsFor: 'instance creation' stamp: 'ikp 7/7/2002 04:33'!
command: commandString arguments: argumentArray

	"(PseudoTTY command: '/bin/bash' arguments: #('-c' 'pwd')) upToEnd asString"

	^self new
		command: commandString
		arguments: argumentArray! !


!PseudoTTY class methodsFor: 'examples' stamp: 'ikp 7/10/2002 23:00'!
example
	"Show the user's current tty mode settings."
	"PseudoTTY example"

	| pty output buf |
	pty _ self command: '/bin/stty' arguments: #('-a').
	pty isNil ifTrue: [^self error: 'Could not create pty or process.'].
	output _ WriteStream on: String new.
	output nextPutAll: 'Your tty modes are: '; cr; space; cr.
	[(buf _ pty upToEnd) isNil] whileFalse: [output nextPutAll: buf asString].
	pty close.
	self inform: output contents! !


PseudoTTY initialize!
