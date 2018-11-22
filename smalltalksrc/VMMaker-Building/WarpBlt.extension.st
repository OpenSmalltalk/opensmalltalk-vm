Extension { #name : #WarpBlt }

{ #category : #'*VMMaker-Interpreter-system simulation' }
WarpBlt >> warpBitsSimulated [
	"Simulate WarpBlt"

	cellSize < 1 ifTrue: [ ^self error: 'cellSize must be >= 1' ].

	self warpBitsSimulated: cellSize
		sourceMap: (sourceForm colormapIfNeededForDepth: 32).

]

{ #category : #'*VMMaker-Interpreter-system simulation' }
WarpBlt >> warpBitsSimulated: n sourceMap: sourceMap [
	"Simulate WarpBlt"
	^ BitBltSimulation warpBitsFrom: self
]
