#!/bin/ksh

##########################################################################
#
# Script Name: run_point_stat_06h.ksh
#
# Date: 1/4/2019
#
# Description:
#    This script runs the MET Point-Stat tool to verify gridded output
#    using point observations (SURFRAD processed by ASCII2NC).
#
#    This script assumes the output data directory (DATA_ROOT) contains
#    a postprd directory, which is the location of post-processed data.
#    In this script a metprd directory is created under the DATA_ROOT;
#    this directory contains the MET output.  This directory structure
#    can be modified by the user to accommodate their setup.
#
##########################################################################

module use /glade/p/ral/jntp/MET/MET_releases/modulefiles
module load met/8.0

# Name of this script
SCRIPT=run_point_stat_06h.ksh

# Constants
BASE=/gpfs/fs1/p/ral/jntp/GMTB                             # path to base/top-level directory
SCRIPTS=${BASE}/scripts                                    # path to scripts
OBS_DIR=${BASE}/data/surfrad/proc                          # path to OBS data
LOG_DIR=${SCRIPTS}/log/met                                 # path to log dir

MET_EXE_ROOT=/gpfs/fs1/p/ral/jntp/MET/MET_releases/8.0/bin       # path to MET/bin directory 

# List which configs to run
SUITE_LIST="suite1 suite2 suite3 suite4"

# The full set of forecast hours to evaluate
FCST_TIME_LIST="006 012 018 024 030 036 042 048 \
                054 060 066 072 078 084 090 096 \
                102 108 114 120 126 132 138 144 \
                150 156 162 168 174 180 186 192 \
                198 204 210 216 222 228 234 240"

# The full set of time windows to evaluate
TW_LIST="21600"
TW_HHMMSS="060000"

# The full set of SURFRAD stations to evaluate
STID_LIST="bon dra fpk gwn psu sxf tbl"

# Variable to verify
GRIB="204"   # Downward shortwave

if [[ ${GRIB} == "204" ]]; then
    VAR="dswrf"
elif [[ ${GRIB} == "211" ]]; then
    VAR="uswrf"
elif [[ ${GRIB} == "205" ]]; then
    VAR="dlwrf"
elif [[ ${GRIB} == "212" ]]; then
    VAR="ulwrf" 
fi

# Specify the MET Point-Stat configuration files to be used
CONFIG_SURF_MEDIAN="${SCRIPTS}/met_config/PointStatConfig_SRAD_MEDIAN"

# Loop through configs
for SUITE in ${SUITE_LIST}; do

  # Loop through the inits
  for INIT_PATH in ${BASE}/Phys_Test_FV3GFSv2/POST/${SUITE}/2*; do

    YYYYMMDDHH=`echo ${INIT_PATH} | cut -d"/" -f11`

    # Go to working directory
    workdir=${BASE}/Phys_Test_FV3GFSv2/METVX/${SUITE}/${YYYYMMDDHH}/metprd
    mkdir -p ${workdir}
    cd ${workdir}

    # Loop through the SURFRAD stations
    for STID in ${STID_LIST}; do
    
      if [[ ${STID} == "bon" ]]; then
        SID="Bondville"
      elif [[ ${STID} == "dra" ]]; then
        SID="Desert_Rock"
      elif [[ ${STID} == "fpk" ]]; then
        SID="Fort_Peck"
      elif [[ ${STID} == "gwn" ]]; then
        SID="Goodwin_Creek" 
      elif [[ ${STID} == "sxf" ]]; then
        SID="Sioux_Falls"
      elif [[ ${STID} == "tbl" ]]; then
        SID="Table_Mountain"
      elif [[ ${STID} == "psu" ]]; then
        SID="Penn_State"
      else
        echo "Improper ${STID}!"
        exit
      fi

      # Loop through the time windows
      for TW in ${TW_LIST}; do

        # Loop through the forecast times
        for FCST_TIME in ${FCST_TIME_LIST}; do

          # Compute the verification date
          FCST_TIME_SEC=`expr ${FCST_TIME} \* 3600` # convert forecast lead hour to seconds
          YYYY=`echo ${YYYYMMDDHH} | cut -c1-4`  # year (YYYY) of initialization time
          MM=`echo ${YYYYMMDDHH} | cut -c5-6`    # month (MM) of initialization time
          DD=`echo ${YYYYMMDDHH} | cut -c7-8`    # day (DD) of initialization time
          HH=`echo ${YYYYMMDDHH} | cut -c9-10`   # hour (HH) of initialization time
          START_DATE_UT=`date -ud ''${YYYY}-${MM}-${DD}' UTC '${HH}':00:00' +%s` # convert initialization time to universal time
          VDATE_UT=`expr ${START_DATE_UT} + ${FCST_TIME_SEC}` # calculate current forecast time in universal time
          VDATE=`date -ud '1970-01-01 UTC '${VDATE_UT}' seconds' +%Y%m%d%H` # convert universal time to standard time
          VYYYYMMDD=`echo ${VDATE} | cut -c1-8`  # forecast time (YYYYMMDD)
          VHH=`echo ${VDATE} | cut -c9-10`       # forecast hour (HH)
          echo 'valid time for ' ${FCST_TIME} 'h forecast = ' ${VDATE}

          # Get the forecast to verify
          FCST_FILE=${BASE}/Phys_Test_FV3GFSv2/POST/${SUITE}/${YYYYMMDDHH}/gfs.t${HH}z.pgrb2.0p25.f${FCST_TIME}
          if [ ! -e ${FCST_FILE} ]; then
            echo "WARNING: Could not find UPP output file: ${FCST_FILE}"
            continue 
          fi

          # Get the observation file
          OBS_FILE=`ls -1 ${OBS_DIR}/${STID}/${STID}_${YYYYMMDDHH}_${GRIB}.nc`

          if [ ! -e ${OBS_FILE} ]; then
            echo "WARNING: Could not find observation file: ${OBS_FILE}"
            continue
          fi

#          TW_REM_HH=$((${TW}/60))
#          TW_HH=${TW_REM_HH}
#          typeset -Z2 TW_HH
#          TW_REM_MM=$((${TW}%60))
#          TW_MM=${TW_REM_MM}
#          typeset -Z2 TW_MM
#          TW_SS="00"

#          TW_HHMMSS="030000"
#          typeset -Z2 TW_FORMAT

           echo "MESSAGE TYPE: ${TW_HHMMSS}"

          #######################################################################
          #
          #  Run Point-Stat
          #
          #######################################################################

          export FCST_TIME
          export TW_HHMMSS
          export STID
          export SID
          export SUITE
	  export VAR

          # Verify surface variables for each forecast hour
          CONFIG_FILE=${CONFIG_SURF_MEDIAN}

          echo "CALLING: ${MET_EXE_ROOT}/point_stat ${FCST_FILE} ${OBS_FILE} ${CONFIG_FILE} -outdir . -v 3"

          ${MET_EXE_ROOT}/point_stat ${FCST_FILE} ${OBS_FILE} ${CONFIG_FILE} \
            -outdir . -v 3 

          error=$?
          if [ ${error} -ne 0 ]; then
            echo "WARNING: For ${MODEL}, ${MET_EXE_ROOT}/point_stat ${CONFIG_FILE} crashed  Exit status: ${error}"
            continue
          fi

        done # FCST HR
   
      done # TW
   
    done # STID

  done # INIT
  
done # SUITE 

##########################################################################

echo "${SCRIPT} completed at `date`"

exit 0

