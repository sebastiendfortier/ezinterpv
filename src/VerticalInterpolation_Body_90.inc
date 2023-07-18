!!!mod VerticalInterpolation_90_class -class that manages vertical interpolation
!module VerticalInterpolation_90_class
!module VerticalInterpolation_90_class8
!
!AUTHOR
!     J.W. Blezius MAY 2002 helper on top of the Interp1D library
!
!REVISION
! v1_0    Blezius J.W.          - initial version
! v1_3    Blezius J.W. OCT 2003 - accommodate Extrap1D_Surface (physical data)
! v1_4    Blezius J.W. AUG 2009 - split this file off VerticalInterpolation.ftn90
!
!OBJECT
!        This class encapsulates the environment that controls the vertical
!        interpolation.  In addition to performing the interpolation itself, it
!        invokes any conversion of vertical-level units, according to the type of
!        each grid.
!
!        This class uses the 1D interpolation package to do the calculations.
!        Thus, this is an alternative (higher level) entry point to the 1-D
!        interpolation package.
!
!NOTES
!        The grid which is the source of known values to be interpolated must be
!        ordered:  either ascending or descending.  This constraint is imposed by
!        the Interp1D interpolation package.  If this is combined with the
!        constraint that the VerticalGrid class places on the grid type,
!        N_GRID_TYPE_HYBRID, then the combined constraints require that the
!        grid must be in ascending order.
!
!        Because only one VerticalInterpolation object will ever be used, the
!        'this' concept is not used.
!
!        In principle, the Interp1D routines should be passed 2-D arrays, where
!        the horizontal dimension has been collapsed to a single dimension; such
!        collapsing would be accomplished with the intrinsic function, RESHAPE.
!        However, because the interface is implicit, the compiler will not be
!        able to verify the array dimensions, and the call to RESHAPE is not
!        strictly necessary.
!
!!
  
  use VerticalInterpolationConstants_90
  use VerticalGrid_90_class
  use vGrid_Descriptors, only: vgd_levels
  implicit none

  public N_Videfset, N_Visint, N_Visetopt

  private
  save
                                        ! ensures that the grids have been
  logical :: l_gridsSelected  = .false. ! selected before using them

                                        ! avoids interpolating for nothing
  logical :: l_vLevelsIdentical = .false.

                                        ! the two grids used in the interpolation
  type(T_VerticalGrid), pointer :: o_vGridSource_p, &
                                   o_vGridDestn_p

                                        ! Vertical level cubes.  Units are ln P
                                        ! referenced to 1 mb
  real(real48), allocatable, dimension(:,:,:) :: r_lnPSource_a, &
                                                 r_lnPDestn_a

                                        ! indices to the levels of r_lnPSource_a
                                        ! which are just before the levels of
                                        ! r_lnPDestn_a
  integer, allocatable, dimension(:,:,:) :: n_interpIndex_a

                                        ! (horizontal) dimensions in the
  integer :: n_ni, n_nj                 ! interpolation

  real(real48), allocatable, dimension(:,:) :: r_z0_a, r_ilmo_a, r_hBound_a, &
                                               r_latitude_a

  ! OPTIONS
  procedure (), pointer :: &
                  m_Interp1D_p => null (), & ! the interpolation algorithm to use
                  m_Extrap1D_p => null ()    ! the extrapolation algorithm to use



contains

!!!func N_Videfset - Select the pair of grids to be used for the vertical
!                    interpolation
  integer function N_Videfset(o_vGrid_Destn_p, o_vGrid_Source_p, r_pSurf, r_pSurfLS, &
                              r_z0, r_ilmo, r_hBound, r_lat)
     use app
                                        ! returns error indication:  0='no error'
!
!AUTHOR
!     J.W. Blezius MAY 2002 helper on top of the Interp1D library
!
!REVISION
! v1_0    Blezius J.W.          - initial version
! v1_1    Blezius J.W. SEP 2002 - make all Interp1D* input dim's the same; ditto
!                                 for output
! v1_3    Blezius J.W. OCT 2003 - add 
!
!OBJECT
!        Using a binary search, the location of each level of the target grid is
!        located with respect to the levels of the initial grid. The result, the
!        initial-grid level that is just below each target-grid level, is
!        recorded for future use by the Interpolate routine.
!
!ARGUMENTS
                                        ! the two grids requested
    type(T_VerticalGrid), pointer, intent(in) :: o_vGrid_Destn_p, &
                                                 o_vGrid_Source_p

                                        ! surface pressure at each horiz location
    real(real48), dimension(:,:), intent(in) :: r_pSurf 

    ! only used for SLEEVE coordinates (vcode=5100)
    real(real48), dimension(:,:), optional, intent(in) :: r_pSurfLS

    ! The next four parameters are used only for surface extrapolation
                                        ! roughness length
    real(real48), dimension(:,:), optional, intent(in) :: r_z0
                                        ! inverse Monin-Obukhov length
    real(real48), dimension(:,:), optional, intent(in) :: r_ilmo
                                        ! height of the boundary layer
    real(real48), dimension(:,:), optional, intent(in) :: r_hBound
                                        ! latitude (used only for the wind)
    real(real48), dimension(:,:), optional, intent(in) :: r_lat
!
!NOTES
!        It is assumed that the vertical levels of the o_vGridSource_p are in
!        either ascending or descending order.
!
!        The vertical levels of the o_vGridDestn_p may be in any order.  The
!        determination of the location of each target level is completely
!        independent of all the others.
!
!!

    external Interp1D_FindPos
    integer n_error                     ! receive error from called routines

    logical, parameter :: l_SUPPRESS_MESSAGE = .true.



    N_Videfset = 0                      ! no error yet

    ! Start with a clean slate
    call m_clearGrids(l_SUPPRESS_MESSAGE)

    ! Record the input values to the module
    n_ni = ubound(r_pSurf,1) - lbound(r_pSurf,1) + 1
    n_nj = ubound(r_pSurf,2) - lbound(r_pSurf,2) + 1
    o_vGridSource_p => o_vGrid_Source_p
    o_vGridDestn_p  => o_vGrid_Destn_p

    !
    ! Validate the request
    !
    if(     .not. associated(o_vGridDestn_p) &
       .or. .not. associated(o_vGridSource_p) ) then
      N_Videfset = N_VI_VIERR_UNDEFINED_GRID_REQD
      call lib_log(APP_LIBINTERPV,APP_ERROR,'N_Videfset: One of the requested grids has not been defined')
      call m_clearGrids()
      return
    endif

    !
    ! Allocate arrays
    !
    allocate(r_lnPSource_a(n_ni, n_nj, o_vGridSource_p%N_numVLevels), &
             STAT=n_error)
    if( n_error /= 0) then
      N_Videfset = N_VI_VIERR_FAILED_ALLOCATION
      write(app_msg, *)'N_Videfset: Failed allocating r_lnPSource_a (error=',n_error,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      call m_clearGrids()
      return
    endif

    allocate( r_lnPDestn_a(n_ni, n_nj, o_vGridDestn_p%N_numVLevels),STAT=n_error)
    if( n_error /= 0) then
      N_Videfset = N_VI_VIERR_FAILED_ALLOCATION
      write(app_msg, *)'N_Videfset: Failed allocating r_lnPDestn_a (error=',n_error,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      call m_clearGrids()
      return
    endif

    if (present(r_z0)) then
      allocate(r_z0_a(n_ni, n_nj), STAT=n_error)
      if( n_error /= 0) then
        N_Videfset = N_VI_VIERR_FAILED_ALLOCATION
        write(app_msg, *)'N_Videfset: Failed allocating r_z0_a (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
        call m_clearGrids()
        return
      endif
    endif

    if (present(r_ilmo)) then
      allocate(r_ilmo_a(n_ni, n_nj), STAT=n_error)
      if( n_error /= 0) then
        N_Videfset = N_VI_VIERR_FAILED_ALLOCATION
        write(app_msg, *)'N_Videfset: Failed allocating rr_ilmo_a (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
        call m_clearGrids()
        return
      endif
    endif

    if (present(r_hBound)) then
      allocate(r_hBound_a(n_ni, n_nj), STAT=n_error)
      if( n_error /= 0) then
        N_Videfset = N_VI_VIERR_FAILED_ALLOCATION
        write(app_msg, *)'N_Videfset: Failed allocating r_hBound_a (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
        call m_clearGrids()
        return
      endif
    endif

    if (present(r_lat)) then
      allocate(r_latitude_a(n_ni, n_nj), STAT=n_error)
      if( n_error /= 0) then
        N_Videfset = N_VI_VIERR_FAILED_ALLOCATION
        write(app_msg, *)'N_Videfset: Failed allocating r_latitude_a (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
        call m_clearGrids()
        return
      endif
    endif
    
    !
    ! Create cubes of vertical levels, and convert them to ln P
    !
    n_error=N_VertGridGetLnP(o_vGridSource_p, r_lnPSource_a, r_pSurf, r_pSurfLS)
    if(n_error /= 0) then
      N_Videfset = N_VI_VIERR_LN_PRESS_CONVERSION
      write(app_msg, *)'N_Videfset: Failed converting source to ln(P) (error=',n_error,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      call m_clearGrids()
      return
    endif

    n_error=N_VertGridGetLnP(o_vGridDestn_p, r_lnPDestn_a, r_pSurf, r_pSurfLS)
    if(n_error /= 0) then
      N_Videfset = N_VI_VIERR_LN_PRESS_CONVERSION
      write(app_msg, *)'N_Videfset: Failed converting destination to ln(P) (error=',n_error,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      call m_clearGrids()
      return
    endif


    !
    ! Check to see whether the input and output vertical levels are the same
    !
    if(.not. (o_vGridSource_p /= o_vGridDestn_p) ) then
      l_vLevelsIdentical = .true.
      ! Since no real interpolation will be done, this routine is finished.
    else
      l_vLevelsIdentical = .false.


      allocate(n_interpIndex_a(n_ni, n_nj, o_vGridDestn_p%N_numVLevels), &
               STAT=n_error)
      if( n_error /= 0) then
        N_Videfset = N_VI_VIERR_FAILED_ALLOCATION
        write(app_msg, *)'N_Videfset: Failed allocating n_interpIndex_a (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
        call m_clearGrids()
        return
      endif



      !
      ! CALCULATE THE interpIndex's
      !
      call Interp1D_FindPos(n_ni*n_nj, &
                            o_vGridSource_p%N_numVLevels, &
                            o_vGridDestn_p%N_numVLevels, &
                            n_ni*n_nj, n_ni*n_nj, &

                            r_lnPSource_a, &
                            n_interpIndex_a, &
                            r_lnPDestn_a &
                           )

      ! The interpolation has now been set up and is ready to use
      l_gridsSelected = .true.


      !
      ! Save parameter values
      !
      if (present(r_z0))     r_z0_a       = r_z0
      if (present(r_ilmo))   r_ilmo_a     = r_ilmo
      if (present(r_hBound)) r_hBound_a   = r_hBound
      if (present(r_lat))    r_latitude_a = r_lat

    end if ! o_vGridSource_p /= o_vGridDestn_p

  end function N_Videfset



!!!func N_Visint - performs the selected (scalar or vector) interpolation and
!                  extrapolation
  integer function N_Visint(r_stateOut, r_stateIn, &
                            r_derivOut, r_derivIn, &
                            r_extrapGuideDown, r_extrapGuideUp, &
                            m_slStateValue, m_slFluxGradient, &
                            r_zDest, r_zSrc, &
                            r_y_stateOut, r_y_stateIn, &
                            r_y_derivOut, r_y_derivIn)
     use app
                                        ! returns error indication:  0='no error'
!
!AUTHOR
!     J.W. Blezius MAY 2002 helper on top of the Interp1D library
!
!REVISION
! v1_0    Blezius J.W.          - initial version
! v1_1    Blezius J.W. SEP 2002 - make all Interp1D* input dim's the same; ditto
!                                 for output
! v1_3    Blezius J.W. OCT 2003 - add Extrap1D_Surface
!
!OBJECT
!        This is just a shell routine that performs the selection between the
!        possible interpolation routines.
!
!ARGUMENTS
    !
    ! input and output arrays of the state and derivative, with dimensions as
    ! specified in the calls to N_Viqkdef and N_Videfset
    real(real48), dimension(n_ni, n_nj, o_vGridDestn_p%N_numVLevels), &
                  intent(out) :: r_stateOut
    real(real48), dimension(n_ni, n_nj, o_vGridSource_p%N_numVLevels), &
                  intent(in)  :: r_stateIn
    real(real48), dimension(n_ni, n_nj, o_vGridDestn_p%N_numVLevels), optional, &
                  target, intent(out) :: r_derivOut
    real(real48), dimension(n_ni, n_nj, o_vGridSource_p%N_numVLevels), optional,&
                  target, intent(in)  :: r_derivIn

    ! values used for extrapolating below and above the values in o_vGridSource_p
    ! The meaning of these values depends on the selected extrapolation method.
    real(real48), optional, intent(in) :: r_extrapGuideDown, r_extrapGuideUp

                                        ! s/r to calculate normalized state value
                                        ! at one level within the surface layer
                                        ! ('surface layer' is comprised of the  )
                                        ! (space between the Earth's surface and)
                                        ! (the first model level above it.   )
    procedure (), optional :: m_slStateValue

                                        ! s/r to calculate the normalized flux,
                                        ! and the gradient w.r.t. z
                                        ! at one level within the surface layer
    procedure (), optional :: m_slFluxGradient

                                        ! height (z), in m, above surface of
                                        ! source and destination cubes
    real(real48), dimension(n_ni, n_nj, o_vGridDestn_p%N_numVLevels), &
                                                  optional, intent(in) :: r_zDest
    real(real48), dimension(n_ni, n_nj, o_vGridSource_p%N_numVLevels), &
                                                   optional, intent(in) :: r_zSrc

                                        ! y-components of the vectors
                                        ! (the x-components are in the standard
                                        ! parameters)
    real(real48), dimension(n_ni, n_nj, o_vGridDestn_p%N_numVLevels), optional, &
                                                      intent(out) :: r_y_stateOut
    real(real48), dimension(n_ni, n_nj, o_vGridSource_p%N_numVLevels), optional,&
                                                      intent(in)  :: r_y_stateIn
    real(real48), dimension(n_ni, n_nj, o_vGridDestn_p%N_numVLevels), optional, &
                                                      intent(out) :: r_y_derivOut
    real(real48), dimension(n_ni, n_nj, o_vGridSource_p%N_numVLevels), optional,&
                                                      intent(in)  :: r_y_derivIn
!
!NOTES
!        It is assumed that the first dimension of each of the four arrays
!        matches the number of points used, and that that number is the same as
!        that that was supplied to N_Videfset.  In the case where r_derivIn and
!        r_derivOut aren't needed for the interpolation algorithm, they are not
!        altered and this assumption on these two arrays can be relaxed.
!
!        Special attention should be paid to the units of r_extrapGuideDown and
!        r_extrapGuideUp.  While N_Videfset() automatically converts the units of
!        the vertical levels to ln P, the units of r_extrapGuideDown and
!        r_extrapGuideUp are not adjusted.
!
!        N.B.:  In the case of m_Extrap1D_p=Extrap1D_Surface_X, it is assumed that
!               the lowest vertical level of stateIn represents the surface of
!               the Earth, and that those are true values (at the surface), not
!               those that are obtained from GEM.
!
!        Historical Note:  This routine was initially named Visint, meaning
!        'Vertical Interpolation package, Scalar Interpolation'.  This followed
!        the nomenclature of the ezscint package for horizontal interpolation
!        which contains the analogous routine, ezsint, for scalar interpolation
!        and also the routine, ezuvint, for vector interopolation.  There, the
!        similarity between ezscint and Visint ends:  there is no Viuvint
!        routine.  Instead of duplicating the common functionality of Visint into
!        a new Viuvint routine, the extra functionality of the would-be Viuvint
!        routine was accommodated in Visint using optional parameters.
!
!!
    external Extrap1D_Surface_X,  Extrap1D_SurfaceWind_X
    external Interp1D_CubicLagrange_X, Interp1D_CubicWithDerivs_X

    ! local copies of the parameters.  These ones are guaranteed to exist.  They
    ! are used in cases where only dummies are required, and for local
    ! manipulation of real derivative data.
    real(real48) :: r_extrapGuideDown_local, r_extrapGuideUp_local
    real(real48), dimension(:, :, :), pointer :: r_derivIn_local
    real(real48), dimension(1, 1, 1), target  :: r_derivIn_dummy
    real(real48), dimension(:, :, :), allocatable::r_derivIn_heap,r_derivOut_heap

    real(real48), dimension(:, :, :), pointer :: r_derivOut_local
    real(real48), dimension(1, 1, 1), target  :: r_derivOut_dummy

    real(real48), dimension(:, :, :), allocatable :: r_stateOutTmp

                                        ! flux, gradient at top of surface layer
    real(real48), dimension(:, :), allocatable :: r_ft, r_dtdz, r_y_dtdz, &
                                           r_dzdlnp, r_dtdlnp, r_y_dtdlnp

                                        ! direction of r_ft at the top of the
                                        ! surface layer, in radians
    real(real48), dimension(:, :), allocatable :: r_angleTop
!!
                                        ! inverse of delta-x above and below pt
    real(real48), dimension(:, :), allocatable :: r_inv_dx_above, r_inv_dx_below

                                        ! maximum wind direction change between
    real(real48) :: r_angleMax          ! surface and hBound (in radians) 

                                        ! ADJUSTED indices to the levels of
                                        ! r_lnPSource_a which are just below the
                                        ! levels of r_lnPDestn_a
    integer,dimension(:, :, :), allocatable :: n_interpIndexTmp

    integer :: n_indexSurface           ! index at the Earth's surface
    integer :: n_indexSurface_plus1     ! index at layer above the surface
    integer :: n_indexSurface_plus2
    integer :: n_indexSurface_plus3

    integer :: n_lowIndex, n_highIndex
    integer :: n_vt
    integer :: n_stride


    integer :: n_numExtArraysIn, n_numExtArraysOut
    real(real48), dimension(n_ni, n_nj, 6)  :: r_ExtArraysIn
    real(real48), dimension(:, :, :), allocatable :: r_ExtArraysOut

    real, dimension(2), target :: r_levels_sample
    real, dimension(:), pointer :: r_levels_sample_p
    real, parameter :: r_PSURF_TYPICAL=100000.0
    integer :: i, j, n_error
    integer, dimension(9) :: err


    N_Visint=0                          ! initialize to 'no error'

    if(present(r_derivIn)) then
      r_derivIn_local => r_derivIn
    else
      r_derivIn_local => r_derivIn_dummy
    end if

    if(present(r_derivOut)) then
      r_derivOut_local => r_derivOut
    else
      r_derivOut_local => r_derivOut_dummy
    end if

    if(l_vLevelsIdentical) then
      ! No real interpolation needs to be done.
      ! Just copy the array over.
      r_stateOut = r_stateIn
      if(present(r_derivIn) .and. present(r_derivOut)) then
        r_derivOut = r_derivIn
      end if
      return
    end if

    if (.not. l_gridsSelected) then
      N_Visint=N_VI_VIERR_GRIDS_NOT_SELECTED
      return
    end if


    !
    ! Allocate arrays
    !
    allocate(n_interpIndexTmp(n_ni, n_nj,o_vGridDestn_p%N_numVLevels), &
             STAT=n_error)
    if( n_error /= 0) then
      N_Visint = N_VI_VIERR_FAILED_ALLOCATION
      write(app_msg, *)'N_Visint: failed allocating n_interpIndexTmp (error=',err,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      return
    endif

    allocate(r_ExtArraysOut(n_ni, n_nj, 2*o_vGridDestn_p%N_numVLevels), &
             STAT=n_error)
    if( n_error /= 0) then
      N_Visint = N_VI_VIERR_FAILED_ALLOCATION
      write(app_msg, *)'N_Visint: failed allocating r_ExtArraysOut (error=',err,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      return
    endif


    ! ensure that r_extrapGuideDown and r_extrapGuideUp are defined
    if( present(r_extrapGuideDown) ) then
      r_extrapGuideDown_local = r_extrapGuideDown
    else
      r_extrapGuideDown_local = 0.
    endif

    if( present(r_extrapGuideUp) ) then
      r_extrapGuideUp_local = r_extrapGuideUp
    else
      r_extrapGuideUp_local = 0.
    endif


    !
    ! SURFACE EXTRAPOLATION (and related interpolation)
    ! SURFACE EXTRAPOLATION (and related interpolation)
    ! SURFACE EXTRAPOLATION (and related interpolation)
    !
    if(     associated(m_Extrap1D_p, Extrap1D_Surface_X) &
       .or. associated(m_Extrap1D_p, Extrap1D_SurfaceWind_X)) then

      ! This branch needs the following variables
      err = 0
      allocate(      r_ft(n_ni, n_nj), stat=err(1))
      allocate(    r_dtdz(n_ni, n_nj), stat=err(2))
      allocate(  r_y_dtdz(n_ni, n_nj), stat=err(3))
      allocate(  r_dzdlnp(n_ni, n_nj), stat=err(4))
      allocate(  r_dtdlnp(n_ni, n_nj), stat=err(5))
      allocate(r_y_dtdlnp(n_ni, n_nj), stat=err(6))
      allocate(r_angleTop(n_ni, n_nj), stat=err(7))
      allocate(r_inv_dx_above(n_ni, n_nj), stat=err(8))
      allocate(r_inv_dx_below(n_ni, n_nj), stat=err(9))
        if(any(err .ne. 0)) then
          write(app_msg, *)'N_Visint: allocation error (error=',err,')'
          call lib_log(APP_LIBINTERPV,APP_FATAL,app_msg)
          call qqexit(2)
        end if

      ! First, check to see that the required optional parameters are present
      if(     .not. present(m_slStateValue) &
         .or. .not. present(m_slFluxGradient) &
         .or. .not. present(r_zSrc) &
         .or. .not. present(r_zDest) &
         .or. .not. allocated(r_z0_a) &
         .or. .not. allocated(r_ilmo_a) &
         .or. .not. allocated(r_hBound_a) &
        ) then
        call lib_log(APP_LIBINTERPV,APP_ERROR,'N_Visint:  surface extrapolation requires parameters m_slStateValue, &
           &m_slFluxGradient, r_zSrc, r_zDest')
        call lib_log(APP_LIBINTERPV,APP_ERROR,'N_Visint:  Videfset requires parameters r_z0, r_ilmo, and r_hBound')
        N_Visint = N_VI_VIERR_MISSING_SURFACE_DATA
        return
      end if

      ! Verify the presence of the parameters that are needed for the wind
      if(associated(m_Extrap1D_p, Extrap1D_SurfaceWind_X)) then
        if(     .not. present(r_y_stateOut) &
           .or. .not. present(r_y_stateIn) &
           .or. .not. allocated(r_latitude_a) &
          ) then
            call lib_log(APP_LIBINTERPV,APP_ERROR,'N_Visint:  surface extrapolation  of the wind requires &
               &r_y_stateOut and r_y_stateIn')
            call lib_log(APP_LIBINTERPV,APP_ERROR,'N_Visint:  Videfset requires parameters r_latitude')
          N_Visint = N_VI_VIERR_MISSING_SURFACE_DATA
          return
        end if
      end if


      ! OBTAIN THE NORMALIZED FLUX, & THE GRADIENT AT THE TOP OF THE SURFACE LAYER

      ! Are the vertical levels increasing with index?
      r_levels_sample_p => r_levels_sample
      n_error=vgd_levels(o_vGridSource_p%O_vGridDesc_p, &
                         o_vGridSource_p%N_ip1_p(1:2), &
                         r_levels_sample_p, &
                         r_PSURF_TYPICAL)
      if( r_levels_sample(2) > r_levels_sample(1) ) then
        ! The vertical level values INcrease with the index.
        n_indexSurface       = 1
        n_indexSurface_plus1 = 2
        n_indexSurface_plus2 = 3
        n_indexSurface_plus3 = 4
      else ! not increasing levels
        n_indexSurface       = o_vGridSource_p%N_numVLevels
        n_indexSurface_plus1 = n_indexSurface - 1
        n_indexSurface_plus2 = n_indexSurface - 2
        n_indexSurface_plus3 = n_indexSurface - 3
      endif

      ! Prepare to convert the gradient from dt/dz to dt/(d ln P):
      !    dt/(d ln P) = dz/(d ln dP) . dt/dz
      n_stride = n_indexSurface_plus1 - n_indexSurface
      r_dzdlnp = r_finiteDeriv(r_lnPSource_a(:,:,n_indexSurface: &
                                                 n_indexSurface_plus2: &
                                                 n_stride), &
                                      r_zSrc(:,:,n_indexSurface: &
                                                 n_indexSurface_plus2: &
                                                 n_stride) &
                            )

      if(associated(m_Extrap1D_p, Extrap1D_Surface_X)) then
        call m_slFluxGradient(r_ft, &
                              r_dtdz, &
                              r_stateIn(:,:,n_indexSurface_plus1), &
                              r_stateIn(:,:,n_indexSurface), &
                              r_zSrc(:,:,n_indexSurface_plus1), &
                              r_z0_a, &
                              r_ilmo_a, &
                              r_hBound_a, &
                              n_ni*n_nj)

                                        ! Convert the gradient from dt/dz
        r_dtdlnp = r_dzdlnp * r_dtdz    ! to dt/(d lnP)

      else ! associated(m_Extrap1D_p, Extrap1D_SurfaceWind_X)
        call m_slFluxGradient(r_ft, r_dtdz, r_y_dtdz, r_angleTop, r_angleMax, &
                              r_stateIn  (:,:,n_indexSurface_plus1), &
                              r_y_stateIn(:,:,n_indexSurface_plus1), &
                              r_zSrc     (:,:,n_indexSurface_plus1), &
                              r_z0_a, &
                              r_ilmo_a, &
                              r_hBound_a, &
                              r_latitude_a, &
                              n_ni*n_nj)
                                        !Use extrap'n guide obtained from physics
        r_extrapGuideDown_local = r_angleMax

                                        ! Convert the gradients from dt/dz
        r_dtdlnp   = r_dzdlnp * r_dtdz  ! to dt/(d lnP)
        r_y_dtdlnp = r_dzdlnp * r_y_dtdz
      end if ! associated(m_Extrap1D_p, Extrap1D_Surface_X)


      ! CUBIC_INTERP_LAGRANGE
      if (associated(m_Interp1D_p, Interp1D_CubicLagrange_X)) then
        ! m_interpLagrange_OneComponent will use derivatives, but the context of
        ! Interp1D_CubicLagrange_X does not presume that the user has supplied
        ! any.  Therefore, the derivative array is created now.  Furthermore,
        ! r_stateOutTmp will be needed.  Create that too.
        err = 0
        allocate(r_derivIn_heap(n_ni, n_nj, o_vGridSource_p%N_numVLevels), &
                 stat=err(1))
        allocate(r_derivOut_heap(n_ni, n_nj, o_vGridDestn_p%N_numVLevels), &
                 stat=err(2))
        allocate(r_stateOutTmp(n_ni, n_nj, o_vGridDestn_p%N_numVLevels), &
                 stat=err(3))
        if(any(err .ne. 0)) then
          write(app_msg, *)'N_Visint: allocation error (error=',err(1),err(2),err(3),')'
          call lib_log(APP_LIBINTERPV,APP_FATAL,app_msg)
          call qqexit(2)
        end if

        ! Interpolate the x-component, joining smoothly to the extrapolation
        call m_interpLagrange_OneComponent(r_stateOut, r_stateIn, r_dtdlnp)

        if(associated(m_Extrap1D_p, Extrap1D_SurfaceWind_X)) then
        ! Interpolate the y-component, joining smoothly to the extrapolation
          call m_interpLagrange_OneComponent(r_y_stateOut,r_y_stateIn,r_y_dtdlnp)
        end if

        deallocate(r_derivIn_heap, r_derivOut_heap, r_stateOutTmp)


      ! CUBIC_INTERP_WITH_DERIVS
      else if (associated(m_Interp1D_p, Interp1D_CubicWithDerivs_X)) then
        if( present(r_derivIn) .and. present(r_derivOut)) then

          ! Force derivative to be continuous at edge of surface extrapolation
          r_derivIn_local(:,:,n_indexSurface_plus1) = r_dtdlnp

          call Interp1D_CubicWithDerivs_X(n_ni*n_nj, o_vGridSource_p%N_numVLevels,&
                                          o_vGridDestn_p%N_numVLevels, &
                                          n_ni*n_nj, n_ni*n_nj, &

                                          r_lnPSource_a,r_stateIn,r_derivIn_local,&
                                          n_interpIndex_a,r_lnPDestn_a,r_stateOut,&
                                          r_derivOut_local, &

                                          .false., .false., &
                                          r_extrapGuideDown_local, &
                                          r_extrapGuideUp_local, &

                                          m_slFluxGradient, 0, 0, &
                                          r_ExtArraysIn, r_ExtArraysOut &
                                         )

          if(associated(m_Extrap1D_p, Extrap1D_SurfaceWind_X)) then
            ! INTERPOLATE THE OTHER COMPONENT OF THE VECTOR
            if( present(r_y_derivIn) .and. present(r_y_derivOut)) then
              r_derivIn_local = r_y_derivIn
              ! Force derivative to be continuous at edge of surface extrapolation
              r_derivIn_local(:,:,n_indexSurface_plus1) = r_y_dtdlnp
              call Interp1D_CubicWithDerivs_X( &
                                        n_ni*n_nj, o_vGridSource_p%N_numVLevels,&
                                        o_vGridDestn_p%N_numVLevels, &
                                        n_ni*n_nj, n_ni*n_nj, &

                                        r_lnPSource_a,r_y_stateIn,r_derivIn_local,&
                                        n_interpIndex_a,r_lnPDestn_a,r_y_stateOut,&
                                        r_y_derivOut, &

                                        .false., .false., &
                                        r_extrapGuideDown_local, &
                                        r_extrapGuideUp_local, &

                                        m_slFluxGradient, 0, 0, &
                                        r_ExtArraysIn, r_ExtArraysOut &
                                       )

            else ! r_y_derivIn or r_y_derivOut is not present
              write(app_msg, *)'N_Visint: Cubic interpolation with derivatives missing y-component derivatives'
              call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
              N_Visint=N_VI_VIERR_BAD_INTERPTYP_4_DATA
            end if ! r_y_derivIn or r_y_derivOut present
          end if ! Extrap1D_SurfaceWind_X

        else ! r_derivIn or r_derivOut is not present
          write(app_msg, *)'N_Visint: Cubic interpolation with derivatives missing derivatives'
          call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
          N_Visint=N_VI_VIERR_BAD_INTERPTYP_4_DATA
        end if ! ! r_derivIn or r_derivOut present
      end if ! Interp1D_CubicLagrange_X .or. Interp1D_CubicWithDerivs_X

      ! NOW DO THE SURFACE EXTRAPOLATION PROPER
      if(associated(m_Extrap1D_p, Extrap1D_Surface_X)) then
        n_numExtArraysIn = 4
        n_numExtArraysOut = 0
        r_ExtArraysIn(:,:,1) = r_z0_a
        r_ExtArraysIn(:,:,2) = r_ilmo_a
        r_ExtArraysIn(:,:,3) = r_hBound_a
        r_ExtArraysIn(:,:,4) = r_ft
        call Extrap1D_Surface_X(n_ni*n_nj, o_vGridSource_p%N_numVLevels, &
                                o_vGridDestn_p%N_numVLevels, &
                                n_ni*n_nj, n_ni*n_nj, &

                                r_zSrc, r_stateIn, r_derivIn_local, &
                                n_interpIndex_a, r_zDest, r_stateOut, &
                                                                r_derivOut_local, &

                                .true., .true., &
                                r_extrapGuideDown_local, r_extrapGuideUp_local, &

                                m_slStateValue, &
                                n_numExtArraysIn, n_numExtArraysOut, &
                                r_ExtArraysIn, r_ExtArraysOut &
                               )

      else ! associated(m_Extrap1D_p, Extrap1D_SurfaceWind_X)
        n_numExtArraysIn = 6
        n_numExtArraysOut = 2 * o_vGridDestn_p%N_numVLevels
        r_ExtArraysIn(:,:,1) = r_z0_a
        r_ExtArraysIn(:,:,2) = r_ilmo_a
        r_ExtArraysIn(:,:,3) = r_hBound_a
        r_ExtArraysIn(:,:,4) = r_ft
        r_ExtArraysIn(:,:,5) = r_angleTop
        r_ExtArraysIn(:,:,6) = r_latitude_a

        r_ExtArraysOut(:,:,1:o_vGridDestn_p%N_numVLevels) = r_y_stateOut
        r_ExtArraysOut(:,:,o_vGridDestn_p%N_numVLevels+1: &
                           2*o_vGridDestn_p%N_numVLevels   ) = r_y_derivOut
        call Extrap1D_SurfaceWind_X( &
                                n_ni*n_nj, o_vGridSource_p%N_numVLevels, &
                                o_vGridDestn_p%N_numVLevels, &
                                n_ni*n_nj, n_ni*n_nj, &

                                r_zSrc, r_stateIn, r_derivIn_local, &
                                n_interpIndex_a, r_zDest, r_stateOut, &
                                                                r_derivOut_local, &

                                .true., .true., &
                                r_extrapGuideDown_local, r_extrapGuideUp_local, &

                                m_slStateValue, &
                                n_numExtArraysIn, n_numExtArraysOut, &
                                r_ExtArraysIn, r_ExtArraysOut &
                               )

        r_y_stateOut = r_ExtArraysOut(:,:,1:o_vGridDestn_p%N_numVLevels)
        r_y_derivOut = r_ExtArraysOut(:,:,o_vGridDestn_p%N_numVLevels+1: &
                                          2*o_vGridDestn_p%N_numVLevels)
      end if ! associated(m_Extrap1D_p, Extrap1D_Surface_X)

      deallocate(      r_ft)
      deallocate(    r_dtdz)
      deallocate(  r_y_dtdz)
      deallocate(  r_dzdlnp)
      deallocate(  r_dtdlnp)
      deallocate(r_y_dtdlnp)
      deallocate(r_angleTop)
      deallocate(r_inv_dx_above)
      deallocate(r_inv_dx_below)
    !
    ! end of: SURFACE EXTRAPOLATION (and related interpolation)
    ! end of: SURFACE EXTRAPOLATION (and related interpolation)
    !

    else ! not surface

      !
      ! NORMAL INTERPOLATION
      ! NORMAL INTERPOLATION
      ! NORMAL INTERPOLATION
      !

      ! Setting extrapEnableDown and extrapEnableUp to .false. yields 'clamped'
      ! extrapolation --> no need to do it later.
      !
      call m_Interp1D_p(n_ni*n_nj, o_vGridSource_p%N_numVLevels, &
                        o_vGridDestn_p%N_numVLevels, &
                        n_ni*n_nj, n_ni*n_nj, &

                        r_lnPSource_a,r_stateIn,r_derivIn_local, &
                        n_interpIndex_a,r_lnPDestn_a,r_stateOut,r_derivOut_local,&

                        .false., .false., &
                        r_extrapGuideDown_local, &
                        r_extrapGuideUp_local, &

                        m_slFluxGradient, 0, 0, &
                        r_ExtArraysIn, r_ExtArraysOut &
                       )


      !
      ! NORMAL EXTRAPOLATION
      ! NORMAL EXTRAPOLATION
      ! NORMAL EXTRAPOLATION
      !
      call m_Extrap1D_p(n_ni*n_nj, o_vGridSource_p%N_numVLevels, &
                        o_vGridDestn_p%N_numVLevels, &
                        n_ni*n_nj, n_ni*n_nj, &

                        r_lnPSource_a,r_stateIn,r_derivIn_local, &
                        n_interpIndex_a, &
                        r_lnPDestn_a,r_stateOut,r_derivOut_local,&

                        .true., .true., &
                        r_extrapGuideDown_local, &
                        r_extrapGuideUp_local, &

                        m_slFluxGradient, 0, 0, &
                        r_ExtArraysIn, r_ExtArraysOut &
                       )
    end if

    if( allocated(n_interpIndexTmp) ) then
      deallocate(n_interpIndexTmp, STAT=n_error)
      if( n_error /= 0 ) then
        write(app_msg, *)'N_Visint: Error deallocating n_interpIndexTmp (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      endif
    endif

    if( allocated(r_ExtArraysOut) ) then
      deallocate(r_ExtArraysOut, STAT=n_error)
      if( n_error /= 0 ) then
        write(app_msg, *)'N_Visint: Error deallocating r_ExtArraysOut (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      endif
    endif




  contains
!!!s/r m_interpLagrange_OneComponent - interpolate one vector component
    subroutine m_interpLagrange_OneComponent(r_stOut, r_stIn, r_dtdlnp)
!
!AUTHOR
!     J.W. Blezius OCT 2003
!
!REVISION
! v1_3    Blezius J.W. OCT 2003 - initial version
!
!OBJECT
!        To interpolate a scalar (which is in reality a single component of a
!        vector), using the cubic Lagrange algorithm.  The lowest interval is
!        then re-interpolated using the cubic-with-derivatives algorithm so as to
!        smooth the meeting with the extrapolation which itself determines the
!        gradient at the joint.
!
!ARGUMENTS
      real(real48), dimension(n_ni, n_nj, o_vGridDestn_p%N_numVLevels), &
                    intent(out) :: r_stOut
      real(real48), dimension(n_ni, n_nj, o_vGridSource_p%N_numVLevels), &
                    intent(in)  :: r_stIn
      real(real48), dimension(n_ni, n_nj) :: r_dtdlnp
!
!NOTES
!
!!

      ! Interpolate
      call Interp1D_CubicLagrange_X(n_ni*n_nj, o_vGridSource_p%N_numVLevels, &
                                    o_vGridDestn_p%N_numVLevels, &
                                    n_ni*n_nj, n_ni*n_nj, &

                                    r_lnPSource_a, r_stIn, r_derivIn_heap, &
                                    n_interpIndex_a, r_lnPDestn_a, r_stOut, &
                                                              r_derivOut_heap, &

                                    .false., .false., &
                                    r_extrapGuideDown_local, &
                                    r_extrapGuideUp_local, &

                                    m_slFluxGradient, 0, 0, &
                                    r_ExtArraysIn, r_ExtArraysOut &
                                   )

      ! Smooth the transition to the extrapolation region

      ! Force derivative to be continuous at edge of surface extrapolation
      r_derivIn_heap(:,:,n_indexSurface_plus1) = r_dtdlnp

      ! Caluclate a derivative at n_indexSurface_plus2
      n_stride = n_indexSurface_plus1 - n_indexSurface
      r_derivIn_heap(:,:,n_indexSurface_plus2) = r_finiteDeriv( &
                                        r_lnPSource_a(:,:,n_indexSurface_plus1: &
                                                          n_indexSurface_plus3: &
                                                          n_stride), &
                                               r_stIn(:,:,n_indexSurface_plus1: &
                                                          n_indexSurface_plus3: &
                                                          n_stride) &
                                              )

      ! Now exploit derivatives to RE-interpolate, below n_indexSurface_plus2
                                        ! Determine the region affected
      n_lowIndex  = min(n_indexSurface_plus1, n_indexSurface_plus2)
      n_highIndex = max(n_indexSurface_plus1, n_indexSurface_plus2)

                                        ! Adjust indices into that region
      n_interpIndexTmp =   n_interpIndex_a - (n_lowIndex-1)

                                        ! Re-interpolate the whole (scalar) field
                                        ! (Use just a section of the arrays since
                                        ! r_derivIn is not set elsewhere.)
      call Interp1D_CubicWithDerivs_X(n_ni*n_nj, 2, &
                                   o_vGridDestn_p%N_numVLevels, &
                                   n_ni*n_nj, n_ni*n_nj, &

                                   r_lnPSource_a(:,:,n_lowIndex:n_highIndex), &
                                   r_stIn       (:,:,n_lowIndex:n_highIndex), &
                                   r_derivIn_heap (:,:,n_lowIndex:n_highIndex), &
                                   n_interpIndexTmp, &
                                   r_lnPDestn_a, &
                                   r_stateOutTmp, &
                                   r_derivOut_heap, &

                                   .false., .false., &
                                   r_extrapGuideDown_local, &
                                   r_extrapGuideUp_local, &

                                   m_slFluxGradient, 0, 0, &
                                   r_ExtArraysIn, r_ExtArraysOut &
                                  )
                                        ! Keep results below indexSurface_plus2
      if (n_indexSurface_plus1 > n_indexSurface) then
        ! The vertical level values INcrease with the index.
        do n_vt = 1, o_vGridDestn_p%N_numVLevels
          do j = 1,n_nj
            do i = 1,n_ni
              if (n_interpIndex_a(i,j,n_vt) < n_indexSurface_plus2) then
                r_stOut(i,j,n_vt) = r_stateOutTmp(i,j,n_vt)
              end if
            end do
          end do
        end do
      else ! not increasing levels
        do n_vt = 1, o_vGridDestn_p%N_numVLevels
          do j = 1,n_nj
            do i = 1,n_ni
              if (n_interpIndex_a(i,j,n_vt) >= n_indexSurface_plus2) then
                r_stOut(i,j,n_vt) = r_stateOutTmp(i,j,n_vt)
              end if
            end do
          end do
        end do
      end if ! increasing levels

    end subroutine m_interpLagrange_OneComponent



!!!func r_finiteDeriv - calculate a derivative
    function r_finiteDeriv(r_x, r_y)
!
!AUTHOR
!     J.W. Blezius OCT 2003 
!
!REVISION
! v1_3    Blezius J.W. OCT 2003 - initial version
!
!OBJECT
!        Using finite differences, calculate the derivative of r_y w.r.t. r_x at
!        r_x(2) based on an average of the derivatives over r_x(1:2) and
!        r_x(2:3), and this for every point in the first two dimensions.
!
!ARGUMENTS
      real(real48), dimension(:,:,:), intent(in) :: r_x
      real(real48), dimension(:,:,:), intent(in) :: r_y
      real(real48), dimension(ubound(r_x,1), ubound(r_x,2)) :: r_finiteDeriv
!
!NOTES
!

      r_inv_dx_above = 1.d0 / (  r_x(:,:,3) - r_x(:,:,2))
      r_inv_dx_below = 1.d0 / (  r_x(:,:,2) - r_x(:,:,1))

      r_finiteDeriv = 0.5d0 * (  r_y(:,:,3) * (r_inv_dx_above) &
                               + r_y(:,:,2) * (r_inv_dx_below - r_inv_dx_above)&
                               - r_y(:,:,1) * (r_inv_dx_below) &
                              )
    end function r_finiteDeriv

  end function N_Visint



!!!func N_Visetopt - set an option
  integer function N_Visetopt(s_option, s_value)
                                        ! returns error indication:  0='no error'
!
!AUTHOR
!     J.W. Blezius MAY 2002 helper on top of the Interp1D library
!
!REVISION
! v1_0    Blezius J.W.          - initial version
!
!OBJECT
!        To set options in the vertical interpolation class.  The option and the
!        value to which it is to be set are passed as character strings.  The
!        strings are identified (in a case-sensitive manner!) and the identified
!        option is set.  It remains set until this routine is called again.
!
!ARGUMENTS
    character(len=*), intent(in) :: s_option
    character(len=*), intent(in) :: s_value
!
!NOTES
!        BEWARE:  Due to the lack of a tolower function, the strings are case
!                 sensitive.  To make it easier, they are all in lower case.
!
!!

    external Extrap1D_LapseRate_X, Extrap1D_Fixed_X, Extrap1D_Surface_X
    external Extrap1D_SurfaceWind_X, Extrap1D_Abort_X, Interp1D_CubicLagrange_X
    external Interp1D_CubicWithDerivs_X, Interp1D_Linear_X
    external Interp1D_NearestNeighbour_X

    N_Visetopt = 0                      ! initialize to 'no error'

    ! IDENTIFY THE OPTION TO BE SET
    !
    select case (s_option)
    case ('interptype')
      select case (s_value)
      case ('nearestneighbour')
        m_Interp1D_p => Interp1D_NearestNeighbour_X
      case ('linear')
        m_Interp1D_p => Interp1D_Linear_X
      case ('cubicwithderivs')
        m_Interp1D_p => Interp1D_CubicWithDerivs_X
      case ('cubiclagrange')
        m_Interp1D_p => Interp1D_CubicLagrange_X
      case default
        N_Visetopt = N_VI_VIERR_UNRECOGNIZED_VALUE
      end select

    case ('extraptype')
      select case (s_value)
      case ('clamped')
        m_Extrap1D_p => Extrap1D_Clamped_X
      case ('lapserate')
        m_Extrap1D_p => Extrap1D_LapseRate_X
      case ('fixed')
        m_Extrap1D_p => Extrap1D_Fixed_X
      case ('abort')
        m_Extrap1D_p => Extrap1D_Abort_X
      case ('surfacewind')
        m_Extrap1D_p => Extrap1D_SurfaceWind_X
      case ('surface')
        m_Extrap1D_p => Extrap1D_Surface_X
      case default
        N_Visetopt = N_VI_VIERR_UNRECOGNIZED_VALUE
      end select

    case default
      N_Visetopt = N_VI_VIERR_UNRECOGNIZED_OPTION
    end select

  end function N_Visetopt




!!!s/r Extrap1D_Clamped_X - a routine of the correct syntax that does nothing
  subroutine Extrap1D_Clamped_X(numInterpSets, srcNumLevels, destNumLevels, &
                                src_ijDim, dst_ijDim, &

                                vLevelSource, stateSource, stateDerivSource, &
                                posnDestInSrc, &
                                vLevelDestn,stateDestn,stateDerivDestn,&

                                extrapEnableDown, extrapEnableUp, &
                                extrapGuideDown, extrapGuideUp, &

                                flux, numExtArraysIn, numExtArraysOut, &
                                ExtArraysIn, ExtArraysOut &
                               )
!
!AUTHOR
!     J.W. Blezius AUG 2015
!
!OBJECT
!        In order to accommodate the generic extrapolation call,
!        "call m_Extrap1D_p(...)" for the particular case where nothing needs to be
!        done, this routine does nothing, but it does it with exactly the correct
!        syntax.
!
!ARGUMENTS
      integer, intent(in) :: numInterpSets
      integer, intent(in) :: srcNumLevels
      integer, intent(in) :: destNumLevels

      integer, intent(in) :: src_ijDim
      integer, intent(in) :: dst_ijDim

      real(real48),dimension(src_ijDim,srcNumLevels),intent(in)::vLevelSource
      real(real48),dimension(src_ijDim,srcNumLevels),intent(in)::stateSource
      real(real48),dimension(src_ijDim,srcNumLevels),intent(in)::stateDerivSource

      integer,     dimension(dst_ijDim,destNumLevels),intent(in)::posnDestInSrc
      real(real48),dimension(dst_ijDim,destNumLevels),intent(in)::vLevelDestn
      real(real48),dimension(dst_ijDim,destNumLevels),intent(out)::stateDestn
      real(real48),dimension(dst_ijDim,destNumLevels),intent(out)::stateDerivDestn

      logical,      intent(in) :: extrapEnableDown, extrapEnableUp
      real(real48), intent(in) :: extrapGuideDown,  extrapGuideUp

      external flux

      integer, intent(in)::numExtArraysIn
      integer, intent(in)::numExtArraysOut
      real(real48),dimension(src_ijDim,numExtArraysIn) ,intent(in) ::ExtArraysIn
      real(real48),dimension(dst_ijDim,numExtArraysOut),intent(out)::ExtArraysOut
!
!NOTES
!
!!

      return ! Do nothing:  it has already been done during interpolation

      ! Trick the compiler:  it expects intent(out) parameters to be set
      stateDestn(1,1)=stateDestn(1,1)
      stateDerivDestn(1,1)=stateDerivDestn(1,1)
      ExtArraysOut(1,numExtArraysOut)=ExtArraysOut(1,numExtArraysOut)
      
    end subroutine Extrap1D_Clamped_X



!!!s/r m_clearGrids - clears the selection of grids
  subroutine m_clearGrids(l_suppressMessage)
    use app
!
!AUTHOR
!     J.W. Blezius MAY 2002 helper on top of the Interp1D library
!
!REVISION
! v1_0    Blezius J.W.          - initial version
!
!OBJECT
!        This is just a simple utility for performing an operation that is needed
!        frequently in this module, generally after an error has been detected.
!        The user is warned of the status, the two target pointers are nullified,
!        and the flag is set to indicate this.
!
!ARGUMENTS
    logical, optional :: l_suppressMessage
!
!NOTES
!        The value of l_suppressMessage is ignored.  Only the presence of this
!        argument is tested, and if present it is assumed to be true.
!
!!
    integer :: n_error

    if( .not. present(l_suppressMessage) ) &
       call lib_log(APP_LIBINTERPV,APP_WARNING,'m_clearGrids: Interpolation is now undefined, call N_Videfset')

    nullify(o_vGridSource_p, o_vGridDestn_p)

    if( allocated(r_lnPSource_a) ) then
      deallocate(r_lnPSource_a, STAT=n_error)
      if( n_error /= 0 ) then
        write(app_msg, *)'m_clearGrids: Error deallocating m_clearGrids (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      endif
    endif

    if( allocated(r_lnPDestn_a) ) then
      deallocate(r_lnPDestn_a, STAT=n_error)
      if( n_error /= 0 ) then
        write(app_msg, *)'m_clearGrids: Error deallocating r_lnPDestn_a (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      endif
    endif

    if( allocated(n_interpIndex_a) ) then
      deallocate(n_interpIndex_a, STAT=n_error)
      if( n_error /= 0 ) then
        write(app_msg, *)'m_clearGrids: Error deallocating n_interpIndex_a (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      endif                      
    endif

    if( allocated(r_z0_a) ) then
      deallocate(r_z0_a, STAT=n_error)
      if( n_error /= 0 ) then
        write(app_msg, *)'m_clearGrids: Error deallocating r_z0_a (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      endif
    endif

    if( allocated(r_ilmo_a) ) then
      deallocate(r_ilmo_a, STAT=n_error)
      if( n_error /= 0 ) then
        write(app_msg, *)'m_clearGrids: Error deallocating r_ilmo_a (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      endif
    endif

    if( allocated(r_hBound_a) ) then
      deallocate(r_hBound_a, STAT=n_error)
      if( n_error /= 0 ) then
        write(app_msg, *)'m_clearGrids: Error deallocating r_hBound_a (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      endif
    endif

    if( allocated(r_latitude_a) ) then
      deallocate(r_latitude_a, STAT=n_error)
      if( n_error /= 0 ) then
        write(app_msg, *)'m_clearGrids: Error deallocating r_latitude_a (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      endif
    endif

    l_gridsSelected = .false.           ! ViSelectGrids must be called again
  end subroutine m_clearGrids

!end module VerticalInterpolation_90_class
!end module VerticalInterpolation_90_class8
