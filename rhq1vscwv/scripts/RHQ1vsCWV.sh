#!/bin/csh
# c-shell script to calculate relationship b/t RH or Q1 with Column water vapor (CWV)
# !!!!!! What should be modified !!!!!!
# MMM  : model name
# HHH  : home directory
# VAR  : variables to analyze, e.g. RH and Q1
# XXX  : number of grid in longitude
# YYY  : number of grid in latitude
# SZZ1 : number of selected vertical levels for RH or Q1
# LSZZ1: list of selected vertical levels for RH or Q1 (use grib_dump to check) 
# SZZ2 : number of selected vertical levels for CWV
# LSZZ2: list of selected vertical levels for CWV (grib_dump to check) 
# TTT  : number of total time (in day)
# NBB  : number of basins or regions examined
# LATb : southern bound of latitude of studied domain
# LATe : northern bound of latitude of studied domain
# LONb : western bound of latitude of studied domain
# LONe : eastern bound of latitude of studied domain
# LAT0 : southernmost latitude
# LON0 : westernmost longitude
# GRD  : resolution
# FFF  : number of selected forecast lead times 
# LFF  : list of selected forecast lead times
# BYY  : first year 
# EYY  : last year 
# BMM  : first month
# EMM  : last month
# VRH  : shortname of precipitation in GRIB file
# VPW  : shortname of CWV in GRIB file
# VLS  : shortname of landmask in GRIB file
# NBIN : number of bins to stratify CWV
# CWV0 : minimum value of CWV
# CWV1 : maximum value of CWV
# Contact: Weiwei Li (weiweili@ucar.edu)

# !!!!!! What should be modified !!!!!!
 setenv HHH /glade/u/home/weiweili/my_work/GMTB/diag/rhq1vscwv

 setenv MMM 'FV3GFS'
 setenv XXX 360
 setenv YYY 181
 setenv BYY 2017
 setenv EYY 2017
 setenv BMM 6
 setenv EMM 8
 setenv NBB 1
 setenv LATb '-20'
 setenv LATe '20'
 setenv LONb '0'
 setenv LONe '359'
 setenv LAT0 -90.0
 setenv LON0 0.0
 setenv GRD 1.0
 setenv SZZ1 19
 setenv LSZZ1 '1000, 975, 950, 925, 900, 850, 800, 750, 700, 650, 600, 550, 500, 450, 400, 350, 300, 250, 200'
 setenv SZZ2 1
 setenv LSZZ2 '0'
 setenv FFF 9 # determined by the number of LFF
 setenv LFF '000,024,048,072,096,120,144,168,216'
 setenv VQ1 'Q1'
 setenv VRH 'r' # shortname of RH
 setenv VPW 'pwat' # shortname of CWV
 setenv VLS 'lsm' # shortname of land mask
 setenv NBIN 61
 setenv CWV0 10
 setenv CWV1 70

 foreach VAR (RH Q1)

 cp -f src/rhq1vscwv.f90.sample .
 ln -s src/grib_api_decode.f .
 ln -s src/ngrd.f

 sed "s#homedir#$HHH#g"   rhq1vscwv.f90.sample > tmp1
 sed "s/beg_y/$BYY/g"                  tmp1 > tmp2
 sed "s/end_y/$EYY/g"                  tmp2 > tmp1
 sed "s/beg_m/$BMM/g"                  tmp1 > tmp2
 sed "s/end_m/$EMM/g"                  tmp2 > tmp1
 sed "s/num_x/$XXX/g"                  tmp1 > tmp2
 sed "s/num_y/$YYY/g"                  tmp2 > tmp1
 sed "s/num_bs/$NBB/g"                 tmp1 > tmp2
 sed "s/xx0/$LON0/g"                   tmp2 > tmp1
 sed "s/yy0/$LAT0/g"                   tmp1 > tmp2
 sed "s/grdd/$GRD/g"                   tmp2 > tmp1
 sed "s/YY1/$LATb/g"                   tmp1 > tmp2
 sed "s/YY2/$LATe/g"                   tmp2 > tmp1
 sed "s/XX1/$LONb/g"                   tmp1 > tmp2
 sed "s/XX2/$LONe/g"                   tmp2 > tmp1
 sed "s/num_selz1/$SZZ1/g"             tmp1 > tmp2
 sed "s/sellevs1/$LSZZ1/g"             tmp2 > tmp1
 sed "s/num_selz2/$SZZ2/g"             tmp1 > tmp2
 sed "s/sellevs2/$LSZZ2/g"             tmp2 > tmp1
 sed "s/num_fcst/$FFF/g"               tmp1 > tmp2
 sed "s/selfcst/$LFF/g"                tmp2 > tmp1
 if($VAR == 'RH')then
    sed "s/vnameinput/$VRH/g"          tmp1 > tmp2
 else if($VAR == 'Q1')then
    sed "s/vnameinput/$VQ1/g"          tmp1 > tmp2
 endif
 sed "s/vnamecwv/$VPW/g"               tmp2 > tmp1
 sed "s/vnamelmsk/$VLS/g"              tmp1 > tmp2
 sed "s/nbb/$NBIN/g"                   tmp2 > tmp1
 sed "s/cwv0/$CWV0/g"                  tmp1 > tmp2
 sed "s/cwv1/$CWV1/g"                  tmp2 > rhq1vscwv.f90





 # if array is large, add -mcmodel=medium or =large
 #ifort rhq1vscwv.f90 -I$GRIB_API/include -L$GRIB_API/lib -lgrib_api_f90 
 #./a.out

 rm -f rhq1vscwv.f90.sample
 rm -f a.out
 rm -f tmp1
 rm -f tmp2


# Step 2: generate description file
 cp src/rhq1vscwv_ctl.csh.sample .

 if($VAR == 'RH')then
    sed "s/vnameinput/$VRH/g"     rhq1vscwv_ctl.csh.sample > tmp1
 else if($VAR == 'Q1')then
    sed "s/vnameinput/$VQ1/g"     rhq1vscwv_ctl.csh.sample > tmp1
 endif
 sed "s/vnamecwv/$VPW/g"                              tmp1 > tmp2
 sed "s/nbb/$NBIN/g"                                  tmp2 > tmp1
 sed "s/num_selz1/$SZZ1/g"                            tmp1 > rhq1vscwv_ctl.csh

 chmod 754 rhq1vscwv_ctl.csh
 ./rhq1vscwv_ctl.csh

 rm -f rhq1vscwv_ctl.csh.sample
 rm -f tmp1
 rm -f tmp2


# Step 3: make plot using GrADS
 cp src/plot.rhq1vscwv.gs.sample .
 sed "s#homedir#$HHH#g" plot.rhq1vscwv.gs.sample > tmp1
 sed "s/modelnm/$MMM/g"                     tmp1 > tmp2
 if($VAR == 'RH')then
    sed "s/vnameinput/$VRH/g"               tmp2 > tmp1
 else if($VAR == 'Q1')then
    sed "s/vnameinput/$VQ1/g"               tmp2 > tmp1
 endif
 sed "s/vnamerh/$VRH/g"                     tmp1 > tmp2
 sed "s/vnameq1/$VQ1/g"                     tmp2 > tmp1
 sed "s/vnamecwv/$VPW/g"                    tmp1 > tmp2
 sed "s/cwv0/$CWV0/g"                       tmp2 > tmp1
 sed "s/cwv1/$CWV1/g"                       tmp1 > plot.rhq1vscwv.gs

grads -pb << EOF
plot.rhq1vscwv.gs
EOF

rm -f plot.rhq1vscwv.gs.sample
rm -f tmp1
rm -f tmp2

end


 

