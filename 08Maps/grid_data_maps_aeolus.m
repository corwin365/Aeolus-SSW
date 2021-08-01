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

Settings.DataDir     = [LocalDataDir,'/Aeolus/daily_gridded_uv_1day/'];
Settings.LatScale    = -20:5:90;
Settings.LonScale    = -180:20:180;
Settings.TimeScale   = [...%datenum(2018,12,10):1:datenum(2019,1,20)-1, ... 
                        ...%datenum(2019,12,10):1:datenum(2020,1,20)-1, ...
                        datenum(2020,11,1):1:datenum(2021,3,5)-1];
Settings.HeightScale = 4:2:26;
Settings.OutFile     = 'aeolus_maps2.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% prepare arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%results arrays
Results.HLOS = NaN(numel(Settings.TimeScale),   ...
                   numel(Settings.LonScale),    ...
                   numel(Settings.LatScale),    ...
                   numel(Settings.HeightScale));
Results.U = Results.HLOS;
Results.V = Results.HLOS;
              
%working variables used throughout
[xi,yi,zi] = meshgrid(Settings.LonScale,Settings.LatScale,Settings.HeightScale);
InVars  = {'u','v'};
OutVars = {'U','V'};
  
              
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and bin data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

textprogressbar('Gridding data ')
for iDay=1:1:numel(Settings.TimeScale)
  
  %load the day's data
  [yy,mm,dd] = datevec(Settings.TimeScale(iDay));
  FileName = [Settings.DataDir,'/',sprintf('%04d',yy),sprintf('%02d',mm),sprintf('%02d',dd),'_aeolus_gridded_uv.mat'];
  Data = load(FileName); Data = Data.Aeolus;
  
  %make the grids 3D
  sz = size(Data.u);
  Data.lat = repmat(Data.lat,1,1,sz(3));
  Data.lon = repmat(Data.lon,1,1,sz(3));
  
  %change into profiles
  Data.lat  = reshape(Data.lat, sz(1)*sz(2),sz(3));
  Data.lon  = reshape(Data.lon, sz(1)*sz(2),sz(3));
  Data.u    = reshape(Data.u,   sz(1)*sz(2),sz(3));
  Data.v    = reshape(Data.v,   sz(1)*sz(2),sz(3));
  Data.alt  = reshape(Data.walt,sz(1)*sz(2),sz(3));


  %grid
  for iVar=1:1:numel(InVars)
    InField  = Data.(InVars{iVar});
    OutField = Results.(OutVars{iVar}); 
    zz = squeeze(bin2matN(3,Data.lon,Data.lat,Data.alt,InField,xi,yi,zi,'@nanmean'));
    OutField(iDay,:,:,:) = permute(zz,[2,1,3]); %again, nothing is in hours 24+
    Results.(OutVars{iVar}) = OutField;
 
  end; clear iVar dd hh InField OutField zz
  
  textprogressbar(iDay./numel(Settings.TimeScale).*100);
end; clear iDay xi yi InVars OutVars zi
textprogressbar('!')

save(Settings.OutFile,'Settings','Results')