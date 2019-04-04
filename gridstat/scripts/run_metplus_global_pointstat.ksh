#!/bin/ksh

##########################################################################
#
# Script Name: run_metplus.ksh
#
# Description: 
# This script...
#
# START_TIME = The cycle time to use for the initial time.
# 
##########################################################################

# Make sure we give other group members write access to the files we create
umask 002

MKDIR=/bin/mkdir
ECHO=/bin/echo
CUT=`which cut`
DATE=/bin/date
    
source /apps/lmod/lmod/init/sh
module purge
module load contrib
module load anaconda
module use /lfs1/projects/dtc-hurr/MET/MET_releases/modulefiles
module load met/8.0
module load nco
module load wgrib2

export METPLUS_PATH=/mnt/lfs3/projects/hfv3gfs/GMTB/met_workflow/METplus/METplus-2.0.4
export MET_PATH=/mnt/lfs1/projects/dtc-hurr/MET/MET_releases/8.0
export JLOGFILE=/mnt/lfs3/projects/hfv3gfs/GMTB/met_workflow/METplus/logs/metplus_jlogfile
export PYTHONPATH=${METPLUS_PATH}/ush:${METPLUS_PATH}/parm
export PATH=${PATH}:${METPLUS_PATH}/ush:.

# Vars used for manual testing of the script
export PROJ_DIR=/mnt/lfs3/projects/hfv3gfs/GMTB
export OUTPUT_BASE=${PROJ_DIR}/METVX
export TMP_DIR=${OUTPUT_BASE}/tmp
export METPLUS_CONFIG_DIR=${PROJ_DIR}/met_workflow/config/metplus
export SUITE=suite1
export BEG_DATE=20160101 # Start time YYYYMMDD
export END_DATE=20171231 # End time YYYYMMDD
export FCST_INTERVAL=12
export FCST_MAX_FORECAST=240
export RES=0p25
export GRID_VX=NONE
export FCST_POINT_STAT_INPUT_DIR=${PROJ_DIR}/Phys_Test_FV3GFSv2/POST/${SUITE}
export OBS_POINT_STAT_INPUT_DIR=${PROJ_DIR}/vx_data/prepbufr

# Print run paramenters
${ECHO}
${ECHO} "run_metplus.ksh started at `${DATE}`"
${ECHO}
${ECHO} "    PROJ_DIR                   = ${PROJ_DIR}"
${ECHO} "    OUTPUT_BASE                = ${OUTPUT_BASE}"
${ECHO} "    TMP_DIR                    = ${TMP_DIR}"
${ECHO} "    MET_INSTALL_DIR            = ${MET_PATH}"
${ECHO} "    METPLUS_CONFIG_DIR         = ${METPLUS_CONFIG_DIR}"
${ECHO} "    SUITE                      = ${SUITE}"
${ECHO} "    BEG_DATE                   = ${BEG_DATE}"
${ECHO} "    END_DATE                   = ${END_DATE}"
${ECHO} "    FCST_INTERVAL              = ${FCST_INTERVAL}"
${ECHO} "    FCST_MAX_FORECAST          = ${FCST_MAX_FORECAST}"
${ECHO} "    RES                        = ${RES}"
${ECHO} "    GRID_VX                    = ${GRID_VX}"
${ECHO} "    FCST_POINT_STAT_INPUT_DIR   = ${FCST_POINT_STAT_INPUT_DIR}"
${ECHO} "    OBS_POINT_STAT_INPUT_DIR    = ${OBS_POINT_STAT_INPUT_DIR}"

# Check for exisitance of post files?

# Go to working directory
workdir=${OUTPUT_BASE}/${SUITE}
${MKDIR} -p ${workdir}
${MKDIR} -p ${workdir}/config
cd ${workdir}

# Config file for grid_stat
POINTSTAT_CONFIG=pointstat_ua_gmtb.conf

# Update METplus config file with information
cat ${METPLUS_CONFIG_DIR}/${POINTSTAT_CONFIG} | sed s:_PROJ_DIR_:${PROJ_DIR}:g      \
                         | sed s:_METPLUS_PATH_:${METPLUS_PATH}:g                 \
                         | sed s:_OUTPUT_BASE_:${workdir}:g                       \
                         | sed s:_MET_INSTALL_DIR_:${MET_PATH}:g                  \
                         | sed s:_TMP_DIR_:${TMP_DIR}:g                           \
                         | sed s:_FCST_POINT_STAT_INPUT_DIR_:${FCST_POINT_STAT_INPUT_DIR}:g \
                         | sed s:_OBS_POINT_STAT_INPUT_DIR_:${OBS_POINT_STAT_INPUT_DIR}:g   \
                         | sed s:_BEG_DATE_:${BEG_DATE}:g                         \
                         | sed s:_END_DATE_:${BEG_DATE}:g                         \
                         | sed s:_FCST_MAX_FORECAST_:${FCST_MAX_FORECAST}:g       \
                         | sed s:_FCST_INTERVAL_:${FCST_INTERVAL}:g     \
                         | sed s:_RES_:${RES}:g                                   \
                         | sed s:_GRID_VX_:${GRID_VX}:g                           \
                         | sed s:_SUITE_:${SUITE}:g                  > ${workdir}/config/${POINTSTAT_CONFIG}


${METPLUS_PATH}/ush/master_metplus.py -c ${workdir}/config/${POINTSTAT_CONFIG}

error=$?
if [ ${error} -ne 0 ]; then
    ${ECHO} "ERROR: run_metplus_global.ksh crashed for ${SUITE}. Exit status: ${error}"
    exit ${error}
fi

##########################################################################

${ECHO} "run_metplus_global.ksh completed at `${DATE}`"

exit 0
