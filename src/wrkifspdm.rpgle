
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

          Dcl-Pi WRKIFSPDM;
            pFolder Char(10);
          End-Pi;
          
     Fifspdm    CF   E             WorkStn Sfile(SFLDta:Rrn)
     F                                     IndDS(WkStnInd)
     F                                     InfDS(fileinfo)

          Dcl-S Exit Ind Inz(*Off);

          Dcl-S Rrn          Zoned(4:0) Inz;
          Dcl-S LastRrn                 Like(Rrn);
          Dcl-S RrnCount                Like(Rrn);
          Dcl-S EmptySfl     Ind;

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
          
          Dcl-S  gFiles      Int(5);
          Dcl-S  Name        Char(10);
          Dcl-S  Extension   Char(10);
          Dcl-Ds StreamFiles Qualified Dim(500);
            Name Char(21);
          End-Ds;

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

            @XDIR = pFolder;
            getIFSFolders(pFolder);

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

                for Index = 1 to gFiles;

                  @xfile = StreamFiles(index).Name;

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
                  When @1SEL = '2';
                    index = %Scan('.':StreamFiles(rrn).Name);
                    if (index > 0);
                      Name = %Subst(StreamFiles(rrn).Name:1:index-1);
                      Extension = %Subst(StreamFiles(rrn).Name:index+1);
                    else;
                      Name = StreamFiles(rrn).Name;
                      Extension = '*SAME';
                    endif;

                    system('CRTSRCPF FILE(QTEMP/QSOURCE) RCDLEN(112)');
                    system('CPYFRMSTMF FROMSTMF(''' 
                          + %Trim(pFolder) 
                          + '/' + %Trim(StreamFiles(rrn).Name)
                          + ''') TOMBR(''/QSYS.lib/QTEMP.lib/QSOURCE.file/' 
                          + %Trim(Name) 
                          + '.mbr'') MBROPT(*REPLACE)');
                    QCmdExc('STRSEU SRCFILE(QTEMP/QSOURCE) SRCMBR(' 
                          + %Trim(Name) + ') TYPE(' 
                          + %Trim(Extension) + ')':200);

                  When @1SEL = '5';
                    QCmdExc('DSPF STMF(''' 
                          + %Trim(pFolder) 
                          + '/' + %Trim(StreamFiles(rrn).Name)
                          + ''')':132);

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

          Dcl-Proc getIFSFolders;
            Dcl-Pi *N;
              pFolderName Char(10) Const;
            End-Pi;

            /COPY 'headers/ifs.rpgle'

            Dcl-S lFolder Varchar(10);
            Dcl-S Name    Varchar(21);

            Dcl-S p_dirent     Pointer;
            Dcl-DS dirent  based( p_dirent );
              d_reserv1      Char(16);
              d_reserv2      Uns(10);
              d_fileno       Uns(10);
              d_reclen       Uns(10);
              d_reserv3      Int(10);
              d_reserv4      Char(8);
              d_nlsinfo      Char(12);
              nls_ccsid      Int(10)    overlay( d_nlsinfo:1 );
              nls_cntry      Char(2)    overlay( d_nlsinfo:5 );
              nls_lang       Char(3)    overlay( d_nlsinfo:7 );
              nls_reserv     Char(3)    overlay( d_nlsinfo:10 );
              d_namelen      Uns(10);
              d_name         Char(640);
            End-DS;

            Dcl-S dh           Pointer;
            Dcl-S rtnVal       Uns(10);

            Dcl-DS stat_struct;
              st_other1      Char(48);
              st_objtype     Char(10);
              st_other2      Char(68);
            End-DS;

            lFolder = %Trim(pFolderName);

            clear StreamFiles;
            gFiles = 0;

            //  Open up the directory.
            dh = opendir(lFolder);
            if  dh = *NULL;
              return;
            endif;

            p_dirent = readdir(dh);

            dow  p_dirent <> *NULL ;

              Name = %trim(%str(%addr(d_name)));
              rtnVal = stat(%trim(lFolder + '/' + d_name):
                            %addr(stat_struct));

              if rtnVal = 0 ;
                // if st_objType = '*DIR      ' ;

                // // it's a directory, but there are
                // // two cases we will ignore...
                //     if %str( %addr(d_name) ) <> '.'
                //       AND
                //       %str( %addr(d_name) ) <> '..' ;

                //     // process the directory entry...
                //     // (could process recursively here...)
                //       Msg = 'Dir: ' + Name ;
                //       dsply Msg ;

                //     endif ;

                if st_objType = '*STMF';
                  gFiles += 1;

                  StreamFiles(gFiles).Name = Name;
                endif;
              endif;

              p_dirent = readdir(dh);
            enddo;

            closedir(dh);
          End-Proc;