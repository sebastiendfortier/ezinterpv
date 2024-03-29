! This is the example that appears on the web page:
! wiki.cmc.ec.gc.ca/wiki/RPN-SI/RpnLibrairies/RMNLIB/INTERP1D/Ez_interpv_f90/basic_example
#define NUM_LEVELS_SOURCE 57
#define NUM_LEVELS_DEST   57

program Example_Vertical_Interpolation
  use VerticalGrid_90_class
  use VerticalInterpolation_90_class
  implicit none

  integer :: error_li, kk

  real, dimension(2,1,NUM_LEVELS_SOURCE) :: state_in_lr
  real, dimension(2,1,NUM_LEVELS_DEST)   :: state_out_lr
  real, dimension(2,1)  :: psurf_lr

  type(T_VerticalGrid), target  :: o_gridInit  , o_gridTarget
  type(T_VerticalGrid), pointer :: o_gridInit_p, o_gridTarget_p

  type(vgrid_descriptor), target  :: o_vGridDescInit,   o_vGridDescTarget
  type(vgrid_descriptor), pointer :: o_vGridDescInit_p, o_vGridDescTarget_p


  ! VARIABLES THAT DEFINE THE VGRID DESCRIPTORS
  real, dimension(57), parameter :: HYB= &
     (/0.0134575, 0.0203980, 0.0333528, 0.0472815, 0.0605295, 0.0720790, &
       0.0815451, 0.0889716, 0.0946203, 0.0990605, 0.1033873, 0.1081924, &
       0.1135445, 0.1195212, 0.1262188, 0.1337473, 0.1422414, 0.1518590, &
       0.1627942, 0.1752782, 0.1895965, 0.2058610, 0.2229843, 0.2409671, &
       0.2598105, 0.2795097, 0.3000605, 0.3214531, 0.3436766, 0.3667171, &
       0.3905587, 0.4151826, 0.4405679, 0.4666930, 0.4935319, 0.5210579, &
       0.5492443, 0.5780612, 0.6074771, 0.6374610, 0.6679783, 0.6989974, &
       0.7299818, 0.7591944, 0.7866292, 0.8123021, 0.8362498, 0.8585219, &
       0.8791828, 0.8983018, 0.9159565, 0.9322280, 0.9471967, 0.9609448, &
       0.9735557, 0.9851275, 0.9950425/)
  real, parameter :: RCOEF1=0., &
                     RCOEF2=1.
 
  real(8), parameter :: PTOP_SRC=805d0, &
                        PTOP_TRG=900d0, &
                        PREF=100000d0



  o_gridInit_p   => o_gridInit
  o_gridTarget_p => o_gridTarget
  o_gridInit_p%N_ip1_p         => null()
  o_gridInit_p%O_vGridDesc_p   => null()
  o_gridTarget_p%N_ip1_p       => null()
  o_gridTarget_p%O_vGridDesc_p => null()

  o_vGridDescInit_p   => o_vGridDescInit
  o_vGridDescTarget_p => o_vGridDescTarget

  state_out_lr=0.

  ! DEFINE THE INITIAL STATE
  do kk=1,NUM_LEVELS_SOURCE
    state_in_lr(1,1,kk) = 1000.0 + kk*10.0
    state_in_lr(2,1,kk) = 2000.0 + kk*10.0
  end do


  !
  ! CREATE THE INITIAL GRID
  !
  error_li = vgd_new(o_vGridDescInit, kind=5, version=2, hyb=HYB, &
                     rcoef1=RCOEF1, rcoef2=RCOEF2, ptop_8=PTOP_SRC, pref_8=PREF)
  if(error_li .ne. VGD_OK)write(6,*)'ERROR from vgd_new:', error_li

  error_li=N_Viqkdef(o_gridInit_p, o_vGridDescInit_p, 'VIPT')
  if(error_li /= 0)write(6,*)'ERROR initializing gridInit:  ', error_li


  !
  ! CREATE THE TARGET GRID
  !
  error_li = vgd_new(o_vGridDescTarget, kind=5, version=2, hyb=HYB, &
                     rcoef1=RCOEF1, rcoef2=RCOEF2, ptop_8=PTOP_TRG, pref_8=PREF)
  if(error_li .ne. VGD_OK)write(6,*)'ERROR in TestVI, from vgd_new:', error_li

  error_li=N_Viqkdef(o_gridTarget_p, o_vGridDescTarget_p, 'VIPT')
  if(error_li /= 0)write(6,*)'ERROR initializing gridTarget:  ', error_li


  !
  ! SET THE INITIAL AND TARGET GRIDS
  !
  psurf_lr(:,:)=100000.0
  error_li=N_Videfset(o_gridTarget_p, o_gridInit_p, psurf_lr)
  if(error_li /= 0)write(6,*) 'ERROR:  videfset returned ', error_li


  !
  ! SET THE INTERPOLATION OPTIONS
  !
  error_li=N_Visetopt('interptype', 'linear')
  if(error_li /= 0)write(6,*)'ERROR setting interptype:  N_Visetopt returned ',&
                              error_li

  error_li=N_Visetopt('extraptype', 'clamped')
  if(error_li /= 0)write(6,*)'ERROR setting s_extrapType: N_Visetopt returned ',&
                              error_li


  !
  ! DO THE INTERPOLATION
  !
  error_li = N_Visint(state_out_lr, state_in_lr)
  if(error_li /= 0)write(6,*) 'ERROR interpolating:  N_Visint returned ',error_li

  write(*,*)"The interpolated values are: "
  write(*,*)state_out_lr(1,:,:)
  write(*,*)state_out_lr(2,:,:)


  !
  ! RELEASE THE GRIDS
  !
  call M_ReleaseVerticalGrid(o_gridInit_p)
  call M_ReleaseVerticalGrid(o_gridTarget_p)
end program
