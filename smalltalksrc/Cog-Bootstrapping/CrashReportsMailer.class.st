"
This class generates an almost complete crash report that still needs editing for categories and then posts it after editing.
"
Class {
	#name : #CrashReportsMailer,
	#superclass : #Object,
	#instVars : [
		'mailDirectory',
		'destination',
		'startDate',
		'endDate',
		'rs',
		'causes',
		'soloTime',
		'meetingTime'
	],
	#pools : [
		'ChronologyConstants'
	],
	#category : #'Cog-Scripts'
}

{ #category : #'instance creation' }
CrashReportsMailer class >> mailDirectory: aFileDirectoryOrString destination: anEmailAddress week: startDate [
	^self new
		mailDirectory: aFileDirectoryOrString
		destination: anEmailAddress
		startDate: (TimeStamp fromSeconds: startDate asDate asSeconds)
		endDate:  (TimeStamp fromSeconds: (startDate asDate addDays: 7) asSeconds)

	"(self mailDirectory: '/Users/eliot/Library/Mail/IMAP-emiranda@ussc9-mail01.qwaq.com/INBOX.imapmbox/Messages'
		destination: 'eng@teleplace.com'
		week: '05/15/2010') generateReport"
]

{ #category : #'instance creation' }
CrashReportsMailer class >> mailDirectory: aFileDirectoryOrString destination: anEmailAddress week: startDateString soloTime: soloDurationOrString meetingTime: meetingDurationOrString [
	| startDate |
	startDate := ((startDateString includes: $-)
					ifTrue: [(#(2 3 1) collect: [:i| (startDateString subStrings: '-') at: i]) fold: [:a :b| a,'/',b]]
					ifFalse: [startDateString]) asDate.
	^self new
		mailDirectory: aFileDirectoryOrString
		destination: anEmailAddress
		startDate: (TimeStamp fromSeconds: startDate asSeconds)
		endDate:  (TimeStamp fromSeconds: (startDate addDays: 7) asSeconds - 1)
		soloTime: soloDurationOrString asDuration
		meetingTime: meetingDurationOrString asDuration

	"(self mailDirectory: '/Users/eliot/Library/Mail/IMAP-emiranda@ussc9-mail01.qwaq.com/INBOX.imapmbox/Messages'
		destination: 'eng@teleplace.com'
		week: '05/15/2010'
		soloTime: '20:19:38:55'
		meetingTime: '7:23:44:45') generateReport"
]

{ #category : #reporting }
CrashReportsMailer >> addReportFor: lines [
	rs	resetContents;
		tab;
		nextPutAll: ((lines detect: [:l| l beginsWith: 'Subject:']) ifNotNil:
							[:l| l allButFirst: (l indexOfSubCollection: ' Teleplace Bug')]);
		crtab: 2;
		nextPutAll: (lines detect: [:l| l beginsWith: 'Date:']);
		cr.
	((lines anySatisfy: [:l| (l beginsWith: 'OS Version') and: [l includesSubstring: 'Mac OS X']])
		ifTrue: [self reportForMacOS: lines]
		ifFalse: [(lines anySatisfy: [:l| l beginsWith: 'Module:'])
					ifTrue: [self reportForOldWin32: lines]
					ifFalse: [self reportForNewWin32: lines]]) ifNotNil:
			[:cause|
			(causes at: cause ifAbsentPut: [OrderedCollection new])
				addLast: rs contents]
]

{ #category : #parsing }
CrashReportsMailer >> breakIntoLines: aString [
	^self pruneBogusEmptyLines:
		(Array streamContents:
			[:os| | is ss char |
			is := aString readStream.
			ss := ReadWriteStream on: String new.
			[is atEnd] whileFalse:
				[(char := is next) = Character lf
					ifTrue:
						[os nextPut: ss contents.
						 ss resetContents]
					ifFalse: [ss nextPut: char]].
			ss position > 0 ifTrue:
				[os nextPut: ss contents]])
]

{ #category : #parsing }
CrashReportsMailer >> candidateMessagesDo: aBlock [
	"Evaluate aBlock with the file names of every file newer than the start date minus some slop"
	| start |
	start := (startDate minusDays: 7) asSeconds.
	mailDirectory entries do:
		[:dirEntry|
		((dirEntry name endsWith: '.emlx')
		 and: [dirEntry creationTime > start]) ifTrue:
			[aBlock value: dirEntry name]]
]

{ #category : #reporting }
CrashReportsMailer >> collectReportSummaries [
	self candidateMessagesDo:
		[:fn|
		self ifCrashReport: fn do:
			[:lines|
			self addReportFor: lines]]
]

{ #category : #reporting }
CrashReportsMailer >> generateFinalReport [
	| count numMac ws |
	count := causes inject: 0 into: [:sum :collection| sum + collection size].
	rs reset.
	rs print: count; nextPutAll: ' VM Crashes. ? OpenGL. ? Audio plugin. ? Video plugin. ? Python plugin.  ? core VM. ? unknown.'; cr.
	numMac := (causes keys select: [:k| k beginsWith: 'Mac:']) size.
	rs nextPutAll: 'win: '; print: count- numMac; cr.
	rs nextPutAll: 'mac: '; print: numMac; cr; cr.
	self reportCrashRates: count.
	causes keys asSortedCollection do:
		[:k|
		(causes at: k) do:
			[:report| rs nextPutAll: report].
		rs nextPutAll: k; cr; cr].
	(ws := Workspace new contents: rs contents)
		acceptAction: [:s| (UIManager default confirm: 'Sure you want to send?') ifTrue:
							[self mailReport: s.
							 ws acceptAction:
								[(UIManager default confirm: 'You''ve already sent this. Sure you want to send again?') ifTrue:
										[self mailReport: s]]]];
		openLabel: 'Customer VM Crashes ', startDate date printString, ' to ', endDate date printString;
		shouldStyle: false
]

{ #category : #reporting }
CrashReportsMailer >> generateReport [
	causes := Dictionary new.
	self collectReportSummaries.
	self generateFinalReport
]

{ #category : #parsing }
CrashReportsMailer >> ifCrashReport: fileName do: aBlock [
	"Answer the evaluation of aBlock with the lines for fileName if it is a crash report, or nil if not."
	| file lines subject |
	file := mailDirectory oldFileNamed: fileName.
	lines := [file contentsOfEntireFile]
				on: Error
				do: [:ex|
					file close.
					Transcript nextPutAll: fileName; nextPutAll: ': '; nextPutAll: ex messageText; flush.
					^nil].
	lines := self breakIntoLines: lines.
	subject := lines detect: [:l| l beginsWith: 'Subject:'] ifNone: [^nil].
	(subject includesSubstring: 'Teleplace Bug Report: ') ifFalse: [^nil].
	#('@qwaq.com' '@teleplace.com' '@chonkaa.com' 'craig@netjam.org' 'skysound@mac.com') do:
		[:localEmail| (subject includesSubstring: localEmail caseSensitive: false) ifTrue: [^nil]].
	(lines anySatisfy:
		[:l|
		((l beginsWith: 'OS Version') and: [l includesSubstring: 'Mac OS X'])
		or: [l beginsWith: 'Operating System:']]) ifFalse: [^nil].
	^aBlock value: lines
]

{ #category : #reporting }
CrashReportsMailer >> macOSDateFor: dateString [ 
	| tokens |
	tokens := dateString subStrings: ' -.+'.
	^TimeStamp
		date: (Date year: tokens first asInteger month: tokens second asInteger day: tokens third asInteger)
		time: tokens fourth asTime
]

{ #category : #'initialize-release' }
CrashReportsMailer >> mailDirectory: aFileDirectoryOrString destination: anEmailAddress startDate: startTimestamp endDate: endTimestamp [
	mailDirectory := aFileDirectoryOrString isString
						ifTrue: [FileDirectory on: aFileDirectoryOrString]
						ifFalse: [aFileDirectoryOrString].
	destination := anEmailAddress.
	startDate := startTimestamp.
	endDate := endTimestamp.
	rs := ReadWriteStream on: (String new: 256)
]

{ #category : #'initialize-release' }
CrashReportsMailer >> mailDirectory: aFileDirectoryOrString destination: anEmailAddress startDate: startTimestamp endDate: endTimestamp soloTime: soloDuration meetingTime: meetingDuration [
	mailDirectory := aFileDirectoryOrString isString
						ifTrue: [FileDirectory on: aFileDirectoryOrString]
						ifFalse: [aFileDirectoryOrString].
	destination := anEmailAddress.
	startDate := startTimestamp.
	endDate := endTimestamp.
	soloTime := soloDuration.
	meetingTime := meetingDuration.
	rs := ReadWriteStream on: (String new: 256)
]

{ #category : #mailing }
CrashReportsMailer >> mailReport: aText [
	| msg |
	msg := MailMessage new
			setField: 'from' toString: 'eliot@teleplace.com';
			setField: 'to' toString: destination;
			setField: 'subject' toString:	'Customer VM Crashes ',
										(startDate date printFormat: #(3 2 1 $/ 1 2)),
										' - ',
										((endDate - 1 seconds) date printFormat: #(3 2 1 $/ 1 2));
			body: (MIMEDocument contentType: 'text/plain' content: aText asString).
	SMTPClient
		deliverMailFrom: msg from
		to: (Array with: msg to)
		text: msg text
		usingServer: MailComposition new smtpServer
]

{ #category : #parsing }
CrashReportsMailer >> pruneBogusEmptyLines: lines [
	"Eliminate duplicate empty lines from broken CR-LF to LF-LF conversions."
	| firstEmpty lastEmpty |
	(firstEmpty := lines findFirst: [:l| l isEmpty]) = 0 ifTrue:
		[^lines].
	lastEmpty := firstEmpty.
	[(lines at: lastEmpty + 2) isEmpty] whileTrue:
		[lastEmpty := lastEmpty + 2].
	^(lines copyFrom: 1 to: firstEmpty - 1),
	   ((firstEmpty + 1 to: lastEmpty - 1 by: 2) collect: [:i| lines at: i]),
	   (lines copyFrom: lastEmpty + 1 to: lines size)
]

{ #category : #reporting }
CrashReportsMailer >> reportCrashRates: count [
	{ soloTime. meetingTime }
		with: #('solo hours: ' 'meeting hours: ')
		do: [:time :label|
			rs	nextPutAll: label; print: (time asSeconds / SecondsInHour) rounded;
				space; nextPut: $(; print: time; nextPut: $); cr].
	rs cr.
	{ soloTime. meetingTime }
		with: #('solo' 'meeting')
		do: [:time :label|
			{ SecondsInHour. SecondsInDay }
				with: #('hour' 'day')
				do: [:period :periodLabel| | rate |
					rate := count / (time asSeconds / period).
					rs	print: (rate roundTo: (rate >= 1 ifTrue: [0.1] ifFalse: [0.001]));
						nextPutAll: ' crashes per '; nextPutAll: label; space; nextPutAll: periodLabel; cr]].
	rs cr; cr
]

{ #category : #reporting }
CrashReportsMailer >> reportForMacOS: lines [
	| thread dateAndTime cStackTop cstIdx |

	thread := Integer readFrom: ((lines detect: [:l| l beginsWith: 'Crashed Thread: ']) allButFirst: 15) readStream skipSeparators.
	thread := 'Thread ', thread printString, ' Crashed'.
	lines withIndexDo:
		[:l :i|
		(l beginsWith: 'Date/Time:') ifTrue:
			[dateAndTime := l allButFirst: 11].
		((l beginsWith: thread)
		and: [i < lines size]) ifTrue:
			[cStackTop := lines at: (cstIdx := i + 1)]].
	[cstIdx <= lines size
	 and: [(lines at: cstIdx) notEmpty]] whileTrue:
		[(((lines at: cstIdx) includesSubstring: ' _sigtramp ')
		 and: [((lines at: cstIdx + 1) includesSubstring: ' ??? ')
		 and: [((lines at: cstIdx + 1) includesSubstring: '0xffffffff 0 + 4294967295')]]) ifTrue:
			[cStackTop := lines at: cstIdx + 2.
			 cstIdx := lines size].
		 cstIdx := cstIdx + 1].
	dateAndTime := self macOSDateFor: dateAndTime.
	(dateAndTime between: startDate and: endDate) ifFalse:
		[^nil].
	^'Mac:', (cStackTop allButFirst: (cStackTop indexOf: Character space))
]

{ #category : #reporting }
CrashReportsMailer >> reportForNewWin32: lines [
	| dateAndTime reason stStackTop cStackTop |

	lines withIndexDo:
		[:l :i|
		(l beginsWith: 'Session Summary:') ifTrue:
			[^nil]. "Not a VM bug report, ignore it."
		(dateAndTime isNil
		and: [(l beginsWith: '--------------------')
		and: [i < lines size]]) ifTrue:
			[dateAndTime := lines at: i + 1].
		((l beginsWith: 'Smalltalk stack dump:')
		and: [i < lines size]) ifTrue:
			[stStackTop := lines at: i + 1].
		((l beginsWith: 'Stack backtrace:')
		and: [i < lines size]) ifTrue:
			[cStackTop := lines at: i + 1]].
	dateAndTime isNil ifTrue:
		[^nil].
	dateAndTime := self win32DateFor: dateAndTime.
	(dateAndTime between: startDate and: endDate) ifFalse:
		[^nil].
	reason := (lines detect: [:l| l beginsWith: 'Reason: '] ifNone: []) ifNotNil: [:rl| rl allButFirst: 8].
	"a stack entry looks like
		 0x9c2490 I NetNameResolver class>localHostAddress 271185968: a(n) NetNameResolver class
		t293325136 s BlockClosure>on:do:"
	stStackTop ifNotNil:
		[stStackTop := (stStackTop subStrings: ' ') allButFirst: 2.
		 stStackTop := stStackTop first: (stStackTop findFirst: [:t| t first isDigit]) - 1.
		 stStackTop := stStackTop fold: [:a :b| a, ' ', b]].
	^String streamContents:
		[:s|
		reason ifNotNil: [s nextPutAll: reason; cr].
	 	stStackTop ifNotNil: [s nextPutAll: stStackTop; cr].
		cStackTop ifNotNil: [s nextPutAll: cStackTop]]
]

{ #category : #reporting }
CrashReportsMailer >> reportForOldWin32: lines [
	| dateAndTime module idx stackTop |

	lines withIndexDo:
		[:l :i|
		(dateAndTime isNil
		and: [(l beginsWith: '--------------------')
		and: [i < lines size]]) ifTrue:
			[dateAndTime := lines at: i + 1].
		((l beginsWith: 'Stack dump:')
		and: [i < lines size]) ifTrue:
			 "Occasionally there is a bogus blank line between the label and the first entry"
			[(stackTop := (lines at: i + 1) isEmpty) ifTrue:
				[stackTop := lines at: i + 2]]].
	dateAndTime := self win32DateFor: dateAndTime.
	(dateAndTime between: startDate and: endDate) ifFalse:
		[^nil].
	module := (lines detect: [:l| l beginsWith: 'Module: ']) allButFirst: 8.
	(idx := module indexOfSubCollection: '\Teleplace') > 0 ifTrue:
		[module := module copyFrom: idx to: module size].
	(module first isLetter and: [module second = $:]) ifTrue:
		[module := module allButFirst: 2].
	"a stack entry looks like
		 0x9c2490 I NetNameResolver class>localHostAddress 271185968: a(n) NetNameResolver class
		293325136 s BlockClosure>on:do:
	 but if there is no stack there may be any old crap after Stack dump: so squash errors."
	[stackTop := (stackTop subStrings: ' ') allButFirst: 2.
	 stackTop := stackTop first: (stackTop findFirst: [:t| t first isDigit]) - 1.
	 stackTop := stackTop fold: [:a :b| a, ' ', b]]
		on: Error
		do: [:ex| stackTop := '?'].
	^stackTop, ' in ', module
]

{ #category : #reporting }
CrashReportsMailer >> win32DateFor: dateAndTimeString [ 
	"transform 'Thu Jun 24 14:11:18 2010' to 'Jun 24 2010 14:11:18' to allow parsing"
	| tokens |
	tokens := dateAndTimeString subStrings: ' '.
	^({ tokens second. tokens third. tokens fifth. tokens fourth } fold: [:a :b| a, ' ', b]) asTimeStamp
]
