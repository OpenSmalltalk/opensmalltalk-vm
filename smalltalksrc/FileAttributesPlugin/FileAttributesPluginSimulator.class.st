"
FileAttributesPluginSimulator provides support functions to allow the FilePluginsAttribute to run in the VM simulator.

faPath is opaque to the VM, but normally stores:

1. The file path being interagated in the format provided by the image (precomposed UTF8).
2. The file path in platform specific format, e.g. wide strings for Windows, decomposed UTF8 for Mac.
3. Platform specific directory iteration information when required, e.g. primOpendir.

The simulator stores an Array with:

1. The session ID
2. The input path in precomposed UTF8.
3. The file name when iterating over directories.
4. The input path with platform specific encoding
5. The file name when iterating over directories with platform specific encoding
6. The pointer to the real faPath used by the plugin.

The third and fourth entries (platform specific encoding) are only valid in specific cases, e.g. primitivePlatToStPath and primitiveStToPlatPath.


Instance Variables

"
Class {
	#name : #FileAttributesPluginSimulator,
	#superclass : #FileAttributesPlugin,
	#instVars : [
		'maxPathLen'
	],
	#classVars : [
		'FA_PATH_MAX',
		'HAVE_CHMOD',
		'HAVE_CHOWN',
		'HAVE_LSTAT',
		'PATH_MAX',
		'S_IFBLK',
		'S_IFCHR',
		'S_IFDIR',
		'S_IFIFO',
		'S_IFLNK',
		'S_IFMT',
		'S_IFREG',
		'S_IFSOCK'
	],
	#category : #FileAttributesPlugin
}

{ #category : #translation }
FileAttributesPluginSimulator class >> shouldBeTranslated [
"This class should not be translated"
	^false
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> addressObjectFor: aByteArray [
	"The simulation passes around ByteArrays in place of malloc'd memory.
	Copy the supplied ByteArray to the simulations memory and answer the address."

	^self toOop: aByteArray
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> arrayFromOop: anOop [
	"Answer a copy of the supplied array Oop"

	| sz array |

	sz := interpreterProxy stSizeOf: anOop.
	array := Array new: sz.
	1 to: sz do: [ :i |
		array at: i put: (self fromOop: (interpreterProxy fetchPointer: i-1 ofObject: anOop))].
	^array
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> byteArrayFromOop: anOop [
	"Answer a copy of the supplied byte array Oop"

	| sz array ptr |

	sz := interpreterProxy stSizeOf: anOop.
	ptr := interpreterProxy arrayValueOf: anOop.
	array := ByteArray new: sz.
	1 to: sz do: [ :i |
		array at: i put: (interpreterProxy byteAt: ptr+i-1)].
	^array
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> byteStringFromOop: anOop [
	"Answer a copy of the supplied ByteString Oop"

	| sz array ptr |

	sz := interpreterProxy stSizeOf: anOop.
	ptr := interpreterProxy arrayValueOf: anOop.
	array := ByteString new: sz.
	self strncpy: array _: ptr _: sz.
	^array
]

{ #category : #simulation }
FileAttributesPluginSimulator >> chmod: pathByteArray _: newMode [
	"Set the mode of pathByateArray to anInteger (as defined by chmod())"

	| status |

	status := self primFile: pathByteArray posixPermissions: newMode.
	"The real primitive answers nil on success, convert to C integer status"
	^status ifNil: [0]
]

{ #category : #simulation }
FileAttributesPluginSimulator >> chown: pathByteArray _: uidInteger _: gidInteger [
	"Set the owner and group of path by numeric id."

	| status |

	status := self primFile: pathByteArray uid: uidInteger gid: gidInteger.
	"The real primitive answers nil on success, convert to C integer status"
	^status ifNil: [0]
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> classOf: anOop [

	| clsOop |
	
	anOop = interpreterProxy nilObject ifTrue: [^UndefinedObject].
	clsOop := interpreterProxy fetchClassOf: anOop.
	clsOop = interpreterProxy classArray ifTrue: [^Array].
	clsOop = interpreterProxy classByteArray ifTrue: [^ByteArray].
	clsOop = interpreterProxy classString ifTrue: [^ByteString].
	clsOop = interpreterProxy classLargePositiveInteger ifTrue: [^LargePositiveInteger].
	clsOop = interpreterProxy classSmallInteger ifTrue: [^SmallInteger].
	self error: 'unknown class'
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faAccessAttributes: faPath _: accessArray _: offset [
	"Set the access attributes in the supplied array (size 3) at the supplied offset.
	Simulated by calling primFileAttributes:mask:."

	| access |

	access := self primFileAttributes: (self faGetStPath: faPath) mask: 2r10.
	interpreterProxy
		storePointer: offset+0
			ofObject: accessArray
			withValue: (self toOop: (access at: 1));
		storePointer: offset+1
			ofObject: accessArray
			withValue: (self toOop: (access at: 2));
		storePointer: offset+2
			ofObject: accessArray
			withValue: (self toOop: (access at: 3)).

]

{ #category : #simulation }
FileAttributesPluginSimulator >> faCharToByteArray: filePtr _: byteArrayPtr [
	"Copy the supplied file name to the simulation and set the pointer"

	byteArrayPtr at: 0 put: (self toOop: filePtr).
	^0
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faCloseDirectory: faPath [
	"Simulate the the call by actually calling the primitive and discarding the stat information (which will be retrieved again later in the simulation)."

	| result status |

	result := self primClosedir: (self faPathPtr: faPath).
	result isNumber ifFalse:
		[faPath at: 6 put: nil.
		status := 0 ]
	ifTrue: 
		[status := result < 0 
			ifTrue: [result]
			ifFalse: [self unableToCloseDir]].
	^status

]

{ #category : #simulation }
FileAttributesPluginSimulator >> faConvertUnixToLongSqueakTime: anInteger [
	"In the simulation the primitive returns the value already converted, so this is a no-op"

	^anInteger
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faExists: faPath [
	"Simulate the the call by actually calling the primitive."

	^self primExists: (self faGetStPath: faPath)
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faFileAttribute: faPath _: attributeNumber [
	"Simulate the the call by actually calling the primitive."

	| result |
	
	result := self primFileAttribute: (self faGetStPath: faPath) number: attributeNumber.
	^self toOop: result
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faFileStatAttributes: faPath _: getLinkStats _: attributeArray [
	"Simulate the call to faFileStatAttributes().
	The simulator uses a dictionary with keys named after the stat structure members."

	| path primArray mask |

	path := self faGetStPath: faPath.
	mask := getLinkStats
		ifTrue: [5]	"lstat()"
		ifFalse: [1]. "stat()"
	primArray := self primFileAttributes: path mask: 1.
	primArray isNumber ifTrue: [^primArray].
	primArray doWithIndex: [ :entry :index |
		interpreterProxy
			storePointer: index - 1
			ofObject: attributeArray
			withValue: (self toOop: entry)].
	^0
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faGetPlatPath: faPath [
	"Answer the Plat format of the path.
	In the simulation, actually answer the St format, this is required as the real primitive will eventually be called, which requires the St format."

	^self faGetStPath: faPath
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faGetPlatPathByteCount: faPath [
	"Answer the number of bytes in the platform specific encoding"

	^(self faGetPlatPath: faPath) size
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faGetPlatformPath: faPath [
	"Answer the Platform format of the path.
	This isn't normally used within the simulation as the simulation ultimately calls the actual primitive, which requires the St format of the path."

	| path |

	path := (faPath at: 4) ifNil:
		[faPath 
			at: 5 put: nil;
			at: 4 put: (self primToPlatformPath: (self faGetStPath: faPath))].
	(faPath at: 5) ifNotNil: [
		path := path, (faPath at: 5)].
	^path
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faGetStFile: faPath [
	"Answer the basename of the path.
	The simulated faPath contains the basename as the third entry in the Array."

	^faPath at: 3
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faGetStPath: faPath [
	"Answer the St format of the path."

	| path |

	path := faPath second.
	faPath third ifNotNil: [
		path := path, faPath third].
	^path
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faGetStPathLen: faPath [
	"Answer the length of the path."

	^(self faGetStPath: faPath) size

]

{ #category : #simulation }
FileAttributesPluginSimulator >> faInitSessionId: faPathPtr [
	"Set the session id in the supplied pointer"

	faPathPtr sessionId: interpreterProxy getThisSessionID.
	^self faSuccess
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faInvalidateSessionId: faPathPtr [
	"Clear the session ID in the faPathPtr, marking it invalid"

	faPathPtr sessionId: nil.
	^self faSuccess
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faOpenDirectory: faPath [
	"Simulate the the call by actually calling the primitive and discarding the stat information (which will be retrieved again later in the simulation)."

	| result status |

	result := self primOpendir: (self faGetStPath: faPath).
	result ifNotNil: [
		faPath 
			at: 3 put: (result at: 1);
			at: 6 put: (result at: 3).
		status := 0 ]
	ifNil: [status := self noMoreData].
	^status

]

{ #category : #primitives }
FileAttributesPluginSimulator >> faPathMax [
	"Answer the VMs FA_PATH_MAX value"

	<primitive: 'primitivePathMax' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: 'primPathMax'
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faPathPtr: faPath [
	"Given the simulation faPath, answer the ByteArray pointing to the actual faPath"

	^faPath at: 6
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faReadDirectory: faPath [
	"Simulate the the call by actually calling the primitive and discarding the stat information (which will be retrieved again later in the simulation)."

	| result status |

	result := self primReaddir: (self faPathPtr: faPath).
	result ifNotNil: [
		faPath at: 3 put: (result at: 1).
		status := 0 ]
	ifNil: [status := self noMoreData].
	^status

]

{ #category : #simulation }
FileAttributesPluginSimulator >> faSessionId: faPath [
	"Answer the session id of the current path"
	
	^faPath first
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faSetPlatPathOop: faPath _: fileNameOop [
	"Simulate setting the platform encoded file name in the supplied faPath."

	| fileNameBytes len path stPath |

	fileNameBytes := interpreterProxy arrayValueOf: fileNameOop.
	len := interpreterProxy stSizeOf: fileNameOop.
	path := ByteArray new: len.
	self strncpy: path _: fileNameBytes _: len.
	faPath
		at: 4 put: path;
		at: 5 put: nil.
	stPath := self primFromPlatformPath: path.
	faPath
		at: 2 put: stPath;
		at: 3 put: nil.
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faSetStDirOop: faPath _: dirOop [
	"Simulate setting the dir name in the supplied faPath."

	self faSetStPathOop: faPath _: dirOop.
	faPath second last = FileSystem disk delimiter asciiValue ifFalse:
		[faPath at: 2 put: (faPath second copyWith: FileSystem disk delimiter asciiValue)].
	faPath at: 3 put: nil.
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faSetStPathOop: faPath _: fileNameOop [
	"Set the St encoded path."

	| fileNameBytes len path |

	fileNameBytes := interpreterProxy arrayValueOf: fileNameOop.
	self assert: faPath class == Array.
	len := interpreterProxy stSizeOf: fileNameOop.
	path := ByteArray new: len.
	self strncpy: path _: fileNameBytes _: len.
	faPath 
		at: 2 put: path;
		at: 3 put: nil.
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faStat: faPath _: statBuf _: fileNameOop [
	"Simulate the call to faStat().
	The simulator uses a dictionary with keys named after the stat structure members."

	| path primArray |

	path := self faGetStPath: faPath.
	primArray := self primFileAttributes: path mask: 1.
	primArray isNumber ifTrue: [^primArray].
	"First entry is fileName: **TODO**"
	statBuf contents: primArray.
	^0
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faValidatePath: faPath [
	"The simulation currently doesn't keep track of the sessionId."

	^(self faSessionId: faPath) = interpreterProxy getThisSessionID
]

{ #category : #simulation }
FileAttributesPluginSimulator >> faValidateSessionId: anInteger [
	"Answer a boolean indicating whether the supplied session id matches the current one."

	^anInteger = interpreterProxy getThisSessionID
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> fromOop: anOop [

	| cls |

	cls := self classOf: anOop.
	cls = UndefinedObject ifTrue: [^nil].
	cls = Array ifTrue: [^self arrayFromOop: anOop].
	cls = ByteArray ifTrue: [^self byteArrayFromOop: anOop].
	cls = ByteString ifTrue: [^self byteStringFromOop: anOop].
	cls = LargePositiveInteger ifTrue: [^self largePositiveIntegerFromOop: anOop].
	cls = SmallInteger ifTrue: [^self smallIntegerFromOop: anOop].
	self error: 'Unknown class'.
]

{ #category : #'initialize-release' }
FileAttributesPluginSimulator >> initialize [
	"Initialise the receiver for the current platform"

	| masks |

	masks := self primFileMasks.
	S_IFMT := masks at: 1.
	S_IFSOCK := masks at: 2.
	S_IFLNK := masks at: 3.
	S_IFREG := masks at: 4.
	S_IFBLK := masks at: 5.
	S_IFDIR := masks at: 6.
	S_IFCHR := masks at: 7.
	S_IFIFO := masks at: 8.

	"Simulation has only been tested on Unix"
	HAVE_LSTAT := true.
	HAVE_CHMOD := true.
	HAVE_CHOWN := true.
	PATH_MAX := FA_PATH_MAX := self primPathMax.
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> largePositiveIntegerFromOop: anOop [
	"Answer a copy of the supplied large positive integer Oop"

	| sz array ptr |

	sz := interpreterProxy stSizeOf: anOop.
	ptr := interpreterProxy arrayValueOf: anOop.
	array := ByteArray new: 8.
	1 to: sz do: [ :i |
		array at: i put: (interpreterProxy byteAt: ptr+i-1)].
	^Integer
		byte1: (array at: 1)
		byte2: (array at: 2)
		byte3: (array at: 3)
		byte4: (array at: 4)
		byte5: (array at: 5)
		byte6: (array at: 6)
		byte7: (array at: 7)
		byte8: (array at: 8)

]

{ #category : #simulation }
FileAttributesPluginSimulator >> lchown: pathByteArray _: uidInteger _: gidInteger [
	"Set the symlink owner and group of path by numeric id."

	| status |

	status := self primFile: pathByteArray symlinkUid: uidInteger gid: gidInteger.
	"The real primitive answers nil on success, convert to C integer status"
	^status ifNil: [0]
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> maxPathLen [
	"Answer the maximum supported path length for the current platform"

	^maxPathLen ifNil: [maxPathLen := self primPathMax]
]

{ #category : #private }
FileAttributesPluginSimulator >> objectFromStruct: anObject size: structSize [
	"Copy the simulation path in to the simulated image"

	^self toOop: anObject
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> pointerFrom: arrayOop [
	"For the simulation, convert the supplied address to a ByteArray"

	^self fromOop: arrayOop
]

{ #category : #primitives }
FileAttributesPluginSimulator >> primClosedir: directoryPointerBytes [
	"Close the directory stream associated with directoryPointerBytes.
	Caution: do not call this twice on the same externalAddress."

	"self primClosedir: (self primOpendir: '/etc')"
	"self primClosedir: (self primOpendir: '/no/such/directory')"

	<primitive: 'primitiveClosedir' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: 'primClosedir'
]

{ #category : #primitives }
FileAttributesPluginSimulator >> primExists: aByteArray [
	"Answer a boolean indicating whether the supplied file exists."

	<primitive: 'primitiveFileExists' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: aByteArray.

]

{ #category : #primitives }
FileAttributesPluginSimulator >> primFile: pathByteArray posixPermissions: anInteger [
	"Set the mode of pathByateArray to anInteger (as defined by chmod())"

	<primitive: 'primitiveChangeMode' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: pathByteArray
]

{ #category : #primitives }
FileAttributesPluginSimulator >> primFile: pathByteArray symlinkUid: uidInteger gid: gidInteger [
	"Set the owner and group of path by numeric id."

	<primitive: 'primitiveSymlinkChangeOwner' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: pathByteArray
]

{ #category : #primitives }
FileAttributesPluginSimulator >> primFile: pathByteArray uid: uidInteger gid: gidInteger [
	"Set the owner and group of path by numeric id."

	<primitive: 'primitiveChangeOwner' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: pathByteArray
]

{ #category : #primitives }
FileAttributesPluginSimulator >> primFileAttribute: aByteArray number: attributeNumber [
	"Answer a single attribute for the supplied file.
	For backward compatibility (on Unix) with FileReference if the file doesn't exist, and the specified path is a (broken) symbolic link, answer the requested attribute for the symbolic link.

stat() information:
	
	1: name
	2: mode
	3: ino
	4: dev
	5: nlink
	6: uid
	7: gid
	8: size
	9: accessDate
	10: modifiedDate
	11: changeDate
	12: creationDate

access() information

	13: is readable
	14: is writeable
	15: is executable

symbolic link information

	16: is symbolic link
	"
	<primitive: 'primitiveFileAttribute' module: 'FileAttributesPlugin' error: error>
	"FilePlugin>>primitiveDirectoryEntry would return the symbolic link attributes if the symbolic link was broken.  This was due to the incorrect implementation of attempting to retrieve symbolic link information.
	If the old behaviour is required, the logic is:
	
		(error isPrimitiveError and: [attributeNumber ~= 16 and: [error errorCode = self cantStatPath and: [
					self platformSupportsSymbolicLinksEgUnix]]]) ifTrue:
						[DiskSymlinkDirectoryEntry fileSystem: DiskStore currentFileSystem path: aString asPath]"
	error isPrimitiveError ifTrue: [ 
		(attributeNumber = 16 and: [ error errorCode = self unsupportedOperation ]) ifTrue: 
			"If symlinks aren't supported, answer false"
			[ ^false ]].
	^self signalError: error for: aByteArray

]

{ #category : #primitives }
FileAttributesPluginSimulator >> primFileAttributes: aByteArray mask: attributeMask [
	"Answer an array of attributes for the supplied file.  The size and contents of the array are determined by the attributeMask:

Bit 0: stat() information
Bit 1: access() information
Bit 2: use lstat() (instead of stat())

On error, answer an error code (Integer).

stat() information:
	
	1: name
	2: mode
	3: ino
	4: dev
	5: nlink
	6: uid
	7: gid
	8: size
	9: accessDate
	10: modifiedDate
	11: creationDate

access() information

	1: is readable
	2: is writeable
	3: is executable
	"
	<primitive: 'primitiveFileAttributes' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: aByteArray

]

{ #category : #primitives }
FileAttributesPluginSimulator >> primFileMasks [
	"Answer an array of well known masks:
	
	1: S_IFMT
	2: S_IFSOCK
	3: S_IFLNK
	4: S_IFREG
	5: S_IFBLK
	6: S_IFDIR
	7: S_IFCHR
	8: S_IFIFO

	For more information, see: http://man7.org/linux/man-pages/man2/stat.2.html
	"
	<primitive: 'primitiveFileMasks' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: 'primFileMasks'
]

{ #category : #primitives }
FileAttributesPluginSimulator >> primFromPlatformPath: aByteArray [
	"Convert the supplied platform encoded string to the native (UTF8) equivalent"

	<primitive: 'primitivePlatToStPath' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: 'primToPlatformPath:'
]

{ #category : #primitives }
FileAttributesPluginSimulator >> primOpendir: pathString [
	"Answer an ExternalAddress for a directory stream on pathString, or nil if
	the directory cannot be opened"

	"self primOpendir: '/etc'"
	"self primOpendir: '.'"
	"self primOpendir: '/no/such/directory'"

	<primitive: 'primitiveOpendir' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: pathString
]

{ #category : #primitives }
FileAttributesPluginSimulator >> primPathMax [
	"Answer the maximum path length for this platform"

	<primitive: 'primitivePathMax' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: 'primPathMax'
]

{ #category : #primitives }
FileAttributesPluginSimulator >> primReaddir: directoryPointerBytes [
	"Read the next directory entry from the directory stream associated with
	directoryPointerBytes. Answer the name of the entry, ornil for end of directory stream."

	"self primReaddir: (self primOpendir: '/etc')"
	"self primReaddir: (self primOpendir: '/no/such/directory')"

	<primitive: 'primitiveReaddir' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: 'primReaddir:'
]

{ #category : #primitives }
FileAttributesPluginSimulator >> primToPlatformPath: aByteArray [
	"Convert the supplied UTF8 encoded string to the platform encoded equivalent"

	<primitive: 'primitiveStToPlatPath' module: 'FileAttributesPlugin' error: error>
	^self signalError: error for: 'primToPlatformPath:'
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> s_IFDIR [

	^S_IFDIR
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> s_IFMT [

	^S_IFMT
]

{ #category : #primitives }
FileAttributesPluginSimulator >> signalError: error for: aByteArray [
	"In the simulation, flag the interpreter as failing and return the error code"

	error ifNil: [ ^interpreterProxy primitiveFail ].
	error isSymbol ifTrue: [ ^interpreterProxy primitiveFailFor: 
		((SmalltalkImage current specialObjectsArray at: 52) indexOf: error) ].
	error isPrimitiveError ifFalse: [ 
		"We shouldn't ever get here"
		^self primitiveFailed. ].

	interpreterProxy primitiveFailForOSError: error errorCode.
	^error errorCode.

]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> simulatedFaPath [
	"Answer the simulated faPath.
	See class comments for details."

	^Array new: self sizeOfFaPath.
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> smallIntegerFromOop: anOop [
	"Answer a copy of the supplied large positive integer Oop"

	^interpreterProxy integerValueOf: anOop
]

{ #category : #private }
FileAttributesPluginSimulator >> structFromObject: anOop size: structSize [
	"Copy the object from the simulated image to the simulator.
	At the moment, all objects are passed in Arrays with structSize elements."

	| array |

	array := self fromOop: anOop.
	array isArray ifFalse: [^0].
	array size = structSize ifFalse: [^0].
	^array
]

{ #category : #'simulation support' }
FileAttributesPluginSimulator >> toOop: anObject [
	"Convert the supplied simulation object to an object in the simulated image (oop).
	Use a horrible series of class comparisons to keep it all local for now"

	| resultOop resultBytes |

	anObject class == Array ifTrue: [
		resultOop := interpreterProxy
						instantiateClass: interpreterProxy classArray
						indexableSize: anObject size.
		1 to: anObject size do: [ :i |
			interpreterProxy
				storePointer: i-1
				ofObject: resultOop
				withValue: (self toOop: (anObject at: i))].
		^resultOop].
	anObject class == ByteArray ifTrue: [
		resultOop := interpreterProxy
						instantiateClass: interpreterProxy classByteArray
						indexableSize: anObject size.
		resultBytes := interpreterProxy arrayValueOf: resultOop.
		1 to: anObject size do: [ :i |
			interpreterProxy byteAt: resultBytes+i-1 put: (anObject at: i)].
		^resultOop].
	(anObject isKindOf: Boolean) ifTrue: [
		^anObject
			ifTrue: [interpreterProxy trueObject]
			ifFalse: [interpreterProxy falseObject].
		].
	anObject isInteger ifTrue: [
		(anObject between: -2147483648 and: 2147483648) ifTrue:
			[^interpreterProxy signed32BitIntegerFor: anObject].
		^anObject > 0
			ifTrue: [interpreterProxy positive64BitIntegerFor: anObject]
			ifFalse: [interpreterProxy signed64BitIntegerFor: anObject]].
	anObject == nil ifTrue:
		[^interpreterProxy nilObject].
	anObject class == FAPathPtr ifTrue: [
		resultOop := interpreterProxy
						instantiateClass: interpreterProxy classArray
						indexableSize: 2.
		interpreterProxy
			storePointer: 0
			ofObject: resultOop
			withValue: (self toOop: anObject sessionId).
		interpreterProxy
			storePointer: 1
			ofObject: resultOop
			withValue: (self toOop: anObject faPath).
		^resultOop].
	self error: 'unknown object type'.
]
