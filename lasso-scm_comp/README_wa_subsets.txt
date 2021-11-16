The various *wa_subsets.ncl programs are intended to compare LASSO LES subsets
prepared by Wayne Angevine (wayne.m.angevine@noaa.gov, CIRES at NOAA/CSL)
to output from the 2018 CCPP SCM LASSO cases.

The LES output originates from the publicly-available LASSO LES runs. Wayne
took these data, horizontally averaged them, and reduced the number of output
variables so that a negligible amount of disk space is required to store them.
Wayne gave permission to share these data with other DTC staff. They are 
available from HPSS at:
/ESRL/BMC/ufs-phys/3year/Evan.Kalina/lasso_wa_subsets/wrfstat_extracted_s02_2018.tar 

The various programs and their purposes are as follows:
* LASSO_wrapper.ncl - Run the *wa_subsets.ncl programs for each case date
  and output files containing means and standard deviations across all cases. 
* LASSO_cld_wa_subsets.ncl - Analyze cloud water mixing ratio and cloud
  fraction (time-height cross sections).
* LASSO_pblh_wa_subsets.ncl - Analyze PBL height (time series).
* LASSO_thtQ_prof_wa_subsets.ncl - Create time-averaged profiles of potential
  temperature, water vapor mixing ratio, wind speed, and the physics and
  dynamics tendencies of these variables. The averaging windows are all
  currently two hours long, but the specific windows and their durations
  could be easily changed (vertical profiles).
* LASSO_thtQ_wa_subsets.ncl - Analyze potential temperature and water vapor
  mixing ratio (time-height cross sections).
* LASSO_wind_wa_subsets.ncl - Analyze wind speed, including at 10 m.
  Because Wayne's LASSO subsets do not contain winds at 10 m, similarity theory
  has been used to estimate the 10-m wind speed. The stability is assumed
  to be neutral (time-height cross sections and time series).
* scm_press_to_hgt.ncl - A function called by the *wa_subsets.ncl programs
  to convert the SCM data vertical coordinate from pressure to height using the
  geopotential equation. Needed because the LASSO LES data are only provided
  in height coordinates. Written by Wayne Angevine and adapted to NCL by
  Evan Kalina.

* LASSO_SCM_plot_composite.ncl - Generate composites of the LASSO LES and
  CCPP SCM results from all of the cases. Not run by LASSO_wrapper.ncl.
* LASSO_SCM_multicase_comp.ncl - Plot the results from each individual case
  on the same plot. The computation of the potential temperature lapse rate
  also occurs here, even though it should probably be moved into one of the
  *wa_subsets.ncl programs. Not run by LASSO_wrapper.ncl.

In summary:
* The *wa_subsets.ncl programs make plots for each individual case, but they 
  also create/append relevant output to a netcdf file (one file per case date).

* The wrapper script then uses CDO to output means (LASSO_SCM_composite.nc) and
  standard deviations (LASSO_SCM_composite_std.nc) of the variables in the case
  date files. The LASSO_SCM_plot_composite.ncl script then uses these two netcdf
  files to plot composites of various quantities for both the LASSO LES and SCM.

Notes:
* The *wa_subsets.ncl use linear interpolation to interpolate the CCPP SCM
  output to vertical levels that are similar to the LASSO LES output. The
  target vertical levels are defined in interp_levs.txt. These levels were
  obtained by averaging the LASSO LES vertical level heights over the course 
  of a run (because the heights change slightly over time). 

* In each *wa_subsets.ncl program, rdir should be set to the path that
  contains the LES subsets from Wayne, diro should be set to the paths
  that contain the output.nc files from the SCM runs (a for loop is used
  to loop over the case date), and dir_comp should be set to the path
  you want to write plots and other output files to. 

* These scripts have only been tested on Orion. System modules ncl/6.6.2 and 
  cdo/1.9.10 were used.

* The scripts were written by Evan Kalina (evan.kalina@noaa.gov), and the
  *wa_subsets.ncl scripts are based on scripts written by Dan D'Amico.
