"
VMThreadingConstants ensureClassPool.
CogThreadManager classPool keys do:
	[:k| VMThreadingConstants classPool declare: k from: CogThreadManager classPool].
CoInterpreterMT classPool keys do:
	[:k| VMThreadingConstants classPool declare: k from: CoInterpreterMT classPool].
"
Class {
	#name : #VMThreadingConstants,
	#superclass : #SharedPool,
	#classVars : [
		'AWOLProcessesIncrement',
		'CTMAssignableOrInVM',
		'CTMInitializing',
		'CTMUnavailable',
		'CTMWantingOwnership',
		'ThreadIdIndex',
		'ThreadIdMask'
	],
	#category : #'VMMaker-Multithreading'
}
