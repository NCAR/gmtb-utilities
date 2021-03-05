load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRFUserARW.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/wrf/WRF_contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/skewt_func.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/contrib/cd_string.ncl"

begin

  err = NhlGetErrorObjectId()
  setvalues err
    "errLevel":"Fatal"
  end setvalues

  fname = "wangara2.data.txt"
  floc  = "/glade/u/home/damico/"

  datastring = asciiread(floc+fname,-1,"string")

  nrows = dimsizes(datastring)

  delim = " "

  nfields = new((/ nrows-1 /),integer)
  do i=1,nrows-1,1
    nfields(i-1) = str_fields_count(datastring(i),delim)
  end do

  fields            = new((/ nrows,max(nfields) /),float)
  fields@_FillValue = -999.9
  do i=0,max(nfields)-1,1
    fields(:,i) = stringtofloat(str_get_field(datastring,i+1,delim))
  end do
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Line 1, day, time, surface pressure, and time of sounding ;;;;;;;;;;;;;;;;;;;
  day0 = new((/ (nrows / 49) /),float)
  day1 = new((/ (nrows / 49) /),float)
  day2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      day0(i) = fields(i+1,0)
      day1(i) = fields(i+1,3)
      day2(i) = fields(i+1,6)
    else
      day0(i) = fields((i*49)+1,0)
      day1(i) = fields((i*49)+1,3)
      day2(i) = fields((i*49)+1,6)
    end if
  end do

  time0 = new((/ (nrows / 49) /),float)
  time1 = new((/ (nrows / 49) /),float)
  time2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      time0(i) = fields(i+1,1)
      time1(i) = fields(i+1,4)
      time2(i) = fields(i+1,7)
    else
      time0(i) = fields((i*49)+1,1)
      time1(i) = fields((i*49)+1,4)
      time2(i) = fields((i*49)+1,7)
    end if
  end do

  psurf0 = new((/ (nrows / 49) /),float)
  psurf1 = new((/ (nrows / 49) /),float)
  psurf2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      psurf0(i) = fields(i+1,2)
      psurf1(i) = fields(i+1,5)
      psurf2(i) = fields(i+1,8)
    else
      psurf0(i) = fields((i*49)+1,2)
      psurf1(i) = fields((i*49)+1,5)
      psurf2(i) = fields((i*49)+1,8)
    end if
  end do

  stime0 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      stime0(i) = fields(i+1,10)
    else
      stime0(i) = fields((i*49)+1,10)
    end if
  end do

; END LINE 1 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Line 2 sfc dry bulb temp, sfc wet bulb temp, weather conditions, wind 
; direction at sfc, and 0-1 km thermal wind ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  dbulb0 = new((/ (nrows / 49) /),float)
  dbulb1 = new((/ (nrows / 49) /),float)
  dbulb2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      dbulb0(i) = fields(i+2,0)
      dbulb1(i) = fields(i+2,4)
      dbulb2(i) = fields(i+2,8)
    else
      dbulb0(i) = fields((i*49)+2,0)
      dbulb1(i) = fields((i*49)+2,4)
      dbulb2(i) = fields((i*49)+2,8)
    end if
  end do

  wbulb0 = new((/ (nrows / 49) /),float)
  wbulb1 = new((/ (nrows / 49) /),float)
  wbulb2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      wbulb0(i) = fields(i+2,1)
      wbulb1(i) = fields(i+2,5)
      wbulb2(i) = fields(i+2,9)
    else
      wbulb0(i) = fields((i*49)+2,1)
      wbulb1(i) = fields((i*49)+2,5)
      wbulb2(i) = fields((i*49)+2,9)
    end if
  end do

  wx0 = new((/ (nrows / 49) /),float)
  wx1 = new((/ (nrows / 49) /),float)
  wx2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      wx0(i) = fields(i+2,2)
      wx1(i) = fields(i+2,6)
      wx2(i) = fields(i+2,10)
    else
      wx0(i) = fields((i*49)+2,2)
      wx1(i) = fields((i*49)+2,6)
      wx2(i) = fields((i*49)+2,10)
    end if
  end do

  wdir0 = new((/ (nrows / 49) /),float)
  wdir1 = new((/ (nrows / 49) /),float)
  wdir2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      wdir0(i) = fields(i+2,3)
      wdir1(i) = fields(i+2,7)
      wdir2(i) = fields(i+2,11)
    else
      wdir0(i) = fields((i*49)+2,3)
      wdir1(i) = fields((i*49)+2,7)
      wdir2(i) = fields((i*49)+2,11)
    end if
  end do

  thermalu01 = new((/ (nrows / 49) /),float)
  thermalv01 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      thermalu01(i) = fields(i+2,12)
      thermalv01(i) = fields(i+2,13)
    else
      thermalu01(i) = fields((i*49)+2,12)
      thermalv01(i) = fields((i*49)+2,13)
    end if
  end do

; END LINE 2 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Line 3 Cloud coverage (oktas, range from 0 to 8, with 8 being overcast)
; low clouds first, total after, cloud types (codes in Hicks pdf), geostrophic 
; u and v winds from the synoptic network (not the sounding) ;;;;;;;;;;;;;;;;;;
  locloud0 = new((/ (nrows / 49) /),float)
  locloud1 = new((/ (nrows / 49) /),float)
  locloud2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      locloud0(i) = fields(i+3,0)
      locloud1(i) = fields(i+3,2)
      locloud2(i) = fields(i+3,4)
    else
      locloud0(i) = fields((i*49)+3,0)
      locloud1(i) = fields((i*49)+3,2)
      locloud2(i) = fields((i*49)+3,4)
    end if
  end do

  totcloud0 = new((/ (nrows / 49) /),float)
  totcloud1 = new((/ (nrows / 49) /),float)
  totcloud2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      totcloud0(i) = fields(i+3,1)
      totcloud1(i) = fields(i+3,3)
      totcloud2(i) = fields(i+3,5)
    else
      totcloud0(i) = fields((i*49)+3,1)
      totcloud1(i) = fields((i*49)+3,3)
      totcloud2(i) = fields((i*49)+3,5)
    end if
  end do

  locldtype0 = new((/ (nrows / 49) /),float)
  locldtype1 = new((/ (nrows / 49) /),float)
  locldtype2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      locldtype0(i) = fields(i+3,6)
      locldtype1(i) = fields(i+3,9)
      locldtype2(i) = fields(i+3,12)
    else
      locldtype0(i) = fields((i*49)+3,6)
      locldtype1(i) = fields((i*49)+3,9)
      locldtype2(i) = fields((i*49)+3,12)
    end if
  end do

  mdcldtype0 = new((/ (nrows / 49) /),float)
  mdcldtype1 = new((/ (nrows / 49) /),float)
  mdcldtype2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      mdcldtype0(i) = fields(i+3,7)
      mdcldtype1(i) = fields(i+3,10)
      mdcldtype2(i) = fields(i+3,13)
    else
      mdcldtype0(i) = fields((i*49)+3,7)
      mdcldtype1(i) = fields((i*49)+3,10)
      mdcldtype2(i) = fields((i*49)+3,13)
    end if
  end do

  hicldtype0 = new((/ (nrows / 49) /),float)
  hicldtype1 = new((/ (nrows / 49) /),float)
  hicldtype2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      hicldtype0(i) = fields(i+3,8)
      hicldtype1(i) = fields(i+3,11)
      hicldtype2(i) = fields(i+3,14)
    else
      hicldtype0(i) = fields((i*49)+3,8)
      hicldtype1(i) = fields((i*49)+3,11)
      hicldtype2(i) = fields((i*49)+3,14)
    end if
  end do

  geostru_syn = new((/ (nrows / 49) /),float)
  geostrv_syn = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      geostru_syn(i) = fields(i+3,15)
      geostrv_syn(i) = fields(i+3,16)
    else
      geostru_syn(i) = fields((i*49)+3,15)
      geostrv_syn(i) = fields((i*49)+3,16)
    end if
  end do

; END LINE 3 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Line 4 Sensible heat flux, net radition at ground, ground heat flux, and 
; 1-2 km thermal wind ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  shf0 = new((/ (nrows / 49) /),float)
  shf1 = new((/ (nrows / 49) /),float)
  shf2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1 
    if (i .eq. 0) then
      shf0(i) = fields(i+4,0)
      shf1(i) = fields(i+4,3)
      shf2(i) = fields(i+4,6)
    else
      shf0(i) = fields((i*49)+4,0)
      shf1(i) = fields((i*49)+4,3)
      shf2(i) = fields((i*49)+4,6)
    end if
  end do

  radnet0 = new((/ (nrows / 49) /),float)
  radnet1 = new((/ (nrows / 49) /),float)
  radnet2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1 
    if (i .eq. 0) then
      radnet0(i) = fields(i+4,1)
      radnet1(i) = fields(i+4,4)
      radnet2(i) = fields(i+4,7)
    else
      radnet0(i) = fields((i*49)+4,1)
      radnet1(i) = fields((i*49)+4,4)
      radnet2(i) = fields((i*49)+4,7)
    end if
  end do

  ghf0 = new((/ (nrows / 49) /),float)
  ghf1 = new((/ (nrows / 49) /),float)
  ghf2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      ghf0(i) = fields(i+4,2)
      ghf1(i) = fields(i+4,5)
      ghf2(i) = fields(i+4,8)
    else
      ghf0(i) = fields((i*49)+4,2)
      ghf1(i) = fields((i*49)+4,5)
      ghf2(i) = fields((i*49)+4,8)
    end if
  end do

  thermalu12 = new((/ (nrows / 49) /),float)
  thermalv12 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      thermalu12(i) = fields(i+4,9)
      thermalv12(i) = fields(i+4,10)
    else
      thermalu12(i) = fields((i*49)+4,9)
      thermalv12(i) = fields((i*49)+4,10)
    end if
  end do

; END LINE 4 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Line 5 Modified sensible heat flux, modified net radiation, and friction
; velocity (u*) ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  mshf0 = new((/ (nrows / 49) /),float)
  mshf1 = new((/ (nrows / 49) /),float)
  mshf2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      mshf0(i) = fields(i+5,0)
      mshf1(i) = fields(i+5,3)
      mshf2(i) = fields(i+5,6)
    else
      mshf0(i) = fields((i*49)+5,0)
      mshf1(i) = fields((i*49)+5,3)
      mshf2(i) = fields((i*49)+5,6)
    end if
  end do

  mradnet0 = new((/ (nrows / 49) /),float)
  mradnet1 = new((/ (nrows / 49) /),float)
  mradnet2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1 
    if (i .eq. 0) then
      mradnet0(i) = fields(i+5,1)
      mradnet1(i) = fields(i+5,4)
      mradnet2(i) = fields(i+5,7)
    else
      mradnet0(i) = fields((i*49)+5,1)
      mradnet1(i) = fields((i*49)+5,4)
      mradnet2(i) = fields((i*49)+5,7)
    end if
  end do

  fricvel0 = new((/ (nrows / 49) /),float)
  fricvel1 = new((/ (nrows / 49) /),float)
  fricvel2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1  
    if (i .eq. 0) then
      fricvel0(i) = fields(i+5,2)
      fricvel1(i) = fields(i+5,5)
      fricvel2(i) = fields(i+5,8)
    else
      fricvel0(i) = fields((i*49)+5,2)
      fricvel1(i) = fields((i*49)+5,5)
      fricvel2(i) = fields((i*49)+5,8)
    end if
  end do

; END LINE 5 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Lines 6-8 Total wind at 0.5, 1, 2, 4, 8, and 16 m for Station 4 and 5
; Note: The Hicks data had errors regarding missing values, so the dataset
; was modified by Dan D'Amico to correct for the errors. The data should now 
; match with that reported by Clarke et al. (1981) ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  st5_U0_5a = new((/ (nrows / 49) /),float)
  st5_U0_5b = new((/ (nrows / 49) /),float)
  st5_U0_5c = new((/ (nrows / 49) /),float)
  st4_U0_5a = new((/ (nrows / 49) /),float)
  st4_U0_5b = new((/ (nrows / 49) /),float)
  st4_U0_5c = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      st5_U0_5a(i) = fields(i+6,0)
      st5_U0_5b(i) = fields(i+6,2)
      st5_U0_5c(i) = fields(i+6,4)
      st4_U0_5a(i) = fields(i+6,1)
      st4_U0_5b(i) = fields(i+6,3)
      st4_U0_5c(i) = fields(i+6,5)
    else
      st5_U0_5a(i) = fields((i*49)+6,0)
      st5_U0_5b(i) = fields((i*49)+6,2)
      st5_U0_5c(i) = fields((i*49)+6,4)
      st4_U0_5a(i) = fields((i*49)+6,1)
      st4_U0_5b(i) = fields((i*49)+6,3)
      st4_U0_5c(i) = fields((i*49)+6,5)
    end if
  end do

  st5_U1a = new((/ (nrows / 49) /),float)
  st5_U1b = new((/ (nrows / 49) /),float)
  st5_U1c = new((/ (nrows / 49) /),float)
  st4_U1a = new((/ (nrows / 49) /),float)
  st4_U1b = new((/ (nrows / 49) /),float)
  st4_U1c = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      st5_U1a(i) = fields(i+6,6)
      st5_U1b(i) = fields(i+6,8)
      st5_U1c(i) = fields(i+6,10)
      st4_U1a(i) = fields(i+6,7)
      st4_U1b(i) = fields(i+6,9)
      st4_U1c(i) = fields(i+6,11)
    else
      st5_U1a(i) = fields((i*49)+6,6)
      st5_U1b(i) = fields((i*49)+6,8)
      st5_U1c(i) = fields((i*49)+6,10)
      st4_U1a(i) = fields((i*49)+6,7)
      st4_U1b(i) = fields((i*49)+6,9)
      st4_U1c(i) = fields((i*49)+6,11)
    end if
  end do

  st5_U2a = new((/ (nrows / 49) /),float)
  st5_U2b = new((/ (nrows / 49) /),float)
  st5_U2c = new((/ (nrows / 49) /),float)
  st4_U2a = new((/ (nrows / 49) /),float)
  st4_U2b = new((/ (nrows / 49) /),float)
  st4_U2c = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      st5_U2a(i) = fields(i+7,0)
      st5_U2b(i) = fields(i+7,2)
      st5_U2c(i) = fields(i+7,4)
      st4_U2a(i) = fields(i+7,1)
      st4_U2b(i) = fields(i+7,3)
      st4_U2c(i) = fields(i+7,5)
    else
      st5_U2a(i) = fields((i*49)+7,0)
      st5_U2b(i) = fields((i*49)+7,2)
      st5_U2c(i) = fields((i*49)+7,4)
      st4_U2a(i) = fields((i*49)+7,1)
      st4_U2b(i) = fields((i*49)+7,3)
      st4_U2c(i) = fields((i*49)+7,5)
    end if
  end do

  st5_U4a = new((/ (nrows / 49) /),float)
  st5_U4b = new((/ (nrows / 49) /),float)
  st5_U4c = new((/ (nrows / 49) /),float)
  st4_U4a = new((/ (nrows / 49) /),float)
  st4_U4b = new((/ (nrows / 49) /),float)
  st4_U4c = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      st5_U4a(i) = fields(i+7,6)
      st5_U4b(i) = fields(i+7,8)
      st5_U4c(i) = fields(i+7,10)
      st4_U4a(i) = fields(i+7,7)
      st4_U4b(i) = fields(i+7,9)
      st4_U4c(i) = fields(i+7,11)
    else
      st5_U4a(i) = fields((i*49)+7,6)
      st5_U4b(i) = fields((i*49)+7,8)
      st5_U4c(i) = fields((i*49)+7,10)
      st4_U4a(i) = fields((i*49)+7,7)
      st4_U4b(i) = fields((i*49)+7,9)
      st4_U4c(i) = fields((i*49)+7,11)
    end if
  end do

  st5_U8a = new((/ (nrows / 49) /),float)
  st5_U8b = new((/ (nrows / 49) /),float)
  st5_U8c = new((/ (nrows / 49) /),float)
  st4_U8a = new((/ (nrows / 49) /),float)
  st4_U8b = new((/ (nrows / 49) /),float)
  st4_U8c = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      st5_U8a(i) = fields(i+8,0)
      st5_U8b(i) = fields(i+8,2)
      st5_U8c(i) = fields(i+8,4)
      st4_U8a(i) = fields(i+8,1)
      st4_U8b(i) = fields(i+8,3)
      st4_U8c(i) = fields(i+8,5)
    else
      st5_U8a(i) = fields((i*49)+8,0)
      st5_U8b(i) = fields((i*49)+8,2)
      st5_U8c(i) = fields((i*49)+8,4)
      st4_U8a(i) = fields((i*49)+8,1)
      st4_U8b(i) = fields((i*49)+8,3)
      st4_U8c(i) = fields((i*49)+8,5)
    end if
  end do

  st5_U16a = new((/ (nrows / 49) /),float)
  st5_U16b = new((/ (nrows / 49) /),float)
  st5_U16c = new((/ (nrows / 49) /),float)
  st4_U16a = new((/ (nrows / 49) /),float)
  st4_U16b = new((/ (nrows / 49) /),float)
  st4_U16c = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      st5_U16a(i) = fields(i+8,6)
      st5_U16b(i) = fields(i+8,8)
      st5_U16c(i) = fields(i+8,10)
      st4_U16a(i) = fields(i+8,7)
      st4_U16b(i) = fields(i+8,9)
      st4_U16c(i) = fields(i+8,11)
    else
      st5_U16a(i) = fields((i*49)+8,6)
      st5_U16b(i) = fields((i*49)+8,8)
      st5_U16c(i) = fields((i*49)+8,10)
      st4_U16a(i) = fields((i*49)+8,7)
      st4_U16b(i) = fields((i*49)+8,9)
      st4_U16c(i) = fields((i*49)+8,11)
    end if
  end do

; END LINES 6-8 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Line 9 Lapse rates from 2-1 meters, 4-2 meters, and the exact time of the
; sounding ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  dT_dz_21a = new((/ (nrows / 49) /),float)
  dT_dz_21b = new((/ (nrows / 49) /),float)
  dT_dz_21c = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      dT_dz_21a(i) = fields(i+9,0)
      dT_dz_21b(i) = fields(i+9,2)
      dT_dz_21c(i) = fields(i+9,4)
    else
      dT_dz_21a(i) = fields((i*49)+9,0)
      dT_dz_21b(i) = fields((i*49)+9,2)
      dT_dz_21c(i) = fields((i*49)+9,4)
    end if
  end do

  dT_dz_42a = new((/ (nrows / 49) /),float)
  dT_dz_42b = new((/ (nrows / 49) /),float)
  dT_dz_42c = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      dT_dz_42a(i) = fields(i+9,1)
      dT_dz_42b(i) = fields(i+9,3)
      dT_dz_42c(i) = fields(i+9,5)
    else
      dT_dz_42a(i) = fields((i*49)+9,1)
      dT_dz_42b(i) = fields((i*49)+9,3)
      dT_dz_42c(i) = fields((i*49)+9,5)
    end if
  end do

  sounding_day  = new((/ (nrows / 49) /),float)
  sounding_time = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      sounding_day(i)  = fields(i+9,6)
      sounding_time(i) = fields(i+9,7)
    else
      sounding_day(i)  = fields((i*49)+9,6)
      sounding_time(i) = fields((i*49)+9,7)
    end if
  end do

; END LINE 9 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Lines 10-17 Sounding thermodynamic data, stored as pressure, temperature,
; mixing ratio ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  pres0 = new((/ (nrows / 49),8 /),float)
  pres1 = new((/ (nrows / 49),8 /),float)
  pres2 = new((/ (nrows / 49),8 /),float)
  pres3 = new((/ (nrows / 49),8 /),float)
  do j=0,7,1
    do i=0,(nrows / 49)-1,1
      if (i .eq. 0 .and. j .eq. 0) then
        pres0(i,j) = fields(i+10,0)
        pres1(i,j) = fields(i+10,3)
        pres2(i,j) = fields(i+10,6)
        pres3(i,j) = fields(i+10,9)
      else
        pres0(i,j) = fields((i*49)+(10+j),0)
        pres1(i,j) = fields((i*49)+(10+j),3)
        pres2(i,j) = fields((i*49)+(10+j),6)
        pres3(i,j) = fields((i*49)+(10+j),9)
      end if
    end do
  end do

  tair0 = new((/ (nrows / 49),8 /),float)
  tair1 = new((/ (nrows / 49),8 /),float)
  tair2 = new((/ (nrows / 49),8 /),float)
  tair3 = new((/ (nrows / 49),8 /),float)
  do j=0,7,1
    do i=0,(nrows / 49)-1,1
      if (i .eq. 0 .and. j .eq. 0) then
        tair0(i,j) = fields(i+10,1)
        tair1(i,j) = fields(i+10,4)
        tair2(i,j) = fields(i+10,7)
        tair3(i,j) = fields(i+10,10)
      else
        tair0(i,j) = fields((i*49)+(10+j),1)
        tair1(i,j) = fields((i*49)+(10+j),4)
        tair2(i,j) = fields((i*49)+(10+j),7)
        tair3(i,j) = fields((i*49)+(10+j),10)
      end if
    end do
  end do

  rv0 = new((/ (nrows / 49),8 /),float)
  rv1 = new((/ (nrows / 49),8 /),float)
  rv2 = new((/ (nrows / 49),8 /),float)
  rv3 = new((/ (nrows / 49),8 /),float)
  do j=0,7,1
    do i=0,(nrows / 49)-1,1
      if (i .eq. 0 .and. j .eq. 0) then
        rv0(i,j) = fields(i+10,2)
        rv1(i,j) = fields(i+10,5)
        rv2(i,j) = fields(i+10,8)
        rv3(i,j) = fields(i+10,11)
      else
        rv0(i,j) = fields((i*49)+(10+j),2)
        rv1(i,j) = fields((i*49)+(10+j),5)
        rv2(i,j) = fields((i*49)+(10+j),8)
        rv3(i,j) = fields((i*49)+(10+j),11)
      end if
    end do
  end do

; END LINES 10-17 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Lines 18-47 Vertical profiles of winds (u,v, and w). "N" is the number of 
; stations the wind values were averaged over. ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  u0 = new((/ (nrows / 49),30 /),float)
  u1 = new((/ (nrows / 49),30 /),float)
  u2 = new((/ (nrows / 49),30 /),float)
  do j=0,29,1
    do i=0,(nrows / 49)-1,1
      if (i .eq. 0 .and. j .eq. 0) then
        u0(i,j) = fields(i+18,0)
        u1(i,j) = fields(i+18,4)
        u2(i,j) = fields(i+18,8)
      else
        u0(i,j) = fields((i*49)+(18+j),0)
        u1(i,j) = fields((i*49)+(18+j),4)
        u2(i,j) = fields((i*49)+(18+j),8)
      end if
    end do
  end do

  v0 = new((/ (nrows / 49),30 /),float)
  v1 = new((/ (nrows / 49),30 /),float)
  v2 = new((/ (nrows / 49),30 /),float)
  do j=0,29,1
    do i=0,(nrows / 49)-1,1
      if (i .eq. 0 .and. j .eq. 0) then
        v0(i,j) = fields(i+18,1)
        v1(i,j) = fields(i+18,5)
        v2(i,j) = fields(i+18,9)
      else
        v0(i,j) = fields((i*49)+(18+j),1)
        v1(i,j) = fields((i*49)+(18+j),5)
        v2(i,j) = fields((i*49)+(18+j),9)
      end if
    end do
  end do

  w0 = new((/ (nrows / 49),30 /),float)
  w1 = new((/ (nrows / 49),30 /),float)
  w2 = new((/ (nrows / 49),30 /),float)
  do j=0,29,1
    do i=0,(nrows / 49)-1,1
      if (i .eq. 0 .and. j .eq. 0) then
        w0(i,j) = fields(i+18,2)
        w1(i,j) = fields(i+18,6)
        w2(i,j) = fields(i+18,10)
      else
        w0(i,j) = fields((i*49)+(18+j),2)
        w1(i,j) = fields((i*49)+(18+j),6)
        w2(i,j) = fields((i*49)+(18+j),10)
      end if
    end do
  end do

  N0 = new((/ (nrows / 49),30 /),float)
  N1 = new((/ (nrows / 49),30 /),float)
  N2 = new((/ (nrows / 49),30 /),float)
  do j=0,29,1
    do i=0,(nrows / 49)-1,1
      if (i .eq. 0 .and. j .eq. 0) then
        N0(i,j) = fields(i+18,3)
        N1(i,j) = fields(i+18,7)
        N2(i,j) = fields(i+18,11)
      else
        N0(i,j) = fields((i*49)+(18+j),3)
        N1(i,j) = fields((i*49)+(18+j),7)
        N2(i,j) = fields((i*49)+(18+j),11)
      end if
    end do
  end do

; END LINES 18-47 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Lines 48-49 Geostrophic u and v wind from experiment observations and
; 500 m acceleration ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ugeo_obs0 = new((/ (nrows / 49) /),float)
  ugeo_obs1 = new((/ (nrows / 49) /),float)
  ugeo_obs2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      ugeo_obs0(i) = fields(i+48,0)
      ugeo_obs1(i) = fields(i+48,4)
      ugeo_obs2(i) = fields(i+49,0)
    else
      ugeo_obs0(i) = fields((i*49)+48,0)
      ugeo_obs1(i) = fields((i*49)+48,4)
      ugeo_obs2(i) = fields((i*49)+49,0)
    end if
  end do

  vgeo_obs0 = new((/ (nrows / 49) /),float)
  vgeo_obs1 = new((/ (nrows / 49) /),float)
  vgeo_obs2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      vgeo_obs0(i) = fields(i+48,1)
      vgeo_obs1(i) = fields(i+48,5)
      vgeo_obs2(i) = fields(i+49,1)
    else
      vgeo_obs0(i) = fields((i*49)+48,1)
      vgeo_obs1(i) = fields((i*49)+48,5)
      vgeo_obs2(i) = fields((i*49)+49,1)
    end if
  end do

  uaccel0 = new((/ (nrows / 49) /),float)
  uaccel1 = new((/ (nrows / 49) /),float)
  uaccel2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      uaccel0(i) = fields(i+48,2)
      uaccel1(i) = fields(i+48,6)
      uaccel2(i) = fields(i+49,2)
    else
      uaccel0(i) = fields((i*49)+48,2)
      uaccel1(i) = fields((i*49)+48,6)
      uaccel2(i) = fields((i*49)+49,2)
    end if
  end do

  vaccel0 = new((/ (nrows / 49) /),float)
  vaccel1 = new((/ (nrows / 49) /),float)
  vaccel2 = new((/ (nrows / 49) /),float)
  do i=0,(nrows / 49)-1,1
    if (i .eq. 0) then
      vaccel0(i) = fields(i+48,3)
      vaccel1(i) = fields(i+48,7)
      vaccel2(i) = fields(i+49,3)
    else
      vaccel0(i) = fields((i*49)+48,3)
      vaccel1(i) = fields((i*49)+48,7)
      vaccel2(i) = fields((i*49)+49,3)
    end if
  end do

; END LINES 48-49 ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; End reading of data ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Organize the data into arrays that are easier to use and easier to write 
; in netCDF ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  delete(fields)

  day    = new((/ dimsizes(day0)*3 /),float)
  day(0) = day0(0)
  day(1) = day1(0)
  day(2) = day2(0)

  do i=3,(dimsizes(day0)*3)-1,3
    day(i) = day0(i/3)
  end do
  do i=4,(dimsizes(day0)*3)-1,3
    day(i) = day1(i/3)
  end do
  do i=5,(dimsizes(day0)*3)-1,3
    day(i) = day2(i/3)
  end do

  delete(day0)
  delete(day1)
  delete(day2)

  day@long_name = "Day of experiment"

  timeX    = new((/ dimsizes(time0)*3 /),float)
  timeX(0) = time0(0)
  timeX(1) = time1(0)
  timeX(2) = time2(0)

  do i=3,(dimsizes(time0)*3)-1,3
    timeX(i) = time0(i/3)
  end do
  do i=4,(dimsizes(time0)*3)-1,3
    timeX(i) = time1(i/3)
  end do
  do i=5,(dimsizes(time0)*3)-1,3
    timeX(i) = time2(i/3)
  end do

  Time_strings = sprinti("%0.4i",toint(timeX))
  Time_strings@long_name  = "Time"
  Time_strings@units      = "Australian Eastern Standard Time"
  Time_strings@_FillValue = 9999
  timeX@units             = Time_strings@units

  psurf    = new((/ dimsizes(psurf0)*3 /),float,9999.9)
  psurf(0) = 9999.9
  psurf(1) = 9999.9
  psurf(2) = 9999.9

  do i=3,(dimsizes(psurf0)*3)-1,3
    psurf(i) = psurf0(i/3)
  end do
  do i=4,(dimsizes(psurf0)*3)-1,3
    psurf(i) = psurf1(i/3)
  end do
  do i=5,(dimsizes(psurf0)*3)-1,3
    psurf(i) = psurf2(i/3)
  end do

  delete(psurf0)
  delete(psurf1)
  delete(psurf2)

  psurf@long_name  = "Air pressure at the surface"
  psurf@units      = "hPa"
  psurf@_FillValue = 9999.9

  approx_sounding_time = sprinti("%0.4i",toint(stime0))

  approx_sounding_time@long_name = "Approximate time of 3-hourly sounding"
  approx_sounding_time@units     = Time_strings@units

  exact_sounding_time = sprinti("%0.4i",toint(sounding_time))

  exact_sounding_time@long_name = "Exact time of 3-hourly sounding"
  exact_sounding_time@units     = Time_strings@units

  sounding_day@long_name = day@long_name

  dbulb    = new((/ dimsizes(dbulb0)*3 /),float)
  dbulb(0) = dbulb0(0)
  dbulb(1) = dbulb1(0)
  dbulb(2) = dbulb2(0)

  do i=3,(dimsizes(dbulb0)*3)-1,3
    dbulb(i) = dbulb0(i/3)
  end do
  do i=4,(dimsizes(dbulb0)*3)-1,3
    dbulb(i) = dbulb1(i/3)
  end do
  do i=5,(dimsizes(dbulb0)*3)-1,3
    dbulb(i) = dbulb2(i/3)
  end do

  delete(dbulb0)
  delete(dbulb1)
  delete(dbulb2)

  dbulb@long_name = "Surface dry bulb temperature"
  dbulb@units     = "C"

  wbulb    = new((/ dimsizes(wbulb0)*3 /),float)
  wbulb(0) = wbulb0(0)
  wbulb(1) = wbulb1(0)
  wbulb(2) = wbulb2(0)
  
  do i=3,(dimsizes(wbulb0)*3)-1,3
    wbulb(i) = wbulb0(i/3)
  end do
  do i=4,(dimsizes(wbulb0)*3)-1,3
    wbulb(i) = wbulb1(i/3)
  end do
  do i=5,(dimsizes(wbulb0)*3)-1,3
    wbulb(i) = wbulb2(i/3)
  end do

  delete(wbulb0)
  delete(wbulb1)
  delete(wbulb2)

  wbulb@long_name = "Surface wet bulb temperature"
  wbulb@units     = "C"

  weather    = new((/ dimsizes(wx0)*3 /),float)
  weather(0) = wx0(0)
  weather(1) = wx1(0)
  weather(2) = wx2(0)

  do i=3,(dimsizes(wx0)*3)-1,3
    weather(i) = wx0(i/3)
  end do
  do i=4,(dimsizes(wx0)*3)-1,3
    weather(i) = wx1(i/3)
  end do
  do i=5,(dimsizes(wx0)*3)-1,3
    weather(i) = wx2(i/3)
  end do

  delete(wx0)
  delete(wx1)
  delete(wx2)

  weather@long_name  = "Weather conditions at surface"
  weather@units      = "Codes Based on Hicks Dataset"

  wdir = new((/ dimsizes(wdir0)*3 /),float,999)
  wdir(0) = wdir0(0)
  wdir(1) = wdir1(0)
  wdir(2) = wdir2(0)

  do i=3,(dimsizes(wdir0)*3)-1,3
    wdir(i) = wdir0(i/3)
  end do
  do i=4,(dimsizes(wdir0)*3)-1,3
    wdir(i) = wdir1(i/3)
  end do
  do i=5,(dimsizes(wdir0)*3)-1,3
    wdir(i) = wdir2(i/3)
  end do

  delete(wdir0)
  delete(wdir1)
  delete(wdir2)

  wdir@long_name  = "Surface wind direction"
  wdir@units      = "deg"
  wdir@_FillValue = 999

  thermalu01@long_name  = "0-1 km thermal W-E wind"
  thermalu01@units      = "cm s-1"
  thermalu01@_FillValue = 9999

  thermalv01@long_name  = "0-1 km thermal S-N wind"
  thermalv01@units      = "cm s-1"
  thermalv01@_FillValue = 9999

  thermalu12@long_name  = "1-2 km thermal W-E wind"
  thermalu12@units      = "cm s-1"
  thermalu12@_FillValue = 9999

  thermalv12@long_name  = "1-2 km thermal S-N wind"
  thermalv12@units      = "cm s-1"
  thermalv12@_FillValue = 9999

  low_cloud    = new((/ dimsizes(locloud0)*3 /),float)
  low_cloud(0) = locloud0(0)
  low_cloud(1) = locloud1(0)
  low_cloud(2) = locloud2(0)

  do i=3,(dimsizes(locloud0)*3)-1,3
    low_cloud(i) = locloud0(i/3)
  end do
  do i=4,(dimsizes(locloud0)*3)-1,3
    low_cloud(i) = locloud1(i/3)
  end do
  do i=5,(dimsizes(locloud0)*3)-1,3
    low_cloud(i) = locloud2(i/3)
  end do

  delete(locloud0)
  delete(locloud1)
  delete(locloud2)

  low_cloud@long_name = "Low clouds"
  low_cloud@units     = "oktas"

  tot_cloud    = new((/ dimsizes(totcloud0)*3 /),float)
  tot_cloud(0) = totcloud0(0)
  tot_cloud(1) = totcloud1(0)
  tot_cloud(2) = totcloud2(0)

  do i=3,(dimsizes(totcloud0)*3)-1,3
    tot_cloud(i) = totcloud0(i/3)
  end do
  do i=4,(dimsizes(totcloud0)*3)-1,3
    tot_cloud(i) = totcloud1(i/3)
  end do
  do i=5,(dimsizes(totcloud0)*3)-1,3
    tot_cloud(i) = totcloud2(i/3)
  end do

  delete(totcloud0)
  delete(totcloud1)
  delete(totcloud2)

  tot_cloud@long_name = "Total clouds"
  tot_cloud@units     = "oktas"

  low_cldtype    = new((/ dimsizes(locldtype0)*3 /),float)
  low_cldtype(0) = locldtype0(0)
  low_cldtype(1) = locldtype1(0)
  low_cldtype(2) = locldtype2(0)

  do i=3,(dimsizes(locldtype0)*3)-1,3
    low_cldtype(i) = locldtype0(i/3)
  end do
  do i=4,(dimsizes(locldtype0)*3)-1,3
    low_cldtype(i) = locldtype1(i/3)
  end do
  do i=5,(dimsizes(locldtype0)*3)-1,3
    low_cldtype(i) = locldtype2(i/3)
  end do

  delete(locldtype0)
  delete(locldtype1)
  delete(locldtype2)

  low_cldtype@long_name = "Low cloud type"
  low_cldtype@units     = "Codes Based on Hicks Dataset"

  mid_cldtype    = new((/ dimsizes(mdcldtype0)*3 /),float)
  mid_cldtype(0) = mdcldtype0(0)
  mid_cldtype(1) = mdcldtype1(0)
  mid_cldtype(2) = mdcldtype2(0)

  do i=3,(dimsizes(mdcldtype0)*3)-1,3
    mid_cldtype(i) = mdcldtype0(i/3)
  end do
  do i=4,(dimsizes(mdcldtype0)*3)-1,3
    mid_cldtype(i) = mdcldtype1(i/3)
  end do
  do i=5,(dimsizes(mdcldtype0)*3)-1,3
    mid_cldtype(i) = mdcldtype2(i/3)
  end do

  delete(mdcldtype0)
  delete(mdcldtype1)
  delete(mdcldtype2)

  mid_cldtype@long_name = "Mid-level cloud type"
  mid_cldtype@units     = "Codes Based on Hicks Dataset"

  high_cldtype    = new((/ dimsizes(hicldtype0)*3 /),float)
  high_cldtype(0) = hicldtype0(0)
  high_cldtype(1) = hicldtype1(0)
  high_cldtype(2) = hicldtype2(0)
  
  do i=3,(dimsizes(hicldtype0)*3)-1,3
    high_cldtype(i) = hicldtype0(i/3)
  end do
  do i=4,(dimsizes(hicldtype0)*3)-1,3
    high_cldtype(i) = hicldtype1(i/3)
  end do
  do i=5,(dimsizes(hicldtype0)*3)-1,3
    high_cldtype(i) = hicldtype2(i/3)
  end do

  delete(hicldtype0)
  delete(hicldtype1)
  delete(hicldtype2)

  high_cldtype@long_name = "High cloud type"
  high_cldtype@units     = "Codes Based on Hicks Dataset"

  synoptic_geou = geostru_syn

  synoptic_geou@long_name = "Geostrophic W-E wind based on synoptic charts"
  synoptic_geou@units     = "cm s-1"

  synoptic_geov = geostrv_syn

  synoptic_geov@long_name = "Geostrophic S-N wind based on synoptic charts"
  synoptic_geov@units     = "cm s-1"

  shf_mWcm2    = new((/ dimsizes(shf0)*3 /),float,99.9)
  shf_mWcm2(0) = shf0(0)
  shf_mWcm2(1) = shf1(0)
  shf_mWcm2(2) = shf2(0)

  do i=3,(dimsizes(shf0)*3)-1,3
    shf_mWcm2(i) = shf0(i/3)
  end do
  do i=4,(dimsizes(shf0)*3)-1,3
    shf_mWcm2(i) = shf1(i/3)
  end do
  do i=5,(dimsizes(shf0)*3)-1,3
    shf_mWcm2(i) = shf2(i/3)
  end do

  delete(shf0)
  delete(shf1)
  delete(shf2)

  shf_mWcm2@long_name  = "Surface sensible heat flux"
  shf_mWcm2@units      = "mW cm-2"
  shf_mWcm2@_FillValue = 99.9

  netrad_mWcm2    = new((/ dimsizes(radnet0)*3 /),float,99.9)
  netrad_mWcm2(0) = radnet0(0)
  netrad_mWcm2(1) = radnet1(0)
  netrad_mWcm2(2) = radnet2(0)

  do i=3,(dimsizes(radnet0)*3)-1,3
    netrad_mWcm2(i) = radnet0(i/3)
  end do
  do i=4,(dimsizes(radnet0)*3)-1,3
    netrad_mWcm2(i) = radnet1(i/3)
  end do
  do i=5,(dimsizes(radnet0)*3)-1,3
    netrad_mWcm2(i) = radnet2(i/3)
  end do

  delete(radnet0)
  delete(radnet2)
  delete(radnet1)

  netrad_mWcm2@long_name  = "Net radiation at the surface"
  netrad_mWcm2@units      = "mW cm-2"
  netrad_mWcm2@_FillValue = 99.9

  ghf_mWcm2    = new((/ dimsizes(ghf0)*3 /),float,99.9)
  ghf_mWcm2(0) = ghf0(0)
  ghf_mWcm2(1) = ghf1(0)
  ghf_mWcm2(2) = ghf2(0)

  do i=3,(dimsizes(ghf0)*3)-1,3
    ghf_mWcm2(i) = ghf0(i/3)
  end do
  do i=4,(dimsizes(ghf0)*3)-1,3
    ghf_mWcm2(i) = ghf1(i/3)
  end do
  do i=5,(dimsizes(ghf0)*3)-1,3
    ghf_mWcm2(i) = ghf2(i/3)
  end do

  delete(ghf0)
  delete(ghf1)
  delete(ghf2)

  ghf_mWcm2@long_name  = "Ground heat flux"
  ghf_mWcm2@units      = "mW cm-2"
  ghf_mWcm2@_FillValue = 99.9

  shf_Wm2 = new((/ dimsizes(mshf0)*3 /),float,9999)
  shf_Wm2(0) = mshf0(0)
  shf_Wm2(1) = mshf1(0)
  shf_Wm2(2) = mshf2(0)

  do i=3,(dimsizes(mshf0)*3)-1,3
    shf_Wm2(i) = mshf0(i/3)
  end do
  do i=4,(dimsizes(mshf0)*3)-1,3
    shf_Wm2(i) = mshf1(i/3)
  end do
  do i=5,(dimsizes(mshf0)*3)-1,3
    shf_Wm2(i) = mshf2(i/3)
  end do

  delete(mshf0)
  delete(mshf1)
  delete(mshf2)

  shf_Wm2@long_name  = "Surface sensible heat flux"
  shf_Wm2@units      = "W m-2"
  shf_Wm2@_FillValue = 9999

  netrad_Wm2 = new((/ dimsizes(mradnet0)*3 /),float,9999)
  netrad_Wm2(0) = mradnet0(0)
  netrad_Wm2(1) = mradnet1(0)
  netrad_Wm2(2) = mradnet2(0)

  do i=3,(dimsizes(mradnet0)*3)-1,3
    netrad_Wm2(i) = mradnet0(i/3)
  end do
  do i=4,(dimsizes(mradnet0)*3)-1,3
    netrad_Wm2(i) = mradnet1(i/3)
  end do
  do i=5,(dimsizes(mradnet0)*3)-1,3
    netrad_Wm2(i) = mradnet2(i/3)
  end do

  delete(mradnet0)
  delete(mradnet2)
  delete(mradnet1)

  netrad_Wm2@long_name  = "Net radiation at the surface"
  netrad_Wm2@units      = "W m-2"
  netrad_Wm2@_FillValue = 9999

  friction_vel    = new((/ dimsizes(fricvel0)*3 /),float,99.99999)
  friction_vel(0) = fricvel0(0)
  friction_vel(1) = fricvel1(0)
  friction_vel(2) = fricvel2(0)

  do i=3,(dimsizes(fricvel0)*3)-1,3
    friction_vel(i) = fricvel0(i/3)
  end do
  do i=4,(dimsizes(fricvel0)*3)-1,3
    friction_vel(i) = fricvel1(i/3)
  end do
  do i=5,(dimsizes(fricvel0)*3)-1,3
    friction_vel(i) = fricvel2(i/3)
  end do

  delete(fricvel0)
  delete(fricvel1)
  delete(fricvel2)

  friction_vel@long_name  = "Surface friction velocity"
  friction_vel@units      = "cm s-1"
  friction_vel@_FillValue = 99.99999

  U0_5_Sta5    = new((/ dimsizes(st5_U0_5a)*3 /),float,9999)
  U0_5_Sta5(0) = st5_U0_5a(0)
  U0_5_Sta5(1) = st5_U0_5b(0)
  U0_5_Sta5(2) = st5_U0_5c(0)

  do i=3,(dimsizes(st5_U0_5a)*3)-1,3
    U0_5_Sta5(i) = st5_U0_5a(i/3)
  end do
  do i=4,(dimsizes(st5_U0_5a)*3)-1,3
    U0_5_Sta5(i) = st5_U0_5b(i/3)
  end do
  do i=5,(dimsizes(st5_U0_5a)*3)-1,3
    U0_5_Sta5(i) = st5_U0_5c(i/3)
  end do

  delete(st5_U0_5a)
  delete(st5_U0_5b)
  delete(st5_U0_5c)

  U0_5_Sta5@long_name  = "Wind speed at 0.5 m recorded at Station 5"
  U0_5_Sta5@units      = "cm s-1"
  U0_5_Sta5@_FillValue = 9999

  U0_5_Sta4    = new((/ dimsizes(st4_U0_5a)*3 /),float,9999)
  U0_5_Sta4(0) = st4_U0_5a(0)
  U0_5_Sta4(1) = st4_U0_5b(0)
  U0_5_Sta4(2) = st4_U0_5c(0)
  
  do i=3,(dimsizes(st4_U0_5a)*3)-1,3
    U0_5_Sta4(i) = st4_U0_5a(i/3)
  end do
  do i=4,(dimsizes(st4_U0_5a)*3)-1,3
    U0_5_Sta4(i) = st4_U0_5b(i/3)
  end do
  do i=5,(dimsizes(st4_U0_5a)*3)-1,3
    U0_5_Sta4(i) = st4_U0_5c(i/3)
  end do

  delete(st4_U0_5a)
  delete(st4_U0_5b)
  delete(st4_U0_5c)

  U0_5_Sta4@long_name  = "Wind speed at 0.5 m recorded at Station 4"
  U0_5_Sta4@units      = "cm s-1"
  U0_5_Sta4@_FillValue = 9999

  U1_Sta5    = new((/ dimsizes(st5_U1a)*3 /),float,9999)
  U1_Sta5(0) = st5_U1a(0)
  U1_Sta5(1) = st5_U1b(0)
  U1_Sta5(2) = st5_U1c(0)
  
  do i=3,(dimsizes(st5_U1a)*3)-1,3
    U1_Sta5(i) = st5_U1a(i/3)
  end do
  do i=4,(dimsizes(st5_U1a)*3)-1,3
    U1_Sta5(i) = st5_U1b(i/3)
  end do
  do i=5,(dimsizes(st5_U1a)*3)-1,3
    U1_Sta5(i) = st5_U1c(i/3)
  end do

  delete(st5_U1a)
  delete(st5_U1b)
  delete(st5_U1c)

  U1_Sta5@long_name  = "Wind speed at 1 m recorded at Station 5"
  U1_Sta5@units      = "cm s-1"
  U1_Sta5@_FillValue = 9999

  U1_Sta4    = new((/ dimsizes(st4_U1a)*3 /),float,9999)
  U1_Sta4(0) = st4_U1a(0)
  U1_Sta4(1) = st4_U1b(0)
  U1_Sta4(2) = st4_U1c(0)
  
  do i=3,(dimsizes(st4_U1a)*3)-1,3
    U1_Sta4(i) = st4_U1a(i/3)
  end do
  do i=4,(dimsizes(st4_U1a)*3)-1,3
    U1_Sta4(i) = st4_U1b(i/3)
  end do
  do i=5,(dimsizes(st4_U1a)*3)-1,3
    U1_Sta4(i) = st4_U1c(i/3)
  end do

  delete(st4_U1a)
  delete(st4_U1b)
  delete(st4_U1c)

  U1_Sta4@long_name  = "Wind speed at 1 m recorded at Station 4"
  U1_Sta4@units      = "cm s-1"
  U1_Sta4@_FillValue = 9999

  U2_Sta5    = new((/ dimsizes(st5_U2a)*3 /),float,9999)
  U2_Sta5(0) = st5_U2a(0)
  U2_Sta5(1) = st5_U2b(0)
  U2_Sta5(2) = st5_U2c(0)
  
  do i=3,(dimsizes(st5_U2a)*3)-1,3
    U2_Sta5(i) = st5_U2a(i/3)
  end do
  do i=4,(dimsizes(st5_U2a)*3)-1,3
    U2_Sta5(i) = st5_U2b(i/3)
  end do
  do i=5,(dimsizes(st5_U2a)*3)-1,3
    U2_Sta5(i) = st5_U2c(i/3)
  end do

  delete(st5_U2a)
  delete(st5_U2b)
  delete(st5_U2c)

  U2_Sta5@long_name  = "Wind speed at 2 m recorded at Station 5"
  U2_Sta5@units      = "cm s-1"
  U2_Sta5@_FillValue = 9999

  U2_Sta4    = new((/ dimsizes(st4_U2a)*3 /),float,9999)
  U2_Sta4(0) = st4_U2a(0)
  U2_Sta4(1) = st4_U2b(0)
  U2_Sta4(2) = st4_U2c(0)

  do i=3,(dimsizes(st4_U2a)*3)-1,3
    U2_Sta4(i) = st4_U2a(i/3)
  end do
  do i=4,(dimsizes(st4_U2a)*3)-1,3
    U2_Sta4(i) = st4_U2b(i/3)
  end do
  do i=5,(dimsizes(st4_U2a)*3)-1,3
    U2_Sta4(i) = st4_U2c(i/3)
  end do

  delete(st4_U2a)
  delete(st4_U2b)
  delete(st4_U2c)

  U2_Sta4@long_name  = "Wind speed at 2 m recorded at Station 4"
  U2_Sta4@units      = "cm s-1"
  U2_Sta4@_FillValue = 9999

  U4_Sta5    = new((/ dimsizes(st5_U4a)*3 /),float,9999)
  U4_Sta5(0) = st5_U4a(0)
  U4_Sta5(1) = st5_U4b(0)
  U4_Sta5(2) = st5_U4c(0)
  
  do i=3,(dimsizes(st5_U4a)*3)-1,3
    U4_Sta5(i) = st5_U4a(i/3)
  end do
  do i=4,(dimsizes(st5_U4a)*3)-1,3
    U4_Sta5(i) = st5_U4b(i/3)
  end do
  do i=5,(dimsizes(st5_U4a)*3)-1,3
    U4_Sta5(i) = st5_U4c(i/3)
  end do

  delete(st5_U4a)
  delete(st5_U4b)
  delete(st5_U4c)

  U4_Sta5@long_name  = "Wind speed at 4 m recorded at Station 5"
  U4_Sta5@units      = "cm s-1"
  U4_Sta5@_FillValue = 9999

  U4_Sta4    = new((/ dimsizes(st4_U4a)*3 /),float,9999)
  U4_Sta4(0) = st4_U4a(0)
  U4_Sta4(1) = st4_U4b(0)
  U4_Sta4(2) = st4_U4c(0)
    
  do i=3,(dimsizes(st4_U4a)*3)-1,3
    U4_Sta4(i) = st4_U4a(i/3)
  end do
  do i=4,(dimsizes(st4_U4a)*3)-1,3
    U4_Sta4(i) = st4_U4b(i/3)
  end do
  do i=5,(dimsizes(st4_U4a)*3)-1,3
    U4_Sta4(i) = st4_U4c(i/3)
  end do

  delete(st4_U4a)
  delete(st4_U4b)
  delete(st4_U4c)

  U4_Sta4@long_name  = "Wind speed at 4 m recorded at Station 4"
  U4_Sta4@units      = "cm s-1"
  U4_Sta4@_FillValue = 9999

  U8_Sta5    = new((/ dimsizes(st5_U8a)*3 /),float,9999)
  U8_Sta5(0) = st5_U8a(0)
  U8_Sta5(1) = st5_U8b(0)
  U8_Sta5(2) = st5_U8c(0)

  do i=3,(dimsizes(st5_U8a)*3)-1,3
    U8_Sta5(i) = st5_U8a(i/3)
  end do
  do i=4,(dimsizes(st5_U8a)*3)-1,3
    U8_Sta5(i) = st5_U8b(i/3)
  end do
  do i=5,(dimsizes(st5_U8a)*3)-1,3
    U8_Sta5(i) = st5_U8c(i/3)
  end do

  delete(st5_U8a)
  delete(st5_U8b)
  delete(st5_U8c)

  U8_Sta5@long_name  = "Wind speed at 8 m recorded at Station 5"
  U8_Sta5@units      = "cm s-1"
  U8_Sta5@_FillValue = 9999

  U8_Sta4    = new((/ dimsizes(st4_U8a)*3 /),float,9999)
  U8_Sta4(0) = st4_U8a(0)
  U8_Sta4(1) = st4_U8b(0)
  U8_Sta4(2) = st4_U8c(0)
     
  do i=3,(dimsizes(st4_U8a)*3)-1,3
    U8_Sta4(i) = st4_U8a(i/3)
  end do
  do i=4,(dimsizes(st4_U8a)*3)-1,3
    U8_Sta4(i) = st4_U8b(i/3)
  end do
  do i=5,(dimsizes(st4_U8a)*3)-1,3
    U8_Sta4(i) = st4_U8c(i/3)
  end do

  delete(st4_U8a)
  delete(st4_U8b)
  delete(st4_U8c)

  U8_Sta4@long_name  = "Wind speed at 8 m recorded at Station 4"
  U8_Sta4@units      = "cm s-1"
  U8_Sta4@_FillValue = 9999

  U16_Sta5    = new((/ dimsizes(st5_U16a)*3 /),float,9999)
  U16_Sta5(0) = st5_U16a(0)
  U16_Sta5(1) = st5_U16b(0)
  U16_Sta5(2) = st5_U16c(0)

  do i=3,(dimsizes(st5_U16a)*3)-1,3
    U16_Sta5(i) = st5_U16a(i/3)
  end do
  do i=4,(dimsizes(st5_U16a)*3)-1,3
    U16_Sta5(i) = st5_U16b(i/3)
  end do
  do i=5,(dimsizes(st5_U16a)*3)-1,3
    U16_Sta5(i) = st5_U16c(i/3)
  end do

  delete(st5_U16a)
  delete(st5_U16b)
  delete(st5_U16c)

  U16_Sta5@long_name  = "Wind speed at 16 m recorded at Station 5"
  U16_Sta5@units      = "cm s-1"
  U16_Sta5@_FillValue = 9999

  U16_Sta4    = new((/ dimsizes(st4_U16a)*3 /),float,9999)
  U16_Sta4(0) = st4_U16a(0)
  U16_Sta4(1) = st4_U16b(0)
  U16_Sta4(2) = st4_U16c(0)
     
  do i=3,(dimsizes(st4_U16a)*3)-1,3
    U16_Sta4(i) = st4_U16a(i/3)
  end do
  do i=4,(dimsizes(st4_U16a)*3)-1,3
    U16_Sta4(i) = st4_U16b(i/3)
  end do
  do i=5,(dimsizes(st4_U16a)*3)-1,3
    U16_Sta4(i) = st4_U16c(i/3)
  end do

  delete(st4_U16a)
  delete(st4_U16b)
  delete(st4_U16c)

  U16_Sta4@long_name  = "Wind speed at 16 m recorded at Station 4"
  U16_Sta4@units      = "cm s-1"
  U16_Sta4@_FillValue = 9999

  dT_dz_21    = new((/ dimsizes(dT_dz_21a)*3 /),float,99.99)
  dT_dz_21(0) = dT_dz_21a(0)
  dT_dz_21(1) = dT_dz_21b(0)
  dT_dz_21(2) = dT_dz_21c(0)

  do i=3,(dimsizes(dT_dz_21a)*3)-1,3
    dT_dz_21(i) = dT_dz_21a(i/3)
  end do
  do i=4,(dimsizes(dT_dz_21a)*3)-1,3
    dT_dz_21(i) = dT_dz_21b(i/3)
  end do
  do i=5,(dimsizes(dT_dz_21a)*3)-1,3
    dT_dz_21(i) = dT_dz_21c(i/3)
  end do

  delete(dT_dz_21a)
  delete(dT_dz_21b)
  delete(dT_dz_21c)

  dT_dz_21@long_name  = "Temperature change between 2 m and 1 m"
  dT_dz_21@units      = "C"
  dT_dz_21@_FillValue = 99.99

  dT_dz_42    = new((/ dimsizes(dT_dz_42a)*3 /),float,99.99)
  dT_dz_42(0) = dT_dz_42a(0)
  dT_dz_42(1) = dT_dz_42b(0)
  dT_dz_42(2) = dT_dz_42c(0)
  
  do i=3,(dimsizes(dT_dz_42a)*3)-1,3
    dT_dz_42(i) = dT_dz_42a(i/3)
  end do
  do i=4,(dimsizes(dT_dz_42a)*3)-1,3
    dT_dz_42(i) = dT_dz_42b(i/3)
  end do
  do i=5,(dimsizes(dT_dz_42a)*3)-1,3
    dT_dz_42(i) = dT_dz_42c(i/3)
  end do

  delete(dT_dz_42a)
  delete(dT_dz_42b)
  delete(dT_dz_42c)

  dT_dz_42@long_name  = "Temperature change between 4 m and 2 m"
  dT_dz_42@units      = "C"
  dT_dz_42@_FillValue = 99.99

; Pressure, temperature, and mixing ratio from the sounding are placed in one-
; dimensional arrays, so that all of them can match each other when placed 
; into a single total array ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  presSOUND0 = ndtooned(pres0)
  presSOUND1 = ndtooned(pres1)
  presSOUND2 = ndtooned(pres2)
  presSOUND3 = ndtooned(pres3)

  presall    = new((/ dimsizes(presSOUND0)*4 /),float,9999)
  presall(0) = presSOUND0(0)
  presall(1) = presSOUND1(0)
  presall(2) = presSOUND2(0)
  presall(3) = presSOUND3(0)

  do i=4,(dimsizes(presSOUND0)*4)-1,4
    presall(i) = presSOUND0(i/4)
  end do
  do i=5,(dimsizes(presSOUND0)*4)-1,4
    presall(i) = presSOUND1(i/4)
  end do
  do i=6,(dimsizes(presSOUND0)*4)-1,4
    presall(i) = presSOUND2(i/4)
  end do
  do i=7,(dimsizes(presSOUND0)*4)-1,4
    presall(i) = presSOUND3(i/4)
  end do

  delete(pres0)
  delete(pres1)
  delete(pres2)
  delete(pres3)
  delete(presSOUND0)
  delete(presSOUND1)
  delete(presSOUND2)
  delete(presSOUND3)

  pres = onedtond(presall,(/ 315,32 /))

  delete(presall)

  pres@long_name  = "Pressure"
  pres@units      = "hPa"
  pres@_FillValue = 9999

  tairSOUND0 = ndtooned(tair0)
  tairSOUND1 = ndtooned(tair1)
  tairSOUND2 = ndtooned(tair2)
  tairSOUND3 = ndtooned(tair3)

  tairall    = new((/ dimsizes(tairSOUND0)*4 /),float,999.9)
  tairall(0) = tairSOUND0(0)
  tairall(1) = tairSOUND1(0)
  tairall(2) = tairSOUND2(0)
  tairall(3) = tairSOUND3(0)
    
  do i=4,(dimsizes(tairSOUND0)*4)-1,4
    tairall(i) = tairSOUND0(i/4)
  end do
  do i=5,(dimsizes(tairSOUND0)*4)-1,4
    tairall(i) = tairSOUND1(i/4)
  end do
  do i=6,(dimsizes(tairSOUND0)*4)-1,4
    tairall(i) = tairSOUND2(i/4)
  end do
  do i=7,(dimsizes(tairSOUND0)*4)-1,4
    tairall(i) = tairSOUND3(i/4)
  end do

  tair = onedtond(tairall,(/ 315,32 /))

  tair@long_name  = "Absolute air temperature"
  tair@units      = "C"
  tair@_FillValue = 999.9

  delete(tair0)
  delete(tair1)
  delete(tair2)
  delete(tair3)
  delete(tairSOUND0)
  delete(tairSOUND1)
  delete(tairSOUND2)
  delete(tairSOUND3)
  delete(tairall)

  rvSOUND0 = ndtooned(rv0)
  rvSOUND1 = ndtooned(rv1)
  rvSOUND2 = ndtooned(rv2)
  rvSOUND3 = ndtooned(rv3)

  rvall    = new((/ dimsizes(rvSOUND0)*4 /),float,99.9)
  rvall(0) = rvSOUND0(0)
  rvall(1) = rvSOUND1(0)
  rvall(2) = rvSOUND2(0)
  rvall(3) = rvSOUND3(0)

  do i=4,(dimsizes(rvSOUND0)*4)-1,4
    rvall(i) = rvSOUND0(i/4)
  end do
  do i=5,(dimsizes(rvSOUND0)*4)-1,4
    rvall(i) = rvSOUND1(i/4)
  end do
  do i=6,(dimsizes(rvSOUND0)*4)-1,4
    rvall(i) = rvSOUND2(i/4)
  end do
  do i=7,(dimsizes(rvSOUND0)*4)-1,4
    rvall(i) = rvSOUND3(i/4)
  end do

  delete(rv0)
  delete(rv1)
  delete(rv2)
  delete(rv3)
  delete(rvSOUND0)
  delete(rvSOUND1)
  delete(rvSOUND2)
  delete(rvSOUND3)

  rv = onedtond(rvall,(/ 315,32 /))

  delete(rvall)

  rv@long_name  = "Water vapor mixing ratio"
  rv@units      = "g kg-1"
  rv@_FillValue = 99.9

  uSOUND = new((/ dimsizes(u0(:,0)),3,dimsizes(u0(0,:)) /),float,99999)

  uSOUND(:,0,:) = u0
  uSOUND(:,1,:) = u1
  uSOUND(:,2,:) = u2

  uall = ndtooned(uSOUND)

  u = onedtond(uall,(/ 945,30 /))

  delete(u0)
  delete(u1)
  delete(u2)
  delete(uSOUND)
  delete(uall)

  u@long_name  = "W-E wind"
  u@units      = "cm s-1"
  u@_FillValue = 99999

  vSOUND = new((/ dimsizes(v0(:,0)),3,dimsizes(v0(0,:)) /),float,99999)

  vSOUND(:,0,:) = v0
  vSOUND(:,1,:) = v1
  vSOUND(:,2,:) = v2

  vall = ndtooned(vSOUND)

  v = onedtond(vall,(/ 945,30 /))

  delete(v0)
  delete(v1)
  delete(v2)
  delete(vSOUND)
  delete(vall)

  v@long_name  = "S-N wind"
  v@units      = "cm s-1"
  v@_FillValue = 99999

  wSOUND = new((/ dimsizes(w0(:,0)),3,dimsizes(w0(0,:)) /),float,999.9)

  wSOUND(:,0,:) = w0
  wSOUND(:,1,:) = w1
  wSOUND(:,2,:) = w2

  wall = ndtooned(wSOUND)

  w = onedtond(wall,(/ 945,30 /))

  delete(w0)
  delete(w1)
  delete(w2)
  delete(wSOUND)
  delete(wall)

  w@long_name  = "Vertical wind speed"
  w@units      = "cm s-1"
  w@_FillValue = 999.9

  NSOUND = new((/ dimsizes(N0(:,0)),3,dimsizes(N0(0,:)) /),float)

  NSOUND(:,0,:) = N0
  NSOUND(:,1,:) = N1
  NSOUND(:,2,:) = N2

  Nall = ndtooned(NSOUND)

  N = onedtond(NSOUND,(/ 945,30 /))

  delete(N0)
  delete(N1)
  delete(N2)
  delete(NSOUND)
  delete(Nall)

  N@long_name  = "Number of stations u, v, and w are averaged over"

  obs_geou    = new((/ dimsizes(ugeo_obs0)*3 /),float,99999)
  obs_geou(0) = ugeo_obs0(0)
  obs_geou(1) = ugeo_obs1(0)
  obs_geou(2) = ugeo_obs2(0)

  do i=3,(dimsizes(ugeo_obs0)*3)-1,3
    obs_geou(i) = ugeo_obs0(i/3)
  end do
  do i=4,(dimsizes(ugeo_obs0)*3)-1,3
    obs_geou(i) = ugeo_obs1(i/3)
  end do
  do i=5,(dimsizes(ugeo_obs0)*3)-1,3
    obs_geou(i) = ugeo_obs2(i/3)
  end do

  delete(ugeo_obs0)
  delete(ugeo_obs1)
  delete(ugeo_obs2)

  obs_geou@long_name  = "Gestrophic W-E wind from observations"
  obs_geou@units      = "cm s-1"
  obs_geou@_FillValue = 99999

  obs_geov    = new((/ dimsizes(vgeo_obs0)*3 /),float,99999)
  obs_geov(0) = vgeo_obs0(0)
  obs_geov(1) = vgeo_obs1(0)
  obs_geov(2) = vgeo_obs2(0)
  
  do i=3,(dimsizes(vgeo_obs0)*3)-1,3
    obs_geov(i) = vgeo_obs0(i/3)
  end do
  do i=4,(dimsizes(vgeo_obs0)*3)-1,3
    obs_geov(i) = vgeo_obs1(i/3)
  end do
  do i=5,(dimsizes(vgeo_obs0)*3)-1,3
    obs_geov(i) = vgeo_obs2(i/3)
  end do

  delete(vgeo_obs0)
  delete(vgeo_obs1)
  delete(vgeo_obs2)

  obs_geov@long_name  = "Gestrophic S-N wind from observations"
  obs_geov@units      = "cm s-1"
  obs_geov@_FillValue = 99999

  u_accel    = new((/ dimsizes(uaccel0)*3 /),float,999.999)
  u_accel(0) = uaccel0(0)
  u_accel(1) = uaccel1(0)
  u_accel(2) = uaccel2(0)

  do i=3,(dimsizes(uaccel0)*3)-1,3
    u_accel(i) = uaccel0(i/3)
  end do
  do i=4,(dimsizes(uaccel0)*3)-1,3
    u_accel(i) = uaccel1(i/3)
  end do
  do i=5,(dimsizes(uaccel0)*3)-1,3
    u_accel(i) = uaccel2(i/3)
  end do

  delete(uaccel0)
  delete(uaccel1)
  delete(uaccel2)

  u_accel@long_name  = "W-E acceleration at 500 m"
  u_accel@units      = "cm s-2"
  u_accel@_FillValue = 999.999

  v_accel    = new((/ dimsizes(vaccel0)*3 /),float,9999.996)
  v_accel(0) = vaccel0(0)
  v_accel(1) = vaccel1(0)
  v_accel(2) = vaccel2(0)

  do i=3,(dimsizes(vaccel0)*3)-1,3
    v_accel(i) = vaccel0(i/3)
  end do
  do i=4,(dimsizes(vaccel0)*3)-1,3
    v_accel(i) = vaccel1(i/3)
  end do
  do i=5,(dimsizes(vaccel0)*3)-1,3
    v_accel(i) = vaccel2(i/3)
  end do

  delete(vaccel0)
  delete(vaccel1)
  delete(vaccel2)

  v_accel@long_name  = "S-N acceleration at 500 m"
  v_accel@units      = "cm s-2"
  v_accel@_FillValue = 9999.996

; END ORGANIZING NEW ARRAYS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Define the dimensions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  TStringSplit = str_split_by_length(Time_strings,(/ 2,2 /))

  hour_fraction = tofloat(TStringSplit(:,1)) / 60.

  full_hour = tofloat(TStringSplit(:,0)) + hour_fraction

  Time = new((/ dimsizes(full_hour) /),float)
  do i=0,dimsizes(full_hour)-1,1
    Time(i) = full_hour(i) + (24 * (day(i) - 1))
  end do

  delete(TStringSplit)
  delete(hour_fraction)
  delete(full_hour)

  Time@long_name = "Time"
  Time@units     = "hours since 1967-07-14 14:00:00"
  Time!0         = "Time"

  SStringSplit = str_split_by_length(exact_sounding_time,(/ 2,2 /))

  hour_fraction = new((/ dimsizes(SStringSplit(:,0)) /),float)
  do i=0,dimsizes(SStringSplit(:,0))-1,1
    if (SStringSplit(i,1) .ne. "99") then
      hour_fraction(i) = tofloat(SStringSplit(i,1)) / 60.
    else
      hour_fraction(i) = tofloat(SStringSplit(i,1))
    end if
  end do

  full_hour = new((/ dimsizes(SStringSplit(:,0)) /),float)
  do i=0,dimsizes(SStringSplit(:,0))-1,1
    if (hour_fraction(i) .ne. 99.) then
      full_hour(i) = tofloat(SStringSplit(i,0)) + hour_fraction(i)
    else
      full_hour(i) = 9999.
    end if
  end do

  Time_3hr = new((/ dimsizes(full_hour) /),float,9999.)
  do i=0,dimsizes(full_hour)-1,1
    if (full_hour(i) .ne. 9999.) then
      Time_3hr(i) = full_hour(i) + (24 * (sounding_day(i) - 1))
    else
      Time_3hr(i) = full_hour(i)
    end if
  end do

  Time_3hr@long_name  = "Time of 3 hourly thermodynamic sounding"
  Time_3hr@units      = Time@units
  Time_3hr@_FillValue = 9999.
  Time_3hr!0          = "Time_3hr"

  delete(SStringSplit)
  delete(hour_fraction)
  delete(full_hour)

  height    = new((/ dimsizes(u(0,:)) /),float)
  height(0) = 50.
  do i=1,dimsizes(u(0,:))-1,1
    if (height(i-1) .lt. 1000.) then
      height(i) = height(i-1) + 50.
    else
      height(i) = height(i-1) + 100.
    end if
  end do

  height@long_name = "Height above ground level"
  height@units     = "m"
  height!0         = "height"

  height_3hr    = new((/ dimsizes(pres(0,:)) /),float)
  height_3hr(0) = 0.
  do i=1,dimsizes(pres(0,:))-1,1
    if (height_3hr(i-1) .lt. 1000.) then
      height_3hr(i) = height_3hr(i-1) + 50.
    else
      height_3hr(i) = height_3hr(i-1) + 100.
    end if
  end do

  height_3hr@long_name = height@long_name
  height_3hr@units     = height@units
  height_3hr!0         = "height_3hr"

; END Defining dimensions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Dimension each variable ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  nt  = dimsizes(Time)
  nt3 = dimsizes(Time_3hr)
  nz  = dimsizes(height)
  nz3 = dimsizes(height_3hr)

  day!0           = "Time"
  psurf!0         = "Time"
  dbulb!0         = "Time"
  wbulb!0         = "Time"
  weather!0       = "Time"
  wdir!0          = "Time"
  thermalu01!0    = "Time"
  thermalv01!0    = "Time"
  thermalu12!0    = "Time"
  thermalv12!0    = "Time"
  low_cloud!0     = "Time"
  tot_cloud!0     = "Time"
  low_cldtype!0   = "Time"
  mid_cldtype!0   = "Time"
  high_cldtype!0  = "Time"
  synoptic_geou!0 = "Time"
  synoptic_geov!0 = "Time"
  shf_mWcm2!0     = "Time"
  netrad_mWcm2!0  = "Time"
  ghf_mWcm2!0     = "Time"
  shf_Wm2!0       = "Time"
  netrad_Wm2!0    = "Time"
  friction_vel!0  = "Time"
  U0_5_Sta5!0     = "Time"
  U0_5_Sta4!0     = "Time"
  U1_Sta5!0       = "Time"
  U1_Sta4!0       = "Time"
  U2_Sta5!0       = "Time"
  U2_Sta4!0       = "Time"
  U4_Sta5!0       = "Time"
  U4_Sta4!0       = "Time"
  U8_Sta5!0       = "Time"
  U8_Sta4!0       = "Time"
  U16_Sta5!0      = "Time"
  U16_Sta4!0      = "Time"
  dT_dz_21!0      = "Time"
  dT_dz_42!0      = "Time"
  obs_geou!0      = "Time"
  obs_geov!0      = "Time"
  u_accel!0       = "Time"
  v_accel!0       = "Time"

  u!0 = "Time"
  u!1 = "height"
  v!0 = "Time"
  v!1 = "height"
  w!0 = "Time"
  w!1 = "height"
  N!0 = "Time"
  N!1 = "height"

  sounding_day!0 = "Time_3hr"

  pres!0 = "Time_3hr"
  pres!1 = "height_3hr"
  tair!0 = "Time_3hr"
  tair!1 = "height_3hr"
  rv!0   = "Time_3hr"
  rv!1   = "height_3hr"

  print("No fatal errors")

; END Data collection and organization ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Create and write a netCDF file with all of the organized data. Not all data
; can be used for the CCPP SCM, but all data are made available for anyone 
; interested in using the variables in concert with a different model. The new
; netCDF file will contain all variables in the Hicks/Clarke datasets, rather
; than a select few as are currently available in the Hicks netCDF data. ;;;;;;
  setfileoption("nc","FileStructure","Advanced")
  setfileoption("nc","Format","NetCDF4")
  fout = "Wangara2.nc"

  system("/bin/rm -f "+fout)
  fo = addfile(fout,"c")

  fAtt               = True
  fAtt@title         = "Complete Clarke/Hicks Wangara Dataset"
  fAtt@creation_date = systemfunc("date")

; Define the dimensions
  dimNames = (/ "Time","height","Time_3hr","height_3hr" /)
  dimSizes = (/  nt,    nz,      nt3,       nz3 /)
  dimUnlim = (/  True,  False,   True,      False /)

  filedimdef(fo,dimNames,dimSizes,dimUnlim)

  filevardef(fo,"Time",typeof(Time),"Time")
  filevarattdef(fo,"Time",Time)
  fo->Time = (/ Time /)

  filevardef(fo,"height",typeof(height),"height")
  filevarattdef(fo,"height",height)
  fo->height = (/ height /)

  filevardef(fo,"Time_3hr",typeof(Time_3hr),"Time_3hr")
  filevarattdef(fo,"Time_3hr",Time_3hr)
  fo->Time_3hr = (/ Time_3hr /)

  filevardef(fo,"height_3hr",typeof(height_3hr),"height_3hr")
  filevarattdef(fo,"height_3hr",height_3hr)
  fo->height_3hr = (/ height_3hr /)

; Define groups
  grpnames = (/ "Near_surface","Cloud","Thermal_wind","Geostrophic_wind", \
                "Acceleration","Sounding_thermodynamic","Sounding_dynamic" /)
  filegrpdef(fo,grpnames)

  g1 = fo=>/Near_surface
  g2 = fo=>/Cloud
  g3 = fo=>/Thermal_wind
  g4 = fo=>/Geostrophic_wind
  g5 = fo=>/Acceleration
  g6 = fo=>/Sounding_thermodynamic
  g7 = fo=>/Sounding_dynamic

; Group 1: Surface and near surface variables
  filedimdef(g1,dimNames(0),dimSizes(0),dimUnlim(0))

  filevardef(g1,"day",typeof(day),"Time")
  filevarattdef(g1,"day",day)
  g1->day = (/ day /)

  filevardef(g1,"psurf",typeof(psurf),"Time")
  filevarattdef(g1,"psurf",psurf)
  g1->psurf = (/ psurf /)

  filevardef(g1,"dbulb",typeof(dbulb),"Time")
  filevarattdef(g1,"dbulb",dbulb)
  g1->dbulb = (/ dbulb /)

  filevardef(g1,"wbulb",typeof(wbulb),"Time")
  filevarattdef(g1,"wbulb",wbulb)
  g1->wbulb = (/ wbulb /)

  filevardef(g1,"dT_dz_21",typeof(dT_dz_21),"Time")
  filevarattdef(g1,"dT_dz_21",dT_dz_21)
  g1->dT_dz_21 = (/ dT_dz_21 /)

  filevardef(g1,"dT_dz_42",typeof(dT_dz_42),"Time")
  filevarattdef(g1,"dT_dz_42",dT_dz_42)
  g1->dT_dz_42 = (/ dT_dz_42 /)

  filevardef(g1,"shf_mWcm2",typeof(shf_mWcm2),"Time")
  filevarattdef(g1,"shf_mWcm2",shf_mWcm2)
  g1->shf_mWcm2 = (/ shf_mWcm2 /)

  filevardef(g1,"shf_Wm2",typeof(shf_Wm2),"Time")
  filevarattdef(g1,"shf_Wm2",shf_Wm2)
  g1->shf_Wm2 = (/ shf_Wm2 /)

  filevardef(g1,"netrad_mWcm2",typeof(netrad_mWcm2),"Time")
  filevarattdef(g1,"netrad_mWcm2",netrad_mWcm2)
  g1->netrad_mWcm2 = (/ netrad_mWcm2 /)

  filevardef(g1,"netrad_Wm2",typeof(netrad_Wm2),"Time")
  filevarattdef(g1,"netrad_Wm2",netrad_Wm2)
  g1->netrad_Wm2 = (/ netrad_Wm2 /)

  filevardef(g1,"ghf_mWcm2",typeof(ghf_mWcm2),"Time")
  filevarattdef(g1,"ghf_mWcm2",ghf_mWcm2)
  g1->ghf_mWcm2 = (/ ghf_mWcm2 /)

  filevardef(g1,"wdir",typeof(wdir),"Time")
  filevarattdef(g1,"wdir",wdir)
  g1->wdir = (/ wdir /)

  filevardef(g1,"U0_5_Sta5",typeof(U0_5_Sta5),"Time")
  filevarattdef(g1,"U0_5_Sta5",U0_5_Sta5)
  g1->U0_5_Sta5 = (/ U0_5_Sta5 /)

  filevardef(g1,"U0_5_Sta4",typeof(U0_5_Sta4),"Time")
  filevarattdef(g1,"U0_5_Sta4",U0_5_Sta4)
  g1->U0_5_Sta4 = (/ U0_5_Sta4 /)

  filevardef(g1,"U1_Sta5",typeof(U1_Sta5),"Time")
  filevarattdef(g1,"U1_Sta5",U1_Sta5)
  g1->U1_Sta5 = (/ U1_Sta5 /)

  filevardef(g1,"U1_Sta4",typeof(U1_Sta4),"Time")
  filevarattdef(g1,"U1_Sta4",U1_Sta4)
  g1->U1_Sta4 = (/ U1_Sta4 /)

  filevardef(g1,"U2_Sta5",typeof(U2_Sta5),"Time")
  filevarattdef(g1,"U2_Sta5",U2_Sta5)
  g1->U2_Sta5 = (/ U2_Sta5 /)
  
  filevardef(g1,"U2_Sta4",typeof(U2_Sta4),"Time")
  filevarattdef(g1,"U2_Sta4",U2_Sta4)
  g1->U2_Sta4 = (/ U2_Sta4 /)

  filevardef(g1,"U4_Sta5",typeof(U4_Sta5),"Time")
  filevarattdef(g1,"U4_Sta5",U4_Sta5)
  g1->U4_Sta5 = (/ U4_Sta5 /)
  
  filevardef(g1,"U4_Sta4",typeof(U4_Sta4),"Time")
  filevarattdef(g1,"U4_Sta4",U4_Sta4)
  g1->U4_Sta4 = (/ U4_Sta4 /)

  filevardef(g1,"U8_Sta5",typeof(U8_Sta5),"Time")
  filevarattdef(g1,"U8_Sta5",U8_Sta5)
  g1->U8_Sta5 = (/ U8_Sta5 /)
  
  filevardef(g1,"U8_Sta4",typeof(U8_Sta4),"Time")
  filevarattdef(g1,"U8_Sta4",U8_Sta4)
  g1->U8_Sta4 = (/ U8_Sta4 /)

  filevardef(g1,"U16_Sta5",typeof(U16_Sta5),"Time")
  filevarattdef(g1,"U16_Sta5",U16_Sta5)
  g1->U16_Sta5 = (/ U16_Sta5 /)
  
  filevardef(g1,"U16_Sta4",typeof(U16_Sta4),"Time")
  filevarattdef(g1,"U16_Sta4",U16_Sta4)
  g1->U16_Sta4 = (/ U16_Sta4 /)

  filevardef(g1,"friction_vel",typeof(friction_vel),"Time")
  filevarattdef(g1,"friction_vel",friction_vel)
  g1->friction_vel = (/ friction_vel /)

; Group 2: Cloud related variables
  filedimdef(g2,dimNames(0),dimSizes(0),dimUnlim(0))

  filevardef(g2,"low_cloud",typeof(low_cloud),"Time")
  filevarattdef(g2,"low_cloud",low_cloud)
  g2->low_cloud = (/ low_cloud /)

  filevardef(g2,"tot_cloud",typeof(tot_cloud),"Time")
  filevarattdef(g2,"tot_cloud",tot_cloud)
  g2->tot_cloud = (/ tot_cloud /)

  filevardef(g2,"low_cldtype",typeof(low_cldtype),"Time")
  filevarattdef(g2,"low_cldtype",low_cldtype)
  g2->low_cldtype = (/ low_cldtype /)

  filevardef(g2,"mid_cldtype",typeof(mid_cldtype),"Time")
  filevarattdef(g2,"mid_cldtype",mid_cldtype)
  g2->mid_cldtype = (/ mid_cldtype /)

  filevardef(g2,"high_cldtype",typeof(high_cldtype),"Time")
  filevarattdef(g2,"high_cldtype",high_cldtype)
  g2->high_cldtype = (/ high_cldtype /)

; Group 3: Thermal winds
  filedimdef(g3,dimNames(0),dimSizes(0),dimUnlim(0))

  filevardef(g3,"thermalu01",typeof(thermalu01),"Time")
  filevarattdef(g3,"thermalu01",thermalu01)
  g3->thermalu01 = (/ thermalu01 /)

  filevardef(g3,"thermalv01",typeof(thermalv01),"Time")
  filevarattdef(g3,"thermalv01",thermalv01)
  g3->thermalv01 = (/ thermalv01 /)

  filevardef(g3,"thermalu12",typeof(thermalu12),"Time")
  filevarattdef(g3,"thermalu12",thermalu12)
  g3->thermalu12 = (/ thermalu12 /)

  filevardef(g3,"thermalv12",typeof(thermalv12),"Time")
  filevarattdef(g3,"thermalv12",thermalv12)
  g3->thermalv12 = (/ thermalv12 /)

; Group 4: Synoptic geostrophic winds and geostrophic winds from observations
  filedimdef(g4,dimNames(0),dimSizes(0),dimUnlim(0))

  filevardef(g4,"synoptic_geou",typeof(synoptic_geou),"Time")
  filevarattdef(g4,"synoptic_geou",synoptic_geou)
  g4->synoptic_geou = (/ synoptic_geou /)

  filevardef(g4,"synoptic_geov",typeof(synoptic_geov),"Time")
  filevarattdef(g4,"synoptic_geov",synoptic_geov)
  g4->synoptic_geov = (/ synoptic_geov /)

  filevardef(g4,"obs_geou",typeof(obs_geou),"Time")
  filevarattdef(g4,"obs_geou",obs_geou)
  g4->obs_geou = (/ obs_geou /)

  filevardef(g4,"obs_geov",typeof(obs_geov),"Time")
  filevarattdef(g4,"obs_geov",obs_geov)
  g4->obs_geov = (/ obs_geov /)

; Group 5: Acceleration at 500 m
  filedimdef(g5,dimNames(0),dimSizes(0),dimUnlim(0))

  filevardef(g5,"u_accel",typeof(u_accel),"Time")
  filevarattdef(g5,"u_accel",u_accel)
  g5->u_accel = (/ u_accel /)

  filevardef(g5,"v_accel",typeof(v_accel),"Time")
  filevarattdef(g5,"v_accel",v_accel)
  g5->v_accel = (/ v_accel /)

; Group 6: 3 hourly sounding with thermodynamic variables
  filedimdef(g6,dimNames(2:3),dimSizes(2:3),dimUnlim(2:3))

  filevardef(g6,"pres",typeof(pres),(/ "Time_3hr","height_3hr" /))
  filevarattdef(g6,"pres",pres)
  g6->pres = (/ pres /)

  filevardef(g6,"tair",typeof(tair),(/ "Time_3hr","height_3hr" /))
  filevarattdef(g6,"tair",tair)
  g6->tair = (/ tair /)

  filevardef(g6,"rv",typeof(rv),(/ "Time_3hr","height_3hr" /))
  filevarattdef(g6,"rv",rv)
  g6->rv = (/ rv /)

  filevardef(g6,"sounding_day",typeof(sounding_day),"Time_3hr")
  filevarattdef(g6,"sounding_day",sounding_day)
  g6->sounding_day = (/ sounding_day /)

; Group 7: Hourly dynamic soundings
  filedimdef(g7,dimNames(0:1),dimSizes(0:1),dimUnlim(0:1))

  filevardef(g7,"u",typeof(u),(/ "Time","height" /))
  filevarattdef(g7,"u",u)
  g7->u = (/ u /)

  filevardef(g7,"v",typeof(v),(/ "Time","height" /))
  filevarattdef(g7,"v",v)
  g7->v = (/ v /)

  filevardef(g7,"w",typeof(w),(/ "Time","height" /))
  filevarattdef(g7,"w",w)
  g7->w = (/ w /)

  filevardef(g7,"N",typeof(N),(/ "Time","height" /))
  filevarattdef(g7,"N",N)
  g7->N = (/ N /)

  print("No fatal errors "+systemfunc("date"))
  print("Wrote "+fout)

end

