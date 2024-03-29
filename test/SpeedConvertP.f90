program SpeedConvertP
  use VerticalGrid_90_class
  implicit none

  integer, parameter :: NNI=500         ! scales the arrays involved
  real,    dimension(50) :: vLevelSource
  real,    dimension(NNI,50) :: lnPSource
  real,    dimension(NNI) :: pSurf
  type(T_VerticalGrid), target :: gridSource     ! the grid that will be defined
  type(T_VerticalGrid),pointer :: gridSource_p ! and a pointer to it
  integer, dimension(NNI,50) :: posnDestInSrc

  real, parameter :: pTopSrc=10.
  real, parameter :: pRefSrc=800.
  real, parameter :: rCoefSrc=1.

  integer :: error, ConvertToLnP
  integer :: h                          ! horizontal loop index
  integer :: v                          ! vertical loop index


  ! Fill in some source and destination levels, and source states and derivatives
  do v=1,50
    vLevelSource(v)=v
  end do ! v
  do h=1,NNI
    pSurf(h)=100000.
  end do ! h

  ! Define a vertical grid
  gridSource_p => gridSource
  gridSource_p%N_ip1_p         => null()
  gridSource_p%O_vGridDesc_p   => null()
  call ViqkDef(gridSource_p, 50, N_GRID_TYPE_PRESSURE, vLevelSource, &
               pTopSrc, pRefSrc, rCoefSrc)

  ! Process 200,000 horizontal points, converting the vertical levels to ln P
  do h=1,200000/NNI
    error = ConvertToLnP(gridSource_p, lnPSource, NNI, pSurf)
  end do

end program SpeedConvertP
