clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%grid u, v and T for assessing various atmospheric parameters
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/13
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%general
Settings.OutFile          = 'gridded_data.mat';

%common gridding settings
Settings.Grid.LatScale    = -90:10:90;
Settings.Grid.LonScale    = -180:20:180;
Settings.Grid.TimeScale   = datenum(2020,10,1):1:datenum(2021,2,28);
Settings.Grid.HeightScale = 0:2:26; %km

%list of datasets
Settings.DataSets         = {'Mls','Aeolus','Era5'};

%Aeolus-specific settings
Settings.Aeolus.DataDir   = [LocalDataDir,'/Aeolus/NC_FullQC/'];
Settings.Aeolus.InVars    = {'Zonal_wind_projection','Meridional_wind_projection'};
Settings.Aeolus.OutVars   = {'U','V'}; 

%MLS-specific settings
Settings.Mls.DataDir      = [LocalDataDir,'/MLS/'];
Settings.Mls.InVars       = {'T'};
Settings.Mls.OutVars      = {'T'};

%ECMWF-specific settings 
Settings.Era5.DataDir     = LocalDataDir;
Settings.Era5.InVars      = {'u','v','t'};
Settings.Era5.OutVars     = {'U','V','T'};


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create storage grids
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%make a list of unique dataset-var combinations
Results.VarList  = {};
Results.InstList = {};
for iDataSet=1:1:numel(Settings.DataSets)
  VarList = Settings.(Settings.DataSets{iDataSet}).OutVars;
  for iVar=1:1:numel(VarList)
    Results.InstList{end+1} = Settings.DataSets{iDataSet};
    Results.VarList{ end+1} = VarList{iVar};
  end
end; clear iDataSet iVar VarList

Results.Data = NaN(numel(Results.VarList),           ...
                   numel(Settings.Grid.TimeScale),   ...
                   numel(Settings.Grid.HeightScale), ...
                   numel(Settings.Grid.LonScale),    ...
                   numel(Settings.Grid.LatScale));
                 
Results.Grid = Settings.Grid; %so we can just laod the "results" struct in later scripts

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% create internal-use variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[xi,yi,zi] = meshgrid(Settings.Grid.LonScale,Settings.Grid.LatScale,Settings.Grid.HeightScale);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% grid data!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%fastest to loop over datasets first and then date, as files are likely to
%be sequential on the disk.

for iDataSet=1:1:numel(Settings.DataSets)
  
  textprogressbar(['Processing ',Settings.DataSets{iDataSet},' '])
  for iDay=1:1:numel(Settings.Grid.TimeScale)
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %load data and format into a common format we can grid later
    %these functions will return a single list of points for each 
    %variable, with associated geolocation
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    switch Settings.DataSets{iDataSet}
      case 'Aeolus'; Data = get_aeolus(Settings.Grid.TimeScale(iDay), ...
                                       Settings.Aeolus.DataDir,       ...
                                       Settings.Aeolus.InVars,        ...
                                       Settings.Aeolus.OutVars);
      case 'Mls';    Data = get_mls(   Settings.Grid.TimeScale(iDay), ...
                                       Settings.Mls.DataDir,          ...
                                       Settings.Mls.InVars,           ...
                                       Settings.Mls.OutVars);
      case 'Era5';   Data = get_era5(  Settings.Grid.TimeScale(iDay), ...
                                       Settings.Era5.DataDir,         ...
                                       Settings.Era5.InVars,          ...
                                       Settings.Era5.OutVars);
      otherwise; disp('Dataset not in valid list. Stopping'); stop; 
    end
    
    if numel(Data.Lat) == 0; continue; end %no data
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %grid the data
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
    VarList = Settings.(Settings.DataSets{iDataSet}).OutVars;
    for iVar=1:1:numel(VarList)
      try
      
      
      %grid variable
      Var = Data.(VarList{iVar});
      zz = bin2matN(3,Data.Lon,Data.Lat,Data.Alt,Var,xi,yi,zi,'@nanmean');
      %store it
      ThisVar = find(contains(Results.InstList,Settings.DataSets{iDataSet}) ...
                   & contains( Results.VarList,VarList{iVar}));
      Results.Data(ThisVar,iDay,:,:,:) = permute(zz,[3,2,1]);
      
      
      %and we're done!
      catch; end
    end; clear iVar VarList zz Var ThisVar Data


    textprogressbar(iDay./numel(Settings.Grid.TimeScale).*100)
  end; clear iDay
  textprogressbar('!')
end; clear iDataSet
clear xi yi zi


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%save
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save(Settings.OutFile,'Results','Settings')