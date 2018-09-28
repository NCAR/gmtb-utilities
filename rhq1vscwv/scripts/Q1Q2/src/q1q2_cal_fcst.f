! subroutine to calculate Q1 and Q2 using analysis and forecast data
! calculation of time derivatives: data initialized at the same date/time
! weiweili@ucar.edu
subroutine q1q2_fcst(nx,ny,nz,nt,lon,lat,dx,dy,delt,p,tmp,tmp2,tmp3,q,q_2,q_3,u,v,w,q1,q2,iflag)

!parameters-
!p0: surface pressure, unit[hPa]
!R: gas constant for dry air unit[ J/(kg·K)]
!c_p:specific heat of air at constant pressure
!L: latent heat of vaporization
!Re: radius of the Earth

real,parameter:: p0=1000.1,c_p=1004.0,R=287.058
integer,parameter:: L=2501e3,Re=6.371e6
real::d2r,Pi
real::lon(nx),lat(ny)
integer::delt
integer,dimension(nz)::p
real, dimension(nx,ny,nz,nt)::q1,q2
real, dimension(:,:,:,:),allocatable::dqdp,dqdt,dqdx,dqdy,dsdp,dsdt,dsdx,dsdy,s,s2,s3
real, dimension(nx,ny,nz,nt)::u,v,q,q_2,q_3,tmp,tmp2,tmp3,w
integer:: iflag

!Step I: Calculate potential tmperature (s)
!Input: p,T(NX,NY,NP,NT)
!Output: s(NX,NY,NP,NT)
!Algorithm: Poisson's equation-
!Units: s[K],p[hPa],T[K]
allocate(s(nx,ny,nz,nt),s2(nx,ny,nz,nt),s3(nx,ny,nz,nt))

do k=1,nz
    s(:,:,k,:)=tmp(:,:,k,:)*(p0/p(k))**(R/c_p)
enddo
do k=1,nz
    s2(:,:,k,:)=tmp2(:,:,k,:)*(p0/p(k))**(R/c_p)
enddo
do k=1,nz
    s3(:,:,k,:)=tmp3(:,:,k,:)*(p0/p(k))**(R/c_p)
enddo

!Step II: Calculate spatial, pressure, and time derivatives of 
!s(potential tmperature) and q(mixing ratio)
! dqdp: pressure derivative of q
! dqdt: time derivative of q
! dqdx: derivative of q wrt x
! dqdy: derivative of q wrt y
! dsdp: pressure derivative of s
! dsdt: time derivative of s
! dsdx: derivative of s wrt x
! dsdy: derivative of s wrt y
!

Pi=4.*ATAN(1.)
d2r=Pi/180.0 !change angle into radian

! get Q1
allocate(dsdp(nx,ny,nz,nt),dsdt(nx,ny,nz,nt),dsdx(nx,ny,nz,nt),dsdy(nx,ny,nz,nt))

!-dsdp-
do k=2,nz-1
    dsdp(:,:,k,:) = (s(:,:,k+1,:)-s(:,:,k-1,:))/(p(k+1)-p(k-1))
enddo
dsdp(:,:,1,:)=dsdp(:,:,2,:)+(dsdp(:,:,2,:)-dsdp(:,:,3,:))/(p(2)-p(3))*(p(1)-p(2))
dsdp(:,:,nz,:)=dsdp(:,:,nz-1,:)+(dsdp(:,:,nz-1,:)-dsdp(:,:,nz-2,:))/(p(nz-1)-p(nz-2))*(p(nz)-p(nz-1))
!-dsdt-
if(iflag==0)then
    do it=2,nt-1
        dsdt(:,:,:,it) = (s(:,:,:,it+1)-s(:,:,:,it-1))/(2*delt)
    enddo
    dsdt(:,:,:,1)=2*dsdt(:,:,:,2)-dsdt(:,:,:,3)
    dsdt(:,:,:,nt)=2*dsdt(:,:,:,nt-1)-dsdt(:,:,:,nt-2)
else if(iflag==1)then
    do it=1,nt
        dsdt(:,:,:,it) = (s2(:,:,:,it)-s3(:,:,:,it))/(2*delt)
    enddo
endif
!dsdt(:,:,:,1)=2*dsdt(:,:,:,2)-dsdt(:,:,:,3)
!dsdt(:,:,:,nt)=2*dsdt(:,:,:,nt-1)-dsdt(:,:,:,nt-2)

!-dsdx-
do j=1,ny
do i=2,nx-1
    dsdx(i,j,:,:) = (s(i+1,j,:,:)-s(i-1,j,:,:))/(Re*cos(lat(j)*d2r)*2*dx*d2r)
enddo
enddo
dsdx(1,:,:,:)=2*dsdx(2,:,:,:)-dsdx(3,:,:,:)
dsdx(nx,:,:,:)=2*dsdx(nx-1,:,:,:)-dsdx(nx-2,:,:,:)

!-dsdy-
do j=2,ny-1
    dsdy(:,j,:,:) = (s(:,j+1,:,:)-s(:,j-1,:,:))/(Re*2*dy*d2r)
enddo
dsdy(:,1,:,:)=2*dsdy(:,2,:,:)-dsdy(:,3,:,:)
dsdy(:,ny,:,:)=2*dsdy(:,ny-1,:,:)-dsdy(:,ny-2,:,:)

!Q1
do k=1,nz
    q1(:,:,k,:)=c_p*(p(k)/p0)**(R/c_p)*(dsdt(:,:,k,:)+u(:,:,k,:)*dsdx(:,:,k,:)+v(:,:,k,:)*dsdy(:,:,k,:)+w(:,:,k,:)*dsdp(:,:,k,:))
enddo

!-unit:K/day-
q1=q1/c_p*86400


deallocate(dsdp,dsdt,dsdx,dsdy,s,s2,s3)


! get Q2
allocate(dqdp(nx,ny,nz,nt),dqdt(nx,ny,nz,nt),dqdx(nx,ny,nz,nt),dqdy(nx,ny,nz,nt))

!-dqdp-
do k=2,nz-1
    dqdp(:,:,k,:) = (q(:,:,k+1,:)-q(:,:,k-1,:))/(p(k+1)-p(k-1))
enddo
dqdp(:,:,1,:)=dqdp(:,:,2,:)+(dqdp(:,:,2,:)-dqdp(:,:,3,:))/(p(2)-p(3))*(p(1)-p(2))
dqdp(:,:,nz,:)=dqdp(:,:,nz-1,:)+(dqdp(:,:,nz-1,:)-dqdp(:,:,nz-2,:))/(p(nz-1)-p(nz-2))*(p(nz)-p(nz-1))
!-dqdt-
if(iflag==0)then
    do it=2,nt-1
        dqdt(:,:,:,it) = (q(:,:,:,it+1)-q(:,:,:,it-1))/(2*delt)
    enddo
    dqdt(:,:,:,1)=2*dqdt(:,:,:,2)-dqdt(:,:,:,3)
    dqdt(:,:,:,nt)=2*dqdt(:,:,:,nt-1)-dqdt(:,:,:,nt-2)
else if(iflag==1)then
    do it=1,nt
        dqdt(:,:,:,it) = (q_2(:,:,:,it)-q_3(:,:,:,it))/(2*delt)
    enddo
endif
!-dqdx-
do j=1,ny
do i=2,nx-1
    dqdx(i,j,:,:) = (q(i+1,j,:,:)-q(i-1,j,:,:))/(Re*cos(lat(j)*d2r)*2*dx*d2r)
enddo
enddo
dqdx(1,:,:,:)=2*dqdx(2,:,:,:)-dqdx(3,:,:,:)
dqdx(nx,:,:,:)=2*dqdx(nx-1,:,:,:)-dqdx(nx-2,:,:,:)

!-dqdy-
do j=2,ny-1
    dqdy(:,j,:,:) = (q(:,j+1,:,:)-q(:,j-1,:,:))/(Re*2*dy*d2r)
enddo
dqdy(:,1,:,:)=2*dqdy(:,2,:,:)-dqdy(:,3,:,:)
dqdy(:,ny,:,:)=2*dqdy(:,ny-1,:,:)-dqdy(:,ny-2,:,:)

!Q2
q2(:,:,:,:)=-L*(dqdt(:,:,:,:)+u(:,:,:,:)*dqdx(:,:,:,:)+v(:,:,:,:)*dqdy(:,:,:,:)+w(:,:,:,:)*dqdp(:,:,:,:))

!-unit:K/day-
q2=q2/c_p*86400

deallocate(dqdp,dqdt,dqdx,dqdy)


END
