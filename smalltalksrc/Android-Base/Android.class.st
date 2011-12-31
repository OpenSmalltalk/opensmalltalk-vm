"
Low-level interface to Android services
"
Class {
	#name : #Android,
	#superclass : #Object,
	#category : #'Android-Base'
}

{ #category : #'system primitives' }
Android class >> briefMessage: aString [
	"display a brief message (a toast) by means of Android runtime"
	<primitive: 'primBriefMessage' module: 'AndroidPlugin'>
	self primitiveFailed.
]

{ #category : #'system primitives' }
Android class >> createShortcutFor: aPath withLabel: aString andCommand: aCmd andIcon: aForm [
	"create a home screen shortcut for a given image"
	Android createShortcutFor: aPath 
		withLabel: aString 
		andCommand: aCmd 
		iconWH: ((aForm width << 16) bitOr: (aForm height))
		iconFlags: 0 
		iconBits: (aForm bits asByteArray).
]

{ #category : #'system primitives' }
Android class >> createShortcutFor: aPath withLabel: aString andCommand: aCmd iconWH: xy iconFlags: flg iconBits: b [
	"create a home screen shortcut for a given image"
	<primitive: 'primShortCut' module: 'AndroidPlugin'>
	self primitiveFailed.

]

{ #category : #'system primitives' }
Android class >> createShortcutFor: aPath withLabel: aString andIcon: aForm [
	"create a home screen shortcut for a given image"
	Android createShortcutFor: aPath 
		withLabel: aString 
		andCommand: '' 
		iconWH: ((aForm width << 16) bitOr: (aForm height))
		iconFlags: 0 
		iconBits: (aForm bits asByteArray).
]

{ #category : #'system primitives' }
Android class >> getClipboardString [
	"get a string from Android clipboard"
	<primitive: 'primGetClipboardString' module: 'AndroidPlugin'>
	self primitiveFailed.
]

{ #category : #'system primitives' }
Android class >> inAndroid [
	"answer true if running in Android"
	<primitive: 'primInAndroid' module: 'AndroidPlugin'>
	^false.
]

{ #category : #'system primitives' }
Android class >> setPitch: aFloat [
	"set TTS synthesized speech pitch"
	<primitive: 'primSetPitch' module: 'AndroidPlugin'>
	self primitiveFailed.
]

{ #category : #'system primitives' }
Android class >> setSpeechRate: aFloat [
	"set TTS synthesized speech rate"
	<primitive: 'primSetSpeechRate' module: 'AndroidPlugin'>
	self primitiveFailed.
]

{ #category : #'system primitives' }
Android class >> speak: aString [
	"speak the given string via TTS"
	<primitive: 'primSpeak' module: 'AndroidPlugin'>
	self primitiveFailed.
]
