#!/usr/bin/env python

#####################################################################
# model_tc_gen_ver.py                                               #
#                                                                   #
# This script reads in TC genesis forecasts from the Marchok/GFDL   #
# tracker and verifies them against the ATCF b-decks and a-decks.   #
# It was designed for verification of AL and EP TCs, but can be     #
# modified to verify TC genesis forecasts in any basin.             #
#                                                                   #
# Modified by Man Zhang @ GMTB                                      #
# make the original script compatiable on Theia and Jet             #
#                                                                   #
# Created by Dan Halperin                  Last updated: 2017-03-20 #
# Contact: Daniel.Halperin@noaa.gov                                 #
#####################################################################

#import necessary modules
import numpy as np
import pandas as pd
import datetime
import sys
import os
import shutil


#Set necessary input files (or provide on the command line as arguments)
YYYY         = "2016"
HEM          = "NH"
suitn        = "suite4"
print suitn, YYYY,HEM

bdeckgenfile = "./gentimefinal"+YYYY+"_"+HEM+".txt"
bdeckallfile = "./btallfinal"+YYYY+"_"+HEM+".txt"
adeckfile    = "./adecks.txt"
casesfile    = "list_cases_"+YYYY+".txt"

#define temporal tolerance
tmscale = 5        #default: 5 day
spscale = 5        #default: 5 degree

#Set path information
indir     = "./physdata/"+suitn+"/"
outdir    = "./"+suitn+"_"+YYYY+"_"+HEM+"_tem1/"

if os.path.exists(outdir):
   shutil.rmtree(outdir)
os.makedirs(outdir)



#Import data
bdeckgen  = pd.read_csv(bdeckgenfile, header=None, sep='\s+', engine='python')
bdeckall  = pd.read_csv(bdeckallfile, header=None, sep='\s+', engine='python')
adeck     = pd.read_csv(adeckfile, header=None, sep=", ", engine='python')
cases     = np.loadtxt(casesfile,dtype='string')

#Format bdeckgen information
bdeckgen.ix[:,2] = pd.to_datetime(bdeckgen.ix[:,2],format="%Y%m%d%H")


#Format bdeckall information
bdeckall.ix[:,2] = pd.to_datetime(bdeckall.ix[:,2],format="%Y%m%d%H")

bdeckall.ix[:,3] = bdeckall.ix[:,3]/10.
for jj in range(len(bdeckall.ix[:,2])):
  if bdeckall.ix[jj,0] == 'AL' or bdeckall.ix[jj,0] == 'EP' or bdeckall.ix[jj,0] == 'CP':
     bdeckall.ix[jj,4] = bdeckall.ix[jj,4]/-10.  
  elif bdeckall.ix[jj,0] == 'WP' or bdeckall.ix[jj,0] == 'IO':
     bdeckall.ix[jj,4] = bdeckall.ix[jj,4]/10.

#Format adeck information
#adeck.ix[:,2] = pd.to_datetime(adeck.ix[:,2],format="%Y%m%d%H")
#adeck         = adeck.loc[adeck.ix[:,3] == 0]
#adeck         = adeck.drop_duplicates()

adeck.ix[:,2] = pd.to_datetime(adeck.ix[:,2],format="%Y%m%d%H")


for kk in range(len(adeck.ix[:,2])):
  if adeck.ix[kk,0] == 'AL' or adeck.ix[kk,0] == 'EP' or adeck.ix[kk,0] == 'CP':
     #print kk, adeck.ix[kk,:]
     adeck.ix[kk,5] =adeck.ix[kk,5]/(-10.)
  elif adeck.ix[kk,0] == 'WP'  or adeck.ix[kk,0] == 'IO':
     adeck.ix[kk,5] =adeck.ix[kk,5]/10. 

#Loop over all Marchok/GFDL tracker genesis files
n=0      #hit
m=0      #FA
nm=0     #perfect 
mm=0
itotal=0
for case in range(len(cases)):
   print 
   print cases[case]
   bas0=[]
   btid0=[]
   geninfo1=[]
   geninfo2=[]
   geninfo3=[]
   geninfo4=[]
   tcfile  = indir+cases[case]+"/genesis.fort.66."+suitn+"."+cases[case]
   tcinfo  = pd.read_csv(tcfile,sep=", ",header=None, engine='python')

   #print len(tcinfo.ix[:,2])
   geninfo = np.unique(tcinfo.ix[:,2])
   #print len(geninfo)

   for i in range(len(geninfo)):
      #print geninfo[i],np.count_nonzero(tcinfo.ix[:,2] == geninfo[i])
      if np.count_nonzero(tcinfo.ix[:,2] == geninfo[i]) > 9:
         geninfo1.append(geninfo[i])

   print 'lifetime longer than 24h : ', len(geninfo1)

   #filering out TCgen make it to 34 for 24h or longer 
   for j in range(len(geninfo1)):
    ia=0
    for ij in range(len(tcinfo.ix[:,2])):
     if tcinfo.ix[ij,2] == geninfo1[j] and tcinfo.ix[ij,9] >= 34:
       ia=ia+1
       if ia >= 9:
         geninfo2.append(geninfo1[j])

   geninfo3 = np.unique(geninfo2)


   print ' also meet 34kt TC standard  ',len(geninfo3)


   #outfile_gen=outdir+"gen_"+cases[case]+".txt"
   for ik in range(len(geninfo3)):
    if int(geninfo3[ik][12:15]) >0 and int(geninfo3[ik][12:15]) <120  \
        and  geninfo3[ik][19] == "N":
       geninfo4.append(geninfo3[ik])
   #outinfo_gen=str(geninfo5)
   #fg = open(outfile_gen,"a")
   #fg.write(outinfo_gen+"\n")

   itotal=itotal+len(geninfo4)
   print ' valid TCgen event number:  ',len(geninfo4) 


   outfile=outdir+"out_"+cases[case]+".txt"
   if os.path.isfile(outfile):
        os.remove(outfile)

   #zhang: identify all possible HITs : all observed TG taking place between 0-120h after ini 
   ctime = datetime.datetime.strptime(cases[case],'%Y%m%d%H')
   #print ctime
   for j in range(len(bdeckgen.ix[:,1])) :
        if (bdeckgen.ix[j,2] - pd.to_datetime(ctime)).total_seconds()/(60*60*24) <= tmscale and \
           (bdeckgen.ix[j,2] - pd.to_datetime(ctime)).total_seconds()/(60*60*24) > 0:
           nm=nm+1
           print nm,'perfect: ',bdeckgen.ix[j,0],bdeckgen.ix[j,1],bdeckgen.ix[j,2]


    #Format model genesis forecast information
   for i in range(len(geninfo4)):

      fhr      = int(geninfo4[i][12:15])
      tclathem = geninfo4[i][19]
      tclonhem = geninfo4[i][25]

      #consider cases in the north Hemisphere: AL, EP, WP, and CP, IO
      #if fhr > 0 and tclathem == 'N' :
      if fhr > 0 and fhr < 120 and tclathem == 'N' :
        itime      = datetime.datetime.strptime(geninfo4[i][0:10],'%Y%m%d%H')
        # vtime is the model TG initial time 
        vtime      = itime + datetime.timedelta(hours=fhr)
        itimestamp = pd.to_datetime(itime)
        vtimestamp = pd.to_datetime(vtime)
#        if tclathem == 'N':
        tclat      = float(format(float(geninfo4[i][16:19])/10, '.2f'))
#        elif tclathem == 'S':
#           tclat      = float(format(float(geninfo4[i][16:19])/-10, '.2f'))
        if tclonhem == 'W':
           tclon      = float(format(float(geninfo4[i][21:25])/-10, '.2f'))
        elif tclonhem == 'E':
           tclon      = float(format(float(geninfo4[i][21:25])/10, '.2f'))

        #Find entry in b-decks that matches forecast genesis valid time
        #and is with 5 deg lat/lon of forecast genesis location
        timematch  = np.where(vtimestamp == bdeckall.ix[:,2])  #fcst genesis valid time match
        latmatch   = np.where(abs(tclat - bdeckall.ix[:,3]) <= spscale)
        lonmatch   = np.where(abs(tclon - bdeckall.ix[:,4]) <= spscale)

        locmatch   = np.intersect1d(latmatch[0],lonmatch[0])
        matchrow   = np.intersect1d(timematch[0],locmatch)

        #If a match exists in the b-decks, determine whether genesis occurs in the 
        #b-decks within 5 days of the model initialization time            
        if np.shape(matchrow)[0] > 0:     # how many rows zhang
              decktag='b'
              for i in range(0,np.shape(matchrow)[0],1):
                for j in range(len(bdeckgen.ix[:,1])) :
                    if bdeckgen.ix[j,1] ==bdeckall.ix[matchrow[i],1] and bdeckgen.ix[j,0] == bdeckall.ix[matchrow[i],0]:
                       if (bdeckgen.ix[j,2] - itimestamp).total_seconds()/(60*60*24) <= tmscale and \
                          (bdeckgen.ix[j,2] - itimestamp).total_seconds()/(60*60*24) > 0:
                           y    = 1        # hit
                           btid = bdeckall.ix[matchrow[i],1]
                           bas  = bdeckall.ix[matchrow[i],0]
                           n=n+1
                           #print n,'hit(b):',bas,btid,bdeckall.ix[matchrow[i],2],abs(tclat - bdeckall.ix[matchrow[i],3]), abs(tclon - bdeckall.ix[matchrow[i],4])
                           # Find the model HIT location in geninfo
                           print n,'hit(b):', bas,btid,bdeckall.ix[matchrow[i],2], tclat,tclon
                       elif (bdeckgen.ix[j,2] - itimestamp).total_seconds()/(60*60*24) > tmscale:
                           y    = 3        #  False Alarm
                           btid = bdeckall.ix[matchrow[i],1]
                           bas  = bdeckall.ix[matchrow[i],0]
                           #print cases[case]
                           mm=mm+1
                           print m,'FA(b):',bas,btid,bdeckall.ix[matchrow[i],2],tclat,tclon

                       elif (bdeckgen.ix[j,2] - itimestamp).total_seconds()/(60*60*24) <= 0  and \
                            (itimestamp - bdeckgen.ix[j,2]).total_seconds()/(60*60*24) <= 3 :
                           y    = 2        #  LG 
                           #btid = 0
                           btid = bdeckall.ix[matchrow[i],1]
                           bas  = bdeckall.ix[matchrow[i],0]
                           m=m+1
                           print m,'IT:',bas,btid,bdeckgen.ix[j,2],itimestamp
 
                       else:
                     
                           y    = -3           #zhang discard 
                           btid = 0
                           bas  = "NA"
                           mm=mm+1
                           print mm,'FA(too late):',geninfo4[i],tclat,tclon 


                       outinfo = datetime.datetime.strftime(itimestamp, format="%Y%m%d%H") + " " + str(fhr) + " " + " " + \
                          datetime.datetime.strftime(vtimestamp, format="%Y%m%d%H") + " " + str(tclat) + " " + \
                          str(tclon) + " " + str(y) + " " + str(bas) + " " + str(btid).zfill(2) + "  " + \
                          decktag
                       f = open(outfile,"a")
                       f.write(outinfo+"\n")
                  

                       
                       #print outinfo

        #If no match is found in the b-decks, repeat the above process for the a-decks
        #elif np.shape(matchrow)[0] == 0:
                
               # timematch2 = np.where(vtimestamp == adeck.ix[:,2])
               # latmatch2  = np.where(abs(tclat - adeck.ix[:,4]) <= spscale)
               # lonmatch2  = np.where(abs(tclon - adeck.ix[:,5]) <= spscale)

               # locmatch2  = np.intersect1d(latmatch2[0],lonmatch2[0])
               # matchrow2  = np.intersect1d(timematch2[0],locmatch2)

               # if np.shape(matchrow2)[0] > 0:
               #     decktag='a'
               #     for  ii in range(0,np.shape(matchrow2)[0],1):
               #       for k in range(len(bdeckgen.ix[:,1])) :
               #         if adeck.ix[matchrow2[ii],3] == 0 and  \
               #           bdeckgen.ix[k,1] == adeck.ix[matchrow2[ii],1] and bdeckgen.ix[k,0] == adeck.ix[matchrow2[ii],0]:
               #           if (bdeckgen.ix[k,2] - itimestamp).total_seconds()/(60*60*24) <= tmscale and \
               #              (bdeckgen.ix[k,2] - itimestamp).total_seconds()/(60*60*24) >0:
               #              y    = -1          #hit
               #              btid = adeck.ix[matchrow2[ii],1]
               #              bas  = adeck.ix[matchrow2[ii],0]                        
               #              #print cases[case]
               #              #n=n+1
               #              print 'hit(a):',bas,btid


               #           elif (bdeckgen.ix[k,2] - itimestamp).total_seconds()/(60*60*24) > tmscale:
               #              y    = -2        #False Alarm
               #              btid = adeck.ix[matchrow2[ii],1]
               #              bas  = adeck.ix[matchrow2[ii],0]                        
               #              #print cases[case]
               #              #m=m+1
               #              print 'FA(a):',bas,btid

               #           elif (bdeckgen.ix[k,2] - itimestamp).total_seconds()/(60*60*24) <= 0:
               #              y    = -3        # DISCARD
               #              btid = adeck.ix[matchrow2[ii],1]
               #              bas  = adeck.ix[matchrow2[ii],0]                        
               #              #print 'DISCARD(a):',bas,btid

                          #outinfo = datetime.datetime.strftime(itimestamp, format="%Y%m%d%H") + " " + str(fhr) + " " + " " + \
                          #      datetime.datetime.strftime(vtimestamp, format="%Y%m%d%H") + " " + str(tclat) + " " + \
                          #      str(tclon) + " " + str(y) + " " + str(bas) + " " + str(btid).zfill(2) + "  " + \
                          #      decktag

                          #print outinfo
                          #f = open(outfile,"a")
                          #f.write(outinfo+"\n")

    

               #If no match exists in the a-decks, the forecast genesis event is a false alarm
               # elif np.shape(matchrow2)[0] == 0:
       
        #If no match exists in the b-decks, the forecast genesis event is a false alarm
        elif np.shape(matchrow)[0] == 0:
               decktag='F'
               y    = -3           #zhang discard 
               btid = 0
               bas  = "NA"
               mm=mm+1
               #print mm,'FA(NA):',geninfo4,tclat,tclon 


               outinfo = datetime.datetime.strftime(itimestamp, format="%Y%m%d%H") + " " + str(fhr) + " " + " " + \
                         datetime.datetime.strftime(vtimestamp, format="%Y%m%d%H") + " " + str(tclat) + " " + \
                         str(tclon) + " " + str(y) + " " + str(bas) + " " + str(btid).zfill(2) + "  " + \
                         decktag
               

               f = open(outfile,"a")
               f.write(outinfo+"\n")
               f.close()
               #print outinfo

    #print bas0
    #print btid0
    #print 
    #if n != 0 or nm!=0:
    # fr=float(nm)/float(n+nm)
    # #pod=float(n)/float(n+nm)
    # sr=1-fr
print 'perfect,hit,IT, FA,itotal = ',nm, n,m,mm,itotal
#f.close()


sys.exit()
