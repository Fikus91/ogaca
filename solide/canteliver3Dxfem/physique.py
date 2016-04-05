#fichier regroupant les donnees physique du calcul

#################################################
#Materieau
#################################################
#materiaux acier

#module d young
para['MAE']=210E9
#coef de poissons
para['MANU']=.3

#densite il vaut mieu la laisser a 1
para['RHO']=1.
para['Lambda']=para['MANU']/((1.+para['MANU'])*(1.-2.*para['MANU']));
para['Mu']=1/(2.*(1.+para['MANU']));


#MA=DEFI_MATERIAU (ELAS=_F(E=para['MAE'],NU=para['MANU'],RHO=para['RHO'],));
#je ne suis pas sur de l utiliter de ceci
#CHMATE=AFFE_MATERIAU(MAILLAGE=MAIL,AFFE=_F(TOUT='OUI',MATER=MA),)



########################################################################
##Definition des charges
########################################################################
MAIL=DEFI_GROUP(reuse=MAIL,MAILLAGE=MAIL,CREA_GROUP_NO=_F(NOM="GRNA",GROUP_MA='Group_2'));
para['GRN_APPUIS']='GRNA';

CHARJ1=AFFE_CHAR_MECA(MODELE=MODEMEV,
	DDL_IMPO=_F(DX=0.0,DY=0.0,DZ=0.0,GROUP_MA='Group_2'),
	FORCE_FACE=_F(GROUP_MA='Group_3',FX=1.,),);
CHARJ2=AFFE_CHAR_MECA(MODELE=MODEMEV,
	DDL_IMPO=_F(DX=0.0,DY=0.0,DZ=0.0,GROUP_MA='Group_2'),
	FORCE_FACE=_F(GROUP_MA='Group_3',FY=0.01,),);

