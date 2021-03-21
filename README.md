# Aeolus January 2021 SSW


This is the code underlying Wright et al (2021), a manuscript submitted to Weather and Climate Dynamics in March 2021 which uses data from Aeolus, MLS and ERA5 to study the January 2021 Sudden Stratospheric Warming.

This release only contains code I have produced as lead-author. This excludes the processing chains used to produce the data for Figures 5, 10, and 11, and the plotting code for Figure 11.


Most of the code is written in Matlab. All functions needed to produce the Figures should be included in the directory "functions/", but in the event I've made an error any missing functions are very likely to be available from https://github.com/corwin365/MatlabFunctions. 

The code is presented as-is at time of submission, and has not been specifically tidied for upload due to time constraints - my main aim here is to produce an audit-trail for our work rather than a solid package people can use for their own work. I am very happy to help as much as I can if you're trying to decode a particular bit of code though, so get in touch if you're stuck!

Finally, for all figures manual modifications to the layout, including adding contextual lines and rearranging panels into figures, was carried out in image-editing software. So: the above files will not produce final versions as seen in the paper - although usually it will be very close.



### Data Sources

Data used were obtained from (ERA5) the Copernicus Climate Data Store (Aeolus) the ESA website and (MLS) NASA's DISC, all in standard netCDF formats as of MArch 2021. These were put in the following directories with the following naming conventions:

- LocalDataDir/Aeolus/DBL/     
   then: same name as original ESA files.
   You will need to create LocalDataDir/Aeolus/NC_FullQC/ to place the converted files
   
- LocalDataDir/ERA5/YYYY/      
   then: era5t_YYYYdDDD.nc
   
- LocalDataDir/MLS/T     
   then: original file name from NASA DISC
   
where LocalDataDir is specified in the function "functions/LocalDataDir", YYYY is the four-digit year, and DDD is the three-digit day-of-year.


### Data Generation

The routines were produced organically over a period of several months and bits of data in figures produced earlier were often reused in figures produced later. As a result, there are some weird cross-dependencies between figures.  Running all the data-generation routines first should avoid issues due to this. You can try running individual files if you just want one figure - just be prepared to hunt down where any missing data is coming from!

1. Run the Python scripts in 01AeolusConversion to convert the Aeolus data from their original ESA DBL format to a slimmed-down netCDF format used throughout this study. This will require some small manual tweaks for your filesystem throughout the programme, that will not carry over to the rest of the Matlab analyses - keep prodding until it works!

2. Run:
 - 02HeightTimeSeries/grid_aeolus.m
 - 02HeightTimeSeries/grid_era5.m
 - 02HeightTimeSeries/grid_mls.m
 
 The MLS routine will need to be run twice, once with a 55-65 degree range and ocne with a 60-90N range. This can be done by commenting in and out the relevant lines in the "Settings" section at the top of the routine.
 
3. Run:
 - 03Context/grid_data_timeseries_mls.m
 - 03Context/grid_data_timeseries_era5.m
 - 04HlosTesting/hlos_testdata_gen.m
 - 04HlosTesting/hlos_testdata_statsgen.m
 - 05ThreeDPlots/generate_plot_data.m
 - 06TropopauseFinding/find_stratopause_simple.m
 - 06TropopauseFinding/zm_stratopause.m
 - 06TropopauseFinding/find_tropopause_simple.m
 - 06TropopauseFinding/zm_tropopause.m 
 - 07Fluxes/grid_datasets.m
 - 07Fluxes/compute_fluxes.m
 - 08Maps/grid_data_maps_aeolus.m
 - 10WindComparison/01MlsGeostrophicWind/mls_geostrophic_wind.m
 - 12Zmt_Mls/grid_mls.m

### Data Generation

Phew, that took a bit of typing! OK, you can now make each figure individually:

Figure 1: 10WindComparison/compare_winds_v2.m

Figure 2: 03Context/plot_timeseries_mls_era5_spaghetti.m

Figure 3: 02HeightTimeSeries/plot_height_timeseries.m

Figure 4: as figure 3, comment in and out relevant lines in settings

Figure 5: Data not included in file release - from co-author. Plotting: 14VortexMetrics/plot_metrics.m

Figure 6: 07Fluxes/plot_timeseries.m

Figure 7: 08Maps/plot_maps_singleyear.m

Figure 8: 05ThreeDPlots/christmas_cakes.m

Figure 9: 14VortexMetrics/plot_vortex_gph.m

Figure 10:  Data not included in file release - from co-author. Plotting:  13SurfaceCoupling/plot_surface_coupling.m

Figure 11: Data and code not included in file release - from co-author.

Figure A1: Generated in graphics package, no code.

Figure A2: 04HlosTesting/hlos_testdata_maps.m

Figure A3: 04HlosTesting/hlos_testdata_statsplot.m

Figure B1: as figure 3, comment in and out relevant lines in settings

Figure B4: as figure 3, comment in and out relevant lines in settings
