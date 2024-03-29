!!!mod VerticalInterpolationConstants_90 - Constants for vertical interpolation
!                                          package
module VerticalInterpolationConstants_90
!
!AUTHOR
!     J.W. Blezius MAY 2002 first library to replace duplicate interpolation
!                           routines
!
!REVISION
! v1_0    Blezius J.W.          - initial version
!
!OBJECT
!        This file gathers together into one place the constants that control
!        the vertical interpolation package.
!
!!

  public

  !!!!!
  !
  ! Globally define the kinds of real variables
  !
  !!!!!
  integer, parameter :: single=4
  integer, parameter :: double=8




  !!!!!
  !
  ! The set of possible errors that can be reported by the vertical interpolation
  ! package
  !
  !!!!!

  ! errors from the VerticalInterpolation_90 class
  integer, parameter :: N_VI_VIERR_FAILED_ALLOCATION    =100, &
                        N_VI_VIERR_UNDEFINED_GRID_REQD  =101, &
                        N_VI_VIERR_GRIDS_NOT_SELECTED   =102, &
                        N_VI_VIERR_BAD_INTERPTYP_4_DATA =103, &
                        N_VI_VIERR_UNRECOGNIZED_OPTION  =104, &
                        N_VI_VIERR_UNRECOGNIZED_VALUE   =105, &
                        N_VI_VIERR_LN_PRESS_CONVERSION  =106, &
                        N_VI_VIERR_MISSING_SURFACE_DATA =108, &

  ! errors from VerticalGrid_90 class
                        N_VI_VIERR_VGD_DESCRIPTOR_ERROR =203, &
                        N_VI_VIERR_IP1S_NOT_SPECIFIED   =204

end module VerticalInterpolationConstants_90
