**FREE

Dcl-Pr PASE ExtProc('CM_PASECALL');
  pCommand Char(1024) Const;
END-PR;

//********************************

Dcl-C MAX_COMMITS 50;

Dcl-Ds tLogEntry Qualified Template;
  Hash   Char(7);
  Author Char(64);
  Date   Char(64);
  Text   Char(128);
End-Ds;

Dcl-Pr GitLogParse ExtProc('GITLOGPARSE');
  pFile  Char(128) Const;
  pValid Ind;
  pLogEntry LikeDS(tLogEntry) Dim(MAX_COMMITS);
End-Pr;

//********************************

Dcl-C MAX_FILES 50;

Dcl-Ds tChangedFiles Qualified Template;
  Status Int(3);
  Path   Char(64);
End-Ds;

Dcl-Pr GitListCommitFiles ExtProc('GITLISTCOMMITFILES');
  pCommit Char(128) Const;
  pFiles LikeDS(tChangedFiles) Dim(MAX_FILES);
End-Pr;

Dcl-Pr CommitInfo ExtPgm('COMMITINF');
  pCommit LikeDS(tLogEntry);
End-Pr;

//********************************

Dcl-C MAX_LINES    1000;
Dcl-C GIT_LINE_LEN 128;

Dcl-Pr GitDiffGetter ExtProc('GITDIFFGETTER');
  pCommit Char(128) Const;
  pFile   Char(128) Const;
  oLines  Char(GIT_LINE_LEN) Dim(MAX_LINES);
End-Pr;

Dcl-Pr DIFF ExtPgm;
  pCommit Char(7);
  pFile   Char(64);
End-Pr;

//********************************


Dcl-C RED 1;
Dcl-C GREEN 2;
Dcl-C ORANGE 3;

Dcl-Pr GitStatusParse ExtProc('GITSTATUSPARSE');
  pFiles LikeDS(tChangedFiles) Dim(MAX_FILES);
End-Pr;

Dcl-Pr STATUSPGM ExtPgm;
End-Pr;