Class {
	#name : #ShootoutBody,
	#superclass : #Object,
	#instVars : [
		'x',
		'y',
		'z',
		'vx',
		'vy',
		'vz',
		'mass'
	],
	#category : #'Cog-Benchmarks'
}

{ #category : #constants }
ShootoutBody class >> daysPerYear [
	^365.24
]

{ #category : #constants }
ShootoutBody class >> jupiter [
	^self new
		x: 4.84143144246472090
		y: -1.16032004402742839
		z: -1.03622044471123109e-1
		vx: 1.66007664274403694e-3 * self daysPerYear
		vy: 7.69901118419740425e-3 * self daysPerYear
		vz: -6.90460016972063023e-5 * self daysPerYear
		mass: 9.54791938424326609e-4 * self solarMass
]

{ #category : #constants }
ShootoutBody class >> neptune [
	^self new
		x: 1.53796971148509165e1
		y: -2.59193146099879641e1
		z: 1.79258772950371181e-1
		vx: 2.68067772490389322e-3 * self daysPerYear
		vy: 1.62824170038242295e-3 * self daysPerYear
		vz: -9.51592254519715870e-5 * self daysPerYear
		mass: 5.15138902046611451e-5 * self solarMass
]

{ #category : #constants }
ShootoutBody class >> pi [
	^3.141592653589793
]

{ #category : #constants }
ShootoutBody class >> saturn [
	^self new
		x: 8.34336671824457987
		y: 4.12479856412430479
		z: -4.03523417114321381e-1
		vx: -2.76742510726862411e-3 * self daysPerYear
		vy: 4.99852801234917238e-3 * self daysPerYear
		vz: 2.30417297573763929e-5 * self daysPerYear
		mass: 2.85885980666130812e-4 * self solarMass
]

{ #category : #constants }
ShootoutBody class >> solarMass [
	^4.0 * self pi * self pi
]

{ #category : #constants }
ShootoutBody class >> sun [
	^self new
		x: 0.0
		y: 0.0
		z: 0.0
		vx: 0.0
		vy: 0.0
		vz: 0.0
		mass: self solarMass
]

{ #category : #constants }
ShootoutBody class >> uranus [
	^self new
		x: 1.28943695621391310e1
		y: -1.51111514016986312e1
		z: -2.23307578892655734e-1
		vx: 2.96460137564761618e-3 * self daysPerYear
		vy: 2.37847173959480950e-3 * self daysPerYear
		vz: -2.96589568540237556e-5 * self daysPerYear
		mass: 4.36624404335156298e-5 * self solarMass
]

{ #category : #nbody }
ShootoutBody >> addMomentumTo: anArray [
	anArray at: 1 put: (anArray at: 1) + (vx * mass).
	anArray at: 2 put: (anArray at: 2) + (vy * mass).
	anArray at: 3 put: (anArray at: 3) + (vz * mass).
	^anArray
]

{ #category : #nbody }
ShootoutBody >> and: aBody velocityAfter: dt [
	| dx dy dz distance mag |
	dx := x - aBody x.
	dy := y - aBody y.
	dz := z - aBody z.

	distance := ((dx*dx) + (dy*dy) + (dz*dz)) sqrt.
	mag := dt / (distance * distance * distance).

	self decreaseVelocity: dx y: dy z: dz m: aBody mass * mag.
	aBody increaseVelocity: dx y: dy z: dz m: mass * mag
]

{ #category : #nbody }
ShootoutBody >> decreaseVelocity: dx y: dy z: dz m: m [
	vx := vx - (dx * m).
	vy := vy - (dy * m).
	vz := vz - (dz * m)
]

{ #category : #nbody }
ShootoutBody >> increaseVelocity: dx y: dy z: dz m: m [
	vx := vx + (dx * m).
	vy := vy + (dy * m).
	vz := vz + (dz * m)
]

{ #category : #nbody }
ShootoutBody >> kineticEnergy [
	^0.5 * mass * ((vx * vx) + (vy * vy) + (vz * vz))
]

{ #category : #accessing }
ShootoutBody >> mass [
	^mass
]

{ #category : #nbody }
ShootoutBody >> offsetMomentum: anArray [
	| m |
	m := self class solarMass.
	vx := (anArray at: 1) negated / m.
	vy := (anArray at: 2) negated / m.
	vz := (anArray at: 3) negated / m
]

{ #category : #nbody }
ShootoutBody >> positionAfter: dt [
	x := x + (dt * vx).
	y := y + (dt * vy).
	z := z + (dt * vz)
]

{ #category : #nbody }
ShootoutBody >> potentialEnergy: aBody [
	| dx dy dz distance |
	dx := x - aBody x.
	dy := y - aBody y.
	dz := z - aBody z.

	distance := ((dx*dx) + (dy*dy) + (dz*dz)) sqrt.
	^mass * aBody mass / distance
]

{ #category : #accessing }
ShootoutBody >> x [
	^x
]

{ #category : #accessing }
ShootoutBody >> x: d1 y: d2 z: d3 vx: d4 vy: d5 vz: d6 mass: d7 [
	x := d1.
	y := d2.
	z := d3.
	vx := d4.
	vy := d5.
	vz := d6.
	mass := d7
]

{ #category : #accessing }
ShootoutBody >> y [
	^y
]

{ #category : #accessing }
ShootoutBody >> z [
	^z
]
