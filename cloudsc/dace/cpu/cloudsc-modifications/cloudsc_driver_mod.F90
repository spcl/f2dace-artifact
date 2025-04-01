! (C) Copyright 1988- ECMWF.
!
! This software is licensed under the terms of the Apache Licence Version 2.0
! which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
!
! In applying this licence, ECMWF does not waive the privileges and immunities
! granted to it by virtue of its status as an intergovernmental organisation
! nor does it submit to any jurisdiction.

MODULE CLOUDSC_DRIVER_MOD
  USE PARKIND1, ONLY: JPIM, JPIB, JPRB, JPRD
  USE YOMPHYDER, ONLY: STATE_TYPE
  USE YOECLDP, ONLY : NCLV
  USE CLOUDSC_MPI_MOD, ONLY: NUMPROC, IRANK
  USE TIMER_MOD, ONLY : PERFORMANCE_TIMER, GET_THREAD_NUM
use iso_c_binding
  IMPLICIT NONE

external cloudsc_driver_wrapper

CONTAINS

  SUBROUTINE CLOUDSC_DRIVER( &
     & NUMOMP, NPROMA, NLEV, NGPTOT, NGPTOTG, &
     & KFLDX, PTSPHY, &
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
     & PFPLSL,   PFPLSN,   PFHPSL,   PFHPSN, &
     & YDOMCST, YDOETHF, YDECLDP )
    ! Driver routine that performans the parallel NPROMA-blocking and
    ! invokes the CLOUDSC kernel

    USE YOECLDP  , ONLY : TECLDP
    USE YOMCST   , ONLY : TOMCST
    USE YOETHF   , ONLY : TOETHF

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

    TYPE(TOMCST)    :: YDOMCST
    TYPE(TOETHF)    :: YDOETHF
    TYPE(TECLDP)    :: YDECLDP

REAL(KIND=JPRB) :: tendency_loc_t(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
REAL(KIND=JPRB) :: tendency_loc_a(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1) )
REAL(KIND=JPRB) :: tendency_loc_cld(NPROMA,NLEV,5,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1) )
REAL(KIND=JPRB) :: tendency_loc_q(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
REAL(KIND=JPRB) :: tendency_tmp_t(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1) )
REAL(KIND=JPRB) :: tendency_tmp_a(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
REAL(KIND=JPRB) :: tendency_tmp_cld(NPROMA,NLEV,5,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
REAL(KIND=JPRB) :: tendency_tmp_q(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
REAL(KIND=JPRB) :: tendency_dummy(NPROMA,NLEV,(NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)  )
    NGPBLKS = (NGPTOT / NPROMA) + MIN(MOD(NGPTOT,NPROMA), 1)
1003 format(5x,'NUMPROC=',i0,', NUMOMP=',i0,', NGPTOTG=',i0,', NPROMA=',i0,', NGPBLKS=',i0)
    if (irank == 0) then
      write(0,1003) NUMPROC,NUMOMP,NGPTOTG,NPROMA,NGPBLKS
    end if

    ! Global timer for the parallel region
    CALL TIMER%START(NUMOMP)

    !$omp parallel default(shared) private(JKGLO,IBL,ICEND,TID) &
    !$omp& num_threads(NUMOMP)

    ! Local timer for each thread
    TID = GET_THREAD_NUM()
    CALL TIMER%THREAD_START(TID)

print *, "yikes"

DO JKGLO=1,NGPTOT,NPROMA
       IBL=(JKGLO-1)/NPROMA+1
       PCOVPTOT(:,:,IBL) = 0.0_JPRB
       TENDENCY_LOC(IBL)%cld(:,:,NCLV) = 0.0_JPRB
       tendency_tmp_cld(:,:,1:4,IBL)=TENDENCY_TMP(IBL)%cld(:,:,1:4)
       tendency_tmp_q(:,:,IBL)=TENDENCY_TMP(IBL)%q(:,:)
       tendency_tmp_a(:,:,IBL)=TENDENCY_TMP(IBL)%a(:,:)
       tendency_tmp_T(:,:,IBL)=TENDENCY_TMP(IBL)%T(:,:)
ENDDO

print *, "ngptot=", ngptot
print *, "ktype=", size(ktype, 1), size(ktype, 2)
print *, "plude=", size(plude, 1), size(plude, 2), size(plude, 3)
call cloudsc_driver_wrapper(ktype, ldcum, pa, pap, paph, pccn, pclv, pcovptot, pdyna, pdyni, pdynl, pfcqlng, pfcqnng, pfcqrng, pfcqsng, pfhpsl, pfhpsn, pfplsl, pfplsn, pfsqif, pfsqitur, pfsqlf, pfsqltur, pfsqrf, pfsqsf, phrlw, phrsw, picrit_aer, plcrit_aer, plsm, plu, plude, pmfd, pmfu, pnice, pq, prainfrac_toprfz, pre_ice, psnde, psupsat, pt, pvervel, pvfa, pvfi, pvfl, tendency_loc_a, tendency_loc_cld, tendency_loc_q, tendency_loc_t, tendency_tmp_a, tendency_tmp_cld, tendency_tmp_q, tendency_tmp_t, ydecldp, ydoethf, ydomcst, &
        &size(ktype, 1),size(ldcum, 1),size(pa, 1),size(pa, 2),size(pap, 1),size(pap, 2),size(paph, 1),size(paph, 2),size(pclv, 1),size(pclv, 2),size(pclv, 3),size(pcovptot, 1),size(pcovptot, 2),size(pfcqlng, 1),size(pfcqlng, 2),size(pfcqnng, 1),size(pfcqnng, 2),size(pfcqrng, 1),size(pfcqrng, 2),size(pfcqsng, 1),size(pfcqsng, 2),size(pfhpsl, 1),size(pfhpsl, 2),size(pfhpsn, 1),size(pfhpsn, 2),size(pfplsl, 1),size(pfplsl, 2),size(pfplsn, 1),size(pfplsn, 2),size(pfsqif, 1),size(pfsqif, 2),size(pfsqitur, 1),size(pfsqitur, 2),size(pfsqlf, 1),size(pfsqlf, 2),size(pfsqltur, 1),size(pfsqltur, 2),size(pfsqrf, 1),size(pfsqrf, 2),size(pfsqsf, 1),size(pfsqsf, 2),size(phrlw, 1),size(phrlw, 2),size(phrsw, 1),size(phrsw, 2),size(picrit_aer, 1),size(picrit_aer, 2),size(plsm, 1),size(plu, 1),size(plu, 2),size(plude, 1),size(plude, 2),size(pmfd, 1),size(pmfd, 2),size(pmfu, 1),size(pmfu, 2),size(pnice, 1),size(pnice, 2),size(pq, 1),size(pq, 2),size(prainfrac_toprfz, 1),size(pre_ice, 1),size(pre_ice, 2),size(psnde, 1),size(psnde, 2),size(psupsat, 1),size(psupsat, 2),size(pt, 1),size(pt, 2),size(pvervel, 1),size(pvervel, 2),size(pvfi, 1),size(pvfi, 2),size(pvfl, 1),size(pvfl, 2),size(tendency_loc_a, 1),size(tendency_loc_a, 2),size(tendency_loc_cld, 1),size(tendency_loc_cld, 2),size(tendency_loc_cld, 3),size(tendency_loc_q, 1),size(tendency_loc_q, 2),size(tendency_loc_t, 1),size(tendency_loc_t, 2),size(tendency_tmp_a, 1),size(tendency_tmp_a, 2),size(tendency_tmp_cld, 1),size(tendency_tmp_cld, 2),size(tendency_tmp_cld, 3),size(tendency_tmp_q, 1),size(tendency_tmp_q, 2),size(tendency_tmp_t, 1),size(tendency_tmp_t, 2),lbound(ktype, 2),lbound(ldcum, 2),lbound(pa, 3),lbound(pap, 3),lbound(paph, 3),lbound(pclv, 4),lbound(pcovptot, 1),lbound(pcovptot, 2),lbound(pcovptot, 3),lbound(pfcqlng, 3),lbound(pfcqnng, 3),lbound(pfcqrng, 3),lbound(pfcqsng, 3),lbound(pfhpsl, 3),lbound(pfhpsn, 3),lbound(pfplsl, 3),lbound(pfplsn, 3),lbound(pfsqif, 3),lbound(pfsqitur, 3),lbound(pfsqlf, 3),lbound(pfsqltur, 3),lbound(pfsqrf, 3),lbound(pfsqsf, 3),lbound(phrlw, 3),lbound(phrsw, 3),lbound(picrit_aer, 3),lbound(plsm, 2),lbound(plu, 3),lbound(plude, 3),lbound(pmfd, 3),lbound(pmfu, 3),lbound(pnice, 3),lbound(pq, 3),lbound(prainfrac_toprfz, 2),lbound(pre_ice, 3),lbound(psnde, 3),lbound(psupsat, 3),lbound(pt, 3),lbound(pvervel, 3),lbound(pvfi, 3),lbound(pvfl, 3),lbound(tendency_loc_a, 1),lbound(tendency_loc_cld, 1),lbound(tendency_loc_cld, 2),lbound(tendency_loc_cld, 3),lbound(tendency_loc_cld, 4),lbound(tendency_loc_q, 1),lbound(tendency_loc_t, 1),lbound(tendency_tmp_a, 1),lbound(tendency_tmp_cld, 1),lbound(tendency_tmp_q, 1),lbound(tendency_tmp_t, 1), &
        &kfldx, ngptot, ngptotg, nlev, nproma, numomp, ptsphy)

DO JKGLO=1,NGPTOT,NPROMA
       IBL=(JKGLO-1)/NPROMA+1
       TENDENCY_LOC(IBL)%cld(:,:,1:4)=tendency_loc_cld(:,:,1:4,IBL)
       TENDENCY_LOC(IBL)%q(:,:)=tendency_loc_q(:,:,IBL)
       TENDENCY_LOC(IBL)%a(:,:)=tendency_loc_a(:,:,IBL)
       TENDENCY_LOC(IBL)%T(:,:)=tendency_loc_T(:,:,IBL)

ENDDO

      CALL TIMER%THREAD_END(TID)

      !$omp end parallel

      CALL TIMER%END()

      CALL TIMER%PRINT_PERFORMANCE(NPROMA, NGPBLKS, NGPTOT)
    
  END SUBROUTINE CLOUDSC_DRIVER

END MODULE CLOUDSC_DRIVER_MOD
