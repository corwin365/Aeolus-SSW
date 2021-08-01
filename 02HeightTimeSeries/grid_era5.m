clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%grid u, v and T for assessing various atmospheric parameters
%also does operational analysis, as I added this later and didn't want to
%rename the file
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/13
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%general
Settings.OutFile          = 'zm_data_era5_5565.mat';

%regionalisation
Settings.LatRange         = [60,65];
Settings.Grid.TimeScale   = datenum(2020,10,1):1:datenum(2021,3,15);
Settings.Grid.HeightScale = [0;flipud(p2h(ecmwf_prs_v2([],137)))]; %km
Settings.Grid.HeightScale = Settings.Grid.HeightScale(1:end-1); %needed due to how I handle the top edge in ecmwf_prs_v2

%list of datasets
Settings.DataSets         = {'Era5','OpAl'};

%ERA5-specific settings 
Settings.Era5.DataDir     = LocalDataDir;
Settings.Era5.InVars      = {'u','v','t'};
Settings.Era5.OutVars     = {'U','V','T'};

%OpAl-specific settings 
Settings.OpAl.DataDir     = LocalDataDir;
Settings.OpAl.InVars      = {'u','v','t'};
Settings.OpAl.OutVars     = {'U','V','T'};

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
                   numel(Settings.Grid.HeightScale));
                 
Results.Grid = Settings.Grid; %so we can just laod the "results" struct in later scripts

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
      case 'OpAl';   Data = get_opal(  Settings.Grid.TimeScale(iDay), ...
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
      
      %load variable
      if ~isfield(Data,VarList{iVar});continue; end
      Var = Data.(VarList{iVar});
      
      
      %bin variable
      InRange = inrange(Data.Lat,Settings.LatRange);

      zz = bin2matN(1,Data.Alt(InRange),Var(InRange),Settings.Grid.HeightScale);

      %store it
      ThisVar = find(contains(Results.InstList,Settings.DataSets{iDataSet}) ...
                   & contains( Results.VarList,VarList{iVar}));
      Results.Data(ThisVar,iDay,:,:,:) = zz;
      
      %and we're done
    end; clear iVar VarList zz Var ThisVar Data InRange


    textprogressbar(iDay./numel(Settings.Grid.TimeScale).*100)
  end; clear iDay
  textprogressbar('!')
end; clear iDataSet
clear xi yi zi


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%save
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save(Settings.OutFile,'Results','Settings')