      MODULE iceshelf_vbc_mod
!
!=======================================================================
!  Copyright (c) 2002 ROMS/TOMS Group                                  !
!========================================== Benjamin K. Galton-Fenzi ==!
!                                                                      !
! This module sets the ice-shelf/ocean vertical boundary conditions    !
!                                                                      !
!                                                                      !
!   Ice shelf         Ti, Si                                           !
!                                                                      !
!  ================================                                    !
!                                                                      !
!   Laminar sublayer  Tb, Sb, ustar                                    !                      
!                                                                      !
!  --------------------------------                                    !
!                                                                      !
!   Ocean             Tm, Sm, u                                        !
!                                                                      !
!                                                                      !
! References:                                                          ! 
!                                                                      !
! Hellmer, H. H., and D. Olbers, A two-dimensional model for the       !
!  thermohaline circulation under an ice shelf, Antarctic Science,     !
!  1, 325–33, 1989.                                                    ! 
!                                                                      !
! Scheduikat, M., and D. J. Olbers, A one-dimensional mixed layer      !
!  model beneath the Ross Ice Shelf with tidally induced vertical      !
!  mixing, Antarctic Science, 2(1), 29–42, 1990.                       !
!                                                                      !  
! Holland, D. M., and A. Jenkins, Modeling thermodynamic ice-ocean     !
!  interactions at the base of an ice shelf, Journal of Physical       !
!  Oceanography, 29, 1787–1800, 1999.                                  !
!                                                                      !
!=======================================================================
!
      implicit none
      PRIVATE
      PUBLIC  :: iceshelf_vbc
      CONTAINS
!
!***********************************************************************
      SUBROUTINE iceshelf_vbc (ng, tile)
!***********************************************************************
!
      USE mod_param
      USE mod_grid
      USE mod_forces
      USE mod_ocean
      USE mod_iceshelf
      USE mod_coupling
      USE mod_stepping
      USE mod_iceshelfvar
!
      implicit none
!
      integer, intent(in) :: ng, tile
      integer :: IminS, ImaxS, JminS, JmaxS
      integer :: LBi, UBi, LBj, UBj, LBij, UBij
!
!  Set horizontal starting and ending indices for automatic private
!  storage arrays.
!
      IminS=BOUNDS(ng)%Istr(tile)-3
      ImaxS=BOUNDS(ng)%Iend(tile)+3
      JminS=BOUNDS(ng)%Jstr(tile)-3
      JmaxS=BOUNDS(ng)%Jend(tile)+3
!
!  Determine array lower and upper bounds in the I- and J-directions.
!
      LBi=BOUNDS(ng)%LBi(tile)
      UBi=BOUNDS(ng)%UBi(tile)
      LBj=BOUNDS(ng)%LBj(tile)
      UBj=BOUNDS(ng)%UBj(tile)
!
!  Set array lower and upper bounds for MIN(I,J) directions and
!  MAX(I,J) directions.
!
      LBij=BOUNDS(ng)%LBij
      UBij=BOUNDS(ng)%UBij
!
      CALL wclock_on (ng, iNLM, 6)
      CALL iceshelf_vbc_tile (ng, tile,                                 &
     &                   LBi, UBi, LBj, UBj,                            &
     &                   IminS, ImaxS, JminS, JmaxS,                    &
     &                   nrhs(ng), nnew(ng),                            &
     &                   GRID(ng) % Hz,                                 &
     &                   GRID(ng) % rmask,                              &
     &                   GRID(ng) % z_r,                                &
     &                   GRID(ng) % z_w,                                &
     &                   GRID(ng) % zice,                               &
     &                   GRID(ng) % f,                                  &
     &                   OCEAN(ng) % u,                                 &
     &                   OCEAN(ng) % v,                                 &
     &                   OCEAN(ng) % t,                                 &
     &                   ICESHELFVAR(ng) % gammaT,                      &
     &                   ICESHELFVAR(ng) % gammaS,                      &
     &                   ICESHELFVAR(ng) % Tb,                          &
     &                   ICESHELFVAR(ng) % Tstar,                       &
     &                   ICESHELFVAR(ng) % ustar,                       &
     &                   ICESHELFVAR(ng) % Sb,                          &
     &                   ICESHELFVAR(ng) % m,                           &
     &                   ICESHELFVAR(ng) % ssflxSOF,                    &
     &                   ICESHELFVAR(ng) % shflxSOF,                    &
     &                   OCEAN(ng) % rho,                               &
     &                   FORCES(ng) % sustr,                            &
     &                   FORCES(ng) % svstr,                            &
     &                   FORCES(ng) % srflx,                            &
     &                   FORCES(ng) % stflx                             &
     &                   )
      CALL wclock_off (ng, iNLM, 6)
      RETURN
      END SUBROUTINE iceshelf_vbc
!
!***********************************************************************
      SUBROUTINE iceshelf_vbc_tile (ng, tile,                           &
     &                         LBi, UBi, LBj, UBj,                      &
     &                         IminS, ImaxS, JminS, JmaxS,              &
     &                         nrhs,nnew,                               &
     &                         Hz,                                      &
     &                         rmask,                                   &
     &                         z_r, z_w,                                &
     &                         zice,f,                                  &
     &                         u, v, t,                                 &
     &                         gammaT, gammaS,                          &
     &                         Tb, Tstar, ustar, Sb,                    &
     &                         m,                                       &
     &                         ssflxSOF,                                &
     &                         shflxSOF,                                &
     &                         rho,                                     &
     &                         sustr, svstr,                            &
     &                         srflx,                                   &
     &                         stflx)                                   
!***********************************************************************
!
      USE mod_param
      USE mod_scalars
!
      USE mod_iceshelf
      USE bc_2d_mod
      USE exchange_2d_mod, ONLY : exchange_r2d_tile
      USE mp_exchange_mod, ONLY : mp_exchange2d
!
!  Imported variable declarations.
!
      integer, intent(in) :: ng, tile
      integer, intent(in) :: LBi, UBi, LBj, UBj
      integer, intent(in) :: IminS, ImaxS, JminS, JmaxS
      integer, intent(in) :: nrhs,nnew
      real(r8), intent(in) :: u(LBi:,LBj:,:,:)
      real(r8), intent(in) :: v(LBi:,LBj:,:,:)
      real(r8), intent(out) :: sustr(LBi:,LBj:)
      real(r8), intent(out) :: svstr(LBi:,LBj:)
      real(r8), intent(in) :: rho(LBi:,LBj:,:)
      real(r8), intent(in) :: Hz(LBi:,LBj:,:)
      real(r8), intent(in) :: rmask(LBi:,LBj:)
      real(r8), intent(in) :: z_r(LBi:,LBj:,:)
      real(r8), intent(in) :: z_w(LBi:,LBj:,0:)
      real(r8), intent(in) :: zice(LBi:,LBj:)
      real(r8), intent(in) :: f(LBi:,LBj:)
      real(r8), intent(in) :: t(LBi:,LBj:,:,:,:)
      real(r8), intent(out) :: gammaT(LBi:,LBj:)
      real(r8), intent(out) :: gammaS(LBi:,LBj:)
      real(r8), intent(out) :: Tb(LBi:,LBj:)
      real(r8), intent(out) :: Tstar(LBi:,LBj:)
      real(r8), intent(out) :: ustar(LBi:,LBj:)
      real(r8), intent(out) :: Sb(LBi:,LBj:)
      real(r8), intent(out) :: m(LBi:,LBj:)
      real(r8), intent(out) :: ssflxSOF(LBi:UBi,LBj:UBj)
      real(r8), intent(out) :: shflxSOF(LBi:UBi,LBj:UBj)
      real(r8), intent(inout) :: srflx(LBi:,LBj:)
      real(r8), intent(inout) :: stflx(LBi:,LBj:,:)
!
!  Local variable declarations.
!
!      integer :: IstrR, IENDR, JstrR, JendR, IstrU, JstrV
      integer :: i, j, itrc
      real(r8) :: Pradj,Scadj, Cdrt, cp_i
!      real(r8) :: a,b,c,Pr,Sc,Cd,small
!      real(r8) :: cp_w,ustar,visc,turb,TFb,rho_i
      real(r8) :: Sm,Tm,rhoi_on_rho0,TFb,turb
      real(r8) :: mflag,TFi,cff3 
      real(r8) :: cff1, cff2
      real(r8) :: cff
      real(r8) :: Salt_insitu, Temp_insitu, Tf, shflx_old
!
!-----------------------------------------------------------------------
!  Set lower and upper tile bounds and staggered variables bounds for
!  this horizontal domain partition.  Notice that if tile=-1, it will
!  set the values for the global grid.
!-----------------------------------------------------------------------
!
      integer :: Istr, IstrB, IstrP, IstrR, IstrT, IstrM, IstrU
      integer :: Iend, IendB, IendP, IendR, IendT
      integer :: Jstr, JstrB, JstrP, JstrR, JstrT, JstrM, JstrV
      integer :: Jend, JendB, JendP, JendR, JendT
      integer :: Istrm3, Istrm2, Istrm1, IstrUm2, IstrUm1
      integer :: Iendp1, Iendp2, Iendp2i, Iendp3
      integer :: Jstrm3, Jstrm2, Jstrm1, JstrVm2, JstrVm1
      integer :: Jendp1, Jendp2, Jendp2i, Jendp3
!
      Istr   =BOUNDS(ng) % Istr   (tile)
      IstrB  =BOUNDS(ng) % IstrB  (tile)
      IstrM  =BOUNDS(ng) % IstrM  (tile)
      IstrP  =BOUNDS(ng) % IstrP  (tile)
      IstrR  =BOUNDS(ng) % IstrR  (tile)
      IstrT  =BOUNDS(ng) % IstrT  (tile)
      IstrU  =BOUNDS(ng) % IstrU  (tile)
      Iend   =BOUNDS(ng) % Iend   (tile)
      IendB  =BOUNDS(ng) % IendB  (tile)
      IendP  =BOUNDS(ng) % IendP  (tile)
      IendR  =BOUNDS(ng) % IendR  (tile)
      IendT  =BOUNDS(ng) % IendT  (tile)
      Jstr   =BOUNDS(ng) % Jstr   (tile)
      JstrB  =BOUNDS(ng) % JstrB  (tile)
      JstrM  =BOUNDS(ng) % JstrM  (tile)
      JstrP  =BOUNDS(ng) % JstrP  (tile)
      JstrR  =BOUNDS(ng) % JstrR  (tile)
      JstrT  =BOUNDS(ng) % JstrT  (tile)
      JstrV  =BOUNDS(ng) % JstrV  (tile)
      Jend   =BOUNDS(ng) % Jend   (tile)
      JendB  =BOUNDS(ng) % JendB  (tile)
      JendP  =BOUNDS(ng) % JendP  (tile)
      JendR  =BOUNDS(ng) % JendR  (tile)
      JendT  =BOUNDS(ng) % JendT  (tile)
!
      Istrm3 =BOUNDS(ng) % Istrm3 (tile)            ! Istr-3
      Istrm2 =BOUNDS(ng) % Istrm2 (tile)            ! Istr-2
      Istrm1 =BOUNDS(ng) % Istrm1 (tile)            ! Istr-1
      IstrUm2=BOUNDS(ng) % IstrUm2(tile)            ! IstrU-2
      IstrUm1=BOUNDS(ng) % IstrUm1(tile)            ! IstrU-1
      Iendp1 =BOUNDS(ng) % Iendp1 (tile)            ! Iend+1
      Iendp2 =BOUNDS(ng) % Iendp2 (tile)            ! Iend+2
      Iendp2i=BOUNDS(ng) % Iendp2i(tile)            ! Iend+2 interior
      Iendp3 =BOUNDS(ng) % Iendp3 (tile)            ! Iend+3
      Jstrm3 =BOUNDS(ng) % Jstrm3 (tile)            ! Jstr-3
      Jstrm2 =BOUNDS(ng) % Jstrm2 (tile)            ! Jstr-2
      Jstrm1 =BOUNDS(ng) % Jstrm1 (tile)            ! Jstr-1
      JstrVm2=BOUNDS(ng) % JstrVm2(tile)            ! JstrV-2
      JstrVm1=BOUNDS(ng) % JstrVm1(tile)            ! JstrV-1
      Jendp1 =BOUNDS(ng) % Jendp1 (tile)            ! Jend+1
      Jendp2 =BOUNDS(ng) % Jendp2 (tile)            ! Jend+2
      Jendp2i=BOUNDS(ng) % Jendp2i(tile)            ! Jend+2 interior
      Jendp3 =BOUNDS(ng) % Jendp3 (tile)            ! Jend+3
!
!-----------------------------------------------------------------------
!  If ice shelf cavities, replace surface wind stress with ice shelf
!  cavity stress (m2/s2).
!-----------------------------------------------------------------------
!
!  Set limiting factor for ice shelf basal. The stress is adjusted
!  to not change the direction of momentum.  It only should slow down
!  to zero.  The value of 0.75 is arbitrary limitation assigment.
!
      cff=0.75_r8/dt(ng)
!
!  Set quadratic ice shelf cavity stress.
!
      DO j=Jstr,JEND
        DO i=IstrU,IEND
          IF (zice(i,j)*zice(i-1,j).ne.0.0_r8) THEN
            cff1=0.25_r8*(v(i  ,j  ,N(ng),nrhs)+                        &
     &                    v(i  ,j+1,N(ng),nrhs)+                        &
     &                    v(i-1,j  ,N(ng),nrhs)+                        &
     &                    v(i-1,j+1,N(ng),nrhs))
            cff2=SQRT(u(i,j,N(ng),nrhs)*u(i,j,N(ng),nrhs)+cff1*cff1)
            sustr(i,j)=-rdrg2(ng)*u(i,j,N(ng),nrhs)*cff2
          cff3=cff*0.5_r8*(Hz(i-1,j,N(ng))+Hz(i,j,N(ng)))
          sustr(i,j)=SIGN(1.0_r8, sustr(i,j))*                          &
     &               MIN(ABS(sustr(i,j)),                               &
     &                   ABS(u(i,j,N(ng),nrhs))*cff3)
          END IF
        END DO
      END DO
      DO j=JstrV,JEND
        DO i=Istr,IEND
          IF (zice(i,j)*zice(i,j-1).ne.0.0_r8) THEN
            cff1=0.25_r8*(u(i  ,j  ,N(ng),nrhs)+                        &
     &                    u(i+1,j  ,N(ng),nrhs)+                        &
     &                    u(i  ,j-1,N(ng),nrhs)+                        &
     &                    u(i+1,j-1,N(ng),nrhs))
            cff2=SQRT(cff1*cff1+v(i,j,N(ng),nrhs)*v(i,j,N(ng),nrhs))
            svstr(i,j)=-rdrg2(ng)*v(i,j,N(ng),nrhs)*cff2
          cff3=cff*0.5_r8*(Hz(i,j-1,N(ng))+Hz(i,j,N(ng)))
          svstr(i,j)=SIGN(1.0_r8, svstr(i,j))*                          &
     &               MIN(ABS(svstr(i,j)),                               &
     &                   ABS(v(i,j,N(ng),nrhs))*cff3)
          END IF
        END DO
      END DO
!
!  Apply boundary conditions.
!
      CALL bc_u2d_tile (ng, tile,                                       &
     &                          LBi, UBi, LBj, UBj,                     &
     &                          sustr)
      CALL bc_v2d_tile (ng, tile,                                       &
     &                          LBi, UBi, LBj, UBj,                     &
     &                          svstr)
      CALL mp_exchange2d (ng, tile, iNLM, 2,                            &
     &                    LBi, UBi, LBj, UBj,                           &
     &                    NghostPoints, EWperiodic(ng), NSperiodic(ng), &
     &                    sustr,svstr)
!-----------------------------------------------------------------------
!  If ice shelf cavities, zero out for now the surface tracer flux
!  over the ice.
!-----------------------------------------------------------------------
!
      Pradj = 12.5_r8*(Pr**(2.0_r8/3.0_r8))
      Scadj = 12.5_r8*(Sc**(2.0_r8/3.0_r8))
      Cdrt =  sqrt(Cd)
      cp_i =  152.5_r8+7.122_r8*(273.15_r8+Ti)
      rhoi_on_rho0 = rho_i/rho0
      DO j=Jstr,JEND
        DO i=Istr,IEND
          Sm=MAX(0.0_r8,t(i,j,N(ng),nrhs,isalt))
!          write(6,*)
          IF (zice(i,j).ne.0.0_r8 .AND. rmask(i,j).gt.0.0_r8) THEN
! Get the insitu salinity and temperature
         CALL potit(Sm,t(i,j,N(ng),nrhs,itemp),-zice(i,j),0.0_r8,Tm,i,j)
!    Calculate exchange coefficients. Note that this assumes log profile 
            ustar(i,j) = SQRT(SQRT((0.5_r8*                             &
     &                         (sustr(i,j)+sustr(i+1,j)))**2+           &
     &                        (0.5_r8*(svstr(i,j)+svstr(i,j+1)))**2))
            ustar(i,j) = ustar(i,j)*rmask(i,j)
           if(ustar(i,j).lt.small) ustar(i,j) = small
! Uses simplified version of McPhee 1987
            IF (ustar(i,j).gt.small.and.ABS(f(i,j)).gt.1.0E-8) THEN
          turb = 2.5_r8*LOG(5300.0_r8*ustar(i,j)*ustar(i,j)/ABS(f(i,j)))&
     &           + 7.12_r8  
            ELSE
              turb = 0.0_r8
            END IF
            gammaT(i,j) = ustar(i,j)/(turb + Pradj - 6.0_r8)
            gammaS(i,j) = ustar(i,j)/(turb + Scadj - 6.0_r8)
            TFb = a*Sm + b + c*zice(i,j)
            Tstar(i,j) = Tm - TFb
            mflag= 0.5*(1 + SIGN(1.0_r8,Tm-TFb))
            TFi = (1 - mflag)*a*Si + b + c*zice(i,j)
! Calculate coefficents in quadratic to be solved:
           cff1 = L/cp_w + mflag*(cp_i/cp_w)*(TFi-Ti)
           cff2 = gammaS(i,j)*(L/cp_w + mflag*(cp_i/cp_w)*(TFb-Ti))     &
     &          + gammaT(i,j)*(TFi-Tm)
           cff3 = gammaS(i,j)*gammaT(i,j)*(TFb - Tm)
! Calculate melt rate:
           m(i,j) = -(cff2 - SQRT(cff2*cff2 - 4*cff1*cff3))/(2*cff1)
! Calculate basal temperature and salinity:
           Tb(i,j) = (gammaT(i,j)*Tm+mflag*(cp_i/cp_w)*m(i,j)*Ti        &
     &             - (L/cp_w)*m(i,j))                                   &
     &             /(gammaT(i,j) + mflag*(cp_i/cp_w)*m(i,j))
           Sb(i,j) = (Tb(i,j) - b - c*zice(i,j))/a
         stflx(i,j,itemp)=(gammaT(i,j)+rhoi_on_rho0*m(i,j))*(Tb(i,j)-Tm)
         stflx(i,j,isalt)=(gammaS(i,j)+rhoi_on_rho0*m(i,j))*(Sb(i,j)-Sm)
!           write(6,*) gammaT,gammaS,Tb,Sb,Tm,Sm,rhoi_on_rho0
          ELSE IF (zice(i,j).eq.0.0_r8 .AND. rmask(i,j).gt.0.0_r8) THEN
            m(i,j) = 0.0_r8
! Eva Cougnon 2016
! Added in for correction due to overzelous Takeshi Heat flux!
! Should be removed if ice model is included!
            Salt_insitu = MAX(0.0_r8,t(i,j,N(ng),nrhs,isalt))
            Temp_insitu = t(i,j,N(ng),nrhs,itemp) ! naughty -- resuing old variable
            Tf = a*Salt_insitu+b
! Winter correction -- release salt when getting close to Tf
            IF(stflx(i,j,itemp).lt.0.0_r8.and.Temp_insitu.gt.(Tf+0.1_r8)) THEN
               ssflxSOF(i,j)=stflx(i,j,isalt)
               stflx(i,j,isalt)=0.0_r8
! Ben's code: If temperature below Tf and heat flux < 0 relax
! temperature a Tf
            ELSE IF(stflx(i,j,itemp).lt.0.0_r8.and.Temp_insitu.lt.Tf) THEN
               shflx_old = stflx(i,j,itemp)
               stflx(i,j,itemp)=Hz(i,j,N(ng))*(Tf-Temp_insitu)/trelax
               shflxSOF(i,j) = stflx(i,j,itemp) - shflx_old
!         ELSE IF(stflx(i,j,itemp).gt.0.0_r8.and.Temp_insitu.gt.0.0_r8)
!         THEN
! summer condition: decrease input of heat from the surface forcing
! relax to new temperature at the surface to avoir over warming from
! strong Takeshi flux in summer
!          stflx(i,j,itemp)=Hz(i,j,N(ng))*
!                                                                       &
!    &                         (0.0_r8-Temp_insitu)/trelax
            END IF
! Oles code: account for the missing salt due to Eva's Winter correction
! by increasing positive salt input using constant factor
! (factor calculated to balance total salt budget after first year of
! integration)
            !IF(stflx(i,j,isalt).gt.0.0_r8) THEN
            !     stflx(i,j,isalt)=stflx(i,j,isalt)*1.1790762
            !END IF
          ELSE
            m(i,j) = 0.0_r8
          END IF
        END DO
      END DO
!-----------------------------------------------------------------------
! Store old ice shelf thickness.
!-----------------------------------------------------------------------
!
!
!  Apply gradient or periodic boundary conditions for the two fluxes
!
      CALL bc_r2d_tile (ng, tile,                                       &
     &                  LBi, UBi, LBj, UBj,                             &
     &                  stflx(:,:,itemp))
      CALL bc_r2d_tile (ng, tile,                                       &
     &                  LBi, UBi, LBj, UBj,                             &
     &                  stflx(:,:,isalt))
      CALL mp_exchange2d (ng, tile, iNLM, 1,                            &
     &                    LBi, UBi, LBj, UBj,                           &
     &                    NghostPoints, EWperiodic(ng), NSperiodic(ng), &
     &                    stflx(:,:,itemp))
      CALL mp_exchange2d (ng, tile, iNLM, 1,                            &
     &                    LBi, UBi, LBj, UBj,                           &
     &                    NghostPoints, EWperiodic(ng), NSperiodic(ng), &
     &                    stflx(:,:,isalt))
      DO j=JstrR,JENDR
        DO i=IstrR,IENDR
          IF (zice(i,j).ne.0.0_r8) THEN
            srflx(i,j)=0.0_r8
          END IF
        END DO
      END DO
      RETURN
      END SUBROUTINE iceshelf_vbc_tile
! *********************************************************************
      SUBROUTINE potit(Sal,theta,Pres,RPres,Temp,i,j)
! *********************************************************************
! Calculates from the salinity (sal, psu), potential temperature 
! (theta, degC) and reference pressure (pres, dbar) the in-situ 
! temperaure (Temp_insitu, degC) related to the in-situ pressure 
! (rfpres, dbar) with the help of an iterative method.
      USE mod_kinds
      integer, intent(in)   :: i, j
      real(r8), intent(in)  :: Sal, Pres,theta
      real(r8), intent(out) :: Temp
      integer               :: ind
      real(r8)              :: tpmd, theta1, thetad, epsi, RPres
      data tpmd / 0.001 /
      epsi = 0.
      do ind=1,100
      Temp   = theta+epsi
      thetad  = thetaa(Sal,Temp,Pres,RPres)-theta
      IF(abs(thetad).lt.tpmd) return
       epsi = epsi-thetad
      ENDdo
      write(6,*) ' WARNING!',                                           &
     & ' in-situ temperature calculation has not converged!', i,j
      RETURN
      END SUBROUTINE potit
! *********************************************************************
      REAL FUNCTION thetaa(Sal,Temp,Pres,RPres)
! Calculates from the salinity (sal, psu), the in-situ temperature 
! (Temp, degC) and the in-situ pressure press, dbar) the potential 
! temperature (Theta, degC) converted to the reference pressure
! (RPres, dbar). A Runge-Kutta procedure of the fourth order is used.
!
! Check value: theta   =    36.89073  degC
!         given sal    =    40.0      psu
!               Temp   =    40.0      degC
!               pres   = 10000.000    dbar
!               rfpres =     0.000    dbar
      USE mod_kinds
      real(r8), intent(in) ::  Sal,Temp,Pres,RPres
      real(r8)             ::  p,t,dp,dt,q,ct2,ct3,cq2a,cq2b,cq3a,cq3b
      data ct2 ,ct3  /0.29289322 ,  1.707106781/
      data cq2a,cq2b /0.58578644 ,  0.121320344/
      data cq3a,cq3b /3.414213562, -4.121320344/
      p  = Pres
      t  = Temp
      dp = RPres-Pres
      dt = dp*dTemp(Sal,t,p)
      t  = t +0.5*dt
      q = dt
      p  = p +0.5*dp
      dt = dp*dTemp(Sal,t,p)
      t  = t + ct2*(dt-q)
      q  = cq2a*dt + cq2b*q
      dt = dp*dTemp(Sal,t,p)
      t  = t + ct3*(dt-q)
      q  = cq3a*dt + cq3b*q
      p  = RPres
      dt = dp*dTemp(Sal,t,p)
      thetaa = t + (dt-q-q)/6.0
      END FUNCTION thetaa
! *********************************************************************
! *********************************************************************
      REAL FUNCTION dTemp(Sal,Temp,Pres)
! Calculates from the salinity (Sal,psu), the in-situ Temperature
! (Temp, degC) and the in-situ pressure (Pres, dbar) the adiabatic 
! temperature gradient (dTemp, K Dbar^-1).
!
! Check values: dTemp  =     3.255976E-4 K dbar^-1
!          given Sal    =    40.0         psu
!                Temp   =    40.0         degC
!                Pres   = 10000.000       dbar
      USE mod_kinds
      real(r8), intent(in) :: Sal, Temp, Pres
      real(r8)             :: s0,a0,a1,a2,a3,b0,b1,c0,c1,c2,c3
      real(r8)             :: d0,d1,e0,e1,e2,ds
      data s0 /35.0D0/
      data a0,a1,a2,a3 /3.5803D-5, 8.5258D-6, -6.8360D-8, 6.6228D-10/
      data b0,b1       /1.8932D-6, -4.2393D-8/
      data c0,c1,c2,c3 /1.8741D-8, -6.7795D-10, 8.7330D-12, -5.4481D-14/
      data d0,d1       /-1.1351D-10, 2.7759D-12/
      data e0,e1,e2    /-4.6206D-13,  1.8676D-14, -2.1687D-16/
      ds = Sal-s0
      dTemp = ( ( (e2*Temp + e1)*Temp + e0 )*Pres                       &
     &      + ( (d1*Temp + d0)*ds                                       &
     &      + ( (c3*Temp + c2)*Temp + c1 )*Temp + c0 ) )*Pres           &
     &      + (b1*Temp + b0)*ds +  ( (a3*Temp + a2)*Temp + a1 )*Temp    &
     &      + a0
      RETURN
      END FUNCTION dTemp
      END MODULE iceshelf_vbc_mod
