"
/********************************************************
 * An interface to LibMPEG3
 * Author: Adam Williams <broadcast@earthling.net>
 * Page: heroine.linuxbox.com
 *
 * Changed for Squeak to work with Squeak and to work on the Macintosh
 * Sept 2000, by John M McIntosh johnmci@smalltalkconsulting.com
 * The smalltalk code and the C code it produces is released under the 
 * Squeak licence. The libmpeg3 C code is co-licenced under either the Squeak licence or
 * the GNU LGPL
"
Class {
	#name : #Mpeg3Plugin,
	#superclass : #SmartSyntaxInterpreterPlugin,
	#instVars : [
		'maximumNumberOfFilesToWatch',
		'mpegFiles'
	],
	#category : #'VMMaker-Plugins'
}

{ #category : #'initialize-release' }
Mpeg3Plugin class >> declareCVarsIn: cg [ 
	super declareCVarsIn: cg.
	cg var: 'mpegFiles' declareC: 'mpeg3_t *mpegFiles[1024+1]'.

]

{ #category : #'initialize-release' }
Mpeg3Plugin class >> hasHeaderFile [
	"If there is a single intrinsic header file to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #'initialize-release' }
Mpeg3Plugin class >> requiresCrossPlatformFiles [
	"If there cross platform files to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #'initialize-release' }
Mpeg3Plugin class >> requiresPlatformFiles [
	"If there platform files to be associated with the plugin, here is where you want to flag"
	^true
]

{ #category : #support }
Mpeg3Plugin >> checkFileEntry: aMpegFile [
	<var: #aMpegFile type: 'mpeg3_t * '>
	1 to: maximumNumberOfFilesToWatch do: 
		[:i | ((mpegFiles at: i) = aMpegFile) ifTrue: 
				[^true]].
	^false.
		
	
]

{ #category : #support }
Mpeg3Plugin >> initialiseModule [
	<export: true>
	maximumNumberOfFilesToWatch := 1024.
	1 to: maximumNumberOfFilesToWatch do: [:i | mpegFiles at: i put: 0].
	^self cCode: 'true' inSmalltalk:[true]
]

{ #category : #support }
Mpeg3Plugin >> makeFileEntry: aMpegFile [
	<var: #aMpegFile type: 'mpeg3_t * '>
	1 to: maximumNumberOfFilesToWatch do: 
		[:i | ((mpegFiles at: i) = 0) ifTrue: 
				[mpegFiles at: i put: aMpegFile.
				^true]].
	^false
	"Ok no room just ignore, we'll get a primitive failure later"
		
	
]

{ #category : #support }
Mpeg3Plugin >> mpeg3tValueOf: mpeg3tHandle [ 
	"Return a pointer to the first byte of of the mpeg3_t record within the  
	given Smalltalk object, or nil if socketOop is not a mpeg3_t record."
	| index check |

	<returnTypeC: 'mpeg3_t *'>
	<var: #index type: 'mpeg3_t ** '>
	interpreterProxy success: ((interpreterProxy isBytes: mpeg3tHandle)
			and: [(interpreterProxy byteSizeOf: mpeg3tHandle)
					= 4]).
	interpreterProxy failed
		ifTrue: [^ nil]
		ifFalse: 
			[index := self cCoerce: (interpreterProxy firstIndexableField: mpeg3tHandle)
						to: 'mpeg3_t **'.
			self cCode: 'check = checkFileEntry(*index)'.
			check = 0 ifTrue: [^nil]. 
			^ self cCode: '*index']
]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3AudioChannels: fileHandle stream: aNumber [
	| file result |

	"int mpeg3_audio_channels(mpeg3_t *file,int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3AudioChannels'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^0].
	aNumber >= (self cCode: 'mpeg3_total_astreams(file)') ifTrue: [
		interpreterProxy success: false. ^0.
	].

	result := self cCode: 'mpeg3_audio_channels(file,aNumber)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3AudioSamples: fileHandle stream: aNumber [
	| file result |

	"long mpeg3_audio_samples(mpeg3_t *file, int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3AudioSamples'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'mpeg3_total_astreams(file)') ifTrue: [
		interpreterProxy success: false. ^0.
	].

	self cCode: 'result = mpeg3_audio_samples(file,aNumber)'.
	^result asOop: Float

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3CheckSig: path [
	| result sz storage |

	"int mpeg3_check_sig(char *path)"
	<var: #storage declareC: 'char storage[1024] '>
	self primitive: 'primitiveMPEG3CheckSig'
		parameters: #(String).
	sz := interpreterProxy byteSizeOf: path cPtrAsOop.
	interpreterProxy ioFilename: storage fromString: path ofLength: sz resolveAliases: true.
	self cCode: 'result = mpeg3_check_sig(storage)'.
	^result asOop: Boolean

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3Close: fileHandle [
	| file index |

	"int mpeg3_close(mpeg3_t *file)"
	<var: #file type: 'mpeg3_t * '>
	<var: #index type: 'mpeg3_t ** '>
	self primitive: 'primitiveMPEG3Close'
		parameters: #(Oop).
	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^nil].
	self cCode: 'removeFileEntry(file); mpeg3_close(file)'.
	index := self cCoerce: (interpreterProxy firstIndexableField: fileHandle)
						to: 'mpeg3_t **'.
	self cCode: '*index = 0'.

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3DropFrames: fileHandle frames: aFrameNumber stream: aNumber [
	| file result |

	"int mpeg3_drop_frames(mpeg3_t *file, long frames, int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3DropFrames'
		parameters: #(Oop SmallInteger SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_vstreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	self cCode: 'result = mpeg3_drop_frames(file,aFrameNumber,aNumber)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3EndOfAudio: fileHandle stream: aNumber [
	| file result |

	"int mpeg3_end_of_audio(mpeg3_t *file, int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3EndOfAudio'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_astreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].

	self cCode: 'result = mpeg3_end_of_audio(file,aNumber)'.
	^result asOop: Boolean

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3EndOfVideo: fileHandle stream: aNumber [
	| file result |

	"int mpeg3_end_of_video(mpeg3_t *file, int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3EndOfVideo'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_vstreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	self cCode: 'result = mpeg3_end_of_video(file,aNumber)'.
	^result asOop: Boolean

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3FrameRate: fileHandle stream: aNumber [
	| file result |

	"float mpeg3_frame_rate(mpeg3_t *file, int stream)"
	<var: #result type: 'double '>
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3FrameRate'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_vstreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	self cCode: 'result =  mpeg3_frame_rate(file,aNumber)'.
	^result asOop: Float

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3GenerateToc: fileHandle useSearch: timecode doStreams: streams buffer: aString [
	| file bufferSize |

	"int mpeg3_generate_toc_for_Squeak(FILE *output, char *path, int timecode_search, int print_streams, char *buffer)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3GenerateToc'
		parameters: #(Oop SmallInteger Boolean  String).
	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^nil].
	bufferSize := interpreterProxy slotSizeOf: (interpreterProxy stackValue: 0).
	self cCode: 'mpeg3_generate_toc_for_Squeak(file,timecode,streams,aString,bufferSize)'.

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3GetFrame: fileHandle stream: aNumber [
	| file result |

	"long mpeg3_get_frame(mpeg3_t *file,int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3GetFrame'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_vstreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].

	self cCode: 'result = mpeg3_get_frame(file,aNumber)'.
	^result asOop: Float.

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3GetSample: fileHandle stream: aNumber [
	| file result |

	"int mpeg3_video_width(mpeg3_t *file, int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3GetSample'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_astreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	self cCode: 'result = mpeg3_get_sample(file,aNumber)'.
	^result asOop: Float

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3GetTime: fileHandle [ 
	| file result |

	"double mpeg3_get_time(mpeg3_t *file)"
	<var: #result type: 'double '>
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3GetTime'
		parameters: #(Oop).
	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^nil].
	self cCode: 'result = mpeg3_get_time(file)'.
	^result asOop: Float.

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3HasAudio: fileHandle [
	| file result |

	"int mpeg3_has_audio(mpeg3_t *file)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3HasAudio'
		parameters: #(Oop).
	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^nil].
	self cCode: 'result = mpeg3_has_audio(file)'.
	^result asOop: Boolean

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3HasVideo: fileHandle [
	| file result |

	"int mpeg3_has_video(mpeg3_t *file)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3HasVideo'
		parameters: #(Oop).
	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^nil].
	self cCode: 'result = mpeg3_has_video(file)'.
	^result asOop: Boolean

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3Open: path [
	| mpeg3Oop index sz storage |

	"mpeg3_t* mpeg3_open(char *path)"
	<var: #index declareC: 'mpeg3_t ** index'>
	<var: #storage declareC: 'char storage[1024]'>
	self primitive: 'primitiveMPEG3Open'
		parameters: #(String).
	sz := interpreterProxy byteSizeOf: path cPtrAsOop.
	interpreterProxy ioFilename: storage fromString: path ofLength: sz resolveAliases: true.
	mpeg3Oop := interpreterProxy instantiateClass: interpreterProxy classByteArray
					indexableSize: 4.
	index := self cCoerce: (interpreterProxy firstIndexableField: mpeg3Oop)
						to: 'mpeg3_t **'.
	self cCode: '*index = mpeg3_open(storage,0); makeFileEntry(*index)'.
	^mpeg3Oop.

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3OpenABuffer: path size: size [
	| mpeg3Oop index |

	<var: #index declareC: 'mpeg3_t ** index'>
	self primitive: 'primitiveMPEG3OpenABuffer'
		parameters: #(String SmallInteger).
	mpeg3Oop := interpreterProxy instantiateClass: interpreterProxy classByteArray
					indexableSize: 4.	
	index := self cCoerce: (interpreterProxy firstIndexableField: mpeg3Oop)
						to: 'mpeg3_t **'.
	self cCode: '*index = mpeg3_open(path,size); makeFileEntry(*index)'.
	^mpeg3Oop.

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3PreviousFrame: fileHandle stream: aNumber [
	| file result |

	"int mpeg3_previous_frame(mpeg3_t *file, int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3PreviousFrame'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	file = nil ifTrue: [^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_vstreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	self cCode: 'result = mpeg3_previous_frame(file,aNumber)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3ReReadAudio: fileHandle shortArray: anArray channel: aChannelNumber samples: aSampleNumber stream: aNumber [
	| file result arrayBase |

	"int mpeg3_reread_audio(mpeg3_t *file, 
		float *output_f, 
		short *output_i, 
		int channel, 
		long samples,
		int stream)"
	<var: #file type: 'mpeg3_t * '>
	<var: #arrayBase type: 'short * '>
	self primitive: 'primitiveMPEG3ReReadAudio'
		parameters: #(Oop Array SmallInteger SmallInteger SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_astreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	arrayBase := self cCoerce: anArray to: 'short *'.
	interpreterProxy failed ifTrue: [^nil].
	self cCode: 'result = mpeg3_reread_audio(file,(float *) NULL,arrayBase,aChannelNumber,aSampleNumber,aNumber)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3ReadAudio: fileHandle shortArray: anArray channel: aChannelNumber samples: aSampleNumber stream: aNumber [
	| file result arrayBase |

	"int mpeg3_read_audio(mpeg3_t *file, 
		float *output_f, 
		short *output_i, 
		int channel, 
		long samples,
		int stream)"
	<var: #file type: 'mpeg3_t * '>
	<var: #arrayBase type: 'short * '>
	self primitive: 'primitiveMPEG3ReadAudio'
		parameters: #(Oop Array SmallInteger SmallInteger SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_astreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].
	arrayBase := self cCoerce: anArray to: 'short *'.
	interpreterProxy failed ifTrue: [^nil].

	self cCode: 'result = mpeg3_read_audio(file,(float *) NULL,arrayBase,aChannelNumber,aSampleNumber,aNumber)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3ReadFrame: fileHandle buffer: aBuffer bufferOffset: aBufferOffset x: xNumber y: yNumber w: width h: height ow: outWidth oh: outHeight colorModel: model stream: aNumber bytesPerRow: aByteNumber [ 
	| file result outputRowsPtr bufferBaseAddr |
	<var: #file declareC: 'mpeg3_t * file'>
	<var: #bufferBaseAddr declareC: 'unsigned char *bufferBaseAddr'>
	<var: #outputRowsPtr declareC: 'unsigned char  ** outputRowsPtr'>

	"int mpeg3_read_frame(mpeg3_t *file, 
		unsigned char **output_rows, 
		int in_x, 
		int in_y, 
		int in_w, 
		int in_h, 
		int out_w, 
		int out_h, 
		int color_model,
		int stream)"

	self primitive: 'primitiveMPEG3ReadFrameBufferOffset'
		parameters: #(Oop WordArray  SmallInteger SmallInteger  SmallInteger  SmallInteger  SmallInteger  SmallInteger  SmallInteger  SmallInteger  SmallInteger SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [ interpreterProxy success: false.  ^nil ].
	aNumber >= (self cCode: 'result = mpeg3_total_vstreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].

	bufferBaseAddr := self cCoerce: aBuffer to: 'unsigned char *'.
	self cCode: 'outputRowsPtr = (unsigned char **) memoryAllocate(1,sizeof(unsigned char*) * outHeight)'.

	0 to: outHeight-1 do: [:i | outputRowsPtr at: i put: (bufferBaseAddr + aBufferOffset + (aByteNumber*i))].
		
	self cCode: 'result = mpeg3_read_frame(file,outputRowsPtr,xNumber,yNumber,width,height,outWidth,outHeight,model,aNumber)'.
	self cCode: 'memoryFree(outputRowsPtr)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3ReadFrame: fileHandle buffer: aBuffer x: xNumber y: yNumber w: width h: height ow: outWidth oh: outHeight colorModel: model stream: aNumber bytesPerRow: aByteNumber [ 
	| file result outputRowsPtr bufferBaseAddr |
	<var: #file type: 'mpeg3_t * '>
	<var: #bufferBaseAddr type: 'unsigned char *'>
	<var: #outputRowsPtr type: 'unsigned char  ** '>

	"int mpeg3_read_frame(mpeg3_t *file, 
		unsigned char **output_rows, 
		int in_x, 
		int in_y, 
		int in_w, 
		int in_h, 
		int out_w, 
		int out_h, 
		int color_model,
		int stream)"

	self primitive: 'primitiveMPEG3ReadFrame'
		parameters: #(Oop WordArray  SmallInteger  SmallInteger  SmallInteger  SmallInteger  SmallInteger  SmallInteger  SmallInteger  SmallInteger SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [ interpreterProxy success: false.  ^nil ].
	aNumber >= (self cCode: 'result = mpeg3_total_vstreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].

	bufferBaseAddr := self cCoerce: aBuffer to: 'unsigned char *'.
	self cCode: 'outputRowsPtr = (unsigned char **) memoryAllocate(1,sizeof(unsigned char*) * outHeight)'.

	0 to: outHeight-1 do: [:i | outputRowsPtr at: i put: (bufferBaseAddr + (aByteNumber*i))].
		
	self cCode: 'result = mpeg3_read_frame(file,outputRowsPtr,xNumber,yNumber,width,height,outWidth,outHeight,model,aNumber)'.
	self cCode: 'memoryFree(outputRowsPtr)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3SampleRate: fileHandle stream: aNumber [
	| file result |

	"int mpeg3_sample_rate(mpeg3_t *file,int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3SampleRate'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_astreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	self cCode: 'result = mpeg3_sample_rate(file,aNumber)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3SeekPercentage: fileHandle percentage: aNumber [
	| file result |

	"int mpeg3_seek_percentage(mpeg3_t *file, double percentage)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3SeekPercentage'
		parameters: #(Oop Float).
	file := self mpeg3tValueOf: fileHandle.
	aNumber < 0.0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber > 1.0 ifTrue: [interpreterProxy success: false. ^nil].
	file = nil ifTrue: [^nil].
	self cCode: 'result = mpeg3_seek_percentage(file,aNumber)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3SetCpus: fileHandle number: cpus [
	| file |

	"int mpeg3_set_cpus(mpeg3_t *file, int cpus)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3SetCpus'
		parameters: #(Oop SmallInteger).
	file := self mpeg3tValueOf: fileHandle.
	cpus < 0 ifTrue: [interpreterProxy success: false. ^nil].
	file = nil ifTrue: [^nil].
	self cCode: 'mpeg3_set_cpus(file,cpus)'.

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3SetFrame: fileHandle frame: aFrameNumber stream: aNumber [
	| file result |

	"int mpeg3_set_frame(mpeg3_t *file, long frame, int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3SetFrame'
		parameters: #(Oop Float SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_vstreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	self cCode: 'result = mpeg3_set_frame(file,(long) aFrameNumber,aNumber)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3SetMmx: fileHandle useMmx: mmx [
	| file |

	"int mpeg3_set_mmx(mpeg3_t *file, int use_mmx)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3SetMmx'
		parameters: #(Oop Boolean).
	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^nil].
	self cCode: 'mpeg3_set_mmx(file,mmx)'.

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3SetSample: fileHandle sample: aSampleNumber stream: aNumber [
	| file result |

	"int mpeg3_set_sample(mpeg3_t *file, long sample, int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3SetSample'
		parameters: #(Oop Float SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_astreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	aSampleNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	self cCode: 'result = mpeg3_set_sample(file,aSampleNumber,aNumber)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3TellPercentage: fileHandle [
	| file result |

	"double mpeg3_tell_percentage(mpeg3_t *file)"
	<var: #result type: 'double '>
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3TellPercentage'
		parameters: #(Oop).
	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^nil].
	self cCode: 'result = mpeg3_tell_percentage(file)'.
	^result asOop: Float.

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3TotalAStreams: fileHandle [
	| file result |

	"int mpeg3_total_astreams(mpeg3_t *file)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3TotalAStreams'
		parameters: #(Oop).
	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	self cCode: 'result = mpeg3_total_astreams(file)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3TotalVStreams: fileHandle [
	| file result |

	"int mpeg3_total_vstreams(mpeg3_t *file)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3TotalVStreams'
		parameters: #(Oop).
	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^nil].
	self cCode: 'result = mpeg3_total_vstreams(file)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3VideoFrames: fileHandle stream: aNumber [
	| file result |

	"long mpeg3_video_frames(mpeg3_t *file, int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3VideoFrames'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_vstreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	self cCode: 'result = mpeg3_video_frames(file,aNumber)'.
	^result asOop: Float.

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3VideoHeight: fileHandle stream: aNumber [
	| file result |

	"int mpeg3_video_height(mpeg3_t *file,int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3VideoHeight'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_vstreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	self cCode: 'result = mpeg3_video_height(file,aNumber)'.
	^result asSmallIntegerObj

]

{ #category : #primitives }
Mpeg3Plugin >> primitiveMPEG3VideoWidth: fileHandle stream: aNumber [
	| file result |

	"int mpeg3_video_width(mpeg3_t *file, int stream)"
	<var: #file type: 'mpeg3_t * '>
	self primitive: 'primitiveMPEG3VideoWidth'
		parameters: #(Oop SmallInteger).

	file := self mpeg3tValueOf: fileHandle.
	file = nil ifTrue: [^0].
	aNumber < 0 ifTrue: [interpreterProxy success: false. ^nil].
	aNumber >= (self cCode: 'result = mpeg3_total_vstreams(file)') ifTrue: [
		interpreterProxy success: false.  ^0 ].


	self cCode: 'result = mpeg3_video_width(file,aNumber)'.
	^result asSmallIntegerObj

]

{ #category : #support }
Mpeg3Plugin >> removeFileEntry: aMpegFile [
	<var: #aMpegFile type: 'mpeg3_t * '>
	1 to: maximumNumberOfFilesToWatch do: 
		[:i | ((mpegFiles at: i) = aMpegFile) ifTrue: 
				[mpegFiles at: i put: 0.
				^true]].
	"Just ignore"
	^false
		
	
]

{ #category : #support }
Mpeg3Plugin >> shutdownModule [
	<export: true>
	1 to: maximumNumberOfFilesToWatch do: 
		[:i | ((mpegFiles at: i) ~= 0) ifTrue:
			[self cCode: 'mpeg3_close(mpegFiles[i])'.
			mpegFiles at: i put: 0]].
	^self cCode:  'true' inSmalltalk:[true]
]
