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

Settings.DataDir     = [LocalDataDir,'/Aeolus/NC_FullQC/'];
Settings.LatScale    = -90:2:90;
Settings.LonScale    = 0:15:360;
Settings.TimeScale   = [datenum(2020,11,1)-5:1:datenum(2021,3,5)];  Settings.OutFile     = 'aeolus_data_3d_2021.mat';
% Settings.TimeScale   = [datenum(2019,12,1):1:datenum(2020,2,30)];  Settings.OutFile     = 'aeolus_data_3d_1920.mat';
Settings.HeightScale = 0:1.5:30;


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
InVars  = {'Rayleigh_HLOS_wind_speed','Zonal_wind_projection','Meridional_wind_projection'};
OutVars = {'HLOS','U','V'};
  
              
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and bin data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

textprogressbar('Gridding data ')
for iDay=1:1:numel(Settings.TimeScale)
  
  %each file has the date as a string in the filename
  %generate this string and find all files for this day
  [y,m,d] = datevec(Settings.TimeScale(iDay));
  FileString = ['AE_2B_',sprintf('%04d',y),'-',sprintf('%02d',m),'-',sprintf('%02d',d)];
  OnThisDay = wildcardsearch(Settings.DataDir,['*',FileString,'*']);
  clear y m d FileString
  if numel(OnThisDay) == 0; clear OnThisDay; continue; end %no files
  
  %load all these files and glue their data together
  for iFile=1:1:numel(OnThisDay)
    FileData = rCDF(OnThisDay{iFile});
    if iFile == 1; Data = FileData;  Data = rmfield(Data,{'RG','MetaData'});
    else;          Data = cat_struct(Data,FileData,1,{'RG','MetaData'}); 
    end
  end; clear FileData iFile OnThisDay
  
  %apply QC flags
  Data = reduce_struct(Data,find(Data.QC_Flag_Both ==1));

  %pull out the region of interest
  Data = reduce_struct(Data,inrange(Data.lat,[min(Settings.LatScale),max(Settings.LatScale)]));
  

  %grid
  for iVar=1:1:numel(InVars)
    InField  = Data.(InVars{iVar});
    OutField = Results.(OutVars{iVar}); 
    zz = squeeze(bin2matN(3,Data.lon,Data.lat,Data.alt./1000,InField,xi,yi,zi,'@nanmean'))./100;
    OutField(iDay,:,:,:) = permute(zz,[2,1,3]); %again, nothing is in hours 24+
    Results.(OutVars{iVar}) = OutField;
 
  end; clear iVar dd hh InField OutField zz
  
  textprogressbar(iDay./numel(Settings.TimeScale).*100);
end; clear iDay xi yi InVars OutVars zi
textprogressbar('!')



save(Settings.OutFile,'Settings','Results')

% % % % % clearvars
% % % % % 
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % %prepare data for Aeolus SSW analysis
% % % % % %
% % % % % %Corwin Wright, c.wright@bath.ac.uk, 2021/01/06
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % 
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % %% settings
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % 
% % % % % Settings.DataDir     = [LocalDataDir,'/Aeolus/daily_gridded_uv_1day/'];
% % % % % Settings.LatScale    = -90:2:90;
% % % % % Settings.LonScale    = -180:15:180;
% % % % % Settings.TimeScale   = [datenum(2020,12,1)-5:1:datenum(2021,3,5)];  Settings.OutFile     = 'aeolus_data_3d_2021.mat';
% % % % % % Settings.TimeScale   = [datenum(2019,12,1):1:datenum(2020,2,30)];  Settings.OutFile     = 'aeolus_data_3d_1920.mat';
% % % % % Settings.HeightScale = 0:1.5:20;
% % % % % 
% % % % % 
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % %% prepare arrays
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % 
% % % % % %results arrays
% % % % % Results.HLOS = NaN(numel(Settings.TimeScale),   ...
% % % % %                    numel(Settings.LonScale),    ...
% % % % %                    numel(Settings.LatScale),    ...
% % % % %                    numel(Settings.HeightScale));
% % % % % Results.U = Results.HLOS;
% % % % % Results.V = Results.HLOS;
% % % % %               
% % % % % %working variables used throughout
% % % % % [xi,yi,zi] = meshgrid(Settings.LonScale,Settings.LatScale,Settings.HeightScale);
% % % % % InVars  = {'u','v'};
% % % % % OutVars = {'U','V'};
% % % % %   
% % % % %               
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % %% load and bin data
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % 
% % % % % textprogressbar('Gridding data ')
% % % % % for iDay=1:1:numel(Settings.TimeScale)
% % % % %   
% % % % %   %load the day's data
% % % % %   [yy,mm,dd] = datevec(Settings.TimeScale(iDay));
% % % % %   FileName = [Settings.DataDir,'/',sprintf('%04d',yy),sprintf('%02d',mm),sprintf('%02d',dd),'_aeolus_gridded_uv.mat'];
% % % % %   Data = load(FileName); Data = Data.Aeolus;
% % % % %   
% % % % %  %make the grids 3D
% % % % %   sz = size(Data.u);
% % % % %   Data.lat = repmat(Data.lat,1,1,sz(3));
% % % % %   Data.lon = repmat(Data.lon,1,1,sz(3));
% % % % %   
% % % % %   %change into profiles
% % % % %   Data.lat  = reshape(Data.lat, sz(1)*sz(2),sz(3));
% % % % %   Data.lon  = reshape(Data.lon, sz(1)*sz(2),sz(3));
% % % % %   Data.u    = reshape(Data.u,   sz(1)*sz(2),sz(3));
% % % % %   Data.v    = reshape(Data.v,   sz(1)*sz(2),sz(3));
% % % % %   Data.alt  = reshape(Data.walt,sz(1)*sz(2),sz(3));
% % % % % 
% % % % %   %grid
% % % % %   for iVar=1:1:numel(InVars)
% % % % %     InField  = Data.(InVars{iVar});
% % % % %     OutField = Results.(OutVars{iVar}); 
% % % % %     zz = squeeze(bin2matN(3,Data.lon,Data.lat,Data.alt,InField,xi,yi,zi,'@nanmean'));
% % % % %     OutField(iDay,:,:,:) = permute(zz,[2,1,3]); %again, nothing is in hours 24+
% % % % %     Results.(OutVars{iVar}) = OutField;
% % % % %  
% % % % %   end; clear iVar dd hh InField OutField zz
% % % % % 
% % % % %   textprogressbar(iDay./numel(Settings.TimeScale).*100);
% % % % % end; clear iDay xi yi InVars OutVars zi
% % % % % textprogressbar('!')
% % % % % 
% % % % % 
% % % % % 
% % % % % save(Settings.OutFile,'Settings','Results')