#####################################################################
#
# Tropical Cyclone Tracks (Python)
# Created by Man Zhang (Man.Zhang@noaa.gov)
#
# Version: 1.0
# 
# Description: This program uses a CSV containing date and time 
# , latitude , longitude , min. central pressure  and max. sustained
# winds to plot the tropical cyclone genesis
#
# Dependencies:
# Python: basemap, matplotlib, and numpy
#
"""
draw TC genesis tracks from storms that labels tc
"""
#####################################################################

from mpl_toolkits.basemap import Basemap
import matplotlib.pyplot as plt
import numpy as np
import time
import os,sys
import csv


# Get the cycle information from env vars
#moad_dataroot   =   os.getenv('MOAD_DATAROOT')
#rotdir          =   os.getenv('ROTDIR')
#start_time      =   os.getenv('START_TIME')     # @Y@m@d@H
#tc_id           =   os.getenv('tc_id') 
#tc_ct           =   os.getenv('tc_ct')
#exp1            =   os.getenv('EXP1')
#exp2            =   os.getenv('EXP2')


#print 'start_time:', start_time
HEM             ='NH'
YYYY            ='2017'
suitn           ='suite4'
expnm           =suitn+'_'+YYYY+'_'+HEM+'_tem1'
indir           =''.join(['./',expnm])

use_map         = 'np'  
outfile         =''.join([expnm,'_',use_map])
genfile         = 'gentimefinal'+YYYY+'_'+HEM+'.txt'

grid            ='on'				# lat/lon grid on or off?
prnt            ='on'                           # show plot?

fig = plt.figure(figsize=(11,8))

####################### Draw background map ######################################################

# setup Lambert conformal basemap
if use_map == 'full':
	print('Using Full Atlantic Basin Map')
	m = Basemap(width=7000000,height=7000000,projection='lcc',resolution='c',lat_0=25,lon_0=-40.)
elif use_map == 'global':
        print('Using Global Map for TC genesis')
        m = Basemap(projection='cyl',llcrnrlat= -3.,urcrnrlat= 36.,\
              resolution='c',  llcrnrlon=-181.,urcrnrlon=0.)
elif use_map == 'np':
        print('Using Global Map for TC genesis')
        m = Basemap(projection='npstere',boundinglat=0,lon_0=270,resolution='l')
elif use_map == 'sp':
        print('Using Global Map for TC genesis')
        m = Basemap(projection='spstere',boundinglat=0,lon_0=120,resolution='l')
elif use_map == 'west_global':
        print('Using Global Map for TC genesis')
        m = Basemap(llcrnrlon=0,llcrnrlat=-80,urcrnrlon=360,urcrnrlat=80,projection='mill')
        m = Basemap(projection='ortho',lat_0=30,lon_0=-90,resolution='l')
elif use_map == 'east_global':
        print('Using Global Map for TC genesis')
        m = Basemap(llcrnrlon=0,llcrnrlat=-80,urcrnrlon=360,urcrnrlat=80,projection='mill')
        m = Basemap(projection='ortho',lat_0=30,lon_0=100,resolution='l')
elif use_map == 'moll':
        print('Using Global Map for TC genesis')
        m = Basemap(projection='moll',lon_0=-90)
elif use_map == 'kav7':
        print('Using Global Map for TC genesis')
        m = Basemap(projection='kav7',lon_0=180,resolution=None)
elif use_map == 'gulf':
	print('Using Gulf of Mexico Map')
	m = Basemap(width=2000000,height=1600000,projection='lcc',resolution='c',lat_0=25, lon_0=-88.)
elif use_map == 'east_pacific':
        print('Using East Pacific Map')
        m = Basemap(width=10000000,height=5000000,projection='lcc',resolution='c',lat_0=16, lon_0=-100.)
elif use_map == 'west_pacific':
        print('Using West Pacific Map')
        m = Basemap(width=10000000,height=5000000,projection='lcc',resolution='c',lat_0=16, lon_0=120.)
elif use_map == 'carib':
	print('Using Caribbean Map')
        #m = Basemap(width=10000000,height=6000000,projection='lcc',resolution='c',lat_0= 30, lon_0=-70.)
        m = Basemap(projection='cyl',llcrnrlat= -5.,urcrnrlat= 60.,\
             resolution='c',  llcrnrlon=-100.,urcrnrlon=-15.)

elif use_map == 'east_coast':
	print('Using East Coast Map')
        m = Basemap(width=2200000,height=1200000,projection='lcc',resolution='c',lat_0=36, lon_0=-70.)
else:
	sys.exit('Please use either full, gulf, carib, or east_coast for your map!')

# draw the land-sea mask
print('Drawing map...')
#m.drawlsmask(land_color='peachpuff',ocean_color='azure',lakes='True')
m.drawlsmask(land_color='peachpuff',ocean_color='white',lakes='True')

# draw various boundaries
m.drawstates(color='white')
m.drawcountries(color='white')
#m.drawmeridians(np.arange(0,360,30))
#m.drawparallels(np.arange(-90,90,30))

# draw and label lat and lon grid
if grid == 'on':
	parallels = np.arange(-90.,90.,30.)
	meridians = np.arange(0.,360.,30.)
	m.drawparallels(parallels,labels=[1,1,0,0],color='gray')
	m.drawmeridians(meridians,labels=[0,0,0,1],color='gray')

# add shaded relief background
#m.bluemarble()
#m.shadedrelief()

##find location of gentime in BT
latb=[]
lonb=[]
i=0
with open(genfile) as f:
  for line in f:
      line = line.strip()
      columns= line.split()
      lat=float(columns[3])/10.
      #print lat
      latb.append(lat)
      #print columns[0]
      if columns[0] == "AL" or columns[0] == "EP" or columns[0] == "CP":
         lon=float(columns[4])*(-1.)/10.
      elif columns[0] == "WP" or columns[0] == "IO":
         lon=float(columns[4])/10.
      elif columns[0] == "SH":
         lon=float(columns[4])/10.
      lonb.append(lon)
      #print i, line
      i=i+1

# find names of storms that labels as 'TG'
n0=0   #FA
n1=0   #hit
n2=0   #LG
n3=0   #hit in a
lat=[]
lon=[]
lat0=[]
lon0=[]
lat1=[]
lon1=[]
lat2=[]
lon2=[]
lat3=[]
lon3=[]
for filename in os.listdir(indir):
   infile       ='/'.join([indir, filename])
   print ' '
   with open(infile) as f:
     for line in f:
          line    = line.strip()
          columns = line.split()
          lat=float(columns[3])
          lon=float(columns[4])
          if abs(int(columns[5])) == 2   :             # IT
             lat0.append(lat)
             lon0.append(lon)
             n0=n0+1
             print "IT", n0,columns
          elif int(columns[5]) == 1 :           #hit in bdeck 
             lat1.append(lat)
             lon1.append(lon)
             n1=n1+1
             print "HIT", n1, columns
          elif int(columns[5]) == -1:           #hit in adeck
             lat3.append(lat)
             lon3.append(lon)
             n3=n3+1
          elif abs(int(columns[5])) == 3 :     # FA
             lat2.append(lat)
             lon2.append(lon)
             n2=n2+1
             #print filename, n2, columns


xpt2, ypt2 = m(lon2, lat2)
m.plot(xpt2, ypt2, 'ro',markersize=12,markerfacecolor='red',markeredgecolor='white',mew=1.5, label=''.join(['FA(',str(n2),')']))

xpt1, ypt1 = m(lon1, lat1)
m.plot(xpt1, ypt1, 'go',markersize=12, markerfacecolor='green',markeredgecolor='white',mew=1.2,label=''.join(['HIT(',str(n1),')']) )

#xpt3, ypt3 = m(lon3, lat3)
#m.plot(xpt3, ypt3, 'bo',markersize=5, markerfacecolor='blue',markeredgecolor='blue',label=''.join(['HIT-a(',str(n3),')'])  )

xptb, yptb = m(lonb, latb)
m.plot(xptb, yptb, 'b*' ,markersize=10,markerfacecolor='none',markeredgecolor='black', mew=1., label=''.join(['BT(',str(i),')']))
#m.plot(xptb, yptb, 'b*' ,markersize=7, markerfacecolor=(0.3,0.3,0,0.5),markeredgecolor='none', mew=1.2, label=''.join(['BT(',str(i),')']))

xpt0, ypt0 = m(lon0, lat0)
m.plot(xpt0, ypt0, 'bs',markersize=10,markerfacecolor='blue',markeredgecolor='white',mew=1.2, label=''.join(['LG(',str(n0),')']))



title = YYYY+ '  '+ suitn +' '+use_map     
#title= 'COUNTS:   RSMC-named:'+ str(n1)+';   model-generated: '+str(n2)
print title
plt.legend(loc='upper center',bbox_to_anchor=(0.5, -0.05),  ncol=4)
plt.title(title)
#plt.xlabel(title2)

#plt.show()
art=[]
plt.savefig(outfile,orientation='landscape',additional_artists=art,bbox_inches='tight')
plt.show()
print('Great success!!!')


