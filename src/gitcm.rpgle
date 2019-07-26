
      /COPY 'headers/gitcm.rpgle'

      //---------------------------------------------------------------*
  
        Dcl-C F12        X'3C';
        Dcl-C ENTER      X'F1';

        Dcl-S HEAD Char(7) Inz('HEAD');

      //---------------------------------------------------------------*

        Dcl-Pi GITCM;
        End-Pi;
          
     Fgitcmdsp  CF   E             WorkStn InfDS(fileinfo)

     DFILEINFO         DS
     D  FILENM           *FILE
     D  CPFID                 46     52
     D  MBRNAM               129    138
     D  FMTNAM               261    270
     D  CURSED               370    371B 0
     D  FUNKEY               369    369
     D  SFLRRN_TOP           378    379B 0
     D  SF_RRN               376    377I 0
     D  SF_RCDS              380    381I 0

        Dcl-S Exit Ind;

        Exit = *Off;

        Dow (Not Exit);
          Exfmt CONTENT;

          Select;
            When (Funkey = F12);
              Exit = *On;
            When (Funkey = ENTER);
              Exsr HandleInputs;
          Endsl;
        Enddo;

        Return;

        Begsr HandleInputs;
          Select;
            When (@xopt = '1');
              Monitor;
                Qcmdexc('?wrkifspdm':10);
              On-Error *ALL;
              Endmon;
            When (@xopt = '2');
              Qcmdexc('git':3);
          Endsl;
        Endsr;