      SUBROUTINE OP0062(IER)
C
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
C
C TOLE CRP_20
      IMPLICIT NONE
      INTEGER           IER
C
C ----------------------------------------------------------------------
C
C OPERATEUR PROPA_CHLVL
C
C CALCUL DE LA levelset APRES PROPAGATION AU PAS DE TEMPS SUIVANT
C
C ----------------------------------------------------------------------
C
C
C OUT IER   : CODE RETOUR ERREUR COMMANDE
C               IER = 0 => TOUT S'EST BIEN PASSE
C               IER > 0 => NOMBRE D'ERREURS RENCONTREES
C
C
C -------------- DEBUT DECLARATIONS NORMALISEES JEVEUX -----------------
C
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
      CHARACTER*32    JEXATR
C
C ---------------- FIN DECLARATIONS NORMALISEES JEVEUX -----------------
C
      INTEGER        IFM,NIV,IBID,NDIM,IRET,ME4,
     &               JCARAF,CLSM,JCONX1,
     &               JCONX2,NBMA,I,J
      INTEGER        IADRMA,JDIME
      INTEGER        JNODTO,JCNSVN,NODE
      REAL*8         LCMIN,DELTAT
      CHARACTER*8    K8B,K8BID,NOMA,NOMO,FISS,FISPRE,METHOD,FISINI
      CHARACTER*8    NCHAVN,NCHAVT
      INTEGER        NFISS,JFISS,JNFIS
      CHARACTER*16   K16BID,TYPDIS
      CHARACTER*19   CNSVT,CNSVN,GRLT,GRLN,CNSLT,CNSLN,CNSEN,CNSBAS,
     &               CNSENR,NOESOM,ISOZRO,NORESI,CNXINV,VCN,VCND,
     &               REFLOC,CNSBL,CNSDIS,VCNT,VCNDT
      CHARACTER*24   LISMAE,LISNOE,SDCONT
      INTEGER        JXC,JXSDC
      CHARACTER*19   TEMP
      REAL*8         MESERR(3),DMIN,DMAX
      CHARACTER*8    TEST,LISNOM(2)
      CHARACTER*1    K1BID

C     MESSAGES
      REAL*8         VALR
      INTEGER        VALI
      CHARACTER*8    MSGOUT(3)

C     CRACK ADVANCEMENT
      REAL*8         DAMAX,DTTOT,R8MIEM,VMAX,VACTUEL,RAYON
      REAL*8         BMAX,PAS
      CHARACTER*24   VVIT,VBETA
      INTEGER        JBETA

C     LEVELSET AUXILIARY MESH
      CHARACTER*8    UNOMO,UNOMA,UFISS,UFISPR,LSTGRD
      INTEGER        JTMP,UJCARA,UNDIM,JUDIME,JLISNO
      CHARACTER*19   UCNSLT,UCNSLN,UGRLT,UGRLN,UCNXIN,DISFR,NODTOR,
     &               ELETOR,LIGGRD
      CHARACTER*24   ULISMA,ULISNO
      LOGICAL        GRIRES

C     DUMMY MODEL
      CHARACTER*8    DNOMA,DNOMO,DFISPR,DFISS
      CHARACTER*19   DCNSLT,DCNSLN,DGRLT,DGRLN,DCNXIN

C     FIELD PROJECTION
      LOGICAL        LDMAX
      REAL*8         DISTMA,R8MAEM,RADTOR
      CHARACTER*16   CORRES
      CHARACTER*8    LPAIN(4),LPAOUT(2)
      CHARACTER*19   CNOLS,CELGLS,CHAMS,GRLS
      CHARACTER*24   LCHIN(4),LCHOUT(2),LIGREL
      CHARACTER*19   NDOMP,EDOMG,PROFCN

C     TEST_MAIL
      REAL*8         DIST,DISTOL

C     DOMAINE LOCALISATION
      INTEGER        NBNO,JGLTP,JGLNP,JGLT,JGLN,JGLTL,JGLNL
      CHARACTER*19   GRLTC,GRLNC
      LOGICAL        GRPRE,TOPRE,GRACT
      REAL*8         RADIMP,RADLIM,CFLPRO

C     taille du maillage
      CHARACTER*24   CHGEOM,CHGEOME
      CHARACTER*19   CHGEOMS
      INTEGER        JGEOM
      LOGICAL        EXIGEO
      REAL*8         XMIN
C
C ----------------------------------------------------------------------
C
      CALL JEMARQ()
      CALL INFMAJ()
      CALL INFDBG('XFEM',IFM,NIV)
C
C --- NOM DU CONCEPT FISSURE
C
      CALL GETRES(FISS,K16BID,K16BID)
C
C --- NOM DU MODELE
C
      CALL GETVID(' ','MODELE',1,1,1,NOMO,IBID)
C
C --- RETRIEVE THE NAME OF THE MODEL THAT SHOULD BE USED AS AN AUXILIARY
C     GRID FOR THE EVALUATION OF THE LEVELSETS.
C
      CALL GETVID(' ','GRILLE_AUX',1,1,1,LSTGRD,IBID)
      IF (IBID.EQ.0) THEN
C        ONLY ONE GRID IS USED
         LSTGRD=' '
      ENDIF

C     CHECK IF THE LOCALIZATION OF THE DOMAIN SHOULD BE ACTIVATED
      GRIRES=.FALSE.
C      CALL GETVTX(' ','ZONE_MAJ',1,1,1,K8BID,IBID)
C      IF (K8BID(1:4).EQ.'TORE') THEN
C        OK, THE LOCALIZATION MUST BE ACTIVATED
C         GRIRES = .TRUE.
C        CHECK IF THE USER HAS SPECIFIED THE RADIUS OF THE TORUS
C         CALL GETVR8(' ','RAYON_TORE',1,1,1,RADIMP,IBID)
C         IF (IBID.EQ.0) THEN
C           THE USER HAS NOT SPECIFIED THE RADIUS OF THE TORUS
C            RADIMP = -1.D0
C         ELSE
C            RADIMP = RADIMP**2
C         ENDIF
C      ELSE
C        THE WHOLE GRID MUST BE USED
C         GRIRES = .FALSE.
C      ENDIF

C
C --- NOM DU MAILLAGE ATTACHE AU MODELE
C
      CALL JEVEUO(NOMO(1:8)//'.MODELE    .LGRF','L',IADRMA)
      NOMA  = ZK8(IADRMA)
C
C --- DIMENSION DU PROBLEME
C

      CALL JEVEUO(NOMA//'.DIME','L',JDIME)
      NDIM  = ZI(JDIME-1+6)
      IF ((NDIM.LT.2).OR.(NDIM.GT.3)) THEN
        CALL U2MESS('F','XFEM_18')
      ENDIF

      CALL DISMOI('F','NB_MA_MAILLA',NOMA,'MAILLAGE',NBMA,K8BID,IBID)
      CALL JEVEUO(NOMA(1:8)//'.CONNEX','L',JCONX1)
      CALL JEVEUO(JEXATR(NOMA(1:8)//'.CONNEX','LONCUM'),'L',JCONX2)
C
C --- CONNECTIVITE INVERSEE
C

      CNXINV = '&&XPRREO.CNCINV'
      CALL CNCINV(NOMA,IBID,0,'V',CNXINV)

C
C --- RETRIEVE THE NAME OF THE CRACK THAT MUST BE ELABORATED
C
      CALL GETVID(' ','FISS_PROP',1,1,1,FISPRE,IBID)


C     VERIFICATION QUE L'ON TRAITE UNE FISSURE ET NON UNE INTERFACE 
      CALL DISMOI('F','TYPE_DISCONTINUITE',FISPRE,'FISS_XFEM',
     &                                                 IBID,TYPDIS,IRET)
C      IF (TYPDIS.NE.'FISSURE') CALL U2MESS('F','XFEM2_1')
      IF (NIV.GE.2) WRITE(IFM,*)'OP0062 pas de test de fissure'

C     RETRIEVE THE MAXIMUM ADVANCEMENT OF THE CRACK FRONT
      CALL GETVR8(' ','DA_MAX',1,1,1,DAMAX,IBID)

C     RETRIEVE le pas de ce calcul
      CALL GETVR8(' ','PAS',1,1,1,PAS,IBID)
      
      
      
C Recuperation du champ de vitesse
      CNSVN='&&OP0062.CNSVN'

      CALL GETVID(' ','CH_VITN',1,1,1,NCHAVN,IBID)
      IF (IBID.EQ.0) THEN
C        ONLY ONE GRID IS USED
         NCHAVN=' '
	 PAS=0
      ELSE
         CALL CNOCNS(NCHAVN,'V',CNSVN)
      ENDIF
      



c      VVIT  = '&&OP0062.VVIT'
C      VBETA = '&&OP0062.VBETA'

C     CALCULATE EVERYTHING IS RELATED TO THE PROPAGATION SPEED OF THE
C     CRACKS OF THE MODEL AND MANAGE THE OPTIONS RELATED TO THIS SPEED
C     (E.G.: TEST_MAIL, NB_POINT_FOND, COMP_LINE)
C      CALL XPRCYC(NOMO,FISPRE,NDIM,DAMAX,VVIT,VBETA,DTTOT,DAFISS)

C
C --- RECUPERATION DES LEVEL SETS ET GRADIENTS
C
      CNSLT = '&&OP0062.CNSLT'
      CNSLN = '&&OP0062.CNSLN'
      GRLT  = '&&OP0062.GRLT'
      GRLN  = '&&OP0062.GRLN'
      CALL CNOCNS(FISPRE//'.LTNO','V',CNSLT)
      CALL CNOCNS(FISPRE//'.LNNO','V',CNSLN)
      CALL CNOCNS(FISPRE//'.GRLTNO','V',GRLT)
      CALL CNOCNS(FISPRE//'.GRLNNO','V',GRLN)
C
C --- DUPLICATION DES GROUP_MA_ENRI ET GROUP_NO_ENRI
C
      LISMAE = FISS//'.GROUP_MA_ENRI'
      LISNOE = FISS//'.GROUP_NO_ENRI'
      CALL JEDUPO(FISPRE//'.GROUP_MA_ENRI','G',LISMAE,.FALSE.)
      CALL JEDUPO(FISPRE//'.GROUP_NO_ENRI','G',LISNOE,.FALSE.)

      CALL JEDUPO(FISPRE//'.INFO','G',FISS//'.INFO',.FALSE.)
C      CALL JEDUPO(FISPRE//'.LTNO','G',FISS//'.LTNO',.FALSE.)
      
      CALL JEDUPO(FISPRE//'.CARAFOND','G',FISS//'.CARAFOND',.FALSE.)
C      CALL JEDUPO(FISPRE//'.TYPE_DISCONTINUITE','G',
c     &                    FISS//'.TYPE_DISCONTINUITE',.FALSE.)
C
C --- RECUPERATION DES CARACTERISTIQUES DU FOND DE FISSURE
C
C      CALL JEDUPO(FISPRE//'.CARAFOND','G',FISS//'.CARAFOND',.FALSE.)
C      CALL JEVEUO(FISS//'.CARAFOND','L',JCARAF)

C   RECUPERATION DE LA METHODE DE REINITIALISATION A EMPLOYER
      CALL GETVTX(' ','METHODE',1,1,1,METHOD,IBID)

C   RETRIEVE THE RADIUS THAT MUST BE USED TO ASSESS THE LOCAL RESIDUAL
      CALL GETVR8(' ','RAYON',1,1,1,RAYON,IBID)

C     SET THE DEFAULT VALUES FOR THE AUXILIARY GRID AND DOMAIN
C     RESTRICTION FLAGS
      GRPRE = .FALSE.
      GRACT = .FALSE.
      TOPRE = .FALSE.

C-----------------------------------------------------------------------
C     RETRIEVE THE AUXILIARY GRID FOR THE LEVELSETS, IF THIS IS THE CASE
C-----------------------------------------------------------------------

      IF(LSTGRD.NE.' ') THEN

C        SET THE FLAG FOR THE AUXILIARY GRID
         GRACT = .TRUE.

         UNOMO = LSTGRD

C        RETRIEVE THE NAME OF THE MAILLAGE
         CALL JEVEUO(UNOMO//'.MODELE    .LGRF','L',IADRMA)
         UNOMA  = ZK8(IADRMA)

C        CHECK THAT THE DIMENSION OF THE LEVELSET MESH IS COHERENT WITH
C        THE DIMENSION OF THE PHYSICAL MESH
         CALL JEVEUO(UNOMA//'.DIME','L',JUDIME)
         UNDIM  = ZI(JUDIME-1+6)
         IF (UNDIM.NE.NDIM) THEN
            CALL U2MESS('F','XFEM2_58')
         ENDIF

C        CHECK THAT A CRACK HAS BEEN DEFINED ON THE AUXILIARY GRID
         CALL JEEXIN(UNOMO//'.NFIS',IBID)
         IF (IBID.EQ.0) THEN
            LISNOM(1) = FISPRE
            LISNOM(2) = LSTGRD
            CALL U2MESK('F','XFEM2_92',2,LISNOM)
         ENDIF

C        CHECK THAT ONLY ONE CRACK HAS BEEN DEFINED FOR THE AUXILIARY
C        GRID
         CALL JEVEUO(UNOMO//'.NFIS','L',JTMP)
         VALI = ZI(JTMP)
         IF (VALI.NE.1)
     &        CALL U2MESG('F','XFEM2_75',1,UNOMO,1,VALI,0,VALR)

C        RETRIEVE THE NAME OF THE SD_FISS_XFEM
         CALL JEVEUO(UNOMO//'.FISS','L',JTMP)
         UFISS = ZK8(JTMP)

C        RETRIEVE THE LEVELSETS AND THEIR GRADIENTS
         UCNSLT = '&&OP0062.UCNSLT'
         UCNSLN = '&&OP0062.UCNSLN'
         UGRLT  = '&&OP0062.UGRLT'
         UGRLN  = '&&OP0062.UGRLN'
         CALL CNOCNS(UFISS//'.LTNO','V',UCNSLT)
         CALL CNOCNS(UFISS//'.LNNO','V',UCNSLN)
         CALL CNOCNS(UFISS//'.GRLTNO','V',UGRLT)
         CALL CNOCNS(UFISS//'.GRLNNO','V',UGRLN)

         CALL DISMOI('F','TYPE_DISCONTINUITE',UFISS,'FISS_XFEM',
     &                                            IBID,TYPDIS,IRET)
c        pas de teste que c est une fissure
c         IF (TYPDIS.NE.'FISSURE') CALL U2MESS('F','XFEM2_1')

C        CHECK IF THE LIST OF NODES WHERE THE RESTRICTION HAS BEEN
C        DONE EXISTS
         CALL JEEXIN(UFISS//'.TORE',IBID)
         IF (IBID.EQ.0) THEN
C           THE LIST DOES NOT EXISTS. THIS MEANS THAT THIS IS THE FIRST
C           PROPAGATION THAT WILL BE CALCULATED USING THE GRID.
C           THE LIST WILL BE CREATED.

C           RETRIEVE THE NUMBER OF NODES DEFINING THE GRID
            CALL DISMOI('F','NB_NO_MAILLA',UNOMA,'MAILLAGE',IBID,K8BID,
     &                  IRET)
            CALL WKVECT(UFISS//'.TORE','G V L',IBID,JLISNO)

            DO 1000 I=1,IBID
               ZL(JLISNO-1+I) = .TRUE.
1000        CONTINUE

         ENDIF

C        CREATE THE INVERSE CONNECTIVITY
         UCNXIN = '&&OP0062.UCNCINV'
         CALL CNCINV(UNOMA,IBID,0,'V',UCNXIN)

C        CREATE A TEMPORARY JEVEUO OBJECT TO STORE THE "CONNECTION"
C        BETWEEN THE PHYSICAL AND AUXILIARY MESH USED IN THE PROJECTION
         CORRES = '&&OP0062.CORRES'

C        WRITE SOME INFORMATIONS ABOUT THE MODELS USED IN THE
C        PROPAGATION
         IF (NIV.GE.1) THEN
            WRITE(IFM,*)' OP0062 LES MODELES SUIVANTS SONT UTILISES'//
     &                  ' OP0062 POUR LA PROPAGATION:'
            WRITE(IFM,*)' OP0062  MODELE PHYSIQUE  : ',NOMO
            WRITE(IFM,*)' OP0062  MODELE LEVEL SETS: ',LSTGRD
         ENDIF

      ELSE

C        NO PROJECTION REQUIRED
         CORRES = ' '

C        CHECK IF THE LIST OF NODES WHERE THE RESTRICTION HAS BEEN
C        DONE EXISTS
         CALL JEEXIN(FISPRE//'.TORE',IBID)
         IF (IBID.EQ.0) THEN
C           THE LIST DOES NOT EXISTS. THIS MEANS THAT THIS IS THE FIRST
C           PROPAGATION THAT WILL BE CALCULATED USING THE RESTRICTION.
C           THE LIST WILL BE CREATED.

C           RETRIEVE THE NUMBER OF NODES DEFINING THE GRID
            CALL DISMOI('F','NB_NO_MAILLA',NOMA,'MAILLAGE',IBID,K8BID,
     &                  IRET)
            CALL WKVECT(FISPRE//'.TORE','G V L',IBID,JLISNO)

            DO 1500 I=1,IBID
               ZL(JLISNO-1+I) = .TRUE.
1500        CONTINUE

         ENDIF

C        WRITE SOME INFORMATIONS ABOUT THE MODELS USED IN THE
C        PROPAGATION
         IF (NIV.GE.1) THEN
            WRITE(IFM,*)'OP0062 LE MEME MODELE EST UTILISE POUR '//
     &                  'LE MAILLAGE PHYSIQUE ET LE '//
     &                  'MAILLAGE LEVEL SETS.'
            WRITE(IFM,*)'OP0062   MODELE UTILISE: ',NOMO
         ENDIF

      ENDIF

C-----------------------------------------------------------------------
C     CHECK FOR THE COHERENCE OF THE USE OF THE AUXILIARY GRID AND
C     DOMAIN LOCALISATION BETWEEN THE PREVIOUS AND THE ACTUAL STEP
C-----------------------------------------------------------------------

C     FOR THE MOMENT, THE LOCALISATION AND THE UPWIND METHOD CAN BE
C     USED TOGETHER ONLY WITH AN AUXILIARY GRID
      IF ((METHOD.EQ.'UPWIND').AND.(.NOT.GRACT).AND.(GRIRES))
     &    CALL U2MESS('F','XFEM2_69')

C     CHECK IF IN THE PREVIOUS PROPAGATION THE AUXILIARY GRID HAS BEEN
C     USED
      CALL JEEXIN(FISPRE//'.GRIAUX',IBID)
      IF (IBID.NE.0) GRPRE = .TRUE.

C     IF THE AUXILIARY GRID WAS USED AND NOW IT HAS BEEN EXCLUDED, AN
C     ERROR IS ISSUED
      IF ((GRPRE).AND.(.NOT.GRACT)) CALL U2MESS('F','XFEM2_95')

C     CHECK IF THE SAME GRID HAS BEEN SPECIFIED BY THE USER
      IF ((GRPRE).AND.(GRACT)) THEN
         CALL JEVEUO(FISPRE//'.GRIAUX','L',IBID)
         IF (ZK8(IBID).NE.LSTGRD) THEN
            MSGOUT(1) = FISPRE
            MSGOUT(2) = ZK8(IBID)
            MSGOUT(3) = LSTGRD
            CALL U2MESK('F','XFEM2_96',3,MSGOUT)
         ENDIF
      ENDIF

C     CHECK IF THE DOMAIN LOCALISATION HAS BEEN USED IN THE PREVIOUS
C     STEP
      IF (GRPRE) THEN
         CALL JEEXIN(UFISS//'.RAYON',IBID)
         IF (IBID.NE.0) TOPRE=.TRUE.
      ELSE
         CALL JEEXIN(FISPRE//'.RAYON',IBID)
         IF (IBID.NE.0) TOPRE=.TRUE.
      ENDIF

C     IF THE DOMAIN LOCALISATION HAS BEEN USED PREVIOUSLY, IT MUST BE
C     USED ALSO IN THIS STEP
      IF ((TOPRE).AND.(.NOT.GRIRES)) CALL U2MESS('F','XFEM2_97')

C     IF THE DOMAIN LOCALISATION HAS BEEN USED PREVIOUSLY WITHOUT AN
C     AUXILIARY GRID, THE SAME MUST BE DONE IN THIS STEP
      IF ((TOPRE).AND.(.NOT.GRPRE).AND.GRACT) THEN
         MSGOUT(1) = FISPRE
         CALL U2MESK('F','XFEM2_98',1,MSGOUT)
      ENDIF

C     IF AN AUXILIARY GRID IS USED IN THIS STEP, STORE ITS NAME
      IF (GRACT) THEN
         CALL WKVECT(FISS//'.GRIAUX','G V K8',1,IBID)
         ZK8(IBID) = LSTGRD
      ENDIF

C-----------------------------------------------------------------------
C     SET THE CORRECT VALUE OF THE WORKING MODEL IN ORDER TO ASSESS
C     CORRECTLY THE CASE IN WHICH THE USER WANTS TO USE ONLY ONE MODEL
C     AND THE CASE IN WHICH HE OR SHE WANTS TO USE TWO DIFFERENT MODELS.
C     ALL THE FOLLOWING SUBROUTINES REFER TO A DUMMY MODEL AND ALL THE
C     VARIABLES REFERRED TO THIS MODEL BEGIN WITH THE LETTER "D".
C-----------------------------------------------------------------------

      IF(LSTGRD.NE.' ') THEN

         IF (NIV.GE.1) 
     &	  WRITE(IFM,*)'OP0062 la grille auxiliaire est desactive '

         DNOMA  = UNOMA
         DFISS  = UFISS
         DNOMO  = UNOMO
c         DCNSLT = UCNSLT
         DCNSLN = UCNSLN
c         DGRLT  = UGRLT
         DGRLN  = UGRLN
         DCNXIN = UCNXIN

      ELSE

         DNOMA  = NOMA
         DFISS  = FISS
         DNOMO  = NOMO
c        DCNSLT = CNSLT
         DCNSLN = CNSLN
c         DGRLT  = GRLT
         DGRLN  = GRLN
         DCNXIN = CNXINV

      ENDIF


C-----------------------------------------------------------------------
C     CALCUL DES LONGUEURS CARACTERISTIQUES ET DES CONDITIONS CFL
C-----------------------------------------------------------------------

      IF (NIV.GE.1) THEN
         WRITE(IFM,*)
         WRITE(IFM,*) 'OP0062-2) '//
     &         'CALCUL DE LA LONGUEUR CARACTERISTIQUE'
         WRITE(IFM,902)
      ENDIF

      CALL XPRCFL(DNOMO,LCMIN)

C     THE VALUE OF RAYON MUST BE GREATER THAN THE SHORTEST EDGE IN THE
C     MESH IN ORDER TO BE ABLE TO CALCULATE THE LOCAL RESIDUAL
      IF (RAYON.LT.LCMIN) THEN
         MESERR(1)=RAYON
         MESERR(2)=LCMIN
         CALL U2MESR('F','XFEM2_64',2,MESERR)
      ENDIF

C     THE VALUE OF DAMAX SHOULD BE GREATER THAN THE SHORTEST EDGE IN THE
C     MESH. IF THIS IS NOT TRUE, THE MESH COULD FAIL TO CORRECTLY
C     REPRESENT THE LEVEL SETS. THIS IS NOT A FATAL ERROR AND A WARNING
C     MESSAGE IS ISSUED.
C      IF (LCMIN.GT.DAMAX) THEN
C         MESERR(1)=DAMAX
C         MESERR(2)=LCMIN
C         CALL U2MESR('A','XFEM2_63',2,MESERR)
C      ENDIF

C-----------------------------------------------------------------------
C     DOMAINS USED FOR THE RESTRICTION AND FOR THE PROJECTION
C-----------------------------------------------------------------------

      IF (NIV.GE.1) THEN
         WRITE(IFM,*)
         WRITE(IFM,*)'OP0062-3) DOMAINE DE CALCUL'
         WRITE(IFM,901)
      ENDIF

      NOESOM = '&&OP0062.NOESOM'
      NORESI = '&&OP0062.NORESI'
      VCN = '&&OP0062.VCN'
      VCND = '&&OP0062.VCND'
      IF (GRIRES) THEN
         VCNT = '&&OP0062.VCNT'
         VCNDT = '&&OP0062.VCNDT'
      ELSE
         VCNT  = VCN
         VCNDT = VCND
      ENDIF
      REFLOC = '&&OP0062.REFLOC'

C     INITIALISE THE SIMPLEXE OR THE UPWIND SCHEMA.
C     DFISPR AND FISS ARE NOT USED BY THE UPWIND SCHEMA. HOWEVER THEY
C     ARE PASSED TO THE SUBROUTINE IN ORDER TO USE THE SAME SUBROUTINE
C     FOR THE SIMPLEXE AND UPWIND SCHEMA.
      CALL XPRINI(DNOMO,DNOMA,DCNXIN,FISPRE,DFISS,DCNSLN,DGRLN,
     &            NOESOM,NORESI,VCN,VCND,REFLOC)  

C     DEFINE THE PROJECTION DOMAINS FOR THE PHYSICAL AND LEVEL SET
C     MESHES (IF THE AUXILIARY GRID IS USED)
      IF (LSTGRD.NE.' ') THEN
         IF (NIV.GE.2) THEN
         WRITE(IFM,*)'OP0062-debut de XPRDOM'
         ENDIF
         NDOMP = '&&OP0062.NDOMP'
         EDOMG = '&&OP0062.EDOMG'
         CALL XPRDOM(DNOMO,DNOMA,DCNXIN,DISFR,NOMO,NOMA,CNXINV,FISPRE,
     &               DAMAX,NDOMP,EDOMG,RADTOR)
      ELSE
C        IF THE PROJECTION HAS NOT BEEN SELECTED, THE ESTIMATION OF THE
C        RADIUS OF THE TORUS DEFINING THE LOCAL DOMAIN TO BE USED FOR
C        THE LEVEL SET UPDATE CALCULATIONS MUST BE ESTIMATED HERE
         RADTOR = (RAYON+DAMAX)**2
      ENDIF

C     RETREIVE THE RADIUS OF THE TORUS TO BE IMPOSED
      IF (GRIRES) THEN
C        THE USER HAS NOT SPECIFIED THE RADIUS. THE RADIUS USED IN
C        THE PREVIOUS PROPAGATION SHOULD BE RETREIVED, IF ANY
         IF (RADIMP.LT.0.D0) THEN
            IF(TOPRE.AND.GRPRE) THEN
               CALL JEVEUO(UFISS//'.RAYON','L',IBID)
               RADIMP = ZR(IBID)
            ENDIF
            IF(TOPRE.AND.(.NOT.GRPRE)) THEN
               CALL JEVEUO(FISPRE//'.RAYON','L',IBID)
               RADIMP = ZR(IBID)
            ENDIF
         ENDIF
      ENDIF

C     DEFINE THE DOMAIN USED FOR THE LEVEL SET COMPUTATION (ONLY IF
C     THE LOCALISATION HAS BEEN SELECTED)
      NODTOR='&&OP0062.NODTOR'
      ELETOR='&&OP0062.ELETOR'
      LIGGRD='&&OP0062.LIGGRD'
      IF (LSTGRD.NE.' ') THEN
         CALL XPRTOR(METHOD,DNOMO,DNOMA,DCNXIN,DFISS,DFISS,
     &               VCN,VCND,DCNSLN,DGRLN,DCNSLT,DGRLT,GRIRES,RADTOR,
     &               RADIMP,CNSDIS,DISFR,CNSBL,NODTOR,ELETOR,LIGGRD,
     &               VCNT,VCNDT)
      ELSE
         CALL XPRTOR(METHOD,DNOMO,DNOMA,DCNXIN,FISPRE,DFISS,
     &               VCN,VCND,DCNSLN,DGRLN,DCNSLT,DGRLT,GRIRES,
     &               RADTOR,RADIMP,CNSDIS,DISFR,CNSBL,NODTOR,ELETOR,
     &               LIGGRD,VCNT,VCNDT)
      ENDIF

C     CHECK IF THE RADIUS OF THE TORUS IS GREATER THAN THE CRITICAL
C     VALUE
      IF (TOPRE) THEN
         IF (GRPRE) THEN
            CALL JEVEUO(UFISS//'.RAYON','L',IBID)
         ELSE
            CALL JEVEUO(FISPRE//'.RAYON','L',IBID)
         ENDIF

C        CALCULATE THE CRITICAL VALUE OF THE RADIUS
         RADLIM = DAMAX**2+ZR(IBID)**2

         IF(RADLIM.LT.RADTOR) THEN
            MESERR(1)=SQRT(RADTOR)
            MESERR(2)=SQRT(RADLIM)
            CALL U2MESR('A','XFEM2_88',3,MESERR)
         ENDIF

      ENDIF

      IF ((GRIRES).AND.(NIV.GE.1)) THEN
         WRITE(IFM,*)'OP0062   LE DOMAINE DE CALCUL EST LOCALISE '//
     &               ' AUTOUR DU FOND DE LA FISSURE:'
         WRITE(IFM,*)'OP0062      RAYON DU TORE DE LOCALISATION = ',
     &                SQRT(RADTOR)

         CALL JELIRA(NODTOR,'LONMAX',I,K1BID)
         WRITE(IFM,*)'OP0062      NOMBRE DE NOEUDS DU DOMAINE   = ',I
      ENDIF

      IF ((.NOT.(GRIRES)).AND.(NIV.GE.1)) THEN
         IF(LSTGRD.EQ.' ') THEN
            WRITE(IFM,*)'OP0062   LE DOMAINE DE CALCUL COINCIDE '//
     &                  ' AVEC LE MODELE PHYSIQUE ',NOMO
         ELSE
            WRITE(IFM,*)'OP0062   LE DOMAINE DE CALCUL COINCIDE '//
     &                  ' AVEC LE MODELE LEVEL SET ',LSTGRD
         ENDIF
      ENDIF

C-----------------------------------------------------------------------
C     AJUSTEMENT DE VT
C-----------------------------------------------------------------------

      IF (NIV.GE.1) THEN
         WRITE(IFM,*)
         WRITE(IFM,*)'OP0062-4) DETERMINATION DE VMAX'
         WRITE(IFM,903)
      ENDIF

      IF (PAS.NE.0) THEN
C        RETRIEVE THE TOTAL NUMBER OF THE NODES THAT MUST BE ELABORATED
         CALL JELIRA(NODTOR,'LONMAX',NBNO,K8B)
      
C        RETRIEVE THE NUMBER OF THE NODES THAT MUST TO BE USED IN THE
C        CALCULUS (SAME ORDER THAN THE ONE USED IN THE CONNECTION TABLE)
         CALL JEVEUO(NODTOR,'L',JNODTO)
      
C        Champ des vitesse champ de vitesse CNSVN
         CALL JEVEUO(CNSVN//'.CNSV','L',JCNSVN)
      
         VMAX=0.D0
         DO 400 I=1,NBNO

C            RETREIVE THE NODE NUMBER
             NODE = ZI(JNODTO-1+I)
             VACTUEL=ABS(ZR(JCNSVN-1+NODE))
C	     WRITE(IFM,*)'OP0062  Vactuel= ',VACTUEL
             IF(VMAX.LT.VACTUEL)
     &          VMAX=VACTUEL

400      CONTINUE
      ELSE
         VMAX=0
      ENDIF
      IF (NIV.GE.1) WRITE(IFM,*)'OP0062  VMAX= ',VMAX
      
C      CALL JEDETR(JNODTO)
C      CALL JEDETR(JCNSVN)

C      CALL XPRAJU(DNOMA,DFISS,DCNSLT,CNSVT,CNSVN,DTTOT,VMAX)


C-----------------------------------------------------------------------
C     PROPAGATION DES LEVEL SETS
C-----------------------------------------------------------------------
      IF (VMAX.EQ.0) THEN
         IF (NIV.GE.1) WRITE(IFM,*)'OP0062 PAS DE PROPAGATION '
	 
      ELSE
C     CALCULATE THE CFL CONDITION FOR THE PROPAGATION OF THE LEVEL SETS
         CFLPRO = LCMIN/VMAX
         DTTOT = PAS
         IF (NIV.GE.1) THEN
            WRITE(IFM,*)
            WRITE(IFM,*)'OP0062-5) PROPAGATION DES LEVEL SETS'
            WRITE(IFM,904)

C        WRITE SOME INFORMATIONS
            WRITE(IFM,*)'OP0062-PAS = ',PAS
	    WRITE(IFM,*)'OP0062-LCMIN = ',LCMIN
            WRITE(IFM,*)'OP0062condition CFL (CFLPRO)  = '
     &               ,CFLPRO
         ENDIF


         CALL XPRLS(DNOMO,DNOMA,DCNSLN,DGRLN,CNSVN,
     &           CNSBL,DTTOT,CFLPRO,DFISS,NODTOR,ELETOR,LIGGRD)
      ENDIF
      
c      CALL JEDETR(CNSVT)
      CALL JEDETR(CNSVN)
      CALL JEDETR(CNSBL)

C-----------------------------------------------------------------------
C     REINITIALISATION DE LSN
C-----------------------------------------------------------------------

      IF (NIV.GE.1) THEN
         WRITE(IFM,*)
         WRITE(IFM,*)'OP0062-6) REINITIALISATION DE LSN'
	 WRITE(IFM,*)'OP0062-6) LCMIN=',LCMIN
         WRITE(IFM,905)
      ENDIF

      DELTAT = LCMIN*0.45D0
      ISOZRO = '&&OP0062.ISOZRO'

c suprime,DCNSLT

      IF (METHOD.EQ.'SIMPLEXE') THEN
         CALL XPRREI(DNOMO,DNOMA,DFISS,NOESOM,NORESI,DCNSLN,
     &               DGRLN,DELTAT,LCMIN,ISOZRO,DCNXIN,NODTOR,
     &               ELETOR,LIGGRD)
      ENDIF
      
C "ELSE" AVOIDED IN ORDER TO LEAVE ROOM FOR A FUTURE METHOD
      IF (METHOD.EQ.'UPWIND') THEN
C     IN THE UPWIND SCHEME THE FISS DATA STRUCTURE IS NOT USED. HOWEVER
C     THE SUBROUTINE XPRLS0 IS CALLED INSIDE THE UPWIND SUBROUTINE AND
C     IT REQUIRES THAT THE FISS DATA STRUCTURE IS PASSED AS AN INPUT
C     PARAMETER. HOWEVER ALSO XPRLS0 DOES NOT USE THE FISS DATA
C     STRUCTURE!
c         CALL XPRUPW('REINITLN',DNOMO,DNOMA,DFISS,VCNT,VCNDT,
c     &               REFLOC,NOESOM,LCMIN,DCNSLN,DGRLN,DCNSLT,DGRLT,
c     &               DELTAT,NORESI,ISOZRO,NODTOR,ELETOR,LIGGRD)
      ENDIF

      IF (NIV.GE.2) WRITE(IFM,*)'OP0062 debut des destruction '
      
      CALL JEDETR(VVIT)
      CALL JEDETR(VBETA)
      IF (NIV.GE.2) WRITE(IFM,*)'OP0062 1'
      CALL JEDETR(ISOZRO)
      CALL JEDETR(NOESOM)
      IF (NIV.GE.2) WRITE(IFM,*)'OP0062 avant upwind '
      
      IF (METHOD(1:6).EQ.'UPWIND') THEN
         CALL JEDETR(VCN)
         CALL JEDETR(VCND)
         IF (GRIRES) THEN
            CALL JEDETR(VCNT)
            CALL JEDETR(VCNDT)
         ENDIF
      ENDIF
      IF (NIV.GE.2) WRITE(IFM,*)'OP0062 1b'
      CALL JEDETR(REFLOC)
      IF (NIV.GE.2) WRITE(IFM,*)'OP0062 1b'
C     Distance entre chaque noeud et le fond de fissure non ini
C      CALL JEDETR(CNSDIS)
      IF (NIV.GE.2) WRITE(IFM,*)'OP0062 1b'
      CALL JEDETR(NODTOR)
      IF (NIV.GE.2) WRITE(IFM,*)'OP0062 2'
      CALL JEDETR(ELETOR)
      CALL JEDETR(LIGGRD)

      IF (NIV.GE.2) WRITE(IFM,*)'OP0062 fin des destruction '

C-----------------------------------------------------------------------
C     THE NEW VALUES OF THE LEVELSETS FOR THE AUXILIARY MESH (TWO GRIDS
C     CASE ONLY) ARE STORED. AFTER THAT THESE VALUES MUST BE PROJECTED
C     TO THE PHYSICAL MESH FOR THE FRACTURE MECHANICS COMPUTATIONS.
C-----------------------------------------------------------------------

      IF (CORRES.NE.' ') THEN

C       CREATE THE CHAMP_NO WITH THE NEW VALUES OF THE LEVELSETS AND
C       THEIR GRADIENTS. THE EXISTING CHAMP_NO ARE AUTOMATICALLY
C       DESTROYED BY THE SUBROUTINE "CNSCNO"
        CALL DISMOI('F','PROF_CHNO',UFISS//'.LTNO','CHAM_NO',IBID,
     &              PROFCN,IBID)
        CALL CNSCNO(DCNSLT,PROFCN,'OUI','G',UFISS//'.LTNO','F',IBID)

        CALL DISMOI('F','PROF_CHNO',UFISS//'.LNNO','CHAM_NO',IBID,
     &              PROFCN,IBID)
        CALL CNSCNO(DCNSLN,PROFCN,'OUI','G',UFISS//'.LNNO','F',IBID)

        CALL DISMOI('F','PROF_CHNO',UFISS//'.GRLTNO','CHAM_NO',IBID,
     &              PROFCN,IBID)
        CALL CNSCNO(DGRLT,PROFCN,'OUI','G',UFISS//'.GRLTNO','F',IBID)

        CALL DISMOI('F','PROF_CHNO',UFISS//'.GRLNNO','CHAM_NO',IBID,
     &              PROFCN,IBID)
        CALL CNSCNO(DGRLN,PROFCN,'OUI','G',UFISS//'.GRLNNO','F',IBID)

C       PROJECT THE LEVEL SETS
        CALL XPRPLS(DNOMO,DCNSLN,DCNSLT,NOMO,NOMA,
     &              CNSLN,CNSLT,GRLN,GRLT,CORRES,NDIM,NDOMP,EDOMG)

      ENDIF
      
      IF (NIV.GE.2) WRITE(IFM,*)'OP0062 fin de la recorrespodance'

      CALL JEDETR(DISFR)

C     NOW I CAN WORK ON THE PHYSICAL MESH

C-----------------------------------------------------------------------
C     REAJUSTEMENT DES LEVEL SETS TROP PROCHES DE 0
C-----------------------------------------------------------------------
      IF (NIV.GE.1) THEN
         WRITE(IFM,*)
         WRITE(IFM,*)'OP0062-9) ENRICHISSEMENT DE LA SD FISS_XFEM'
         WRITE(IFM,908)
      ENDIF

      CALL XAJULS(IFM,NOMA,NBMA,CNSLT,CNSLN,JCONX1,JCONX2,CLSM)

      IF (NIV.GE.1) THEN
         WRITE(IFM,*)'OP0062 Nb DE LvlL SET REAJUST APRES CONTROLE:',
     &               CLSM
      ENDIF

C-----------------------------------------------------------------------
C     EXTENSION DES LEVEL SETS AUX NOEUDS MILIEUX
C-----------------------------------------------------------------------

      CALL XPRMIL(NOMA,CNSLT,CNSLN)
C      CALL XPRMIL(NOMA,CNSLN,CNSLN)
      IF (NIV.GE.2) WRITE(IFM,*)'OP0062 debug fin de xprmil'

C     IF THE DOMAINE LOCALISATION HAS BEEN USED ON THE PHYSICAL MODEL,
C     THE VALUES OF THE LEVEL SET GRADIENTS OUTSIDE THE DOMAINE MUST
C     BE COPIED FROM THE ORIGINAL VALUES (NOW THEY ARE EQUAL TO ZERO!)
      IF ((CORRES.EQ.' ').AND.GRIRES) THEN
C        RETRIEVE THE LIST OF THE NODES USED IN THE LAST LOCALIZATION
         CALL JEVEUO(FISS//'.TORE','E',JLISNO)
         CALL JELIRA(FISS//'.TORE','LONMAX',NBNO,K8BID)

         GRLTC  = '&&OP0062.GRLTC'
         GRLNC  = '&&OP0062.GRLNC'

         CALL CNOCNS(FISPRE//'.GRLTNO','V',GRLTC)
         CALL CNOCNS(FISPRE//'.GRLNNO','V',GRLNC)

         CALL JEVEUO(GRLTC//'.CNSV','L',JGLTP)
         CALL JEVEUO(GRLNC//'.CNSV','L',JGLNP)

         CALL JEVEUO(GRLT//'.CNSV','E',JGLT)
         CALL JEVEUO(GRLT//'.CNSL','E',JGLTL)
         CALL JEVEUO(GRLN//'.CNSV','E',JGLN)
         CALL JEVEUO(GRLN//'.CNSL','E',JGLNL)

         DO 2000 I=1,NBNO

            IF (.NOT.(ZL(JLISNO-1+I))) THEN
               ZR(JGLT-1+NDIM*(I-1)+1) = ZR(JGLTP-1+NDIM*(I-1)+1)
               ZL(JGLTL-1+NDIM*(I-1)+1) = .TRUE.
               ZR(JGLT-1+NDIM*(I-1)+2) = ZR(JGLTP-1+NDIM*(I-1)+2)
               ZL(JGLTL-1+NDIM*(I-1)+2) = .TRUE.

               ZR(JGLN-1+NDIM*(I-1)+1) = ZR(JGLNP-1+NDIM*(I-1)+1)
               ZL(JGLNL-1+NDIM*(I-1)+1) = .TRUE.
               ZR(JGLN-1+NDIM*(I-1)+2) = ZR(JGLNP-1+NDIM*(I-1)+2)
               ZL(JGLNL-1+NDIM*(I-1)+2) = .TRUE.

               IF(NDIM.EQ.3) THEN
                  ZR(JGLT-1+NDIM*(I-1)+3) = ZR(JGLTP-1+NDIM*(I-1)+3)
                  ZL(JGLTL-1+NDIM*(I-1)+3) = .TRUE.

                  ZR(JGLN-1+NDIM*(I-1)+3) = ZR(JGLNP-1+NDIM*(I-1)+3)
                  ZL(JGLNL-1+NDIM*(I-1)+3) = .TRUE.
               ENDIF

            ENDIF

2000     CONTINUE

         CALL JEDETR(GRLTC)
         CALL JEDETR(GRLNC)

      ENDIF

      CALL CNSCNO(CNSLT,' ','NON','G',FISS//'.LTNO','F',IBID)
      CALL CNSCNO(CNSLN,' ','NON','G',FISS//'.LNNO','F',IBID)
      CALL CNSCNO(GRLT,' ','NON','G',FISS//'.GRLTNO','F',IBID)
      CALL CNSCNO(GRLN,' ','NON','G',FISS//'.GRLNNO','F',IBID)

C     IF THE DOMAIN LOCALISATION HAS NOT BEEN USED, THE BOOLEAN LIST
C     OF THE NODES IN THE TORE MUST BE DESTROYED
      IF (.NOT.GRIRES) THEN
         IF (.NOT.GRACT) THEN
            CALL JEDETR(FISS//'.TORE')
         ELSE
            CALL JEDETR(UFISS//'.TORE')
         ENDIF
      ENDIF

C     IF THE DOMAIN LOCALISATION HAS BEEN USED, THE RADIUS OF THE TORUS
C     USED IN THE LOCALISATION MUST BE STORED
      IF (GRIRES) THEN
         IF (.NOT.GRACT) THEN
            CALL WKVECT(FISS//'.RAYON','G V R',1,IBID)
         ELSE
            CALL JEEXIN(UFISS//'.RAYON',IBID)
            IF (IBID.EQ.0) THEN
               CALL WKVECT(UFISS//'.RAYON','G V R',1,IBID)
            ELSE
               CALL JEVEUO(UFISS//'.RAYON','E',IBID)
            ENDIF
         ENDIF
C        VALUE OF THE RADIUS USED IN THE ACTUAL PROPAGATION
         ZR(IBID) = RADTOR
      ENDIF

C----------------------------------------------------------------------+
C                 FIN DE LA PARTIE PROPAGATION :                       |
C                 ----------------------------                         |
C    LA SD FISS_XFEM EST ENRICHIE COMME DANS OP0041 : DEFI_FISS_XFEM   |
C   ( TOUTE MODIF. AFFECTANT OP0041 DOIT ETRE REPERCUTEE PLUS BAS,     |
C     EXCEPTE L'APPEL A SDCONX )                                       |
C----------------------------------------------------------------------+

C-----------------------------------------------------------------------
C     CALCUL DE L'ENRICHISSEMENT ET DES POINTS DU FOND DE FISSURE
C-----------------------------------------------------------------------

      CNSEN='&&OP0062.CNSEN'
      CNSENR='&&OP0062.CNSENR'

      CALL XENRCH(NOMO,NOMA,CNSLT,CNSLN,CNSEN,CNSENR,
     &                NDIM,FISS,LISMAE,LISNOE)
C      CALL XENRCH(NOMO,NOMA,CNSLN,CNSLN,CNSEN,CNSENR,
C     &                NDIM,FISS,LISMAE,LISNOE)

      CALL CNSCNO(CNSENR,' ','NON','G',FISS//'.STNOR','F',IBID)
      CALL CNSCNO(CNSEN,' ','NON','G',FISS//'.STNO','F',IBID)


C-----------------------------------------------------------------------
C     CALCUL DE LA BASE LOCALE AU FOND DE FISSURE
C-----------------------------------------------------------------------

      CALL XBASLO(NOMO  ,NOMA  ,FISS  ,GRLT  ,GRLN  , NDIM)
C      CALL JEDUPO(FISPRE//'.BASLOC','G',FISS//'.BASLOC',.FALSE.)

C-----------------------------------------------------------------------
C     ELABORATE THE OPTION "TEST_MAIL"
C-----------------------------------------------------------------------

C     RETRIEVE THE VALUE FOR THE "TEST_MAIL" PARAMETER
C      CALL GETVTX(' ','TEST_MAIL',1,1,1,TEST,IBID)

C     CHECK THE MESH, IF THIS IS THE CASE
C      IF (TEST(1:3).EQ.'OUI') THEN
C        RETREIVE THE DISTANCE BETWEEN THE PROPAGATED CRACK AND THE
C        INITIAL FRONT
C         CALL GETVR8(' ','DISTANCE',1,1,1,DIST,IBID)
C        RETREIVE THE VALUE OF THE TOLERANCE
C         CALL GETVR8(' ','TOLERANCE',1,1,1,DISTOL,IBID)
C        RETREIVE THE INITIAL CRACK
C         CALL GETVID(' ','FISS_INITIALE',1,1,1,FISINI,IBID)
C        CHECK THE CRACK FRONT
C         CALL XPRDIS(FISINI,FISS,DIST,DISTOL,LCMIN)

C      ENDIF

C-----------------------------------------------------------------------
C     FIN
C-----------------------------------------------------------------------
      CALL JEDETR(CNXINV)

 901  FORMAT (10X,37('-'))
 902  FORMAT (10X,55('-'))
 903  FORMAT (10X,35('-'))
 904  FORMAT (10X,26('-'))
 905  FORMAT (10X,23('-'))
 906  FORMAT (10X,26('-'))
 907  FORMAT (10X,23('-'))
 908  FORMAT (10X,33('-'))

      CALL JEDEMA()
      END
