! (C) Copyright 1988- ECMWF.
!
! This software is licensed under the terms of the Apache Licence Version 2.0
! which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
!
! In applying this licence, ECMWF does not waive the privileges and immunities
! granted to it by virtue of its status as an intergovernmental organisation
! nor does it submit to any jurisdiction.

MODULE CLOUDSC_DRIVER_MOD
  USE PARKIND1 , ONLY : JPIM, JPRB, JPIA, JPIB, JPIS, JPIT, JPLM, JPRD, JPRM, JPRS, JPRT
  !USE YOMHOOK  , ONLY : LHOOK, DR_HOOK
  USE YOMCST   , ONLY : RG, RD, RCPD, RETV, RLVTT, RLSTT, RLMLT, RTT, RV  
  USE YOETHF   , ONLY : R2ES, R3LES, R3IES, R4LES, R4IES, R5LES, R5IES, &
 & R5ALVCP, R5ALSCP, RALVDCP, RALSDCP, RALFDCP, RTWAT, RTICE, RTICECU, &
 & RTWAT_RTICE_R, RTWAT_RTICECU_R, RKOOP1, RKOOP2
  USE YOECLDP  , ONLY : YRECLDP, NCLDQV, NCLDQL, NCLDQR, NCLDQI, NCLDQS, NCLV
  USE YOMPHYDER ,ONLY : STATE_TYPE
  USE CLOUDSC_MPI_MOD, ONLY: NUMPROC, IRANK
  USE TIMER_MOD, ONLY : PERFORMANCE_TIMER, GET_THREAD_NUM
  USE EC_PMON_MOD, ONLY: EC_PMON

  IMPLICIT NONE

EXTERNAL cloudsc2
CONTAINS

  SUBROUTINE CLOUDSC_DRIVER( &
     & NUMOMP, NPROMA, NLEV, NGPTOT, NGPTOTG, KFLDX, PTSPHY, &
     & PT, PQ, TENDENCY_CML, TENDENCY_TMP, TENDENCY_LOC, &
     & PVFA, PVFL, PVFI, PDYNA, PDYNL, PDYNI, &
     & PHRSW,    PHRLW, &
     & PVERVEL,  PAP,      PAPH, &
     & PLSM,     LDCUM,    KTYPE, &
     & PLU,      PLUDE,    PSNDE,    PMFU,     PMFD, &
     & PA,       PCLV,     PSUPSAT,&
     & PLCRIT_AER,PICRIT_AER, PRE_ICE, &
     & PCCN,     PNICE,&
     & PCOVPTOT, PRAINFRAC_TOPRFZ, &
     & PFSQLF,   PFSQIF ,  PFCQNNG,  PFCQLNG, &
     & PFSQRF,   PFSQSF ,  PFCQRNG,  PFCQSNG, &
     & PFSQLTUR, PFSQITUR, &
     & PFPLSL,   PFPLSN,   PFHPSL,   PFHPSN &
     & )
    ! Driver routine that performans the parallel NPROMA-blocking and
    ! invokes the CLOUDSC kernel

    INTEGER(KIND=JPIM), INTENT(IN)    :: NUMOMP, NPROMA, NLEV, NGPTOT, NGPTOTG
    INTEGER(KIND=JPIM), INTENT(IN)    :: KFLDX
    REAL(KIND=JPRB),    INTENT(IN)    :: PTSPHY       ! Physics timestep
    REAL(KIND=JPRB),    INTENT(IN)    :: PT(:,:,:)    ! T at start of callpar
    REAL(KIND=JPRB),    INTENT(IN)    :: PQ(:,:,:)    ! Q at start of callpar
    TYPE(STATE_TYPE),   INTENT(IN)    :: TENDENCY_CML(:) ! cumulative tendency used for final output
    TYPE(STATE_TYPE),   INTENT(IN)    :: TENDENCY_TMP(:) ! cumulative tendency used as input
    TYPE(STATE_TYPE),   INTENT(OUT)   :: TENDENCY_LOC(:) ! local tendency from cloud scheme
    REAL(KIND=JPRB),    INTENT(IN)    :: PVFA(:,:,:)  ! CC from VDF scheme
    REAL(KIND=JPRB),    INTENT(IN)    :: PVFL(:,:,:)  ! Liq from VDF scheme
    REAL(KIND=JPRB),    INTENT(IN)    :: PVFI(:,:,:)  ! Ice from VDF scheme
    REAL(KIND=JPRB),    INTENT(IN)    :: PDYNA(:,:,:) ! CC from Dynamics
    REAL(KIND=JPRB),    INTENT(IN)    :: PDYNL(:,:,:) ! Liq from Dynamics
    REAL(KIND=JPRB),    INTENT(IN)    :: PDYNI(:,:,:) ! Liq from Dynamics
    REAL(KIND=JPRB),    INTENT(IN)    :: PHRSW(:,:,:) ! Short-wave heating rate
    REAL(KIND=JPRB),    INTENT(IN)    :: PHRLW(:,:,:) ! Long-wave heating rate
    REAL(KIND=JPRB),    INTENT(IN)    :: PVERVEL(:,:,:) !Vertical velocity
    REAL(KIND=JPRB),    INTENT(IN)    :: PAP(:,:,:)   ! Pressure on full levels
    REAL(KIND=JPRB),    INTENT(IN)    :: PAPH(:,:,:)  ! Pressure on half levels
    REAL(KIND=JPRB),    INTENT(IN)    :: PLSM(:,:)    ! Land fraction (0-1)
    LOGICAL        ,    INTENT(IN)    :: LDCUM(:,:)   ! Convection active
    INTEGER(KIND=JPIM), INTENT(IN)    :: KTYPE(:,:)   ! Convection type 0,1,2
    REAL(KIND=JPRB),    INTENT(IN)    :: PLU(:,:,:)   ! Conv. condensate
    REAL(KIND=JPRB),    INTENT(INOUT) :: PLUDE(:,:,:) ! Conv. detrained water
    REAL(KIND=JPRB),    INTENT(IN)    :: PSNDE(:,:,:) ! Conv. detrained snow
    REAL(KIND=JPRB),    INTENT(IN)    :: PMFU(:,:,:)  ! Conv. mass flux up
    REAL(KIND=JPRB),    INTENT(IN)    :: PMFD(:,:,:)  ! Conv. mass flux down
    REAL(KIND=JPRB),    INTENT(IN)    :: PA(:,:,:)    ! Original Cloud fraction (t)
    REAL(KIND=JPRB),    INTENT(IN)    :: PCLV(:,:,:,:) 
    REAL(KIND=JPRB),    INTENT(IN)    :: PSUPSAT(:,:,:)
    REAL(KIND=JPRB),    INTENT(IN)    :: PLCRIT_AER(:,:,:) 
    REAL(KIND=JPRB),    INTENT(IN)    :: PICRIT_AER(:,:,:) 
    REAL(KIND=JPRB),    INTENT(IN)    :: PRE_ICE(:,:,:) 
    REAL(KIND=JPRB),    INTENT(IN)    :: PCCN(:,:,:)     ! liquid cloud condensation nuclei
    REAL(KIND=JPRB),    INTENT(IN)    :: PNICE(:,:,:)    ! ice number concentration (cf. CCN)

    REAL(KIND=JPRB),    INTENT(INOUT) :: PCOVPTOT(:,:,:) ! Precip fraction
    REAL(KIND=JPRB),    INTENT(OUT)   :: PRAINFRAC_TOPRFZ(:,:) 
    ! Flux diagnostics for DDH budget
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFSQLF(:,:,:)  ! Flux of liquid
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFSQIF(:,:,:)  ! Flux of ice
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFCQLNG(:,:,:) ! -ve corr for liq
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFCQNNG(:,:,:) ! -ve corr for ice
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFSQRF(:,:,:)  ! Flux diagnostics
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFSQSF(:,:,:)  !    for DDH, generic
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFCQRNG(:,:,:) ! rain
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFCQSNG(:,:,:) ! snow
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFSQLTUR(:,:,:) ! liquid flux due to VDF
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFSQITUR(:,:,:) ! ice flux due to VDF
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFPLSL(:,:,:) ! liq+rain sedim flux
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFPLSN(:,:,:) ! ice+snow sedim flux
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFHPSL(:,:,:) ! Enthalpy flux for liq
    REAL(KIND=JPRB),    INTENT(OUT)   :: PFHPSN(:,:,:) ! Enthalp flux for ice

    INTEGER(KIND=JPIM) :: JKGLO,IBL,ICEND,NGPBLKS

    TYPE(PERFORMANCE_TIMER) :: TIMER
    INTEGER(KIND=JPIM) :: TID ! thread id from 0 .. NUMOMP - 1
    INTEGER(KIND=JPIB) :: ENERGY, POWER, POWER_TOTAL, POWER_MAX, POWER_COUNT
    LOGICAL            :: LEC_PMON = .FALSE.
    CHARACTER(LEN=1)   :: CLEC_PMON

INTEGER(KIND=JPIM)::print1

INTEGER :: print,ind1,ind2
LOGICAL :: LDMAINCALL
LOGICAL :: LDSLPHY
REAL(KIND=JPRB) :: PEXTRA(10,10,10)
REAL(KIND=JPRB) :: tendency_cml_T(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1) )
REAL(KIND=JPRB) :: tendency_cml_a(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1) )
REAL(KIND=JPRB) :: tendency_cml_cld(NPROMA,NLEV,5,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
REAL(KIND=JPRB) :: tendency_cml_q(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1) )
REAL(KIND=JPRB) :: tendency_loc_T(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
REAL(KIND=JPRB) :: tendency_loc_a(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1) )
REAL(KIND=JPRB) :: tendency_loc_cld(NPROMA,NLEV,5,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1) )
REAL(KIND=JPRB) :: tendency_loc_q(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
REAL(KIND=JPRB) :: tendency_tmp_T(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1) )
REAL(KIND=JPRB) :: tendency_tmp_a(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
REAL(KIND=JPRB) :: tendency_tmp_cld(NPROMA,NLEV,5,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
REAL(KIND=JPRB) :: tendency_tmp_q(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
REAL(KIND=JPRB) :: tendency_dummy(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )

ASSOCIATE(LAERICEAUTO=>YRECLDP%LAERICEAUTO, LAERICESED=>YRECLDP%LAERICESED, &
 & LAERLIQAUTOLSP=>YRECLDP%LAERLIQAUTOLSP, LAERLIQCOLL=>YRECLDP%LAERLIQCOLL, &
 & LCLDBUDGET=>YRECLDP%LCLDBUDGET, NCLDTOP=>YRECLDP%NCLDTOP, &
 & NSSOPT=>YRECLDP%NSSOPT, RAMID=>YRECLDP%RAMID, RAMIN=>YRECLDP%RAMIN, &
 & RCCN=>YRECLDP%RCCN, RCLCRIT_LAND=>YRECLDP%RCLCRIT_LAND, &
 & RCLCRIT_SEA=>YRECLDP%RCLCRIT_SEA, RCLDIFF=>YRECLDP%RCLDIFF, &
 & RCLDIFF_CONVI=>YRECLDP%RCLDIFF_CONVI, RCLDTOPCF=>YRECLDP%RCLDTOPCF, &
 & RCL_APB1=>YRECLDP%RCL_APB1, RCL_APB2=>YRECLDP%RCL_APB2, &
 & RCL_APB3=>YRECLDP%RCL_APB3, RCL_CDENOM1=>YRECLDP%RCL_CDENOM1, &
 & RCL_CDENOM2=>YRECLDP%RCL_CDENOM2, RCL_CDENOM3=>YRECLDP%RCL_CDENOM3, &
 & RCL_CONST1I=>YRECLDP%RCL_CONST1I, RCL_CONST1R=>YRECLDP%RCL_CONST1R, &
 & RCL_CONST1S=>YRECLDP%RCL_CONST1S, RCL_CONST2I=>YRECLDP%RCL_CONST2I, &
 & RCL_CONST2R=>YRECLDP%RCL_CONST2R, RCL_CONST2S=>YRECLDP%RCL_CONST2S, &
 & RCL_CONST3I=>YRECLDP%RCL_CONST3I, RCL_CONST3R=>YRECLDP%RCL_CONST3R, &
 & RCL_CONST3S=>YRECLDP%RCL_CONST3S, RCL_CONST4I=>YRECLDP%RCL_CONST4I, &
 & RCL_CONST4R=>YRECLDP%RCL_CONST4R, RCL_CONST4S=>YRECLDP%RCL_CONST4S, &
 & RCL_CONST5I=>YRECLDP%RCL_CONST5I, RCL_CONST5R=>YRECLDP%RCL_CONST5R, &
 & RCL_CONST5S=>YRECLDP%RCL_CONST5S, RCL_CONST6I=>YRECLDP%RCL_CONST6I, &
 & RCL_CONST6R=>YRECLDP%RCL_CONST6R, RCL_CONST6S=>YRECLDP%RCL_CONST6S, &
 & RCL_CONST7S=>YRECLDP%RCL_CONST7S, RCL_CONST8S=>YRECLDP%RCL_CONST8S, &
 & RCL_FAC1=>YRECLDP%RCL_FAC1, RCL_FAC2=>YRECLDP%RCL_FAC2, &
 & RCL_FZRAB=>YRECLDP%RCL_FZRAB, RCL_KA273=>YRECLDP%RCL_KA273, &
 & RCL_KKAAC=>YRECLDP%RCL_KKAAC, RCL_KKAAU=>YRECLDP%RCL_KKAAU, &
 & RCL_KKBAC=>YRECLDP%RCL_KKBAC, RCL_KKBAUN=>YRECLDP%RCL_KKBAUN, &
 & RCL_KKBAUQ=>YRECLDP%RCL_KKBAUQ, &
 & RCL_KK_CLOUD_NUM_LAND=>YRECLDP%RCL_KK_CLOUD_NUM_LAND, &
 & RCL_KK_CLOUD_NUM_SEA=>YRECLDP%RCL_KK_CLOUD_NUM_SEA, RCL_X3I=>YRECLDP%RCL_X3I, &
 & RCOVPMIN=>YRECLDP%RCOVPMIN, RDENSREF=>YRECLDP%RDENSREF, &
 & RDEPLIQREFDEPTH=>YRECLDP%RDEPLIQREFDEPTH, &
 & RDEPLIQREFRATE=>YRECLDP%RDEPLIQREFRATE, RICEHI1=>YRECLDP%RICEHI1, &
 & RICEHI2=>YRECLDP%RICEHI2, RICEINIT=>YRECLDP%RICEINIT, RKCONV=>YRECLDP%RKCONV, &
 & RKOOPTAU=>YRECLDP%RKOOPTAU, RLCRITSNOW=>YRECLDP%RLCRITSNOW, &
 & RLMIN=>YRECLDP%RLMIN, RNICE=>YRECLDP%RNICE, RPECONS=>YRECLDP%RPECONS, &
 & RPRC1=>YRECLDP%RPRC1, RPRECRHMAX=>YRECLDP%RPRECRHMAX, &
 & RSNOWLIN1=>YRECLDP%RSNOWLIN1, RSNOWLIN2=>YRECLDP%RSNOWLIN2, &
 & RTAUMEL=>YRECLDP%RTAUMEL, RTHOMO=>YRECLDP%RTHOMO, RVICE=>YRECLDP%RVICE, &
 & RVRAIN=>YRECLDP%RVRAIN, RVRFACTOR=>YRECLDP%RVRFACTOR, &
 & RVSNOW=>YRECLDP%RVSNOW)
print=1
    CALL GET_ENVIRONMENT_VARIABLE('EC_PMON', CLEC_PMON)
    IF (CLEC_PMON == '1') LEC_PMON = .TRUE.

    POWER_MAX = 0_JPIB
    POWER_TOTAL = 0_JPIB
    POWER_COUNT = 0_JPIB

    NGPBLKS = (NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)
1003 format(5x,'NUMPROC=',i0,', NUMOMP=',i0,', NGPTOTG=',i0,', NPROMA=',i0,', NGPBLKS=',i0)
    if (irank == 0) then
      write(0,1003) NUMPROC,NUMOMP,NGPTOTG,NPROMA,NGPBLKS
    end if


DO JKGLO=1,NGPTOT,NPROMA
       IBL=(JKGLO-1)/NPROMA+1
       PCOVPTOT(:,:,IBL) = 0.0_JPRB
       TENDENCY_LOC(IBL)%cld(:,:,NCLV) = 0.0_JPRB
       tendency_cml_cld(:,:,1:4,IBL)=TENDENCY_CML(IBL)%cld(:,:,1:4)
       tendency_tmp_cld(:,:,1:4,IBL)=TENDENCY_TMP(IBL)%cld(:,:,1:4)   
       tendency_cml_q(:,:,IBL)=TENDENCY_CML(IBL)%q(:,:)
       tendency_cml_a(:,:,IBL)=TENDENCY_CML(IBL)%a(:,:)
       tendency_cml_T(:,:,IBL)=TENDENCY_CML(IBL)%T(:,:)
       tendency_tmp_q(:,:,IBL)=TENDENCY_TMP(IBL)%q(:,:)
       tendency_tmp_a(:,:,IBL)=TENDENCY_TMP(IBL)%a(:,:)
       tendency_tmp_T(:,:,IBL)=TENDENCY_TMP(IBL)%T(:,:) 	
ENDDO    
!write (*,*) "after silly copies some init outside"
    call cloudsc2(&
& KTYPE,&
& LDCUM,&
& PAPH,&
& PAP,&
& PA,&
& PCCN,&
& PCLV,&
& PCOVPTOT,&
& PDYNA,&
& PDYNI,&
& PDYNL,&
& PEXTRA,&
& PFCQLNG,&
& PFCQNNG,&
& PFCQRNG,&
& PFCQSNG,&
& PFHPSL,&
& PFHPSN,&
& PFPLSL,&
& PFPLSN,&
& PFSQIF,&
& PFSQITUR,&
& PFSQLF,&
& PFSQLTUR,&
& PFSQRF,&
& PFSQSF,&
& PHRLW,&
& PHRSW,&
& PICRIT_AER,&
& PLCRIT_AER,&
& PLSM,&
& PLUDE,&
& PLU,&
& PMFD,&
& PMFU,&
& PNICE,&
& PQ,&
& PRAINFRAC_TOPRFZ,&
& PRE_ICE,&
& PSNDE,&
& PSUPSAT,&
& PT,&
& PVERVEL,&
& PVFA,&
& PVFI,&
& PVFL,&
& tendency_cml_T,&
& tendency_cml_a,&
& tendency_cml_cld,&
& tendency_dummy,&
& tendency_cml_q,&
& tendency_dummy,&
& tendency_dummy,&
& tendency_loc_T,&
& tendency_loc_a,&
& tendency_loc_cld,&
& tendency_dummy,&
& tendency_loc_q,&
& tendency_dummy,&
& tendency_dummy,&
& tendency_tmp_T,&
& tendency_tmp_a,&
& tendency_tmp_cld,&
& tendency_dummy,&
& tendency_tmp_q,&
& tendency_dummy,&
& tendency_dummy,&
& JPIA,&
& JPIB,&
& JPIM,&
& JPIS,&
& JPIT,&
& JPLM,&
& JPRB,&
& JPRD,&
& JPRM,&
& JPRS,&
& JPRT,&
& ICEND,&
& KFLDX,&
& 1,&
& NLEV,&
& NPROMA,&
& NGPBLKS,&
& NCLDQI,&
& NCLDQL,&
& NCLDQR,&
& NCLDQS,&
& NCLDQV,&
& NCLV,&
& NPROMA,&
& 1,&
& LAERICEAUTO,&
& LAERICESED,&
& LAERLIQAUTOLSP,&
& LAERLIQCOLL,&
& LDMAINCALL,&
& LDSLPHY,&
& NCLDTOP,&
& NGPBLKS,&
& NGPTOTG,&
& NGPTOT,&
& NSSOPT,&
& NUMOMP,&
& PTSPHY,&
& R2ES,&
& R3IES,&
& R3LES,&
& R4IES,&
& R4LES,&
& R5ALSCP,&
& R5ALVCP,&
& R5IES,&
& R5LES,&
& RALFDCP,&
& RALSDCP,&
& RALVDCP,&
& RAMID,&
& RAMIN,&
& RCCN,&
& RCLCRIT_LAND,&
& RCLCRIT_SEA,&
& RCLDIFF,&
& RCLDIFF_CONVI,&
& RCLDTOPCF,&
& RCL_APB1,&
& RCL_APB2,&
& RCL_APB3,&
& RCL_CDENOM1,&
& RCL_CDENOM2,&
& RCL_CDENOM3,&
& RCL_CONST1I,&
& RCL_CONST1R,&
& RCL_CONST1S,&
& RCL_CONST2I,&
& RCL_CONST2R,&
& RCL_CONST2S,&
& RCL_CONST3I,&
& RCL_CONST3R,&
& RCL_CONST3S,&
& RCL_CONST4I,&
& RCL_CONST4R,&
& RCL_CONST4S,&
& RCL_CONST5I,&
& RCL_CONST5R,&
& RCL_CONST5S,&
& RCL_CONST6I,&
& RCL_CONST6R,&
& RCL_CONST6S,&
& RCL_CONST7S,&
& RCL_CONST8S,&
& RCL_FAC1,&
& RCL_FAC2,&
& RCL_FZRAB,&
& RCL_KA273,&
& RCL_KKAac,&
& RCL_KKAau,&
& RCL_KKBac,&
& RCL_KKBaun,&
& RCL_KKBauq,&
& RCL_KK_CLOUD_NUM_LAND,&
& RCL_KK_CLOUD_NUM_SEA,&
& RCOVPMIN,&
& RCPD,&
& RDENSREF,&
& RDEPLIQREFDEPTH,&
& RDEPLIQREFRATE,&
& RD,&
& RETV,&
& RG,&
& RICEINIT,&
& RKCONV,&
& RKOOP1,&
& RKOOP2,&
& RKOOPTAU,&
& RLCRITSNOW,&
& RLMIN,&
& RLMLT,&
& RLSTT,&
& RLVTT,&
& RNICE,&
& RPECONS,&
& RPRC1,&
& RPRECRHMAX,&
& RSNOWLIN1,&
& RSNOWLIN2,&
& RTAUMEL,&
& RTHOMO,&
& RTICECU,&
& RTICE,&
& RTT,&
& RTWAT,&
& RTWAT_RTICECU_R,&
& RTWAT_RTICE_R,&
& RVICE,&
& RVRAIN,&
& RVRFACTOR,&
& RVSNOW,&
& RV,print)
!write (*,*) "finished call"
DO JKGLO=1,NGPTOT,NPROMA
       IBL=(JKGLO-1)/NPROMA+1

       TENDENCY_LOC(IBL)%cld(:,:,1:4)=tendency_loc_cld(:,:,1:4,IBL)
       TENDENCY_LOC(IBL)%q(:,:)=tendency_loc_q(:,:,IBL)
       TENDENCY_LOC(IBL)%a(:,:)=tendency_loc_a(:,:,IBL)
       TENDENCY_LOC(IBL)%T(:,:)=tendency_loc_T(:,:,IBL)
       
ENDDO  
!tendency_loc%T(:,:)=tendency_loc_T(:,:)
!tendency_loc%a(:,:)=tendency_loc_a(:,:)
!tendency_loc%cld(:,:,1:4)=tendency_loc_cld(:,:,1:4)
!tendency_loc%o3(:,:)=tendency_loc_o3(:,:)
!tendency_loc%q(:,:)=tendency_loc_q(:,:)
!tendency_loc%u(:,:)=tendency_loc_u(:,:)
!tendency_loc%v(:,:)=tendency_loc_v(:,:)

!===============================================================================
END ASSOCIATE

    ! Global timer for the parallel region
    CALL TIMER%START(NUMOMP)

    
  END SUBROUTINE CLOUDSC_DRIVER

END MODULE CLOUDSC_DRIVER_MOD

