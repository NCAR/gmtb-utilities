#!/bin/ksh

base=/scratch4/BMC/gmtb/harrold/test_surfrad
script=$base/scripts/model_vs_surfrad_plot.ncl
ncl=/apps/ncl/6.3.0-nodap_gcc447/intel.bin/ncl

date_list="20170925"
init_list="00"
site_list="dra"
grib_code_list="204"

for date in ${date_list};do
  for init in ${init_list}; do
      for site in ${site_list}; do
	for grib_code in ${grib_code_list}; do
	    
  srad_file=${base}/surfrad/proc/${site}/${site}_${date}${init}_${grib_code}.nc
  echo ${srad_file}

  ref_file1=${base}/gfs.${date}/first_file/gfs.t${init}z.pgrb2.0p50.f006.grib2
  echo ${ref_file1}

  ref_files_dir=${base}/gfs.${date}/other_fcst_files/
  echo ${ref_files_dir}

  png_file=${base}/plots/model_vs_${site}_srad${grib_code}_${date}i${init}.png
  echo ${png_file}

  # Example command line:
  #ncl srad_file=\"/scratch4/BMC/gmtb/harrold/test_surfrad/surfrad/proc/tw_360min/dra/dra_2017092500_204_tw360min.nc\" ref_file1=\"/scratch4/BMC/gmtb/harrold/test_surfrad/gfs.20170925/gfs.t00z.pgrb2.0p50.f006.grib2\" ref_files_dir=\"/scratch4/BMC/dtc/jwolff/gmtb/gfs.20170925/\" grib_code=204 png_file=\"/scratch4/BMC/gmtb/harrold/test_surfrad/plots/model_vs_dra_tw360min_surfrad_20170925i00.png\" model_vs_surfrad_sw_plot.ncl

  echo "${ncl} srad_file=\\\"${srad_file}\\\" ref_file1=\\\"${ref_file1}\\\" ref_files_dir=\\\"${ref_files_dir}\\\" grib_code=${grib_code} png_file=\\\"${png_file}\\\" ${script}"

  ${ncl} "srad_file=\"${srad_file}\"" "ref_file1=\"${ref_file1}\"" "ref_files_dir=\"${ref_files_dir}\"" grib_code=${grib_code} "png_file=\"${png_file}\"" ${script}

        done # grib_code
      done # site
  done # init
done # date
