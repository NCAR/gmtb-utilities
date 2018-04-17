#!/usr/bin/python

#####################################################################
# model_tc_gen_ver.py                                               #
#                                                                   #
# This script reads in TC genesis forecasts from the Marchok/GFDL   #
# tracker and verifies them against the ATCF b-decks and a-decks.   #
# It was designed for verification of AL and EP TCs, but can be     #
# modified to verify TC genesis forecasts in any basin.             #
#                                                                   #
# Created by Dan Halperin                  Last updated: 2017-03-20 #
# Contact: Daniel.Halperin@erau.edu                                 #
#####################################################################

#import necessary modules
import numpy as np
import pandas as pd
import datetime
import sys

#Set necessary input files (or provide on the command line as arguments)
bdeckgenfile = "/path/to/bdeck/genesis/file"
bdeckallfile = "/path/to/file/with/all/bdeck/entries"
adeckfile    = "/path/to/adeck/file/"
casesfile    = "/path/to/file/with/list/of/tracker/files"

def gen_ver(casesfile, adeckfile, bdeckgenfile, bdeckallfile):

  #Set path information
  indir     = "/path/to/input/directory/"
  outdir    = "/path/to/output/directory/"

  #Import data
  bdeckgen  = pd.read_csv(bdeckgenfile, header=None, delim_whitespace=True)
  bdeckall  = pd.read_csv(bdeckallfile, header=None, delim_whitespace=True)
  adeck     = pd.read_csv(adeckfile, header=None, sep=", ")
  cases     = np.loadtxt(casesfile,dtype='string')

  #Format bdeckgen information
  bdeckgen.ix[:,2] = pd.to_datetime(bdeckgen.ix[:,2],format="%Y%m%d%H")
  bdeckgen.ix[:,3] = bdeckgen.ix[:,3]/10.
  bdeckgen.ix[:,4] = bdeckgen.ix[:,4]/-10.

  #Format bdeckall information
  bdeckall.ix[:,2] = pd.to_datetime(bdeckall.ix[:,2],format="%Y%m%d%H")
  bdeckall.ix[:,3] = bdeckall.ix[:,3]/10.
  bdeckall.ix[:,4] = bdeckall.ix[:,4]/-10.

  #Format adeck information
  adeck.ix[:,2] = pd.to_datetime(adeck.ix[:,2],format="%Y%m%d%H")
  adeck         = adeck.loc[adeck.ix[:,3] == 0]
  adeck         = adeck.drop_duplicates()

  #Loop over all Marchok/GFDL tracker genesis files
  for case in range(len(cases)):
    tcfile  = indir+cases[case]
    tcinfo  = pd.read_csv(tcfile,sep=", ",header=None)
    geninfo = np.unique(tcinfo.ix[:,2])

    #Format model genesis forecast information
    for i in range(len(geninfo)):
        fhr      = int(geninfo[i][12:15])
        tclathem = geninfo[i][19]
        tclonhem = geninfo[i][25]

        #Only consider cases in the AL, EP, and CP basins
        #Can be modified to verify cases globally
        if fhr > 0 and tclathem == 'N' and tclonhem == 'W':
            tclat      = float(format(float(geninfo[i][16:19])/10, '.2f'))
            tclon      = float(format(float(geninfo[i][21:25])/-10, '.2f'))
            itime      = datetime.datetime.strptime(geninfo[i][0:10],'%Y%m%d%H')
            vtime      = itime + datetime.timedelta(hours=fhr)
            itimestamp = pd.to_datetime(itime)
            vtimestamp = pd.to_datetime(vtime)

            #Find entry in b-decks that matches forecast genesis valid time
            #and is with 5 deg lat/lon of forecast genesis location
            timematch  = np.where(vtimestamp == bdeckall.ix[:,2])
            latmatch   = np.where(abs(tclat - bdeckall.ix[:,3]) <= 5)
            lonmatch   = np.where(abs(tclon - bdeckall.ix[:,4]) <= 5)

            locmatch   = np.intersect1d(latmatch[0],lonmatch[0])
            matchrow   = np.intersect1d(timematch[0],locmatch)

            #If a match exists in the b-decks, determine whether genesis occurs in the 
            #b-decks within 5 days of the model initialization time            
            if np.shape(matchrow)[0] > 0:
                btnummatch = np.where(bdeckall.ix[matchrow[0],1] == bdeckgen.ix[:,1])
                btbasmatch = np.where(bdeckall.ix[matchrow[0],0] == bdeckgen.ix[:,0])
                btidmatch  = np.intersect1d(btnummatch[0],btbasmatch[0])

                if (bdeckgen.ix[btidmatch[0],2] - itimestamp).total_seconds()/(60*60*24) <= 5 and \
                   (bdeckgen.ix[btidmatch[0],2] - itimestamp).total_seconds()/(60*60*24) > 0:
                    y    = 1
                    btid = bdeckall.ix[matchrow[0],1]
                    bas  = bdeckall.ix[matchrow[0],0]

                if (bdeckgen.ix[btidmatch[0],2] - itimestamp).total_seconds()/(60*60*24) > 5:
                    y    = 0
                    btid = 0
                    bas  = bdeckall.ix[matchrow[0],0]

                if (bdeckgen.ix[btidmatch[0],2] - itimestamp).total_seconds()/(60*60*24) <= 0:
                    y    = 2
                    btid = 0
                    bas  = bdeckall.ix[matchrow[0],0]


            #If no match is found in the b-decks, repeat the above process for the a-decks
            if np.shape(matchrow)[0] == 0:
                timematch2 = np.where(vtimestamp == adeck.ix[:,2])
                latmatch2  = np.where(abs(tclat - adeck.ix[:,4]) <= 5)
                lonmatch2  = np.where(abs(tclon - adeck.ix[:,5]) <= 5)

                locmatch2  = np.intersect1d(latmatch2[0],lonmatch2[0])
                matchrow2  = np.intersect1d(timematch2[0],locmatch2)

                if np.shape(matchrow2)[0] > 0:
                    btnummatch2 = np.where(adeck.ix[matchrow2[0],1] == bdeckgen.ix[:,1])
                    btbasmatch2 = np.where(adeck.ix[matchrow2[0],0] == bdeckgen.ix[:,0])
                    btidmatch2  = np.intersect1d(btnummatch2[0],btbasmatch2[0])
 
                    if (bdeckgen.ix[btidmatch2[0],2] - itimestamp).total_seconds()/(60*60*24) <= 5 and \
                       (bdeckgen.ix[btidmatch2[0],2] - itimestamp).total_seconds()/(60*60*24) > 0:
                        y    = 1
                        btid = adeck.ix[matchrow2[0],1]
                        bas  = adeck.ix[matchrow2[0],0]                        

                    if (bdeckgen.ix[btidmatch2[0],2] - itimestamp).total_seconds()/(60*60*24) > 5:
                        y    = 0
                        btid = 0
                        bas  = adeck.ix[matchrow2[0],0]                        

                    if (bdeckgen.ix[btidmatch2[0],2] - itimestamp).total_seconds()/(60*60*24) <= 0:
                        y    = 2
                        btid = 0
                        bas  = adeck.ix[matchrow2[0],0]                        
    

                #If no match exists in the a-decks, the forecast genesis event is a false alarm
                if np.shape(matchrow2)[0] == 0:
                        y    = 0
                        btid = 0
                        bas  = "NA"

            #Only send cases to output where the init time is earlier than the b-deck genesis time
            if y != 2:
                outinfo = datetime.datetime.strftime(itimestamp, format="%Y%m%d%H") + " " + str(fhr) + " " + " " + \
                          datetime.datetime.strftime(vtimestamp, format="%Y%m%d%H") + " " + str(tclat) + " " + \
                          str(tclon) + " " + str(y) + " " + str(bas) + " " + str(btid).zfill(2)

                f = open(outdir+"out_"+cases[case]+".txt","a")
                f.write(outinfo+"\n")
                f.close()

#If file paths are passed as arguments on command line,
#override paths provided at top of script
if __name__ == '__main__':
    if len(sys.argv) > 4:
        casesfile    = sys.argv[1]
        adeckfile    = sys.argv[2]
        bdeckgenfile = sys.argv[3]
        bdeckallfile = sys.argv[4]

gen_ver(casesfile, adeckfile, bdeckgenfile, bdeckallfile)


sys.exit()
