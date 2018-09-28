! convert relatively humidity to specific humidity
! http://cires.colorado.edu/~voemel/vp.html	Buck 1996 (Eqs. 5 and 16)
! Also see CIRES-es-Formulations.pdf
! P: pressure in hPa
! sh: specific humidity in kg/kg
! rh: relative humidity in percentage
! temp: temperature in deg C
! contact: weiweili@ucar.edu
	subroutine rhum2shum(sh,p,t,r,nx,ny)
	real sh(nx,ny),p,t(nx,ny),r(nx,ny)

	do j=1,ny
	do i=1,nx
	  temp=t(i,j)		!temp.
          if(temp>=0)then
            Es=6.1121*exp((18.678-temp/234.5)*temp/(temp+257.14))
          else
            Es=6.1115*exp((23.036-temp/333.7)*temp/(temp+279.82))
	  endif
	  e=r(i,j)/100*Es	!vapor pressure
	  sh(i,j)=0.62198*e/p
	enddo
	enddo
	
	end
