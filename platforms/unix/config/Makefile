configure : .force
	./mkacinc > acplugins.m4
	libtoolize
	command -v autoreconf2.69 && autoreconf2.69 --install --force || autoreconf --install --force
	rm acplugins.m4

.force :
