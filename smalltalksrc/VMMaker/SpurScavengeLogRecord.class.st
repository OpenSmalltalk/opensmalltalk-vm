Class {
	#name : #SpurScavengeLogRecord,
	#superclass : #VMStructType,
	#instVars : [
		'sEdenBytes',
		'sPastBytes',
		'sRememberedSetSize',
		'sRememberedSetRedZone',
		'sRememberedSetLimit',
		'sStatTenures',
		'tTenureCriterion',
		'tTenureThreshold',
		'tRefCountToShrinkRT',
		'eSurvivorBytes',
		'eRememberedSetSize',
		'eStatTenures'
	],
	#category : #'VMMaker-SpurMemoryManager'
}

{ #category : #translation }
SpurScavengeLogRecord class >> instVarNamesAndTypesForTranslationDo: aBinaryBlock [
	self allInstVarNames do:
		[:ivn|
		(SpurMemoryManager isNonArgumentImplicitReceiverVariableName: ivn) ifFalse:
			[aBinaryBlock value: ivn value: #usqInt]]
]

{ #category : #accessing }
SpurScavengeLogRecord >> eRememberedSetSize [
	
	^ eRememberedSetSize

]

{ #category : #accessing }
SpurScavengeLogRecord >> eRememberedSetSize: anObject [
	
	^ eRememberedSetSize := anObject.

]

{ #category : #accessing }
SpurScavengeLogRecord >> eStatTenures [
	
	^ eStatTenures

]

{ #category : #accessing }
SpurScavengeLogRecord >> eStatTenures: anObject [
	
	^ eStatTenures := anObject.

]

{ #category : #accessing }
SpurScavengeLogRecord >> eSurvivorBytes [
	
	^ eSurvivorBytes

]

{ #category : #accessing }
SpurScavengeLogRecord >> eSurvivorBytes: anObject [
	
	^ eSurvivorBytes := anObject.

]

{ #category : #accessing }
SpurScavengeLogRecord >> sEdenBytes [
	
	^ sEdenBytes

]

{ #category : #accessing }
SpurScavengeLogRecord >> sEdenBytes: anObject [
	
	^ sEdenBytes := anObject.

]

{ #category : #accessing }
SpurScavengeLogRecord >> sPastBytes [
	
	^ sPastBytes

]

{ #category : #accessing }
SpurScavengeLogRecord >> sPastBytes: anObject [
	
	^ sPastBytes := anObject.

]

{ #category : #accessing }
SpurScavengeLogRecord >> sRememberedSetLimit [
	
	^ sRememberedSetLimit

]

{ #category : #accessing }
SpurScavengeLogRecord >> sRememberedSetLimit: anObject [
	
	^ sRememberedSetLimit := anObject.

]

{ #category : #accessing }
SpurScavengeLogRecord >> sRememberedSetRedZone [
	
	^ sRememberedSetRedZone

]

{ #category : #accessing }
SpurScavengeLogRecord >> sRememberedSetRedZone: anObject [
	
	^ sRememberedSetRedZone := anObject.

]

{ #category : #accessing }
SpurScavengeLogRecord >> sRememberedSetSize [
	
	^ sRememberedSetSize

]

{ #category : #accessing }
SpurScavengeLogRecord >> sRememberedSetSize: anObject [
	
	^ sRememberedSetSize := anObject.

]

{ #category : #accessing }
SpurScavengeLogRecord >> sStatTenures [
	
	^ sStatTenures

]

{ #category : #accessing }
SpurScavengeLogRecord >> sStatTenures: anObject [
	
	^ sStatTenures := anObject.

]

{ #category : #accessing }
SpurScavengeLogRecord >> tRefCountToShrinkRT [
	
	^ tRefCountToShrinkRT

]

{ #category : #accessing }
SpurScavengeLogRecord >> tRefCountToShrinkRT: anObject [
	
	^ tRefCountToShrinkRT := anObject.

]

{ #category : #accessing }
SpurScavengeLogRecord >> tTenureCriterion [
	
	^ tTenureCriterion

]

{ #category : #accessing }
SpurScavengeLogRecord >> tTenureCriterion: anObject [
	
	^ tTenureCriterion := anObject.

]

{ #category : #accessing }
SpurScavengeLogRecord >> tTenureThreshold [
	
	^ tTenureThreshold

]

{ #category : #accessing }
SpurScavengeLogRecord >> tTenureThreshold: anObject [
	
	^ tTenureThreshold := anObject.

]
