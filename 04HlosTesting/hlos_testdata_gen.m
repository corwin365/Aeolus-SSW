clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%generate data for HLOS tests vs zonal/merid in paper
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/08
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataDir     = [LocalDataDir,'/Aeolus/NC_FullQC/'];
Settings.LatRange    = [-90,90];
Settings.TimeScale   = [datenum(2020,1,1):1:datenum(2020,1,31)];
Settings.OutFile     = 'hlos_testdata.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% create results arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Results = struct();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% processing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


for iDay=1:1:numel(Settings.TimeScale)
  
  
  %get Aeolus
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %each file has the date as a string in the filename
  %generate this string and find all files for this day
  [y,m,d] = datevec(Settings.TimeScale(iDay));
  FileString = ['AE_2B_',sprintf('%04d',y),'-',sprintf('%02d',m),'-',sprintf('%02d',d)];
  OnThisDay = wildcardsearch(Settings.DataDir,['*',FileString,'*']);
  clear y m d FileString
  if numel(OnThisDay) == 0; clear OnThisDay; continue; end %no files
  
  %load all these files and glue their data together
  for iFile=1:1:numel(OnThisDay)
    FileData = rCDF(OnThisDay{iFile});
    if iFile == 1; Aeolus = FileData;  Aeolus = rmfield(Aeolus,{'RG','MetaData'});
    else;          Aeolus = cat_struct(Aeolus,FileData,1,{'RG','MetaData'}); 
    end
  end; clear FileData iFile OnThisDay
  stop
  
  %apply QC flags
  Aeolus = reduce_struct(Aeolus,find(Aeolus.QC_Flag_Both ==1));

  %pull out the region of interest
  Aeolus = reduce_struct(Aeolus,inrange(Aeolus.lat,Settings.LatRange));
  
  %convert time to hours
  [~,~,~,hh,mm,~] = datevec(datenum(2000,1,1,0,0,Aeolus.time));
  Aeolus.hh = hh+mm./60; clear hh mm
  
  %convert Z to km
  Aeolus.alt = Aeolus.alt./1000;
  
  %'fix' longitudes
  Aeolus.lon(Aeolus.lon > 180) = Aeolus.lon(Aeolus.lon > 180)-360;

  
  %get ERA5
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %get data
  FilePath = era5_path(Settings.TimeScale(iDay));
  Era5 = rCDF(FilePath);
  Era5.Z = p2h(ecmwf_prs_v2([],137));
  Era5.hh = 0:3:21;
  clear FilePath
  
  %put lats and heights in right order
  [~,idx1] = sort(Era5.Z,'asc');
  Era5.Z = Era5.Z(idx1); Era5.u = Era5.u(:,:,idx1,:); Era5.v = Era5.v(:,:,idx1,:);
  [~,idx2] = sort(Era5.latitude,'asc');
  Era5.latitude = Era5.latitude(idx2); Era5.u = Era5.u(:,idx2,:,:); Era5.v = Era5.v(:,idx2,:,:); 
  clear idx1 idx2
     
  %interpolate ERA5 U and V to Aeolus measurements
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %produce interpolants
  I.U = griddedInterpolant({Era5.longitude,Era5.latitude,Era5.Z,Era5.hh},Era5.u);
  I.V = griddedInterpolant({Era5.longitude,Era5.latitude,Era5.Z,Era5.hh},Era5.v);
  
  %interpolate!
  Aeolus.Era5_U = I.U(Aeolus.lon,Aeolus.lat,Aeolus.alt,Aeolus.hh);
  Aeolus.Era5_V = I.V(Aeolus.lon,Aeolus.lat,Aeolus.alt,Aeolus.hh);
  clear I Era5
  
  %project to a fake HLOS
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

  HLOS = (-Aeolus.Era5_U .* sind(Aeolus.LOS_azimuth)) - (Aeolus.Era5_V .* cosd(Aeolus.LOS_azimuth));
  
  %and back to 'resolved' directions
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
  Aeolus.Era5_U_Proj = -HLOS .* sind(Aeolus.LOS_azimuth);
  Aeolus.Era5_V_Proj = -HLOS .* cosd(Aeolus.LOS_azimuth);

  %now, store and done
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %organise variable space 
  Aeolus.U_Proj    = Aeolus.Zonal_wind_projection;
  Aeolus.V_Proj    = Aeolus.Meridional_wind_projection;
  Aeolus.HLOS      = Aeolus.Rayleigh_HLOS_wind_speed;
  Aeolus.Era5_HLOS =  HLOS;
  Aeolus = rmfield(Aeolus,{'Satellite_Velocity','QC_Flag_ObsType', ...
                           'QC_Flag_HLOSErr','hh','Zonal_wind_projection', ...
                           'Rayleigh_HLOS_wind_speed', ...
                           'Meridional_wind_projection'});
  
  %add to storage pile
  Results.(['ae_',num2str(Settings.TimeScale(iDay))]) = Aeolus;
  clear Aeolus HLOS

end

save(Settings.OutFile,'Settings','Results');