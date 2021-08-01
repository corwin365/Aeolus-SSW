function Aeolus = get_aeolus(Date,DataDir,InVars,OutVars)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load and return Aeolus data in standard format for gridding
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/13
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%create an array of empty variables, in case nothing is found to return
Aeolus.Lat  = [];
Aeolus.Lon  = [];
Aeolus.Lat  = [];
Aeolus.Time = [];
for iVar=1:1:numel(InVars)
  Aeolus.(OutVars{iVar}) = [];
end


%ok, let's get going

%each file has the date as a string in the filename
%generate this string and find all files for this day
[y,m,d] = datevec(Date);
FileString = ['AE_2B_',sprintf('%04d',y),'-',sprintf('%02d',m),'-',sprintf('%02d',d)];
OnThisDay = wildcardsearch(DataDir,['*',FileString,'*']);
clear y m d FileString
if numel(OnThisDay) == 0; clear OnThisDay; return; end %no files

%load all these files and glue their data together
for iFile=1:1:numel(OnThisDay)
  FileData = rCDF(OnThisDay{iFile});
  if iFile == 1; Data = FileData;  Data = rmfield(Data,{'RG','MetaData'});
  else;          Data = cat_struct(Data,FileData,1,{'RG','MetaData'});
  end
end; clear FileData iFile OnThisDay

%apply QC flags
Data = reduce_struct(Data,find(Data.QC_Flag_Both ==1));

%put into -180-180
Data.lon(Data.lon > 180) = Data.lon(Data.lon > 180)-360;

%scale units
Data.Zonal_wind_projection      = Data.Zonal_wind_projection./100;
Data.Meridional_wind_projection = Data.Meridional_wind_projection./100;
Data.alt                        = Data.alt./1000;

%pull out the requested variable,s plus geolocation
Aeolus.Lat  = Data.lat;
Aeolus.Lon  = Data.lon;
Aeolus.Alt  = Data.alt;
Aeolus.Time = datenum(2000,1,1,0,0,Data.time);

for iVar=1:1:numel(InVars)
  Aeolus.(OutVars{iVar}) = Data.(InVars{iVar});
end



end