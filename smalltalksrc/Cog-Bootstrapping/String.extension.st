Extension { #name : #String }

{ #category : #'*Cog-script support' }
String >> extractSelector [
	"Dan's code for hunting down selectors with keyword parts; while this doesn't give a true parse,
	 in most cases it does what we want, and where it doesn't, we're none the worse for it.
	 Unlike findSelector this doesn't require that the poutative selector has been interned."
	| sel possibleParens |
	sel := self withBlanksTrimmed.
	(sel includes: $:) ifTrue:
		[sel := sel copyReplaceAll: ':' with: ': '.	"for the style (aa max:bb) with no space"
		sel := sel copyReplaceAll: '[:' with: '[ :'.    "for the style ([:a) with no space"  
		possibleParens := sel findTokens: Character separators.
		sel := self class streamContents:
			[:s | | level |
			level := 0.
			possibleParens do:
				[:token |
				(level = 0 and: [token endsWith: ':'])
					ifTrue: [s nextPutAll: token]
					ifFalse: [level := level
							+ (token occurrencesOf: $() - (token occurrencesOf: $))
							+ (token occurrencesOf: $[) - (token occurrencesOf: $])
							+ (token occurrencesOf: ${) - (token occurrencesOf: $})]]]].
	sel isEmpty ifTrue: [^ nil].
	^sel
]
