! Select the version of the code to be tested:

!!$#define test48 4
#define test48 8
#define VerticalGrid_90_class VerticalGrid_90_class8
#define VerticalInterpolation_90_class VerticalInterpolation_90_class8

#define TOCTOC_FILENUM 9

!!!prog Test_Vertical_Interpolation -program that automates testing of ez_interpv
program Test_Vertical_Interpolation
!
!AUTHOR
!     J.W. Blezius OCT 2003
!
!REVISION
! v1_3    Blezius J.W. OCT 2003 - formalized from existing non-automatic test
!    ?    Blezius J.W. FEB 2010 - improve test values for normalized hybrid
!                               - add test for (new) un-normalized hybrid
!                               - remove test for the defunct pre-X interface
!
!OBJECT
!        To test the ez_interpv package.
!
!ARGUMENTS
!
!NOTES
!

!!
  use VerticalGrid_90_class
  use VerticalInterpolation_90_class
  implicit none



  external m_slStateValueStub,     m_slFluxGradientStub
  external m_slStateValueWindStub, m_slFluxGradientWindStub

  real(test48), parameter :: r_HMIN = 30.
  integer, parameter :: n_PTS_INIT=4
  integer, parameter :: n_PTS_TARGET=5
  integer, parameter :: n_NI=2, &  ! sin and tan
                        n_NJ=1
  integer :: i, j, k
  integer :: error

  character(60) :: s_title, s_interpType, s_extrapType
  logical :: l_pass
  integer :: n_gridType, n_gridTypeIn, n_gridTypeOut
  real(test48), dimension(n_PTS_INIT) :: r_levelsInit
  real(test48), dimension(n_PTS_TARGET) :: r_levelsTarget
  real(test48), dimension(n_NI,n_NJ,n_PTS_INIT) :: &
                                           r_stateIncreasing, r_stateDecreasing,&
                                           r_stateIn, &
                                           r_derivIncreasing, r_derivDecreasing,&
                                           r_derivIn, r_y_derivIn, &
                                           r_zSrc, r_temp3, r_y_stateIn
  real(test48), dimension(n_NI,n_NJ,n_PTS_TARGET) :: &
                                             r_stateAnswer, r_derivAnswer, &
                                             r_zDest, &
                                             r_y_stateAnswer, r_y_derivAnswer
  real(test48), dimension(1,1,21) :: r_stateIn_21,     r_derivIn_21, &
                                     r_stateAnswer_21, r_derivAnswer_21

  real(test48), parameter :: r_EXTRAP_GUIDE_DOWN=0.4, &
                             r_EXTRAP_GUIDE_UP=-0.5

  real, parameter :: r_PTOP_INIT=10., &
                     r_PREF_INIT=800., &
                     r_RCOEFF_INIT=1., &

                     r_PTOP_TARGET=10., &
                     r_PREF_TARGET=800., &
                     r_RCOEFF_TARGET=1.

  real, parameter :: R_FACTN = 1.2

  real(test48), dimension(n_NI, n_NJ), parameter :: r_PSURF   = 100000.
  real(test48), dimension(1,    1),    parameter :: r_PSURF_1 = 100000.

                                        ! angle, in radians, INCREASING
  real(test48), dimension(n_PTS_INIT), parameter :: r_LEVELS_INCREASING= &
                                                       (/0.64, 1.25, 2.44, 2.97/)
                                        ! angle, in radians, standard values
  real(test48), dimension(n_PTS_TARGET), parameter :: r_LEVELS_TARGET_STD= &
                                                   (/1.13, 2.62, 2.79, 0.5, 3.1/)

  ! The next four parameters are used only for surface extrapolation
                                        ! roughness length
  real(test48), dimension(n_NI, n_NJ) :: r_z0
                                        ! inverse Monin-Obukhov length
  real(test48), dimension(n_NI, n_NJ) :: r_ilmo
                                        ! height of the boundary layer
  real(test48), dimension(n_NI, n_NJ) :: r_hBound
                                        ! latitude (used only for the wind)
  real(test48), dimension(n_NI, n_NJ) :: r_lat

  integer, external :: fnom, fstouv, fstfrm


  ! Possible values of the gridType.
  ! These values are the same as those used in CONVIP (except for eta) at the
  ! time of writing.  (However, future compatibility with CONVIP is not
  ! guaranteed.)
  integer, parameter :: N_GRID_TYPE_SIGMA    = 1, & ! P/Ps
                        N_GRID_TYPE_PRESSURE = 2, & ! in mb
                        N_GRID_TYPE_HYBRID   = 5, & ! NORMALIZED hybrid (i.e. hybrid type 1)
                        N_GRID_TYPE_ETA      = 7, & !(Pt-P)/(Pt-Ps) -not in convip
                                                    ! UNnormalized hybrid (i.e. hybrid type 5, version 1)
                        N_GRID_TYPE_HYBRID_NOTNORM = 8, &
                        N_GRID_TYPE_STAGGERED = 9, &! Staggered (i.e. hybrid type 5, version 2)
                        N_GRID_TYPE_STAG5005  = 5005  ! Vcode=5005 (i.e. hybrid type 5, version 5)



  ! Open the file that defines a vgrid
  error = fnom(TOCTOC_FILENUM, 'toctoc_5005', 'STD+RND+OLD+R/O', 0)
  if (error /= 0)write(6,*)"ERROR opening toctoc_5005:  error=", error

  ! Prepare the file for accessing it
  error = fstouv(TOCTOC_FILENUM, 'RND') ! returns no. of records or error
  if(error < 0)write(6,*)"ERROR initializing toctoc_5005:  error=", error



  ! ascending
  r_stateIncreasing(1,1,1) = 0.5971954   ! sin 0.64
  r_stateIncreasing(1,1,2) = 0.9489846   ! sin 1.25
  r_stateIncreasing(1,1,3) = 0.6454      ! sin 2.44
  r_stateIncreasing(1,1,4) = 0.1708      ! sin 2.97

  r_derivIncreasing(1,1,1) = 0.8020958   ! cos 0.64
  r_derivIncreasing(1,1,2) = 0.3153224   ! cos 1.25
  r_derivIncreasing(1,1,3) =-0.7638      ! cos 2.44
  r_derivIncreasing(1,1,4) =-0.9853      ! cos 2.97


  r_stateIncreasing(2,1,1) = 0.744544    ! tan 0.64
  r_stateIncreasing(2,1,2) = 3.009570    ! tan 1.25
  r_stateIncreasing(2,1,3) =-0.8450      ! tan 2.44
  r_stateIncreasing(2,1,4) =-0.1733      ! tan 2.97

  r_derivIncreasing(2,1,1) = 1.554346    ! 1/cos2 0.64
  r_derivIncreasing(2,1,2) = 10.057510   ! 1/cos2 1.25
  r_derivIncreasing(2,1,3) = 1.7140      ! 1/cos2 2.44
  r_derivIncreasing(2,1,4) = 1.03003     ! 1/cos2 2.97

  ! descending
  r_stateDecreasing(1,1,4) = 0.5971954   ! sin 0.64
  r_stateDecreasing(1,1,3) = 0.9489846   ! sin 1.25
  r_stateDecreasing(1,1,2) = 0.6454      ! sin 2.44
  r_stateDecreasing(1,1,1) = 0.1708      ! sin 2.97

  r_derivDecreasing(1,1,4) = 0.8020958   ! cos 0.64
  r_derivDecreasing(1,1,3) = 0.3153224   ! cos 1.25
  r_derivDecreasing(1,1,2) =-0.7638      ! cos 2.44
  r_derivDecreasing(1,1,1) =-0.9853      ! cos 2.97


  r_stateDecreasing(2,1,4) = 0.744544    ! tan 0.64
  r_stateDecreasing(2,1,3) = 3.009570    ! tan 1.25
  r_stateDecreasing(2,1,2) =-0.8450      ! tan 2.44
  r_stateDecreasing(2,1,1) =-0.1733      ! tan 2.97

  r_derivDecreasing(2,1,4) = 1.554346    ! 1/cos2 0.64
  r_derivDecreasing(2,1,3) = 10.057510   ! 1/cos2 1.25
  r_derivDecreasing(2,1,2) = 1.7140      ! 1/cos2 2.44
  r_derivDecreasing(2,1,1) = 1.03003     ! 1/cos2 2.97


  !
  ! START THE SERIES OF TESTS
  !
  l_pass = .true.





!!$  !
!!$  ! FIRST TEST
!!$  ! FIRST TEST
!!$  !
!!$  ! This defunct test used to test the normalized hybrid grid type.
!!$  ! The vgrid descriptor, on which this interpolator is based, does
!!$  ! not support this grid type.





  !
  ! SECOND TEST
  ! SECOND TEST
  !
  s_title = "TEST 2:  vcode 5005; cubic derivs; clamped; ascending"

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_stateIn      = r_stateIncreasing
  r_derivIn      = r_derivIncreasing

  s_interpType = 'cubicwithderivs'
  s_extrapType = 'clamped'

  r_stateAnswer(1,1,:) =(/0.5971954, 1.1050999, 1.2870281, 0.4353272, 0.1708000/)
  r_stateAnswer(2,1,:) =(/0.7445440, 6.5792871, 5.2396612,-0.3028076,-0.1733000/)

  r_derivAnswer(1,1,:) =(/0.8020958, 0.2623369, 0.0111124,-0.0236369,-0.9853000/)
  r_derivAnswer(2,1,:) =(/1.5543460, 3.5922914,-4.3209844, 0.2144366, 1.0300300/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF &
                     )





  !
  ! THIRD TEST
  ! THIRD TEST
  !
  s_title = "TEST 3:  vcode 5005; cubic Lagrange; clamped; ascending"

  ! n_gridType = N_GRID_TYPE_STAG5005


  r_stateIn      = r_stateIncreasing
  r_derivIn      = r_derivIncreasing

  s_interpType = 'cubiclagrange'
  s_extrapType = 'clamped'

  r_stateAnswer(1,1,:) =(/0.5971954, 0.9659845, 0.9165952, 0.5209374, 0.1708000/)
  r_stateAnswer(2,1,:) =(/0.7445440, 2.7246029, 1.4263948,-1.1904740,-0.1733000/)

  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF &
                     )





  !
  ! FOURTH TEST
  ! FOURTH TEST
  !
  s_title = "TEST 4:  vcode 5005; nearest neighbour; lapse rate; ascending"

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_stateIn      = r_stateIncreasing
  r_derivIn      = r_derivIncreasing

  s_interpType = 'nearestneighbour'
  s_extrapType = 'lapserate'

  r_stateAnswer(1,1,:) =(/-0.0682094,0.9489846, 0.9489846, 0.6454000,-0.6632335/)
  r_stateAnswer(2,1,:) =(/0.0791393, 3.0095699, 3.0095699,-0.8450000,-1.0073335/)

  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF &
                     )





  !
  ! FIFTH TEST
  ! FIFTH TEST
  !
  s_title = "TEST 5:  vcode 5005; linear; clamped; ascending"

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_stateIn      = r_stateIncreasing
  r_derivIn      = r_derivIncreasing

  s_interpType = 'linear'
  s_extrapType = 'clamped'

  r_stateAnswer(1,1,:) =(/0.5971954, 0.9042622, 0.8041871, 0.5088742, 0.1708000/)
  r_stateAnswer(2,1,:) =(/0.7445440, 2.4417365, 1.1710972,-0.6517754,-0.1733000/)

  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF &
                     )





  !
  ! SIXTH TEST
  ! SIXTH TEST
  !
  s_title = "TEST 6:  vcode 5005; cubic derivs; clamped; descending"

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_stateIn      = r_stateDecreasing
  r_derivIn      = r_derivDecreasing

  s_interpType = 'cubicwithderivs'
  s_extrapType = 'clamped'

  r_stateAnswer(1,1,:) =(/0.5971954, 1.1050999, 1.2870281, 0.4353272, 0.1708000/)
  r_stateAnswer(2,1,:) =(/0.7445440, 6.5792871, 5.2396612,-0.3028076,-0.1733000/)

  r_derivAnswer(1,1,:) =(/0.8020958, 0.2623369, 0.0111124,-0.0236369,-0.9853000/)
  r_derivAnswer(2,1,:) =(/1.5543460, 3.5922914,-4.3209844, 0.2144366, 1.0300300/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF, l_reverseOrder=.true. &
                     )





  !
  ! SEVENTH TEST
  ! SEVENTH TEST
  !
  ! NOTE:  the surface routines do not work with real(8)
  s_title = "TEST 7:  vcode 5005; no interpolation; surface; special values"

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_derivIn      = r_derivDecreasing    ! unused


  ! Set the source and destionation levels
  ! Set also the state values (simulate temperature or humidity values)
  do j=1,n_NJ
    do i=1,n_NI
      r_stateIn(i,j,1) = 0.             ! at the surface
      r_stateIn(i,j,2) = 100.           ! lowest source level above the surface
    end do
  end do
  do k=3,n_PTS_INIT
    do j=1,n_NJ
      do i=1,n_NI
        r_stateIn(i,j,k) = 100. + k
      end do
    end do
  end do


  ! Set the roughness length
  ! (z0), inverse of Monin-Obukhov length (ilmo) and height of the boundary layer
  ! (hBound).  Set the height (in m) of the lowest source level above the surface
  ! (r_zSrc (i,j,2)) and of the surface itself (r_zSrc (i,j,1)).
  r_zSrc(:,:,:) = 1000.
  do j=1,n_NJ
    do i=1,n_NI
      r_zSrc (i,j,1) = 0.
      r_zSrc (i,j,2) = 100.
      do k=1,n_PTS_TARGET
        r_zDest(i,j,k)=5*(k-1.)
      end do

      r_z0(i,j)=1.0
      r_hBound(i,j)=300.
                                        ! Perform a quality control on hBound
      r_hBound(i,j)=max(r_HMIN, &
                        r_hBound(i,j), &
                        (r_stateIn(i,j,2)+2*r_z0(i,j))*R_FACTN &
                       )
      r_ilmo(i,j)=-0.01+i*0.01
      r_lat(i,j)=0 !unused
    end do
  end do

  s_interpType = 'cubiclagrange'
  s_extrapType = 'surface'

  r_stateAnswer(1,1,:) =(/0.0000000000,112.4697037,116.1466980,99.17175293,104.0000000/)
  r_stateAnswer(2,1,:) =(/0.0000000000,121.3532562,126.9689178,99.17175293,104.0000000/)

  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF, &

                      r_zSrc, r_zDest, r_z0, r_ilmo, r_hBound, r_lat &
                     )





  !
  ! EIGHTH TEST
  ! EIGHTH TEST
  !
  s_title = "TEST 8:  vcode 5005; cubic derivs; clamped; ascending"
            ! Just to set the ground for the following test

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_derivIn      = r_derivIncreasing


  ! Set the state values
  do j=1,n_NJ
    do i=1,n_NI
      r_stateIn(i,j,1) = 0.
      r_stateIn(i,j,2) = 100.
    end do
  end do
  do k=3,n_PTS_INIT
    do j=1,n_NJ
      do i=1,n_NI
        r_stateIn(i,j,k) = 100. + 10.*k
      end do
    end do
  end do


  ! Set the roughness length
  ! (z0), inverse of Monin-Obukhov length (ilmo) and height of the boundary layer
  ! (hBound).  Set the height (in m) of the lowest source level above the surface
  ! (r_zSrc (i,j,2)) and of the surface itself (r_zSrc (i,j,1)).
  r_zSrc(:,:,:) = 1000.
  do j=1,n_NJ
    do i=1,n_NI
      r_zSrc (i,j,1) = 0.               !r_zSrc, r_zDest ignored by cubiclagrange
      r_zSrc (i,j,2) = 100.
      do k=1,n_PTS_TARGET
        r_zDest(i,j,k)=5*(k-1.)
      end do

      r_z0(i,j)=1.0
      r_hBound(i,j)=300.
                                        ! Perform a quality control on hBound
      r_hBound(i,j)=max(r_HMIN, &
                        r_hBound(i,j), &
                        (r_stateIn(i,j,2)+2*r_z0(i,j))*R_FACTN &
                       )
      r_ilmo(i,j)=-0.01+i*0.01
      r_lat(i,j)=0 !unused
    end do
  end do

  s_interpType = 'cubicwithderivs'
  s_extrapType = 'clamped'

  r_stateAnswer(1,1,:) =(/0.000,101.9352570,114.4432526,131.8916016,140.0000000/)
  r_stateAnswer(2,1,:) =(/0.000,105.5573425,117.9881516,132.4138641,140.0000000/)

  r_derivAnswer(1,1,:) =(/0.8020958, 6.5528378,12.5041494, 5.9654603,-0.9853000/)
  r_derivAnswer(2,1,:) =(/1.5543460,10.6199150, 9.6359911, 5.5481100, 1.0300300/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF, &

                      r_zSrc, r_zDest, r_z0, r_ilmo, r_hBound, r_lat &
                     )





  !
  ! NINTH TEST
  ! NINTH TEST
  !
  s_title = "TEST 9:  vcode 5005; cubic derivs; surface; ascending"
            ! This is the same as the previous test, except that surface
            ! extrapolation has been chosen.  Compared to the results of the
            ! previous test, surface extrapolation should apply only to the
            ! surface layer .  The derivative in the lowest
            ! interval and below is modified somewhat from test 8 since the
            ! surface extrapolation ensures a smooth derivative at the lowest
            ! level.

            ! N.B.:  The result from this calculation has been observed to be
            !        slightly different when compiled without optimization:
            !        derivOut(1,4)=13.3242283

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_derivIn      = r_derivIncreasing


  ! Set the state values
  do j=1,n_NJ
    do i=1,n_NI
      r_stateIn(i,j,1) = 0.
      r_stateIn(i,j,2) = 100.
    end do
  end do
  do k=3,n_PTS_INIT
    do j=1,n_NJ
      do i=1,n_NI
        r_stateIn(i,j,k) = 100. + 10.*k
      end do
    end do
  end do


  ! Set the roughness length
  ! (z0), inverse of Monin-Obukhov length (ilmo) and height of the boundary layer
  ! (hBound).  Set the height (in m) of the lowest source level above the surface
  ! (r_zSrc (i,j,2)) and of the surface itself (r_zSrc (i,j,1)).
  r_zSrc(:,:,:) = 1000.
  do j=1,n_NJ
    do i=1,n_NI
      r_zSrc (i,j,1) = 0.               !r_zSrc, r_zDest ignored by cubiclagrange
      r_zSrc (i,j,2) = 100.
      do k=1,n_PTS_TARGET
        r_zDest(i,j,k)=5*(k-1.)
      end do

      r_z0(i,j)=1.0
      r_hBound(i,j)=300.
                                        ! Perform a quality control on hBound
      r_hBound(i,j)=max(r_HMIN, &
                        r_hBound(i,j), &
                        (r_stateIn(i,j,2)+2*r_z0(i,j))*R_FACTN &
                       )
      r_ilmo(i,j)=-0.01+i*0.01
      r_lat(i,j)=0 !unused
    end do
  end do

  s_interpType = 'cubicwithderivs'
  s_extrapType = 'surface'

  r_stateAnswer(1,1,:) =(/0.0000000,114.1495895,129.3231201,131.8916016,140.0000000/)
  r_stateAnswer(2,1,:) =(/0.0000000,122.8666687,139.0749054,132.4138641,140.0000000/)

  r_derivAnswer(1,1,:) =(/0.8020958, 21.4986687,  5.4256353,  5.9654603, -0.9853000/)
  r_derivAnswer(2,1,:) =(/1.5543460, 31.8001499, -0.3952063,  5.5481100,  1.0300300/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF, &

                      r_zSrc, r_zDest, r_z0, r_ilmo, r_hBound, r_lat &
                     )





  !
  ! TENTH TEST
  ! TENTH TEST
  !
  s_title = "TEST 10:  vcode 5005; cubic Lagrange; surface; ascending"
            ! This is the same as the previous test, except that the
            ! interpolation has been changed to cubicLagrange.  In this case,
            ! surface extrapolation should apply to the surface layer as in the
            ! previous test.

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_derivIn      = r_derivIncreasing


  ! Set the state values
  do j=1,n_NJ
    do i=1,n_NI
      r_stateIn(i,j,1) = 0.
      r_stateIn(i,j,2) = 100.
    end do
  end do
  do k=3,n_PTS_INIT
    do j=1,n_NJ
      do i=1,n_NI
        r_stateIn(i,j,k) = 100. + 10.*k
      end do
    end do
  end do


  ! Set the roughness length
  ! (z0), inverse of Monin-Obukhov length (ilmo) and height of the boundary layer
  ! (hBound).  Set the height (in m) of the lowest source level above the surface
  ! (r_zSrc (i,j,2)) and of the surface itself (r_zSrc (i,j,1)).
  r_zSrc(:,:,:) = 1000.
  do j=1,n_NJ
    do i=1,n_NI
      r_zSrc (i,j,1) = 0.               !r_zSrc, r_zDest ignored by cubiclagrange
      r_zSrc (i,j,2) = 100.
      do k=1,n_PTS_TARGET
        r_zDest(i,j,k)=5*(k-1.)
      end do

      r_z0(i,j)=1.0
      r_hBound(i,j)=300.
                                        ! Perform a quality control on hBound
      r_hBound(i,j)=max(r_HMIN, &
                        r_hBound(i,j), &
                        (r_stateIn(i,j,2)+2*r_z0(i,j))*R_FACTN &
                       )
      r_ilmo(i,j)=-0.01+i*0.01
      r_lat(i,j)=0 !unused
    end do
  end do

  s_interpType = 'cubiclagrange'
  s_extrapType = 'surface'

  r_stateAnswer(1,1,:) =(/0.0000000,113.6644821,126.2038116,130.2463379,140.0000000/)
  r_stateAnswer(2,1,:) =(/0.0000000,122.5480347,137.0260315,130.2463379,140.0000000/)

  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF, &

                      r_zSrc, r_zDest, r_z0, r_ilmo, r_hBound, r_lat &
                     )





  !
  ! ELEVENTH TEST
  ! ELEVENTH TEST
  !
  s_title = "TEST 11:  vcode 5005; surface; decreasing special values"
             ! This test is based on test seven, but with the input orders
             ! reversed such that it is decreasing.  The result should be the
             ! same as in test seven.

  ! n_gridType = N_GRID_TYPE_STAG5005



  r_derivIn      = r_derivDecreasing


  ! Set the source and destionation levels
  ! Set also the state values (simulate temperature or humidity values)
  do j=1,n_NJ
    do i=1,n_NI
      r_stateIn(i,j,1) = 0.             ! at the surface
      r_stateIn(i,j,2) = 100.           ! lowest source level above the surface
    end do
  end do
  do k=3,n_PTS_INIT
    do j=1,n_NJ
      do i=1,n_NI
        r_stateIn(i,j,k) = 100. + k
      end do
    end do
  end do


  ! Set the roughness length
  ! (z0), inverse of Monin-Obukhov length (ilmo) and height of the boundary layer
  ! (hBound).  Set the height (in m) of the lowest source level above the surface
  ! (r_zSrc (i,j,2)) and of the surface itself (r_zSrc (i,j,1)).
  r_zSrc(:,:,:) = 1000.
  do j=1,n_NJ
    do i=1,n_NI
      r_zSrc (i,j,1) = 0.
      r_zSrc (i,j,2) = 100.
      do k=1,n_PTS_TARGET
        r_zDest(i,j,k)=5*(k-1.)
      end do

      r_z0(i,j)=1.0
      r_hBound(i,j)=300.
                                        ! Perform a quality control on hBound
      r_hBound(i,j)=max(r_HMIN, &
                        r_hBound(i,j), &
                        (r_stateIn(i,j,2)+2*r_z0(i,j))*R_FACTN &
                       )
      r_ilmo(i,j)=-0.01+i*0.01
      r_lat(i,j)=0 !unused
    end do
  end do

  s_interpType = 'cubiclagrange'
  s_extrapType = 'surface'

  r_stateAnswer(1,1,:) =(/0.0000000,112.4697037,116.1467056,99.1717529,104.0000000/)
  r_stateAnswer(2,1,:) =(/0.0000000,121.3532562,126.9689178,99.1717529,104.0000000/)

  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  ! Reverse the input order to decreasing
  r_temp3 = r_stateIn
  do k=1,n_PTS_INIT
    r_stateIn(:,:,k) = r_temp3(:,:,n_PTS_INIT+1-k)
  end do

  r_temp3 = r_zSrc
  do k=1,n_PTS_INIT
    r_zSrc(:,:,k) = r_temp3(:,:,n_PTS_INIT+1-k)
  end do

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF, &

                      r_zSrc, r_zDest, r_z0, r_ilmo, r_hBound, r_lat, &

                      l_reverseOrder=.true. &
                     )





  !
  ! TWELFTH TEST
  ! TWELFTH TEST
  !
  s_title = "TEST 12:  vcode 5005; no interp'n; surface wind; special values"
            ! This is the same as test 7, but for the wind

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_derivIn      = r_derivDecreasing


  ! Set the destionation levels
  ! Set also the state values (simulate wind values)
  do j=1,n_NJ
    do i=1,n_NI
      r_stateIn(i,j,1) = 1000.          ! at the surface:  0 is assumed!
      r_y_stateIn(i,j,1) = 0.

      r_stateIn(i,j,2) = 10.            ! lowest source level above the surface
      r_y_stateIn(i,j,2) = 0.
    end do
  end do
  do k=3,n_PTS_INIT
    do j=1,n_NJ
      do i=1,n_NI
        r_stateIn(i,j,k) = 143. + k
      end do
    end do
  end do


  ! Set the roughness length
  ! (z0), inverse of Monin-Obukhov length (ilmo) and height of the boundary layer
  ! (hBound).  Set the height (in m) of the lowest source level above the surface
  ! (r_zSrc (i,j,2)) and of the surface itself (r_zSrc (i,j,1)).
  r_zSrc(:,:,:) = 1000.
  do j=1,n_NJ
    do i=1,n_NI
      r_zSrc (i,j,1) = 0.
      r_zSrc (i,j,2) = 80.
      do k=1,n_PTS_TARGET
        r_zDest(i,j,k)=12*k
      end do

      r_z0(i,j)=1.0
      r_ilmo(i,j)=-0.10+i*0.10
      r_hBound(i,j)=100./max(r_ilmo(i,j),real(1.d-9, test48))
      r_lat(i,j)=1.0
    end do
  end do

  s_interpType = 'cubiclagrange'
  s_extrapType = 'surfacewind'

  r_stateAnswer(1,1,:) =(/0.0000000,0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_y_stateAnswer(1,1,:)=(/0.0000000,0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  r_stateAnswer(2,1,:) =(/0.0000000,0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_y_stateAnswer(2,1,:)=(/0.0000000,0.0000000, 0.0000000, 0.0000000, 0.0000000/)


  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_y_derivAnswer(1,1,:)=(/0.0000000,0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_y_derivAnswer(2,1,:)=(/0.0000000,0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF, &

                      r_zSrc, r_zDest, r_z0, r_ilmo, r_hBound, r_lat, &
                      r_y_stateIn, r_y_stateAnswer, r_y_derivIn,r_y_derivAnswer &
                     )





  !
  ! THIRTEENTH TEST
  ! THIRTEENTH TEST
  !
  s_title = "TEST 13:  vcode 5005; cubic derivs; clamped; ascending"
            ! Just to set the ground (y-component) for the following test.

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_derivIn      = r_derivIncreasing


  ! Set the state values
  do j=1,n_NJ
    do i=1,n_NI
      r_stateIn(i,j,1) = 0.
      r_stateIn(i,j,2) = 0.
    end do
  end do
  do k=3,n_PTS_INIT
    do j=1,n_NJ
      do i=1,n_NI
        r_stateIn(i,j,k) = 143. + k
      end do
    end do
  end do


  ! Set the roughness length
  ! (z0), inverse of Monin-Obukhov length (ilmo) and height of the boundary layer
  ! (hBound).  Set the height (in m) of the lowest source level above the surface
  ! (r_zSrc (i,j,2)) and of the surface itself (r_zSrc (i,j,1)).
  r_zSrc(:,:,:) = 1000.
  do j=1,n_NJ
    do i=1,n_NI
      r_zSrc (i,j,1) = 0.               !r_zSrc, r_zDest ignored by cubiclagrange
      r_zSrc (i,j,2) = 80.
      do k=1,n_PTS_TARGET
        r_zDest(i,j,k)=12.*k
      end do

      r_z0(i,j)=1.0
      r_ilmo(i,j)=-0.10+i*0.10
      r_hBound(i,j)=100./max(r_ilmo(i,j),real(1.d-9, test48))
      r_lat(i,j)=1.0
    end do
  end do

  s_interpType = 'cubicwithderivs'
  s_extrapType = 'clamped'

  r_stateAnswer(1,1,:) =(/0.0000000, 8.7456951,68.4369888,146.0858002,147.0000000/)
  r_stateAnswer(2,1,:) =(/0.0000000,12.3677778,71.9818954,146.6080627,147.0000000/)

  r_derivAnswer(1,1,:) =(/0.8020958,30.6324348,60.3266182, 0.8195000,-0.9853000/)
  r_derivAnswer(2,1,:) =(/1.5543460,34.6995125,57.4584618, 0.4021498, 1.0300300/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF, &

                      r_zSrc, r_zDest, r_z0, r_ilmo, r_hBound, r_lat &
                     )




! This test is sensitive to round-off error.  There are often a few bits that
! differ and cause a failure of the test, even though all is well

  !
  ! FOURTEENTH TEST
  ! FOURTEENTH TEST
  !
  ! N.B.:  This test will fail if not preceeded by test 13
  s_title = "TEST 14:  vcode 5005; cubic derivs; surface wind; ascending"
            ! This is the same as tests 8 (x-component) and 13 (y-component),
            ! except that surface wind extrapolation has been chosen.  Compared
            ! to the results of tests 8 and 13, surface wind extrapolation should
            ! apply only to the surface layer.
            !
            ! The derivative
            ! in the lowest interval and below is modified somewhat from tests 8
            ! and 13 since the surface extrapolation ensures a smooth derivative
            ! at the lowest level.

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_derivIn      = r_derivIncreasing
  r_y_derivIn    = r_derivIncreasing


  ! Set the state values
  do j=1,n_NJ
    do i=1,n_NI
      r_stateIn(i,j,1) = 0.
      r_y_stateIn(i,j,1) = 0.

      r_stateIn(i,j,2) = 10.
      r_y_stateIn(i,j,2) = 0.
    end do
  end do
  do k=3,n_PTS_INIT
    do j=1,n_NJ
      do i=1,n_NI
        r_stateIn(i,j,k) = 100. + 10.*k
        r_y_stateIn(i,j,k) = 143. + k
      end do
    end do
  end do


  ! Set the roughness length
  ! (z0), inverse of Monin-Obukhov length (ilmo) and height of the boundary layer
  ! (hBound).  Set the height (in m) of the lowest source level above the surface
  ! (r_zSrc (i,j,2)) and of the surface itself (r_zSrc (i,j,1)).
  r_zSrc = 1000.
  do j=1,n_NJ
    do i=1,n_NI
                                        ! r_zSrc, r_zDest NOT ignored by
                                        ! cubiclagrange for extrap=surfacewind
      r_zSrc (i,j,1) = 0.
      r_zSrc (i,j,2) = 80.
      r_zSrc (i,j,3) = 0.
      r_zSrc (i,j,4) = 0.
      do k=1,n_PTS_TARGET
        r_zDest(i,j,k)=12.*k
      end do

      r_z0(i,j)=1.0
      r_ilmo(i,j)=-0.10+i*0.10
      r_hBound(i,j)=100./max(r_ilmo(i,j),real(1.d-9, test48))
      r_lat(i,j)=1.0
    end do
  end do


  s_interpType = 'cubicwithderivs'
  s_extrapType = 'surfacewind'

  r_stateAnswer(1,1,:)  =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)
  r_y_stateAnswer(1,1,:)=(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)

  r_stateAnswer(2,1,:)  =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)
  r_y_stateAnswer(2,1,:)=(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)


  r_derivAnswer(1,1,:)  =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)
  r_y_derivAnswer(1,1,:)=(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)

  r_derivAnswer(2,1,:)  =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)
  r_y_derivAnswer(2,1,:)=(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF, &

                      r_zSrc, r_zDest, r_z0, r_ilmo, r_hBound, r_lat, &
                      r_y_stateIn, r_y_stateAnswer, r_y_derivIn,r_y_derivAnswer &
                     )





  !
  ! FIFTEENTH TEST
  ! FIFTEENTH TEST
  !
  s_title = "TEST 15:  vcode 5005; cubic Lagrange; surface wind; ascending"
            ! This is the same as the previous test, except that the
            ! interpolation has been changed to cubicLagrange.  In this case,
            ! surface extrapolation should apply to the surface layer as in the
            ! previous test, and should adjust the interpolation in the
            ! next layer above that to use cubic with derivatives, albeit with a
            ! manufactured derivative.

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_derivIn      = r_derivIncreasing
  r_y_derivIn    = r_derivIncreasing


  ! Set the state values
  do j=1,n_NJ
    do i=1,n_NI
      r_stateIn(i,j,1) = 0.
      r_y_stateIn(i,j,1) = 0.

      r_stateIn(i,j,2) = 10.
      r_y_stateIn(i,j,2) = 0.
    end do
  end do
  do k=3,n_PTS_INIT
    do j=1,n_NJ
      do i=1,n_NI
        r_stateIn(i,j,k) = 100. + 10.*k
        r_y_stateIn(i,j,k) = 143. + k
      end do
    end do
  end do


  ! Set the roughness length
  ! (z0), inverse of Monin-Obukhov length (ilmo) and height of the boundary layer
  ! (hBound).  Set the height (in m) of the lowest source level above the surface
  ! (r_zSrc (i,j,2)) and of the surface itself (r_zSrc (i,j,1)).
  r_zSrc(:,:,:) = 1000.
  do j=1,n_NJ
    do i=1,n_NI
      r_zSrc (i,j,1) = 0.               !r_zSrc, r_zDest ignored by cubiclagrange
      r_zSrc (i,j,2) = 80.
      do k=1,n_PTS_TARGET
        r_zDest(i,j,k)=12.*k
      end do

      r_z0(i,j)=1.0
      r_ilmo(i,j)=-0.10+i*0.10
      r_hBound(i,j)=100./max(r_ilmo(i,j),real(1.d-9, test48))
      r_lat(i,j)=1.0
    end do
  end do


  s_interpType = 'cubiclagrange'
  s_extrapType = 'surfacewind'

  r_stateAnswer(1,1,:)  =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)
  r_y_stateAnswer(1,1,:)=(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)

  r_stateAnswer(2,1,:)  =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)
  r_y_stateAnswer(2,1,:)=(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)


  r_derivAnswer(1,1,:)  =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)
  r_y_derivAnswer(1,1,:)=(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)

  r_derivAnswer(2,1,:)  =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)
  r_y_derivAnswer(2,1,:)=(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.000000/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF, &

                      r_zSrc, r_zDest, r_z0, r_ilmo, r_hBound, r_lat, &
                      r_y_stateIn, r_y_stateAnswer, r_y_derivIn,r_y_derivAnswer &
                     )





!!!$  !
!!!$  ! SIXTEENTH TEST
!!!$  ! SIXTEENTH TEST
!!!$  !
!!!$  ! This defunct test used to test the old (pre-_X) interface





  !
  ! SEVENTEENTH TEST
  ! SEVENTEENTH TEST
  !
  s_title = "TEST 17:  vcode 5005; linear; fixed; ascending"

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_stateIn      = r_stateIncreasing
  r_derivIn      = r_derivIncreasing

  s_interpType = 'linear'
  s_extrapType = 'fixed'

  r_stateAnswer(1,1,:) =(/0.4000000,  0.9042623,  0.8041871,  0.5088742, -0.5000000/)
  r_stateAnswer(2,1,:) =(/0.4000000,  2.4417364,  1.1710972, -0.6517754, -0.5000000/)

  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                      r_stateIn , r_derivIn, &
                      r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF &
                     )





  !
  ! EIGHTEENTH TEST
  ! EIGHTEENTH TEST
  !
  ! (The same as FIRST TEST, but with a different grid type.)
  s_title = "TEST 18:  unnormalized hybrid; cubic derivs; clamped; ascending"

  n_gridType = N_GRID_TYPE_HYBRID_NOTNORM

  r_levelsInit   = r_LEVELS_INCREASING
  r_stateIn      = r_stateIncreasing
  r_derivIn      = r_derivIncreasing
  r_levelsTarget = r_LEVELS_TARGET_STD

  s_interpType = 'cubicwithderivs'
  s_extrapType = 'clamped'

  r_stateAnswer(1,1,:) =(/0.5971954, 0.9315544, 0.3601077, 0.3026085, 0.1708000/)
  r_stateAnswer(2,1,:) =(/0.7445440, 1.2305623,-0.3820439,-0.3150665,-0.1733000/)

  r_derivAnswer(1,1,:)=(/0.8020958,-0.3575073,-0.8898256,-0.9181176,-0.9853000/)
  r_derivAnswer(2,1,:)=(/1.5543460,-7.4034305, 1.0748973, 1.0347385, 1.0300300/)

  !
  ! MAKE THE DATA REASONABLE FOR THE HYBRID GRID TYPE
  !
  ! convert the levels to reasonable hybrid values
  do i=1,n_PTS_INIT
    r_levelsInit(i) = r_levelsInit(i) / 3.2
  end do
  r_levelsInit(n_PTS_INIT) = 1.0
  r_levelsInit(1) = (r_PTOP_INIT/2.) / (r_PREF_INIT/2.)

  ! convert the levels to reasonable hybrid values
  do i=n_PTS_TARGET,2,-1
    r_levelsTarget(i) = r_levelsTarget(i-1) / 3.2
  end do
  r_levelsTarget(1) = (r_PTOP_TARGET/2.5) / (r_PREF_TARGET/2.)
  r_levelsTarget(n_PTS_TARGET) = 1.0


! NOTE:  modifying the initial pref and rcoeff
  call m_testOneCombo_2GridTypes(s_title, n_gridType, n_gridType, &
                      s_interpType, s_extrapType, &

                      r_levelsInit,   r_stateIn , r_derivIn, &
                      r_levelsTarget, r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PTOP_INIT/2., r_PREF_INIT/2., r_RCOEFF_INIT*2, &
                      r_PTOP_TARGET/2.5, r_PREF_TARGET/2., r_RCOEFF_TARGET, &
                      r_PSURF, &

                      0.0, 0.0 &
                     )




  !
  ! NINETEENTH TEST
  ! NINETEENTH TEST
  !
  ! This defunct test used to test with arrays that do not start at zero, nor end
  ! at n_VLevels.  Since the tests were adapted to use the grid descriptor, all
  ! of them are based on just a few noncontiguous levels.  Thus, this test is no
  ! longer of any use.




!!$  !
!!$  ! TWENTIETH TEST
!!$  ! TWENTIETH TEST
!!$  !
!!$  ! (The same as the first test, but with staggered levels.)
!!$  s_title = "TEST 20:  staggered vertical levels"
!!$
!!$  n_gridType = N_GRID_TYPE_STAGGERED
!!$
!!$  r_levelsInit   = r_LEVELS_INCREASING
!!$  r_stateIn      = r_stateIncreasing
!!$  r_derivIn      = r_derivIncreasing
!!$  r_levelsTarget = r_LEVELS_TARGET_STD
!!$
!!$  s_interpType = 'linear'
!!$  s_extrapType = 'clamped'
!!$
!!$  r_stateAnswer(1,1,:) =(/0.9473432, 0.8168903, 0.3669596, 0.2841619, 0.1708000/)
!!$  r_stateAnswer(2,1,:) =(/2.9887292, 1.3323874,-0.4509242,-0.3337408,-0.1733000/)
!!$
!!$  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
!!$  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
!!$
!!$  !
!!$  ! MAKE THE DATA REASONABLE FOR THE HYBRID GRID TYPE
!!$  !
!!$  ! convert the levels to reasonable hybrid values
!!$  do i=1,n_PTS_INIT
!!$    r_levelsInit(i) = r_levelsInit(i) / 3.2
!!$  end do
!!$
!!$  ! convert the levels to reasonable hybrid values
!!$  do i=n_PTS_TARGET,2,-1
!!$    r_levelsTarget(i) = r_levelsTarget(i-1) / 3.5
!!$  end do
!!$  r_levelsTarget(1) = r_levelsInit(1)
!!$  r_levelsTarget(5) = 0.90
!!$
!!$
!!$
!!$! NOTE:  modifying the initial pref and rcoeff
!!$  call m_testOneCombo_2GridTypes &
!!$                     (s_title, n_gridType, n_gridType, &
!!$                      s_interpType, s_extrapType, &
!!$
!!$                      r_levelsInit,   r_stateIn , r_derivIn, &
!!$                      r_levelsTarget, r_stateAnswer, r_derivAnswer, &
!!$
!!$                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &
!!$
!!$                      r_PTOP_INIT, r_PREF_INIT/2., r_RCOEFF_INIT*2., &
!!$                      r_PTOP_TARGET, r_PREF_TARGET, r_RCOEFF_TARGET, &
!!$                      r_PSURF, &
!!$
!!$                      r_RCOEFF_INIT*2., r_RCOEFF_TARGET &
!!$                     )





  !
  ! TWENTY-FIRST TEST
  ! TWENTY-FIRST TEST
  !
  s_title = "TEST 21:  vcode 5005; linear; abort; ascending"
  write(6,*)" "
  write(6,*)" "
  write(6,*)s_title
  write(6,*)"The correct result is an abortion."
  write(6,*)"UNCOMMENT THE CODE to perform the test."
  write(6,*)"UNCOMMENT THE CODE to perform the test."
  write(6,*)"UNCOMMENT THE CODE to perform the test."
  write(6,*)" "

!!!$  write(6,*)"BEGINNING ", s_title
!!!$  write(6,*)"The correct result is an abortion..."
!!!$
!!!$!   n_gridType = N_GRID_TYPE_STAG5005
!!!$
!!!$  r_stateIn      = r_stateIncreasing
!!!$  r_derivIn      = r_derivIncreasing
!!!$
!!!$  s_interpType = 'linear'
!!!$  s_extrapType = 'abort'
!!!$
!!!$  r_stateAnswer(1,1,:) =(/0.8797802, 0.4842152, 0.3319850, 0.4000000,-0.5000000/)
!!!$  r_stateAnswer(2,1,:) =(/2.5639911,-0.6168757,-0.4014246, 0.4000000,-0.5000000/)
!!!$
!!!$  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
!!!$  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
!!!$
!!!$  call m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &
!!!$
!!!$                      r_stateIn , r_derivIn, &
!!!$                      r_stateAnswer, r_derivAnswer, &
!!!$
!!!$                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &
!!!$
!!!$                      r_PSURF &
!!!$                     )





!!$  !
!!$  ! TWENTY-SECOND TEST
!!$  ! TWENTY-SECOND TEST
!!$  !
!!$  ! (The same as the twentieth test, but with vcode=5005 levels in one grid.)
!!$  s_title = "TEST 22:  vcode=5005; linear; clamped; ascending"
!!$
!!$  n_gridTypeIn  = N_GRID_TYPE_STAGGERED
!!$  n_gridTypeOut = N_GRID_TYPE_STAG5005
!!$
!!$  r_levelsInit   = r_LEVELS_INCREASING
!!$  r_stateIn      = r_stateIncreasing
!!$  r_derivIn      = r_derivIncreasing
!!$  r_levelsTarget = r_LEVELS_TARGET_STD
!!$
!!$  s_interpType = 'linear'
!!$  s_extrapType = 'clamped'
!!$
!!$! Must be corrected:
!!$  r_stateAnswer(1,1,:) =(/0.5971954, 0.7488908, 0.6590497, 0.5538221, 0.2496417/)
!!$  r_stateAnswer(2,1,:) =(/0.7445440, 1.7212481,-0.6716905,-0.7153901,-0.2848845/)
!!$
!!$  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
!!$  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
!!$
!!$  !
!!$  ! MAKE THE DATA REASONABLE FOR THE HYBRID GRID TYPE
!!$  !
!!$  ! convert the levels to reasonable hybrid values
!!$  do i=1,n_PTS_INIT
!!$    r_levelsInit(i) = r_levelsInit(i) / 3.2
!!$  end do
!!$
!!$  ! convert the levels to reasonable hybrid values
!!$  do i=n_PTS_TARGET,2,-1
!!$    r_levelsTarget(i) = r_levelsTarget(i-1) / 3.5
!!$  end do
!!$  r_levelsTarget(1) = r_levelsInit(1)
!!$  r_levelsTarget(5) = 0.90
!!$
!!$! NOTE:  modifying the initial pref and rcoeff
!!$  call m_testOneCombo_2GridTypes &
!!$                     (s_title, n_gridTypeIn, n_gridTypeOut, &
!!$                      s_interpType, s_extrapType, &
!!$
!!$                      r_levelsInit,   r_stateIn , r_derivIn, &
!!$                      r_levelsTarget, r_stateAnswer, r_derivAnswer, &
!!$
!!$                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &
!!$
!!$                      r_PTOP_INIT, r_PREF_INIT/2., r_RCOEFF_INIT*2., &
!!$                      r_PTOP_TARGET, r_PREF_TARGET, r_RCOEFF_TARGET, &
!!$                      r_PSURF, &
!!$
!!$                      r_RCOEFF_INIT*2., r_RCOEFF_TARGET &
!!$                     )





  !
  ! TWENTY-THIRD TEST
  ! TWENTY-THIRD TEST
  !
  ! NOTE:  since vgrid revision 6.3.2, this test has remarkably bad values
  !        The author of vgrid is not worried since the difference is not
  !        meteorologically significant.
  s_title = "TEST 23:  sigma; linear; clamped; ascending"

  n_gridType = N_GRID_TYPE_SIGMA

  r_levelsInit   = r_LEVELS_INCREASING
  r_stateIn      = r_stateIncreasing
  r_derivIn      = r_derivIncreasing
  r_levelsTarget = r_LEVELS_TARGET_STD

  s_interpType = 'linear'
  s_extrapType = 'clamped'

  ! Original good values
!!r_stateAnswer(1,1,:) =(/0.5971954, 0.8959478, 0.5208192, 0.4107825, 0.1708000/)
!!r_stateAnswer(2,1,:) =(/0.7445440, 2.6680875,-0.6686813,-0.5129465,-0.1733000/)

  ! Values obtained with vgrid 6.3.2
  r_stateAnswer(1,1,:) =(/0.5971954, 0.8959387, 0.5209261, 0.4107324, 0.1708000/)
  r_stateAnswer(2,1,:) =(/0.7445440, 2.6680293,-0.6688324,-0.5128756,-0.1733000/)

  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  !
  ! MAKE THE LEVELS MONOTONICALLY INCREASING
  !
  ! convert the levels to reasonable hybrid values
  do i=1,n_PTS_INIT
    r_levelsInit(i) = r_levelsInit(i) / 3.2
  end do
  r_levelsInit(n_PTS_INIT) = 1.0

  ! convert the levels to reasonable hybrid values
  do i=n_PTS_TARGET-1,2,-1
    r_levelsTarget(i) = r_levelsTarget(i-1) / 3.2
  end do
  r_levelsTarget(1) = r_levelsInit(1)
  r_levelsTarget(n_PTS_TARGET) = 1.0


! NOTE:  modifying the initial pref and rcoeff
!        r_rCoef_2_Init and r_rCoef_2_Target are unused for N_GRID_TYPE_SIGMA
  call m_testOneCombo_2GridTypes(s_title, n_gridType, n_gridType, s_interpType, s_extrapType, &

                      r_levelsInit,   r_stateIn , r_derivIn, &
                      r_levelsTarget, r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PTOP_INIT, r_PREF_INIT/2., r_RCOEFF_INIT*2., &
                      r_PTOP_TARGET, r_PREF_TARGET, r_RCOEFF_TARGET, &
                      r_PSURF, 0.0, 0.0 &
                     )





  !
  ! TWENTY-FOURTH TEST
  ! TWENTY-FOURTH TEST
  !
  s_title = "TEST 24:  pressure; linear; clamped; ascending"

  n_gridType = N_GRID_TYPE_PRESSURE

  r_levelsInit   = r_LEVELS_INCREASING
  r_stateIn      = r_stateIncreasing
  r_derivIn      = r_derivIncreasing
  r_levelsTarget = r_LEVELS_TARGET_STD

  s_interpType = 'linear'
  s_extrapType = 'clamped'

  r_stateAnswer(1,1,:) =(/ 0.8959476, 0.4735463, 0.3217543, 0.1708000, 0.1708000/)
  r_stateAnswer(2,1,:) =(/ 2.6680861,-0.6017760,-0.3869452,-0.1733000,-0.1733000/)

  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  ! MAKE THE LEVELS MONOTONICALLY INCREASING
  r_levelsTarget(4) = 2.99


! NOTE:  modifying the initial pref and rcoeff
!        r_rCoef_2_Init and r_rCoef_2_Target are unused for N_GRID_TYPE_PRESSURE
  call m_testOneCombo_2GridTypes(s_title, n_gridType, n_gridType, &
                      s_interpType, s_extrapType, &

                      r_levelsInit,   r_stateIn , r_derivIn, &
                      r_levelsTarget, r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PTOP_INIT, r_PREF_INIT/2., r_RCOEFF_INIT*2., &
                      r_PTOP_TARGET, r_PREF_TARGET, r_RCOEFF_TARGET, &
                      r_PSURF, 0.0, 0.0 &
                     )





  !
  ! TWENTY-FIFTH TEST
  ! TWENTY-FIFTH TEST
  !
  ! Vgrid gives different results from those that are otherwise expected.
  ! This question has not been resolved definitively.  Nonetheless, this
  ! test has been re-activated so as to confirm that the results for this
  ! case remain constant.
  s_title = "TEST 25:  eta; linear; clamped; ascending"

  n_gridType = N_GRID_TYPE_ETA

  r_levelsInit   = r_LEVELS_INCREASING
  r_stateIn      = r_stateIncreasing
  r_derivIn      = r_derivIncreasing
  r_levelsTarget = r_LEVELS_TARGET_STD

  s_interpType = 'linear'
  s_extrapType = 'clamped'

  r_stateAnswer(1,1,:) =(/0.5971954, 0.9446925, 0.5209283, 0.4107352, 0.1708000/)
  r_stateAnswer(2,1,:) =(/0.7445440, 2.9819345,-0.6688356,-0.5128796,-0.1733000/)

  r_derivAnswer(1,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)
  r_derivAnswer(2,1,:) =(/0.0000000, 0.0000000, 0.0000000, 0.0000000, 0.0000000/)

  !
  ! MAKE THE DATA REASONABLE FOR THE HYBRID GRID TYPE
  !
  ! convert the levels to reasonable hybrid values
  do i=1,n_PTS_INIT
    r_levelsInit(i) = r_levelsInit(i) / 3.2
  end do
  r_levelsInit(1)          = 0.0
  r_levelsInit(n_PTS_INIT) = 1.0

  ! convert the levels to reasonable hybrid values
  do i=n_PTS_TARGET,2,-1
    r_levelsTarget(i) = r_levelsTarget(i-1) / 3.2
  end do
  r_levelsTarget(1)            = 0.0
  r_levelsTarget(n_PTS_TARGET) = 1.0


! NOTE:  modifying the initial pref and rcoeff
!        r_rCoef_2_Init and r_rCoef_2_Target are unused for N_GRID_TYPE_ETA
  call m_testOneCombo_2GridTypes(s_title, n_gridType, n_gridType, &
                      s_interpType, s_extrapType, &

                      r_levelsInit,   r_stateIn , r_derivIn, &
                      r_levelsTarget, r_stateAnswer, r_derivAnswer, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PTOP_INIT, r_PREF_INIT, r_RCOEFF_INIT, &
                      r_PTOP_TARGET, r_PREF_TARGET, r_RCOEFF_TARGET, &
                      r_PSURF, 0.0, 0.0 &
                     )





  !
  ! TWENTY-SIXTH TEST
  ! TWENTY-SIXTH TEST
  !
  s_title = "TEST 26:  specify ip1 type to qkdef"

  ! n_gridType = N_GRID_TYPE_STAG5005

  r_stateIn_21(1,1,:) = (/1.0, 1.2, 1.4, 1.6, 1.8, 2.0, 2.2, 2.4, 2.6, 2.8, &
                          3.0, 3.2, 3.4, 3.6, 3.8, 4.0, 4.2, 4.4, 4.6, 4.8, 5.0/)
  r_derivIn_21(:,:,:) = 0.0

  s_interpType = 'linear'
  s_extrapType = 'clamped'

  r_stateAnswer_21(1,1,:) =(/1.1000000,1.3000000,1.5000000,1.7000000,1.9000000, &
                             2.1000001,2.3000000,2.5000000,2.7000000,2.9000001, &
                             3.0999999,3.3000000,3.5000000,3.6999996,3.9000001, &
                             4.0999994,4.3000002,4.4999990,4.6999998,4.9000001, &
                             5.0000000/)

  r_derivAnswer_21(1,1,:) = 0.0

  call m_testOneCombo_ip1Type(s_title, s_interpType, s_extrapType, &

                      r_stateIn_21,     r_derivIn_21, &
                      r_stateAnswer_21, r_derivAnswer_21, &

                      r_EXTRAP_GUIDE_DOWN, r_EXTRAP_GUIDE_UP, &

                      r_PSURF_1 &
                     )




  ! Report the overall test status
  if(l_pass) then
    write(6,*)'*  T E S T   P A S S E D  *'
    write(6,"(' *     (', I1, '-byte reals)      *')")test48
  else
    write(6,*)'* * * * * * * * * * * * * *'
    write(6,*)'*                         *'
    write(6,*)'*  T E S T   F A I L E D  *'
    write(6,"(' *     (', I1, '-byte reals)      *')")test48
    write(6,*)'*                         *'
    write(6,*)'* * * * * * * * * * * * * *'
  end if


  ! Close the file that defines a vgrid
  error = fstfrm(TOCTOC_FILENUM) ! returns no. of records or error
  if(error < 0)write(6,*)"ERROR closing toctoc_5005:  error=", error

contains

!!!s/r m_testOneCombo_5005 - routine that tests a single combination of parameters
subroutine m_testOneCombo_5005(s_title, s_interpType, s_extrapType, &

                          r_stateIn , r_derivIn, &
                          r_stateAnswer, r_derivAnswer, &

                          r_extrapGuideDown, r_extrapGuideUp, &

                          r_pSurf, &

                          r_zSrc, r_zDest, r_z0, r_ilmo, r_hBound, r_lat, &
                          r_y_stateIn,  r_y_stateAnswer, &
                          r_y_derivIn, r_y_derivAnswer, &

                          l_reverseOrder &
                         )
!
!AUTHOR
!     J.W. Blezius OCT 2003
!
!REVISION
! v1_3    Blezius J.W. OCT 2003 - formalized from existing non-automatic test
!
!OBJECT
!        To test the ez_interpv package.
!
!ARGUMENTS
  use VerticalGrid_90_class
  use VerticalInterpolation_90_class
  implicit none

                                        ! parameters of most interest
  character(*), intent(in) :: s_title
  character(*), intent(in) :: s_interpType, s_extrapType

                                        ! input data for the interpolation and
                                        ! the expected results
  real(test48), dimension(:,:,:), intent(in) :: r_stateIn , r_derivIn, &
                                        r_stateAnswer, r_derivAnswer

                                        ! more interpolation parameters
  real(test48), intent(in) :: r_extrapGuideDown, r_extrapGuideUp

                                        ! grid parameter
  real(test48), dimension(:,:), intent(in) :: r_pSurf
  real(test48), dimension(:,:,:), optional, intent(in) :: r_zSrc, r_zDest

  ! The next four parameters are used only for surface extrapolation
                                        ! roughness length
  real(test48), dimension(:,:), optional, intent(in) :: r_z0
                                        ! inverse Monin-Obukhov length
  real(test48), dimension(:,:), optional, intent(in) :: r_ilmo
                                        ! height of the boundary layer
  real(test48), dimension(:,:), optional, intent(in) :: r_hBound
                                        ! latitude (used only for the wind)
  real(test48), dimension(:,:), optional, intent(in) :: r_lat
  real(test48), dimension(:,:,:), optional, intent(in) :: r_y_stateIn, r_y_stateAnswer, &
                                                  r_y_derivIn, r_y_derivAnswer
  logical, optional, intent(in) :: l_reverseOrder
!
!NOTES
!        Assume that both the initial and target grid types are as defined in the
!        file, TOCTOC_FILENUM; i.e. N_GRID_TYPE_STAG5005.
!
!!
                                        ! a place to hold the results
  real(test48), &
        dimension(ubound(r_stateAnswer,1), &
                  ubound(r_stateAnswer,2), &
                  ubound(r_stateAnswer,3)) :: r_stateOut   , r_derivOut, &
                                              r_y_stateOut , r_y_derivOut

  integer :: i, j, k, n_ni, n_nj, n_nk, n_error

  type(T_VerticalGrid), target  :: o_gridInit  , o_gridTarget
  type(T_VerticalGrid), pointer :: o_gridInit_p, o_gridTarget_p

                                        ! The ip1's of the field levels that are
                                        ! present in the associated field
  integer, dimension(n_PTS_TARGET) :: n_ip1
  integer, dimension(:), pointer   :: n_ip1_temp_p

  type(vgrid_descriptor), target  :: o_vGridDescInit,   o_vGridDescTarget
  type(vgrid_descriptor), pointer :: o_vGridDescInit_p, o_vGridDescTarget_p

  character(len=19) :: s_pass     = '  PASS', &
                       s_fail     = '  **** F A I L ****', &
                       s_passFail = '  **** T E M P ****'

  nullify(n_ip1_temp_p)

  write(6,*)
  write(6,*) s_title

  o_gridInit_p   => o_gridInit
  o_gridTarget_p => o_gridTarget
  o_gridInit_p%N_ip1_p         => null()
  o_gridInit_p%O_vGridDesc_p   => null()
  o_gridTarget_p%N_ip1_p       => null()
  o_gridTarget_p%O_vGridDesc_p => null()

  n_ni = ubound(r_stateAnswer,1)
  n_nj = ubound(r_stateAnswer,2)
  n_nk = ubound(r_stateAnswer,3)



  ! Clear the destination tables
  r_stateOut=0.
  r_derivOut=0.
  r_y_stateOut=0.
  r_y_derivOut=0.

  !
  ! CREATE THE INITIAL GRID
  !

  ! Obtain the ip1's defined in the vertical grid
  n_error = vgd_new(o_vGridDescInit, TOCTOC_FILENUM, 'fst')
  if(n_error .ne. VGD_OK)write(6,*)'ERROR in TestVI, from vgd_new:', n_error

  ! Specify for which ip1's there are fields;
  ! make a selection from the defined levels
  n_error = vgd_get(o_vGridDescInit, 'VIPT', n_ip1_temp_p)
  if(n_error .ne. VGD_OK)write(6,*)'ERROR in TestVI, from vgd_get:', n_error

  n_ip1(1) = n_ip1_temp_p(3)
  n_ip1(2) = n_ip1_temp_p(5)
  n_ip1(3) = n_ip1_temp_p(8)
  n_ip1(4) = n_ip1_temp_p(10)

  if(present(l_reverseOrder) .and. l_reverseOrder .eqv. .true.) then
    n_ip1(4) = n_ip1_temp_p(3)
    n_ip1(3) = n_ip1_temp_p(5)
    n_ip1(2) = n_ip1_temp_p(8)
    n_ip1(1) = n_ip1_temp_p(10)
  end if

  deallocate(n_ip1_temp_p) ! vgd_get allocated it
  nullify(n_ip1_temp_p)

  o_vGridDescInit_p => o_vGridDescInit
  error=N_Viqkdef(o_gridInit_p, o_vGridDescInit_p, n_ip1=n_ip1(:n_PTS_INIT))
  if(error /= 0)write(6,*)'ERROR initializing gridInit:  ', error

  !
  ! CREATE THE TARGET GRID
  !

  ! Obtain the ip1's defined in the vertical grid
  n_error = vgd_new(o_vGridDescTarget, TOCTOC_FILENUM, 'fst')
  if(n_error .ne. VGD_OK)write(6,*)'ERROR in TestVI, from vgd_new:', n_error

  ! Specify for which ip1's there are fields (use 'VIPM' to have different
  ! levels); make a selection from the defined levels
  n_error = vgd_get(o_vGridDescTarget, 'VIPM', n_ip1_temp_p)
  if(n_error .ne. VGD_OK)write(6,*)'ERROR in TestVI, from vgd_get:', n_error

  n_ip1(1) = n_ip1_temp_p(2)
  n_ip1(2) = n_ip1_temp_p(6)
  n_ip1(3) = n_ip1_temp_p(7)
  n_ip1(4) = n_ip1_temp_p(9)
  n_ip1(5) = n_ip1_temp_p(13)
  deallocate(n_ip1_temp_p) ! vgd_get allocated it
  nullify(n_ip1_temp_p)

  o_vGridDescTarget_p => o_vGridDescTarget
  error=N_Viqkdef(o_gridTarget_p, o_vGridDescTarget_p, n_ip1=n_ip1)
  if(error /= 0)write(6,*)'ERROR initializing gridTarget:  ', error

  !
  ! SET THE INITIAL AND TARGET GRIDS
  !
  if (present(r_z0)) then
    error=N_Videfset   (o_gridTarget_p, o_gridInit_p, &
                        r_pSurf, r_z0=r_z0, r_ilmo=r_ilmo, r_hBound=r_hBound, r_lat=r_lat)
  else
    error=N_Videfset(o_gridTarget_p, o_gridInit_p, r_pSurf)
  end if
  if(error /= 0) write(6,*) 'ERROR in test:  videfset returned ', error


  !
  ! SET THE INTERPOLATION OPTIONS
  !
  error=N_Visetopt('interptype', s_interpType)
  if(error /= 0) then
    write(6,*) 'ERROR setting interptype:  N_Visetopt returned ', error
  end if

  error=N_Visetopt('extraptype', s_extrapType)
  if(error /= 0) then
    write(6,*) 'ERROR setting s_extrapType:  N_Visetopt returned ', error
  end if


  !
  ! PERFORM THE INTERPOLATION / EXTRAPOLATION
  !
!!$  if(s_extrapType == 'surfacewind') then
!!$                                        ! This is just a lazy way to call the
!!$                                        ! WIND stubs
!!$    error = N_Visint     (r_stateOut, r_stateIn, r_derivOut, r_derivIn, &
!!$                          r_extrapGuideDown, r_extrapGuideUp, &
!!$                          m_slStateValueWindStub, m_slFluxGradientWindStub, &
!!$                          r_zDest, r_zSrc, &
!!$                          r_y_stateOut, r_y_stateIn, r_y_derivOut, r_y_derivIn &
!!$                         )
!!$
!!$  else 
    error = N_Visint     (r_stateOut, r_stateIn, r_derivOut, r_derivIn, &
                          r_extrapGuideDown, r_extrapGuideUp, &
                          m_slStateValueStub, m_slFluxGradientStub, &
                          r_zDest, r_zSrc &
                         )
!!$  end if

  if(error /= 0) then
    write(6,*) 'ERROR interpolating:  N_Visint returned ', error
  end if


  !
  ! RELEASE THE GRIDS
  !
  call M_ReleaseVerticalGrid(o_gridInit_p)
  call M_ReleaseVerticalGrid(o_gridTarget_p)


  !
  ! VERIFY THE RESULTS
  !
  s_passFail = s_pass
  do k=1, n_nk
    do j=1,n_nj
      do i=1,n_ni
        if (     abs(r_stateOut(i,j,k)   - r_stateAnswer(i,j,k)  ) > 1.6e-5 &
            .or. abs(r_derivOut(i,j,k  ) - r_derivAnswer(i,j,k)  ) > 2e-5) then
          l_pass = .false.
          s_passFail = s_fail
          exit
        end if
        if(present(r_y_stateAnswer))then
          if (     abs(r_y_stateOut(i,j,k) - r_y_stateAnswer(i,j,k)) > 1e-6 &
              .or. abs(r_y_derivOut(i,j,k) - r_y_derivAnswer(i,j,k)) > 1e-6) then
            l_pass = .false.
            s_passFail = s_fail
            exit
          end if
        end if
      end do
    end do
  end do

  write(6,*) s_passFail
  write(6,*)'stateOut='
  do i=1,n_NI
    write(6,'((10f12.7))') ((r_stateOut(i,j,k),k=1,n_PTS_TARGET),j=1,n_NJ)
  end do

  write(6,*)'derivOut='
  do i=1,n_NI
    write(6,'((10f12.7))') ((r_derivOut(i,j,k),k=1,n_PTS_TARGET),j=1,n_NJ)
  end do

  if(present(r_y_stateAnswer))then
    write(6,*)'y_stateOut='
    do i=1,n_NI
      write(6,'((10f12.7))') ((r_y_stateOut(i,j,k),k=1,n_PTS_TARGET),j=1,n_NJ)
    end do

    write(6,*)'y_derivOut='
    do i=1,n_NI
      write(6,'((10f12.7))') ((r_y_derivOut(i,j,k),k=1,n_PTS_TARGET),j=1,n_NJ)
    end do
  end if


end subroutine m_testOneCombo_5005






!!!s/r m_setVcode - set the vgrid parameters (vcode, kind, version), based on the
!                   N_GRID_TYPE
subroutine m_setVcode(n_grid_type, n_vcode, n_vgd_kind, n_vgd_version)
!
!AUTHOR
!     J.W. Blezius July 2015
!
!OBJECT
!        To translate the local definition of grid type (N_GRID_TYPE_*) to the
!        vgrid definition of grid type (n_vgd_kind and n_vgd_version).
!
!ARGUMENTS
  integer, intent(in)  :: n_grid_type
  integer, intent(out) :: n_vcode, n_vgd_kind, n_vgd_version
!
!NOTES
!
!!

  select case (n_grid_type)
  case (N_GRID_TYPE_SIGMA)
    n_vcode = 1001

  case (N_GRID_TYPE_ETA)
    n_vcode = 1002

  case (N_GRID_TYPE_HYBRID)
    n_vcode = 1003

  case (N_GRID_TYPE_PRESSURE)
    n_vcode = 2001

  case (N_GRID_TYPE_HYBRID_NOTNORM)
    n_vcode = 5001

  case (N_GRID_TYPE_STAGGERED)
    n_vcode = 5002

  case (N_GRID_TYPE_STAG5005)
    n_vcode = 5005

  case default
    n_vcode = 0
    write(*,*)"ERROR in m_setVcode:  n_gridType not recognized:  ", n_gridType
  end select

  n_vgd_kind    = n_vcode / 1000
  n_vgd_version = n_vcode - (n_vgd_kind * 1000)
end subroutine m_setVcode






!!!s/r m_testOneCombo_2GridTypes - routine that tests a single combination of
!                       parameters, with two different grid types.
subroutine m_testOneCombo_2GridTypes &
                         (s_title, n_gridTypeIn, n_gridTypeOut, &
                          s_interpType, s_extrapType, &

                          r_levelsInit,   r_stateIn , r_derivIn, &
                          r_levelsTarget, r_stateAnswer, r_derivAnswer, &

                          r_extrapGuideDown, r_extrapGuideUp, &

                          r_pTopInit, r_pRefInit, r_rCoefInit, &
                          r_pTopTarget, r_pRefTarget, r_rCoefTarget, &
                          r_pSurf, &

                          r_rCoef_2_Init, r_rCoef_2_Target &
                         )
!
!AUTHOR
!     J.W. Blezius Feb 2015
!
!OBJECT
!        To test the ez_interpv package, with two different grid types
!
!ARGUMENTS
  use VerticalGrid_90_class, only: T_VerticalGrid, N_Viqkdef
  use VerticalInterpolation_90_class, only: N_Videfset, N_Visint
  implicit none

                                        ! parameters of most interest
  character(*), intent(in) :: s_title
  integer, intent(in) :: n_gridTypeIn, n_gridTypeOut
  character(*), intent(in) :: s_interpType, s_extrapType

                                        ! input data for the interpolation and
                                        ! the expected results
  real(test48), dimension(:), intent(in) :: r_levelsInit, r_levelsTarget
  real(test48), dimension(:,:,:), intent(in) :: r_stateIn , r_derivIn, &
                                        r_stateAnswer, r_derivAnswer

                                        ! more interpolation parameters
  real(test48), intent(in) :: r_extrapGuideDown, r_extrapGuideUp

                                        ! grid parameters
  real, intent(in) :: r_pTopInit, r_pRefInit, r_rCoefInit, &
                      r_pTopTarget, r_pRefTarget, r_rCoefTarget, &
                      r_rCoef_2_Init, r_rCoef_2_Target
  real(test48), dimension(:,:), intent(in) :: r_pSurf
!
!NOTES
!
!!

                                        ! a place to hold the results
  real(test48), &
        dimension(ubound(r_stateAnswer,1), &
                  ubound(r_stateAnswer,2), &
                  ubound(r_stateAnswer,3)) :: r_stateOut   , r_derivOut, &
                                              r_y_stateOut , r_y_derivOut

  integer :: i, j, k, n_ni, n_nj, n_nk
  integer :: n_error, n_vcode, n_vgd_kind, n_vgd_version

  type(T_VerticalGrid), target  :: o_gridInit,   o_gridTarget
  type(T_VerticalGrid), pointer :: o_gridInit_p, o_gridTarget_p

  type(vgrid_descriptor), target  :: o_vGridDescInit,   o_vGridDescTarget
  type(vgrid_descriptor), pointer :: o_vGridDescInit_p, o_vGridDescTarget_p

                                        ! The ip1's of the field levels that are
                                        ! present in the associated field
  integer, pointer, dimension(:) :: n_ip1_p, n_ip1_temp_p

  real(8) :: ptop_out_dummy

  character(len=19) :: s_pass     = '  PASS', &
                       s_fail     = '  **** F A I L ****', &
                       s_passFail = '  **** T E M P ****'

  nullify(n_ip1_temp_p)

  o_gridInit_p   => o_gridInit
  o_gridTarget_p => o_gridTarget
  o_gridInit_p%N_ip1_p         => null()
  o_gridInit_p%O_vGridDesc_p   => null()
  o_gridTarget_p%N_ip1_p       => null()
  o_gridTarget_p%O_vGridDesc_p => null()

  write(6,*)
  write(6,*) s_title

  n_ni = ubound(r_stateAnswer,1)
  n_nj = ubound(r_stateAnswer,2)
  n_nk = ubound(r_stateAnswer,3)



  ! Clear the destination tables
  r_stateOut=0.
  r_derivOut=0.
  r_y_stateOut=0.
  r_y_derivOut=0.

  !
  ! CREATE THE INITIAL GRID
  !
  call m_setVcode(n_gridTypeIn, n_vcode, n_vgd_kind, n_vgd_version)

  select case(n_vcode)
  case (1001)  ! N_GRID_TYPE_SIGMA
    n_error = vgd_new(o_vGridDescInit, n_vgd_kind, n_vgd_version, &
                      real(r_levelsInit))

  case (1002)  ! N_GRID_TYPE_ETA
    n_error = vgd_new(o_vGridDescInit, n_vgd_kind, n_vgd_version, &
                      real(r_levelsInit),&
                      ptop_8=real(r_pTopInit/r_MBAR_PER_PASCAL, kind=8))

  case (1003)  ! N_GRID_TYPE_HYBRID
    n_error = vgd_new(o_vGridDescInit, n_vgd_kind, n_vgd_version, &
                      real(r_levelsInit), r_rCoefInit, &
                      ptop_8=real(r_pTopInit/r_MBAR_PER_PASCAL, kind=8),&
                      pref_8=real(r_pRefInit/r_MBAR_PER_PASCAL, kind=8))

  case (2001)  ! N_GRID_TYPE_PRESSURE
    n_error = vgd_new(o_vGridDescInit, n_vgd_kind, n_vgd_version, &
                      real(r_levelsInit))

  case (5001)  ! N_GRID_TYPE_HYBRID_NOTNORM
    n_error = vgd_new(o_vGridDescInit, n_vgd_kind, n_vgd_version, &
                      real(r_levelsInit), r_rCoefInit, &
                      ptop_8=real(r_pTopInit/r_MBAR_PER_PASCAL, kind=8),&
                      pref_8=real(r_pRefInit/r_MBAR_PER_PASCAL, kind=8))

! N_GRID_TYPE_STAGGERED is no longer supported by vgrid
!!$  case (5002)  ! N_GRID_TYPE_STAGGERED
!!$    n_error = vgd_new(o_vGridDescInit, n_vgd_kind, n_vgd_version, &
!!$                    real(r_levelsInit), r_rCoefInit, r_rCoef_2_Init,&
!!$                    real(r_pTopInit/r_MBAR_PER_PASCAL, kind=8), &
!!$                    real(r_pRefInit/r_MBAR_PER_PASCAL, kind=8))

  case (5005)  ! N_GRID_TYPE_STAG5005
    n_error = vgd_new(o_vGridDescInit, n_vgd_kind, n_vgd_version, &
                      real(r_levelsInit), r_rCoefInit, r_rCoef_2_Init,&
                      pref_8=real(r_pRefInit/r_MBAR_PER_PASCAL, kind=8), &
                      ptop_out_8=ptop_out_dummy, &
                      dhm=10.0, dht=1.5)

  case default
    write(*,*)"In m_testOneCombo_2GridTypes, n_vcode not recognized:  ", n_vcode
  end select
  if(n_error /= VGD_OK)write(6,*)'Error from vgd_new in TestVI:  error=', n_error

  ! In order to be useful, o_vGridDescInit will require n_ip1_p
  ! (Ask for VIPM, because vgd_new assumed the r_vLevelIn to be VIPM.)
  n_error = vgd_get(o_vGridDescInit, 'VIPM', n_ip1_temp_p)
  if(n_error .ne. VGD_OK)write(6,*)'ERROR in TestVI, from vgd_get:', n_error

  ! vgd might have (depending on the grid type) added hyb=1 (the last
  ! entry) and the 10m level (after hyb=1) to the list.  Remove them.
  allocate(n_ip1_p(n_PTS_INIT), STAT=n_error)
  if(n_error /= 0)write(6,*)'Error allocating n_ip1_p in TestVI:  error=',n_error
  n_ip1_p(:) = n_ip1_temp_p(:n_PTS_INIT)
  deallocate(n_ip1_temp_p) ! vgd_get allocated it
  nullify(n_ip1_temp_p)

  o_vGridDescInit_p => o_vGridDescInit
  error=N_Viqkdef(o_gridInit_p, o_vGridDescInit_p, n_ip1=n_ip1_p)
  if(error /= 0)write(6,*)'ERROR initializing gridInitial:  ', error
  deallocate(n_ip1_p)
  nullify(n_ip1_p)


  !
  ! CREATE THE TARGET GRID
  !
  call m_setVcode(n_gridTypeOut, n_vcode, n_vgd_kind, n_vgd_version)

  select case(n_vcode)
  case (1001)  ! N_GRID_TYPE_SIGMA
        n_error = vgd_new(o_vGridDescTarget, n_vgd_kind, n_vgd_version, &
                          real(r_levelsTarget))

  case (1002)  ! N_GRID_TYPE_ETA
    n_error = vgd_new(o_vGridDescTarget, n_vgd_kind, n_vgd_version, &
                      real(r_levelsTarget),&
                      ptop_8=real(r_pTopTarget/r_MBAR_PER_PASCAL, kind=8))

  case (1003)  ! N_GRID_TYPE_HYBRID
    n_error = vgd_new(o_vGridDescTarget, n_vgd_kind, n_vgd_version, &
                      real(r_levelsTarget), r_rCoefTarget, &
                      ptop_8=real(r_pTopTarget/r_MBAR_PER_PASCAL, kind=8),&
                      pref_8=real(r_pRefTarget/r_MBAR_PER_PASCAL, kind=8))

  case (2001)  ! N_GRID_TYPE_PRESSURE
    n_error = vgd_new(o_vGridDescTarget, n_vgd_kind, n_vgd_version, &
                      real(r_levelsTarget))

  case (5001)  ! N_GRID_TYPE_HYBRID_NOTNORM
    n_error = vgd_new(o_vGridDescTarget, n_vgd_kind, n_vgd_version, &
                      real(r_levelsTarget), r_rCoefTarget, &
                      ptop_8=real(r_pTopTarget/r_MBAR_PER_PASCAL, kind=8),&
                      pref_8=real(r_pRefTarget/r_MBAR_PER_PASCAL, kind=8))

! N_GRID_TYPE_STAGGERED is no longer supported by vgrid
!!$  case (5002)  ! N_GRID_TYPE_STAGGERED
!!$    n_error = vgd_new(o_vGridDescTarget, n_vgd_kind, n_vgd_version, &
!!$                    real(r_levelsTarget), r_rCoefTarget, r_rCoef_2_Target,&
!!$                    real(r_pTopTarget/r_MBAR_PER_PASCAL, kind=8), &
!!$                    real(r_pRefTarget/r_MBAR_PER_PASCAL, kind=8))

  case (5005)  ! N_GRID_TYPE_STAG5005
    n_error = vgd_new(o_vGridDescTarget, n_vgd_kind, n_vgd_version, &
                      real(r_levelsTarget), r_rCoefTarget, r_rCoef_2_Target,&
                      pref_8=real(r_pRefTarget/r_MBAR_PER_PASCAL, kind=8), &
                      ptop_out_8=ptop_out_dummy, &
                      dhm=10.0, dht=1.5)

  case default
    write(*,*)"In m_testOneCombo_2GridTypes, n_vcode not recognized:  ", n_vcode
  end select
  if(n_error /= VGD_OK)write(6,*)'Error from vgd_new in TestVI:  error=', n_error

  ! In order to be useful, o_vGridDescTarget will require n_ip1_p
  ! (Ask for VIPM, because vgd_new assumed the r_vLevelIn to be VIPM.)
  n_error = vgd_get(o_vGridDescTarget, 'VIPM', n_ip1_temp_p)
  if(n_error .ne. VGD_OK)write(6,*)'ERROR in TestVI, from vgd_get:', n_error

  ! vgd might have (depending on the grid type) added hyb=1 (the last
  ! entry) and the 10m level (after hyb=1) to the list.  Remove them.
  allocate(n_ip1_p(n_PTS_TARGET), STAT=n_error)
  if(n_error /= 0)write(6,*)'Error allocating n_ip1_p in TestVI:  error=',n_error
  n_ip1_p(:) = n_ip1_temp_p(:n_PTS_TARGET)
  deallocate(n_ip1_temp_p) ! vgd_get allocated it
  nullify(n_ip1_temp_p)

  o_vGridDescTarget_p => o_vGridDescTarget
  error=N_Viqkdef(o_gridTarget_p, o_vGridDescTarget_p, n_ip1=n_ip1_p)
  if(error /= 0)write(6,*)'ERROR initializing gridTarget:  ', error
  deallocate(n_ip1_p)
  nullify(n_ip1_p)


  !
  ! SET THE INITIAL AND TARGET GRIDS
  !
  error=N_Videfset(o_gridTarget_p, o_gridInit_p, r_pSurf)
  if(error /= 0) write(6,*) 'ERROR in test:  N_Videfset returned ', error


  !
  ! SET THE INTERPOLATION OPTIONS
  !
  error=N_Visetopt('interptype', s_interpType)
  if(error /= 0) then
    write(6,*) 'ERROR setting interptype:  N_Visetopt returned ', error
  end if

  error=N_Visetopt('extraptype', s_extrapType)
  if(error /= 0) then
    write(6,*) 'ERROR setting s_extrapType:  N_Visetopt returned ', error
  end if


  !
  ! PERFORM THE INTERPOLATION / EXTRAPOLATION
  !
  error = N_Visint     (r_stateOut, r_stateIn, r_derivOut, r_derivIn, &
                        r_extrapGuideDown, r_extrapGuideUp, &
                        m_slStateValueStub, m_slFluxGradientStub &
                       )
  if(error /= 0) then
    write(6,*) 'ERROR interpolating:  N_Visint returned ', error
  end if


  !
  ! VERIFY THE RESULTS
  !
  s_passFail = s_pass
  do k=1, n_nk
    do j=1,n_nj
      do i=1,n_ni
        if (     abs(r_stateOut(i,j,k)   - r_stateAnswer(i,j,k)  ) > 8e-6 &
            .or. abs(r_derivOut(i,j,k)   - r_derivAnswer(i,j,k)  ) >11e-6) then
          l_pass = .false.
          s_passFail = s_fail
          exit
        end if
      end do
    end do
  end do

  write(6,*) s_passFail
  write(6,*)'stateOut='
  do i=1,n_NI
    write(6,'((10f12.7))') ((r_stateOut(i,j,k),k=1,n_PTS_TARGET),j=1,n_NJ)
  end do

  write(6,*)'derivOut='
  do i=1,n_NI
    write(6,'((10f12.7))') ((r_derivOut(i,j,k),k=1,n_PTS_TARGET),j=1,n_NJ)
  end do


end subroutine m_testOneCombo_2GridTypes






!!!s/r m_testOneCombo_ip1Type - routine that tests a single combination of
!                               parameters, using ip1Type parameter of N_Viqkdef
subroutine m_testOneCombo_ip1Type(s_title, s_interpType, s_extrapType, &

                          r_stateIn , r_derivIn, &
                          r_stateAnswer, r_derivAnswer, &

                          r_extrapGuideDown, r_extrapGuideUp, &

                          r_pSurf &
                         )
!
!AUTHOR
!     J.W. Blezius Aug 2015
!
!OBJECT
!        To test the ez_interpv package.
!
!ARGUMENTS
  use VerticalGrid_90_class
  use VerticalInterpolation_90_class
  implicit none

                                        ! parameters of most interest
  character(*), intent(in) :: s_title
  character(*), intent(in) :: s_interpType, s_extrapType

                                        ! input data for the interpolation and
                                        ! the expected results
  real(test48), dimension(:,:,:), intent(in) :: r_stateIn , r_derivIn, &
                                        r_stateAnswer, r_derivAnswer

                                        ! more interpolation parameters
  real(test48), intent(in) :: r_extrapGuideDown, r_extrapGuideUp

                                        ! grid parameter
  real(test48), dimension(:,:), intent(in) :: r_pSurf
!
!NOTES
!        Assume that both the initial and target grid types are as defined in the
!        file, TOCTOC_FILENUM; i.e. N_GRID_TYPE_STAG5005.
!
!!
                                        ! a place to hold the results
  real(test48), &
        dimension(ubound(r_stateAnswer,1), &
                  ubound(r_stateAnswer,2), &
                  ubound(r_stateAnswer,3)) :: r_stateOut   , r_derivOut

  integer :: i, j, k, n_ni, n_nj, n_nk, n_error

  type(T_VerticalGrid), target  :: o_gridInit  , o_gridTarget
  type(T_VerticalGrid), pointer :: o_gridInit_p, o_gridTarget_p

  type(vgrid_descriptor), target  :: o_vGridDescInit,   o_vGridDescTarget
  type(vgrid_descriptor), pointer :: o_vGridDescInit_p, o_vGridDescTarget_p

  character(len=19) :: s_pass     = '  PASS', &
                       s_fail     = '  **** F A I L ****', &
                       s_passFail = '  **** T E M P ****'

  write(6,*)
  write(6,*) s_title

  o_gridInit_p   => o_gridInit
  o_gridTarget_p => o_gridTarget
  o_gridInit_p%N_ip1_p         => null()
  o_gridInit_p%O_vGridDesc_p   => null()
  o_gridTarget_p%N_ip1_p       => null()
  o_gridTarget_p%O_vGridDesc_p => null()

  n_ni = ubound(r_stateAnswer,1)
  n_nj = ubound(r_stateAnswer,2)
  n_nk = ubound(r_stateAnswer,3)



  ! Clear the destination tables
  r_stateOut=0.
  r_derivOut=0.

  !
  ! CREATE THE INITIAL GRID
  !
  n_error = vgd_new(o_vGridDescInit, TOCTOC_FILENUM, 'fst')
  if(n_error .ne. VGD_OK)write(6,*)'ERROR in TestVI, from vgd_new:', n_error

  o_vGridDescInit_p => o_vGridDescInit
  error=N_Viqkdef(o_gridInit_p, o_vGridDescInit_p, s_ip1Type='VIPM')
  if(error /= 0)write(6,*)'ERROR initializing gridInit:  ', error

  !
  ! CREATE THE TARGET GRID
  !
  n_error = vgd_new(o_vGridDescTarget, TOCTOC_FILENUM, 'fst')
  if(n_error .ne. VGD_OK)write(6,*)'ERROR in TestVI, from vgd_new:', n_error

  o_vGridDescTarget_p => o_vGridDescTarget
  error=N_Viqkdef(o_gridTarget_p, o_vGridDescTarget_p, s_ip1Type='VIPT')
  if(error /= 0)write(6,*)'ERROR initializing gridTarget:  ', error

  !
  ! SET THE INITIAL AND TARGET GRIDS
  !
  error=N_Videfset(o_gridTarget_p, o_gridInit_p, r_pSurf)
  if(error /= 0) write(6,*) 'ERROR in test:  videfset returned ', error


  !
  ! SET THE INTERPOLATION OPTIONS
  !
  error=N_Visetopt('interptype', s_interpType)
  if(error /= 0) then
    write(6,*) 'ERROR setting interptype:  N_Visetopt returned ', error
  end if

  error=N_Visetopt('extraptype', s_extrapType)
  if(error /= 0) then
    write(6,*) 'ERROR setting s_extrapType:  N_Visetopt returned ', error
  end if


  !
  ! PERFORM THE INTERPOLATION / EXTRAPOLATION
  !
  error = N_Visint     (r_stateOut, r_stateIn, r_derivOut, r_derivIn, &
                        r_extrapGuideDown, r_extrapGuideUp, &
                        m_slStateValueStub, m_slFluxGradientStub &
                       )
  if(error /= 0) then
    write(6,*) 'ERROR interpolating:  N_Visint returned ', error
  end if


  !
  ! RELEASE THE GRIDS
  !
  call M_ReleaseVerticalGrid(o_gridInit_p)
  call M_ReleaseVerticalGrid(o_gridTarget_p)


  !
  ! VERIFY THE RESULTS
  !
  s_passFail = s_pass
  do k=1,21
    do j=1,1
      do i=1,1
        if (     abs(r_stateOut(i,j,k)   - r_stateAnswer(i,j,k)  ) > 8e-6 &
            .or. abs(r_derivOut(i,j,k  ) - r_derivAnswer(i,j,k)  ) >11e-6) then
          l_pass = .false.
          s_passFail = s_fail
          exit
        end if
      end do
    end do
  end do

  write(6,*) s_passFail
  write(6,*)'stateOut='
  do i=1,n_NI
    write(6,'((10f12.7))') ((r_stateOut(i,j,k),k=1,21),j=1,1)
  end do

  write(6,*)'derivOut='
  do i=1,n_NI
    write(6,'((10f12.7))') ((r_derivOut(i,j,k),k=1,21),j=1,1)
  end do

end subroutine m_testOneCombo_ip1Type
end program











!#include "phy_macros_f.h":!copyright (C) 2001  MSC-RPN COMM  %%%RPNPHY%%%
#ifdef DOC
!
! Successive calls to the following macros generate
! two common blocks:
!
!    * MARK_COMPHY_BEG: marks the beginning of the common block
!      of "pointers" (of type INTEGER) that define the structure
!      of the bus
!    * MARK_COMPHY_END: marks the end of the same common block
!    * DCL_PHYVAR: this macro has to be called for each variable
!      included in the bus. If DCLCHAR is not defined, then only
!      the common block of "pointers" is created. If DCLCHAR is
!      defined, then both the common block of "pointers" and the
!      common block of the corresponding "names" (of type CHARACTER)
!      are created.
!
! Example:
!       SUBROUTINE BIDON
! #define DCLCHAR
! #include "phy_macros_f.h"
!       MARK_COMPHY_BEG (phybus)           ! Begins the common block "phybus"
!       DCL_PHYVAR( AL        ,phybus)     ! Adds one "pointer" to the common block
!       DCL_PHYVAR( MG        ,phybus)
!       ...
!       DCL_PHYVAR( Z0        ,phybus)
!       MARK_COMPHY_END (phybus)           ! Ends the common block "phybus"
!       equivalence (phybus_i_first(1),AL) ! "pointer" AL is now the first element
!                                            of the common block "phybus"
!       ...
!       return
!       end
!
! For details of implementation, see comdeck "phybus.cdk"
! and subroutine "phy_ini.ftn" in the physics library.
!
! Author : Vivian Lee (Nov 2000) - adapted by B. Bilodeau
!
#endif

#define _cat_(name1,name2) name1##name2

#define _cat3_(name1,name2,name3) name1##name2##name3

#define AUTOMATIC(name,type,dims)  \
type _cat_(name,dims)

#ifndef DCLCHAR

#define DCL_PHYVAR(__TOKEN__,_COM_) \
integer __TOKEN__ \
common/_cat_(_COM_,_i)/__TOKEN__ \

#define MARK_COMPHY_BEG(_COM_)  \
integer _cat3_(_COM_,_i,_first(-1:0)) \
common /_cat_(_COM_,_i)/_cat3_(_COM_,_i,_first)

#else

#define DCL_PHYVAR(__TOKEN__,_COM_) \
integer __TOKEN__ \
character*8 _cat_(__TOKEN__,_c) \
data  _cat_(__TOKEN__,_c) /'__TOKEN__'/ \
common/_cat_(_COM_,_i)/__TOKEN__ \
common/_cat_(_COM_,_c)/_cat_(__TOKEN__,_c)

#define MARK_COMPHY_BEG(_COM_) \
integer _cat3_(_COM_,_i,_first(-1:0)) \
common /_cat_(_COM_,_i)/_cat3_(_COM_,_i,_first) \
character*8 _cat3_(_COM_,_c,_first(-1:0)) \
common /_cat_(_COM_,_c)/_cat3_(_COM_,_c,_first)

#endif

#define MARK_COMPHY_END(_COM_) \
integer _cat3_(_COM_,_i,_last) \
common /_cat_(_COM_,_i)/_cat3_(_COM_,_i,_last)

#define COMPHY_SIZE(_COM_) (loc(_cat3_(_COM_,_i,_last))-\
loc(_cat3_(_COM_,_i,_first(0)))-1)/(loc(_cat3_(_COM_,_i,_first(0)))-\
loc(_cat3_(_COM_,_i,_first(-1))))
!end of #include "phy_macros_f.h"




!!s/r m_slFluxGradientStub - Testing stub for the FluxGradient routine
subroutine m_slFluxGradientStub(ft,dtdz,ttop,tsurf,ztop,z0t,ilmo,h,n)
!!$subroutine m_slFluxGradientStub(r_ft, &
!!$                            r_dtdz, &
!!$                            r_stateIn(:,:,n_indexSurface_plus1), &
!!$                            r_stateIn(:,:,n_indexSurface), &
!!$                            r_zSrc(:,:,n_indexSurface_plus1), &
!!$                            r_z0_a, &
!!$                            r_ilmo_a, &
!!$                            r_hBound_a, &
!!$                            n_ni*n_nj)
!
!AUTHOR
!     Y. Delage    OCT 2003
!
!REVISION
! v1_3    Blezius J.W. OCT 2003 - extracted from the physics library
!
!OBJECT
!        To fill the role, in part, of the physics library during testing.  The
!        routine is copied here so as to keep this test independent of changes in
!        the physics library.
!
!        Calculates the surface flux and the slope of the temperature
!        or humidity profile at the top of the surface layer (SL)
!
!ARGUMENTS
      IMPLICIT NONE
      INTEGER N
      REAL(test48) FT(N),DTDZ(N),TTOP(N),TSURF(N),ZTOP(N),Z0T(N)
      REAL(test48) ILMO(N),H(N)

!          - Output -
! FT      normalised temperature or humidity flux at surface
! DTDZ    slope of temperature or humidity profile at top of SL
!
!          - Input -
! TTOP    temperature or humidity at the top of surface layer
! TSURF   temperature or humidity at the surface
! ZTOP    height of the top of the surface layer
! Z0T     roughness length for temperature/humidity
! ILMO    inverse of MONIN-OBUKHOV lenth
! H       height of boundary layer (for stable case only)
! N       number of horizontal points to process
!
!NOTES
!        This routine was supplied from the physics library by Yves Delage, who
!        called it sltop_tq, and put together by J.W. Blezius.
!
!!

      INTEGER J

!***************************************************************
!     AUTOMATIC ARRAYS
      REAL(test48) FH(N)
!***************************************************************
      REAL AS,ASX,CI,BS,BETA,FACTN,HMIN,ANGMAX
!
!#include "surfcon_ini.cdk":
! Initilisation of constants in the common SURFCON
!
! Note: some of the constants may be reinitialised at runtime using a namelist

      AS    = 12.
      ASX   = 5.
      CI    = 40.
      BS    = 1.0
      BETA  = 1.0
      FACTN = 1.2
      HMIN  = 30.
      ANGMAX= 0.85

! end of #include "surfcon_ini.cdk"

      call m_slStateValueStub(fh,ztop,z0t,ilmo,h,n)
      DO J=1,N
        ft(j)=(ttop(j)-tsurf(j))/fh(j)
        dtdz(j)=ft(j)*phih(real(ztop(j)),real(ilmo(j)),real(h(j)))/(ztop(j)+z0t(j))
      END DO
!
      return


CONTAINS
!#include "deriv_stabfunc.cdk":
!  Derivatives of the stability functions

        REAL FUNCTION PHIM(Z,ILMO,H)

        REAL Z,ILMO,H,HH

        HH=MAX(1-Z/H,FACTN-1.0)
        IF(ILMO.GT.0.) THEN
           PHIM=MIN(1.+ASX*BETA*Z*ILMO,0.5*(HH+SQRT(HH**2+ &
                4.*AS*BETA*Z*ILMO*HH)))
        ELSE
           PHIM=(1.-CI*BETA*Z*ILMO)**(-.1666666)
        END IF
        RETURN
        END FUNCTION

        REAL FUNCTION PHIH(Z,ILMO,H)

        REAL Z,ILMO,H,HH

        HH=MAX(1-Z/H,FACTN-1.0)
        IF(ILMO.GT.0.) THEN
           PHIH=BETA*MIN(1.+ASX*BETA*Z*ILMO,0.5*(HH+SQRT(HH**2+ &
                4.*AS*BETA*Z*ILMO*HH)))
        ELSE
           PHIH=(1.-CI*BETA*Z*ILMO)**(-.333333333)
        END IF
        RETURN
        END FUNCTION


!end of #include "deriv_stabfunc.cdk"
end subroutine m_slFluxGradientStub








!!s/r m_slStateValueStub - Testing stub for the StateValue routine
!#include "phy_macros_f.h" -- already included before the previous routine
subroutine m_slStateValueStub(fh_48,z_48,z0t_48,ilmo_48,h_48,n)
!subroutine m_slStateValueStub(f,zz,z0,ilmo,h,n)
!
!AUTHOR
!     Y. Delage    OCT 2003
!
!REVISION
! v1_3    Blezius J.W. OCT 2003 - extracted from the physics library
!
!OBJECT
!        To fill the role, in part, of the physics library during testing.  The
!        routine is copied here so as to keep this test independent of changes in
!        the physics library.
!
!        Calculates the integrated surface-layer functions for interpolating
!        temperature, humidity, and other passive variables.
!
!ARGUMENTS
      IMPLICIT NONE
      INTEGER N
      REAL(test48) FH_48(N),Z_48(N),Z0T_48(N),ILMO_48(N),H_48(N)
!
!          - Output -
! FH      normalised temperature or humidity value at desired height
!
!          - Input -
! Z       height of desired output
! Z0T     roughness length for temperature/humidity
! ILMO    inverse of MONIN-OBUKHOV lenth
! H       height of boundary layer (for stable case only)
! N       number of horizontal points to process
!
!NOTES
!        This routine was supplied from the physics library by Yves Delage, who
!        called it slfun_tq, and put together by J.W. Blezius.
!
!!

      INTEGER J
      REAL AS,ASX,CI,BS,BETA,FACTN,HMIN,ANGMAX
      REAL FH(N),Z(N),Z0T(N),ILMO(N),H(N)

      REAL RAC3,X,X0,Y,Y0,Z0(1),HI,LZZ0(1)

!********************************************************************
!     AUTOMATIC ARRAYS
      REAL LZZ0T(N)
!********************************************************************

!#include "surfcon_ini.cdk":
! Initilisation of constants in the common SURFCON
!
! Note: some of the constants may be reinitialised at runtime using a namelist

      Z(:)    = real(Z_48(:),4)
      Z0T(:)  = real(Z0T_48(:),4)
      ILMO(:) = real(ILMO_48(:),4)
      H(:)    = real(H_48(:),4)

      AS    = 12.
      ASX   = 5.
      CI    = 40.
      BS    = 1.0
      BETA  = 1.0
      FACTN = 1.2
      HMIN  = 30.
      ANGMAX= 0.85

! end of #include "surfcon_ini.cdk"

      RAC3=SQRT(3.)

      DO J=1,N
      LZZ0T(J)=LOG(Z(J)/Z0T(J)+1)
      IF(ILMO(J).LE.0.) THEN
!---------------------------------------------------------------------
!                      UNSTABLE CASE
           FH(J)= fhi(z(j)+z0t(j),j)
      ELSE
!---------------------------------------------------------------------
!                        STABLE CASE
        hi=1/MAX(H(J),hmin,factn/(4*AS*BETA*ilmo(j)), &
             (Z(J)+10*Z0T(J))*factn)
        fh(j)=BETA*(LZZ0T(J)+min(psi(Z(J)+Z0T(J),j)-psi(Z0T(J),j), &
                           ASX*BETA*ILMO(J)*Z(J))) 
      ENDIF
!---------------------------------------------------------------------
      END DO
      
      FH_48(:)   = real(FH(:),test48)

      return


CONTAINS
!#include "stabfunc.cdk":
!   Internal function FMI
!   Stability function for momentum in the unstable regime (ilmo<0)
!   Reference: Delage Y. and Girard C. BLM 58 (19-31) Eq. 19

      REAL FUNCTION FMI(Z,I)

      REAL Z
      integer i

      X=(1-CI*Z*BETA*ILMO(I))**(0.1666666)
      X0=(1-CI*Z0(I)*BETA*ILMO(I))**(0.1666666)
      FMI=LZZ0(I)+LOG((X0+1)**2*SQRT(X0**2-X0+1)*(X0**2+X0+1)**1.5 &
                     /((X+1)**2*SQRT(X**2-X+1)*(X**2+X+1)**1.5)) &
                    +RAC3*ATAN(RAC3*((X**2-1)*X0-(X0**2-1)*X)/ &
                    ((X0**2-1)*(X**2-1)+3*X*X0))

      RETURN
      END FUNCTION

!   Internal function FHI
!   Stability function for heat and moisture in the unstable regime (ilmo<0)
!   Reference: Delage Y. and Girard C. BLM 58 (19-31) Eq. 17

      REAL FUNCTION FHI(Z,I)

      REAL Z
      integer i

      Y=(1-CI*Z*BETA*ILMO(I))**(0.33333333)
      Y0=(1-CI*Z0T(I)*BETA*ILMO(I))**(0.3333333)
      FHI=BETA*(LZZ0T(I)+1.5*LOG((Y0**2+Y0+1)/(Y**2+Y+1))+RAC3* &
              ATAN(RAC3*2*(Y-Y0)/((2*Y0+1)*(2*Y+1)+3)))

      RETURN
      END FUNCTION

!   Internal function psi
!   Stability function for momentum in the stable regime (unsl>0)
!   Reference :  Y. Delage, BLM, 82 (p23-48) (Eqs.33-37)

      REAL FUNCTION PSI(Z,I)

      REAL Z,a,b,c,d
      integer i

      d = 4*AS*BETA*ilmo(i)
      c = d*hi - hi**2
      b = d - 2*hi
      a = sqrt(1 + b*z - c*z**2)
      psi = 0.5 * (a-z*hi-log(1+b*z*0.5+a)- &
                  b/(2*sqrt(c))*asin((b-2*c*z)/d))

      RETURN
      END FUNCTION
! end of #include "stabfunc.cdk"
end subroutine m_slStateValueStub




!!s/r m_slFluxGradientWindStub - Testing stub for FluxGradient routine, for wind
subroutine m_slFluxGradientWindStub(nss,dudz,dvdz,angtop,angmax, &
                                    utop,vtop,ztop,z0,ilmo,h,lat,n)
!!$subroutine m_slFluxGradientWindStub( &
!!$                             r_ft, r_dtdz, r_y_dtdz, r_angleTop, r_angleMax, &
!!$                             r_stateIn  (:,:,n_indexSurface_plus1), &
!!$                             r_y_stateIn(:,:,n_indexSurface_plus1), &
!!$                             r_zSrc     (:,:,n_indexSurface_plus1), &
!!$                             r_z0_a, &
!!$                             r_ilmo_a, &
!!$                             r_hBound_a, &
!!$                             r_latitude_a, &
!!$                             n_ni*n_nj)
!
!AUTHOR
!     Y. Delage    OCT 2003
!
!REVISION
! v1_3    Blezius J.W. OCT 2003 - extracted from the physics library
!
!OBJECT
!        To fill the role, in part, of the physics library during testing.  The
!        routine is copied here so as to keep this test independent of changes in
!        the physics library.
!
!        Calculates the surface stress and the slopes of the wind component
!        profiles at the top of the surface layer (SL)
!
!ARGUMENTS
      IMPLICIT NONE
      INTEGER N
      REAL NSS(N),DUDZ(N),DVDZ(N),ANGTOP(N), &
           UTOP(N),VTOP(N),ZTOP(N),Z0(N),ILMO(N),H(N),LAT(N)
      REAL ANGMAX

!          - Output -
! NSS     normalised surface stress
! DUDZ    slope of the U component of wind profile at top of SL
! DVDZ    slope of the V component of wind profile at top of SL
! ANGTOP  wind direction at top of SL
! ANGMAX  maximum wind direction change between surface and H
!
!          - Input -
! UTOP    U component of wind at the top of surface layer
! VTOP    V component of wind at the top of surface layer
! ZTOP    height of the top of the surface layer
! Z0      roughness length for wind
! ILMO    inverse of MONIN-OBUKHOV lenth
! H       height of boundary layer (for stable case only)
! LAT     latitude in radians
! N       number of horizontal points to process
!
!NOTES
!        This routine was supplied from the physics library by Yves Delage, who
!        called it sltop_uv, and put together by J.W. Blezius.
!
!!

      INTEGER J
      
      REAL      FM(N)
      REAL AS,ASX,CI,BS,BETA,FACTN,HMIN,SPEED

! Initilisation of constants in the common SURFCON
!
! Note: some of the constants may be reinitialised at runtime using a namelist

      AS    = 12.
      ASX   = 13.
      CI    = 40.
      BS    = 1.0
      BETA  = 1.0
      FACTN = 1.2
      HMIN  = 40.
      ANGMAX= 0.85

      call m_slStateValueWindStub(fm,ztop,z0,ilmo,h,n)
      DO J=1,N
        speed=sqrt(utop(j)**2+vtop(j)**2)
        angtop(j)=atan2(vtop(j),sign(abs(utop(j))+1.e-05,utop(j)))
        nss(j)=speed/fm(j)
        dudz(j)=nss(j)*phim(ztop(j),ilmo(j),h(j))*cos(angtop(j)) &
                              /(ztop(j)+z0(j)) &
                + speed*sin(angtop(j))*angmax*sin(lat(j))/h(j)
        dvdz(j)=nss(j)*phim(ztop(j),ilmo(j),h(j))*sin(angtop(j)) &
                              /(ztop(j)+z0(j)) &
                - speed*cos(angtop(j))*angmax*sin(lat(j))/h(j)
      END DO

      return
      CONTAINS
!  Derivatives of the stability functions

        REAL FUNCTION PHIM(Z,ILMO,H)

        REAL Z,ILMO,H,HH

        HH=MAX(1-Z/H,FACTN-1.0)
        IF(ILMO.GT.0.) THEN
           PHIM=MIN(1.+ASX*BETA*Z*ILMO,0.5*(HH+SQRT(HH**2+ &
                4.*AS*BETA*Z*ILMO*HH)))
        ELSE
           PHIM=(1.-CI*BETA*Z*ILMO)**(-.1666666)
        END IF
        RETURN
        END FUNCTION

        REAL FUNCTION PHIH(Z,ILMO,H)

        REAL Z,ILMO,H,HH

        HH=MAX(1-Z/H,FACTN-1.0)
        IF(ILMO.GT.0.) THEN
           PHIH=BETA*MIN(1.+ASX*BETA*Z*ILMO,0.5*(HH+SQRT(HH**2+ &
                4.*AS*BETA*Z*ILMO*HH)))
        ELSE
           PHIH=(1.-CI*BETA*Z*ILMO)**(-.333333333)
        END IF
        RETURN
        END FUNCTION
end subroutine m_slFluxGradientWindStub








!!s/r m_slStateValueWindStub - Testing stub for the StateValue routine for wind
subroutine m_slStateValueWindStub(fm,z,z0,ilmo,h,n)
!subroutine m_slStateValueWindStub(f, vLevelDestn(:,vt), z0, ilmo, hBound, &
!                                  numInterpSets)
!
!AUTHOR
!     Y. Delage    OCT 2003
!
!REVISION
! v1_3    Blezius J.W. OCT 2003 - extracted from the physics library
!
!OBJECT
!        To fill the role, in part, of the physics library during testing.  The
!        routine is copied here so as to keep this test independent of changes in
!        the physics library.
!
!        Calculates the integrated surface-layer functions for interpolating
!        wind speed.
!
!ARGUMENTS
      IMPLICIT NONE
      INTEGER N
      REAL FM(N),Z(N),Z0(N),ILMO(N),H(N)
!
!          - Output -
! FM      normalised wind speed at desired output height
!
!          - Input -
! Z       height of desired output
! Z0      roughness length for wind
! ILMO    inverse of MONIN-OBUKHOV lenth
! H       height of boundary layer (for stable case only)
! N       number of horizontal points to process
!
!NOTES
!        This routine was supplied from the physics library by Yves Delage, who
!        called it slfun_uv, and put together by J.W. Blezius.
!
!!
      INTEGER J
      REAL AS,ASX,CI,BS,BETA,FACTN,HMIN,ANGMAX

      REAL RAC3,X,X0,Y,Y0,Z0T(1),HI,LZZ0T(1)
      
      REAL      LZZ0(N)

! Initilisation of constants in the common SURFCON
!
! Note: some of the constants may be reinitialised at runtime using a namelist

      AS    = 12.
      ASX   = 13.
      CI    = 40.
      BS    = 1.0
      BETA  = 1.0
      FACTN = 1.2
      HMIN  = 40.
      ANGMAX= 0.85

      RAC3=SQRT(3.)
      DO J=1,N
      LZZ0(J)=LOG(Z(J)/Z0(J)+1)
      IF(ILMO(J).LE.0.) THEN
!---------------------------------------------------------------------
!                      UNSTABLE CASE
           fm(j)= fmi(z(j)+z0(j),j)
      ELSE
!---------------------------------------------------------------------
!                        STABLE CASE
        hi=1/MAX(H(J),hmin,factn/(4*AS*BETA*ilmo(j)), &
             (Z(J)+10*Z0(J))*factn)
        fm(j)=LZZ0(J)+min(psi(Z(J)+Z0(J),j)-psi(Z0(J),j), &
                           ASX*BETA*ILMO(J)*Z(J))
      ENDIF
!---------------------------------------------------------------------
      END DO

      return
      CONTAINS
!   Internal function FMI
!   Stability function for momentum in the unstable regime (ilmo<0)
!   Reference: Delage Y. and Girard C. BLM 58 (19-31) Eq. 19

      REAL FUNCTION FMI(Z,I)

      REAL Z
      integer i

      X=(1-CI*Z*BETA*ILMO(I))**(0.1666666)
      X0=(1-CI*Z0(I)*BETA*ILMO(I))**(0.1666666)
      FMI=LZZ0(I)+LOG((X0+1)**2*SQRT(X0**2-X0+1)*(X0**2+X0+1)**1.5 &
                     /((X+1)**2*SQRT(X**2-X+1)*(X**2+X+1)**1.5)) &
                    +RAC3*ATAN(RAC3*((X**2-1)*X0-(X0**2-1)*X)/ &
                    ((X0**2-1)*(X**2-1)+3*X*X0))

      RETURN
      END FUNCTION
!   Internal function FHI
!   Stability function for heat and moisture in the unstable regime (ilmo<0)
!   Reference: Delage Y. and Girard C. BLM 58 (19-31) Eq. 17

      REAL FUNCTION FHI(Z,I)

      REAL Z
      integer i

      Y=(1-CI*Z*BETA*ILMO(I))**(0.33333333)
      Y0=(1-CI*Z0T(I)*BETA*ILMO(I))**(0.3333333)
      FHI=BETA*(LZZ0T(I)+1.5*LOG((Y0**2+Y0+1)/(Y**2+Y+1))+RAC3* &
              ATAN(RAC3*2*(Y-Y0)/((2*Y0+1)*(2*Y+1)+3)))

      RETURN
      END FUNCTION
!   Internal function psi
!   Stability function for momentum in the stable regime (unsl>0)
!   Reference :  Y. Delage, BLM, 82 (p23-48) (Eqs.33-37)


      REAL FUNCTION PSI(Z,I)

      REAL Z,a,b,c,d
      integer i

      d = 4*AS*BETA*ilmo(i)
      c = d*hi - hi**2
      b = d - 2*hi
      a = sqrt(1 + b*z - c*z**2)
      psi = 0.5 * (a-z*hi-log(1+b*z*0.5+a)- &
                  b/(2*sqrt(c))*asin((b-2*c*z)/d))

      RETURN
      END FUNCTION
end subroutine m_slStateValueWindStub
