**FREE
Ctl-Opt NoMain;

//************************

/COPY 'headers/ifs.rpgle'
/COPY 'headers/gitcm.rpgle'

//************************

Dcl-S  gRecords Int(5) Inz(0);
Dcl-Ds gGitLog  LikeDS(File_Temp);
Dcl-S  gKey     Char(6);

Dcl-S gIsText Ind;
Dcl-S gText   Varchar(128);

//************************

Dcl-S gUser  Char(10) Inz(*User);
Dcl-S gFocus Varchar(128);

Dcl-Pr get_errno Pointer ExtProc('__errno');
End-Pr;

Dcl-S ptrToErrno Pointer;
Dcl-s errno Int(10) based(ptrToErrno);

Dcl-Pr sleep Uns(10) ExtProc('sleep');
  *N Uns(10) Value;
End-Pr;

Dcl-Proc GitLogParse Export;
  Dcl-Pi GitLogParse;
    pFile  Char(128) Const;
    pValid Ind;
    pLogEntry LikeDS(tLogEntry) Dim(MAX_COMMITS);
  End-Pi;

  gFocus = %Trim(pFile);
  If (gFocus = '*ALL');
    gFocus = '';
  Elseif (gFocus <> '');
    gFocus = ' -- ' + gFocus;
  Endif;

  gGitLog.PathFile = '/tmp/' + %TrimR(gUser) + 'git.log';

  //Program will assume CURDIR is git repo

  //First we need to take the content of GIT LOG into a stream file
  PASE('/QOpenSys/pkgs/bin/git --no-pager log ' + gFocus + ' > '
      + %TrimR(gGitLog.PathFile) + ' 2>&1 & iconv -f UTF-8 -t ISO8859-1 '
      + %TrimR(gGitLog.PathFile) + ' > ' + %TrimR(gGitLog.PathFile));

  //Next we will want to read that stream file
  gGitLog.PathFile = %TrimR(gGitLog.PathFile) + x'00';
  gGitLog.OpenMode = 'r' + x'00';
  gGitLog.FilePtr  = OpenFile(%addr(gGitLog.PathFile)
                             :%addr(gGitLog.OpenMode));

  sleep(1);

  If (gGitLog.FilePtr = *Null);
    //Failed to open file
    ptrToErrno = get_errno(); 
    showMessage('File closed: ' + %Char(errno));
    Return;
  ENDIF;

  gIsText = *Off;
  gRecords = 0;

  Dow (ReadFile(%addr(gGitLog.RtvData)
               :%Len(gGitLog.RtvData)
               :gGitLog.FilePtr) <> *null);

    If (%Subst(gGitLog.RtvData:1:1) = x'25');
      gIsText = *On;
      Iter;
    ENDIF;

    gGitLog.RtvData = %xlate(x'00':' ':gGitLog.RtvData);//End of record null
    gGitLog.RtvData = %xlate(x'25':' ':gGitLog.RtvData);//Line feed (LF)
    gGitLog.RtvData = %xlate(x'0D':' ':gGitLog.RtvData);//Carriage return (CR)
    gGitLog.RtvData = %xlate(x'05':' ':gGitLog.RtvData);//Tab

    gKey = %Subst(gGitLog.RtvData:1:6);

    Select;
      When (gKey = 'commit');
        if (gIsText = *On);
          //Last commit finished, write to file?
          pLogEntry(gRecords).Text = gText;
          Clear gText;
          gIsText = *Off;
        ENDIF;
        gRecords += 1;

        If (gRecords > MAX_COMMITS);
          Leave;
        Endif;

        pLogEntry(gRecords).Hash = %Subst(gGitLog.RtvData:8:7);

      When (gKey = 'Author');
        pLogEntry(gRecords).Author = %Subst(gGitLog.RtvData:9);

      When (gKey = 'Date:');
        pLogEntry(gRecords).Date = %Subst(gGitLog.RtvData:9);

      When (gGitLog.RtvData = *Blank);
        gIsText = *On;

      Other;
        If (gIsText);
          gText += %Trim(gGitLog.RtvData) + ' ';
        ENDIF;

    ENDSL;

    gGitLog.RtvData = '';
  Enddo;

  CloseFile(gGitLog.FilePtr);

  If (gRecords = 0);
    pValid = *Off;
    showMessage('The file you provided may be invalid.');
  Else;
    pValid = *On;
  ENDIF;

  *InLR = *On;
  Return;
End-Proc;

//**************

Dcl-Proc showMessage;
  Dcl-Pi showMessage;
    Text Varchar(8192) Const;
  END-PI;

  Dcl-DS ErrCode;
    BytesIn  Int(10) Inz(0);
    BytesOut Int(10) Inz(0);
  END-DS;

  Dcl-PR QUILNGTX ExtPgm('QUILNGTX');
    MsgText     Char(8192)    Const;
    MsgLength   Int(10)       Const;
    MessageId   Char(7)       Const;
    MessageFile Char(21)      Const;
    dsErrCode   Like(ErrCode);
  END-PR;

  QUILNGTX(Text:%Len(Text):
     '':'':
     ErrCode);

  Return;
END-PROC;