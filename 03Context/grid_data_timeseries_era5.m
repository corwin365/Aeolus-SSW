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

Settings.DataDir     = [LocalDataDir,'/ERA5/'];
Settings.LatRange    = [60,65];
Settings.TimeScale   = [];
for iYear=2004:1:2020;
  Settings.TimeScale = [Settings.TimeScale, ...
                        datenum(iYear,11,1):1:datenum(iYear+1,4,1)-1];
end
Settings.HeightScale = 0:4:40; %km
Settings.HourScale   = 0:8:24;
Settings.OutFile     = 'era5_data.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%results arrays
Results.U = NaN(numel(Settings.TimeScale),   ...
                numel(Settings.HourScale)-1, ... %nothing is in hours 24+...
                numel(Settings.HeightScale));
Results.V = Results.U;

%working variables used throughout
[xi,yi] = meshgrid(Settings.HourScale,Settings.HeightScale);
InVars  = {'u','v'};
OutVars = {'U','V'};
  
              
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and bin data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

textprogressbar('Gridding data ')
for iDay=1:1:numel(Settings.TimeScale)
  
  %load ERA5 data for this day
  [yy,~,~] = datevec(Settings.TimeScale(iDay));
  dd = date2doy(Settings.TimeScale(iDay));
  FileName = wildcardsearch(Settings.DataDir,['*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);
  clear yy dd
  if numel(FileName) == 0; clear FileName; continue;end
  Data = rCDF(FileName{1});
  Data.Prs = ecmwf_prs_v2([],137);
  
  
  %pull out the region of interest
  Data.u = squeeze(nanmean(Data.u(:,inrange(Data.latitude,Settings.LatRange),:,:),[1,2]));
  Data.v = squeeze(nanmean(Data.v(:,inrange(Data.latitude,Settings.LatRange),:,:),[1,2]));
  hh = 0:3:21; %hours in these files

  for iTime=1:1:numel(Settings.HourScale)-1

    InTimeWindow = find(hh >= Settings.HourScale(iTime) ...
                      & hh <  Settings.HourScale(iTime+1));
    for iVar=1:1:numel(InVars)
      InField  = Data.(InVars{iVar});
      OutField = Results.(OutVars{iVar});
      OutField(iDay,iTime,:) = interp1(p2h(Data.Prs),nanmean(InField(:,InTimeWindow),2),Settings.HeightScale);
      Results.(OutVars{iVar}) = OutField;
    end
  end
  clear iTime InTimeWindow iVar InField OutField hh Data

  
  textprogressbar(iDay./numel(Settings.TimeScale).*100);
end; clear iDay xi yi InVars OutVars
textprogressbar('!')

save(Settings.OutFile,'Settings','Results')