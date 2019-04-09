#!/bin/sh

out_dir=/gpfs/u/home/hertneky/scripts/ceres/output
ncl_script=/gpfs/u/home/hertneky/scripts/ceres/ceres_panel_plot.ncl

suite_list="suite1 suite2 suite3 suite4"
season_list="DJF MAM JJA SON YEAR"
day_list="1 3 5 10"
var_list="DSWRF DLWRF USWRF ULWRF USWRF_TOA ULWRF_TOA"

for SUITE in ${suite_list}; do
    for SEASON in ${season_list}; do
	for DAY in ${day_list}; do
	    for VAR in ${var_list}; do

		fcst_file=${out_dir}/fv3gfs_${SUITE}_${SEASON}_day${DAY}_mean_regrid.nc
		obs_file=${out_dir}/ceres_${VAR}_${SEASON}.nc

		export out_dir
		export fcst_file
		export obs_file
		export VAR
		export SUITE
		export SEASON
		export DAY

		ncl ${ncl_script}

	    done
	done
    done
done

