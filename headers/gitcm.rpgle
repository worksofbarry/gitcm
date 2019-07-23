**FREE

Dcl-Pr PASE ExtProc('CM_PASECALL');
  pCommand Char(1024) Const;
END-PR;

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