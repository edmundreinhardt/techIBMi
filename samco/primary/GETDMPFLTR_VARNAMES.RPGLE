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
dcl-c INFDS_FLAG_YES '1';
dcl-c INFDS_FLAG_NO '0';
dcl-ds SectionInfo qualified based(pSectionInfo);
  isInSection char(1);
  isWanted char(1);
  isInfoDataStructure char(1);
  sectionName char(10);
  // Start and end position in line to look for start-value
  startPos1 packed(9:0);
  startPos2 packed(9:0);
  startValue char(50);
  // Start and end position in line to look for end-value
  endPos1 packed(9:0);
  endPos2 packed(9:0);
  endValue char(50);
end-ds;

//-----------------------------------------------------------------
// How to detect the Dump-PSDS section start and end
//-----------------------------------------------------------------
dcl-c PSDS_START_MARKER 'Program Status Area: ';
dcl-c PSDS_END_MARKER 'Member . . . . . ';
dcl-ds ProgramStatusSection qualified;
  isInPsdsSection char(1) inz('0');
  isWantedPsdsSection char(1) inz('0');
  isInfoDataStructure char(1) inz(INFDS_FLAG_NO);
  sectionName char(10) inz('*DMPPSDS');
  startPos1 packed(9:0) inz(2);
  startPos2 packed(9:0) inz(22);
  startValue char(50) inz(PSDS_START_MARKER);
  endPos1 packed(9:0) inz(2);
  endPos2 packed(9:0) inz(18);
  endValue char(50) inz(PSDS_END_MARKER);
end-ds;

//-----------------------------------------------------------------
// How to detect the Dump-INFDS section start and end
//-----------------------------------------------------------------
dcl-c INFDS_START_MARKER 'INFDS FILE FEEDBACK';
dcl-c INFDS_END_MARKER 'Module Name. . . . ';
dcl-ds FileInfoSection qualified;
  isInInfoSection char(1) inz('0');
  isWantedInfoSection char(1) inz('0');
  isInfoDataStructure char(1) inz(INFDS_FLAG_YES);
  sectionName char(10) inz('*DMPINFDS');
  startPos1 packed(9:0) inz(2);
  startPos2 packed(9:0) inz(20);
  startValue char(50) inz(INFDS_START_MARKER);
  endPos1 packed(9:0) inz(2);
  endPos2 packed(9:0) inz(20);
  endValue char(50) inz(INFDS_END_MARKER);
end-ds;

//-----------------------------------------------------------------
// How to detect the Dump-VARS section start and end
//-----------------------------------------------------------------
dcl-c VARS_START_MARKER 'Optimization Level . . .';
dcl-c VARS_END_MARKER '*   E N D   O F   R P G   D U M P';
dcl-ds VariablesSection qualified;
  isInVarsSection char(1) inz('0');
  isWantedVarsSection char(1) inz('0');
  isInfoDataStructure char(1) inz(INFDS_FLAG_NO);
  sectionName char(10) inz('*DMPVARS');
  startPos1 packed(9:0) inz(2);
  startPos2 packed(9:0) inz(25);
  startValue char(50) inz(VARS_START_MARKER);
  endPos1 packed(9:0) inz(22);
  endPos2 packed(9:0) inz(54);
  endValue char(50) inz(VARS_END_MARKER);
end-ds;

dcl-c MAX_SECTIONS 3;

// Size of PointerSizeDS = sizeof(pointer) * MAX_SECTIONS
// so a field defined LIKE(PointerSizeDS) has that size
dcl-ds PointerSizeDS qualified;
  pointerPlaceholder pointer dim(MAX_SECTIONS);
end-ds;

// Order doesn't really matter - add new ones at the end
dcl-ds AllSections qualified;
  pointerOverlay like(PointerSizeDS);
  sectionPointers pointer dim(MAX_SECTIONS) overlay(pointerOverlay:1);
  // Following are the array elements of sectionPointers, initialized
  pProgramStatusSection pointer inz(%addr(ProgramStatusSection)) overlay(pointerOverlay:1);
  pFileInfoSection pointer inz(%addr(FileInfoSection)) overlay(pointerOverlay:17);
  pVariablesSection pointer inz(%addr(VariablesSection)) overlay(pointerOverlay:33);
  // Don't have to add any more if adding a new section
end-ds;

// Data structures for file I/O - matching the original input specs
dcl-ds InputLineWithIgc len(133) end-ds;
dcl-ds InputLine len(132);
  pageLocation char(4) pos(124);
  odpSectionText char(24) pos(2);
  captionText char(40) pos(2);
  odpTypeValue char(2) pos(45);
  dumpValueStart char(4) pos(45);
  dumpPointerValue char(16) pos(49);
  odpBlank1 char(4) pos(1);
  odpBlank2 char(3) pos(9);
  odpBlank3 char(2) pos(20);
  odpBlank4 char(2) pos(30);
  odpColumns char(4) pos(5);
end-ds;

dcl-c MSG_ID_TEXT 'Msg id ';
dcl-s isLineSelected char(1) inz('0');
dcl-s isInInfoDataStructure char(1) inz('0');
dcl-s messageIndex packed(5:0);
dcl-s messageLength packed(5:0);

dcl-ds RequestedSections qualified;
  sectionCount int(10);
  sectionNames char(10) dim(MAX_SECTIONS);
end-ds;

dcl-s includeAllLines char(1) inz('0');

dcl-c ODP_INPUT_BUFFER 'Input Buffer:           ';
dcl-c ODP_OUTPUT_BUFFER 'Output Buffer:          ';
dcl-c ODP_TYPE_MESSAGE 'ODP type . . . . . . . .';
dcl-s odpFileType char(2);

dcl-s jobCaptionTexts char(40) dim(11);
dcl-s printerCaptionTexts char(40) dim(3);

dcl-c HEX_DIGITS '0123456789ABCDE';

dcl-s hasTitleLine char(1) inz('0');
dcl-s titleLine like(InputLine);

dcl-ds DumpOptions qualified;
  optionCount int(10);
  optionFlags int(5) dim(2);
end-ds;

// See GETLST command source (parm DUMPINFO) for these literals
dcl-c OPTION_KEEP_INPUT_BUFFER 1;
dcl-c OPTION_KEEP_OUTPUT_BUFFER 2;
dcl-s keepInputBuffer char(1) inz('0');
dcl-s keepOutputBuffer char(1) inz('0');

dcl-s currentOdpSection int(5) inz(ODP_SECTION_OTHER);
dcl-c ODP_SECTION_OTHER 0;
dcl-c ODP_SECTION_INPUT 1;
dcl-c ODP_SECTION_OUTPUT 2;

// Global pointer variable
dcl-s pSectionInfo pointer;

// Main procedure
dcl-proc processGetDmpFltr;
  dcl-pi *n;
    requestedSections likeds(RequestedSections);
    dumpOptions likeds(DumpOptions);
    startFromHereFlag char(1);
    igcDataFlag char(4);
  end-pi;
  
  dcl-s endOfFile ind;
  
  // Initialize the program
  initializeProgram(requestedSections: dumpOptions);
  
  // Open files
  open GetLstIn;
  open GetLstOut;
  
  // Process each record
  endOfFile = *off;
  read GetLstIn InputLineWithIgc;
  dow not %eof(GetLstIn);
    // If we had an IGCDTA(*YES) spool file, the data is
    // shifted right by one
    if igcDataFlag = '*YES';
      InputLine = %subst(InputLineWithIgc: 2);
    else;
      InputLine = %subst(InputLineWithIgc: 1: 132);
    endif;
    
    // Process the line
    processLine(startFromHereFlag);
    
    // Read the next record
    read GetLstIn InputLineWithIgc;
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
  
  dcl-s isFound ind;
  
  isFound = %lookup(captionText: jobCaptionTexts) > 0;
  if isFound;
    %subst(InputLine:45) = *blanks;
  endif;
  
  // Variables stuff
  if VariablesSection.isInVarsSection = '1';
    if (dumpValueStart = 'SPP:' or dumpValueStart = 'SYP:' or dumpValueStart = 'PRP:');
      if dumpPointerValue = '*NULL';
        dumpValueStart = 'SPP:';
      else;
        dumpPointerValue = '<offsets>';
      endif;
    endif;
  endif;
  
  // Infds stuff
  if isInInfoDataStructure = '1';
    // If this is ODP stuff, we don't want it.
    // Columns 1-4, 9-11, 20-21, 30-31 all blank, and col 5-8 hex digits
    // means this is the ODP hex dump.
    
    // Unless they asked us to leave that part in ...
    if not ((keepInputBuffer = '1' and currentOdpSection = ODP_SECTION_INPUT) or
            (keepOutputBuffer = '1' and currentOdpSection = ODP_SECTION_OUTPUT));
      if odpBlank1 = *blanks and
         odpBlank2 = *blanks and
         odpBlank3 = *blanks and
         odpBlank4 = *blanks;
        
        // Check if odpColumns contains only hex digits
        isFound = %check(HEX_DIGITS: odpColumns) = 0;
        
        // All hex digits? De-select this line
        if not isFound;
          isLineSelected = '0';
        endif;
      endif;
    endif;
    
    if odpFileType = 'SP';
      isFound = %lookup(captionText: printerCaptionTexts) > 0;
      if isFound;
        %subst(InputLine:45) = *blanks;
      endif;
    endif;
  endif;
  
  return;
end-proc;

// Process a line from the input file
dcl-proc processLine;
  dcl-pi *n;
    startFromHereFlag char(1);
  end-pi;
  
  dcl-s sectionIndex int(5);
  
  // If we're handling an INFDS
  if isInInfoDataStructure = '1';
    // See if this is the line saying what type of file this INFDS is
    if odpSectionText = ODP_TYPE_MESSAGE;
      odpFileType = odpTypeValue;
    endif;
    
    // See if this is the line saying what part of the ODP we're doing
    if odpBlank1 <> ' ';
      select;
        when odpSectionText = ODP_TYPE_MESSAGE;
          odpFileType = odpTypeValue;
          currentOdpSection = ODP_SECTION_OTHER;
        when odpSectionText = ODP_INPUT_BUFFER;
          currentOdpSection = ODP_SECTION_INPUT;
        when odpSectionText = ODP_OUTPUT_BUFFER;
          currentOdpSection = ODP_SECTION_OUTPUT;
        other;
          currentOdpSection = ODP_SECTION_OTHER;
      endsl;
    endif;
  endif;
  
  // Assume we don't want this line
  isLineSelected = '0';
  
  // Check if it's a "Page n" or title line.
  if pageLocation = 'Page' or InputLine = titleLine;
    return;
  endif;
  
  // Putting this after the previous check will allow the first
  // title line to get printed (if we're getting the prolog)
  if hasTitleLine = '0';
    titleLine = InputLine;
    hasTitleLine = '1';
  endif;
  
  // See if this is the beginning or end of a section
  for sectionIndex = 1 to MAX_SECTIONS;
    // Set basing pointer of SectionInfo to one of the section infos
    pSectionInfo = AllSections.sectionPointers(sectionIndex);
    
    // If we're not in that section, see if this is the start of
    // it. (We want to print this line if it's the beginning of the
    // section)
    if SectionInfo.isInSection = '0' and
       %subst(InputLine: SectionInfo.startPos1: SectionInfo.startPos2-SectionInfo.startPos1+1) = SectionInfo.startValue;
      SectionInfo.isInSection = '1';
      
      // If they want to start copying everything from "here", set on
      // "includeAllLines" now.
      if startFromHereFlag = '1' and SectionInfo.isWanted = '1';
        includeAllLines = '1';
      endif;
      
      isInInfoDataStructure = SectionInfo.isInfoDataStructure;
    endif;
    
    // If we're in that section then see if this is the end of
    // it. (We want to print this line if it's the end of the
    // section)
    if SectionInfo.isInSection = '1' and SectionInfo.isWanted = '1';
      isLineSelected = '1';
      
      if %subst(InputLine: SectionInfo.endPos1: SectionInfo.endPos2-SectionInfo.endPos1+1) = SectionInfo.endValue;
        SectionInfo.isInSection = '0';
      endif;
    endif;
  endfor;
  
  // Output the line if they want it, first clearing out any
  // date or job related info
  if isLineSelected = '1' or includeAllLines = '1';
    isLineSelected = '1';
    filterLine();
    
    // Output if isLineSelected is still '1' (may be unwanted ODP stuff)
    if isLineSelected = '1';
      writeOutputLine();
    endif;
  endif;
  
  return;
end-proc;

// Initialize the program
dcl-proc initializeProgram;
  dcl-pi *n;
    requestedSections likeds(RequestedSections);
    dumpOptions likeds(DumpOptions);
  end-pi;
  
  dcl-s sectionIndex int(5);
  dcl-s requestedIndex int(5);
  dcl-s optionIndex int(5);
  
  // Initialize jobCaptionTexts array
  jobCaptionTexts(1) = 'Job Name . . . . . . . . . . . . . . . :';
  jobCaptionTexts(2) = 'User Name  . . . . . . . . . . . . . . :';
  jobCaptionTexts(3) = 'Job Number . . . . . . . . . . . . . . :';
  jobCaptionTexts(4) = 'Date Entered System  . . . . . . . . . :';
  jobCaptionTexts(5) = '   Century . . . . . . . . . . . . . . :';
  jobCaptionTexts(6) = 'Date Started . . . . . . . . . . . . . :';
  jobCaptionTexts(7) = 'Time Started . . . . . . . . . . . . . :';
  jobCaptionTexts(8) = 'Compile Date . . . . . . . . . . . . . :';
  jobCaptionTexts(9) = 'Compile Time . . . . . . . . . . . . . :';
  jobCaptionTexts(10) = 'Compiler Level . . . . . . . . . . . . :';
  jobCaptionTexts(11) = 'Open Identifier. . . . . . . . . . . . :';
  
  // Initialize printerCaptionTexts array
  printerCaptionTexts(1) = 'Member . . . . . . . . . . . . . . . . :';
  printerCaptionTexts(2) = 'Spool File . . . . . . . . . . . . . . :';
  printerCaptionTexts(3) = 'Spool File Number  . . . . . . . . . . :';
  
  // First see if they want the whole listing, just cleaned up
  if requestedSections.sectionCount = 1 and requestedSections.sectionNames(1) = '*DMPALL';
    includeAllLines = '1';
  else;
    // Go through the sections seeing if the section is one of the ones
    // they want.
    for sectionIndex = 1 to MAX_SECTIONS;
      // Set basing pointer of SectionInfo to one of the section infos
      pSectionInfo = AllSections.sectionPointers(sectionIndex);
      
      // Look through the Wanted array to see if this section is there
      for requestedIndex = 1 to requestedSections.sectionCount;
        if SectionInfo.sectionName = requestedSections.sectionNames(requestedIndex);
          SectionInfo.isWanted = '1';
          leave;
        endif;
      endfor;
    endfor;
  endif;
  
  // See if there are any sections that we normally clear out, but
  // they want to keep.
  for optionIndex = 1 to dumpOptions.optionCount;
    select;
      when dumpOptions.optionFlags(optionIndex) = OPTION_KEEP_INPUT_BUFFER;
        keepInputBuffer = '1';
      when dumpOptions.optionFlags(optionIndex) = OPTION_KEEP_OUTPUT_BUFFER;
        keepOutputBuffer = '1';
    endsl;
  endfor;
  
  return;
end-proc;

// Write a line to the output file
dcl-proc writeOutputLine;
  dcl-pi *n;
  end-pi;
  
  write GetLstOut InputLine;
  
  return;
end-proc;