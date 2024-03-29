!!!mod VerticalInterpolation_90_class Interfaces
!
!AUTHOR
!     J.W. Blezius AUG 2009 
!
!REVISION
! v1_4    Blezius J.W. AUG 2009 - split VerticalInterpolation_Body.ftn90 off from
!                                 this file
!
!OBJECT
!        To provide a means to easily compile the contained module twice, once
!        with single-precision arguments, and once with double-precision
!        arguments.
!
!NOTES
!
!!

!version that accepts real(single) arguments
module VerticalInterpolation_90_class
#define real48 single
#include "VerticalInterpolation_Body_90.inc"
#undef real48
end module VerticalInterpolation_90_class

!version that accepts real(double) arguments
module VerticalInterpolation_90_class8
#define real48 double
! Rename all of the modules that are used:
#define VerticalGrid_90_class                   VerticalGrid_90_class8
#define VerticalInterpolation_90_class VerticalInterpolation_90_class8
#define VerticalGridRepository                 VerticalGridRepository8
#define Interp1D_FindPos                             Interp1D_FindPos8
#define Interp1D_NearestNeighbour_X       Interp1D_NearestNeighbour_X8
#define Interp1D_Linear_X                           Interp1D_Linear_X8
#define Interp1D_CubicWithDerivs_X         Interp1D_CubicWithDerivs_X8
#define Interp1D_CubicLagrange_X             Interp1D_CubicLagrange_X8
#define Extrap1D_LapseRate_X                     Extrap1D_LapseRate_X8
#define Extrap1D_Fixed_X                             Extrap1D_Fixed_X8
#define Extrap1D_Surface_X                         Extrap1D_Surface_X8
#define Extrap1D_SurfaceWind_X                 Extrap1D_SurfaceWind_X8
#include "VerticalInterpolation_Body_90.inc"
#undef Interp1D_CubicLagrange_X
#undef Interp1D_CubicWithDerivs_X
#undef Interp1D_Linear_X
#undef Interp1D_NearestNeighbour_X
#undef Interp1D_FindPos
#undef VerticalGridRepository
#undef VerticalInterpolation_90_class
#undef VerticalGrid_90_class
#undef real48
end module VerticalInterpolation_90_class8
