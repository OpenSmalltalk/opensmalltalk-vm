'From Squeak3.2gamma of 15 January 2002 [latest update: #4881] on 11 July 2002 at 12:42:23 am'!
TestInterpreterPlugin subclass: #PseudoTTYPlugin
	instanceVariableNames: 'sCOAFfn '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'VMConstruction-Plugins'!
!PseudoTTYPlugin commentStamp: '<historical>' prior: 0!
Author:		Ian Piumarta <ian.piumarta@inria.fr>
Date:		2002-07-06
Version:		1.0

This plugin extends AsynchFilePlugin with support for Unix98-style pseudo ttys.  Pseudo ttys (ptys) are a means for some program A (e.g., Squeak) to spawn a child process B and have B's std{in,out,err} connected to something that smells (to B) like a terminal (the `slave' tty) but which is in fact connected directly to A via another device (the `master' tty).

One example of this would be Squeak spawning an interactive shell.  If we were to use pipes (or sockets) to communicate with the shell's std{in,out,err} then various screen-oriented programs (such as Emacs) would refuse to run, the shell itself would refuse to implement job control and `cooked' characters (intr, quit, suspend, etc.) would be ignored -- all because pipes (and sockets) are absolutely not the same thing as a tty.  Connecting the shell to a slave tty (and talking to it indirectly through our master tty) allows such programs (and shells and interrupts, etc.) to work properly, since they believe themselves to be connected to a `real' terminal.

To use this plugin on any system that supports Unix98 pseudo ttys you would do something like this:

	- open an AsyncFile on /dev/ptmx (the Pseudo Tty master MultipleXor) which returns
	  a handle on the master tty (and creates the slave tty device -- usually something like
	  /dev/ttyN or /dev/pts/N);
	- prepare the slave tty for use by an inferior process by calling primGrantPt and
	  primUnlockPt on the master;
	- call primPtsName on the master to obtain the name of the allocated slave tty device;
	- open the slave tty for read (stdin), write (stdout) and again for write (stderr);
	- fork;
	- connect the inferior process's std{in,out,err} to the slave tty device through the three
	  descriptors just opened;
	- exec the shell (or whatever) in the inferior process.

After all that the parent process can write (via the original AsyncFile) to the master tty (to provide data for the inferior process's stdin) and read (via the AsyncFile) from the master (to retrieve data written to std{out,err} by the inferior process).  If the inferior process tests std{in,out,err} with isatty() it will be told that it is connected to a login terminal.

This plugin provides four primitives, as implied by the above, all of which apply to AsyncFiles:

	primitivePtGrant				- prepare the slave tty for use
	primitivePtUnlock				- allow connections (open) to the slave tty
	primitivePtsNameLength			- return the size of the slave tty's device name
	primitivePtsName				- read the slave tty's device name into a String

(designed to be easily useable in conjunction with OSProcess) and one more (just for my convenience) which does all of the above steps atomically (and also promotes the inferior process to a process group leader, and installs a handler to finalise the inferior process on exit and close its parent's master tty -- without the need to use OSProcess at all):

	primitiveForkAndExecWithPts		- create an inferior process connected to a slave tty

Note that `Unix98' does NOT imply that this will only work on Unix systems!!  Unix98 is the name of a *standard* (describing one possible implementation of pseudo ttys) which can be adopted by any OS, be it Unix or something entirely different.  (Unix98 ptys have been adopted by both BSD and Linux, which is why we consider it the most interesting standard to implement here.  However, be warned that if [for some bizarre, masochistic reason] you have disabled Unix98 pty support in your BSD or Linux kernel then this plugin will explode in your face.  [Although you should never get that far since the initial open of /dev/ptmx will fail.])

Finally note that this plugin might (should) go away in the future if (when) OSProcess implements the required support for pseudo ttys and asynchronous i/o on their master devices.  Dave: are you reading this?!


!PseudoTTYPlugin methodsFor: 'initialize-release' stamp: 'ikp 7/10/2002 22:41'!
initialiseModule

	self export: true.
	"We have to load AsyncFile first, to get the sessionID."
	interpreterProxy ioLoadFunction: 'initializeModule' From: 'AsynchFilePlugin'.
	^self cCode: 'ptyInit()' inSmalltalk: [true]! !

!PseudoTTYPlugin methodsFor: 'initialize-release' stamp: 'ikp 7/7/2002 02:29'!
shutdownModule

	self export: true.
	^self cCode: 'ptyShutdown()' inSmalltalk: [true]! !


!PseudoTTYPlugin methodsFor: 'primitives' stamp: 'ikp 7/7/2002 05:44'!
primitivePtyClose: fHandle

	| f |
	self var: #f declareC: 'AsyncFile *f'.
	self primitive: 'primPtyClose' parameters: #(Oop).
	f _ self asyncFileValueOf: fHandle.
	interpreterProxy failed ifFalse: [self cCode: 'ptyClose(f)'].! !

!PseudoTTYPlugin methodsFor: 'primitives' stamp: 'ikp 7/10/2002 22:31'!
primitivePtyForkAndExec: cmd arguments: args semaIndex: semaIndex

	| f cmdLen cmdIdx argLen argIdx fOop |
	self var: #f declareC: 'AsyncFile *f'.
	self primitive: 'primPtyForkAndExec' parameters: #(Oop Oop SmallInteger).
	interpreterProxy success: (interpreterProxy isBytes: cmd).
	interpreterProxy success: (interpreterProxy isPointers: args).
	interpreterProxy failed ifTrue: [^nil].
	cmdIdx _ self cCoerce: (interpreterProxy firstIndexableField: cmd) to: 'int'.
	cmdLen _ interpreterProxy slotSizeOf: cmd.	"in bytes"
	argIdx _ self cCoerce: (interpreterProxy firstIndexableField: args) to: 'int'.
	argLen _ interpreterProxy slotSizeOf: args.	"in fields"
	fOop _ interpreterProxy
		instantiateClass: interpreterProxy classByteArray
		indexableSize: (self cCode: 'sizeof(AsyncFile)').
	f _ self asyncFileValueOf: fOop.
	interpreterProxy failed
		ifFalse: [self cCode: 'ptyForkAndExec(f, semaIndex, cmdIdx, cmdLen, argIdx, argLen)'].
	^fOop! !

!PseudoTTYPlugin methodsFor: 'primitives' stamp: 'ikp 7/7/2002 06:38'!
primitivePtyWindowSize: fHandle cols: cols rows: rows

	| f |
	self var: #f declareC: 'AsyncFile *f'.
	self primitive: 'primPtyWindowSize' parameters: #(Oop SmallInteger SmallInteger).
	f _ self asyncFileValueOf: fHandle.
	interpreterProxy failed ifFalse: [self cCode: 'ptyWindowSize(f, cols, rows)'].! !


!PseudoTTYPlugin methodsFor: 'private' stamp: 'ikp 7/6/2002 19:08'!
asyncFileValueOf: oop
	"Return a pointer to the first byte of the async file record within the given Smalltalk bytes object, or nil if oop is not an async file record."

	self returnTypeC: 'AsyncFile *'.
	interpreterProxy success:
		((interpreterProxy isIntegerObject: oop) not
			and: [(interpreterProxy isBytes: oop)
			and: [(interpreterProxy slotSizeOf: oop) = (self cCode: 'sizeof(AsyncFile)')]]).
	interpreterProxy failed ifTrue: [^ nil].
	^ self cCode: '(AsyncFile *) (oop + 4)'
! !

"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PseudoTTYPlugin class
	instanceVariableNames: ''!

!PseudoTTYPlugin class methodsFor: 'translation' stamp: 'ikp 7/6/2002 21:18'!
hasHeaderFile

	^true! !

!PseudoTTYPlugin class methodsFor: 'translation' stamp: 'ikp 7/6/2002 21:12'!
requiresPlatformFiles

	^true! !
