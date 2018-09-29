! Description: Fortran subroutine to decode and read GRIB-1 or GRIB-2 files
! by creating and using an index to access messages from a file.
! then assign the field data to a two-dimensional latitude-longitude array.
! Require: GRIB-API (https://confluence.ecmwf.int/display/GRIB/What+is+GRIB-API)
! GRIB-API hides the binary layer of the message and uses a key/value approach
! to access the information in a GRIB message.
! Contact: weiweili@ucar.edu

subroutine grib_api_decode(input_file,varname,nx,ny,nz,levs,fcst0,var)

use grib_api
implicit none

integer iret
integer olevel,levelSize,nx,ny,nz
integer y0,y1,fcst0
integer, dimension(nz):: levs
integer idx, k, iz, igrib, count
integer,dimension(:),allocatable :: level
character*200 input_file 
character*20,dimension(:),allocatable :: shortName
character*20 oshortName, varname*10
real,dimension(nx*ny) :: tmp_var 
real,dimension(nx,ny,nz) :: var

! create an index from a grib file using some keys: 
! for example, here use shortName of a variable and vertical levels
call grib_index_create(idx,input_file,'shortName,level,forecastTime')
 
! uncomment following lines to decode list of the shortnames of all variables
!! get the number of distinct values of shortName in the index
! call grib_index_get_size(idx,'shortName',shortNameSize)
!! print*,shortNameSize
! allocate the array to contain the list of distinct shortName
!! allocate(shortName(shortNameSize))
!! get the list of distinct shortName from the index
! call grib_index_get(idx,'shortName',shortName)
!! print*,shortName
! write(*,'(a,i3)') 'shortNameSize=',shortNameSize 

! get the number of distinct values of level in the index
call grib_index_get_size(idx,'level',levelSize)
! allocate the array to contain the list of distinct levels
allocate(level(levelSize))
! get the list of distinct levels from the index
call grib_index_get(idx,'level',level)
!print*,level
write(*,'(a,i3)') 'levelSize=',levelSize


do  iz = 1, nz 
    ! 1. select levels
    do k=1,levelSize ! loop on level
        if (level(k) .eq. levs(iz)) then
            call grib_index_select(idx,'level',level(k))
            !print*,'orig_level=',level(k)
            ! 2. select variable: shortName=varname
            call grib_index_select(idx,'shortName',trim(varname))
            call grib_index_select(idx,'forecastTime',fcst0)
            exit
        endif
    end do
    !print*,'select_level:',levs(iz)

    call grib_new_from_index(idx,igrib,iret)
    do while (iret /= GRIB_END_OF_INDEX)
        count=count+1
        call grib_get(igrib,'shortName',oshortName)
        call grib_get(igrib,'level',olevel)
        call grib_get(igrib,"values",tmp_var)
        call grib_get(igrib,"latitudeOfFirstGridPointInDegrees",y0)
        call grib_get(igrib,"latitudeOfLastGridPointInDegrees",y1)
        write(*,'(A,A,A,i10)') 'shortName=',trim(oshortName),' level=' ,olevel
        call grib_release(igrib)
        call grib_new_from_index(idx,igrib,iret)
    end do
    call grib_release(igrib)

    var(:,:,iz) = RESHAPE(tmp_var, (/nx, ny/))

    ! if latitudes from North to South
    if(y0 > y1) var(:,:,iz) = var(:,ny:1:-1,iz)

    ! check values
    !print*,maxval(tmp_var),minval(tmp_var) 
    !print*,maxval(var(:,:,iz)),minval(var(:,:,iz))
end do ! iz
write(*,'(i4,a)') count-1,' messages selected'


 
END
