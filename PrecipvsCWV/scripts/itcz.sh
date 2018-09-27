#!/bin/csh
# c-shell script to diagnose precipitation in forecasts
# !!!!!! What should be modified !!!!!!
# HHH  : home directory
# MMM  : model name
# VVV  : shortname of selected variable (use grib_dump to check)
# XXX  : number of grid in longitude
# YYY  : number of grid in latitude
# XX0  : first longitude in degree
# YY0  : first latitude in degree
# DDX  : x-direction resolution in degree
# DDY  : y-direction resolution in degree
# SZZ  : number of selected vertical levels for output
# LSZZ : list of selected vertical levels (use grib_dump to check) 
# TTT  : number of total time (in day)
# FFF  : number of selected forecast lead times 
# LFF  : list of selected forecast lead times
# BYY  : first year 
# EYY  : last year 
# BMM  : first month
# EMM  : last month
# Contact: Weiwei Li (weiweili@ucar.edu)

# !!!!!! What should be modified !!!!!!
 setenv HHH /glade/u/home/weiweili/my_work/GMTB/diag/APCPvsPW/4git

 foreach VVV ( tp ) # grib_dump to check the shortname of a variable 

 setenv MMM 'FV3GFS'
 setenv XXX 360
 setenv YYY 181
 setenv XX0 0
 setenv YY0 -90
 setenv DDX 1.0
 setenv DDY 1.0
 setenv SZZ 1
 setenv LSZZ '0'
 setenv TTT 92
 setenv FFF 8
 setenv LFF '024,048,072,096,120,144,168,216'
 setenv BYY 2017
 setenv EYY 2017
 setenv BMM 6
 setenv EMM 8

# Step 1: output into binary for GrADS
 cp src/read_fv3gfs.f90.sample .
 ln -s src/grib_api_decode.f .

 sed "s#homedir#$HHH#g"   read_fv3gfs.f90.sample > tmp1
 sed "s/vname/$VVV/g"                       tmp1 > tmp2
 sed "s/num_x/$XXX/g"                       tmp2 > tmp1
 sed "s/num_y/$YYY/g"                       tmp1 > tmp2 
 sed "s/num_t/$TTT/g"                       tmp2 > tmp1
 sed "s/num_selz/$SZZ/g"                    tmp1 > tmp2
 sed "s/sellevs/$LSZZ/g"                    tmp2 > tmp1 
 sed "s/num_fcst/$FFF/g"                    tmp1 > tmp2
 sed "s/selfcst/$LFF/g"                     tmp2 > tmp1
 sed "s/beg_y/$BYY/g"                       tmp1 > tmp2 
 sed "s/end_y/$EYY/g"                       tmp2 > tmp1 
 sed "s/beg_m/$BMM/g"                       tmp1 > tmp2
 sed "s/end_m/$EMM/g"                       tmp2 > read_fv3gfs.f90

 # if array is large, add -mcmodel=medium or =large
 ifort read_fv3gfs.f90 -I$GRIB_API/include -L$GRIB_API/lib -lgrib_api_f90 
 ./a.out
 rm -f read_fv3gfs.f90.sample
 rm -f a.out
 rm -f tmp1
 rm -f tmp2

# Step 2: generate description file
 cp src/itcz_ctl.csh.sample .

 sed "s/vname/$VVV/g"        itcz_ctl.csh.sample > tmp2
 sed "s/num_x/$XXX/g"                       tmp2 > tmp1
 sed "s/num_y/$YYY/g"                       tmp1 > tmp2
 sed "s/num_t/$TTT/g"                       tmp2 > tmp1
 sed "s/beg_x/$XX0/g"                       tmp1 > tmp2
 sed "s/beg_y/$YY0/g"                       tmp2 > tmp1
 sed "s/delt_x/$DDX/g"                      tmp1 > tmp2
 sed "s/delt_y/$DDY/g"                      tmp2 > itcz_ctl.csh

 chmod 754 itcz_ctl.csh
 ./itcz_ctl.csh

 rm -f itcz_ctl.csh.sample
 rm -f tmp1
 rm -f tmp2


# Step 3: make plot using GrADS
 cp src/plot.itcz.gs.sample .
 sed "s#homedir#$HHH#g"   plot.itcz.gs.sample > tmp1
 sed "s/modelnm/$MMM/g"                  tmp1 > tmp2
 sed "s/vname/$VVV/g"                    tmp2 > plot.itcz.gs

grads -pbc << EOF
plot.itcz.gs
EOF

rm -f plot.itcz.gs.sample
rm -f tmp1
rm -f tmp2

 
end

