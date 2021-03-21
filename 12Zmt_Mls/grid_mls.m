clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%grid MLS zonal mean temperature to study stratopause height
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/03/15
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%regionalisation
Settings.OutFile          = 'zmt_mls.mat';
Settings.Grid.LatScale    = 0:2:90;
Settings.Grid.TimeScale   = datenum(2020,12,20):1:datenum(2021,2,28);
Settings.Grid.HeightScale = [10:4:50,54:6:120]; %km

%list of datasets
Settings.DataSets         = {'Mls'};

%MLS-specific settings
Settings.Mls.DataDir      = [LocalDataDir,'/MLS/'];
Settings.Mls.InVars       = {'T'};
Settings.Mls.OutVars      = {'T'};

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

Results.Data = NaN(numel(Settings.Grid.LatScale),    ...
                   numel(Settings.Grid.TimeScale),   ...
                   numel(Settings.Grid.HeightScale));
                 
Results.Grid = Settings.Grid; %so we can just load the "results" struct in later scripts

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
      
      %load variable
      if ~isfield(Data,VarList{iVar});continue; end
      Var = Data.(VarList{iVar});
      if numel(Var) == 0; continue; end
      
      %bin variable
      [xi,yi] = meshgrid(Settings.Grid.LatScale,Settings.Grid.HeightScale);
      zz = bin2matN(2,Data.Lat,Data.Alt,Var,xi,yi,'@nanmean');
      
      %store it
      Results.Data(:,iDay,:) = squeeze(zz)';
      
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