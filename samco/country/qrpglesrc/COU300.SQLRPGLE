      *%METADATA                                                                          *
      * %TEXT Functions Country                                                           *
      *%EMETADATA                                                                         *
     h nomain

     // SQL Definitions
     exec sql set option commit=*none, datfmt=*iso, closqlcsr=*endmod;

      /copy qprotosrc,COUNTRY

     d chainCOUNTRY    pr
     D P_COID                         2A    value

     D FCOUN           ds                   qualified
     D  COID                          2A
     D  COUNTR                       50A    varying
     D  COISO                         3A

      *=============================================
     PGetCountryName   B                     export
     DGetCountryName   PI                   like(FCOUN.countr)
     D P_COID                         2A    value
      /free
         chainCOUNTRY(P_COID);
         return FCOUN.COUNTR;
      /end-free
     pGetCountryName   e
      *=============================================
     PGetCountryIso3   B                     export
     DGetCountryIso3   PI                   like(FCOUN.coiso)
     D P_COID                         2A    value
      /free
         chainCOUNTRY(P_COID);
         return FCOUN.COISO;
      /end-free
     pGetCountryIso3   e

      *=============================================
     P ExistCountry    B                     export
     D ExistCountry    PI              n
     D P_COID                         2A    value
     D found           s               n
      /free
         exec sql
           SELECT 1
           INTO :found
           FROM COUNTRY
           WHERE COID = :P_COID;
           
         return SQLSTT = '00000' or SQLSTT = '01000';
      /end-free
     p ExistCountry    e

     p chainCOUNTRY    b
     d chainCOUNTRY    pi
     D P_COID                         2A    value
      /free
         clear FCOUN;
         
         exec sql
           SELECT COID, COUNTR, COISO
           INTO :FCOUN.COID, :FCOUN.COUNTR, :FCOUN.COISO
           FROM COUNTRY
           WHERE COID = :P_COID;
      /end-free
     p chainCOUNTRY    e

     // No need for closeCOUNTRY procedure with SQL