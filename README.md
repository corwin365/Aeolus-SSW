# Aeolus January 2021 SSW


This is the code underlying Wright et al (2021), a manuscript submitted to Weaher and Climate Dynamics in March 2021 which uses data from Aeolus, MLS and ERA5 to study the January 2021 Sudden Stratospheric Warming.


Most of the code is written in Matlab. I have checked and all functions needed to produce the Figures should be included in the directory "functions/", but in the event I've made an error any missing functions are very likely to be available from https://github.com/corwin365/MatlabFunctions. 

The code is presented as-is at time of submission, and has not been specifically tidied for upload due to time constraints - my main aim here is to produce an audit-trail for our work rather than a solid package people can use for their own work. I am very happy to help as much as I can if you're trying to decode a particular bit of code though, so get in touch if you're stuck!

Finally, for all figures manual modification to the layout, including adding contextual lines and rearranging panels into figures, was carried out in image-editing software. So: the above files will not produce final versions as seen in the paper - although usually it will be very close.

### Data Sources

Data used were obtained from (ERA5) the Copernicus Climate Data Store (Aeolus) the ESA website and (MLS) NASA's DISC, all in standard netCDF formats as of MArch 2021. These were put in the following directories with the following naming conventions:

- LocalDataDir/Aeolus/NC_FullQC/     
   then: same name as original ESA files, with .nc suffix
   
- LocalDataDir/ERA5/YYYY/      
   then: era5t_YYYYdDDD.nc
   
- LocalDataDir/MLS/T     
   then: original file name from NASA DISC
   
where LocalDataDir is specified in the function "functions/LocalDataDir", YYYY is the four-digit year, and DDD is the three-digit day-of-year.


### Data Generation

The routines were produced organically over a period of several months and bits of data in figures produced earlier were often reused in figures produced later. As a result, there are some weird cross-dependencies between figures.  RUnning all the data-generation routines first should avoid issues due to this.

1. Run the Python scripts in 01AeolusConversion to convert the Aeolus data from their original ESA DBL format to a slimmed-down netCDF format

2. Run:
 - 02HeightTimeSeries/grid_aeolus.m
 - 02HeightTimeSeries/grid_era5.m
 - 02HeightTimeSeries/grid_mls.m
 
 The MLS routine will need to be run twice, once with a 55-65 degree range and ocne with a 60-90N range. This can be done by commenting in and out the relevant lines in the "Settings" section at the top of the routine.
 
3. Run:
 - 03Context/grid_data_timeseries_mls.m
 - 03Context/grid_data_timeseries_era5.m
 - 04HlosTesting/hlos_testdata_gen.m
 - 04Hlos
