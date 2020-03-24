LIBRARY=BARRY
SYSTEM_PARMS=-s

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
	system $(SYSTEM_PARMS) "CRTPGM PGM($(LIBRARY)/$*) MODULE($(modules)) ENTMOD(*PGM)"
	touch $@

%.rpgle: src/%.rpgle
	system $(SYSTEM_PARMS) "CHGATR OBJ('$<') ATR(*CCSID) VALUE(1252)"
	system $(SYSTEM_PARMS) "CRTRPGMOD MODULE($(LIBRARY)/$*) SRCSTMF('$<') DBGVIEW(*SOURCE)"
	touch $@

%.dspf: src/%.dspf
	-system -q "CRTSRCPF FILE($(LIBRARY)/QSOURCE) RCDLEN(112)"
	system $(SYSTEM_PARMS) "CPYFRMSTMF FROMSTMF('$<') TOMBR('/QSYS.lib/$(LIBRARY).lib/QSOURCE.file/$(notdir $*).mbr') MBROPT(*REPLACE)"
	system $(SYSTEM_PARMS) "CRTDSPF FILE($(LIBRARY)/$*) SRCFILE($(LIBRARY)/QSOURCE) SRCMBR(*FILE)"
	touch $@

%.cmd: src/%.cmd
	-system -q "CRTSRCPF FILE($(LIBRARY)/QSOURCE) RCDLEN(112)"
	system $(SYSTEM_PARMS) "CPYFRMSTMF FROMSTMF('$<') TOMBR('/QSYS.lib/$(LIBRARY).lib/QSOURCE.file/$*.mbr') MBROPT(*REPLACE)"
	system $(SYSTEM_PARMS) "CRTCMD CMD($(LIBRARY)/$*) PGM($(LIBRARY)/$*) SRCFILE($(LIBRARY)/QSOURCE)"
	touch $@
