**FREE
Ctl-Opt NoMain;

//************************

/COPY 'headers/ifs.rpgle'
/COPY 'headers/gitcm.rpgle'

//************************

Dcl-S  gRecords Int(5) Inz(0);
Dcl-Ds gGitLog  LikeDS(File_Temp);

//************************

Dcl-S gUser  Char(10) Inz(*User);

Dcl-Pr get_errno Pointer ExtProc('__errno');
End-Pr;

Dcl-S ptrToErrno Pointer;
Dcl-s errno Int(10) based(ptrToErrno);

Dcl-Pr sleep Uns(10) ExtProc('sleep');
  *N Uns(10) Value;
End-Pr;

Dcl-Proc GitStatusParse Export;
  Dcl-Pi GitStatusParse;
    pFiles LikeDS(tChangedFiles) Dim(MAX_FILES);
  End-Pi;

  Dcl-S Status Char(1);

  Clear pFiles;

  gGitLog.PathFile = '/tmp/' + %TrimR(gUser) + 'git.log';

  //Program will assume CURDIR is git repo

  //First we need to take the content of GIT LOG into a stream file
  PASE('/QOpenSys/pkgs/bin/git status --porcelain '
      + x'4F' + ' iconv -f UTF-8 -t ISO8859-1 > ' + %TrimR(gGitLog.PathFile));

  //Next we will want to read that stream file
  gGitLog.PathFile = %TrimR(gGitLog.PathFile) + x'00';
  gGitLog.OpenMode = 'r' + x'00';
  gGitLog.FilePtr  = OpenFile(%addr(gGitLog.PathFile)
                             :%addr(gGitLog.OpenMode));

  //sleep(1);

  If (gGitLog.FilePtr = *Null);
    //Failed to open file
    ptrToErrno = get_errno(); 
    Return;
  ENDIF;

  gRecords = 0;

  Dow (ReadFile(%addr(gGitLog.RtvData)
               :%Len(gGitLog.RtvData)
               :gGitLog.FilePtr) <> *null);

    If (%Subst(gGitLog.RtvData:1:1) = x'25');
      Iter;
    ENDIF;

    If (gRecords > MAX_FILES);
      Leave;
    Endif;

    gRecords += 1;

    gGitLog.RtvData = %xlate(x'00':' ':gGitLog.RtvData);//End of record null
    gGitLog.RtvData = %xlate(x'25':' ':gGitLog.RtvData);//Line feed (LF)
    gGitLog.RtvData = %xlate(x'0D':' ':gGitLog.RtvData);//Carriage return (CR)
    gGitLog.RtvData = %xlate(x'05':' ':gGitLog.RtvData);//Tab

    Status = %Subst(gGitLog.RtvData:1:1);

    Select;
      When (Status = '?');
        pFiles(gRecords).Status = ORANGE;
      When (Status = 'M');
        pFiles(gRecords).Status = GREEN;
      When (Status = 'A');
        pFiles(gRecords).Status = GREEN;
      Other;
        pFiles(gRecords).Status = RED;
    Endsl;

    pFiles(gRecords).Path = %TrimR(%Subst(gGitLog.RtvData:3));

    gGitLog.RtvData = '';
  Enddo;

  CloseFile(gGitLog.FilePtr);

  If (gRecords = 0);
    ptrToErrno = get_errno(); 
    showMessage('No commits found.');
  Else;
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