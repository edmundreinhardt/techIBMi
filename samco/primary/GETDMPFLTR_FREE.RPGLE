**FREE
//------------------------------------------------------------
// MOD# PROGRAMMER      DATE     DESCRIPTION
// ---- --------------- -------- ----------------------------
// $00  B. MORRIS       96/11/14 create
// $01  B. MORRIS       97/09/25 filter out actual pointer values
// $06  B. MORRIS       98/02/12 keep I/O buffers if asked
// $07  B. MORRIS       98/11/19 keep "All from this point"
// $08  B. MORRIS       14/04/22 add IGCDTA parm, *YES means that
//                               the data is shifted 1 right
// $09  CONVERTED       25/09/15 Converted to free-form RPG
//------------------------------------------------------------

// Control options
ctl-opt dftactgrp(*no) actgrp(*caller) main(processGetDmpFltr);

// File declarations - program-described files
dcl-f GetLstIn disk(133) usage(*input) keyed usropn;
dcl-f GetLstOut disk(132) usage(*output) usropn;

//-----------------------------------------------------------------
// General structure for detecting start and end of a section
//-----------------------------------------------------------------
dcl-c InfdsSecY '1';
dcl-c InfdsSecN '0';
dcl-ds Info qualified based(pInfo);
  InThis char(1);
  WantThis char(1);
  InfdsThis char(1);
  Section char(10);
  // Start and end position in line to look for start-value
  S1 packed(9:0);
  S2 packed(9:0);
  StartVal char(50);
  // Start and end position in line to look for end-value
  E1 packed(9:0);
  E2 packed(9:0);
  EndVal char(50);
end-ds;

//-----------------------------------------------------------------
// How to detect the Dump-PSDS section start and end
//-----------------------------------------------------------------
dcl-c @DMPPSDS1 'Program Status Area: ';
dcl-c @DMPPSDS2 'Member . . . . . ';
dcl-ds DmpPsds qualified;
  InDmpPsds char(1) inz('0');
  WantDmpPsd char(1) inz('0');
  InfdsFlag char(1) inz(InfdsSecN);
  SectionName char(10) inz('*DMPPSDS');
  S1 packed(9:0) inz(2);
  S2 packed(9:0) inz(22);
  StartVal char(50) inz(@DMPPSDS1);
  E1 packed(9:0) inz(2);
  E2 packed(9:0) inz(18);
  EndVal char(50) inz(@DMPPSDS2);
end-ds;

//-----------------------------------------------------------------
// How to detect the Dump-INFDS section start and end
//-----------------------------------------------------------------
dcl-c @DMPINF1 'INFDS FILE FEEDBACK';
dcl-c @DMPINF2 'Module Name. . . . ';
dcl-ds DmpInfds qualified;
  InDmpInfds char(1) inz('0');
  WantDmpInf char(1) inz('0');
  InfdsFlag char(1) inz(InfdsSecY);
  SectionName char(10) inz('*DMPINFDS');
  S1 packed(9:0) inz(2);
  S2 packed(9:0) inz(20);
  StartVal char(50) inz(@DMPINF1);
  E1 packed(9:0) inz(2);
  E2 packed(9:0) inz(20);
  EndVal char(50) inz(@DMPINF2);
end-ds;

//-----------------------------------------------------------------
// How to detect the Dump-VARS section start and end
//-----------------------------------------------------------------
dcl-c @DMPVARS1 'Optimization Level . . .';
dcl-c @DMPVARS2 '*   E N D   O F   R P G   D U M P';
dcl-ds DmpVars qualified;
  InDmpVars char(1) inz('0');
  WantDmpVar char(1) inz('0');
  InfdsFlag char(1) inz(InfdsSecN);
  SectionName char(10) inz('*DMPVARS');
  S1 packed(9:0) inz(2);
  S2 packed(9:0) inz(25);
  StartVal char(50) inz(@DMPVARS1);
  E1 packed(9:0) inz(22);
  E2 packed(9:0) inz(54);
  EndVal char(50) inz(@DMPVARS2);
end-ds;

dcl-c MaxSection 3;

// Size of LenDs = sizeof(pointer) * MaxSection
// so a field defined LIKE(LenDs) has that size
dcl-ds LenDs qualified;
  Dummy pointer dim(MaxSection);
end-ds;

// Order doesn't really matter - add new ones at the end
dcl-ds AllInfo qualified;
  InfoPtrsOv like(LenDs);
  pInfos pointer dim(MaxSection) overlay(InfoPtrsOv:1);
  // Following are the array elements of pInfos, initialized
  pDmpPsds pointer inz(%addr(DmpPsds)) overlay(InfoPtrsOv:1);
  pDmpInfds pointer inz(%addr(DmpInfds)) overlay(InfoPtrsOv:17);
  pDmpVars pointer inz(%addr(DmpVars)) overlay(InfoPtrsOv:33);
  // Don't have to add any more if adding a new section
end-ds;

// Data structures for file I/O - matching the original input specs
dcl-ds InLineIgcDta char(133);
dcl-ds InLine char(132);
  PageLoc char(4) pos(124);
  OdpSection char(24) pos(2);
  Caption char(40) pos(2);
  InLineOdp char(2) pos(45);
  DmpValStrt char(4) pos(45);
  DmpPtrVal char(16) pos(49);
  OdpBlnk1 char(4) pos(1);
  OdpBlnk2 char(3) pos(9);
  OdpBlnk3 char(2) pos(20);
  OdpBlnk4 char(2) pos(30);
  OdpCols char(4) pos(5);
end-ds;

dcl-c @MSGID 'Msg id ';
dcl-s SelectThis char(1) inz('0');
dcl-s InInfds char(1) inz('0');
dcl-s M1 packed(5:0);
dcl-s MLen packed(5:0);

dcl-ds WantParm qualified;
  WantedNum int(10);
  Wanted char(10) dim(MaxSection);
end-ds;

dcl-s WantAll char(1) inz('0');

dcl-c ODPInb 'Input Buffer:           ';
dcl-c ODPOutb 'Output Buffer:          ';
dcl-c ODPTypeMsg 'ODP type . . . . . . . .';
dcl-s ODPType char(2);

dcl-s JobCaption char(40) dim(11);
dcl-s PrtCaption char(40) dim(3);

dcl-c HexDigits '0123456789ABCDE';

dcl-s HaveTitle char(1) inz('0');
dcl-s Title like(InLine);

dcl-ds DumpInfo qualified;
  NumDI int(10);
  DiArr int(5) dim(2);
end-ds;

// See GETLST command source (parm DUMPINFO) for these literals
dcl-c @DiInBuf 1;
dcl-c @DiOutBuf 2;
dcl-s KeepInBuf char(1) inz('0');
dcl-s KeepOutBuf char(1) inz('0');

dcl-s OdpSect int(5) inz(OdpOther);
dcl-c OdpOther 0;
dcl-c OdpInBuf 1;
dcl-c OdpOutBuf 2;

// Global pointer variable
dcl-s pInfo pointer;

// Main procedure
dcl-proc processGetDmpFltr;
  dcl-pi *n;
    pWantParm likeds(WantParm);
    pDumpInfo likeds(DumpInfo);
    pStartFrom char(1);
    pIgcDta char(4);
  end-pi;
  
  dcl-s eof ind;
  
  // Initialize the program
  initializeProgram(pWantParm: pDumpInfo);
  
  // Open files
  open GetLstIn;
  open GetLstOut;
  
  // Process each record
  eof = *off;
  read GetLstIn InLineIgcDta;
  dow not %eof(GetLstIn);
    // If we had an IGCDTA(*YES) spool file, the data is
    // shifted right by one
    if pIgcDta = '*YES';
      InLine = %subst(InlineIgcDta: 2);
    else;
      InLine = %subst(InLineIgcDta: 1: 132);
    endif;
    
    // Process the line
    processLine(pStartFrom);
    
    // Read the next record
    read GetLstIn InLineIgcDta;
  enddo;
  
  // Close files
  close GetLstIn;
  close GetLstOut;
  
  return;
end-proc;

// Filter - remove date or job-specific info
//        - also remove printer-file specific info from INFDS
//        - change the value for dumped pointers to a constant value
dcl-proc filterLine;
  dcl-pi *n;
  end-pi;
  
  dcl-s found ind;
  
  found = %lookup(Caption: JobCaption) > 0;
  if found;
    %subst(InLine:45) = *blanks;
  endif;
  
  // Variables stuff
  if DmpVars.InDmpVars = '1';
    if (DmpValStrt = 'SPP:' or DmpValStrt = 'SYP:' or DmpValStrt = 'PRP:');
      if DmpPtrVal = '*NULL';
        DmpValStrt = 'SPP:';
      else;
        DmpPtrVal = '<offsets>';
      endif;
    endif;
  endif;
  
  // Infds stuff
  if InInfds = '1';
    // If this is ODP stuff, we don't want it.
    // Columns 1-4, 9-11, 20-21, 30-31 all blank, and col 5-8 hex digits
    // means this is the ODP hex dump.
    
    // Unless they asked us to leave that part in ...
    if not ((KeepInBuf = '1' and OdpSect = OdpInbuf) or
            (KeepOutBuf = '1' and OdpSect = OdpOutBuf));
      if OdpBlnk1 = *blanks and
         OdpBlnk2 = *blanks and
         OdpBlnk3 = *blanks and
         OdpBlnk4 = *blanks;
        
        // Check if OdpCols contains only hex digits
        found = %check(HexDigits: OdpCols) = 0;
        
        // All hex digits? De-select this line
        if not found;
          SelectThis = '0';
        endif;
      endif;
    endif;
    
    if OdpType = 'SP';
      found = %lookup(Caption: PrtCaption) > 0;
      if found;
        %subst(InLine:45) = *blanks;
      endif;
    endif;
  endif;
  
  return;
end-proc;

// Process a line from the input file
dcl-proc processLine;
  dcl-pi *n;
    pStartFrom char(1);
  end-pi;
  
  dcl-s ix int(5);
  
  // If we're handling an INFDS
  if InInfds = '1';
    // See if this is the line saying what type of file this INFDS is
    if OdpSection = ODPTypeMsg;
      OdpType = InLineOdp;
    endif;
    
    // See if this is the line saying what part of the ODP we're doing
    if OdpBlnk1 <> ' ';
      select;
        when OdpSection = ODPTypeMsg;
          OdpType = InLineOdp;
          OdpSect = OdpOther;
        when OdpSection = ODPInb;
          OdpSect = OdpInBuf;
        when OdpSection = ODPOutb;
          OdpSect = OdpOutBuf;
        other;
          OdpSect = OdpOther;
      endsl;
    endif;
  endif;
  
  // Assume we don't want this line
  SelectThis = '0';
  
  // Check if it's a "Page n" or title line.
  if PageLoc = 'Page' or InLine = Title;
    return;
  endif;
  
  // Putting this after the previous check will allow the first
  // title line to get printed (if we're getting the prolog)
  if HaveTitle = '0';
    Title = InLine;
    HaveTitle = '1';
  endif;
  
  // See if this is the beginning or end of a section
  for ix = 1 to MaxSection;
    // Set basing pointer of Info to one of the section infos
    pInfo = AllInfo.pInfos(ix);
    
    // If we're not in that section, see if this is the start of
    // it. (We want to print this line if it's the beginning of the
    // section)
    if Info.InThis = '0' and
       %subst(InLine: Info.S1: Info.S2-Info.S1+1) = Info.StartVal;
      Info.InThis = '1';
      
      // If they want to start copying everything from "here", set on
      // "WantAll" now.
      if pStartFrom = '1' and Info.WantThis = '1';
        WantAll = '1';
      endif;
      
      InInfds = Info.InfdsThis;
    endif;
    
    // If we're in that section then see if this is the end of
    // it. (We want to print this line if it's the end of the
    // section)
    if Info.InThis = '1' and Info.WantThis = '1';
      SelectThis = '1';
      
      if %subst(InLine: Info.E1: Info.E2-Info.E1+1) = Info.EndVal;
        Info.InThis = '0';
      endif;
    endif;
  endfor;
  
  // Output the line if they want it, first clearing out any
  // date or job related info
  if SelectThis = '1' or WantAll = '1';
    SelectThis = '1';
    filterLine();
    
    // Output if SelectThis is still '1' (may be unwanted ODP stuff)
    if SelectThis = '1';
      writeOutputLine();
    endif;
  endif;
  
  return;
end-proc;

// Initialize the program
dcl-proc initializeProgram;
  dcl-pi *n;
    pWantParm likeds(WantParm);
    pDumpInfo likeds(DumpInfo);
  end-pi;
  
  dcl-s ix int(5);
  dcl-s iy int(5);
  dcl-s dix int(5);
  
  // Initialize JobCaption array
  JobCaption(1) = 'Job Name . . . . . . . . . . . . . . . :';
  JobCaption(2) = 'User Name  . . . . . . . . . . . . . . :';
  JobCaption(3) = 'Job Number . . . . . . . . . . . . . . :';
  JobCaption(4) = 'Date Entered System  . . . . . . . . . :';
  JobCaption(5) = '   Century . . . . . . . . . . . . . . :';
  JobCaption(6) = 'Date Started . . . . . . . . . . . . . :';
  JobCaption(7) = 'Time Started . . . . . . . . . . . . . :';
  JobCaption(8) = 'Compile Date . . . . . . . . . . . . . :';
  JobCaption(9) = 'Compile Time . . . . . . . . . . . . . :';
  JobCaption(10) = 'Compiler Level . . . . . . . . . . . . :';
  JobCaption(11) = 'Open Identifier. . . . . . . . . . . . :';
  
  // Initialize PrtCaption array
  PrtCaption(1) = 'Member . . . . . . . . . . . . . . . . :';
  PrtCaption(2) = 'Spool File . . . . . . . . . . . . . . :';
  PrtCaption(3) = 'Spool File Number  . . . . . . . . . . :';
  
  // First see if they want the whole listing, just cleaned up
  if pWantParm.WantedNum = 1 and pWantParm.Wanted(1) = '*DMPALL';
    WantAll = '1';
  else;
    // Go through the sections seeing if the section is one of the ones
    // they want.
    for ix = 1 to MaxSection;
      // Set basing pointer of Info to one of the section infos
      pInfo = AllInfo.pInfos(ix);
      
      // Look through the Wanted array to see if this section is there
      for iy = 1 to pWantParm.WantedNum;
        if Info.Section = pWantParm.Wanted(iy);
          Info.WantThis = '1';
          leave;
        endif;
      endfor;
    endfor;
  endif;
  
  // See if there are any sections that we normally clear out, but
  // they want to keep.
  for dix = 1 to pDumpInfo.NumDI;
    select;
      when pDumpInfo.DiArr(dix) = @DiInBuf;
        KeepInBuf = '1';
      when pDumpInfo.DiArr(dix) = @DiOutBuf;
        KeepOutBuf = '1';
    endsl;
  endfor;
  
  return;
end-proc;

// Write a line to the output file
dcl-proc writeOutputLine;
  dcl-pi *n;
  end-pi;
  
  write GetLstOut InLine;
  
  return;
end-proc;