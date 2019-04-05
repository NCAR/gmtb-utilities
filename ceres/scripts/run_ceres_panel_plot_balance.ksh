#!/bin/sh

out_dir=/gpfs/u/home/hertneky/scripts/ceres/output
ncl_script=/gpfs/u/home/hertneky/scripts/ceres/ceres_panel_plot_balance.ncl

suite_list="suite1 suite2 suite3 suite4"
season_list="YEAR"
day_list="1 3 5 10"

for SUITE in ${suite_list}; do
    for SEASON in ${season_list}; do
	for DAY in ${day_list}; do

	    fcst_file=${out_dir}/fv3gfs_${SUITE}_${SEASON}_day${DAY}_mean_regrid.nc
	    obs_file=${out_dir}/ceres_NET_TOA_${SEASON}.nc
	    const_file=${out_dir}/ceres_SOLAR_${SEASON}.nc

	    export out_dir
	    export fcst_file
	    export obs_file
	    export const_file
	    export SUITE
	    export SEASON
	    export DAY

	    ncl ${ncl_script}

	done
    done
done

