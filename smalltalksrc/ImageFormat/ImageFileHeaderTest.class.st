"
ImageFileHeaderTest provides unit tests for ImageFileHeader and CogImageFileHeader. These tests verify conversion to and from disk file format for various word sizes, platform endianness, and image formats.
"
Class {
	#name : #ImageFileHeaderTest,
	#superclass : #TestCase,
	#category : #'ImageFormat-Tests'
}

{ #category : #running }
ImageFileHeaderTest >> sample6504HeaderData [
	"First 200 bytes of an image file saved by an interpreter VM, an ImageFileHeader
	for a 32-bit image with closure support and no native platform float word order
	requirement (6504)"

	^#[104 25 0 0 64 0 0 0 4 127 88 8 16 0 0 0 196 175 67 5 175 67 0 0 151 3 160 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 209 143 131 0 5 0 0 30 89 145 131 0 5 0 160 24 149 144 131 0 5 0 12 23 15 129 56 0 140 122 24 0 12 22 0 0 4 1 0 0 36 49 132 0 0 50 188 26 88 198 24 0 3 0 0 0 8 197 24 0 3 0 0 0 64 188 24 0 3 0 0 0 88 188 24 0 3 0 0 0 76 188 24 0 3 0 0 0 52 188 24 0 3 0 0 0 72 124 24 0 3 0 0 0 112 129 24 0 3 0 0 0 36 199 24 0 3 0 0 0 100 199 24 0 3 0 0 0 132 197 24 0 3 0 0 0]
]

{ #category : #running }
ImageFileHeaderTest >> sample6505HeaderData [
	"First 200 bytes of an image file saved by a Cog VM, an ImageFileHeader for
	a 32-bit image with closure support and float words stored in native platform
	order (6505)"

	^#[105 25 0 0 64 0 0 0 28 181 88 8 0 224 70 183 180 143 138 188 71 229 231 47 151 3 160 4 2 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 193 111 202 183 5 0 0 30 73 113 202 183 5 0 160 24 133 112 202 183 5 0 12 23 15 129 56 0 124 90 95 183 252 245 70 183 4 1 0 0 20 17 203 183 0 50 188 26 72 166 95 183 3 0 0 0 248 164 95 183 3 0 0 0 48 156 95 183 3 0 0 0 72 156 95 183 3 0 0 0 60 156 95 183 3 0 0 0 36 156 95 183 3 0 0 0 56 92 95 183 3 0 0 0 96 97 95 183 3 0 0 0 20 167 95 183 3 0 0 0 84 167 95 183 3 0 0 0 116 165 95 183 3 0 0 0]
]

{ #category : #running }
ImageFileHeaderTest >> sample68002HeaderData [
	"First 200 bytes of a 64-bit image file saved by an interpreter VM, an
	ImageFileHeader for a 64-bit image with closure support and no native
	platform float word order requirement (68002)"

	^#[162 9 1 0 0 0 0 0 128 0 0 0 0 0 0 0 200 95 202 11 0 0 0 0 0 160 102 243 128 127 0 0 168 160 102 243 128 127 0 0 76 217 0 0 0 0 0 0 148 3 192 4 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 73 187 102 243 128 127 0 0 9 0 12 23 0 0 0 0 177 187 102 243 128 127 0 0 9 0 160 24 0 0 0 0 57 160 102 243 128 127 0 0 9 0 0 30 0 0 0 0 25 188 102 243 128 127 0 0 97 1 12 30 0 0 0 0 88 188 102 243 128 127 0 0]
]

{ #category : #testing }
ImageFileHeaderTest >> testAsByteArray [
	"Read and write with data in all byte positions"

	| hdr ws b1 b2 |
	b1 := self sample6505HeaderData.
	hdr := ImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: true.
	b2 := ws contents.
	self assert: hdr asByteArray = b2.
]

{ #category : #testing }
ImageFileHeaderTest >> testCogStoreOn [
	"Read and write with data in all byte positions"

	| hdr ws b1 b2 hdr2 |
	b1 := ByteArray new: 64.
	b1 at: 1 put: 104; at: 2 put: 25; at: 3 put: 0; at: 4 put: 0. "a valid image format number"
	b1 at: 5 put: 64; at: 6 put: 0; at: 7 put: 0; at: 8 put: 0. "header size 64"
	9 to: 64 do: [ :i | b1 at: i put: i ].
	hdr := CogImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ''.
	hdr storeOn: ws.
	hdr2 := Compiler evaluate: ws contents.
	ws := WriteStream on: ByteArray new.
	hdr2 writeTo: ws littleEndian: true.
	b2 := ws contents.
	self assert: (b2 first: 46) = (b1 first: 46).
	self assert: (b2 last: (64 - 46)) asSet size = 1. "all zeros"
]

{ #category : #testing }
ImageFileHeaderTest >> testReadWrite64BitBigEndian [
	"Read and write with data in all byte positions"

	| hdr ws b1 b2 |
	b1 := ByteArray new: 128.
	#[0 0 0 0 0 1 9 162 0 0 0 0 0 0 0 128] withIndexDo: [ :e :i | b1 at: i put: e].
	17 to: 128 do: [ :i | b1 at: i put: i ].
	hdr := ImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: false.
	b2 := ws contents.
	self assert: (b2 first: 72) = (b1 first: 72).
	self assert: (b2 last: (128 - 72)) asSet size = 1. "all zeros"
]

{ #category : #testing }
ImageFileHeaderTest >> testReadWrite64BitCogBigEndian [
	"Read and write with data in all byte positions"

	| hdr ws b1 b2 |
	b1 := ByteArray new: 128.
	#[0 0 0 0 0 1 9 162 0 0 0 0 0 0 0 128] withIndexDo: [ :e :i | b1 at: i put: e].
	17 to: 128 do: [ :i | b1 at: i put: i ].
	hdr := CogImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: false.
	b2 := ws contents.
	self assert: (b2 first: 92) = (b1 first: 92).
	self assert: (b2 last: (128 - 92)) asSet size = 1. "all zeros"
]

{ #category : #testing }
ImageFileHeaderTest >> testReadWrite64BitCogLittleEndian [
	"Read and write with data in all byte positions"

	| hdr ws b1 b2 |
	b1 := ByteArray new: 128.
	#[162 9 1 0 0 0 0 0 128 0 0 0 0 0 0 0] withIndexDo: [ :e :i | b1 at: i put: e].
	17 to: 128 do: [ :i | b1 at: i put: i ].
	hdr := CogImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: true.
	b2 := ws contents.
	self assert: (b2 first: 92) = (b1 first: 92).
	self assert: (b2 last: (128 - 92)) asSet size = 1. "all zeros"
]

{ #category : #testing }
ImageFileHeaderTest >> testReadWrite64BitLittleEndian [
	"Read and write with data in all byte positions"

	| hdr ws b1 b2 |
	b1 := ByteArray new: 128.
	#[162 9 1 0 0 0 0 0 128 0 0 0 0 0 0 0] withIndexDo: [ :e :i | b1 at: i put: e].
	17 to: 128 do: [ :i | b1 at: i put: i ].
	hdr := ImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: true.
	b2 := ws contents.
	self assert: (b2 first: 72) = (b1 first: 72).
	self assert: (b2 last: (128 - 72)) asSet size = 1. "all zeros"
]

{ #category : #testing }
ImageFileHeaderTest >> testReadWriteBigEndian [
	"Read and write with data in all byte positions"

	| hdr ws b1 b2 |
	b1 := ByteArray new: 64.
	b1 at: 4 put: 104; at: 3 put: 25; at: 2 put: 0; at: 1 put: 0. "a valid image format number"
	b1 at: 8 put: 64; at: 7 put: 0; at: 6 put: 0; at: 5 put: 0. "header size 64"
	9 to: 64 do: [ :i | b1 at: i put: i ].
	hdr := ImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: false.
	b2 := ws contents.
	self assert: (b2 first: 36) = (b1 first: 36).
	self assert: (b2 last: (64 - 36)) asSet size = 1. "all zeros"
]

{ #category : #testing }
ImageFileHeaderTest >> testReadWriteCogBigEndian [
	"Read and write with data in all byte positions"

	| hdr ws b1 b2 |
	b1 := ByteArray new: 64.
	b1 at: 4 put: 104; at: 3 put: 25; at: 2 put: 0; at: 1 put: 0. "a valid image format number"
	b1 at: 8 put: 64; at: 7 put: 0; at: 6 put: 0; at: 5 put: 0. "header size 64"
	9 to: 64 do: [ :i | b1 at: i put: i ].
	hdr := CogImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: false.
	b2 := ws contents.
	self assert: (b2 first: 46) = (b1 first: 46).
	self assert: (b2 last: (64 - 46)) asSet size = 1. "all zeros"
]

{ #category : #testing }
ImageFileHeaderTest >> testReadWriteCogLittleEndian [
	"Read and write with data in all byte positions"

	| hdr ws b1 b2 |
	b1 := ByteArray new: 64.
	b1 at: 1 put: 104; at: 2 put: 25; at: 3 put: 0; at: 4 put: 0. "a valid image format number"
	b1 at: 5 put: 64; at: 6 put: 0; at: 7 put: 0; at: 8 put: 0. "header size 64"
	9 to: 64 do: [ :i | b1 at: i put: i ].
	hdr := CogImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: true.
	b2 := ws contents.
	self assert: (b2 first: 46) = (b1 first: 46).
	self assert: (b2 last: (64 - 46)) asSet size = 1. "all zeros"
]

{ #category : #testing }
ImageFileHeaderTest >> testReadWriteLittleEndian [
	"Read and write with data in all byte positions"

	| hdr ws b1 b2 |
	b1 := ByteArray new: 64.
	b1 at: 1 put: 104; at: 2 put: 25; at: 3 put: 0; at: 4 put: 0. "a valid image format number"
	b1 at: 5 put: 64; at: 6 put: 0; at: 7 put: 0; at: 8 put: 0. "header size 64"
	9 to: 64 do: [ :i | b1 at: i put: i ].
	hdr := ImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: true.
	b2 := ws contents.
	self assert: (b2 first: 36) = (b1 first: 36).
	self assert: (b2 last: (64 - 36)) asSet size = 1. "all zeros"
]

{ #category : #testing }
ImageFileHeaderTest >> testSample6504Header [
	"Using data from a real file header, verify conversions"

	| hdr ws b1 b2 |
	b1 := self sample6504HeaderData.
	hdr := ImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: true.
	b2 := ws contents.
	self assert: b2 = (b1 first: 64).
]

{ #category : #testing }
ImageFileHeaderTest >> testSample6505Header [
	"Using data from a real file header, verify conversions"

	| hdr ws b1 b2 |
	b1 := self sample6505HeaderData.
	hdr := ImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: true.
	b2 := ws contents.
	self assert: b2 = (b1 first: 64).
]

{ #category : #testing }
ImageFileHeaderTest >> testSample68002Header [
	"Using data from a real file header, verify conversions"

	| hdr ws b1 b2 |
	b1 := self sample68002HeaderData.
	hdr := ImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ByteArray new.
	hdr writeTo: ws littleEndian: true.
	b2 := ws contents.
	self assert: b2 = (b1 first: 128).
]

{ #category : #testing }
ImageFileHeaderTest >> testStoreOn [
	"Read and write with data in all byte positions"

	| hdr ws b1 b2 hdr2 |
	b1 := ByteArray new: 64.
	b1 at: 1 put: 104; at: 2 put: 25; at: 3 put: 0; at: 4 put: 0. "a valid image format number"
	b1 at: 5 put: 64; at: 6 put: 0; at: 7 put: 0; at: 8 put: 0. "header size 64"
	9 to: 64 do: [ :i | b1 at: i put: i ].
	hdr := ImageFileHeader readFrom: (ReadStream on: b1).
	ws := WriteStream on: ''.
	hdr storeOn: ws.
	hdr2 := Compiler evaluate: ws contents.
	ws := WriteStream on: ByteArray new.
	hdr2 writeTo: ws littleEndian: true.
	b2 := ws contents.
	self assert: (b2 first: 36) = (b1 first: 36).
	self assert: (b2 last: (64 - 36)) asSet size = 1. "all zeros"
]
