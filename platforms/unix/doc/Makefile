MAIN = HowToBuildFromSource

all : $(MAIN).ps $(MAIN).html/$(MAIN).html $(MAIN).pdf $(MAIN).txt

dvi : $(MAIN).dvi

.SUFFIXES : .tex .dvi .ps .pdf .html .txt

.ps.pdf :
	ps2pdf $< $@

.dvi.ps :
#	dvips -P cmz -o $@ $<
	dvips -o $@ $<

.tex.dvi : .force
	latex $(MAIN).tex
	latex $(MAIN).tex
	makeindex $(MAIN).idx
	latex $(MAIN).tex

$(MAIN).html/%.html : %.tex Makefile
	test -d tmp || mkdir tmp
	latex2html -dir tmp -local_icons -auto_prefix -show_section_numbers -split 4 $(MAIN).tex
	test -d $(MAIN).html || mkdir $(MAIN).html
	cp -p tmp/*.html tmp/*.css tmp/*.png $(MAIN).html/.
	/bin/rm -rf tmp

$(MAIN).txt : $(MAIN).tex html2text.rc Makefile
	test -d tmp || mkdir tmp
	latex2html -dir tmp -nonavigation -noinfo -show_section_numbers -split 0 $(MAIN).tex
	html2text -rcfile html2text.rc -nobs tmp/$(MAIN).html | uniq > $@
	/bin/rm -rf tmp

clean : .force
	/bin/rm -f *~ *.{aux,idx,ilg,ind,log,out,toc}

distclean : clean
	/bin/rm -rf $(MAIN).html
	/bin/rm -f *.{dvi,ps,pdf,txt}

.force :
