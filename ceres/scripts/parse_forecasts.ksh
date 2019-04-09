#!/bin/sh
# Sorts forecasts into seasonal file lists by VALID date
#   -Additionally separates into day 1, 3, 5, 10, and all forecasts
# Also creates files lists for full year for day 1, 3, 5, 10
# A day includes a 24-hour period (e.g. day1=f006,f012,f018,f024)

scripts=/gpfs/u/home/hertneky/scripts
model_dir=/glade/p/ral/jntp/GMTB/Phys_Test_FV3GFSv2/POST
list_dir=${scripts}/ceres/file_lists
ndate=${scripts}/ndate.exe

fcst_list="  6  12  18  24  30  36  42  48 \
            54  60  66  72  78  84  90  96 \
           102 108 114 120 126 132 138 144 \
           150 156 162 168 174 180 186 192 \
           198 204 210 216 222 228 234 240"

suite_list="suite1 suite2 suite3 suite4"

# Loop through all suites, initializations, and fcsts
for suite in ${suite_list}; do
    for init_path in ${model_dir}/${suite}/2017*; do
	for fcst in ${fcst_list}; do

	    # Init date (YYYYMMDDHH)
	    init=`echo ${init_path} | cut -d"/" -f10`
	    # Init hour (HH)
            HH=`echo ${init} | cut -c9-10`
	    # Valid date (YYYYMMDDHH)
	    valid=`${ndate} +${fcst} ${init}`
	    # Valid month (MM)
	    vmm=`echo ${valid} | cut -c5-6`
	    # Formatted fcst for file names
	    fhr=`printf "%03i" ${fcst}`

	    # Fcst file
	    file=${init_path}/gfs.t${HH}z.pgrb2.1p00.f${fhr}

	    mkdir -p ${list_dir}

	    # Create file lists for day 1, 3, 5, 10 for year
	    if [[ ${fcst} -ge 6 && ${fcst} -le 24 ]]; then
		echo ${file} >> ${list_dir}/file_list_${suite}_YEAR_day1.txt
	    elif [[ ${fcst} -ge 54 && ${fcst} -le 72 ]]; then
		echo ${file} >> ${list_dir}/file_list_${suite}_YEAR_day3.txt
	    elif [[ ${fcst} -ge 102 && ${fcst} -le 120 ]]; then
		echo ${file} >> ${list_dir}/file_list_${suite}_YEAR_day5.txt
	    elif [[ ${fcst} -ge 222 && ${fcst} -le 240 ]]; then
		echo ${file} >> ${list_dir}/file_list_${suite}_YEAR_day10.txt
	    fi

	    # Create seasonal file lists for day 1, 3, 5, 10, as well as all forecasts
	    if [[ ${vmm} = 12 || ${vmm} = 01 || ${vmm} = 02 ]]; then
		echo ${file} >> ${list_dir}/file_list_${suite}_DJF.txt
		if [[ ${fcst} -ge 6 && ${fcst} -le 24 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_DJF_day1.txt
		elif [[ ${fcst} -ge 54 && ${fcst} -le 72 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_DJF_day3.txt
		elif [[ ${fcst} -ge 102 && ${fcst} -le 120 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_DJF_day5.txt
		elif [[ ${fcst} -ge 222 && ${fcst} -le 240 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_DJF_day10.txt
		fi
	    elif [[ ${vmm} = 03 || ${vmm} = 04 || ${vmm} = 05 ]]; then
		echo ${file} >> ${list_dir}/file_list_${suite}_MAM.txt
		if [[ ${fcst} -ge 6 && ${fcst} -le 24 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_MAM_day1.txt
		elif [[ ${fcst} -ge 54 && ${fcst} -le 72 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_MAM_day3.txt
		elif [[ ${fcst} -ge 102 && ${fcst} -le 120 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_MAM_day5.txt
		elif [[ ${fcst} -ge 222 && ${fcst} -le 240 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_MAM_day10.txt
		fi
	    elif [[ ${vmm} = 06 || ${vmm} = 07 || ${vmm} = 08 ]]; then
		echo ${file} >> ${list_dir}/file_list_${suite}_JJA.txt
		if [[ ${fcst} -ge 6 && ${fcst} -le 24 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_JJA_day1.txt
		elif [[ ${fcst} -ge 54 && ${fcst} -le 72 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_JJA_day3.txt
		elif [[ ${fcst} -ge 102 && ${fcst} -le 120 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_JJA_day5.txt
		elif [[ ${fcst} -ge 222 && ${fcst} -le 240 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_JJA_day10.txt
		fi
	    elif [[ ${vmm} = 09 || ${vmm} = 10 || ${vmm} = 11 ]]; then
		echo ${file} >> ${list_dir}/file_list_${suite}_SON.txt
		if [[ ${fcst} -ge 6 && ${fcst} -le 24 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_SON_day1.txt
		elif [[ ${fcst} -ge 54 && ${fcst} -le 72 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_SON_day3.txt
		elif [[ ${fcst} -ge 102 && ${fcst} -le 120 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_SON_day5.txt
		elif [[ ${fcst} -ge 222 && ${fcst} -le 240 ]]; then
		    echo ${file} >> ${list_dir}/file_list_${suite}_SON_day10.txt
		fi
	    else
		echo "Month is not valid"
		exit 1
	    fi

	done
    done
done
