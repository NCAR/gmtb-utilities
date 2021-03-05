load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"

begin

; User modification area, read in the LASSO files and determine time
; Note: your directories will likely be different; will need to adjust
; based on your personal directory choices.
  topdir = "/glade/u/home/damico/"
  LAS    = "LASSO"

  ffs = systemfunc("ls "+topdir+"sgp*.tar.gz")

  ntb = dimsizes(ffs)

  delim = "."

;  nfields = str_fields_count(ffs,delim)

  date_strings = str_get_field(ffs,3,delim)
  date_int     = toint(date_strings)
  date_ints    = get_unique_values(date_int)

  nd = dimsizes(date_ints)

  sgp_strings = str_get_field(ffs,1,delim)
  sgp_int     = str_get_cols(sgp_strings,-3,-3)

  do i=0,nd-1,1
    system("/bin/mkdir -v "+topdir+LAS+"_"+date_ints(i))
  end do

  do i=0,ntb-1,1
    do j=0,nd-1,1
      ff0 = topdir+"sgplassodiagconfobsmod"+sgp_int(i)+"C1.m1."+date_ints(j)+ \
            ".000000.tar.gz"
      if (fileexists(ff0)) then
        system("/bin/mkdir -v "+topdir+LAS+"_"+date_ints(j)+"/000"+ \
               sgp_int(i))
        system("/bin/mv -v "+topdir+"sgplassodiagconfobsmod"+sgp_int(i)+ \
               "C1.m1."+date_ints(j)+".000000.tar.gz "+topdir+LAS+"_"+\
               date_ints(j)+"/000"+sgp_int(i)+"/.")
;        system("/bin/tar xzvf "+topdir+LAS+"_"+date_ints(j)+"/000"+ \
;               sgp_int(i)+"/sgp*.gz")
      else
        print(date_ints(j)+" SID000"+sgp_int(i)+" does not exist")
      end if
    end do
  end do

  do i=0,ntb-1,1
    do j=0,nd-1,1
      ff1 = topdir+LAS+"_"+date_ints(j)+"/000"+sgp_int(i)+ \
            "/sgplassodiagconfobsmod"+sgp_int(i)+"C1.m1."+date_ints(j)+ \
            ".000000.tar.gz"
      if (fileexists(ff1)) then
        system("/bin/tar xzvf "+ff1+" --directory="+topdir+LAS+"_"+ \
               date_ints(j)+"/000"+sgp_int(i)+"/")
      else
        print(date_ints(j)+" SID000"+sgp_int(i)+" does not exist")
      end if
    end do
  end do

;  do i=0,nd-1,1
;    system("/bin/mkdir -v "topdir+LAS+"_"+date_ints(i))
;    system("/bin/mv -v sgp*"+date_ints(i)+"*.tar.gz "+topdir+LAS+"_"+ \
;           date_ints(i)+"/.")
;  end do

;  system("/bin/mkdir "+LAS+"_mkdir")

end

