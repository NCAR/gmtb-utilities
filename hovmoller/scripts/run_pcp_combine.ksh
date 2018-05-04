#!/bin/ksh -l

# This script pre-processes CMORPH data in NetCDF format and model output in GRIB2 format in order to read it into plot_hovmoller.ncl. Using the MET pcp-combine tool, CMORPH and model data are output in NetCDF format in user-specified accumulations. Note that only accumulation times of 06-h and 24-h have been tested. The end output that is read into plot_hovmoller.ncl is one NetCDF file with forecast precipitation for a desired time period or one NetCDF file with the corresponding observations.

# Path to base Hovmoller testing base directory
# Note, this script assumes a particular directory structure:
# $base/scripts --> directory where met_pcpi_combine.ksh is run
base=/scratch4/BMC/gmtb/harrold/test_hovmoller
script=$base/scripts/met_pcp_combine.ksh

# If on Theia, simply load the necessary following modules:
module load met/6.1
export LD_LIBRARY_PATH=/scratch4/BMC/dtc/MET/external_libs_intel/lib:${LD_LIBRARY_PATH}
module load nco
module load cdo

# If on another machine, you will need to have a compilation of MET and access to NCO and CDO tools
#met_exe_root=/scratch4/BMC/gmtb/MET/met-6.1/bin

# Initialization to process (yyyymmddhh)
init_time_start="2016060200"
init_time_end="2016061100"
init_inc="86400"

# List of forecast lead times to process (hh)
fcst_time_list="24"

# Desired output accumulation time to use in plotting (hh)
accum_time="06"

# Accumulation bucket for input model output (hh)
model_bucket="06" 

# Accumulation bucket for input CMORPH analyses (hh)
obs_bucket="01" 

# Name of observation type
obtype="cmorph"

# Name and level information in CMORPH file (included to make pcp-combine arguement list more straightforward)
field='name="CMORPH";level="(0,*,*)";'

# Directory where hourly CMORPH data is located
raw_obs="/scratch4/BMC/gmtb/data/vx_data/${obtype}/PROC_01h"

# Directory where model output data is located
fcst_data="/scratch4/BMC/gmtb/harrold/test_ceres/gf"

# Directory where CMORPH output from pcp-combine is located
pcp_combine_obs_dir="/scratch4/BMC/gmtb/harrold/test_hovmoller/${obtype}/bucket_${accum_time}h"

# Directory where CMORPH output from CDO/NCO commands is located
pcp_combine_obs_proc="/scratch4/BMC/gmtb/harrold/test_hovmoller/${obtype}/proc"

# Handle converting start and end initializations to UT
init_start_yyyy=`echo ${init_time_start} | cut -c1-4`  # year (yyyy) of initialization time
init_start_mm=`echo ${init_time_start} | cut -c5-6`    # month (mm) of initialization time
init_start_dd=`echo ${init_time_start} | cut -c7-8`    # day (dd) of initialization time
init_start_hh=`echo ${init_time_start} | cut -c9-10`   # hour (hh) of initialization time
init_start_ut=`date -u -d ''${init_start_yyyy}-${init_start_mm}-${init_start_dd}' UTC '${init_start_hh}':00:00' +%s` # convert initialization time to universal time

init_end_yyyy=`echo ${init_time_end} | cut -c1-4`  # year (yyyy) of initialization time
init_end_mm=`echo ${init_time_end} | cut -c5-6`    # month (mm) of initialization time
init_end_dd=`echo ${init_time_end} | cut -c7-8`    # day (dd) of initialization time
init_end_hh=`echo ${init_time_end} | cut -c9-10`   # hour (hh) of initialization time
init_end_ut=`date -u -d ''${init_end_yyyy}-${init_end_mm}-${init_end_dd}' UTC '${init_end_hh}':00:00' +%s` # convert initialization time to universal time

init_cur_ut=${init_start_ut}
# Loop through all of the init times to be run through pcp-combine on forecast and observation data
while [[ ${init_cur_ut} -le ${init_end_ut} ]]; do

  # Convert to initialization in UT to yyyymmddhh time string
  init=`date -ud '1970-01-01 UTC '${init_cur_ut}' seconds' +%Y%m%d%H`
  yyyy=`echo ${init} | cut -c1-4`  # year (yyyy) of initialization time
  mm=`echo ${init} | cut -c5-6`    # month (mm) of initialization time
  dd=`echo ${init} | cut -c7-8`    # day (dd) of initialization time
  hh=`echo ${init} | cut -c9-10`   # hour (hh) of initialization time

  # Start forecast hour loop
  for fcst_time in ${fcst_time_list}; do

    # Compute the verification date
    fcst_time_sec=`expr ${fcst_time} \* 3600` # convert forecast lead hour to seconds
    vdate_ut=`expr ${init_cur_ut} + ${fcst_time_sec}` # calculate current forecast time in universal time
    vdate=`date -ud '1970-01-01 UTC '${vdate_ut}' seconds' +%Y%m%d%H` # convert universal time to standard time
    vyyyymmdd=`echo ${vdate} | cut -c1-8`  # forecast time (yyyymmdd)
    vyyyy=`echo ${vdate} | cut -c1-4`  # forecast time (yyyy)
    vhh=`echo ${vdate} | cut -c9-10`       # forecast hour (hh)
    echo 'valid time for ' ${fcst_time} 'h forecast = ' ${vdate}
    
    pvdate_ut=`expr ${vdate_ut} - 86400` # calculate previous day (-24h) in universal time
    pvdate=`date -ud '1970-01-01 UTC '${pvdate_ut}' seconds' +%Y%m%d%H` # convert universal time to standard time
    pvyyyymmdd=`echo ${pvdate} | cut -c1-8`  # previous forecast time in standard time (yyyymmdd)
    
    #### CMORPH observation processing steps ####  

    # Check if the necessary CMORPH directories exist based on the valid time
    raw_obs_dir=${raw_obs}/${vyyyymmdd}
    if [ ! -e ${raw_obs_dir} ]; then
        echo "ERROR: ${raw_obs_dir} does not exist!"
        exit 1
    fi
    prev_raw_obs_dir=${raw_obs}/${pvyyyymmdd}
    if [ ! -e ${prev_raw_obs_dir} ]; then
        echo "ERROR: ${prev_raw_obs_dir} does not exist!"
        exit 1
    fi

    # Make output directory for pcp-combine obs output
    mkdir -p ${pcp_combine_obs_dir}/${vyyyymmdd}

    # Create obs file to be created by pcp-combine
    obs_file=${pcp_combine_obs_dir}/${vyyyymmdd}/${obtype}_${vyyyymmdd}_${vhh}0000_${accum_time}h.nc

    # Set up arguments to sum 1-hrly files into appropriate accumulation time
    export field # NetCDF field info
    pcp_combine_args="-sum 00000000_000000 ${obs_bucket} ${vyyyymmdd}_${vhh}0000 ${accum_time} -pcpdir ${raw_obs_dir} -pcpdir ${prev_raw_obs_dir} -field '${field}' -name "APCP_${accum_time}" ${obs_file}"

    # Run pcp_combine on hourly CMORPH observations to make appropriate accumulation times
    echo "pcp_combine ${pcp_combine_args}"
    pcp_combine ${pcp_combine_args}

    # If you are not running on Theia (or another platform that has MET as a built in module), uncomment below and comment the corresponding calls above
    #echo "${met_exe_root}/pcp_combine ${pcp_combine_args}"
    #${met_exe_root}/pcp_combine ${pcp_combine_args}

    # Add a variable 'time' to the pcp_combine NetCDF output using ncap; this is for plotting purposes
    # Make obs output directory for pcp-combine output that has been processed with ncap command
    mkdir -p ${pcp_combine_obs_proc}/time/${vyyyymmdd}

    # Create obs file to be created as output from ncap command
    obs_file_time=${pcp_combine_obs_proc}/time/${vyyyymmdd}/${obtype}_${vyyyymmdd}.nc

    # Create and run command to add time array
    ncap_obs_command="defdim(\"time\",1);time[time]=${vyyyymmdd}${vhh};time@long_name=\"Time\";"
    echo "ncap2 -s ${ncap_obs_command} ${obs_file} -O ${obs_file_time}"
    ncap2 -s ${ncap_obs_command} ${obs_file} -O ${obs_file_time}


    #### Model output processing steps ####
    # Check if the necessary model output directory exists based on the initialization time
    fcst_grib_file_dir=${fcst_data}/${init}
    if [ ! -e ${fcst_grib_file_dir} ]; then
      echo "ERROR: ${fcst_grib_file_dir} does not exist!"
      exit 1
    fi

    # Directory where model output from pcp-combine is located
    pcp_combine_fcst_dir="${base}/gf/pcp_combine"

    # Make output directory for pcp-combine model output
    mkdir -p ${pcp_combine_fcst_dir}

    # Create fcst file to be created by pcp-combine
    fcst_file=${pcp_combine_fcst_dir}/f${fcst_time}.gfs.${init}_${accum_time}h.nc 

    # Run pcp_combine on model output to make appropriate accumulation times
    echo "pcp_combine -sum ${yyyy}${mm}${dd}_${hh}0000 ${model_bucket} ${vyyyymmdd}_${vhh}0000 ${accum_time} -pcpdir ${fcst_grib_file_dir} -pcprx 'pgrbq.*grib2$' -name "APCP_${accum_time}" ${fcst_file}"

    pcp_combine -sum ${yyyy}${mm}${dd}_${hh}0000 ${model_bucket} ${vyyyymmdd}_${vhh}0000 ${accum_time} -pcpdir ${fcst_grib_file_dir} -pcprx 'pgrbq.*grib2$' -name "APCP_${accum_time}" ${fcst_file}

    # If you are not running on Theia (or another platform that has MET as a built in module), uncomment below and comment the corresponding calls above
    # echo "${met_exe_root}/pcp_combine -sum ${YYYYMMDD}_${HH}0000 ${MODEL_BUCKET} ${VYYYYMMDD}_${VHH}0000 ${ACCUM_TIME} -pcpdir ${FCST_GRIB_FILE_DIR} -pcprx 'pgrbq.*grib2$' -name "APCP_${ACCUM_TIME}" ${FCST_FILE}"
    #${met_exe_root}/pcp_combine -sum ${YYYYMMDD}_${HH}0000 ${MODEL_BUCKET} ${VYYYYMMDD}_${VHH}0000 ${ACCUM_TIME} -pcpdir ${FCST_GRIB_FILE_DIR} -pcprx 'pgrbq.*grib2$' -name "APCP_${ACCUM_TIME}" ${FCST_FILE}

    # Add a variable 'time' to the pcp_combine NetCDF output using ncap; this is for plotting purposes
    # Make forecast output directory for pcp-combine output that has been processed with ncap command
    mkdir -p ${pcp_combine_fcst_dir}/time/${init}

    # Create fcst file to be created as output from ncap command
    fcst_file_time=${pcp_combine_fcst_dir}/time/${init}/${init}_f${fcst_time}_${accum_time}h.nc

    # Create and run command to add time array
    ncap_fcst_command="defdim(\"time\",1);time[time]=${vyyyymmdd}${vhh};time@long_name=\"Time\";"
    echo "ncap2 -s ${ncap_fcst_command} ${fcst_file} -O ${fcst_file_time}"
    ncap2 -s ${ncap_fcst_command} ${fcst_file} -O ${fcst_file_time}

  done # fcst_time loop

   # Increment the current init time
   init_cur_ut=`expr ${init_cur_ut} + ${init_inc}`

done # init while loop

# To combine all individual files into one forecast and one observation file to read into plotting script, use CDO copy command
# Make directory for output from cdo copy
mkdir -p ${pcp_combine_obs_proc}/cat

# Create obs file to be created by cdo copy
obs_file_cat=${pcp_combine_obs_proc}/cat/${obtype}_APCP${accum_time}_${init_time_start}-${init_time_end}_valid${vhh}Z.nc

# Run cdo copy command on observation files
cdo_obs_command="cdo copy ${pcp_combine_obs_proc}/time/*/*.nc ${obs_file_cat}"
echo "cdo copy ${pcp_combine_obs_proc}/time/*/*.nc ${obs_file_cat}"
${cdo_obs_command}

# Make directory for output from cdo copy
mkdir -p ${pcp_combine_fcst_dir}/cat

# Create fcst file to be created by cdo copy
fcst_file_cat=${pcp_combine_fcst_dir}/cat/APCP${accum_time}_${init_time_start}-${init_time_end}_valid${vhh}Z.nc

# Run cdo copy command on forecast files
cdo_fcst_command="cdo copy ${pcp_combine_fcst_dir}/time/*/*.nc ${fcst_file_cat}"
echo "cdo copy ${pcp_combine_fcst_dir}/time/*/*.nc ${fcst_file_cat}"
${cdo_fcst_command}
