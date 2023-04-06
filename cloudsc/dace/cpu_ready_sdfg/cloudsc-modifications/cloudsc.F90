! (C) Copyright 1988- ECMWF.
!
! This software is licensed under the terms of the Apache Licence Version 2.0
! which can be obtained at http://www.apache.org/licenses/LICENSE-2.0.
!
! In applying this licence, ECMWF does not waive the privileges and immunities
! granted to it by virtue of its status as an intergovernmental organisation
! nor does it submit to any jurisdiction.

SUBROUTINE CLOUDSC &
 !---input
 & (KIDIA,    KFDIA,    KLON,    KLEV,&
 & PTSPHY,&
 & PT, PQ, tendency_cml,tendency_tmp,tendency_loc, &
 & PVFA, PVFL, PVFI, PDYNA, PDYNL, PDYNI, &
 & PHRSW,    PHRLW,&
 & PVERVEL,  PAP,      PAPH,&
 & PLSM,     LDCUM,    KTYPE, &
 & PLU,      PLUDE,    PSNDE,    PMFU,     PMFD,&
 !---prognostic fields
 & PA,&
 & PCLV,  &
 & PSUPSAT,&
!-- arrays for aerosol-cloud interactions
!!! & PQAER,    KAER, &
 & PLCRIT_AER,PICRIT_AER,&
 & PRE_ICE,&
 & PCCN,     PNICE,&
 !---diagnostic output
 & PCOVPTOT, PRAINFRAC_TOPRFZ,&
 !---resulting fluxes
 & PFSQLF,   PFSQIF ,  PFCQNNG,  PFCQLNG,&
 & PFSQRF,   PFSQSF ,  PFCQRNG,  PFCQSNG,&
 & PFSQLTUR, PFSQITUR , &
 & PFPLSL,   PFPLSN,   PFHPSL,   PFHPSN,&
 & KFLDX)

!===============================================================================
!**** *CLOUDSC* -  ROUTINE FOR PARAMATERIZATION OF CLOUD PROCESSES
!                  FOR PROGNOSTIC CLOUD SCHEME
!!
!     M.Tiedtke, C.Jakob, A.Tompkins, R.Forbes     (E.C.M.W.F.)
!!
!     PURPOSE
!     -------
!          THIS ROUTINE UPDATES THE CONV/STRAT CLOUD FIELDS.
!          THE FOLLOWING PROCESSES ARE CONSIDERED:
!        - Detrainment of cloud water from convective updrafts
!        - Evaporation/condensation of cloud water in connection
!           with heating/cooling such as by subsidence/ascent
!        - Erosion of clouds by turbulent mixing of cloud air
!           with unsaturated environmental air
!        - Deposition onto ice when liquid water present (Bergeron-Findeison) 
!        - Conversion of cloud water into rain (collision-coalescence)
!        - Conversion of cloud ice to snow (aggregation)
!        - Sedimentation of rain, snow and ice
!        - Evaporation of rain and snow
!        - Melting of snow and ice
!        - Freezing of liquid and rain
!        Note: Turbulent transports of s,q,u,v at cloud tops due to
!           buoyancy fluxes and lw radiative cooling are treated in 
!           the VDF scheme
!!
!     INTERFACE.
!     ----------
!          *CLOUDSC* IS CALLED FROM *CALLPAR*
!     THE ROUTINE TAKES ITS INPUT FROM THE LONG-TERM STORAGE:
!     T,Q,L,PHI AND DETRAINMENT OF CLOUD WATER FROM THE
!     CONVECTIVE CLOUDS (MASSFLUX CONVECTION SCHEME), BOUNDARY
!     LAYER TURBULENT FLUXES OF HEAT AND MOISTURE, RADIATIVE FLUXES,
!     OMEGA.
!     IT RETURNS ITS OUTPUT TO:
!      1.MODIFIED TENDENCIES OF MODEL VARIABLES T AND Q
!        AS WELL AS CLOUD VARIABLES L AND C
!      2.GENERATES PRECIPITATION FLUXES FROM STRATIFORM CLOUDS
!!
!     EXTERNALS.
!     ----------
!          NONE
!!
!     MODIFICATIONS.
!     -------------
!      M. TIEDTKE    E.C.M.W.F.     8/1988, 2/1990
!     CH. JAKOB      E.C.M.W.F.     2/1994 IMPLEMENTATION INTO IFS
!     A.TOMPKINS     E.C.M.W.F.     2002   NEW NUMERICS
!        01-05-22 : D.Salmond   Safety modifications
!        02-05-29 : D.Salmond   Optimisation
!        03-01-13 : J.Hague     MASS Vector Functions  J.Hague
!        03-10-01 : M.Hamrud    Cleaning
!        04-12-14 : A.Tompkins  New implicit solver and physics changes
!        04-12-03 : A.Tompkins & M.Ko"hler  moist PBL
!     G.Mozdzynski  09-Jan-2006  EXP security fix
!        19-01-09 : P.Bechtold  Changed increased RCLDIFF value for KTYPE=2
!        07-07-10 : A.Tompkins/R.Forbes  4-Phase flexible microphysics
!        01-03-11 : R.Forbes    Mixed phase changes and tidy up
!        01-10-11 : R.Forbes    Melt ice to rain, allow rain to freeze
!        01-10-11 : R.Forbes    Limit supersat to avoid excessive values
!        31-10-11 : M.Ahlgrimm  Add rain, snow and PEXTRA to DDH output
!        17-02-12 : F.Vana      Simplified/optimized LU factorization
!        18-05-12 : F.Vana      Cleaning + better support of sequential physics
!        N.Semane+P.Bechtold     04-10-2012 Add RVRFACTOR factor for small planet
!        01-02-13 : R.Forbes    New params of autoconv/acc,rain evap,snow riming
!        15-03-13 : F. Vana     New dataflow + more tendencies from the first call
!        K. Yessad (July 2014): Move some variables.
!        F. Vana  05-Mar-2015  Support for single precision
!        15-01-15 : R.Forbes    Added new options for snow evap & ice deposition
!        10-01-15 : R.Forbes    New physics for rain freezing
!        23-10-14 : P. Bechtold remove zeroing of convection arrays
!
!     SWITCHES.
!     --------
!!
!     MODEL PARAMETERS
!     ----------------
!     RCLDIFF:    PARAMETER FOR EROSION OF CLOUDS
!     RCLCRIT_SEA:  THRESHOLD VALUE FOR RAIN AUTOCONVERSION OVER SEA
!     RCLCRIT_LAND: THRESHOLD VALUE FOR RAIN AUTOCONVERSION OVER LAND
!     RLCRITSNOW: THRESHOLD VALUE FOR SNOW AUTOCONVERSION
!     RKCONV:     PARAMETER FOR AUTOCONVERSION OF CLOUDS (KESSLER)
!     RCLDMAX:    MAXIMUM POSSIBLE CLW CONTENT (MASON,1971)
!!
!     REFERENCES.
!     ----------
!     TIEDTKE MWR 1993
!     JAKOB PhD 2000
!     GREGORY ET AL. QJRMS 2000
!     TOMPKINS ET AL. QJRMS 2007
!!
!===============================================================================

USE PARKIND1 , ONLY : JPIM, JPRB, JPIA, JPIB, JPIS, JPIT, JPLM, JPRD, JPRM, JPRS, JPRT
!USE YOMHOOK  , ONLY : LHOOK, DR_HOOK
USE YOMCST   , ONLY : RG, RD, RCPD, RETV, RLVTT, RLSTT, RLMLT, RTT, RV  
USE YOETHF   , ONLY : R2ES, R3LES, R3IES, R4LES, R4IES, R5LES, R5IES, &
 & R5ALVCP, R5ALSCP, RALVDCP, RALSDCP, RALFDCP, RTWAT, RTICE, RTICECU, &
 & RTWAT_RTICE_R, RTWAT_RTICECU_R, RKOOP1, RKOOP2
USE YOECLDP  , ONLY : YRECLDP, NCLDQV, NCLDQL, NCLDQR, NCLDQI, NCLDQS, NCLV
USE YOMPHYDER ,ONLY : STATE_TYPE

IMPLICIT NONE

EXTERNAL cloudsc2
!-------------------------------------------------------------------------------
!                 Declare input/output arguments
!-------------------------------------------------------------------------------
 
! PLCRIT_AER : critical liquid mmr for rain autoconversion process
! PICRIT_AER : critical liquid mmr for snow autoconversion process
! PRE_LIQ : liq Re
! PRE_ICE : ice Re
! PCCN    : liquid cloud condensation nuclei
! PNICE   : ice number concentration (cf. CCN)

REAL(KIND=JPRB)   ,INTENT(IN)    :: PLCRIT_AER(KLON,KLEV) 
REAL(KIND=JPRB)   ,INTENT(IN)    :: PICRIT_AER(KLON,KLEV) 
REAL(KIND=JPRB)   ,INTENT(IN)    :: PRE_ICE(KLON,KLEV) 
REAL(KIND=JPRB)   ,INTENT(IN)    :: PCCN(KLON,KLEV)     ! liquid cloud condensation nuclei
REAL(KIND=JPRB)   ,INTENT(IN)    :: PNICE(KLON,KLEV)    ! ice number concentration (cf. CCN)

INTEGER(KIND=JPIM),INTENT(IN)    :: KLON             ! Number of grid points
INTEGER(KIND=JPIM),INTENT(IN)    :: KLEV             ! Number of levels
INTEGER(KIND=JPIM),INTENT(IN)    :: KIDIA 
INTEGER(KIND=JPIM),INTENT(IN)    :: KFDIA 
REAL(KIND=JPRB)   ,INTENT(IN)    :: PTSPHY            ! Physics timestep
REAL(KIND=JPRB)   ,INTENT(IN)    :: PT(KLON,KLEV)    ! T at start of callpar
REAL(KIND=JPRB)   ,INTENT(IN)    :: PQ(KLON,KLEV)    ! Q at start of callpar
TYPE (STATE_TYPE) , INTENT (IN)  :: tendency_cml   ! cumulative tendency used for final output
TYPE (STATE_TYPE) , INTENT (IN)  :: tendency_tmp   ! cumulative tendency used as input
TYPE (STATE_TYPE) , INTENT (OUT) :: tendency_loc   ! local tendency from cloud scheme
REAL(KIND=JPRB)   ,INTENT(IN)    :: PVFA(KLON,KLEV)  ! CC from VDF scheme
REAL(KIND=JPRB)   ,INTENT(IN)    :: PVFL(KLON,KLEV)  ! Liq from VDF scheme
REAL(KIND=JPRB)   ,INTENT(IN)    :: PVFI(KLON,KLEV)  ! Ice from VDF scheme
REAL(KIND=JPRB)   ,INTENT(IN)    :: PDYNA(KLON,KLEV) ! CC from Dynamics
REAL(KIND=JPRB)   ,INTENT(IN)    :: PDYNL(KLON,KLEV) ! Liq from Dynamics
REAL(KIND=JPRB)   ,INTENT(IN)    :: PDYNI(KLON,KLEV) ! Liq from Dynamics
REAL(KIND=JPRB)   ,INTENT(IN)    :: PHRSW(KLON,KLEV) ! Short-wave heating rate
REAL(KIND=JPRB)   ,INTENT(IN)    :: PHRLW(KLON,KLEV) ! Long-wave heating rate
REAL(KIND=JPRB)   ,INTENT(IN)    :: PVERVEL(KLON,KLEV) !Vertical velocity
REAL(KIND=JPRB)   ,INTENT(IN)    :: PAP(KLON,KLEV)   ! Pressure on full levels
REAL(KIND=JPRB)   ,INTENT(IN)    :: PAPH(KLON,KLEV+1)! Pressure on half levels
REAL(KIND=JPRB)   ,INTENT(IN)    :: PLSM(KLON)       ! Land fraction (0-1) 
LOGICAL           ,INTENT(IN)    :: LDCUM(KLON)      ! Convection active
INTEGER(KIND=JPIM),INTENT(IN)    :: KTYPE(KLON)      ! Convection type 0,1,2
REAL(KIND=JPRB)   ,INTENT(IN)    :: PLU(KLON,KLEV)   ! Conv. condensate
REAL(KIND=JPRB)   ,INTENT(INOUT) :: PLUDE(KLON,KLEV) ! Conv. detrained water 
REAL(KIND=JPRB)   ,INTENT(IN)    :: PSNDE(KLON,KLEV) ! Conv. detrained snow
REAL(KIND=JPRB)   ,INTENT(IN)    :: PMFU(KLON,KLEV)  ! Conv. mass flux up
REAL(KIND=JPRB)   ,INTENT(IN)    :: PMFD(KLON,KLEV)  ! Conv. mass flux down
REAL(KIND=JPRB)   ,INTENT(IN)    :: PA(KLON,KLEV)    ! Original Cloud fraction (t)

INTEGER(KIND=JPIM),INTENT(IN)    :: KFLDX 

REAL(KIND=JPRB)   ,INTENT(IN)    :: PCLV(KLON,KLEV,NCLV) 

 ! Supersat clipped at previous time level in SLTEND
REAL(KIND=JPRB)   ,INTENT(IN)    :: PSUPSAT(KLON,KLEV)
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PCOVPTOT(KLON,KLEV) ! Precip fraction
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PRAINFRAC_TOPRFZ(KLON) 
! Flux diagnostics for DDH budget
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFSQLF(KLON,KLEV+1)  ! Flux of liquid
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFSQIF(KLON,KLEV+1)  ! Flux of ice
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFCQLNG(KLON,KLEV+1) ! -ve corr for liq
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFCQNNG(KLON,KLEV+1) ! -ve corr for ice
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFSQRF(KLON,KLEV+1)  ! Flux diagnostics
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFSQSF(KLON,KLEV+1)  !    for DDH, generic
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFCQRNG(KLON,KLEV+1) ! rain
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFCQSNG(KLON,KLEV+1) ! snow
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFSQLTUR(KLON,KLEV+1) ! liquid flux due to VDF
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFSQITUR(KLON,KLEV+1) ! ice flux due to VDF
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFPLSL(KLON,KLEV+1) ! liq+rain sedim flux
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFPLSN(KLON,KLEV+1) ! ice+snow sedim flux
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFHPSL(KLON,KLEV+1) ! Enthalpy flux for liq
REAL(KIND=JPRB)   ,INTENT(OUT)   :: PFHPSN(KLON,KLEV+1) ! Enthalp flux for ice

!-------------------------------------------------------------------------------
!                       Declare local variables
!-------------------------------------------------------------------------------

REAL(KIND=JPRB) :: &
!  condensation and evaporation terms
 & ZLCOND1(KLON), ZLCOND2(KLON),&
 & ZLEVAP,        ZLEROS,&
 & ZLEVAPL(KLON), ZLEVAPI(KLON),&
! autoconversion terms
 & ZRAINAUT(KLON), ZSNOWAUT(KLON), &
 & ZLIQCLD(KLON),  ZICECLD(KLON)
REAL(KIND=JPRB) :: ZFOKOOP(KLON), ZFOEALFA(KLON,KLEV+1)
REAL(KIND=JPRB) :: ZICENUCLEI(KLON) ! number concentration of ice nuclei

REAL(KIND=JPRB) :: ZLICLD(KLON)
REAL(KIND=JPRB) :: ZACOND
REAL(KIND=JPRB) :: ZAEROS
REAL(KIND=JPRB) :: ZLFINALSUM(KLON)
REAL(KIND=JPRB) :: ZDQS(KLON)
REAL(KIND=JPRB) :: ZTOLD(KLON)
REAL(KIND=JPRB) :: ZQOLD(KLON)  
REAL(KIND=JPRB) :: ZDTGDP(KLON) 
REAL(KIND=JPRB) :: ZRDTGDP(KLON)  
REAL(KIND=JPRB) :: ZTRPAUS(KLON)
REAL(KIND=JPRB) :: ZCOVPCLR(KLON)   
REAL(KIND=JPRB) :: ZPRECLR
REAL(KIND=JPRB) :: ZCOVPTOT(KLON)    
REAL(KIND=JPRB) :: ZCOVPMAX(KLON)
REAL(KIND=JPRB) :: ZQPRETOT(KLON)
REAL(KIND=JPRB) :: ZDPEVAP
REAL(KIND=JPRB) :: ZDTFORC
REAL(KIND=JPRB) :: ZDTDIAB
REAL(KIND=JPRB) :: ZTP1(KLON,KLEV)   
REAL(KIND=JPRB) :: ZLDEFR(KLON)
REAL(KIND=JPRB) :: ZLDIFDT(KLON)
REAL(KIND=JPRB) :: ZDTGDPF(KLON)
REAL(KIND=JPRB) :: ZLCUST(KLON,NCLV)
REAL(KIND=JPRB) :: ZACUST(KLON)
REAL(KIND=JPRB) :: ZMF(KLON) 

REAL(KIND=JPRB) :: ZRHO(KLON)
REAL(KIND=JPRB) :: ZTMP1(KLON),ZTMP2(KLON),ZTMP3(KLON)
REAL(KIND=JPRB) :: ZTMP4(KLON),ZTMP5(KLON),ZTMP6(KLON),ZTMP7(KLON)
REAL(KIND=JPRB) :: ZALFAWM(KLON)

! Accumulators of A,B,and C factors for cloud equations
REAL(KIND=JPRB) :: ZSOLAB(KLON) ! -ve implicit CC
REAL(KIND=JPRB) :: ZSOLAC(KLON) ! linear CC
REAL(KIND=JPRB) :: ZANEW
REAL(KIND=JPRB) :: ZANEWM1(KLON) 

REAL(KIND=JPRB) :: ZGDP(KLON)

!---for flux calculation
REAL(KIND=JPRB) :: ZDA(KLON)
REAL(KIND=JPRB) :: ZLI(KLON,KLEV),           ZA(KLON,KLEV)
REAL(KIND=JPRB) :: ZAORIG(KLON,KLEV) ! start of scheme value for CC

LOGICAL :: LLFLAG(KLON)
LOGICAL :: LLO1

INTEGER(KIND=JPIM) :: ICALL, IK, JK, JL, JM, JN, JO, JLEN, IS

REAL(KIND=JPRB) :: ZDP(KLON), ZPAPHD(KLON)

REAL(KIND=JPRB) :: ZALFA
! & ZALFACU, ZALFALS
REAL(KIND=JPRB) :: ZALFAW
REAL(KIND=JPRB) :: ZBETA,ZBETA1
!REAL(KIND=JPRB) :: ZBOTT
REAL(KIND=JPRB) :: ZCFPR
REAL(KIND=JPRB) :: ZCOR
REAL(KIND=JPRB) :: ZCDMAX
REAL(KIND=JPRB) :: ZMIN(KLON)
REAL(KIND=JPRB) :: ZLCONDLIM
REAL(KIND=JPRB) :: ZDENOM
REAL(KIND=JPRB) :: ZDPMXDT
REAL(KIND=JPRB) :: ZDPR
REAL(KIND=JPRB) :: ZDTDP
REAL(KIND=JPRB) :: ZE
REAL(KIND=JPRB) :: ZEPSEC
REAL(KIND=JPRB) :: ZFAC, ZFACI, ZFACW
REAL(KIND=JPRB) :: ZGDCP
REAL(KIND=JPRB) :: ZINEW
REAL(KIND=JPRB) :: ZLCRIT
REAL(KIND=JPRB) :: ZMFDN
REAL(KIND=JPRB) :: ZPRECIP
REAL(KIND=JPRB) :: ZQE
REAL(KIND=JPRB) :: ZQSAT, ZQTMST, ZRDCP
REAL(KIND=JPRB) :: ZRHC, ZSIG, ZSIGK
REAL(KIND=JPRB) :: ZWTOT
REAL(KIND=JPRB) :: ZZCO, ZZDL, ZZRH, ZZZDT, ZQADJ
REAL(KIND=JPRB) :: ZQNEW, ZTNEW
REAL(KIND=JPRB) :: ZRG_R,ZGDPH_R,ZCONS1,ZCOND,ZCONS1A
REAL(KIND=JPRB) :: ZLFINAL
REAL(KIND=JPRB) :: ZMELT
REAL(KIND=JPRB) :: ZEVAP
REAL(KIND=JPRB) :: ZFRZ
REAL(KIND=JPRB) :: ZVPLIQ, ZVPICE
REAL(KIND=JPRB) :: ZADD, ZBDD, ZCVDS, ZICE0, ZDEPOS
REAL(KIND=JPRB) :: ZSUPSAT(KLON)
REAL(KIND=JPRB) :: ZFALL
REAL(KIND=JPRB) :: ZRE_ICE
REAL(KIND=JPRB) :: ZRLDCP
REAL(KIND=JPRB) :: ZQP1ENV

!----------------------------
! Arrays for new microphysics
!----------------------------
INTEGER(KIND=JPIM) :: IPHASE(NCLV) ! marker for water phase of each species
                                   ! 0=vapour, 1=liquid, 2=ice

INTEGER(KIND=JPIM) :: IMELT(NCLV)  ! marks melting linkage for ice categories
                                   ! ice->liquid, snow->rain

LOGICAL :: LLFALL(NCLV)      ! marks falling species
                             ! LLFALL=0, cloud cover must > 0 for zqx > 0
                             ! LLFALL=1, no cloud needed, zqx can evaporate

LOGICAL            :: LLINDEX1(KLON,NCLV)      ! index variable
LOGICAL            :: LLINDEX3(KLON,NCLV,NCLV) ! index variable
REAL(KIND=JPRB)    :: ZMAX
REAL(KIND=JPRB)    :: ZRAT 
INTEGER(KIND=JPIM) :: IORDER(KLON,NCLV) ! array for sorting explicit terms

REAL(KIND=JPRB) :: ZLIQFRAC(KLON,KLEV)  ! cloud liquid water fraction: ql/(ql+qi)
REAL(KIND=JPRB) :: ZICEFRAC(KLON,KLEV)  ! cloud ice water fraction: qi/(ql+qi)
REAL(KIND=JPRB) :: ZQX(KLON,KLEV,NCLV)  ! water variables
REAL(KIND=JPRB) :: ZQX0(KLON,KLEV,NCLV) ! water variables at start of scheme
REAL(KIND=JPRB) :: ZQXN(KLON,NCLV)      ! new values for zqx at time+1
REAL(KIND=JPRB) :: ZQXFG(KLON,NCLV)     ! first guess values including precip
REAL(KIND=JPRB) :: ZQXNM1(KLON,NCLV)    ! new values for zqx at time+1 at level above
REAL(KIND=JPRB) :: ZFLUXQ(KLON,NCLV)    ! fluxes convergence of species (needed?)
! Keep the following for possible future total water variance scheme?
!REAL(KIND=JPRB) :: ZTL(KLON,KLEV)       ! liquid water temperature
!REAL(KIND=JPRB) :: ZABETA(KLON,KLEV)    ! cloud fraction
!REAL(KIND=JPRB) :: ZVAR(KLON,KLEV)      ! temporary variance
!REAL(KIND=JPRB) :: ZQTMIN(KLON,KLEV)
!REAL(KIND=JPRB) :: ZQTMAX(KLON,KLEV)

REAL(KIND=JPRB) :: ZPFPLSX(KLON,KLEV+1,NCLV) ! generalized precipitation flux
REAL(KIND=JPRB) :: ZLNEG(KLON,KLEV,NCLV)     ! for negative correction diagnostics
REAL(KIND=JPRB) :: ZMELTMAX(KLON)
REAL(KIND=JPRB) :: ZFRZMAX(KLON)
REAL(KIND=JPRB) :: ZICETOT(KLON)

REAL(KIND=JPRB) :: ZQXN2D(KLON,KLEV,NCLV)   ! water variables store

REAL(KIND=JPRB) :: ZQSMIX(KLON,KLEV) ! diagnostic mixed phase saturation 
!REAL(KIND=JPRB) :: ZQSBIN(KLON,KLEV) ! binary switched ice/liq saturation
REAL(KIND=JPRB) :: ZQSLIQ(KLON,KLEV) ! liquid water saturation
REAL(KIND=JPRB) :: ZQSICE(KLON,KLEV) ! ice water saturation

!REAL(KIND=JPRB) :: ZRHM(KLON,KLEV) ! diagnostic mixed phase RH
!REAL(KIND=JPRB) :: ZRHL(KLON,KLEV) ! RH wrt liq
!REAL(KIND=JPRB) :: ZRHI(KLON,KLEV) ! RH wrt ice

REAL(KIND=JPRB) :: ZFOEEWMT(KLON,KLEV)
REAL(KIND=JPRB) :: ZFOEEW(KLON,KLEV)
REAL(KIND=JPRB) :: ZFOEELIQT(KLON,KLEV)
!REAL(KIND=JPRB) :: ZFOEEICET(KLON,KLEV)

REAL(KIND=JPRB) :: ZDQSLIQDT(KLON), ZDQSICEDT(KLON), ZDQSMIXDT(KLON)
REAL(KIND=JPRB) :: ZCORQSLIQ(KLON)
REAL(KIND=JPRB) :: ZCORQSICE(KLON) 
!REAL(KIND=JPRB) :: ZCORQSBIN(KLON)
REAL(KIND=JPRB) :: ZCORQSMIX(KLON)
REAL(KIND=JPRB) :: ZEVAPLIMLIQ(KLON), ZEVAPLIMICE(KLON), ZEVAPLIMMIX(KLON)

!-------------------------------------------------------
! SOURCE/SINK array for implicit and explicit terms
!-------------------------------------------------------
! a POSITIVE value entered into the arrays is a...
!            Source of this variable
!            |
!            |   Sink of this variable
!            |   |
!            V   V
! ZSOLQA(JL,IQa,IQb)  = explicit terms
! ZSOLQB(JL,IQa,IQb)  = implicit terms
! Thus if ZSOLAB(JL,NCLDQL,IQV)=K where K>0 then this is 
! a source of NCLDQL and a sink of IQV
! put 'magic' source terms such as PLUDE from 
! detrainment into explicit source/sink array diagnognal
! ZSOLQA(NCLDQL,NCLDQL)= -PLUDE
! i.e. A positive value is a sink!????? weird... 
!-------------------------------------------------------

REAL(KIND=JPRB) :: ZSOLQA(KLON,NCLV,NCLV) ! explicit sources and sinks
REAL(KIND=JPRB) :: ZSOLQB(KLON,NCLV,NCLV) ! implicit sources and sinks
                        ! e.g. microphysical pathways between ice variables.
REAL(KIND=JPRB) :: ZQLHS(KLON,NCLV,NCLV)  ! n x n matrix storing the LHS of implicit solver
REAL(KIND=JPRB) :: ZVQX(NCLV)        ! fall speeds of three categories
REAL(KIND=JPRB) :: ZEXPLICIT, ZRATIO(KLON,NCLV), ZSINKSUM(KLON,NCLV)

! for sedimentation source/sink terms
REAL(KIND=JPRB) :: ZFALLSINK(KLON,NCLV)
REAL(KIND=JPRB) :: ZFALLSRCE(KLON,NCLV)

! for convection detrainment source and subsidence source/sink terms
REAL(KIND=JPRB) :: ZCONVSRCE(KLON,NCLV)
REAL(KIND=JPRB) :: ZCONVSINK(KLON,NCLV)

! for supersaturation source term from previous timestep
REAL(KIND=JPRB) :: ZPSUPSATSRCE(KLON,NCLV)

! Numerical fit to wet bulb temperature
REAL(KIND=JPRB),PARAMETER :: ZTW1 = 1329.31_JPRB
REAL(KIND=JPRB),PARAMETER :: ZTW2 = 0.0074615_JPRB
REAL(KIND=JPRB),PARAMETER :: ZTW3 = 0.85E5_JPRB
REAL(KIND=JPRB),PARAMETER :: ZTW4 = 40.637_JPRB
REAL(KIND=JPRB),PARAMETER :: ZTW5 = 275.0_JPRB

REAL(KIND=JPRB) :: ZSUBSAT  ! Subsaturation for snow melting term         
REAL(KIND=JPRB) :: ZTDMTW0  ! Diff between dry-bulb temperature and 
                            ! temperature when wet-bulb = 0degC 

! Variables for deposition term
REAL(KIND=JPRB) :: ZTCG ! Temperature dependent function for ice PSD
REAL(KIND=JPRB) :: ZFACX1I, ZFACX1S! PSD correction factor
REAL(KIND=JPRB) :: ZAPLUSB,ZCORRFAC,ZCORRFAC2,ZPR02,ZTERM1,ZTERM2 ! for ice dep
REAL(KIND=JPRB) :: ZCLDTOPDIST(KLON) ! Distance from cloud top
REAL(KIND=JPRB) :: ZINFACTOR         ! No. of ice nuclei factor for deposition

! Autoconversion/accretion/riming/evaporation
INTEGER(KIND=JPIM) :: IWARMRAIN
INTEGER(KIND=JPIM) :: IEVAPRAIN
INTEGER(KIND=JPIM) :: IEVAPSNOW
INTEGER(KIND=JPIM) :: IDEPICE
REAL(KIND=JPRB) :: ZRAINACC(KLON)
REAL(KIND=JPRB) :: ZRAINCLD(KLON)
REAL(KIND=JPRB) :: ZSNOWRIME(KLON)
REAL(KIND=JPRB) :: ZSNOWCLD(KLON)
REAL(KIND=JPRB) :: ZESATLIQ
REAL(KIND=JPRB) :: ZFALLCORR
REAL(KIND=JPRB) :: ZLAMBDA
REAL(KIND=JPRB) :: ZEVAP_DENOM
REAL(KIND=JPRB) :: ZCORR2
REAL(KIND=JPRB) :: ZKA
REAL(KIND=JPRB) :: ZCONST
REAL(KIND=JPRB) :: ZTEMP

! Rain freezing
LOGICAL :: LLRAINLIQ(KLON)  ! True if majority of raindrops are liquid (no ice core)
LOGICAL :: LDMAINCALL
LOGICAL :: LDSLPHY
REAL(KIND=JPRB) :: PEXTRA(KLON,KLEV,KFLDX)
!----------------------------
! End: new microphysics
!----------------------------

!----------------------
! SCM budget statistics 
!----------------------
REAL(KIND=JPRB) :: ZRAIN

REAL(KIND=JPRB) :: Z_TMP1(KFDIA-KIDIA+1)
REAL(KIND=JPRB) :: Z_TMP2(KFDIA-KIDIA+1)
REAL(KIND=JPRB) :: Z_TMP3(KFDIA-KIDIA+1)
REAL(KIND=JPRB) :: Z_TMP4(KFDIA-KIDIA+1)
!REAL(KIND=JPRB) :: Z_TMP5(KFDIA-KIDIA+1)
REAL(KIND=JPRB) :: Z_TMP6(KFDIA-KIDIA+1)
REAL(KIND=JPRB) :: Z_TMP7(KFDIA-KIDIA+1)
REAL(KIND=JPRB) :: Z_TMPK(KFDIA-KIDIA+1,KLEV)
!REAL(KIND=JPRB) :: ZCON1,ZCON2
REAL(KIND=JPRB) :: ZHOOK_HANDLE
REAL(KIND=JPRB) :: ZTMPL,ZTMPI,ZTMPA

REAL(KIND=JPRB) :: ZMM,ZRR
REAL(KIND=JPRB) :: ZRG(KLON)

REAL(KIND=JPRB) :: ZBUDCC(KLON,KFLDX) ! extra fields
REAL(KIND=JPRB) :: ZBUDL(KLON,KFLDX) ! extra fields
REAL(KIND=JPRB) :: ZBUDI(KLON,KFLDX) ! extra fields

REAL(KIND=JPRB) :: ZZSUM, ZZRATIO
REAL(KIND=JPRB) :: ZEPSILON

REAL(KIND=JPRB) :: ZCOND1, ZQP
INTEGER(KIND=JPIM)::print1
REAL(KIND=JPRB) :: tendency_cml_T(KLON,KLEV )
REAL(KIND=JPRB) :: tendency_cml_a(KLON,KLEV )
REAL(KIND=JPRB) :: tendency_cml_cld(KLON,KLEV,5 )
REAL(KIND=JPRB) :: tendency_cml_o3(KLON,KLEV  )
REAL(KIND=JPRB) :: tendency_cml_q(KLON,KLEV  )
REAL(KIND=JPRB) :: tendency_cml_u(KLON,KLEV  )
REAL(KIND=JPRB) :: tendency_cml_v(KLON,KLEV  )
REAL(KIND=JPRB) :: tendency_loc_T(KLON,KLEV  )
REAL(KIND=JPRB) :: tendency_loc_a(KLON,KLEV )
REAL(KIND=JPRB) :: tendency_loc_cld(KLON,KLEV,5 )
REAL(KIND=JPRB) :: tendency_loc_o3(KLON,KLEV  )
REAL(KIND=JPRB) :: tendency_loc_q(KLON,KLEV  )
REAL(KIND=JPRB) :: tendency_loc_u(KLON,KLEV  )
REAL(KIND=JPRB) :: tendency_loc_v(KLON,KLEV )
REAL(KIND=JPRB) :: tendency_tmp_T(KLON,KLEV  )
REAL(KIND=JPRB) :: tendency_tmp_a(KLON,KLEV  )
REAL(KIND=JPRB) :: tendency_tmp_cld(KLON,KLEV,5 )
REAL(KIND=JPRB) :: tendency_tmp_o3(KLON,KLEV )
REAL(KIND=JPRB) :: tendency_tmp_q(KLON,KLEV  )
REAL(KIND=JPRB) :: tendency_tmp_u(KLON,KLEV )
REAL(KIND=JPRB) :: tendency_tmp_v(KLON,KLEV  )
INTEGER :: print,ind1,ind2

#include "abor1.intfb.h"

!DIR$ VFUNCTION EXPHF
#include "fcttre.func.h"
#include "fccld.func.h"

!===============================================================================
!IF (LHOOK) CALL DR_HOOK('CLOUDSC',0,ZHOOK_HANDLE)

!write (*,*) "actual start of cloudsc"
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

!===============================================================================
!  0.0     Beginning of timestep book-keeping
!----------------------------------------------------------------------

!tendency_cml_T(:,:)=tendency_cml%T(:,:)
!tendency_cml_a(:,:)=tendency_cml%a(:,:)

!tendency_cml_cld(:,:,:)=tendency_cml%cld(:,:,:)

!write (*,*) "after first 3"
!tendency_cml_o3(:,:)=tendency_cml%o3(:,:)

!write (*,*) "after first 4"
!tendency_cml_q(:,:)=tendency_cml%q(:,:)
!write (*,*) "after first 5"
!tendency_cml_u(:,:)=tendency_cml%u(:,:)
!write (*,*) "after first 6"
!tendency_cml_v(:,:)=tendency_cml%v(:,:)

!write (*,*) "after first 7"
!tendency_tmp_T(:,:)=tendency_tmp%T(:,:)
!tendency_tmp_a(:,:)=tendency_tmp%a(:,:)

!write (*,*) "after first 9"
!tendency_cml_o3(:,:)=tendency_cml%o3(:,:)
!tendency_tmp_cld(:,:,:)=tendency_tmp%cld(:,:,:)
!tendency_tmp_o3(:,:)=tendency_tmp%o3(:,:)
!tendency_tmp_q(:,:)=tendency_tmp%q(:,:)
!tendency_tmp_u(:,:)=tendency_tmp%u(:,:)
!tendency_tmp_v(:,:)=tendency_tmp%v(:,:)

print=1
!write (*,*) "Before call to cloudsc2:", KLON, KLEV, NCLV

!DO ind1=1,10
!DO ind2=1,1
!write (*,*) PT(ind1,ind2)
!ENDDO
!ENDDO
!write (*,*) "JPIM=",JPIM," JPRB=",JPRB
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
& tendency_cml%T,&
& tendency_cml%a,&
& tendency_cml%cld,&
& tendency_cml_o3,&
& tendency_cml%q,&
& tendency_cml_u,&
& tendency_cml_v,&
& tendency_loc%T,&
& tendency_loc%a,&
& tendency_loc%cld,&
& tendency_loc_o3,&
& tendency_loc%q,&
& tendency_loc_u,&
& tendency_loc_v,&
& tendency_tmp%T,&
& tendency_tmp%a,&
& tendency_tmp%cld,&
& tendency_tmp_o3,&
& tendency_tmp%q,&
& tendency_tmp_u,&
& tendency_tmp_v,&
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
& KFDIA,&
& KFLDX,&
& KIDIA,&
& KLEV,&
& KLON,&
& NCLDQI,&
& NCLDQL,&
& NCLDQR,&
& NCLDQS,&
& NCLDQV,&
& NCLV,&
& LAERICEAUTO,&
& LAERICESED,&
& LAERLIQAUTOLSP,&
& LAERLIQCOLL,&
& LDMAINCALL,&
& LDSLPHY,&
& NCLDTOP,&
& NSSOPT,&
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


!tendency_loc%T(:,:)=tendency_loc_T(:,:)
!tendency_loc%a(:,:)=tendency_loc_a(:,:)
!tendency_loc%cld(:,:,1:4)=tendency_loc_cld(:,:,1:4)
!tendency_loc%o3(:,:)=tendency_loc_o3(:,:)
!tendency_loc%q(:,:)=tendency_loc_q(:,:)
!tendency_loc%u(:,:)=tendency_loc_u(:,:)
!tendency_loc%v(:,:)=tendency_loc_v(:,:)

!===============================================================================
END ASSOCIATE
!IF (LHOOK) CALL DR_HOOK('CLOUDSC',1,ZHOOK_HANDLE)
END SUBROUTINE CLOUDSC

