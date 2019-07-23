
LIBRARY=BARRY


main.pgm: pasecall.rpgle gitlogprse.rpgle main.rpgle
commitinf.pgm: pasecall.rpgle gitcmtprse.rpgle commitinf.rpgle

main.rpgle: main.dspf
commitinf.rpgle: commit.dspf

%.pgm:
	$(eval modules := $(patsubst %,$(LIBRARY)/%,$(basename $(filter %.rpgle %.sqlrpgle,$(notdir $^)))))
	system "CRTPGM PGM($(LIBRARY)/$*) MODULE($(modules)) ENTMOD(*PGM)"

%.rpgle:
	system "CRTRPGMOD MODULE($(LIBRARY)/$*) SRCSTMF('src/$*.rpgle') DBGVIEW(*SOURCE)"

%.dspf: src/%.dspf
	-system -q "CRTSRCPF FILE($(LIBRARY)/QSOURCE) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('$<') TOMBR('/QSYS.lib/$(LIBRARY).lib/QSOURCE.file/$(notdir $*).mbr') MBROPT(*REPLACE)"
	system "CRTDSPF FILE($(LIBRARY)/$*) SRCFILE($(LIBRARY)/QSOURCE) SRCMBR(*FILE)"