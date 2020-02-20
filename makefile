# makefile for gitcm

LIBRARY=BARRY

all: git.pgm commitinf.pgm diff.pgm statuspgm.pgm wrkifspdm.pgm gitcm.pgm

git.pgm: pasecall.rpgle gitlogprse.rpgle git.rpgle
commitinf.pgm: pasecall.rpgle gitcmtprse.rpgle commitinf.rpgle
diff.pgm: pasecall.rpgle gitdiffget.rpgle diff.rpgle
statuspgm.pgm: pasecall.rpgle gitstatus.rpgle statuspgm.rpgle
wrkifspdm.pgm: pasecall.rpgle wrkifspdm.rpgle
gitcm.pgm: pasecall.rpgle gitcm.rpgle

git.rpgle: gitdsp.dspf git.cmd
commitinf.rpgle: commit.dspf
diff.rpgle: diffscrn.dspf
statuspgm.rpgle: status.dspf
wrkifspdm.rpgle: ifspdm.dspf wrkifspdm.cmd
gitcm.rpgle: gitcmdsp.dspf gitcm.cmd

%.pgm:
	$(eval modules := $(patsubst %,$(LIBRARY)/%,$(basename $(filter %.rpgle %.sqlrpgle,$(notdir $^)))))
	system "CRTPGM PGM($(LIBRARY)/$*) MODULE($(modules)) ENTMOD(*PGM)"

%.rpgle: src/%.rpgle
	system "CRTRPGMOD MODULE($(LIBRARY)/$*) SRCSTMF('$<') DBGVIEW(*SOURCE)"

%.dspf: src/%.dspf
	-system -q "CRTSRCPF FILE($(LIBRARY)/QSOURCE) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('$<') TOMBR('/QSYS.lib/$(LIBRARY).lib/QSOURCE.file/$(notdir $*).mbr') MBROPT(*REPLACE)"
	system "CRTDSPF FILE($(LIBRARY)/$*) SRCFILE($(LIBRARY)/QSOURCE) SRCMBR(*FILE)"

%.cmd: src/%.cmd
	-system -q "CRTSRCPF FILE($(LIBRARY)/QSOURCE) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('$<') TOMBR('/QSYS.lib/$(LIBRARY).lib/QSOURCE.file/$*.mbr') MBROPT(*REPLACE)"
	system "CRTCMD CMD($(LIBRARY)/$*) PGM($(LIBRARY)/$*) SRCFILE($(LIBRARY)/QSOURCE)"
