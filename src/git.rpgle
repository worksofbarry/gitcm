
      /COPY 'headers/gitcm.rpgle'
     
     Fgitdsp    CF   E             WorkStn Sfile(SFLDta:Rrn)
     F                                     IndDS(WkStnInd)
     F                                     InfDS(fileinfo)

      //---------------------------------------------------------------*
      
        Dcl-S Exit Ind Inz(*Off);
        Dcl-DS WkStnInd;
            SflDspCtl      Ind        Pos(85);
            SflDsp         Ind        Pos(95);
        End-DS;
  
        Dcl-C F01        X'31';
        Dcl-C F02        X'32';
        Dcl-C F03        X'33';
        Dcl-C F04        X'34';
        Dcl-C F05        X'35';
        Dcl-C F06        X'36';
        Dcl-C F07        X'37';
        Dcl-C F08        X'38';
        Dcl-C F09        X'39';
        Dcl-C F10        X'3A';
        Dcl-C F11        X'3B';
        Dcl-C F12        X'3C';
        Dcl-C F13        X'B1';
        Dcl-C F14        X'B2';
        Dcl-C F15        X'B3';
        Dcl-C F16        X'B4';
        Dcl-C F17        X'B5';
        Dcl-C F18        X'B6';
        Dcl-C F19        X'B7';
        Dcl-C F20        X'B8';
        Dcl-C F21        X'B9';
        Dcl-C F22        X'BA';
        Dcl-C F24        X'BC';
        Dcl-C ENTER      X'F1';
        Dcl-C HELP       X'F3';
        Dcl-C PRINT      X'F6';

        Dcl-S rrn          Zoned(4:0) Inz;
        Dcl-S ValidRepo    Ind Inz(*Off); 
 
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

      //---------------------------------------------------------------*
      *
     D index           S              2  0 Inz
      //---------------------------------------------------------------*

        Dcl-Ds gLogEntry LikeDS(tLogEntry) Dim(MAX_COMMITS);
        Dcl-S  gUser     Char(10) Inz(*USER);
        Dcl-S  Refresh   Ind Inz(*On);

      //------------------------------------------------------------reb04

        PASE('echo hi > /tmp/' + %TrimR(gUser) + 'git.log');
        system('CHGATR OBJ(''/tmp/' + %TrimR(gUser)
              + 'git.log'') ATR(*CCSID) VALUE(819)');

        Exit = *Off;
        Refresh = *On;
        Dow (Not Exit);
          If (Refresh);
            LoadSubfile();
            Refresh = *Off;
          Endif;

          Write HEADER_FMT;
          Write FOOTER_FMT;
          Exfmt SFLCTL;

          Select;
            When (Funkey = F03);
              Exit = *On;
            WHEN (FunKey = F05);
              Refresh = *On;
            When (Funkey = F06);
              STATUSPGM();
            When (Funkey = ENTER);
              Exsr HandleInputs;
          Endsl;
        Enddo;

        Return;

        Begsr HandleInputs;
          Dou (%EOF(gitdsp));
            ReadC SFLDTA;
            If (%EOF(gitdsp));
              Iter;
            Endif;

            Select;
                When @1SEL = '5';
                  CommitInfo(gLogEntry(rrn));
            Endsl;

            If (@1SEL <> *Blank);
              @1SEL = *Blank;
              Update SFLDTA;
              SFLRRN = rrn;
            Endif;
          Enddo;
        Endsr;

      //------------------------------------------------------------

        Dcl-Proc ClearSubfile;
          SflDspCtl = *Off;
          SflDsp = *Off;

          Write SFLCTL;

          SflDspCtl = *On;

          rrn = 0;
        End-Proc;

        Dcl-Proc LoadSubfile;
          Dcl-S lCommits     Int(5);

          ClearSubfile();

          GitLogParse('*ALL':ValidRepo:gLogEntry);

          lCommits = %Lookup(*blank:glogEntry(*).hash);
          If (lCommits = 0); //We do this incase the DS is filled
            lCommits = %Elem(gLogEntry); 
          Else;
            lCommits -= 1;
          Endif;

          for Index = 1 to lCommits;

            @xcommit = glogEntry(index).Hash;
            @xuser =  glogEntry(index).Author;
            @xdate =  glogEntry(index).Date;
            @xtext =  glogEntry(index).Text;

            rrn += 1;
            Write SFLDTA;

          endfor;

          If (rrn > 0);
            SflDsp = *On;
            SFLRRN = 1;
          Endif;
        End-Proc;