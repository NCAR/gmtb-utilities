#!/bin/csh
# c-shell script to calculate heat source Q1 and moisture sink Q2 (Yanai et al. 1973)
# !!!!!! What should be modified !!!!!!
# HHH  : home directory
# XXX  : number of grid in longitude
# YYY  : number of grid in latitude
# SZZ : number of selected vertical levels
# LSZZ: list of selected vertical levels (use grib_dump to check) 
# TTT  : number of total time (in day) within a season of a calendar year
# DDD  : time interval in second for calculating dx/dt 
# LAT0 : southernmost latitude
# LON0 : westernmost longitude
# GRDX : resolution in x-direction
# GRDY : resolution in y-direction
# FFF  : number of selected forecast lead times 
# LFF  : list of selected forecast lead times
# BYY  : first year 
# EYY  : last year 
# BMM  : first month
# EMM  : last month
# Contact: Weiwei Li (weiweili@ucar.edu)

# !!!!!! What should be modified !!!!!!
 setenv HHH /glade/u/home/weiweili/my_work/GMTB/diag/rhq1vscwv/Q1Q2

 setenv XXX 360
 setenv YYY 181
 setenv BYY 2017
 setenv EYY 2017
 setenv BMM 6
 setenv EMM 8
 setenv LAT0 -90.0
 setenv LON0 0.0
 setenv GRDX 1.0
 setenv GRDY 1.0
 setenv SZZ 19
 setenv LSZZ '1000, 975, 950, 925, 900, 850, 800, 750, 700, 650, 600, 550, 500, 450, 400, 350, 300, 250, 200'
 setenv FFF 9 # determined by the number of LFF
 setenv LFF '000,024,048,072,096,120,144,168,216'
 setenv TTT 92
 setenv DDD 86400


 cd $HHH
 mkdir output

 cp -f src/cal_q1q2_fv3gfs.f90.sample .
 ln -s src/grib_api_decode.f .
 ln -s src/q1q2_cal_fcst.f . 
 ln -s src/rhum2shum.f .

 sed "s#homedir#$HHH#g"   cal_q1q2_fv3gfs.f90.sample > tmp1
 sed "s/beg_y/$BYY/g"                           tmp1 > tmp2
 sed "s/end_y/$EYY/g"                           tmp2 > tmp1
 sed "s/beg_m/$BMM/g"                           tmp1 > tmp2
 sed "s/end_m/$EMM/g"                           tmp2 > tmp1
 sed "s/num_x/$XXX/g"                           tmp1 > tmp2
 sed "s/num_y/$YYY/g"                           tmp2 > tmp1
 sed "s/num_t/$TTT/g"                           tmp1 > tmp2
 sed "s/xx0/$LON0/g"                            tmp2 > tmp1
 sed "s/yy0/$LAT0/g"                            tmp1 > tmp2
 sed "s/ddd/$DDD/g"                             tmp2 > tmp1
 sed "s/grdd_x/$GRDX/g"                         tmp1 > tmp2
 sed "s/grdd_y/$GRDY/g"                         tmp2 > tmp1
 sed "s/num_selz/$SZZ/g"                        tmp1 > tmp2
 sed "s/sellevs/$LSZZ/g"                        tmp2 > tmp1
 sed "s/num_fcst/$FFF/g"                        tmp1 > tmp2
 sed "s/selfcst/$LFF/g"                         tmp2 > cal_q1q2_fv3gfs.f90 


 # if array is large, add -mcmodel=medium or =large
 ifort cal_q1q2_fv3gfs.f90 -I$GRIB_API/include -L$GRIB_API/lib -lgrib_api_f90 
 ./a.out

 rm -f cal_q1q2_fv3gfs.f90.sample
 rm -f a.out
 rm -f tmp1
 rm -f tmp2

