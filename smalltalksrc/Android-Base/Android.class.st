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

{ #category : #'system settings' }
Android class >> editingSettingsOn: aBuilder [
	<systemsettings>
	(aBuilder group: #Android)
		description: 'Android-specific VM settings' translated.
]

{ #category : #'system primitives' }
Android class >> getClipboardString [
	"get a string from Android clipboard"
	<primitive: 'primGetClipboardString' module: 'AndroidPlugin'>
	self primitiveFailed.
]

{ #category : #'system primitives' }
Android class >> getSDCardRoot [
	"get a string from Android clipboard"
	<primitive: 'primGetSDCardRoot' module: 'AndroidPlugin'>
	self primitiveFailed.
]

{ #category : #'system primitives' }
Android class >> getVMTimerInterval [
	"get VM idle timer interval"
	<primitive: 'primGetVMTimerInterval' module: 'AndroidPlugin'>
	self primitiveFailed.
]

{ #category : #'system primitives' }
Android class >> inAndroid [
	"answer true if running in Android"
	<primitive: 'primInAndroid' module: 'AndroidPlugin'>
	^false.
]

{ #category : #'system primitives' }
Android class >> onScreenKbd: anInteger [
	"show/hide the onscreen keyboard"
	<primitive: 'primOnScreenKbd' module: 'AndroidPlugin'>
	self primitiveFailed.
]

{ #category : #'system primitives' }
Android class >> openURI: aString [
	"open an URI in browser"
	<primitive: 'primOpenURI' module: 'AndroidPlugin'>
	self primitiveFailed.
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
Android class >> setVMTimerInterval: anInteger [
	"set VM idle timer interval"
	<primitive: 'primSetVMTimerInterval' module: 'AndroidPlugin'>
	self primitiveFailed.
]

{ #category : #'system primitives' }
Android class >> speak: aString [
	"speak the given string via TTS"
	<primitive: 'primSpeak' module: 'AndroidPlugin'>
	self primitiveFailed.
]

{ #category : #'system settings' }
Android class >> vmTimerInterval [
	^Android getVMTimerInterval.
]

{ #category : #'system settings' }
Android class >> vmTimerInterval: anInteger [
	"this message sets VM idle timer interval to the given number of milliseconds"
	"set to larger values if battery life is of concern"
	Android setVMTimerInterval: anInteger.
]

{ #category : #'system settings' }
Android class >> vmTimerIntervalOn: aBuilder [
	<systemsettings>
	(aBuilder setting: #vmTimerInterval)
		label: 'Android VM Idle Timer Interval (ms)' translated;
		parent: #Android;
		target: Android;
		description: 'Sets the Android VM idle timer interval in milliseconds: longer interval -> longer battery life' translated.
]
