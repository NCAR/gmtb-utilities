#!/bin/csh
# c-shell script to calculate relationship between precipitation and CWV
# !!!!!! What should be modified !!!!!!
# HHH  : home directory
# VVV  : shortname of selected variable (use grib_dump to check)
# XXX  : number of grid in longitude
# YYY  : number of grid in latitude
# SZZ  : number of selected vertical levels for output
# LSZZ : list of selected vertical levels (use grib_dump to check) 
# TTT  : number of total time (in day)
# FFF  : number of selected forecast lead times 
# LFF  : list of selected forecast lead times
# BYY  : first year 
# EYY  : last year 
# BMM  : first month
# EMM  : last month
# MMM  : missing value
# Contact: Weiwei Li (weiweili@ucar.edu)

# !!!!!! What should be modified !!!!!!
 setenv HHH /glade/u/home/weiweili/my_work/GMTB/diag/APCPvsPW/4git

 foreach VVV ( tp ) # grib_dump to check the shortname of a variable 

 setenv MMM 'FV3GFS'
 setenv VPR 'tp' # shortname of precip
 setenv VPW 'pwat' # shortname of CWV
 setenv VLS 'lsm' # shortname of land mask
 setenv XXX 360
 setenv YYY 181
 setenv LATb -20
 setenv LATe 20
 setenv LONb 0
 setenv LONe 359
 setenv LAT0 -90.0
 setenv LON0 0.0
 setenv GRD 1.0
 setenv SZZ 1
 setenv LSZZ '0'
 setenv TTT 83 # precip data only availabe from Jun 10
 setenv FFF 8
 setenv LFF '024,048,072,096,120,144,168,216'
 setenv BYY 2017
 setenv EYY 2017
 setenv BMM 6
 setenv EMM 8
 setenv NBIN 61
 setenv CWV0 10
 setenv CWV1 70

 ln -s src/ngrd.f
 cp -f src/TPvsCWV_fv3gfs.f90.sample .

 sed "s#homedir#$HHH#g"   TPvsCWV_fv3gfs.f90.sample > tmp1
 sed "s/beg_y/$BYY/g"                          tmp2 > tmp1
 sed "s/end_y/$EYY/g"                          tmp1 > tmp2
 sed "s/variable/$var/g"                       tmp2 > tmp1
 sed "s/num_x/$XXX/g"                          tmp1 > tmp2
 sed "s/num_y/$YYY/g"                          tmp2 > tmp1
 sed "s/xx0/$LON0/g"                           tmp1 > tmp2
 sed "s/yy0/$LAT0/g"                           tmp2 > tmp1
 sed "s/grdd/$GRD/g"                           tmp1 > tmp2
 sed "s/YY1/$LATb/g"                           tmp2 > tmp1
 sed "s/YY2/$LATe/g"                           tmp1 > tmp2
 sed "s/XX1/$LONb/g"                           tmp2 > tmp1
 sed "s/XX2/$LONe/g"                           tmp1 > tmp2
 sed "s/tmax/$TTT/g"                           tmp2 > tmp1
 sed "s/nbb/$NBIN/g"                           tmp1 > tmp2
 sed "s/cwv0/$CWV0/g"                          tmp2 > tmp1
 sed "s/cwv1/$CWV1/g"                          tmp1 > tmp2
 sed "s/ld0/$LEAD0/g"                          tmp2 > tmp1
 sed "s/ld1/$LEAD1/g"                          tmp1 > tmp2
 sed "s/ild/$ILEAD/g"                          tmp2 > tmp1
 sed "s/amiss/$MMM/g"                          tmp1 > tmp2
 sed "s/variable/$var/g"                       tmp2 > tmp1
 sed "s/fcstnm/$FCST/g"                        tmp1 > cal.$var.fcst.f90






# calculate Precip vs CWV
 sed "s#homedir#$HHH#g"  TPvsCWV_fv3gfs.f90.sample > tmp1
 sed "s/vnamep/$VVV/g"                      tmp1 > tmp2
 sed "vnamepw/$VPW/g"
 sed "vnamelmsk/$VLS/g"
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

 rm -f a.out
 rm -f tmp1
 rm -f tmp2




# Step 2: calculate Precip vs CWV
 sed "s#homedir#$HHH#g"   TPvsCWV_fv3gfs.f90.sample > tmp1
 sed "s/vnamep/$VVV/g"                       tmp1 > tmp2
 sed "vnamepw/$VPW/g"
 sed "vnamelmsk/$VLS/g"
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














# cd $HHH/data/$var
#
# sed "s/daily/daily.clim/g" daily.$PPP.ctl > daily.clim.$PPP.ctl
# sed "s/daily/daily.anom/g" daily.$PPP.ctl > daily.anom.$PPP.ctl
 
 end

