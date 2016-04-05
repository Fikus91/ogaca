      SUBROUTINE XPRLS(MODEL,NOMA,CNSLN,GRLN,CNSVN,
     &                 CNSBL,DELTAT,CFL,FISS,NODTOR,ELETOR,LIGGRD)
      IMPLICIT NONE
      REAL*8         DELTAT,CFL
      CHARACTER*8    MODEL,NOMA,FISS
      CHARACTER*19   CNSLN,GRLN,CNSVN,CNSBL,NODTOR,
     &               ELETOR,LIGGRD

C            CONFIGURATION MANAGEMENT OF EDF VERSION
C MODIF ALGORITH  DATE 15/12/2009   AUTEUR COLOMBO D.COLOMBO 
C ======================================================================
C COPYRIGHT (C) 1991 - 2006  EDF R&D                  WWW.CODE-ASTER.ORG
C THIS PROGRAM IS FREE SOFTWARE; YOU CAN REDISTRIBUTE IT AND/OR MODIFY
C IT UNDER THE TERMS OF THE GNU GENERAL PUBLIC LICENSE AS PUBLISHED BY
C THE FREE SOFTWARE FOUNDATION; EITHER VERSION 2 OF THE LICENSE, OR
C (AT YOUR OPTION) ANY LATER VERSION.
C
C THIS PROGRAM IS DISTRIBUTED IN THE HOPE THAT IT WILL BE USEFUL, BUT
C WITHOUT ANY WARRANTY; WITHOUT EVEN THE IMPLIED WARRANTY OF
C MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. SEE THE GNU
C GENERAL PUBLIC LICENSE FOR MORE DETAILS.
C
C YOU SHOULD HAVE RECEIVED A COPY OF THE GNU GENERAL PUBLIC LICENSE
C ALONG WITH THIS PROGRAM; IF NOT, WRITE TO EDF R&D CODE_ASTER,
C   1 AVENUE DU GENERAL DE GAULLE, 92141 CLAMART CEDEX, FRANCE.
C ======================================================================
C RESPONSABLE MASSIN P.MASSIN
C     ------------------------------------------------------------------
C
C       XPRLS   : X-FEM PROPAGATION DES LEVEL SETS
C       -----     -     --              -     -
C    PROPAGATION DES LEVEL SETS AU PAS DE TEMP SUIVANT
C
C    ENTREE
C        MODEL   : NOM DU CONCEPT MODELE
C        NOMA    : NOM DU CONCEPT MAILLAGE
C        CNSLT   : CHAM_NO_S LEVEL SET TANGENTIELLE supr
C        CNSLN   : CHAM_NO_S LEVEL SET NORMALE
C        GRLT    : CHAM_NO_S GRADIENT DE LEVEL SET TANGENTIELLE suprm
C        GRLN    : CHAM_NO_S GRADIENT DE LEVEL SET NORMALE
C        CNSVN   : CHAM_NO_S DES COMPOSANTES NORMALES DE LA VITESSE DE
C                  PROPAGATION
C        CNSVT   : CHAM_NO_S DES COMPOSANTES TANGENTES DE LA VITESSE DE
C                  PROPAGATION suprm
C        CNSBL   : CHAM_NO_S DES VECTEURS NORMALE ET TANGENTIELLE DE LA
C                  BASE LOCALE
C                  IN CHAQUE NODE DU MAILLAGE
C        DELTAT  : TEMPS TOTAL D'INTEGRATION
C        CFL     : VALEUR DE LA CONDITION CFL A RESPECTER
C        FISS    : NOM DU CONCEPT FISSURE X-FEM DE LA FISSURE A PROPAGER
C        NODTOR  : LISTE DES NOEUDS DEFINISSANT LE DOMAINE DE CALCUL
C        ELETOR  : LISTE DES ELEMENTS DEFINISSANT LE DOMAINE DE CALCUL
C        LIGGRD  : LIGREL DU DOMAINE DE CALCUL (VOIR XPRTOR.F)
C
C    SORTIE
C        CNSLT   : CHAM_NO_S LEVEL SET TANGENTIELLE suprm
C        CNSLN   : CHAM_NO_S LEVEL SET NORMALE
C        GRLT    : CHAM_NO_S GRADIENT DE LEVEL SET TANGENTIELLE suprm
C        GRLN    : CHAM_NO_S GRADIENT DE LEVEL SET NORMALE
C
C     ------------------------------------------------------------------

C     ----- DEBUT COMMUNS NORMALISES  JEVEUX  --------------------------
      INTEGER          ZI
      COMMON  /IVARJE/ ZI(1)
      REAL*8           ZR
      COMMON  /RVARJE/ ZR(1)
      COMPLEX*16       ZC
      COMMON  /CVARJE/ ZC(1)
      LOGICAL          ZL
      COMMON  /LVARJE/ ZL(1)
      CHARACTER*8      ZK8
      CHARACTER*16             ZK16
      CHARACTER*24                      ZK24
      CHARACTER*32                               ZK32
      CHARACTER*80                                        ZK80
      COMMON  /KVARJE/ ZK8(1), ZK16(1), ZK24(1), ZK32(1), ZK80(1)
      CHARACTER*32    JEXNUM,JEXATR
C     -----  FIN  COMMUNS NORMALISES  JEVEUX  --------------------------

      INTEGER    I,IFM,NIV,NBNO,IRET,JLTNO,JLNNO,JGRTNO,JGRNNO,NDIM,
     &           ADDIM,J,NI,JELCAL,JGRTV,JGRNV,JNODTO,NODE,NBNOMA
      INTEGER    JLNI,JLNIL,JGRNI,IBID,NELETO
      CHARACTER*8      K8B,LPAIN(2),LPAOUT(1)
      CHARACTER*19     CNSLNI,CNSGNI,CHGRNI,CHAMSI,
     &                 CHGRLN,CHAMS,CNOLNI,CNOLN
      CHARACTER*24     OBJMA,LCHIN(2),LCHOUT(1)
      REAL*8           NORMGN,NORGNI

      REAL*8           DTLEFT,R8MIEM,R8PREM,DT,DAMAX,TMPLSN
      CHARACTER*8      TYPCMP(3)
      CHARACTER*19     CNSVVT,CNSVVN
      INTEGER          JVTV,JVTL,JVNV,JVNL,JCNSVN

      INTEGER JBL
      REAL*8  BAST(3),TAST(3),N(3),T(3),B(3)

C-----------------------------------------------------------------------
C     DEBUT
C-----------------------------------------------------------------------
      
      CALL JEMARQ()
      CALL INFMAJ()
      CALL INFNIV(IFM,NIV)

      IF (NIV.GE.2) WRITE(IFM,*)'xprls debut et initialisation'

C     RETRIEVE THE LOCAL REFERENCE SYSTEM FOR EACH NODE IN THE MESH
C      CALL JEVEUO(CNSBL//'.CNSV','E',JBL)

C     RECUPERATION DE CARACTERISTIQUES DU MAILLAGE
      CALL DISMOI('F','NB_NO_MAILLA',NOMA,'MAILLAGE',NBNOMA,K8B,IRET)

C     RETRIEVE THE DIMENSION OF THE PROBLEM (2D AND 3D ARE SUPPORTED)
      CALL JEVEUO(NOMA//'.DIME','L',ADDIM)
      NDIM=ZI(ADDIM-1+6)

C     RETRIEVE THE NUMBER OF THE NODES THAT MUST TO BE USED IN THE
C     CALCULUS (SAME ORDER THAN THE ONE USED IN THE CONNECTION TABLE)
      CALL JEVEUO(NODTOR,'L',JNODTO)

C     RETRIEVE THE TOTAL NUMBER OF THE NODES THAT MUST BE ELABORATED
      CALL JELIRA(NODTOR,'LONMAX',NBNO,K8B)

C     RETRIEVE THE LIST OF THE ELEMENTS SUPPORTING THE NODES IN THE TORE
      CALL JEVEUO(ELETOR,'L',JELCAL)

C     RETRIEVE THE NUMBER OF ELEMENTS DEFINING THE TORE
      CALL JELIRA(ELETOR,'LONMAX',NELETO,K8B)

C     INITIALIZE THE REMAINING INTEGRATION TIME VARIABLE
      DTLEFT = DELTAT

C     COUNTER FOR THE NUMBER OF ITERATIONS
      NI=0

      IF (NIV.GE.2) WRITE(IFM,*)'xprls fin de initialisation'

C ***************************************************************
C CALCULATE THE NORMAL AND TANGENTIAL PROPAGATION SPEED VECTOR FOR
C EACH NODE IN THE MESH (WITH RESPECT TO THE CRACK PLANE). THESE
C VECTORS ARE NOT CHANGED DURING THE INTEGRATION OF THE LEVEL SET
C UPDATE EQUATIONS.
C ***************************************************************

C     CREATION OF THE NORMAL AND TANGENTIAL PROPAGATION SPEED VECTORS
C     DATA STRUCTURES (CHAMP_NO_S)
C      CNSVVT = '&&XPRLS.CNSVT'
      CNSVVN = '&&XPRLS.CNSVN'
      TYPCMP(1)='X1'
      TYPCMP(2)='X2'
      TYPCMP(3)='X3'
C      CALL CNSCRE(NOMA,'NEUT_R',NDIM,TYPCMP,'V',CNSVVT)
      CALL CNSCRE(NOMA,'NEUT_R',NDIM,TYPCMP,'V',CNSVVN)

C      CALL JEVEUO(CNSVVT//'.CNSV','E',JVTV)
C      CALL JEVEUO(CNSVVT//'.CNSL','E',JVTL)
      CALL JEVEUO(CNSVVN//'.CNSV','E',JVNV)
      CALL JEVEUO(CNSVVN//'.CNSL','E',JVNL)

C     RETRIEVE THE GRADIENT OF THE TWO LEVEL SETS
      IF (NIV.GE.2) WRITE(IFM,*)'xprls GRADIENT OF THE LEVEL SET'

C     La level set tangente n est pas defini
C      CALL JEVEUO(GRLT//'.CNSV','E',JGRTNO)
      CALL JEVEUO(GRLN//'.CNSV','E',JGRNNO)

C     RETRIEVE THE NORMAL AND TANGENTIAL PROPAGATION SPEEDS (SCALAR
C     VALUE). THESE VALUES WILL BE USED BELOW TO CALCULATE THE
C     PROPAGATION SPEED VECTORS FOR EACH NODE
      IF (NIV.GE.2) WRITE(IFM,*)'xprls PROPAGATION SPEED'

      CALL JEVEUO(CNSVN//'.CNSV','L',JCNSVN)
C      CALL JEVEUO(CNSVT//'.CNSV','L',JCNSVT)

C     ELABORATE EACH NODE IN THE TORE
      DO 400 I=1,NBNO

C         RETREIVE THE NODE NUMBER
          NODE = ZI(JNODTO-1+I)

C           EVALUATE THE SPEED VECTORS
C            WRITE(IFM,*)'xprls av vecteur vitesse'
C            CALL JEVEUO(CNSLT//'.CNSV','E',JLTNO)
C            WRITE(IFM,*)'xprls apre vecteur vitesse'

C           CHECK IF THE NODE IS ON THE EXISTING CRACK SURFACE
C            IF (ZR(JLTNO-1+NODE).LT.R8MIEM()) THEN
C            On utilise toujours le gradient comme direction de propagation

C              CALCULATE THE NORM OF THE GRADIENTS IN ORDER TO EVALUATE
C              THE NORMAL AND TANGENTIAL UNIT VECTORS
               IF(NDIM.EQ.2) THEN
                 NORMGN = ( ZR(JGRNNO-1+2*(NODE-1)+1)**2.D0 +
     &                      ZR(JGRNNO-1+2*(NODE-1)+2)**2.D0 )**.5D0
               ELSE
                 NORMGN = ( ZR(JGRNNO-1+3*(NODE-1)+1)**2.D0 +
     &                      ZR(JGRNNO-1+3*(NODE-1)+2)**2.D0 +
     &                      ZR(JGRNNO-1+3*(NODE-1)+3)**2.D0 )**.5D0
               ENDIF

C              IF THE TANGENTIAL LEVELSET IS NEGATIVE, THE NODE BELONGS
C              TO THE EXISTING CRACK SURFACE. THEREFORE THE GRADIENT OF
C              THE LEVEL SETS IS A GOOD CANDIDATE FOR THE LOCAL
C              REFERENCE SYSTEM.
               DO 405 J=1,NDIM
                 IF(NORMGN.GT.R8PREM()) THEN
                    ZR(JVNV-1+NDIM*(NODE-1)+J) = ZR(JCNSVN-1+NODE)*
     &                              ZR(JGRNNO-1+NDIM*(NODE-1)+J)/NORMGN
                 ELSE
                    ZR(JVNV-1+NDIM*(NODE-1)+J) = 0.D0
                 ENDIF
c concerne le gradient tangant
c                 IF(NORMGT.GT.R8PREM()) THEN
c                    ZR(JVTV-1+NDIM*(NODE-1)+J) = ZR(JCNSVT-1+NODE)*
c     &                              ZR(JGRTNO-1+NDIM*(NODE-1)+J)/NORMGT
c                 ELSE
c                    ZR(JVTV-1+NDIM*(NODE-1)+J) = 0.D0
c                 ENDIF
405            CONTINUE

C            ELSE

C              IF THE TANGENTIAL LEVELSET IS POSITIVE, THE LOCAL
C              REFERENCE SYSTEM CALCULATED PREVIOUSLY FROM THE
C              INFORMATIONS ON THE CRACK FRONT CAN BE USED
C               DO 406 J=1,NDIM
C                 ZR(JVNV-1+NDIM*(NODE-1)+J) = ZR(JCNSVN-1+NODE)*
C     &                                     ZR(JBL-1+2*NDIM*(NODE-1)+J)
C                 ZR(JVTV-1+NDIM*(NODE-1)+J) = ZR(JCNSVT-1+NODE)*
C     &                                ZR(JBL-1+2*NDIM*(NODE-1)+NDIM+J)
C406            CONTINUE

C            ENDIF

400   CONTINUE

C ***************************************************************
C START THE ITERATIONS FOR THE INTEGRATION OF THE LEVEL SET UPDATE
C EQUATION
C ***************************************************************
      IF (NIV.GE.2) WRITE(IFM,*)'xprls init des it intermediarie'

C     CREATION DES OBJETS VOLATILES
c      CNSLTI = '&&XPRLS.CNSLTI'
      CNSLNI = '&&XPRLS.CNSLNI'
c      CNOLTI = '&&XPRLS.CNOLTI'
      CNOLNI = '&&XPRLS.CNOLNI'
c      CHGRTI = '&&XPRLS.CHGRTI'
      CHGRNI = '&&XPRLS.CHGRNI'
c      CNSGTI = '&&XPRLS.CNSGTI'
      CNSGNI = '&&XPRLS.CNSGNI'
c      CHGRLT = '&&XPRLS.CHGRLT'
      CHGRLN = '&&XPRLS.CHGRLN'
      CHAMS  = '&&XPRLS.CHAMS'
c      CNOLT  = '&&XPRLS.CNOLT'
      CNOLN  = '&&XPRLS.CNOLN'

C     CREATE THE CHAMP_NO_S FOR THE INTERMEDIATE LEVEL SETS
C      CALL CNSCRE(NOMA,'NEUT_R',1,'X1','V',CNSLTI)
      CALL CNSCRE(NOMA,'NEUT_R',1,'X1','V',CNSLNI)

C      CALL JEVEUO(CNSLTI//'.CNSV','E',JLTI)
C      CALL JEVEUO(CNSLTI//'.CNSL','E',JLTIL)
      CALL JEVEUO(CNSLNI//'.CNSV','E',JLNI)
      CALL JEVEUO(CNSLNI//'.CNSL','E',JLNIL)

C     INITIALIZE THE INTERMEDIATE LEVEL SET FIELD FOR THE WHOLE
C     COMPUTATION GRID
      DO 500 I=1,NBNOMA

C            ZL(JLTIL-1+I)=.TRUE.
            ZL(JLNIL-1+I)=.TRUE.
C           THE VALUE HAS NO MEANING
            ZR(JLNI-1+I) = 1.D0
C            ZR(JLTI-1+I) = 1.D0

500   CONTINUE

C     BEGIN OF THE INTEGRATION LOOP
300   CONTINUE

C     RECUPERATION DE L'ADRESSE DES VALEURS DE LT, LN ET LEURS GRADIENTS
C      CALL JEVEUO(CNSLT//'.CNSV','E',JLTNO)
      CALL JEVEUO(CNSLN//'.CNSV','E',JLNNO)
C      CALL JEVEUO(GRLT//'.CNSV','E',JGRTNO)
      CALL JEVEUO(GRLN//'.CNSV','E',JGRNNO)

C     EVALUATE THE TIME LEFT FOR THE INTEGRATION
      IF (DTLEFT.GT.CFL) THEN
         DT=CFL
         DTLEFT = DTLEFT-CFL
      ELSE
         DT=DTLEFT
         DTLEFT=0
      ENDIF

C-----------------------------------------------------------------------
C     CALCUL DES LEVEL SETS INTERMEDIAIRES
C-----------------------------------------------------------------------
      IF (NIV.GE.2) WRITE(IFM,*)'xprls debut des it intermediarie'

C     INTEGRATE THE EQUATIONS FOR EACH NODE IN THE TORE
      DO 100 I=1,NBNO

C         RETREIVE THE NODE NUMBER
          NODE = ZI(JNODTO-1+I)

          ZR(JLNI-1+NODE) = 0.D0
C          ZR(JLTI-1+NODE) = 0.D0

          DO 105 J=1,NDIM
C            SCALAR PRODUCT BETWEEN THE NORMAL PROPAGATION SPEED
C            VECTOR AND THE NORMAL GRADIENT
             ZR(JLNI-1+NODE)=ZR(JLNI-1+NODE)+
     &          ZR(JVNV-1+NDIM*(NODE-1)+J)*ZR(JGRNNO-1+NDIM*(NODE-1)+J)

C            SCALAR PRODUCT BETWEEN THE TANGENTIAL PROPAGATION SPEED
C            VECTOR AND  THE TANGENTIAL GRADIENT
C             ZR(JLTI-1+NODE)=ZR(JLTI-1+NODE)+
C     &         ZR(JVTV-1+NDIM*(NODE-1)+J)*ZR(JGRTNO-1+NDIM*(NODE-1)+J)
105       CONTINUE

C         CALCULATE THE VALUE OF THE INTERMEDIATE LEVEL SETS
C         (RUNGE-KUTTA)
C          ZR(JLTI-1+NODE)=ZR(JLTNO-1+NODE)-DT*ZR(JLTI-1+NODE)
          ZR(JLNI-1+NODE)=ZR(JLNNO-1+NODE)-DT*ZR(JLNI-1+NODE)

 100  CONTINUE

C-----------------------------------------------------------------------
C     CALCUL DES GRADIENTS DES LEVEL SETS INTERMEDIAIRES
C-----------------------------------------------------------------------

C  GRADIENT DE LTI
C      CALL CNSCNO(CNSLTI,' ','NON','V',CNOLTI,'F',IBID)
C
C      LPAIN(1) = 'PGEOMER'
C      LCHIN(1) = NOMA//'.COORDO'
C      LPAIN(2) = 'PNEUTER'
C      LCHIN(2) = CNOLTI
C      LPAOUT(1)= 'PGNEUTR'
C      LCHOUT(1)= CHGRTI
C
C      CALL CALCUL('S','GRAD_NEUT_R',LIGGRD,2,LCHIN,LPAIN,1,
C     &            LCHOUT,LPAOUT,'V')
C
C      CALL CELCES ( CHGRTI, 'V', CHAMS )
C      CALL CESCNS ( CHAMS, ' ', 'V', CNSGTI )
C      CALL JEVEUO ( CNSGTI//'.CNSV','L',JGRTI)

C  GRADIENT DE LNI
      CALL CNSCNO(CNSLNI,' ','NON','V',CNOLNI,'F',IBID)

      LPAIN(1) = 'PGEOMER'
      LCHIN(1) = NOMA//'.COORDO'
      LPAIN(2) = 'PNEUTER'
      LCHIN(2) = CNOLNI
      LPAOUT(1)= 'PGNEUTR'
      LCHOUT(1)= CHGRNI

      CALL CALCUL('S','GRAD_NEUT_R',LIGGRD,2,LCHIN,LPAIN,1,
     &            LCHOUT,LPAOUT,'V')

      CALL CELCES ( CHGRNI, 'V', CHAMS )
      CALL CESCNS ( CHAMS, ' ', 'V', CNSGNI )
      CALL JEVEUO ( CNSGNI//'.CNSV','L',JGRNI)

C-----------------------------------------------------------------------
C     CALCUL DES LEVEL SETS RESULTANTES
C-----------------------------------------------------------------------
      IF (NIV.GE.2) WRITE(IFM,*)'xprls lvl set final'

C     INTEGRATE THE EQUATIONS FOR EACH NODE IN THE TORUS
      DO 200 I=1,NBNO

C         RETREIVE THE NODE NUMBER
          NODE = ZI(JNODTO-1+I)
C          WRITE(IFM,*)'xprls node number ',NODE
            TMPLSN = 0.D0
C            TMPLST = 0.D0

            DO 205 J=1,NDIM
C              SCALAR PRODUCT BETWEEN THE NORMAL PROPAGATION SPEED
C              VECTOR AND THE NORMAL GRADIENT
               TMPLSN = TMPLSN+ZR(JVNV-1+NDIM*(NODE-1)+J)*
     &                         ZR(JGRNI-1+NDIM*(NODE-1)+J)

C              SCALAR PRODUCT BETWEEN THE TANGENTIAL PROPAGATION SPEED
C              VECTOR AND THE TANGENTIAL GRADIENT
C               TMPLST = TMPLST+ZR(JVTV-1+NDIM*(NODE-1)+J)*
C     &                         ZR(JGRTI-1+NDIM*(NODE-1)+J)
205         CONTINUE
C            WRITE(IFM,*)'xprls fin boucle dim ',NODE

C           CALCULATE THE NEW VALUE OF THE LEVEL SETS (RUNGE-KUTTA)
            ZR(JLNNO-1+NODE) = (ZR(JLNNO-1+NODE)+ZR(JLNI-1+NODE))/2.D0
     &                         - DT/2.D0*TMPLSN
C            ZR(JLTNO-1+NODE) = (ZR(JLTNO-1+NODE)+ZR(JLTI-1+NODE))/2.D0
C     &                         - DT/2.D0*TMPLST
C            WRITE(IFM,*)'xprls fin nouvelle veleur ',NODE

 200  CONTINUE

C-----------------------------------------------------------------------
C     CALCUL DES GRADIENTS DES LEVEL SETS RESULTANTES
C-----------------------------------------------------------------------
      IF (NIV.GE.2) WRITE(IFM,*)'xprls gradient des lvl set final'

C  GRADIENT DE LT
C      CALL CNSCNO(CNSLT,' ','NON','V',CNOLT,'F',IBID)
C
C      LPAIN(1) = 'PGEOMER'
C      LCHIN(1) = NOMA//'.COORDO'
C      LPAIN(2) = 'PNEUTER'
C      LCHIN(2) = CNOLT
C      LPAOUT(1)= 'PGNEUTR'
C      LCHOUT(1)= CHGRLT
C
C      CALL CALCUL('S','GRAD_NEUT_R',LIGGRD,2,LCHIN,LPAIN,1,
C     &            LCHOUT,LPAOUT,'V')
C
C      CALL CELCES ( CHGRLT, 'V', CHAMS )
C      CALL CESCNS ( CHAMS, ' ', 'V', GRLT )

C  GRADIENT DE LN
      CALL CNSCNO(CNSLN,' ','NON','V',CNOLN,'F',IBID)

      LPAIN(1) = 'PGEOMER'
      LCHIN(1) = NOMA//'.COORDO'
      LPAIN(2) = 'PNEUTER'
      LCHIN(2) = CNOLN
      LPAOUT(1)= 'PGNEUTR'
      LCHOUT(1)= CHGRLN

      CALL CALCUL('S','GRAD_NEUT_R',LIGGRD,2,LCHIN,LPAIN,1,
     &            LCHOUT,LPAOUT,'V')

      CALL CELCES ( CHGRLN, 'V', CHAMS )
      CALL CESCNS ( CHAMS, ' ', 'V', GRLN )

C  DESTRUCTION DES OBJETS VOLATILES
c      CALL JEDETR(CNSLTI)
      CALL JEDETR(CNSLNI)
c      CALL JEDETR(CNOLTI)
      CALL JEDETR(CNOLNI)
c      CALL JEDETR(CHGRTI)
      CALL JEDETR(CHGRNI)
c      CALL JEDETR(CNSGTI)
      CALL JEDETR(CNSGNI)
c      CALL JEDETR(CHGRLT)
      CALL JEDETR(CHGRLN)
      CALL JEDETR(CHAMS)
c      CALL JEDETR(CNOLT)
      CALL JEDETR(CNOLN)

C     INCREMENT THE ITERATION COUNTER
      NI=NI+1

C     CHECK IF THE INTEGRATION HAS BEEN DONE FOR THE WHOLE TIME INTERVAL
      IF (DTLEFT.GT.R8PREM()) THEN
         WRITE(IFM,*)'xprls nouvelle boucle NOMBRE D''ITERATIONS     = ',NI
         GOTO 300
      ENDIF

C     WRITE SOME INFORMATIONS
      IF (NIV.GE.2) THEN
         WRITE(IFM,*)'   NOMBRE D''ITERATIONS                    = ',NI
      ENDIF

C      CALL JEDETR(CNSVVT)
      CALL JEDETR(CNSVVN)

C-----------------------------------------------------------------------
C     FIN
C-----------------------------------------------------------------------
      CALL JEDEMA()
      END
