"
IMPLEMENTATION NOTES:
The support should assume a trusted directory based on which access to files is granted when running in restricted mode. If necessary, links need to be resolved before granting access (currently, this applies only to platforms on which links can be created by simply creating the right kind of file).

The untrusted user directory returned MUST be different from the image and VM location. Otherwise a Badlet could attempt to overwrite these by using simple file primitives. The secure directory location returned by the primitive is a place to store per-user security information. Again, this place needs to be outside the untrusted space. Examples:

[Windows]
	* VM+image location: ""C:\Program Files\Squeak\""
	* secure directory location: ""C:\Program Files\Squeak\username\""
	* untrusted user directory: ""C:\My Squeak\username\""
[Unix]
	* VM+image location: ""/user/local/squeak""
	* secure directory location: ""~username/.squeak/
	* untrusted user directory: ""~username/squeak/""
[Mac]
	* plugin VM location: ""MacHD:Netscape:Plugins:""
	* standalone VM and image location: ""MacHD:Squeak:""
	* secure directory location: ""MacHD:Squeak:username:""
	* untrusted user directory: ""MacHD:My Squeak:username:""

Restoring the rights revoked by an image might be possible by some interaction with the VM directly. Any such action should be preceeded by a BIG FAT WARNING - the average user will never need that ability (if she does, we did something wrong) so this is a last resort in cases where something fundamtally tricky happened.

"
Class {
	#name : #SecurityPlugin,
	#superclass : #InterpreterPlugin,
	#category : #'VMMaker-Plugins'
}

{ #category : #translation }
SecurityPlugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #translation }
SecurityPlugin class >> requiresPlatformFiles [
	"default is ok for most, any plugin needing platform specific files must say so"
	^true
]

{ #category : #initialize }
SecurityPlugin >> initialiseModule [
	<export: true>
	^self cCode: 'ioInitSecurity()' inSmalltalk:[true]
]

{ #category : #primitives }
SecurityPlugin >> primitiveCanWriteImage [
	<export: true>
	interpreterProxy pop: 1.
	interpreterProxy pushBool: (self cCode:'ioCanWriteImage()' inSmalltalk:[true])
]

{ #category : #primitives }
SecurityPlugin >> primitiveDisableImageWrite [
	<export: true>
	self cCode: 'ioDisableImageWrite()'
]

{ #category : #primitives }
SecurityPlugin >> primitiveGetSecureUserDirectory [
	"Primitive. Return the secure directory for the current user."
	| dirName dirLen dirOop dirPtr |
	<export: true>
	<var: #dirName type: 'char *'>
	<var: #dirPtr type: 'char *'>
	dirName := self cCode: 'ioGetSecureUserDirectory()' inSmalltalk: [nil].
	(dirName == nil or:[interpreterProxy failed]) 
		ifTrue:[^interpreterProxy primitiveFail].
	dirLen := self strlen: dirName.
	dirOop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: dirLen.
	interpreterProxy failed ifTrue:[^nil].
	dirPtr := interpreterProxy firstIndexableField: dirOop.
	0 to: dirLen-1 do:[:i|
		dirPtr at: i put: (dirName at: i)].
	interpreterProxy pop: 1 thenPush: dirOop.
]

{ #category : #primitives }
SecurityPlugin >> primitiveGetUntrustedUserDirectory [
	"Primitive. Return the untrusted user directory name."
	| dirName dirLen dirOop dirPtr |
	<export: true>
	<var: #dirName type: 'char *'>
	<var: #dirPtr type: 'char *'>
	dirName := self cCode:'ioGetUntrustedUserDirectory()' inSmalltalk:[nil].
	(dirName == nil or:[interpreterProxy failed]) 
		ifTrue:[^interpreterProxy primitiveFail].
	dirLen := self strlen: dirName.
	dirOop := interpreterProxy instantiateClass: interpreterProxy classString indexableSize: dirLen.
	interpreterProxy failed ifTrue:[^nil].
	dirPtr := interpreterProxy firstIndexableField: dirOop.
	0 to: dirLen-1 do:[:i|
		dirPtr at: i put: (dirName at: i)].
	interpreterProxy pop: 1 thenPush: dirOop.
]

{ #category : #'exported functions' }
SecurityPlugin >> secCan: socket ListenOnPort: port [
	<export: true>
	^self cCode: 'ioCanListenOnPort(socket, port)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanConnect: addr ToPort: port [
	<export: true>
	^self cCode: 'ioCanConnectToPort(addr, port)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanCreate: netType SocketOfType: socketType [
	<export: true>
	^self cCode: 'ioCanCreateSocketOfType(netType, socketType)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanCreatePath: dirName OfSize: dirNameSize [
	<export: true>
	<var: #dirName type: 'char *'>
	^self cCode: 'ioCanCreatePathOfSize(dirName, dirNameSize)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanDeleteFile: fileName OfSize: fileNameSize [
	<export: true>
	<var: #fileName type: 'char *'>
	^self cCode: 'ioCanDeleteFileOfSize(fileName, fileNameSize)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanDeletePath: dirName OfSize: dirNameSize [
	<export: true>
	<var: #dirName type: 'char *'>
	^self cCode: 'ioCanDeletePathOfSize(dirName, dirNameSize)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanGetFileType: fileName OfSize: fileNameSize [
	<export: true>
	<var: #fileName type: 'char *'>
	^self cCode: 'ioCanGetFileTypeOfSize(fileName, fileNameSize)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanListPath: pathName OfSize: pathNameSize [
	<export: true>
	<var: #pathName type: 'char *'>
	^self cCode: 'ioCanListPathOfSize(pathName, pathNameSize)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanOpenAsyncFile: fileName OfSize: fileNameSize Writable: writeFlag [
	<export: true>
	<var: #fileName type: 'char *'>
	^self cCode: 'ioCanOpenAsyncFileOfSizeWritable(fileName, fileNameSize, writeFlag)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanOpenFile: fileName OfSize: fileNameSize Writable: writeFlag [
	<export: true>
	<var: #fileName type: 'char *'>
	^self cCode: 'ioCanOpenFileOfSizeWritable(fileName, fileNameSize, writeFlag)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanRenameFile: fileName OfSize: fileNameSize [
	<export: true>
	<var: #fileName type: 'char *'>
	^self cCode: 'ioCanRenameFileOfSize(fileName, fileNameSize)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanRenameImage [
	<export: true>
	^self ioCanRenameImage
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanSetFileType: fileName OfSize: fileNameSize [
	<export: true>
	<var: #fileName type: 'char *'>
	^self cCode: 'ioCanSetFileTypeOfSize(fileName, fileNameSize)'
]

{ #category : #'exported functions' }
SecurityPlugin >> secCanWriteImage [
	<export: true>
	^self ioCanWriteImage
]

{ #category : #'exported functions' }
SecurityPlugin >> secDisableFileAccess [
	<export: true>
	^self ioDisableFileAccess
]

{ #category : #'exported functions' }
SecurityPlugin >> secDisableSocketAccess [
	<export: true>
	^self ioDisableSocketAccess
]

{ #category : #'exported functions' }
SecurityPlugin >> secHasEnvironmentAccess [
	<export: true>
	^self ioHasEnvironmentAccess
]

{ #category : #'exported functions' }
SecurityPlugin >> secHasFileAccess [
	<export: true>
	^self ioHasFileAccess
]

{ #category : #'exported functions' }
SecurityPlugin >> secHasSocketAccess [
	<export: true>
	^self ioHasSocketAccess
]
