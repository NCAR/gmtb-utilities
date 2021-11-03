;*************************************************
; zonal_lwp_iwp.ncl
; This script calculates the zonal averages of liquid water path and ice water path
; from CERES dataset and multiple GFS global run outputs. Modify as needed.
; Xia Sun, xia.sun@noaa.gov, 2020-2021
; WARNING: Dummy codes to read in cloud properties at different pressure levels using UPP output
;************************************************
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
; load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
;************************************************
begin

   
model="GFS"                        ; experiment name using GFS model  
year="2020"  
month="01"
ldy="05"                           ; leading day 
expname=str_upper(model)+"v16beta" ; need to change to your experiment name

setvalues NhlGetWorkspaceObjectId()
    "wsMaximumSize" : 300000000
end setvalues

; CERES data directory
obsdir="/dir/to/your/CERES/"        ;need to change to your CERES data dir

;******Read in Model Output from Different Model Scenarios******
 fName5= "DIRdate_DY05.txt"
 dir="/dir/to/model/run/one"
 dir1="/dir/to/model/run/two"
 dir2="/dir/to/model/run/three"
 dir3="/dir/to/model/run/four"
 dir4="/dir/to/model/run/five"
   
 date5= systemfunc("cut -c1-10 "+ fName5)
 realdate5=systemfunc("cut -c1-8 "+ fName5)
 init5=systemfunc("cut -c9-10 "+ fName5)
 print(realdate5)
 print(init5)
 
 ; fName10= "DIRdate_DY10.txt"                        ; I am only ploting day 5 forecast here.
 ; date10= systemfunc("cut -c1-10 "+ fName10)
 ; realdate10=systemfunc("cut -c1-8 "+ fName10)
 ; init10=systemfunc("cut -c9-10 "+ fName10)

 i=0
 dirs5=" "
 dirs51 =" "
 dirs52=" "
 dirs53=" "
 dirs54=" "
 ; dirs10=" "
 do while (i.le.6)
  dirs5= dirs5 + dir+"/gfs."+realdate5(i)+init5(i)+"/ "
  dirs51= dirs51 + dir1+"/gfs."+realdate5(i)+init5(i)+"/ "
  dirs52= dirs52 + dir2+"/gfs."+realdate5(i)+init5(i)+"/ "
  dirs53= dirs53 + dir3+"/gfs."+realdate5(i)+init5(i)+"/ "
  dirs54= dirs54 + dir4+"/gfs."+realdate5(i)+init5(i)+"/ "
  ; dirs10= dirs10 + dir+"/gfs."+realdate10(i)+init10(i)+"/ "
  i=i+1
 end do
 
 seltime5 = " -type f \( -name gfs.t00z.pgrb2.0p25.f102_cloudsubsetallfive_1deg.nc -o -name gfs.t00z.pgrb2.0p25.f108_cloudsubsetallfive_1deg.nc -o -name gfs.t00z.pgrb2.0p25.f114_cloudsubsetallfive_1deg.nc -o -name gfs.t00z.pgrb2.0p25.f120_cloudsubsetallfive_1deg.nc -o -name gfs.t12z.pgrb2.0p25.f102_cloudsubsetallfive_1deg.nc -o -name gfs.t12z.pgrb2.0p25.f108_cloudsubsetallfive_1deg.nc -o -name gfs.t12z.pgrb2.0p25.f114_cloudsubsetallfive_1deg.nc -o -name gfs.t12z.pgrb2.0p25.f120_cloudsubsetallfive_1deg.nc \)  "
; seltime10 = " -type f \( -name gfs.t00z.pgrb2.0p25.f222_cloudsubsetallfive_1deg.nc -o -name gfs.t00z.pgrb2.0p25.f228_cloudsubsetallfive_1deg.nc -o -name gfs.t00z.pgrb2.0p25.f234_cloudsubsetallfive_1deg.nc -o -name gfs.t00z.pgrb2.0p25.f240_cloudsubsetallfive_1deg.nc -o -name gfs.t12z.pgrb2.0p25.f222_cloudsubsetallfive_1deg.nc -o -name gfs.t12z.pgrb2.0p25.f228_cloudsubsetallfive_1deg.nc -o -name gfs.t12z.pgrb2.0p25.f234_cloudsubsetallfive_1deg.nc -o -name gfs.t12z.pgrb2.0p25.f240_cloudsubsetallfive_1deg.nc \)  "
cmd="find " + dirs5 + seltime5 


fili= systemfunc(cmd)
nfili=dimsizes(fili)

cmd51="find " + dirs51 + seltime5 
fili51=systemfunc(cmd51)
f51=addfiles(fili51,"r")

cmd52="find " + dirs52 + seltime5 
fili52=systemfunc(cmd52)
f52=addfiles(fili52,"r")

cmd53="find " + dirs53 + seltime5 
fili53=systemfunc(cmd53)
f53=addfiles(fili53,"r")

cmd54="find " + dirs54 + seltime5 
fili54=systemfunc(cmd54)
f54=addfiles(fili54,"r")

f    = addfiles(fili,"r") 
print(f)

;*************** Start of Code Block to Read in Water Mixing Ratios **********************************
clmr50=f[:]->CLMR_50mb
icmr50=f[:]->ICMR_50mb
clmr100=f[:]->CLMR_100mb
icmr100=f[:]->ICMR_100mb
clmr150=f[:]->CLMR_150mb
icmr150=f[:]->ICMR_150mb
clmr200=f[:]->CLMR_200mb
icmr200=f[:]->ICMR_200mb
clmr250=f[:]->CLMR_250mb
icmr250=f[:]->ICMR_250mb
clmr300=f[:]->CLMR_300mb
icmr300=f[:]->ICMR_300mb
clmr350=f[:]->CLMR_350mb
icmr350=f[:]->ICMR_350mb
clmr400=f[:]->CLMR_400mb
icmr400=f[:]->ICMR_400mb
clmr450=f[:]->CLMR_450mb
icmr450=f[:]->ICMR_450mb
clmr500=f[:]->CLMR_500mb
icmr500=f[:]->ICMR_500mb
clmr550=f[:]->CLMR_550mb
icmr550=f[:]->ICMR_550mb
clmr600=f[:]->CLMR_600mb
icmr600=f[:]->ICMR_600mb
clmr650=f[:]->CLMR_650mb
icmr650=f[:]->ICMR_650mb
clmr700=f[:]->CLMR_700mb
icmr700=f[:]->ICMR_700mb
clmr750=f[:]->CLMR_750mb
icmr750=f[:]->ICMR_750mb
clmr800=f[:]->CLMR_800mb
icmr800=f[:]->ICMR_800mb
clmr850=f[:]->CLMR_850mb
icmr850=f[:]->ICMR_850mb
clmr900=f[:]->CLMR_900mb
icmr900=f[:]->ICMR_900mb
clmr925=f[:]->CLMR_925mb
icmr925=f[:]->ICMR_925mb
clmr950=f[:]->CLMR_950mb
icmr950=f[:]->ICMR_950mb
clmr975=f[:]->CLMR_975mb
icmr975=f[:]->ICMR_975mb
clmr1000=f[:]->CLMR_1000mb
icmr1000=f[:]->ICMR_1000mb
SNMR50=f[:]->SNMR_50mb
RWMR50=f[:]->RWMR_50mb
SNMR100=f[:]->SNMR_100mb
RWMR100=f[:]->RWMR_100mb
SNMR150=f[:]->SNMR_150mb
RWMR150=f[:]->RWMR_150mb
SNMR200=f[:]->SNMR_200mb
RWMR200=f[:]->RWMR_200mb
SNMR250=f[:]->SNMR_250mb
RWMR250=f[:]->RWMR_250mb
SNMR300=f[:]->SNMR_300mb
RWMR300=f[:]->RWMR_300mb
SNMR350=f[:]->SNMR_350mb
RWMR350=f[:]->RWMR_350mb
SNMR400=f[:]->SNMR_400mb
RWMR400=f[:]->RWMR_400mb
SNMR450=f[:]->SNMR_450mb
RWMR450=f[:]->RWMR_450mb
SNMR500=f[:]->SNMR_500mb
RWMR500=f[:]->RWMR_500mb
SNMR550=f[:]->SNMR_550mb
RWMR550=f[:]->RWMR_550mb
SNMR600=f[:]->SNMR_600mb
RWMR600=f[:]->RWMR_600mb
SNMR650=f[:]->SNMR_650mb
RWMR650=f[:]->RWMR_650mb
SNMR700=f[:]->SNMR_700mb
RWMR700=f[:]->RWMR_700mb
SNMR750=f[:]->SNMR_750mb
RWMR750=f[:]->RWMR_750mb
SNMR800=f[:]->SNMR_800mb
RWMR800=f[:]->RWMR_800mb
SNMR850=f[:]->SNMR_850mb
RWMR850=f[:]->RWMR_850mb
SNMR900=f[:]->SNMR_900mb
RWMR900=f[:]->RWMR_900mb
SNMR925=f[:]->SNMR_925mb
RWMR925=f[:]->RWMR_925mb
SNMR950=f[:]->SNMR_950mb
RWMR950=f[:]->RWMR_950mb
SNMR975=f[:]->SNMR_975mb
RWMR975=f[:]->RWMR_975mb
SNMR1000=f[:]->SNMR_1000mb
RWMR1000=f[:]->RWMR_1000mb

GRLE50=f[:]->GRLE_50mb
GRLE100=f[:]->GRLE_100mb
GRLE150=f[:]->GRLE_150mb
GRLE200=f[:]->GRLE_200mb
GRLE250=f[:]->GRLE_250mb
GRLE300=f[:]->GRLE_300mb
GRLE350=f[:]->GRLE_350mb
GRLE400=f[:]->GRLE_400mb
GRLE450=f[:]->GRLE_450mb
GRLE500=f[:]->GRLE_500mb
GRLE550=f[:]->GRLE_550mb
GRLE600=f[:]->GRLE_600mb
GRLE650=f[:]->GRLE_650mb
GRLE700=f[:]->GRLE_700mb
GRLE750=f[:]->GRLE_750mb
GRLE800=f[:]->GRLE_800mb
GRLE850=f[:]->GRLE_850mb
GRLE900=f[:]->GRLE_900mb
GRLE925=f[:]->GRLE_925mb
GRLE950=f[:]->GRLE_950mb
GRLE975=f[:]->GRLE_975mb
GRLE1000=f[:]->GRLE_1000mb
;*************** End of Code Block to Read in Water Mixing Ratios **********************************

clmr=clmr1000
clmr=((clmr50+clmr100+clmr150+clmr200+clmr250+clmr300+clmr350+clmr400+clmr450+clmr500+clmr550+clmr600+clmr650+clmr700+clmr800+clmr850+clmr900)*50+(clmr925+clmr950+clmr975+clmr1000)*25)*100*1000/9.8

meanclmr=dim_avg_n_Wrap(clmr,0)
meanclmr@units="g m-2"
meanclmr@long_name="Liquid Water Path"
avgclmrdata=avg(clmr)

icmr=icmr1000
icmr=((icmr50+icmr100+icmr150+icmr200+icmr250+icmr300+icmr350+icmr400+icmr450+icmr500+icmr550+icmr600+icmr650+icmr700+icmr800+icmr850+icmr900)*50+(icmr925+icmr950+icmr975+icmr1000)*25)*100*1000/9.8
meanicmr=dim_avg_n_Wrap(icmr,0)
meanicmr@units="g m-2"
meanicmr@long_name="Ice Water Path"
avgicmrdata=avg(icmr)

SNMR=SNMR1000
SNMR=((SNMR50+SNMR100+SNMR150+SNMR200+SNMR250+SNMR300+SNMR350+SNMR400+SNMR450+SNMR500+SNMR550+SNMR600+SNMR650+SNMR700+SNMR800+SNMR850+SNMR900)*50+(SNMR925+SNMR950+SNMR975+SNMR1000)*25)*100*1000/9.8
meanSNMR=dim_avg_n_Wrap(SNMR,0)
meanSNMR@units="g m-2"
meanSNMR@long_name="Ice Water Path"
avgSNMRdata=avg(SNMR)

RWMR=RWMR1000
RWMR=((RWMR50+RWMR100+RWMR150+RWMR200+RWMR250+RWMR300+RWMR350+RWMR400+RWMR450+RWMR500+RWMR550+RWMR600+RWMR650+RWMR700+RWMR800+RWMR850+RWMR900)*50+(RWMR925+RWMR950+RWMR975+RWMR1000)*25)*100*1000/9.8
meanRWMR=dim_avg_n_Wrap(RWMR,0)
meanRWMR@units="g m-2"
meanRWMR@long_name="Ice Water Path"
avgRWMRdata=avg(RWMR)

GRLE=GRLE1000
GRLE=((GRLE50+GRLE100+GRLE150+GRLE200+GRLE250+GRLE300+GRLE350+GRLE400+GRLE450+GRLE500+GRLE550+GRLE600+GRLE650+GRLE700+GRLE800+GRLE850+GRLE900)*50+(GRLE925+GRLE950+GRLE975+GRLE1000)*25)*100*1000/9.8
meanGRLE=dim_avg_n_Wrap(GRLE,0)
meanGRLE@units="g m-2"
meanGRLE@long_name="Ice Water Path"
avgGRLEdata=avg(GRLE)

fivecwp=RWMR1000
fivecwp=icmr+clmr+SNMR+RWMR+GRLE
threeIWP=icmr+GRLE+SNMR
twoCWP=RWMR+clmr
;*************** Calculate Zonal Means of IWP and CWP **********************************
meanthreeIWP=dim_avg_n_Wrap(threeIWP,0)
meanthreeIWP@units="g m~S~-2~N~"
meanthreeIWP@long_name="Cloud Liquid Water Path"
meantwoCWP=dim_avg_n_Wrap(twoCWP,0)
meantwoCWP@units="g m~S~-2~N~"
meantwoCWP@long_name="Cloud Ice Water Path"
avgthreeIWPdata=avg(meanthreeIWP)
zonalmeanthreeIWP=dim_avg(meanthreeIWP)
avgtwoCWPdata=avg(meantwoCWP)
zonalmeantwoCWP=dim_avg(meantwoCWP)

meanfivecwp=dim_avg_n_Wrap(fivecwp,0)
meanfivecwp@units="g m-2"
meanfivecwp@long_name="Total Cloud Water Path"
avgfivecwpdata=avg(meanfivecwp)
zonalmeanfivecwp=dim_avg(meanfivecwp)
zonalmeanclmr=dim_avg(meanclmr)
zonalmeanicmr=dim_avg(meanicmr)

;*************** Start processing second model run scen **********************************

clmr50_51=f51[:]->CLMR_50mb
icmr50_51=f51[:]->ICMR_50mb
clmr100_51=f51[:]->CLMR_100mb
icmr100_51=f51[:]->ICMR_100mb
clmr150_51=f51[:]->CLMR_150mb
icmr150_51=f51[:]->ICMR_150mb
clmr200_51=f51[:]->CLMR_200mb
icmr200_51=f51[:]->ICMR_200mb
clmr250_51=f51[:]->CLMR_250mb
icmr250_51=f51[:]->ICMR_250mb
clmr300_51=f51[:]->CLMR_300mb
icmr300_51=f51[:]->ICMR_300mb
clmr350_51=f51[:]->CLMR_350mb
icmr350_51=f51[:]->ICMR_350mb
clmr400_51=f51[:]->CLMR_400mb
icmr400_51=f51[:]->ICMR_400mb
clmr450_51=f51[:]->CLMR_450mb
icmr450_51=f51[:]->ICMR_450mb
clmr500_51=f51[:]->CLMR_500mb
icmr500_51=f51[:]->ICMR_500mb
clmr550_51=f51[:]->CLMR_550mb
icmr550_51=f51[:]->ICMR_550mb
clmr600_51=f51[:]->CLMR_600mb
icmr600_51=f51[:]->ICMR_600mb
clmr650_51=f51[:]->CLMR_650mb
icmr650_51=f51[:]->ICMR_650mb
clmr700_51=f51[:]->CLMR_700mb
icmr700_51=f51[:]->ICMR_700mb
clmr750_51=f51[:]->CLMR_750mb
icmr750_51=f51[:]->ICMR_750mb
clmr800_51=f51[:]->CLMR_800mb
icmr800_51=f51[:]->ICMR_800mb
clmr850_51=f51[:]->CLMR_850mb
icmr850_51=f51[:]->ICMR_850mb
clmr900_51=f51[:]->CLMR_900mb
icmr900_51=f51[:]->ICMR_900mb
clmr925_51=f51[:]->CLMR_925mb
icmr925_51=f51[:]->ICMR_925mb
clmr950_51=f51[:]->CLMR_950mb
icmr950_51=f51[:]->ICMR_950mb
clmr975_51=f51[:]->CLMR_975mb
icmr975_51=f51[:]->ICMR_975mb
clmr1000_51=f51[:]->CLMR_1000mb
icmr1000_51=f51[:]->ICMR_1000mb
SNMR50_51=f51[:]->SNMR_50mb
RWMR50_51=f51[:]->RWMR_50mb
SNMR100_51=f51[:]->SNMR_100mb
RWMR100_51=f51[:]->RWMR_100mb
SNMR150_51=f51[:]->SNMR_150mb
RWMR150_51=f51[:]->RWMR_150mb
SNMR200_51=f51[:]->SNMR_200mb
RWMR200_51=f51[:]->RWMR_200mb
SNMR250_51=f51[:]->SNMR_250mb
RWMR250_51=f51[:]->RWMR_250mb
SNMR300_51=f51[:]->SNMR_300mb
RWMR300_51=f51[:]->RWMR_300mb
SNMR350_51=f51[:]->SNMR_350mb
RWMR350_51=f51[:]->RWMR_350mb
SNMR400_51=f51[:]->SNMR_400mb
RWMR400_51=f51[:]->RWMR_400mb
SNMR450_51=f51[:]->SNMR_450mb
RWMR450_51=f51[:]->RWMR_450mb
SNMR500_51=f51[:]->SNMR_500mb
RWMR500_51=f51[:]->RWMR_500mb
SNMR550_51=f51[:]->SNMR_550mb
RWMR550_51=f51[:]->RWMR_550mb
SNMR600_51=f51[:]->SNMR_600mb
RWMR600_51=f51[:]->RWMR_600mb
SNMR650_51=f51[:]->SNMR_650mb
RWMR650_51=f51[:]->RWMR_650mb
SNMR700_51=f51[:]->SNMR_700mb
RWMR700_51=f51[:]->RWMR_700mb
SNMR750_51=f51[:]->SNMR_750mb
RWMR750_51=f51[:]->RWMR_750mb
SNMR800_51=f51[:]->SNMR_800mb
RWMR800_51=f51[:]->RWMR_800mb
SNMR850_51=f51[:]->SNMR_850mb
RWMR850_51=f51[:]->RWMR_850mb
SNMR900_51=f51[:]->SNMR_900mb
RWMR900_51=f51[:]->RWMR_900mb
SNMR925_51=f51[:]->SNMR_925mb
RWMR925_51=f51[:]->RWMR_925mb
SNMR950_51=f51[:]->SNMR_950mb
RWMR950_51=f51[:]->RWMR_950mb
SNMR975_51=f51[:]->SNMR_975mb
RWMR975_51=f51[:]->RWMR_975mb
SNMR1000_51=f51[:]->SNMR_1000mb
RWMR1000_51=f51[:]->RWMR_1000mb

GRLE50_51=f51[:]->GRLE_50mb
GRLE100_51=f51[:]->GRLE_100mb
GRLE150_51=f51[:]->GRLE_150mb
GRLE200_51=f51[:]->GRLE_200mb
GRLE250_51=f51[:]->GRLE_250mb
GRLE300_51=f51[:]->GRLE_300mb
GRLE350_51=f51[:]->GRLE_350mb
GRLE400_51=f51[:]->GRLE_400mb
GRLE450_51=f51[:]->GRLE_450mb
GRLE500_51=f51[:]->GRLE_500mb
GRLE550_51=f51[:]->GRLE_550mb
GRLE600_51=f51[:]->GRLE_600mb
GRLE650_51=f51[:]->GRLE_650mb
GRLE700_51=f51[:]->GRLE_700mb
GRLE750_51=f51[:]->GRLE_750mb
GRLE800_51=f51[:]->GRLE_800mb
GRLE850_51=f51[:]->GRLE_850mb
GRLE900_51=f51[:]->GRLE_900mb
GRLE925_51=f51[:]->GRLE_925mb
GRLE950_51=f51[:]->GRLE_950mb
GRLE975_51=f51[:]->GRLE_975mb
GRLE1000_51=f51[:]->GRLE_1000mb

clmr_51=clmr1000_51
clmr_51=((clmr50_51+clmr100_51+clmr150_51+clmr200_51+clmr250_51+clmr300_51+clmr350_51+clmr400_51+clmr450_51+clmr500_51+clmr550_51+clmr600_51+clmr650_51+clmr700_51+clmr800_51+clmr850_51+clmr900_51)*50+(clmr925_51+clmr950_51+clmr975_51+clmr1000_51)*25)*100*1000/9.8
;printVarSummary(clmr)
meanclmr_51=dim_avg_n_Wrap(clmr_51,0)
meanclmr_51@units="g m-2"
meanclmr_51@long_name="Liquid Water Path"
avgclmrdata_51=avg(clmr_51)
;printVarSummary(meanclmr)
icmr_51=icmr1000_51
icmr_51=((icmr50_51+icmr100_51+icmr150_51+icmr200_51+icmr250_51+icmr300_51+icmr350_51+icmr400_51+icmr450_51+icmr500_51+icmr550_51+icmr600_51+icmr650_51+icmr700_51+icmr800_51+icmr850_51+icmr900_51)*50+(icmr925_51+icmr950_51+icmr975_51+icmr1000_51)*25)*100*1000/9.8
meanicmr_51=dim_avg_n_Wrap(icmr_51,0)
meanicmr_51@units="g m-2"
meanicmr_51@long_name="Ice Water Path"
avgicmrdata_51=avg(icmr_51)

SNMR_51=SNMR1000_51
SNMR_51=((SNMR50_51+SNMR100_51+SNMR150_51+SNMR200_51+SNMR250_51+SNMR300_51+SNMR350_51+SNMR400_51+SNMR450_51+SNMR500_51+SNMR550_51+SNMR600_51+SNMR650_51+SNMR700_51+SNMR800_51+SNMR850_51+SNMR900_51)*50+(SNMR925_51+SNMR950_51+SNMR975_51+SNMR1000_51)*25)*100*1000/9.8
meanSNMR_51=dim_avg_n_Wrap(SNMR_51,0)
meanSNMR_51@units="g m-2"
meanSNMR_51@long_name="Ice Water Path"
avgSNMRdata_51=avg(SNMR_51)

RWMR_51=RWMR1000_51
RWMR_51=((RWMR50_51+RWMR100_51+RWMR150_51+RWMR200_51+RWMR250_51+RWMR300_51+RWMR350_51+RWMR400_51+RWMR450_51+RWMR500_51+RWMR550_51+RWMR600_51+RWMR650_51+RWMR700_51+RWMR800_51+RWMR850_51+RWMR900_51)*50+(RWMR925_51+RWMR950_51+RWMR975_51+RWMR1000_51)*25)*100*1000/9.8
meanRWMR_51=dim_avg_n_Wrap(RWMR_51,0)
meanRWMR_51@units="g m-2"
meanRWMR_51@long_name="Ice Water Path"
avgRWMRdata_51=avg(RWMR_51)
GRLE_51=GRLE1000_51
GRLE_51=((GRLE50_51+GRLE100_51+GRLE150_51+GRLE200_51+GRLE250_51+GRLE300_51+GRLE350_51+GRLE400_51+GRLE450_51+GRLE500_51+GRLE550_51+GRLE600_51+GRLE650_51+GRLE700_51+GRLE800_51+GRLE850_51+GRLE900_51)*50+(GRLE925_51+GRLE950_51+GRLE975_51+GRLE1000_51)*25)*100*1000/9.8
meanGRLE_51=dim_avg_n_Wrap(GRLE_51,0)
meanGRLE_51@units="g m-2"
meanGRLE_51@long_name="Ice Water Path"
avgGRLEdata_51=avg(GRLE_51)

fivecwp_51=RWMR1000_51
fivecwp_51=icmr_51+clmr_51+SNMR_51+RWMR_51+GRLE_51
threeIWP_51=icmr_51+GRLE_51+SNMR_51
twoCWP_51=RWMR_51+clmr_51
meanthreeIWP_51=dim_avg_n_Wrap(threeIWP_51,0)
meanthreeIWP_51@units="g m~S~-2~N~"
meanthreeIWP_51@long_name="Cloud Liquid Water Path"
meantwoCWP_51=dim_avg_n_Wrap(twoCWP_51,0)
meantwoCWP_51@units="g m~S~-2~N~"
meantwoCWP_51@long_name="Cloud Ice Water Path"
avgthreeIWPdata_51=avg(meanthreeIWP_51)
zonalmeanthreeIWP_51=dim_avg(meanthreeIWP_51)
avgtwoCWPdata_51=avg(meantwoCWP_51)
zonalmeantwoCWP_51=dim_avg(meantwoCWP_51)

meanfivecwp_51=dim_avg_n_Wrap(fivecwp_51,0)
meanfivecwp_51@units="g m-2"
meanfivecwp_51@long_name="Total Cloud Water Path"
avgfivecwpdata_51=avg(meanfivecwp_51)
zonalmeanfivecwp_51=dim_avg(meanfivecwp_51)
zonalmeanclmr_51=dim_avg(meanclmr_51)
zonalmeanicmr_51=dim_avg(meanicmr_51)
;*************** End processing second model run scen **********************************

clmr50_52=f52[:]->CLMR_50mb
icmr50_52=f52[:]->ICMR_50mb
clmr100_52=f52[:]->CLMR_100mb
icmr100_52=f52[:]->ICMR_100mb
clmr150_52=f52[:]->CLMR_150mb
icmr150_52=f52[:]->ICMR_150mb
clmr200_52=f52[:]->CLMR_200mb
icmr200_52=f52[:]->ICMR_200mb
clmr250_52=f52[:]->CLMR_250mb
icmr250_52=f52[:]->ICMR_250mb
clmr300_52=f52[:]->CLMR_300mb
icmr300_52=f52[:]->ICMR_300mb
clmr350_52=f52[:]->CLMR_350mb
icmr350_52=f52[:]->ICMR_350mb
clmr400_52=f52[:]->CLMR_400mb
icmr400_52=f52[:]->ICMR_400mb
clmr450_52=f52[:]->CLMR_450mb
icmr450_52=f52[:]->ICMR_450mb
clmr500_52=f52[:]->CLMR_500mb
icmr500_52=f52[:]->ICMR_500mb
clmr550_52=f52[:]->CLMR_550mb
icmr550_52=f52[:]->ICMR_550mb
clmr600_52=f52[:]->CLMR_600mb
icmr600_52=f52[:]->ICMR_600mb
clmr650_52=f52[:]->CLMR_650mb
icmr650_52=f52[:]->ICMR_650mb
clmr700_52=f52[:]->CLMR_700mb
icmr700_52=f52[:]->ICMR_700mb
clmr750_52=f52[:]->CLMR_750mb
icmr750_52=f52[:]->ICMR_750mb
clmr800_52=f52[:]->CLMR_800mb
icmr800_52=f52[:]->ICMR_800mb
clmr850_52=f52[:]->CLMR_850mb
icmr850_52=f52[:]->ICMR_850mb
clmr900_52=f52[:]->CLMR_900mb
icmr900_52=f52[:]->ICMR_900mb
clmr925_52=f52[:]->CLMR_925mb
icmr925_52=f52[:]->ICMR_925mb
clmr950_52=f52[:]->CLMR_950mb
icmr950_52=f52[:]->ICMR_950mb
clmr975_52=f52[:]->CLMR_975mb
icmr975_52=f52[:]->ICMR_975mb
clmr1000_52=f52[:]->CLMR_1000mb
icmr1000_52=f52[:]->ICMR_1000mb
SNMR50_52=f52[:]->SNMR_50mb
RWMR50_52=f52[:]->RWMR_50mb
SNMR100_52=f52[:]->SNMR_100mb
RWMR100_52=f52[:]->RWMR_100mb
SNMR150_52=f52[:]->SNMR_150mb
RWMR150_52=f52[:]->RWMR_150mb
SNMR200_52=f52[:]->SNMR_200mb
RWMR200_52=f52[:]->RWMR_200mb
SNMR250_52=f52[:]->SNMR_250mb
RWMR250_52=f52[:]->RWMR_250mb
SNMR300_52=f52[:]->SNMR_300mb
RWMR300_52=f52[:]->RWMR_300mb
SNMR350_52=f52[:]->SNMR_350mb
RWMR350_52=f52[:]->RWMR_350mb
SNMR400_52=f52[:]->SNMR_400mb
RWMR400_52=f52[:]->RWMR_400mb
SNMR450_52=f52[:]->SNMR_450mb
RWMR450_52=f52[:]->RWMR_450mb
SNMR500_52=f52[:]->SNMR_500mb
RWMR500_52=f52[:]->RWMR_500mb
SNMR550_52=f52[:]->SNMR_550mb
RWMR550_52=f52[:]->RWMR_550mb
SNMR600_52=f52[:]->SNMR_600mb
RWMR600_52=f52[:]->RWMR_600mb
SNMR650_52=f52[:]->SNMR_650mb
RWMR650_52=f52[:]->RWMR_650mb
SNMR700_52=f52[:]->SNMR_700mb
RWMR700_52=f52[:]->RWMR_700mb
SNMR750_52=f52[:]->SNMR_750mb
RWMR750_52=f52[:]->RWMR_750mb
SNMR800_52=f52[:]->SNMR_800mb
RWMR800_52=f52[:]->RWMR_800mb
SNMR850_52=f52[:]->SNMR_850mb
RWMR850_52=f52[:]->RWMR_850mb
SNMR900_52=f52[:]->SNMR_900mb
RWMR900_52=f52[:]->RWMR_900mb
SNMR925_52=f52[:]->SNMR_925mb
RWMR925_52=f52[:]->RWMR_925mb
SNMR950_52=f52[:]->SNMR_950mb
RWMR950_52=f52[:]->RWMR_950mb
SNMR975_52=f52[:]->SNMR_975mb
RWMR975_52=f52[:]->RWMR_975mb
SNMR1000_52=f52[:]->SNMR_1000mb
RWMR1000_52=f52[:]->RWMR_1000mb

GRLE50_52=f52[:]->GRLE_50mb
GRLE100_52=f52[:]->GRLE_100mb
GRLE150_52=f52[:]->GRLE_150mb
GRLE200_52=f52[:]->GRLE_200mb
GRLE250_52=f52[:]->GRLE_250mb
GRLE300_52=f52[:]->GRLE_300mb
GRLE350_52=f52[:]->GRLE_350mb
GRLE400_52=f52[:]->GRLE_400mb
GRLE450_52=f52[:]->GRLE_450mb
GRLE500_52=f52[:]->GRLE_500mb
GRLE550_52=f52[:]->GRLE_550mb
GRLE600_52=f52[:]->GRLE_600mb
GRLE650_52=f52[:]->GRLE_650mb
GRLE700_52=f52[:]->GRLE_700mb
GRLE750_52=f52[:]->GRLE_750mb
GRLE800_52=f52[:]->GRLE_800mb
GRLE850_52=f52[:]->GRLE_850mb
GRLE900_52=f52[:]->GRLE_900mb
GRLE925_52=f52[:]->GRLE_925mb
GRLE950_52=f52[:]->GRLE_950mb
GRLE975_52=f52[:]->GRLE_975mb
GRLE1000_52=f52[:]->GRLE_1000mb

clmr_52=clmr1000_52
clmr_52=((clmr50_52+clmr100_52+clmr150_52+clmr200_52+clmr250_52+clmr300_52+clmr350_52+clmr400_52+clmr450_52+clmr500_52+clmr550_52+clmr600_52+clmr650_52+clmr700_52+clmr800_52+clmr850_52+clmr900_52)*50+(clmr925_52+clmr950_52+clmr975_52+clmr1000_52)*25)*100*1000/9.8
;printVarSummary(clmr)
meanclmr_52=dim_avg_n_Wrap(clmr_52,0)
meanclmr_52@units="g m-2"
meanclmr_52@long_name="Liquid Water Path"
avgclmrdata_52=avg(clmr_52)
;printVarSummary(meanclmr)
icmr_52=icmr1000_52
icmr_52=((icmr50_52+icmr100_52+icmr150_52+icmr200_52+icmr250_52+icmr300_52+icmr350_52+icmr400_52+icmr450_52+icmr500_52+icmr550_52+icmr600_52+icmr650_52+icmr700_52+icmr800_52+icmr850_52+icmr900_52)*50+(icmr925_52+icmr950_52+icmr975_52+icmr1000_52)*25)*100*1000/9.8
meanicmr_52=dim_avg_n_Wrap(icmr_52,0)
meanicmr_52@units="g m-2"
meanicmr_52@long_name="Ice Water Path"
avgicmrdata_52=avg(icmr_52)

SNMR_52=SNMR1000_52
SNMR_52=((SNMR50_52+SNMR100_52+SNMR150_52+SNMR200_52+SNMR250_52+SNMR300_52+SNMR350_52+SNMR400_52+SNMR450_52+SNMR500_52+SNMR550_52+SNMR600_52+SNMR650_52+SNMR700_52+SNMR800_52+SNMR850_52+SNMR900_52)*50+(SNMR925_52+SNMR950_52+SNMR975_52+SNMR1000_52)*25)*100*1000/9.8
meanSNMR_52=dim_avg_n_Wrap(SNMR_52,0)
meanSNMR_52@units="g m-2"
meanSNMR_52@long_name="Ice Water Path"
avgSNMRdata_52=avg(SNMR_52)

RWMR_52=RWMR1000_52
RWMR_52=((RWMR50_52+RWMR100_52+RWMR150_52+RWMR200_52+RWMR250_52+RWMR300_52+RWMR350_52+RWMR400_52+RWMR450_52+RWMR500_52+RWMR550_52+RWMR600_52+RWMR650_52+RWMR700_52+RWMR800_52+RWMR850_52+RWMR900_52)*50+(RWMR925_52+RWMR950_52+RWMR975_52+RWMR1000_52)*25)*100*1000/9.8
meanRWMR_52=dim_avg_n_Wrap(RWMR_52,0)
meanRWMR_52@units="g m-2"
meanRWMR_52@long_name="Ice Water Path"
avgRWMRdata_52=avg(RWMR_52)
GRLE_52=GRLE1000_52
GRLE_52=((GRLE50_52+GRLE100_52+GRLE150_52+GRLE200_52+GRLE250_52+GRLE300_52+GRLE350_52+GRLE400_52+GRLE450_52+GRLE500_52+GRLE550_52+GRLE600_52+GRLE650_52+GRLE700_52+GRLE800_52+GRLE850_52+GRLE900_52)*50+(GRLE925_52+GRLE950_52+GRLE975_52+GRLE1000_52)*25)*100*1000/9.8
meanGRLE_52=dim_avg_n_Wrap(GRLE_52,0)
meanGRLE_52@units="g m-2"
meanGRLE_52@long_name="Ice Water Path"
avgGRLEdata_52=avg(GRLE_52)

fivecwp_52=RWMR1000_52
fivecwp_52=icmr_52+clmr_52+SNMR_52+RWMR_52+GRLE_52
threeIWP_52=icmr_52+GRLE_52+SNMR_52
twoCWP_52=RWMR_52+clmr_52
meanthreeIWP_52=dim_avg_n_Wrap(threeIWP_52,0)
meanthreeIWP_52@units="g m~S~-2~N~"
meanthreeIWP_52@long_name="Cloud Liquid Water Path"
meantwoCWP_52=dim_avg_n_Wrap(twoCWP_52,0)
meantwoCWP_52@units="g m~S~-2~N~"
meantwoCWP_52@long_name="Cloud Ice Water Path"
avgthreeIWPdata_52=avg(meanthreeIWP_52)
zonalmeanthreeIWP_52=dim_avg(meanthreeIWP_52)
avgtwoCWPdata_52=avg(meantwoCWP_52)
zonalmeantwoCWP_52=dim_avg(meantwoCWP_52)

meanfivecwp_52=dim_avg_n_Wrap(fivecwp_52,0)
meanfivecwp_52@units="g m-2"
meanfivecwp_52@long_name="Total Cloud Water Path"
avgfivecwpdata_52=avg(meanfivecwp_52)
zonalmeanfivecwp_52=dim_avg(meanfivecwp_52)
zonalmeanclmr_52=dim_avg(meanclmr_52)
zonalmeanicmr_52=dim_avg(meanicmr_52)

;*************** End processing third model run scen **********************************

clmr50_53=f53[:]->CLMR_50mb
icmr50_53=f53[:]->ICMR_50mb
clmr100_53=f53[:]->CLMR_100mb
icmr100_53=f53[:]->ICMR_100mb
clmr150_53=f53[:]->CLMR_150mb
icmr150_53=f53[:]->ICMR_150mb
clmr200_53=f53[:]->CLMR_200mb
icmr200_53=f53[:]->ICMR_200mb
clmr250_53=f53[:]->CLMR_250mb
icmr250_53=f53[:]->ICMR_250mb
clmr300_53=f53[:]->CLMR_300mb
icmr300_53=f53[:]->ICMR_300mb
clmr350_53=f53[:]->CLMR_350mb
icmr350_53=f53[:]->ICMR_350mb
clmr400_53=f53[:]->CLMR_400mb
icmr400_53=f53[:]->ICMR_400mb
clmr450_53=f53[:]->CLMR_450mb
icmr450_53=f53[:]->ICMR_450mb
clmr500_53=f53[:]->CLMR_500mb
icmr500_53=f53[:]->ICMR_500mb
clmr550_53=f53[:]->CLMR_550mb
icmr550_53=f53[:]->ICMR_550mb
clmr600_53=f53[:]->CLMR_600mb
icmr600_53=f53[:]->ICMR_600mb
clmr650_53=f53[:]->CLMR_650mb
icmr650_53=f53[:]->ICMR_650mb
clmr700_53=f53[:]->CLMR_700mb
icmr700_53=f53[:]->ICMR_700mb
clmr750_53=f53[:]->CLMR_750mb
icmr750_53=f53[:]->ICMR_750mb
clmr800_53=f53[:]->CLMR_800mb
icmr800_53=f53[:]->ICMR_800mb
clmr850_53=f53[:]->CLMR_850mb
icmr850_53=f53[:]->ICMR_850mb
clmr900_53=f53[:]->CLMR_900mb
icmr900_53=f53[:]->ICMR_900mb
clmr925_53=f53[:]->CLMR_925mb
icmr925_53=f53[:]->ICMR_925mb
clmr950_53=f53[:]->CLMR_950mb
icmr950_53=f53[:]->ICMR_950mb
clmr975_53=f53[:]->CLMR_975mb
icmr975_53=f53[:]->ICMR_975mb
clmr1000_53=f53[:]->CLMR_1000mb
icmr1000_53=f53[:]->ICMR_1000mb
SNMR50_53=f53[:]->SNMR_50mb
RWMR50_53=f53[:]->RWMR_50mb
SNMR100_53=f53[:]->SNMR_100mb
RWMR100_53=f53[:]->RWMR_100mb
SNMR150_53=f53[:]->SNMR_150mb
RWMR150_53=f53[:]->RWMR_150mb
SNMR200_53=f53[:]->SNMR_200mb
RWMR200_53=f53[:]->RWMR_200mb
SNMR250_53=f53[:]->SNMR_250mb
RWMR250_53=f53[:]->RWMR_250mb
SNMR300_53=f53[:]->SNMR_300mb
RWMR300_53=f53[:]->RWMR_300mb
SNMR350_53=f53[:]->SNMR_350mb
RWMR350_53=f53[:]->RWMR_350mb
SNMR400_53=f53[:]->SNMR_400mb
RWMR400_53=f53[:]->RWMR_400mb
SNMR450_53=f53[:]->SNMR_450mb
RWMR450_53=f53[:]->RWMR_450mb
SNMR500_53=f53[:]->SNMR_500mb
RWMR500_53=f53[:]->RWMR_500mb
SNMR550_53=f53[:]->SNMR_550mb
RWMR550_53=f53[:]->RWMR_550mb
SNMR600_53=f53[:]->SNMR_600mb
RWMR600_53=f53[:]->RWMR_600mb
SNMR650_53=f53[:]->SNMR_650mb
RWMR650_53=f53[:]->RWMR_650mb
SNMR700_53=f53[:]->SNMR_700mb
RWMR700_53=f53[:]->RWMR_700mb
SNMR750_53=f53[:]->SNMR_750mb
RWMR750_53=f53[:]->RWMR_750mb
SNMR800_53=f53[:]->SNMR_800mb
RWMR800_53=f53[:]->RWMR_800mb
SNMR850_53=f53[:]->SNMR_850mb
RWMR850_53=f53[:]->RWMR_850mb
SNMR900_53=f53[:]->SNMR_900mb
RWMR900_53=f53[:]->RWMR_900mb
SNMR925_53=f53[:]->SNMR_925mb
RWMR925_53=f53[:]->RWMR_925mb
SNMR950_53=f53[:]->SNMR_950mb
RWMR950_53=f53[:]->RWMR_950mb
SNMR975_53=f53[:]->SNMR_975mb
RWMR975_53=f53[:]->RWMR_975mb
SNMR1000_53=f53[:]->SNMR_1000mb
RWMR1000_53=f53[:]->RWMR_1000mb

GRLE50_53=f53[:]->GRLE_50mb
GRLE100_53=f53[:]->GRLE_100mb
GRLE150_53=f53[:]->GRLE_150mb
GRLE200_53=f53[:]->GRLE_200mb
GRLE250_53=f53[:]->GRLE_250mb
GRLE300_53=f53[:]->GRLE_300mb
GRLE350_53=f53[:]->GRLE_350mb
GRLE400_53=f53[:]->GRLE_400mb
GRLE450_53=f53[:]->GRLE_450mb
GRLE500_53=f53[:]->GRLE_500mb
GRLE550_53=f53[:]->GRLE_550mb
GRLE600_53=f53[:]->GRLE_600mb
GRLE650_53=f53[:]->GRLE_650mb
GRLE700_53=f53[:]->GRLE_700mb
GRLE750_53=f53[:]->GRLE_750mb
GRLE800_53=f53[:]->GRLE_800mb
GRLE850_53=f53[:]->GRLE_850mb
GRLE900_53=f53[:]->GRLE_900mb
GRLE925_53=f53[:]->GRLE_925mb
GRLE950_53=f53[:]->GRLE_950mb
GRLE975_53=f53[:]->GRLE_975mb
GRLE1000_53=f53[:]->GRLE_1000mb

clmr_53=clmr1000_53
clmr_53=((clmr50_53+clmr100_53+clmr150_53+clmr200_53+clmr250_53+clmr300_53+clmr350_53+clmr400_53+clmr450_53+clmr500_53+clmr550_53+clmr600_53+clmr650_53+clmr700_53+clmr800_53+clmr850_53+clmr900_53)*50+(clmr925_53+clmr950_53+clmr975_53+clmr1000_53)*25)*100*1000/9.8
;printVarSummary(clmr)
meanclmr_53=dim_avg_n_Wrap(clmr_53,0)
meanclmr_53@units="g m-2"
meanclmr_53@long_name="Liquid Water Path"
avgclmrdata_53=avg(clmr_53)
;printVarSummary(meanclmr)
icmr_53=icmr1000_53
icmr_53=((icmr50_53+icmr100_53+icmr150_53+icmr200_53+icmr250_53+icmr300_53+icmr350_53+icmr400_53+icmr450_53+icmr500_53+icmr550_53+icmr600_53+icmr650_53+icmr700_53+icmr800_53+icmr850_53+icmr900_53)*50+(icmr925_53+icmr950_53+icmr975_53+icmr1000_53)*25)*100*1000/9.8
meanicmr_53=dim_avg_n_Wrap(icmr_53,0)
meanicmr_53@units="g m-2"
meanicmr_53@long_name="Ice Water Path"
avgicmrdata_53=avg(icmr_53)

SNMR_53=SNMR1000_53
SNMR_53=((SNMR50_53+SNMR100_53+SNMR150_53+SNMR200_53+SNMR250_53+SNMR300_53+SNMR350_53+SNMR400_53+SNMR450_53+SNMR500_53+SNMR550_53+SNMR600_53+SNMR650_53+SNMR700_53+SNMR800_53+SNMR850_53+SNMR900_53)*50+(SNMR925_53+SNMR950_53+SNMR975_53+SNMR1000_53)*25)*100*1000/9.8
meanSNMR_53=dim_avg_n_Wrap(SNMR_53,0)
meanSNMR_53@units="g m-2"
meanSNMR_53@long_name="Ice Water Path"
avgSNMRdata_53=avg(SNMR_53)

RWMR_53=RWMR1000_53
RWMR_53=((RWMR50_53+RWMR100_53+RWMR150_53+RWMR200_53+RWMR250_53+RWMR300_53+RWMR350_53+RWMR400_53+RWMR450_53+RWMR500_53+RWMR550_53+RWMR600_53+RWMR650_53+RWMR700_53+RWMR800_53+RWMR850_53+RWMR900_53)*50+(RWMR925_53+RWMR950_53+RWMR975_53+RWMR1000_53)*25)*100*1000/9.8
meanRWMR_53=dim_avg_n_Wrap(RWMR_53,0)
meanRWMR_53@units="g m-2"
meanRWMR_53@long_name="Ice Water Path"
avgRWMRdata_53=avg(RWMR_53)
GRLE_53=GRLE1000_53
GRLE_53=((GRLE50_53+GRLE100_53+GRLE150_53+GRLE200_53+GRLE250_53+GRLE300_53+GRLE350_53+GRLE400_53+GRLE450_53+GRLE500_53+GRLE550_53+GRLE600_53+GRLE650_53+GRLE700_53+GRLE800_53+GRLE850_53+GRLE900_53)*50+(GRLE925_53+GRLE950_53+GRLE975_53+GRLE1000_53)*25)*100*1000/9.8
meanGRLE_53=dim_avg_n_Wrap(GRLE_53,0)
meanGRLE_53@units="g m-2"
meanGRLE_53@long_name="Ice Water Path"
avgGRLEdata_53=avg(GRLE_53)

fivecwp_53=RWMR1000_53
fivecwp_53=icmr_53+clmr_53+SNMR_53+RWMR_53+GRLE_53
threeIWP_53=icmr_53+GRLE_53+SNMR_53
twoCWP_53=RWMR_53+clmr_53
meanthreeIWP_53=dim_avg_n_Wrap(threeIWP_53,0)
meanthreeIWP_53@units="g m~S~-2~N~"
meanthreeIWP_53@long_name="Cloud Liquid Water Path"
meantwoCWP_53=dim_avg_n_Wrap(twoCWP_53,0)
meantwoCWP_53@units="g m~S~-2~N~"
meantwoCWP_53@long_name="Cloud Ice Water Path"
avgthreeIWPdata_53=avg(meanthreeIWP_53)
zonalmeanthreeIWP_53=dim_avg(meanthreeIWP_53)
avgtwoCWPdata_53=avg(meantwoCWP_53)
zonalmeantwoCWP_53=dim_avg(meantwoCWP_53)

meanfivecwp_53=dim_avg_n_Wrap(fivecwp_53,0)
meanfivecwp_53@units="g m-2"
meanfivecwp_53@long_name="Total Cloud Water Path"
avgfivecwpdata_53=avg(meanfivecwp_53)
zonalmeanfivecwp_53=dim_avg(meanfivecwp_53)
zonalmeanclmr_53=dim_avg(meanclmr_53)
zonalmeanicmr_53=dim_avg(meanicmr_53)

;*************** End processing fourth model run scen **********************************

clmr50_54=f54[:]->CLMR_50mb
icmr50_54=f54[:]->ICMR_50mb
clmr100_54=f54[:]->CLMR_100mb
icmr100_54=f54[:]->ICMR_100mb
clmr150_54=f54[:]->CLMR_150mb
icmr150_54=f54[:]->ICMR_150mb
clmr200_54=f54[:]->CLMR_200mb
icmr200_54=f54[:]->ICMR_200mb
clmr250_54=f54[:]->CLMR_250mb
icmr250_54=f54[:]->ICMR_250mb
clmr300_54=f54[:]->CLMR_300mb
icmr300_54=f54[:]->ICMR_300mb
clmr350_54=f54[:]->CLMR_350mb
icmr350_54=f54[:]->ICMR_350mb
clmr400_54=f54[:]->CLMR_400mb
icmr400_54=f54[:]->ICMR_400mb
clmr450_54=f54[:]->CLMR_450mb
icmr450_54=f54[:]->ICMR_450mb
clmr500_54=f54[:]->CLMR_500mb
icmr500_54=f54[:]->ICMR_500mb
clmr550_54=f54[:]->CLMR_550mb
icmr550_54=f54[:]->ICMR_550mb
clmr600_54=f54[:]->CLMR_600mb
icmr600_54=f54[:]->ICMR_600mb
clmr650_54=f54[:]->CLMR_650mb
icmr650_54=f54[:]->ICMR_650mb
clmr700_54=f54[:]->CLMR_700mb
icmr700_54=f54[:]->ICMR_700mb
clmr750_54=f54[:]->CLMR_750mb
icmr750_54=f54[:]->ICMR_750mb
clmr800_54=f54[:]->CLMR_800mb
icmr800_54=f54[:]->ICMR_800mb
clmr850_54=f54[:]->CLMR_850mb
icmr850_54=f54[:]->ICMR_850mb
clmr900_54=f54[:]->CLMR_900mb
icmr900_54=f54[:]->ICMR_900mb
clmr925_54=f54[:]->CLMR_925mb
icmr925_54=f54[:]->ICMR_925mb
clmr950_54=f54[:]->CLMR_950mb
icmr950_54=f54[:]->ICMR_950mb
clmr975_54=f54[:]->CLMR_975mb
icmr975_54=f54[:]->ICMR_975mb
clmr1000_54=f54[:]->CLMR_1000mb
icmr1000_54=f54[:]->ICMR_1000mb
SNMR50_54=f54[:]->SNMR_50mb
RWMR50_54=f54[:]->RWMR_50mb
SNMR100_54=f54[:]->SNMR_100mb
RWMR100_54=f54[:]->RWMR_100mb
SNMR150_54=f54[:]->SNMR_150mb
RWMR150_54=f54[:]->RWMR_150mb
SNMR200_54=f54[:]->SNMR_200mb
RWMR200_54=f54[:]->RWMR_200mb
SNMR250_54=f54[:]->SNMR_250mb
RWMR250_54=f54[:]->RWMR_250mb
SNMR300_54=f54[:]->SNMR_300mb
RWMR300_54=f54[:]->RWMR_300mb
SNMR350_54=f54[:]->SNMR_350mb
RWMR350_54=f54[:]->RWMR_350mb
SNMR400_54=f54[:]->SNMR_400mb
RWMR400_54=f54[:]->RWMR_400mb
SNMR450_54=f54[:]->SNMR_450mb
RWMR450_54=f54[:]->RWMR_450mb
SNMR500_54=f54[:]->SNMR_500mb
RWMR500_54=f54[:]->RWMR_500mb
SNMR550_54=f54[:]->SNMR_550mb
RWMR550_54=f54[:]->RWMR_550mb
SNMR600_54=f54[:]->SNMR_600mb
RWMR600_54=f54[:]->RWMR_600mb
SNMR650_54=f54[:]->SNMR_650mb
RWMR650_54=f54[:]->RWMR_650mb
SNMR700_54=f54[:]->SNMR_700mb
RWMR700_54=f54[:]->RWMR_700mb
SNMR750_54=f54[:]->SNMR_750mb
RWMR750_54=f54[:]->RWMR_750mb
SNMR800_54=f54[:]->SNMR_800mb
RWMR800_54=f54[:]->RWMR_800mb
SNMR850_54=f54[:]->SNMR_850mb
RWMR850_54=f54[:]->RWMR_850mb
SNMR900_54=f54[:]->SNMR_900mb
RWMR900_54=f54[:]->RWMR_900mb
SNMR925_54=f54[:]->SNMR_925mb
RWMR925_54=f54[:]->RWMR_925mb
SNMR950_54=f54[:]->SNMR_950mb
RWMR950_54=f54[:]->RWMR_950mb
SNMR975_54=f54[:]->SNMR_975mb
RWMR975_54=f54[:]->RWMR_975mb
SNMR1000_54=f54[:]->SNMR_1000mb
RWMR1000_54=f54[:]->RWMR_1000mb

GRLE50_54=f54[:]->GRLE_50mb
GRLE100_54=f54[:]->GRLE_100mb
GRLE150_54=f54[:]->GRLE_150mb
GRLE200_54=f54[:]->GRLE_200mb
GRLE250_54=f54[:]->GRLE_250mb
GRLE300_54=f54[:]->GRLE_300mb
GRLE350_54=f54[:]->GRLE_350mb
GRLE400_54=f54[:]->GRLE_400mb
GRLE450_54=f54[:]->GRLE_450mb
GRLE500_54=f54[:]->GRLE_500mb
GRLE550_54=f54[:]->GRLE_550mb
GRLE600_54=f54[:]->GRLE_600mb
GRLE650_54=f54[:]->GRLE_650mb
GRLE700_54=f54[:]->GRLE_700mb
GRLE750_54=f54[:]->GRLE_750mb
GRLE800_54=f54[:]->GRLE_800mb
GRLE850_54=f54[:]->GRLE_850mb
GRLE900_54=f54[:]->GRLE_900mb
GRLE925_54=f54[:]->GRLE_925mb
GRLE950_54=f54[:]->GRLE_950mb
GRLE975_54=f54[:]->GRLE_975mb
GRLE1000_54=f54[:]->GRLE_1000mb

clmr_54=clmr1000_54
clmr_54=((clmr50_54+clmr100_54+clmr150_54+clmr200_54+clmr250_54+clmr300_54+clmr350_54+clmr400_54+clmr450_54+clmr500_54+clmr550_54+clmr600_54+clmr650_54+clmr700_54+clmr800_54+clmr850_54+clmr900_54)*50+(clmr925_54+clmr950_54+clmr975_54+clmr1000_54)*25)*100*1000/9.8
;printVarSummary(clmr)
meanclmr_54=dim_avg_n_Wrap(clmr_54,0)
meanclmr_54@units="g m-2"
meanclmr_54@long_name="Liquid Water Path"
avgclmrdata_54=avg(clmr_54)
;printVarSummary(meanclmr)
icmr_54=icmr1000_54
icmr_54=((icmr50_54+icmr100_54+icmr150_54+icmr200_54+icmr250_54+icmr300_54+icmr350_54+icmr400_54+icmr450_54+icmr500_54+icmr550_54+icmr600_54+icmr650_54+icmr700_54+icmr800_54+icmr850_54+icmr900_54)*50+(icmr925_54+icmr950_54+icmr975_54+icmr1000_54)*25)*100*1000/9.8
meanicmr_54=dim_avg_n_Wrap(icmr_54,0)
meanicmr_54@units="g m-2"
meanicmr_54@long_name="Ice Water Path"
avgicmrdata_54=avg(icmr_54)

SNMR_54=SNMR1000_54
SNMR_54=((SNMR50_54+SNMR100_54+SNMR150_54+SNMR200_54+SNMR250_54+SNMR300_54+SNMR350_54+SNMR400_54+SNMR450_54+SNMR500_54+SNMR550_54+SNMR600_54+SNMR650_54+SNMR700_54+SNMR800_54+SNMR850_54+SNMR900_54)*50+(SNMR925_54+SNMR950_54+SNMR975_54+SNMR1000_54)*25)*100*1000/9.8
meanSNMR_54=dim_avg_n_Wrap(SNMR_54,0)
meanSNMR_54@units="g m-2"
meanSNMR_54@long_name="Ice Water Path"
avgSNMRdata_54=avg(SNMR_54)

RWMR_54=RWMR1000_54
RWMR_54=((RWMR50_54+RWMR100_54+RWMR150_54+RWMR200_54+RWMR250_54+RWMR300_54+RWMR350_54+RWMR400_54+RWMR450_54+RWMR500_54+RWMR550_54+RWMR600_54+RWMR650_54+RWMR700_54+RWMR800_54+RWMR850_54+RWMR900_54)*50+(RWMR925_54+RWMR950_54+RWMR975_54+RWMR1000_54)*25)*100*1000/9.8
meanRWMR_54=dim_avg_n_Wrap(RWMR_54,0)
meanRWMR_54@units="g m-2"
meanRWMR_54@long_name="Ice Water Path"
avgRWMRdata_54=avg(RWMR_54)
GRLE_54=GRLE1000_54
GRLE_54=((GRLE50_54+GRLE100_54+GRLE150_54+GRLE200_54+GRLE250_54+GRLE300_54+GRLE350_54+GRLE400_54+GRLE450_54+GRLE500_54+GRLE550_54+GRLE600_54+GRLE650_54+GRLE700_54+GRLE800_54+GRLE850_54+GRLE900_54)*50+(GRLE925_54+GRLE950_54+GRLE975_54+GRLE1000_54)*25)*100*1000/9.8
meanGRLE_54=dim_avg_n_Wrap(GRLE_54,0)
meanGRLE_54@units="g m-2"
meanGRLE_54@long_name="Ice Water Path"
avgGRLEdata_54=avg(GRLE_54)

fivecwp_54=RWMR1000_54
fivecwp_54=icmr_54+clmr_54+SNMR_54+RWMR_54+GRLE_54
threeIWP_54=icmr_54+GRLE_54+SNMR_54
twoCWP_54=RWMR_54+clmr_54
meanthreeIWP_54=dim_avg_n_Wrap(threeIWP_54,0)
meanthreeIWP_54@units="g m~S~-2~N~"
meanthreeIWP_54@long_name="Cloud Liquid Water Path"
meantwoCWP_54=dim_avg_n_Wrap(twoCWP_54,0)
meantwoCWP_54@units="g m~S~-2~N~"
meantwoCWP_54@long_name="Cloud Ice Water Path"
avgthreeIWPdata_54=avg(meanthreeIWP_54)
zonalmeanthreeIWP_54=dim_avg(meanthreeIWP_54)
avgtwoCWPdata_54=avg(meantwoCWP_54)
zonalmeantwoCWP_54=dim_avg(meantwoCWP_54)

meanfivecwp_54=dim_avg_n_Wrap(fivecwp_54,0)
meanfivecwp_54@units="g m-2"
meanfivecwp_54@long_name="Total Cloud Water Path"
avgfivecwpdata_54=avg(meanfivecwp_54)
zonalmeanfivecwp_54=dim_avg(meanfivecwp_54)
zonalmeanclmr_54=dim_avg(meanclmr_54)
zonalmeanicmr_54=dim_avg(meanicmr_54)

;*************** End processing fifth model run scen **********************************

; *******Start Ploting Two Plots of CWP and IWP *********
wks = gsn_open_wks("png","Zonal_Mean_AllLuquidCWP_atmosphere_202001_Dy"+ldy+"_total.png")                      ; Need to change to your desired png name
wks2 = gsn_open_wks("png","Zonal_Mean_AllIceIWP_atmosphere_202001_Dy"+ldy+"_total.png")
  

; Read in Obs
obsfili = systemfunc("cd "+obsdir+" ; ls CERES_SYN1deg-Day_Terra-Aqua-MODIS_Ed4.1_Subset_20200101-20200131.nc") ; Need to change to your CERES data file name

; Sum up mid-high and mid-low to generate the mid level variables in Obs
viwpmidhigh="iwp_mid_high_daily"
vlwpmidhigh="lwp_mid_high_daily"
vlwpmidlow="lwp_mid_low_daily"
viwpmidlow="iwp_mid_low_daily"

a = addfiles(obsdir+obsfili,"r")
lwplow=a[:]->lwp_low_daily
iwplow=a[:]->iwp_low_daily
lwphigh=a[:]->lwp_high_daily
iwphigh=a[:]->iwp_high_daily
lwpmidhigh=a[:]->$vlwpmidhigh$
iwpmidhigh=a[:]->$viwpmidhigh$
lwpmidlow=a[:]->$vlwpmidlow$
iwpmidlow=a[:]->$viwpmidlow$

flashlwp=a[:]->lwp_total_daily
flashlwp@long_name="Cloud Parameters: Liquid Water Path"

flashiwp=a[:]->iwp_total_daily
flashiwp@long_name="Cloud Parameters: Ice Water Path"
meanflashlwp=dim_avg_n_Wrap(flashlwp(0:30:5,:,:),0)
meanflashiwp=dim_avg_n_Wrap(flashiwp(0:30:5,:,:),0)

avgflashlwpdata=avg(flashlwp)
avgflashiwpdata=avg(flashiwp)
difflwp=meanclmr
diffiwp=meanicmr
difflwp=meanclmr-avgflashlwpdata
diffiwp=meanicmr-avgflashiwpdata
avgdiffiwp=avg(diffiwp)
avgdifflwp=avg(difflwp)
zonalmeanflashlwp=dim_avg(meanflashlwp)
zonalmeanflashiwp=dim_avg(meanflashiwp)


zonalmeanflashtwocwp=zonalmeanflashlwp+zonalmeanflashiwp

; Ploting attributes

res                   = True

res@vpXF            = 0.2                          ; make plot bigger
res@vpYF            = 0.9        
res@vpWidthF        = 0.7
res@vpHeightF       = 0.4
res@pmLegendDisplayMode    = "Always"              ; turn on legend
 
res@pmLegendSide           = "Top"                 ; Change location of 
res@pmLegendParallelPosF   = .86                   ; move units right
res@pmLegendOrthogonalPosF = -0.52                 ; more neg = down
res@pmLegendWidthF         = 0.12                  ; Change width and
res@pmLegendHeightF        = 0.15                  ; height of legend.
res@lgLabelFontHeightF     = .012                  ; change font height
res@lgPerimOn              = False                 ; no box around

res@xyExplicitLegendLabels = (/"CERES","Exp_4","Exp_3","Exp_2","Exp_1","CCPP-based Control"/) ; Change the legends

res@tiMainString       = "Cloud Liquid Water Path 2020/01 daily mean"  
res@tiMainFontHeightF  = .020    
res@xyDashPatterns=0
res@tmYROn=False
res@tmXTOn=False
res@xyLineThicknesses = (/  4, 4,4, 4, 4,4/)         
res@xyLineColors      = (/"black","magenta","orange","blue","green","red"/)                    ; Change line colors
res@tmXTLabelsOn=False
res@tmYRLabelsOn=False

;Construct the data array for ploting
iwpdata=new((/6,dimsizes(icmr&lat)/),float)
iwpdata(0,:)=zonalmeanflashiwp(:)
iwpdata(1,:)=zonalmeanthreeIWP_54(:)
iwpdata(2,:)=zonalmeanthreeIWP_53(:)
iwpdata(3,:)=zonalmeanthreeIWP_52(:)
iwpdata(4,:)=zonalmeanthreeIWP_51(:)
iwpdata(5,:)=zonalmeanthreeIWP(:)

lwpdata=new((/6,dimsizes(clmr&lat)/),float)
lwpdata(0,:)=zonalmeanflashlwp(:)
lwpdata(1,:)=zonalmeantwoCWP_54(:)
lwpdata(2,:)=zonalmeantwoCWP_53(:)
lwpdata(3,:)=zonalmeantwoCWP_52(:)
lwpdata(4,:)=zonalmeantwoCWP_51(:)
lwpdata(5,:)=zonalmeantwoCWP(:)


res@tiYAxisString    = "LWP(g m~S~-2~N~)"    ; y-axis label  
res@tiXAxisString    = "Latitude"    ; x-axis label  
 
plot=gsn_csm_xy(wks,icmr&lat,lwpdata,res)

res2=res
res2@tiMainString       = "Cloud Ice Water Path 2020/01 daily mean"  
res2@tiYAxisString    = "IWP(g m~S~-2~N~)"    ; y-axis label  

plot2=gsn_csm_xy(wks2,clmr&lat,iwpdata,res2)
print(" var: Ice Water Path flashflux: "+avg(zonalmeanflashiwp)+" Dy05: "+avg(zonalmeanthreeIWP))
print(" var: Liquid Water Path flashflux: "+avg(zonalmeanflashlwp)+" Dy05: "+avg(zonalmeantwoCWP))

end
