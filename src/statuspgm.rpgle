
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

        Dcl-S HEAD Char(7) Inz('HEAD');

      //---------------------------------------------------------------*

          Dcl-Pi STATUSPGM;
          End-Pi;
          
     Fstatus    CF   E             WorkStn Sfile(SFLDta:Rrn)
     F                                     IndDS(WkStnInd)
     F                                     InfDS(fileinfo)

          Dcl-S Exit Ind Inz(*Off);

          Dcl-S Rrn          Zoned(4:0) Inz;
          Dcl-S LastRrn                 Like(Rrn);
          Dcl-S RrnCount                Like(Rrn);
          Dcl-S EmptySfl     Ind;
          Dcl-S lFiles     Int(5);

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
     D index           S              2  0 Inz
          
          Dcl-Ds gChangedFiles LikeDS(tChangedFiles) Dim(MAX_FILES);
          Dcl-S commitWindow Ind;

        //------------------------------------------------------------reb04

          Exsr InzSr;

          Dow Not Exit; // Continue process until user presses F6
              SflBegin = *On;
              Exsr SFLClear;            // Clear subfile for new search
              Rrn = 1;
              SflSize = 0;
              RrnCount = 0;
              ExSr Fill;
          EndDo;

          *InLr = *On;

          //############################################################
          //##              Subroutines                               ##
          //############################################################
          BegSr InzSr;

            SflRrn = 1;
            SflSize = 0;
            SflEnd = *On;
            SflBegin = *on;
            SflDspCtl = *On;

            Write HEADER_FMT;
            Write FOOTER_FMT;

            GitStatusParse(gChangedFiles);

          EndSr;

          //----------- Begin Fill ----------------------------
          BegSr Fill;

            Select;

              When PageDown;
                SflSize = SflSize + 17;

              When PageUp;
                SflSize = SflSize + 17;

              When SflSize = 0;
                SflSize = 17;
                SflRrn = 1;

                lFiles = %Lookup(*blank:gChangedFiles(*).Path);
                If (lFiles = 0); //We do this incase the DS is filled
                  lFiles = %Elem(gChangedFiles); 
                Else;
                  lFiles -= 1;
                Endif;

                for Index = 1 to lFiles;

                  Select;
                    When (gChangedFiles(index).Status = RED);
                      @xattr = x'28';
                    When (gChangedFiles(index).Status = GREEN);
                      @xattr = x'20';
                    When (gChangedFiles(index).Status = ORANGE);
                      @xattr = x'32';

                  Endsl;

                  @xfile = gChangedFiles(index).Path;

                  Write SFLDTA;
                  Rrn = Rrn + 1;
                  RrnCount = RrnCount + 1;

                endfor;

            EndSl;

            EmptySfl = (Rrn <= 1);

            If Not EmptySfl;

              SflDspCtl = *On;
              SflDsp = *on;
              WRITE HEADER_FMT;
              Write FOOTER_FMT;

            Else;

              SflDspCtl = *On;
              SflDsp = *Off;
              SflBegin = *On;
              WRITE HEADER_FMT;
              WRITE FOOTER_FMT;

            EndIf;

            ExFmt SFLCTL;

            Select;
              When (Funkey = F05);
                GitStatusParse(gChangedFiles);

              When (Funkey = F06);
                //Make commit
                commitWindow = *On;

                Dow (commitWindow);
                  EXFMT COMMIT;

                  Select;
                    When (Funkey = F10);
                      CMTMSG = %ScanRpl('"':'\"':CMTMSG);
                      PASE('/QOpenSys/pkgs/bin/git commit -m "'
                            + %Trim(CMTMSG) + '"');
                      CMTMSG = *Blank;
                      commitWindow = *Off;
                      GitStatusParse(gChangedFiles);

                    When (Funkey = F12);
                      commitWindow = *Off;
                  Endsl;
                Enddo;

              When (Funkey = F09);
                PASE('/QOpenSys/pkgs/bin/git push');

              When (Funkey = F10);
                PASE('/QOpenSys/pkgs/bin/git fetch ' +
                     '&& /QOpenSys/pkgs/bin/git pull');

              When (Funkey = F12);
                exsr #exitpgm;
                leaveSr;
            Endsl;

            If Rrn > 1 and Not PageDown;    
              // check for value in @1SEL
              //Process subfile changes

              Dow Not %Eof;

                ReadC SFLDTA;
                If %EOF;
                    iter;
                endif;

                Select;
                    When @1SEL = '5';
                      DIFF(HEAD:gChangedFiles(rrn).Path);

                    When @1SEL = 'A';
                      PASE('/QOpenSys/pkgs/bin/git add ' + 
                           %TrimR(gChangedFiles(rrn).Path));
                      GitStatusParse(gChangedFiles);

                    When @1SEL = 'R';
                      PASE('/QOpenSys/pkgs/bin/git reset ' +
                           %TrimR(gChangedFiles(rrn).Path));
                      GitStatusParse(gChangedFiles);

                    Other;

                      Write FOOTER_FMT;
                      @1sel = *blank;
                      leaveSr;

                EndSl;

                if  @1sel <> *blanks;
                    @1sel = *blanks;
                    update sfldta;
                endif;

                FunKey = *blanks;
              EndDo;
            EndIf;

          EndSr;
          //------------ End Fill -----------------------------

          begsr #exitpgm;
            Exit = *On;
            *inlr = *on;
            return;
          endSR;

          BegSr SFLClear;
            SflClr = *On;
            SflDsp = *Off;
            SflDspCtl = *Off;
            Write SFLCTL;
            SflClr = *Off;
            SflBegin = *Off;
          EndSr;