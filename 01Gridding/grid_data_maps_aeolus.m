clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%prepare data for Aeolus SSW analysis
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/06
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataDir     = [LocalDataDir,'/Aeolus/NC_FullQC/'];
Settings.LatScale    = 20:3:90;
Settings.LonScale    = 0:30:360;
Settings.TimeScale   = [...%datenum(2018,12,10):1:datenum(2019,1,20)-1, ... 
                        datenum(2019,12,10):1:datenum(2020,1,20)-1, ...
                        datenum(2020,12,10):1:datenum(2021,1,20)-1];
Settings.HeightScale = 4:2:26;
Settings.OutFile     = 'aeolus_maps.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%results arrays
Results.HLOS = NaN(numel(Settings.TimeScale),   ...
                   numel(Settings.LonScale),    ...
                   numel(Settings.LatScale),    ...
                   numel(Settings.HeightScale));
Results.U = Results.HLOS;
Results.V = Results.HLOS;
              
%working variables used throughout
[xi,yi,zi] = meshgrid(Settings.LonScale,Settings.LatScale,Settings.HeightScale);
InVars  = {'Rayleigh_HLOS_wind_speed','Zonal_wind_projection','Meridional_wind_projection'};
OutVars = {'HLOS','U','V'};
  
              
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and bin data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

textprogressbar('Gridding data ')
for iDay=1:1:numel(Settings.TimeScale)
  
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
    if iFile == 1; Data = FileData;  Data = rmfield(Data,{'RG','MetaData'});
    else;          Data = cat_struct(Data,FileData,1,{'RG','MetaData'}); 
    end
  end; clear FileData iFile OnThisDay
  
  %apply QC flags
  Data = reduce_struct(Data,find(Data.QC_Flag_Both ==1));

  %pull out the region of interest
  Data = reduce_struct(Data,inrange(Data.lat,[min(Settings.LatScale),max(Settings.LatScale)]));
  

  %grid
  for iVar=1:1:numel(InVars)
    InField  = Data.(InVars{iVar});
    OutField = Results.(OutVars{iVar}); 
    zz = squeeze(bin2matN(3,Data.lon,Data.lat,Data.alt./1000,InField,xi,yi,zi,'@nanmean'))./100;
    OutField(iDay,:,:,:) = permute(zz,[2,1,3]); %again, nothing is in hours 24+
    Results.(OutVars{iVar}) = OutField;
 
  end; clear iVar dd hh InField OutField zz
  
  textprogressbar(iDay./numel(Settings.TimeScale).*100);
end; clear iDay xi yi InVars OutVars zi
textprogressbar('!')

save(Settings.OutFile,'Settings','Results')