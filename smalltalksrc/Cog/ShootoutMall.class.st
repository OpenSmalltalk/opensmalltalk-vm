Class {
	#name : #ShootoutMall,
	#superclass : #Object,
	#instVars : [
		'guard',
		'maxRendezvous',
		'open',
		'process',
		'queue',
		'cache',
		'pairCache'
	],
	#classVars : [
		'Units'
	],
	#category : #'Cog-Benchmarks'
}

{ #category : #'initialize-release' }
ShootoutMall class >> createAllowing: maxRendezvous [
   "Private"

   ^self basicNew initialize maxRendezvous: maxRendezvous
]

{ #category : #'initialize-release' }
ShootoutMall class >> createCreaturesWith: aCollectionOfColours [
   "Private"

   | aName |
   aName := 0.
   ^aCollectionOfColours collect:
         [:aColour |
         aName := aName + 1.
         ShootoutCreature withName: aName colour: aColour]
]

{ #category : #printing }
ShootoutMall class >> generateReportFor: creatures printOn: stream [
   | sum |
   sum := creatures inject: 0 into: [:accum :each | accum + each creaturesMet].
   creatures do:
         [:aCreature |
         aCreature creaturesMet printOn: stream.
         stream
            space;
            nextPutAll: (self units at: aCreature selfMet + 1);
            nl].
   stream space.
   sum printString
      do: [:el | stream nextPutAll: (self units at: el digitValue + 1)]
      separatedBy: [stream space].
   ^stream
]

{ #category : #printing }
ShootoutMall class >> generateReportForColours: colours printOn: stream [
   stream space.
   colours do: [:colour | colour printOn: stream] separatedBy: [stream space].
   ^stream
]

{ #category : #'initialize-release' }
ShootoutMall class >> initialize [
   "self initialize"

   Units := #('zero' 'one' 'two' 'three' 'four' 'five' 'six' 'seven' 'eight' 'nine')
]

{ #category : #'initialize-release' }
ShootoutMall class >> new [
   ^self shouldNotImplement
]

{ #category : #private }
ShootoutMall class >> openMall: aMall forCreatures: creatures usingGuard: sema [
   | processes |
   processes := creatures
            collect: [:aCreature |
               [aCreature visitMall: aMall.
               sema signal] newProcess].
   processes do:
         [:proc |
         proc priority: Processor userBackgroundPriority.
         proc resume]
]

{ #category : #'initialize-release' }
ShootoutMall class >> openMallWith: aCollectionOfColours forNumberOfMeets: aNumber [
   | mall creatures guard |
   mall := self createAllowing: aNumber.
   mall run.
   creatures := self createCreaturesWith: aCollectionOfColours.
   guard := Semaphore new.
   self
      openMall: mall
      forCreatures: creatures
      usingGuard: guard.
   self
      waitForClosingOfMall: mall
      withCreatures: creatures
      usingGuard: guard.
   ^creatures
]

{ #category : #public }
ShootoutMall class >> runBenchMark: number on: anOutputStream [
   "self runBenchMark: 60000 on: Transcript."

   | firstTestColours secondTestColours blue red yellow creatures |
   blue := ShootoutChameneosColour blue.
   red := ShootoutChameneosColour red.
   yellow := ShootoutChameneosColour yellow.
   firstTestColours := Array
            with: blue
            with: red
            with: yellow.
   secondTestColours := (OrderedCollection new)
            add: blue;
            add: red;
            add: yellow;
            add: red;
            add: yellow;
            add: blue;
            add: red;
            add: yellow;
            add: red;
            add: blue;
            yourself.
   (ShootoutChameneosColour generateReportOfColoursOn: anOutputStream) nl.
   (self generateReportForColours: firstTestColours printOn: anOutputStream)
      nl.
   creatures := ShootoutMall openMallWith: firstTestColours forNumberOfMeets: number.
   (self generateReportFor: creatures printOn: anOutputStream)
      nl;
      nl.
   (self generateReportForColours: secondTestColours printOn: anOutputStream)
      nl.
   creatures := ShootoutMall openMallWith: secondTestColours forNumberOfMeets: number.
   (self generateReportFor: creatures printOn: anOutputStream)
      nl;
      nl
]

{ #category : #accessing }
ShootoutMall class >> units [
   ^Units
]

{ #category : #private }
ShootoutMall class >> waitForClosingOfMall: aMall withCreatures: creatures usingGuard: guard [
   creatures size timesRepeat: [guard wait].
   aMall close
]

{ #category : #controlling }
ShootoutMall >> close [
   open := false
]

{ #category : #'initialize-release' }
ShootoutMall >> initialize [
   guard := Semaphore forMutualExclusion.
   queue := SharedQueue new.
   cache := OrderedCollection new.
   1 to: 10 do: [:x | cache add: ShootoutPair new]
]

{ #category : #accessing }
ShootoutMall >> maxRendezvous: max [
   maxRendezvous := max
]

{ #category : #private }
ShootoutMall >> obtainPair [
   ^cache removeFirst
]

{ #category : #private }
ShootoutMall >> processVisitors [
   [open] whileTrue:
         [1 to: maxRendezvous
            do:
               [:x |
               | first second |
               first := queue next.
               second := queue next.
               self setPartnersOn: first and: second.
               first signal.
               second signal].
         [queue isEmpty] whileFalse: [queue next signal]].
   process terminate.
   process := nil
]

{ #category : #private }
ShootoutMall >> releasePair: pair [
   pair release.
   cache addFirst: pair
]

{ #category : #'initialize-release' }
ShootoutMall >> run [
   open := true.
   process ifNil:
         [process := [self processVisitors] newProcess.
         process priority: Processor userBackgroundPriority -1 ].
   process resume
]

{ #category : #private }
ShootoutMall >> setPartnersOn: first and: second [
   first partner: second me.
   second partner: first me.

]

{ #category : #private }
ShootoutMall >> shutdown [
   [queue isEmpty] whileFalse: [queue next signal].
   process terminate.
   process := nil
]

{ #category : #controlling }
ShootoutMall >> visitWith: aChameneos [
   | pair partner |
   pair := self obtainPair.
   pair me: aChameneos.
   queue nextPut: pair.
   pair wait.
   partner := pair partner.
   self releasePair: pair.
   ^partner
]
