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
Settings.LatRange    = [60,90];
Settings.TimeScale   = [];
for iYear=2004:1:2021;
  Settings.TimeScale = [Settings.TimeScale, ...
                        datenum(iYear,11,1):1:datenum(iYear+1,4,1)-1];
end
Settings.HeightScale = [0:2:40]; %km
Settings.HourScale   = 0:8:24;
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
for iDay=numel(Settings.TimeScale):-1:1
  
  %load MLS data for this day
  [yy,~,~] = datevec(Settings.TimeScale(iDay));
  dd = date2doy(Settings.TimeScale(iDay));
  FileName = wildcardsearch(Settings.DataDir,['*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);
  clear yy dd
  if numel(FileName) == 0; clear FileName; continue; end  
  
  %two versions mixed...
  Data = get_MLS(FileName{1},'Temperature-StdProd');
  if numel(Data.L2gpValue) == 0; Data = get_MLS(FileName{1},'Temperature');end
  
  Data.T = Data.L2gpValue(:);
  [l,p] = meshgrid(Data.Latitude,p2h(Data.Pressure));
  Data.Lat  = l(:);
  Data.Z    = p(:);
  Data.Time = repmat(Data.Time,1,numel(Data.Pressure)); Data.Time = Data.Time(:);
  clear l p
 
  %pull out the region of interest
  Data.T    = Data.T(   inrange(Data.Lat,Settings.LatRange));
  Data.Z    = Data.Z(   inrange(Data.Lat,Settings.LatRange));
  Data.Time = Data.Time(inrange(Data.Lat,Settings.LatRange));
  
  %convert time to hours
  [~,~,~,hh,~,~] = datevec(datenum(1993,1,1,0,0,Data.Time));
  
  %grid
  for iVar=1:1:numel(InVars)
    InField  = Data.(InVars{iVar});
    OutField = Results.(OutVars{iVar}); 
    zz = squeeze(bin2matN(2,hh,Data.Z,InField,xi,yi,'@nanmedian'))';
    OutField(iDay,:,:) = zz(1:end-1,:); %again, nothing is in hours 24+
    Results.(OutVars{iVar}) = OutField;
  end; clear iVar dd hh InField OutField zz
  
  
  if mod(iDay,100) == 0;save(Settings.OutFile,'Settings','Results');end
  
  textprogressbar(iDay./numel(Settings.TimeScale).*100);
end; clear iDay xi yi InVars OutVars
textprogressbar('!')

save(Settings.OutFile,'Settings','Results')