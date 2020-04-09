
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

          Dcl-Pi DIFF;
            pCommit Char(7);
            pFile   Char(64);
          End-Pi;
          
     Fdiffscrn  CF   E             WorkStn Sfile(SFLDta:Rrn)
     F                                     IndDS(WkStnInd)
     F                                     InfDS(fileinfo)

          Dcl-S Exit Ind Inz(*Off);

          Dcl-S Rrn          Zoned(4:0) Inz;

          Dcl-DS WkStnInd;
            ProcessSCF     Ind        Pos(21);
            ReprintScf     Ind        Pos(22);
            Error          Ind        Pos(25);
            PageDown       Ind        Pos(30);
            PageUp         Ind        Pos(31);
            SflEnd         Ind        Pos(40);
            SflBegin       Ind        Pos(41);
            NoRecord       Ind        Pos(60);
            SflDspCtl      Ind        Pos(85);
            SflClr         Ind        Pos(75);
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
          Dcl-S Index Int(5);
          
          Dcl-S Lines Char(GIT_LINE_LEN) Dim(MAX_LINES);

        //Hello world!!
        //------------------------------------------------------------reb04
          Exit = *Off;
          LoadSubfile();

          Dow (Not Exit);
            Write HEADER_FMT;
            Write FOOTER_FMT;
            Exfmt SFLCTL;

            Select;
              When (Funkey = F12);
                Exit = *On;
              When (Funkey = F06);
                Exit = *On;
              When (Funkey = ENTER);
                Exit = *On;
            Endsl;
          Enddo;

          Return;

        //------------------------------------------------------------

          Dcl-Proc ClearSubfile;
            SflDspCtl = *Off;
            SflDsp = *Off;

            Write SFLCTL;

            SflDspCtl = *On;

            rrn = 0;
          End-Proc;

          Dcl-Proc LoadSubfile;
            Dcl-S lCount  Int(5);
            Dcl-S Action  Char(1);
            Dcl-S LongAct Char(3);

            ClearSubfile();

            @XCOMMIT = pCommit;
            @XFILE   = pFile;
            GitDiffGetter(pCommit:pFile:Lines);

            lCount = %Lookup('*EOF':Lines);

            for Index = 1 to lCount;
              
              Action = %Subst(Lines(Index):1:1);
              LongAct = %Subst(Lines(Index):1:3);

              If (LongAct = '+++' OR LongAct = '---');
                Iter;
              Endif;

              @xattr = x'3F';

              Select;
                When (Action = '@');
                  @xattr = x'3A';

                When (Action = '+');
                  @xattr = x'20';

                When (Action = '-');
                  @xattr = x'28';

                When (Action = *Blank);
                  @xattr = x'22';
              Endsl;

              If (@xattr <> x'3F');
                @xline = %Subst(Lines(Index):2);
                rrn += 1;
                Write SFLDTA;
              Endif;

            endfor;

            If (rrn > 0);
              SflDsp = *On;
              SFLRRN = 1;
            Endif;
          End-Proc;