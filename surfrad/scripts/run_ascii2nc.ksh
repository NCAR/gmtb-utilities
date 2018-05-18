#!/bin/ksh
#
# This script is for case studies.

# Path to base SURFRAD testing directory.
# This script assumes a particular directory structure:
# $base/surfrad/raw --> directory where raw SURFRAD data is stored
# $base/surfrad/proc --> directory where output from ascii2nc is put (directory is created in script)
# $base/scripts --> directory where run_ascii2nc.ksh is run
base=/scratch4/BMC/gmtb/harrold/test_surfrad

# Path to ascii2nc executable
ascii2nc=/scratch4/BMC/dtc/MET/MET_development/met/bin/ascii2nc

# Path to Ascii2NcConfig file
# For ASCII2NC iseage and information on the configuration files, please see:
# met-6.0/data/config/README
ascii2nc_config=/scratch4/BMC/gmtb/harrold/test_surfrad/scripts/met_config/Ascii2NcConfig

# SURFRAD station list
#stid_list="bon dra fpk gwn psu sxf tbl"     # Full list of SURFRAD stations
stid_list="dra"

# Specify grib code of desired radiation variable
# 204 = downward shortwave
# 205 = downward longwave
# 211 = upward shortwave
# 212 = upward longwave
grib_code=204

# Time step - time between intervals in seconds
time_step_sec=21600

# Provide desired time widths - time width of summary intervals in minutes
# Negative (positive) numbers indicate time prior (after) to time the summary is occurring
# The example below indicates to use a time window 6 hours prior to the time the summary is occurring
time_width_beg=-360
time_width_end=0

# Statistic for time summary
stat="median"
 
# Statistic type low value
stat_low="min"

# Statistic type high value
stat_high="max"

# List of initializations to process
init_list=2017092500

# Length of model forecast
fcst_length=120

# Start loop of specified intializations to process
for init in ${init_list}; do

  yyyy=`echo ${init} | cut -c1-4`
  yy=`echo ${init} | cut -c3-4`
  mm=`echo ${init} | cut -c5-6`
  dd=`echo ${init} | cut -c7-8`
  hh=`echo ${init} | cut -c9-10`

  doy=`date -ud ''${yyyy}-${mm}-${dd}' UTC '${hh}':00:00' +%j`
  init_s=`date -ud ''${yyyy}-${mm}-${dd}' UTC '${hh}':00:00' +%s`

  # Loop for specified SURFRAD stations to process
  for stid in ${stid_list}; do

    # Calculate the number SURFRAD files needed based on forecast hour length
    num_surf_files=$(( (${fcst_length} / 24) + 1 ))

    # Check it surfrad_file_list exists. If it does, remove it.
    surfrad_file_list=${base}/scripts/surf_file_list
    if [[ -f ${surfrad_file_list} ]]; then
      rm ${surfrad_file_list}
    fi

    # Generate name of each SURFRAD file and make file list to read into ascii2nc
    for file_seq_list in $(seq ${num_surf_files}); do
      for file_seq in ${file_seq_list}; do
        # Need to make zero based
        file_seq=$(( ${file_seq} - 1 ))
        day_sec=$(( ${file_seq} * 86400 ))
        file_sec=`expr ${init_s} + ${day_sec}`
        file_doy=`date -ud '1970-01-01 UTC '${file_sec}' seconds' +%j`

        # Build SURFRAD file name
        surfrad_file=${base}/surfrad/raw/${stid}/${stid}${yy}${file_doy}.dat
        if [[ -f ${surfrad_file} ]]; then
          echo ${surfrad_file} >> ${surfrad_file_list}
        else
          echo "SURFRAD FILE: ${surfrad_file} DOES NOT EXIST"
          exit
        fi
      done # Close file_seq loop
    done # Close file_seq_list loop

    # Reformat SURFRAD file list from vertical to horizontal (to be in proper format for ascii2nc arguements).
    surfrad_file_list=`cat ${surfrad_file_list} | tr '\n' ' '`

    # Convert time width from minutes to seconds
    time_width_beg_sec=$(( ${time_width_beg} * 60 ))
    time_width_end_sec=$(( ${time_width_end} * 60 ))

    # Export envinoment variables to be read into Ascii2NcConfig
    export time_step_sec
    export time_width_beg_sec
    export time_width_end_sec
    export stat
    export stat_low
    export stat_high
    export grib_code

    mkdir -p ${base}/surfrad/proc/${stid}
    nc_file=${base}/surfrad/proc/${stid}/${stid}_${init}_${grib_code}.nc

    # Run ascii2nc for each specified initialization, time width, and station
    echo "${ascii2nc} ${surfrad_file_list} ${nc_file} -format surfrad -config ${ascii2nc_config} -v 3"

    ${ascii2nc} ${surfrad_file_list} ${nc_file} -format surfrad -config ${ascii2nc_config} -v 3

  done # Close stid loop
done # Close initialization loop

