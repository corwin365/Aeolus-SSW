clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%prepare data for MLS SSW analysis
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/18
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataDir     = [LocalDataDir,'/MLS/'];
Settings.LatRange    = [60,90];
Settings.TimeScale   = [...%datenum(2018,11,1):1:datenum(2019,4,1)-1, ... 
                        ...%datenum(2019,10,15):1:datenum(2020,3,15)-1, ...
                        datenum(2020,10,15):1:datenum(2021,3,15)-1];
Settings.HeightScale = [10:4:50,54:6:120]; %km
Settings.HourScale   = [0,24];
Settings.OutFile     = 'mls_data.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%results arrays
Results.T = NaN(numel(Settings.TimeScale),   ...
                numel(Settings.HourScale)-1, ... %nothing is in hours 24+...
                numel(Settings.HeightScale));

              
%working variables used throughout
[xi,yi] = meshgrid(Settings.HourScale,Settings.HeightScale);
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
  Mls.Lon  = flatten(repmat(Data.Longitude,1,numel(Data.Pressure))');
  Mls.Alt  = flatten(Data.Z);
  Mls.Time = flatten(Data.Time');
  Mls.T    = flatten(Data.L2gpValue);
  clear Data


  %convert time to hours
  [~,~,~,hh,~,~] = datevec(Mls.Time);
  
  %grid
  for iVar=1:1:numel(InVars)
    InField  = Mls.(InVars{iVar});
    OutField = Results.(OutVars{iVar}); 
    zz = squeeze(bin2matN(2,hh,Mls.Alt,InField,xi,yi,'@nanmean'))';
    OutField(iDay,:,:) = zz(1:end-1,:); %again, nothing is in hours 24+
    Results.(OutVars{iVar}) = OutField;
  end; clear iVar dd hh InField OutField zz
  
  textprogressbar(iDay./numel(Settings.TimeScale).*100);
end; clear iDay xi yi InVars OutVars
textprogressbar('!')

save(Settings.OutFile,'Settings','Results')