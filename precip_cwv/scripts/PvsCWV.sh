#!/bin/csh
# c-shell script to calculate relationship between precipitation and Column water vapor (CWV)
# !!!!!! What should be modified !!!!!!
# MMM  : model name
# HHH  : home directory
# XXX  : number of grid in longitude
# YYY  : number of grid in latitude
# SZZ  : number of selected vertical levels for output
# LSZZ : list of selected vertical levels (use grib_dump to check) 
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
# VPR  : shortname of precipitation in GRIB file
# VPW  : shortname of CWV in GRIB file
# VLS  : shortname of landmask in GRIB file
# NBIN : number of bins to stratify CWV
# CWV0 : minimum value of CWV
# CWV1 : maximum value of CWV
# NBINP: number of bins to stratify precip
# PR0  : minimum value of precip
# PR1  : maximum value of precip
# Contact: Weiwei Li (weiweili@ucar.edu)

# !!!!!! What should be modified !!!!!!
 setenv HHH $yourdir

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
 setenv SZZ 1
 setenv LSZZ '0'
 setenv FFF 9 # determined by the number of LFF
 setenv LFF '000,024,048,072,096,120,144,168,216'
 setenv VPR 'tp' # shortname of precip
 setenv VPW 'pwat' # shortname of CWV
 setenv VLS 'lsm' # shortname of land mask
 setenv NBIN 61
 setenv CWV0 10
 setenv CWV1 70
 setenv NBINP 8
 setenv PR0 0
 setenv PR1 210
 setenv SCWV0 10
 setenv SCWV1 65

 cp -f src/pvscwv.f90.sample .
 ln -s src/grib_api_decode.f .
 ln -s src/ngrd.f

 sed "s#homedir#$HHH#g"   pvscwv.f90.sample > tmp1
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
 sed "s/num_selz/$SZZ/g"               tmp1 > tmp2
 sed "s/sellevs/$LSZZ/g"               tmp2 > tmp1
 sed "s/num_fcst/$FFF/g"               tmp1 > tmp2
 sed "s/selfcst/$LFF/g"                tmp2 > tmp1
 sed "s/vnamep/$VPR/g"                 tmp1 > tmp2
 sed "s/vnamecwv/$VPW/g"               tmp2 > tmp1
 sed "s/vnamelmsk/$VLS/g"              tmp1 > tmp2
 sed "s/nbb/$NBIN/g"                   tmp2 > tmp1
 sed "s/cwv0/$CWV0/g"                  tmp1 > tmp2
 sed "s/cwv1/$CWV1/g"                  tmp2 > tmp1
 sed "s/npp/$NBINP/g"                  tmp1 > tmp2
 sed "s/precip0/$PR0/g"                tmp2 > tmp1
 sed "s/precip1/$PR1/g"                tmp1 > pvscwv.f90





 # if array is large, add -mcmodel=medium or =large
 #ifort pvscwv.f90 -I$GRIB_API/include -L$GRIB_API/lib -lgrib_api_f90 
 #./a.out

 rm -f pvscwv.f90.sample
 rm -f a.out
 rm -f tmp1
 rm -f tmp2


# Step 2: generate description file
 cp src/pvscwv_ctl.csh.sample .

 sed "s/vnamep/$VPR/g"     pvscwv_ctl.csh.sample > tmp1
 sed "s/vnamecwv/$VPW/g"                    tmp1 > tmp2
 sed "s/nbb/$NBIN/g"                        tmp2 > tmp1
 sed "s/npp/$NBINP/g"                       tmp1 > pvscwv_ctl.csh

 chmod 754 pvscwv_ctl.csh
 ./pvscwv_ctl.csh

 rm -f pvscwv_ctl.csh.sample
 rm -f tmp1
 rm -f tmp2


# Step 3: make plot using GrADS
 cp src/plot.pvscwv.gs.sample .
 sed "s#homedir#$HHH#g"   plot.pvscwv.gs.sample > tmp1
 sed "s/modelnm/$MMM/g"                    tmp1 > tmp2
 sed "s/vnamep/$VPR/g"                     tmp2 > tmp1
 sed "s/vnamecwv/$VPW/g"                   tmp1 > tmp2
 sed "s/cwv0/$CWV0/g"                      tmp2 > tmp1
 sed "s/cwv1/$CWV1/g"                      tmp1 > plot.pvscwv.gs

grads -pbc << EOF
plot.pvscwv.gs
EOF

rm -f plot.pvscwv.gs.sample
rm -f tmp1
rm -f tmp2




 

