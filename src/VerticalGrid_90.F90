!!!mod VerticalGrid_90_class Interfaces
!
!AUTHOR
!     J.W. Blezius AUG 2009 
!
!REVISION
! v1_4    Blezius J.W. AUG 2009 - VerticalGrid_Body.inc split off of this file
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
module VerticalGrid_90_class
#define real48 single
#include "VerticalGrid_Body_90.inc"
#undef real48
end module VerticalGrid_90_class

!version that accepts real(double) arguments
module VerticalGrid_90_class8
#define real48 double
! Rename all of the modules that are used:
#define VerticalGrid_90_class                   VerticalGrid_90_class8
#define VerticalInterpolation_90_class VerticalInterpolation_90_class8
#define VerticalGridRepository                 VerticalGridRepository8
#include "VerticalGrid_Body_90.inc"
#undef VerticalGridRepository
#undef VerticalInterpolation_90_class
#undef VerticalGrid_90_class
#undef real48
end module VerticalGrid_90_class8
