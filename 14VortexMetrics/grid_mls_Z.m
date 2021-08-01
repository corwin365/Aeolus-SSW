clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%prep and grid MLS GPH
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/07/25
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.DataDir          = [LocalDataDir,'/MLS/GPH'];
Settings.Grid.TimeScale   = datenum(2020,10,1):1:datenum(2021,3,31);
Settings.Grid.Lat         = 0:4:90;
Settings.Grid.Lon         = -180:20:180;
Settings.Grid.HeightScale = [10:4:50,54:6:100]; %km

%list of datasets
Settings.DataSets         = {'Mls'};

%MLS-specific settings
Settings.Mls.DataDir      = [LocalDataDir,'/MLS/'];
Settings.Mls.InVars       = {'GPH'};
Settings.Mls.OutVars      = {'Z'};

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
                   numel(Settings.Grid.Lat),         ...
                   numel(Settings.Grid.Lon));
                 
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
      case 'Mls';    Data = get_mls(   Settings.Grid.TimeScale(iDay), ...
                                       Settings.Mls.DataDir,          ...
                                       Settings.Mls.InVars,           ...
                                       Settings.Mls.OutVars);
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
      [a,b,c] = meshgrid(Settings.Grid.HeightScale,Settings.Grid.Lat,Settings.Grid.Lon);
      zz = bin2matN(3,Data.Alt,Data.Lat,Data.Lon,Var,a,b,c,'@nanmean');
      %store it
      ThisVar = find(contains(Results.InstList,Settings.DataSets{iDataSet}) ...
                   & contains( Results.VarList,VarList{iVar}));
      Results.Data(ThisVar,iDay,:,:,:) = permute(squeeze(zz),[2,1,3]);
      
      %and we're done
    end; clear iVar VarList zz Var ThisVar Data InRange


    textprogressbar(iDay./numel(Settings.Grid.TimeScale).*100)
  end; clear iDay
  textprogressbar('!')
end; clear iDataSet
clear a b c

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save('mls_gph.mat','Results','Settings')