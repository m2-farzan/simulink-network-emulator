default:
	mkdir output -p
	rm -f output/*.aux
	pdflatex -halt-on-error -output-directory output main.tex
	BSTINPUT="output:" TEXMFOUTPUT="output:" bibtex output/main
	pdflatex -halt-on-error -output-directory output main.tex
	pdflatex -halt-on-error -output-directory output main.tex
	ln -f output/main.pdf ./simulink-network-emulator-docs.pdf
	xdg-open simulink-network-emulator-docs.pdf

watch:
	make
	when-changed `ls -1 | grep -P '\.(tex)' | xargs` -c make     # may need to run "sudo pip install when-changed"

check:
	for TEXFILE in `ls -1 | grep -P '\.tex'`; do \
		aspell --dont-backup -t -c $$TEXFILE; \
	done

checkg:
	languagetool main.tex
