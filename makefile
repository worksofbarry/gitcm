
LIBRARY=BARRY

all: main.pgm commitinf.pgm diff.pgm statuspgm.pgm wrkifspdm.pgm

main.pgm: pasecall.rpgle gitlogprse.rpgle main.rpgle
commitinf.pgm: pasecall.rpgle gitcmtprse.rpgle commitinf.rpgle
diff.pgm: pasecall.rpgle gitdiffget.rpgle diff.rpgle
statuspgm.pgm: pasecall.rpgle gitstatus.rpgle statuspgm.rpgle
wrkifspdm.pgm: pasecall.rpgle wrkifspdm.rpgle

main.rpgle: main.dspf
commitinf.rpgle: commit.dspf
diff.rpgle: diffscrn.dspf
statuspgm.rpgle: status.dspf
wrkifspdm.rpgle: ifspdm.dspf

%.pgm:
	$(eval modules := $(patsubst %,$(LIBRARY)/%,$(basename $(filter %.rpgle %.sqlrpgle,$(notdir $^)))))
	system "CRTPGM PGM($(LIBRARY)/$*) MODULE($(modules)) ENTMOD(*PGM)"

%.rpgle:
	system "CRTRPGMOD MODULE($(LIBRARY)/$*) SRCSTMF('src/$*.rpgle') DBGVIEW(*SOURCE)"

%.dspf: src/%.dspf
	-system -q "CRTSRCPF FILE($(LIBRARY)/QSOURCE) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('$<') TOMBR('/QSYS.lib/$(LIBRARY).lib/QSOURCE.file/$(notdir $*).mbr') MBROPT(*REPLACE)"
	system "CRTDSPF FILE($(LIBRARY)/$*) SRCFILE($(LIBRARY)/QSOURCE) SRCMBR(*FILE)"