
LIBRARY=BARRY

main.rpgle: main.dspf

%.rpgle:
	system "CRTBNDRPG PGM($(LIBRARY)/$*) SRCSTMF('src/$*.rpgle') DBGVIEW(*SOURCE)"

%.dspf: src/%.dspf
	-system -q "CRTSRCPF FILE($(LIBRARY)/QSOURCE) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('$<') TOMBR('/QSYS.lib/$(LIBRARY).lib/QSOURCE.file/$(notdir $*).mbr') MBROPT(*REPLACE)"
	system "CRTDSPF FILE($(LIBRARY)/$*) SRCFILE($(LIBRARY)/QSOURCE) SRCMBR(*FILE)"