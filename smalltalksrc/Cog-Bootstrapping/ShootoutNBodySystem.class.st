Class {
	#name : #ShootoutNBodySystem,
	#superclass : #Object,
	#instVars : [
		'bodies'
	],
	#category : #'Cog-Benchmarks'
}

{ #category : #nbody }
ShootoutNBodySystem >> after: dt [
	1 to: bodies size do: [:i|
		i+1 to: bodies size do: [:j|
			(bodies at: i) and: (bodies at: j) velocityAfter: dt].
	].
	bodies do: [:each| each positionAfter: dt]
]

{ #category : #nbody }
ShootoutNBodySystem >> energy [
	| e |
	e := 0.0.
	1 to: bodies size do: [:i|
		e := e + (bodies at: i) kineticEnergy.

		i+1 to: bodies size do: [:j|
			e := e - ((bodies at: i) potentialEnergy: (bodies at: j))].
	].
	^e
]

{ #category : #'initialize-release' }
ShootoutNBodySystem >> initialize [
	bodies := (OrderedCollection new
		add: ShootoutBody sun; add: ShootoutBody jupiter; add: ShootoutBody saturn;
		add: ShootoutBody uranus; add: ShootoutBody neptune; yourself) asArray.

	bodies first offsetMomentum:
		(bodies inject: (Array with: 0.0 with: 0.0 with: 0.0)
			into: [:m :each | each addMomentumTo: m])
]
