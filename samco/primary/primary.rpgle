      * ===> crtpf qtemp/evfevento rcdlen(80)                         
      * ===> DSPFD FILE(qtemp/EVFEVENTO)                              
      *       TYPE(*MBRLIST)                                          
      *       OUTPUT(*OUTFILE)                                        
      *       OUTFILE(QTEMP/EVFEVENTI)                                
     FEVFEVENTI ip   e             disk    extdesc('QAFDMBRL')        
     F                                     rename(QWHFDML : irec)     
     FEVFEVENTO o    f   80        disk                               
     FEVFTEMPMBRO    F   10        DISK                               
     D FILE            C                   CONST('QRPGLESRC')         
     D LIBRARY         ds            10                               
     D ds              ds            80                               
     D MEMBER          DS            10                               
     C     *ENTRY        PLIST                                        
     C                   PARM                    LIBRARY              
     C                   if        %subst(MLNAME : 7 : 1) = 'F' or    
     C                             %subst(MLNAME : 7 : 1) = 'D' or    
     C                             %subst(MLNAME : 7 : 1) = 'T'       
     C                   eval      ds = %TRIM(LIBRARY) + '/' + FILE   
     C                                + '(' + %Trim(MLNAME) + ')'     
     C                   write     EVFEVENTO     ds                   
     C                   EVAL      MEMBER = %trim(MLNAME)             
     C                   EVAL      MEMBER = %trim(MLNAME)          
     C                   WRITE     EVFTEMPMBR    MEMBER            
     C                   endif      