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

Settings.DataDir     = [LocalDataDir,'/MLS/'];
Settings.LatScale    = 20:5:90;
Settings.LonScale    = 0:30:360;
Settings.TimeScale   = [...%datenum(2018,12,10):1:datenum(2019,1,20)-1, ... 
                        ...%datenum(2019,12,10):1:datenum(2020,1,20)-1, ...
                        datenum(2020,11,1):1:datenum(2021,3,1)-1];
Settings.HeightScale = 4:2:26;
Settings.OutFile     = 'mls_maps.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%results arrays
Results.T = NaN(numel(Settings.TimeScale),   ...
                numel(Settings.LonScale),    ...
                numel(Settings.LatScale),    ...
                numel(Settings.HeightScale));
              
%working variables used throughout
[xi,yi,zi] = meshgrid(Settings.LonScale,Settings.LatScale,Settings.HeightScale);
InVars  = {'T'};
OutVars = {'T'};
  
              
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and bin data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

textprogressbar('Gridding data ')
for iDay=1:1:numel(Settings.TimeScale)
  

  %load MLS data for this day
  [yy,~,~] = datevec(Settings.TimeScale(iDay));
  dd = date2doy(Settings.TimeScale(iDay));
  FileName = wildcardsearch(Settings.DataDir,['*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);
  clear yy dd
  if numel(FileName) == 0; clear FileName; continue; end
  
  %two versions mixed...
  Data = get_MLS(FileName{1},'Temperature');
  if numel(Data.L2gpValue) == 0; Data = get_MLS(FileName{1},'Temperature_StdProd');end
  
  Data.T = Data.L2gpValue(:);
  [l,p] = meshgrid(Data.Latitude,p2h(Data.Pressure));
  Data.Lat  = l;
  Data.Z    = p;
  Data.Time = repmat(datenum(1993,1,1,0,0,Data.Time),1,numel(Data.Pressure));
  clear l p
  
  
  %pull out the requested variable,s plus geolocation
  Mls.Lat  = flatten(repmat( Data.Latitude,1,numel(Data.Pressure))');
  Mls.Lon  = flatten(repmat(Data.Longitude,1,numel(Data.Pressure))'); Mls.Lon(Mls.Lon <0) = Mls.Lon(Mls.Lon <0)+360;
  Mls.Alt  = flatten(Data.Z);
  Mls.Time = flatten(Data.Time');
  Mls.T    = flatten(Data.L2gpValue);
  clear Data
  
  %grid
  for iVar=1:1:numel(InVars)
    InField  = Mls.(InVars{iVar});
    OutField = Results.(OutVars{iVar}); 
    zz = squeeze(bin2matN(3,Mls.Lon,Mls.Lat,Mls.Alt,InField,xi,yi,zi,'@nanmean'));
    OutField(iDay,:,:,:) = permute(zz,[2,1,3]); %again, nothing is in hours 24+
    Results.(OutVars{iVar}) = OutField;
 
  end; clear iVar dd hh InField OutField zz
  
  textprogressbar(iDay./numel(Settings.TimeScale).*100);
end; clear iDay xi yi InVars OutVars zi
textprogressbar('!')

save(Settings.OutFile,'Settings','Results')