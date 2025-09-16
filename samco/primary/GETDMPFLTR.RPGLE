      *------------------------------------------------------------
      * MOD# PROGRAMMER      DATE     DESCRIPTION
      * ---- --------------- -------- ----------------------------
      * $00  B. MORRIS       96/11/14 create
      * $01  B. MORRIS       97/09/25 filter out actual pointer values
      * $06  B. MORRIS       98/02/12 keep I/O buffers if asked
      * $07  B. MORRIS       98/11/19 keep "All from this point"
      * $08  B. MORRIS       14/04/22 add IGCDTA parm, *YES means that
      *                               the data is shifted 1 right
      *------------------------------------------------------------
@08C FGetLstIn  IP   F  133        DISK
     FGetLstOut O    F  132        DISK

      *-----------------------------------------------------------------
      * General structure for detecting start and end of a section
      *-----------------------------------------------------------------
     D InfdsSecY       C                   '1'
     D InfdsSecN       C                   '0'
     D Info            DS                  BASED(pInfo)
      *
     D InThis                         1A
     D WantThis                       1A
     D InfdsThis                      1A
     D Section                       10A
      * Start and end position in line to look for start-value
     D S1                             9B 0
     D S2                             9B 0
     D StartVal                      50A
      * Start and end position in line to look for end-value
     D E1                             9B 0
     D E2                             9B 0
     D EndVal                        50

      *-----------------------------------------------------------------
      * How to detect the Dump-PSDS section start and end
      *-----------------------------------------------------------------
     D @DMPPSDS1       C                   'Program Status Area: '
     D @DMPPSDS2       C                   'Member . . . . . '
     D DmpPsds         DS
     D InDmpPsds                      1A   inz('0')
     D WantDmpPsd                     1A   inz('0')
     D                                1A   inz(InfdsSecN)
     D                               10A   inz('*DMPPSDS')
     D                                9B 0 inz(2)
     D                                9B 0 inz(22)
     D                               50    inz(@DMPPSDS1)
     D                                9B 0 inz(2)
     D                                9B 0 inz(18)
     D                               50    inz(@DMPPSDS2)

      *-----------------------------------------------------------------
      * How to detect the Dump-INFDS section start and end
      *-----------------------------------------------------------------
     D @DMPINF1        C                   'INFDS FILE FEEDBACK'
     D @DMPINF2        C                   'Module Name. . . . '
     D DmpInfds        DS
     D InDmpInfds                     1A   inz('0')
     D WantDmpInf                     1A   inz('0')
     D                                1A   inz(InfdsSecY)
     D                               10A   inz('*DMPINFDS')
     D                                9B 0 inz(2)
     D                                9B 0 inz(20)
     D                               50    inz(@DMPINF1)
     D                                9B 0 inz(2)
     D                                9B 0 inz(20)
     D                               50    inz(@DMPINF2)

      *-----------------------------------------------------------------
      * How to detect the Dump-VARS section start and end
      *-----------------------------------------------------------------
     D @DMPVARS1       C                   'Optimization Level . . .'
     D @DMPVARS2       C                   '*   E N D   O F   R P G   D U M P'
     D DmpVars         DS
     D InDmpVars                      1A   inz('0')
     D WantDmpVar                     1A   inz('0')
     D                                1A   inz(InfdsSecN)
     D                               10A   inz('*DMPVARS')
     D                                9B 0 inz(2)
     D                                9B 0 inz(25)
     D                               50    inz(@DMPVARS1)
     D                                9B 0 inz(22)
     D                                9B 0 inz(54)
     D                               50    inz(@DMPVARS2)

     D MaxSection      C                   3

      * Size of LenDs = sizeof(pointer) * MaxSection
      * so a field defined LIKE(LenDs) has that size
     D LenDs           DS
     D Dummy                           *    DIM(MaxSection)

      * Order doesn't really matter - add new ones at the end
      * OVERLAY offset increases by 16
     D AllInfo         DS
     D    InfoPtrsOv                        LIKE(LenDs)
     D    pInfos                       *    DIM(MaxSection)
     D                                      OVERLAY(InfoPtrsOv : 1)
      * Following are the array elements of pInfos, initialized
     D    pDmpPsds                     *    INZ(%ADDR(DmpPsds))
     D                                      OVERLAY(InfoPtrsOv : 1)

     D    pDmpInfds                    *    INZ(%ADDR(DmpInfds))
     D                                      OVERLAY(InfoPtrsOv : 17)

     D    pDmpVars                     *    INZ(%ADDR(DmpVars))
     D                                      OVERLAY(InfoPtrsOv : 33)

      * Don't have to add any more if adding a new section

     D InLineIgcDta    DS           133
     D InLine          DS           132
     D    PageLoc            124    127
     D    OdpSection           2     25
     D    Caption              2     41
     D    InLineOdp           45     46
@01A D    DmpValStrt          45     48
@01A D    DmpPtrVal           49     64
     D    OdpBlnk1             1      4
     D    OdpBlnk2             9     11
     D    OdpBlnk3            20     21
     D    OdpBlnk4            30     31
     D    OdpCols              5      8
     D @MSGID          C                   'Msg id '
     D SelectThis      S              1A   INZ('0')
     D InInfds         S              1A   INZ('0')
     D M1              S              5P 0
     D MLen            S              5P 0

     D WantParm        DS
     D   WantedNum                    4B 0
     D   Wanted                      10A   DIM(MaxSection)
     D WantAll         S              1A   INZ('0')

@06A D ODPInb          C                   'Input Buffer:           '
@06A D ODPOutb         C                   'Output Buffer:          '
     D ODPTypeMsg      C                   'ODP type . . . . . . . .'
     D ODPType         S              2A

     D JobCaption      S                   LIKE(Caption) DIM(11) CTDATA
     D PrtCaption      S                   LIKE(Caption) DIM(3)  CTDATA

     D HexDigits       C                   '0123456789ABCDE'

     D HaveTitle       S              1A   INZ('0')
     D Title           S                   LIKE(InLine)

@05A D DumpInfo        DS
@05A D  NumDI                         4B 0
@05A D  DiArr                         1S 0 DIM(2)

@06A  * See GETLST command source (parm DUMPINFO) for these literals
@06A D @DiInBuf        C                   1
@06A D @DiOutBuf       C                   2
@06A D KeepInBuf       S              1A   inz('0')
@06A D KeepOutBuf      S              1A   inz('0')

@06A D OdpSect         S              5I 0 inz(OdpOther)
@06A D OdpOther        C                   0
@06A D OdpInBuf        C                   1
@06A D OdpOutBuf       C                   2

     IGetLstIn  NS  01
     I                                  1  133  InLineIgcDta
     I                                  1  132  InLine

     C     *ENTRY        PLIST
     C                   PARM                    WantParm
     C                   PARM                    DumpInfo
@07A C                   PARM                    StartFrom         1
@07A C                   PARM                    IgcDta            4

      *----------------------------------------------------------------
      * If we had an IGCDTA(*YES) spool file, the data is
      * shifted right by one
      *----------------------------------------------------------------
     C                   if        IgcDta = '*YES'
     C                   eval      InLine = %subst(InlineIgcDta : 2)
     C                   endif

      *----------------------------------------------------------------
      * If we're handling an INFDS
      *----------------------------------------------------------------
@06C C                   IF        InInfds = '1'
      *----------------------------------------------------------------
      * See if this is the line saying what type of file this INFDS is
      *----------------------------------------------------------------
@06C C                   IF        OdpSection = ODPTypeMsg
@06A C                   EVAL      OdpType = InLineOdp
@06A C                   ENDIF
      *----------------------------------------------------------------
      * See if this is the line saying what part of the ODP we're doing
      *----------------------------------------------------------------
@06A C                   IF        OdpBlnk1 <> ' '
@06A C                   SELECT
@06C C                   WHEN      OdpSection = ODPTypeMsg
@06A C                   EVAL      OdpType = InLineOdp
@06A C                   EVAL      OdpSect = OdpOther
@06A C                   WHEN      OdpSection = ODPInb
@06A C                   EVAL      OdpSect = OdpInBuf
@06A C                   WHEN      OdpSection = ODPOutb
@06A C                   EVAL      OdpSect = OdpOutBuf
@06A C                   OTHER
@06A C                   EVAL      OdpSect = OdpOther
@06A C                   ENDSL
@06A C                   ENDIF
     C                   ENDIF

      *----------------------------------------------------------------
      * Assume we don't want this line
      *----------------------------------------------------------------
     C                   EVAL      SelectThis = '0'

      *----------------------------------------------------------------
      * Check if it's a "Page n" or title line.
      *----------------------------------------------------------------
     C                   IF        PageLoc = 'Page'
     C                             or InLine = Title
     C                   GOTO      Skip
     C                   ENDIF

      *----------------------------------------------------------------
      * Putting this after the previous check will allow the first
      * title line to get printed (if we're getting the prolog)
      *----------------------------------------------------------------
     C                   IF        HaveTitle = '0'
     C                   EVAL      Title = InLine
     C                   EVAL      HaveTitle = '1'
     C                   ENDIF

      *----------------------------------------------------------------
      * See if this is the beginning or end of a section
      *----------------------------------------------------------------
     C                   DO        MaxSection    IX                5 0
      * Set basing pointer of Info to one of the section infos
     C                   EVAL      pInfo = pInfos(IX)

      * If we're not in that section, see if this is the start of
      * it.  (We want to print this line if it's the beginning of the
      * section)
     C                   IF        InThis = '0' and
     C                             %SUBST(InLine : S1 : S2-S1+1) = StartVal
     C                   EVAL      InThis = '1'
@07A  * If they want to start copying everything from "here", set on
@07A  * "WantAll" now.
@07A C                   IF        StartFrom = '1' and WantThis = '1'
@07A C                   EVAL      WantAll = '1'
@07A C                   ENDIF
     C                   EVAL      InInfds = InfdsThis

     C                   ENDIF

      * If we're in that section then see if this is the end of
      * it.  (We want to print this line if it's the end of the
      * section)
     C                   IF        InThis = '1' and WantThis = '1'
     C                   EVAL      SelectThis = '1'

     C                   IF        %SUBST(InLine : E1 : E2-E1+1) = EndVal
     C                   EVAL      InThis = '0'
     C                   ENDIF

     C                   ENDIF

     C                   ENDDO

      *----------------------------------------------------------------
      * Output the line if they want it, first clearing out any
      * date or job related info
      *----------------------------------------------------------------
     C                   IF        SelectThis = '1' or WantAll = '1'
     C                   EVAL      SelectThis = '1'
     C                   EXSR      Filter
      * Output if SelectThis is still '1' (may be unwanted ODP stuff)
     C                   IF        SelectThis = '1'
     C                   EXCEPT    OutLine
     C                   ENDIF
     C                   ENDIF


     C     Skip          TAG


      *-----------------------------------------------------------------
      * Filter - remove date or job-specific info
      *        - also remove printer-file specific info from INFDS
      *        - change the value for dumped pointers to a constant value
      *-----------------------------------------------------------------
     C     Filter        BEGSR
     C     Caption       LOOKUP    JobCaption                             10
     C   10              EVAL      %SUBST(InLine:45) = *BLANKS

@01A  * Variables stuff
@01A C                   IF        InDmpVars = '1'
@01A C                   IF        (DmpValStrt = 'SPP:'
@01A C                             or DmpValStrt = 'SYP:'
@01A C                             or DmpValStrt = 'PRP:')
@01A C                   IF        DmpPtrVal = '*NULL'
@01A C                   EVAL      DmpValStrt = 'SPP:'
@01A C                   ELSE
@01A C                   EVAL      DmpPtrVal = '<offsets>'
@01A C                   ENDIF
@01A C                   ENDIF
@01A C                   ENDIF


      * Infds stuff
     C                   IF        InInfds = '1'

      * If this is ODP stuff, we don't want it.
      * Columns 1-4, 9-11, 20-21, 30-31 all blank, and col 5-8 hex digits
      * means this is the ODP hex dump.

@06A  * Unless they asked us to leave that part in ...
@06A C                   IF        NOT (   ( KeepInBuf = '1' and
@06A C                                       OdpSect = OdpInbuf)
@06A C                                 or  ( KeepOutBuf = '1' and
@06A C                                      OdpSect = OdpOutBuf)   )
     C                   IF            OdpBlnk1 = *BLANKS
     C                             and OdpBlnk2 = *BLANKS
     C                             and OdpBlnk3 = *BLANKS
     C                             and OdpBlnk4 = *BLANKS
     C     HexDigits     CHECK     OdpCols                                10
      * All hex digits?  De-select this line
     C  N10              EVAL      SelectThis = '0'
     C                   ENDIF
@06A C                   ENDIF

     C                   IF        OdpType = 'SP'
     C     Caption       LOOKUP    PrtCaption                             10
     C   10              EVAL      %SUBST(InLine:45) = *BLANKS
     C                   ENDIF
      * End Infds stuff
     C                   ENDIF

     C                   ENDSR


      *-----------------------------------------------------------------
      * INZSR - initialize
      *-----------------------------------------------------------------
     C     *INZSR        BEGSR
      * First see if they want the whole listing, just cleaned up
     C                   IF        WantedNum = 1 and Wanted(1) = '*DMPALL'
     C                   EVAL      WantAll = '1'
     C                   ELSE

      * Go through the sections seeing if the section is one of the ones
      * they want.

     C                   DO        MaxSection    IX                5 0
      * Set basing pointer of Info to one of the section infos
     C                   EVAL      pInfo = pInfos(IX)

      * Look through the Wanted array to see if this section is there
     C                   DO        WantedNum     IY                5 0
     C                   IF        Section = Wanted(IY)
     C                   EVAL      WantThis = '1'
     C                   LEAVE
     C                   ENDIF
     C                   ENDDO

     C                   ENDDO

     C                   ENDIF
      * See if there are any sections that we normally clear out, but
      * they want to keep.
     C                   DO        NumDi         DiX               5 0
     C                   SELECT
     C                   when      DiArr(DiX) = @DiInBuf
     C                   eval      KeepInBuf = '1'
     C                   when      DiArr(DiX) = @DiOutBuf
     C                   eval      KeepOutBuf = '1'
     C                   ENDSL
     C                   ENDDO

     C                   ENDSR

     OGetLstOut E            OutLine
     O                       InLine
**CTDATA JobCaption
Job Name . . . . . . . . . . . . . . . :
User Name  . . . . . . . . . . . . . . :
Job Number . . . . . . . . . . . . . . :
Date Entered System  . . . . . . . . . :
   Century . . . . . . . . . . . . . . :
Date Started . . . . . . . . . . . . . :
Time Started . . . . . . . . . . . . . :
Compile Date . . . . . . . . . . . . . :
Compile Time . . . . . . . . . . . . . :
Compiler Level . . . . . . . . . . . . :
Open Identifier. . . . . . . . . . . . :
**CTDATA PrtCaption
Member . . . . . . . . . . . . . . . . :
Spool File . . . . . . . . . . . . . . :
Spool File Number  . . . . . . . . . . :
