!!!mod VerticalGrid_90_class - Class that represents one vertical grid
!module VerticalGrid_90_class
!module VerticalGrid_90_class8
!
!AUTHOR
!     J.W. Blezius MAY 2002 helper on top of the Interp1D library
!
!REVISION
! v1_0    Blezius J.W.          - initial version
! v1_4    Blezius J.W. AUG 2009 - split this file off of VerticalGrid.cdk90
!    ?    Blezius J.W. FEB 2010 - support UNnormalized hybrid grid
!                               - (due to hyb_to_pres) no longer require hybrid
!                                 ceiling to be the first element
!                               - inform the user only once of converting to ln P
!         Blezius J.W. DEC 2010 - add support for the staggered grid type
!
!OBJECT
!        A vertical grid is defined by the specific set of vertical levels in the
!        grid, along with an indication of the representation that is used for
!        the vertical levels, as well as all the parameters, except for surface
!        pressure, that are necessary to convert from that representation to a
!        representation by pressure.
!
!        Naturally, there is a constructor to define the grid and a destructor to
!        release memory that is associated with the grid.  Together, these are
!        the VerticalGrid_90_class that is defined in this module.
!       
!
!NOTES
!        Throughout, the object of the class on which the functions are to
!        operate is passed to each function as its first argument.
!
!        Ideally, the class member that defines what kind of vertical
!        representation is used would not be necessary.  Instead, each kind of
!        representation would be contained in a different sub-class of the
!        VerticalGrid_90_class.  Because fortran 90 does not explicitly support
!        inheritance, the older methods used here are easier.
!
!        The constructor and destructor do not deallocate the class object itself
!        because it is not necessarily on the heap.
!
!!
  use VerticalInterpolationConstants_90
  use vGrid_Descriptors
  implicit none
  public
  save

  real(real48), parameter :: r_MBAR_PER_PASCAL = real(0.01d0,real48)
  real(real48), parameter :: r_LOG_MBAR_PER_PASCAL = log(r_MBAR_PER_PASCAL)

  type T_VerticalGrid
    integer N_numVLevels                ! number of vertical points in this grid

                                        ! The ip1's of the field levels that are
                                        ! present in the associated field
                                        ! N.B.:  the dimension of this array may
                                        !        be greater than N_numVLevels
    integer, pointer, dimension(:) :: N_ip1_p
                                        ! The vgd that describes this grid
    type(vgrid_descriptor), pointer::O_vGridDesc_p
  end type T_VerticalGrid

  interface assignment(=)
    module procedure M_AssignVerticalGrid
  end interface

  interface operator(/=)
    module procedure M_NotEqualVerticalGrid
  end interface

  interface N_Viqkdef
    module procedure N_Viqkdef_ip1List
    module procedure N_Viqkdef_ip1Type
  end interface



contains

!!!func M_NotEqualVerticalGrid - non-equality comparison operator
  logical function M_NotEqualVerticalGrid(o_gridA, o_gridB)
!
!AUTHOR
!     J.W. Blezius OCT 2002
!
!REVISION
! v1_0    Blezius J.W.          - initial version
!
!OBJECT
!        To compare (that means a deep comparison) the value of one vertical
!        grid object to another.
!
!ARGUMENTS
    type (T_VerticalGrid), intent(in) :: o_gridA, &
                                         o_gridB
!
!NOTES
!
!!

  integer :: k                          ! index of the vertical levels


  M_NotEqualVerticalGrid = .false.      ! assume equal until proven otherwise

  if(o_gridA%N_numVLevels /= o_gridB%N_numVLevels) then
    M_NotEqualVerticalGrid = .true.
  else if(     .not. associated(o_gridA%O_vGridDesc_p) &
          .or. .not. associated(o_gridB%O_vGridDesc_p)) then
    if(     associated(o_gridA%O_vGridDesc_p) &
       .or. associated(o_gridB%O_vGridDesc_p)) then
      ! One is associated and the other is not
      M_NotEqualVerticalGrid = .true.
    ! else if both are not associated, then they are equal
    end if
  else if(.not. (o_gridA%O_vGridDesc_p == o_gridB%O_vGridDesc_p)) then
    M_NotEqualVerticalGrid = .true.
  else
    do k=1, o_gridA%N_numVLevels
      if(o_gridA%N_ip1_p(k) /= o_gridB%N_ip1_p(k)) then
        M_NotEqualVerticalGrid = .true.
        exit                            ! no need to check any further
      end if
    end do
  end if

  end function M_NotEqualVerticalGrid



!!!s/r M_AssignVerticalGrid - assigment operator
  subroutine M_AssignVerticalGrid(o_gridOut, o_gridIn)
    use app
!
!AUTHOR
!     J.W. Blezius SEPT 2002
!
!REVISION
! v1_0    Blezius J.W.          - initial version
!
!OBJECT
!        To assign (that means a deep copy) the value of one vertical grid
!        object to another.
!
!ARGUMENTS
    type (T_VerticalGrid), intent(out) :: o_gridOut
    type (T_VerticalGrid), intent(in)  :: o_gridIn
!
!NOTES
!
!!
    integer :: n_error

    o_gridOut%N_numVLevels = o_gridIn%N_numVLevels
                                                      ! deep copy
    if(associated(o_gridIn%N_ip1_p))then
      if(associated(o_gridOut%N_ip1_p)) then
        if(size(o_gridOut%N_ip1_p) < o_gridIn%N_numVLevels) then
          deallocate(o_gridOut%N_ip1_p)
          nullify(o_gridOut%N_ip1_p)
        end if
      end if

      if(.not. associated(o_gridOut%N_ip1_p)) then
          allocate(o_gridOut%N_ip1_p(o_gridIn%N_numVLevels), STAT=n_error)
          if(n_error /= 0) then
            write(app_msg, *)'M_AssignVerticalGrid: Error allocating ip1 in M_AssignVerticalGrid (error=',n_error,')'
            call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
            return
          endif
      end if

      ! Specifying the slices protects against the dimension of <grid>%N_ip1_p
      ! exceeding <grid>%N_numVLevels
      o_gridOut%N_ip1_p(:o_gridOut%N_numVLevels) = o_gridIn%N_ip1_p(:o_gridIn%N_numVLevels)

    else ! .not. associated(o_gridIn%N_ip1_p)
      if(associated(o_gridOut%N_ip1_p)) then
        deallocate(o_gridOut%N_ip1_p)
        nullify(o_gridOut%N_ip1_p)
      end if
    end if

    o_gridOut%O_vGridDesc_p => o_gridIn%O_vGridDesc_p
  end subroutine M_AssignVerticalGrid



!!!func N_ConstructNull - constructor:  Put the object in a valid state
  integer function N_ConstructNull(this, n_numVLevelsIn)
     use app
                                        ! returns error indication:  0='no error'
!
!AUTHOR
!     J.W. Blezius DEC 2003
!
!REVISION
! v1_3    Blezius J.W. DEC 2003 - initial version
!
!OBJECT
!        The null VerticalGrid constructor.  This constructor simply puts the
!        object in a valid state, but containing no data.
!
!ARGUMENTS
    type(T_VerticalGrid), pointer, intent(inout) :: this
    integer, intent(in)::n_numVLevelsIn ! number of vertical levels in the object
!
!NOTES
!
!!
    integer :: n_error

    N_ConstructNull = 0                 ! no error yet
    nullify(this%O_vGridDesc_p)

    if(n_numVLevelsIn == 0) then
        ! The size is not known yet; just nullify the pointer
        nullify(this%N_ip1_p)
    else
        allocate(this%N_ip1_p(n_numVLevelsIn), STAT=n_error)
        if(n_error /= 0) then
          write(app_msg, *)'N_ConstructNull: allocating vLevel in N_ConstructNull (error=',n_error,')'
          call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
          N_ConstructNull = N_VI_VIERR_FAILED_ALLOCATION
          return
        endif ! n_error /= 0
        this%N_ip1_p = 0

    end if ! n_numVLevelsIn == 0
    
    ! Array of vertical levels was successfully allocated.
    this%N_numVLevels = n_numVLevelsIn

  end function N_ConstructNull



!!!func N_Viqkdef - OVERLOADED constructor:  Quick definition of the grid for
!                                            vertical integration
  integer function N_Viqkdef_ip1List(this, o_vGridDesc_p, n_ip1)
     use app
                                        ! returns error indication:  0='no error'
!
!AUTHOR
!     J.W. Blezius MAY 2002 helper on top of the Interp1D library
!
!REVISION
! v1_0    Blezius J.W.          - initial version
!
!OBJECT
!        The VerticalGrid constructor.  The attributes of the
!        VerticalGrid_90_class are initialized.  The ip1 values are obtained from
!        the supplied list.
!
!NOTES
!        N_VIQKDEF IS OVERLOADED:  The ip1 list can be given either explicitly
!                                  or by naming the type of grid (momentum or
!                                  thermodynamic).  The two methods can be
!                                  distinguished by this ip1 parameter, and that
!                                  is the whole point of overloading the method.
!
!ARGUMENTS
    type(T_VerticalGrid), pointer, intent(inout) :: this
                                        ! The vgd that describes this grid
    type(vgrid_descriptor), pointer, intent(in)::o_vGridDesc_p
                                        ! The ip1's of field levels present
    integer, dimension(:), intent(in) :: n_ip1
!
!!
    integer :: n_error, n_kind, n_version, n_numVLevels

    N_Viqkdef_ip1List = 0               ! no error yet
    this%O_vGridDesc_p => o_vGridDesc_p


    !
    ! DETERMINE THE IP1 VALUES
    !

    if (associated(this%N_ip1_p)) then
      deallocate(this%N_ip1_p)
    end if

    nullify(this%N_ip1_p)

    this%N_numVLevels = ubound(n_ip1,1)-lbound(n_ip1,1)+1

    allocate(this%N_ip1_p(this%N_numVLevels), STAT=n_error)
    if(n_error /= 0) then
      write(app_msg, *)'N_Viqkdef_ip1List: Error allocating this%N_ip1_p in N_Viqkdef (error=',n_error,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      N_Viqkdef_ip1List = N_VI_VIERR_FAILED_ALLOCATION
      return
    endif

    ! ... IP1 VALUES GIVEN EXPLICITLY
    this%N_ip1_p = n_ip1

  end function N_Viqkdef_ip1List



!!!func N_Viqkdef - OVERLOADED constructor:  Quick definition of the grid for
!                                            vertical integration
  integer function N_Viqkdef_ip1Type(this, o_vGridDesc_p, s_ip1Type)
     use app
                                        ! returns error indication:  0='no error'
!
!AUTHOR
!     J.W. Blezius AUG 2015 overload the method.
!
!OBJECT
!        The VerticalGrid constructor.  The attributes of the
!        VerticalGrid_90_class are initialized.  The ip1 values are obtained from
!        the vertical-grid descriptor, given the type of grid (VIPT or VIPM).
!
!NOTES
!        For more information, see the header of the preceding method by the same
!        name.
!
!ARGUMENTS
    type(T_VerticalGrid), pointer, intent(inout) :: this
                                        ! The vgd that describes this grid
    type(vgrid_descriptor), pointer, intent(in)::o_vGridDesc_p
    character(len=4), intent(in) :: s_ip1Type ! VIPM or VIPT
!
!!
    integer :: n_error, n_kind, n_version, n_numVLevels
    integer, pointer, dimension(:) :: n_ip1_p

    N_Viqkdef_ip1Type = 0               ! no error yet
    this%O_vGridDesc_p => o_vGridDesc_p

    !
    ! DETERMINE THE IP1 VALUES
    !

    if (associated(this%N_ip1_p)) then
      deallocate(this%N_ip1_p)
    end if

    nullify(this%N_ip1_p)
    nullify(n_ip1_p)

    ! ... IP1 VALUES FROM VGRID, GIVEN 'VIPT' / 'VIPM'
    ! Obtain a list of all (and then some) levels from vgrid
    ! (N.B.:  Although it is not documented, vgrid passes ownership of memory
    ! (       pointed by n_ip1_p to the caller)
    n_error=vgd_get(this%O_vGridDesc_p, s_ip1Type, n_ip1_p)
    if(n_error /= VGD_OK)then
      write(app_msg, *)'N_Viqkdef_ip1Type: Error from vgd_get (error=',n_error,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      N_Viqkdef_ip1Type = N_VI_VIERR_VGD_DESCRIPTOR_ERROR
    end if

    ! In order to adjust the number of levels, need the grid kind & version
    n_error=vgd_get(this%O_vGridDesc_p, 'KIND', n_kind)
    if(n_error /= VGD_OK)then
      write(app_msg, *)'N_Viqkdef_ip1Type: Error getting n_kind (error=',n_error,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      N_Viqkdef_ip1Type = N_VI_VIERR_VGD_DESCRIPTOR_ERROR
    end if

    n_error=vgd_get(this%O_vGridDesc_p, 'VERS', n_version)
    if(n_error /= VGD_OK)then
      write(app_msg, *)'N_Viqkdef_ip1Type: Error getting n_version (error=',n_error,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      N_Viqkdef_ip1Type = N_VI_VIERR_VGD_DESCRIPTOR_ERROR
    end if

    ! Omit the levels that would not be present in a field.
    ! Vgd might have (depending on the grid type) added hyb=1 (the last entry)
    ! and the 10m level (after hyb=1) to the list. Remove the 10m level them.
    n_numVLevels = ubound(n_ip1_p,1)
    select case (n_kind*1000 + n_version)
    case (5002, 5003)
      if(s_ip1Type == 'VIPM') then
        n_numVLevels = n_numVLevels - 1
      else ! 'VIPT'
        n_numVLevels = n_numVLevels - 2
      end if

    case (5004, 5005)
      n_numVLevels = n_numVLevels - 1

    case default
      ! Do not adjust the number of levels
    end select

    allocate(this%N_ip1_p(n_numVLevels), STAT=n_error)
    if(n_error /= 0) then
      write(app_msg, *)'N_Viqkdef_ip1Type: Error allocating this%N_ip1_p (error=',n_error,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      N_Viqkdef_ip1Type = N_VI_VIERR_FAILED_ALLOCATION
      return
    endif

    this%N_ip1_p = n_ip1_p(:n_numVLevels)

    this%N_numVLevels = n_numVLevels

    ! Release memory allocated by vgrid descriptor
    deallocate(n_ip1_p)
    nullify(n_ip1_p)

  end function N_Viqkdef_ip1Type



!!!func N_VertGridGetLnP - Create 'cube' of vertical levels in units of ln P
  integer function N_VertGridGetLnP(this, r_P, r_pSurf, r_pSurfLS, l_in_log)
     use app
                                        ! returns error indication:  0='no error'
!
!AUTHOR
!     J.W. Blezius JULY 2002 helper on top of the Interp1D library
!
!REVISION
! v1_0    Blezius J.W.          - initial version
!
!OBJECT
!        The vertical grid is a 1-D object.  The product is taken with the
!        horizontal surface pressure, r_pSurf and r_pSurfLS (smoothed) to produce
!        a cube of vertical levels, in pressure units.
!
!        The exception is the 'generic' grid type.  In this case, the vertical
!        levels are simply multiplied horizontally, and no attempt is made to
!        obtain a pressure.
!
!NOTES
!        Contrary to the name of the function, it will return pressures that are
!        not in log, depending on the fourth, optional parameter.  The advertized
!        interface to this functionality is the functon, N_VertGridGetP.
!
!ARGUMENTS

                                        ! parameter cannot be a pointer to a
                                        ! user type:  replace 'this' with 'that'
    type(T_VerticalGrid), pointer, intent(in) :: this

                                        ! vertical levels as pressure
    real(real48), dimension(:,:,:), intent(out) :: r_P

                                        ! surface pressure for each horiz point,
                                        ! in units of mb
    real(real48), dimension(:,:), intent(in) :: r_pSurf
    real(real48), dimension(:,:), optional , intent(in) :: r_pSurfLS
    logical, intent(in), optional :: l_in_log
!
!!
    integer :: n_error

    real(real48), dimension(:,:,:), pointer :: r_P_p
    logical :: l_log
    logical :: l_firstTime=.true.


    nullify(r_P_p)
    N_VertGridGetLnP = 0                  ! no error yet

    if(present(l_in_log)) then
      l_log = l_in_log
    else
      l_log = .true.
    end if
    

    if(l_firstTime .eqv. .true.) then
         l_firstTime=.false.
         call lib_log(APP_LIBINTERPV,APP_INFO,'N_VertGridGetLnP: converting the vertical levels to ln P &
            &(1 mb ref level) before interpolating (This message will not be repeated)')
    endif

    !
    ! Create the 'cube' of source vertical levels
    !
                                        ! Obtain, the cube of P.
                                        ! vgd_levels allocates r_P_p
    if (present(r_pSurfLS)) then
       n_error = vgd_levels(this%O_vGridDesc_p, this%N_ip1_p(:this%N_numVLevels),&
                           r_P_p, r_pSurf / r_MBAR_PER_PASCAL, l_log, r_pSurfLS / r_MBAR_PER_PASCAL)
    else
       n_error = vgd_levels(this%O_vGridDesc_p, this%N_ip1_p(:this%N_numVLevels),&
                           r_P_p, r_pSurf / r_MBAR_PER_PASCAL, l_log)
    endif

    if(n_error .ne. VGD_OK)then
      write(app_msg, *)'N_VertGridGetLnP: Error in VerticalGrid_90_class%N_VertGridGetLnP from vgd_levels, (error=',n_error,')'
      call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      N_VertGridGetLnP = N_VI_VIERR_VGD_DESCRIPTOR_ERROR
    end if

    if(l_log) then
      r_P = r_P_p + r_LOG_MBAR_PER_PASCAL
    else
      r_P = r_P_p * r_MBAR_PER_PASCAL
    end if

    deallocate(r_P_p)
    nullify   (r_P_p)

  end function N_VertGridGetLnP



!!!func N_VertGridGetP - Create 'cube' of vertical levels in pressure
  integer function N_VertGridGetP(this, r_P, r_pSurf, r_pSurfLS)
                                        ! returns error indication:  0='no error'
!
!AUTHOR
!     J.W. Blezius OCT 2015 revive this deleted function
!
!OBJECT
!         This is a wrapper to the function, N_VertGridGetLnP, that sets the
!         parameter, l_in_log, to .false.
!
!NOTES
!
!ARGUMENTS

                                        ! parameter cannot be a pointer to a
                                        ! user type:  replace 'this' with 'that'
    type(T_VerticalGrid), pointer, intent(in) :: this

                                        ! vertical levels as pressure
    real(real48), dimension(:,:,:), intent(out) :: r_P

                                        ! surface pressure for each horiz point,
                                        ! in units of mb
    real(real48), dimension(:,:), intent(in) :: r_pSurf
    real(real48), dimension(:,:), intent(in), optional :: r_pSurfLS
!
!!

    N_VertGridGetP = N_VertGridGetLnP(this, r_P, r_pSurf, r_pSurfLS, l_in_log=.false.)
  end function N_VertGridGetP



!!!s/r M_ReleaseVerticalGrid - VerticalGrid destructor
  subroutine M_ReleaseVerticalGrid(this)
     use app
!
!AUTHOR
!     J.W. Blezius MAY 2002 helper on top of the Interp1D library
!
!REVISION
! v1_0    Blezius J.W.          - initial version
!
!OBJECT
!        The memory associated with the attributes is released.
!
!ARGUMENTS
    implicit none
    type(T_VerticalGrid), pointer, intent(inout) :: this
!
!!
    integer :: n_error


    if( associated(this%N_ip1_p) ) then
      deallocate (this%N_ip1_p, STAT=n_error)
      if(n_error /= 0) then
        write(app_msg, *)'M_ReleaseVerticalGrid: Error deallocating vLevel (error=',n_error,')'
        call lib_log(APP_LIBINTERPV,APP_ERROR,app_msg)
      end if
      nullify(this%N_ip1_p)
    end if

! vgd_free causes deallocation error in some circumstances
!!$    ! N.B.:  vgd_free does not deallocate data that were obtained with vgd_get
!!$    if( associated(this%O_vGridDesc_p) ) then
!!$      n_error = vgd_free(this%O_vGridDesc_p)
!!$      if(n_error /= VGD_OK) then
!!$        write(6, *)'Error freeing vgrid descriptor object in ', &
!!$                   'M_ReleaseVerticalGrid:  error from vgrid=', n_error
!!$        call flush(6)
!!$      end if
!!$      nullify(this%O_vGridDesc_p)
!!$    end if

  end subroutine M_ReleaseVerticalGrid

!end module VerticalGrid_90_class
!end module VerticalGrid_90_class8
