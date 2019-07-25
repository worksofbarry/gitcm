
      /COPY 'headers/gitcm.rpgle'

      //---------------------------------------------------------------*
  
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

      //---------------------------------------------------------------*

          Dcl-Pi COMMITINF;
            pCommit LikeDS(tLogEntry);
          End-Pi;
          
     Fcommit    CF   E             WorkStn Sfile(SFLDta:Rrn)
     F                                     IndDS(WkStnInd)
     F                                     InfDS(fileinfo)


          Dcl-S Rrn          Zoned(4:0) Inz;

          Dcl-DS WkStnInd;
            SflDspCtl      Ind        Pos(85);
            SflDsp         Ind        Pos(95);
          End-DS;

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
          
        Dcl-Ds gChangedFiles LikeDS(tChangedFiles) Dim(MAX_FILES);
        Dcl-S Exit    Ind Inz(*Off);
        Dcl-S Refresh Ind Inz(*Off);

        //------------------------------------------------------------reb04
        Exit = *Off;
        Refresh = *On;
        
        Dow (Not Exit);
          If (Refresh);
            LoadSubfile();
            Refresh = *off;
          Endif;

          Write HEADER_FMT;
          Write FOOTER_FMT;
          Exfmt SFLCTL;

          Select;
            When (Funkey = F05);
              Refresh = *On;
                    
            When (Funkey = F12);
              Exit = *On;

            When (Funkey = ENTER);
              Exsr HandleInputs;
          Endsl;
        Enddo;

        Return;

        Begsr HandleInputs;
          Dou (%EOF(commit));
            ReadC SFLDTA;
            If (%EOF(commit));
              Iter;
            Endif;

            Select;
              When @1SEL = '5';
                DIFF(pCommit.Hash:gChangedFiles(rrn).Path);
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
          Dcl-S lFiles Int(5);
          Dcl-S name   Varchar(80);

          ClearSubfile();

          @XCOMMIT = pCommit.Hash;
          @XMSG    = pCommit.Text;
          @XDATE   = pCommit.Date;
          GitListCommitFiles(pCommit.Hash:gChangedFiles);

          lFiles = %Lookup(*blank:gChangedFiles(*).Path);
          If (lFiles = 0); //We do this incase the DS is filled
            lFiles = %Elem(gChangedFiles); 
          Else;
            lFiles -= 1;
          Endif;

          for Index = 1 to lFiles;

            @xfile = gChangedFiles(index).Path;

            rrn += 1;
            Write SFLDTA;

          Endfor;

          If (rrn > 0);
            SflDsp = *On;
            SFLRRN = 1;
          Endif;
        End-Proc;