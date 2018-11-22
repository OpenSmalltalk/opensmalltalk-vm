Extension { #name : #SmalltalkImage }

{ #category : #'*VMMaker-Interpreter' }
SmalltalkImage >> simulatePrimitive: aPrimitive args: args [
    "simulate primitives in RSqueak"
    "SNAPSHOT"
    (aPrimitive = 97 or: [aPrimitive = 247])
        ifTrue: [
            Smalltalk at: #SystemTracer2 ifPresent: [:st |
                |resuming|
                Smalltalk processStartUpList: false.
                [resuming := (st writeImage: Smalltalk imageName interactive: false) isStartingClone.]
                    on: FileExistsException
                    do: [ :e | e resume: (e fileClass forceNewFileNamed: e fileName)].
                Smalltalk processShutDownList: false.
                ^resuming]].
    ^InterpreterProxy new primitiveFailFor: 255.
]
