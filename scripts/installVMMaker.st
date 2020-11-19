Author useAuthor: 'installVMMaker' during: [
	path := CommandLineArguments default commandLineArguments last.
	Metacello new
		baseline: 'VMMaker';
			repository: 'tonel://' , path , '/smalltalksrc';
			load.
]