clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%pgenerate statistical data for HLOS tests vs zonal/merid in paper
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/09
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%data
Settings.InFile  = 'hlos_testdata.mat';

%output
Settings.OutFile = 'hlos_error_stats.mat';

%analysis 1: distribution of error data as f(latitude,height)
Settings.An1.LatScale    = -90:1:90;
Settings.An1.ZScale      = 0:2:30;
Settings.An1.Percentiles = 0:1:100;

%analysis 2: maps of median error
Settings.An2.LatScale    = -90:2:90;
Settings.An2.LonScale    = -180:5:180;
Settings.An2.ZScale      = [5,10,15,20]; %km
Settings.An2.LayerDepth  = 2; %km

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data and merge into a giant pile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

textprogressbar('Importing data ')

Data   = load(Settings.InFile);
Days   = fieldnames(Data.Results); 

for iDay=1:1:numel(Days)
  
  ThisDay = Data.Results.(Days{iDay});
  
  if iDay == 1; Store = ThisDay;
  else          Store = cat_struct(Store,ThisDay,1);
  end
  
  textprogressbar(iDay./numel(Days).*100)
end
textprogressbar('!')
clear Days iDay ThisDay

Store.DeltaU = Store.Era5_U - Store.Era5_U_Proj;
Store.DeltaV = Store.Era5_V - Store.Era5_V_Proj;
Store.DeltaU_Frac = abs(Store.DeltaU./Store.Era5_U);
Store.DeltaV_Frac = abs(Store.DeltaV./Store.Era5_V);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% analysis 1: error as f(latitude, height)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%create storage
An1.ErrorStore = NaN(4,                            ...
                     numel(Settings.An1.LatScale), ...
                     numel(Settings.An1.ZScale),   ...
                     numel(Settings.An1.Percentiles));
 
%do work                   
textprogressbar('Generating latitude-height statistics ')                   
for iLat=1:1:numel(Settings.An1.LatScale)
  for iZ=1:1:numel(Settings.An1.ZScale)
    
    InBin = find(Store.lat >= Settings.An1.LatScale(iLat) ...
               & Store.lat <  Settings.An1.LatScale(iLat)+mean(diff(Settings.An1.LatScale)) ...
               & Store.alt >= Settings.An1.ZScale(    iZ) ...
               & Store.alt <  Settings.An1.ZScale(    iZ)+mean(diff(Settings.An1.ZScale)));
    if numel(InBin) == 0; continue; end
               
    An1.ErrorStore(1,iLat,iZ,:) = prctile(Store.DeltaU(     InBin),Settings.An1.Percentiles);
    An1.ErrorStore(2,iLat,iZ,:) = prctile(Store.DeltaV(     InBin),Settings.An1.Percentiles);  
    An1.ErrorStore(3,iLat,iZ,:) = prctile(Store.DeltaU_Frac(InBin),Settings.An1.Percentiles);
    An1.ErrorStore(4,iLat,iZ,:) = prctile(Store.DeltaV_Frac(InBin),Settings.An1.Percentiles);       
  end
  textprogressbar(iLat./numel(Settings.An1.LatScale).*100)
end
textprogressbar('!')
clear iLat iZ InBin
  

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% analysis 2: error as f(lat,lon) on fixed height levels
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%create storage
An2.ErrorStore = NaN(4,                            ...
                     numel(Settings.An2.LatScale), ...
                     numel(Settings.An2.LonScale),   ...
                     numel(Settings.An2.ZScale));
 
%do work                   
[xi,yi] = meshgrid(Settings.An2.LonScale,Settings.An2.LatScale);

textprogressbar('Generating error maps ')     
for iZ=1:1:numel(Settings.An2.ZScale);

  %get data at level
  ThisLevel = find(Store.alt >= Settings.An2.ZScale(iZ)-0.5.*Settings.An2.LayerDepth ...
                 & Store.alt <= Settings.An2.ZScale(iZ)+0.5.*Settings.An2.LayerDepth);
               
  %make maps
  Vars = {'DeltaU','DeltaV','DeltaU_Frac','DeltaV_Frac','Era5_U','Era5_V','Era5_U_Proj','Era5_V_Proj'};
  for iVar=1:1:numel(Vars)
    Field = Store.(Vars{iVar});
    An2.ErrorStore(iVar,:,:,iZ) = bin2mat(Store.lon(ThisLevel),Store.lat(ThisLevel), ...
                                       Field(ThisLevel),xi,yi,'@nanmean');
  end
                                       
  textprogressbar(iZ./numel(Settings.An2.ZScale).*100)
end
textprogressbar('!')
clear iLat iZ InBin


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% done!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save(Settings.OutFile,'Settings','An1','An2')
