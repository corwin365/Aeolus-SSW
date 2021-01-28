clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compute MLS geostrophic wind for the 2021 SSW
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/25
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%file locations
Settings.Mls.DataDir = [LocalDataDir,'/MLS/'];
Settings.OutFile     = 'mls_gradient_winds.mat';

%gridding
Settings.LatScale    = -90:5:90;  
Settings.LonScale    = -180:20:180; 
Settings.TimeScale   = datenum(2020,10,1):1:datenum(2021,3,31);
Settings.HeightScale = [10:4:50,54:6:120]; %km



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% results arrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Results.U    = NaN(numel(Settings.TimeScale),   ...
                   numel(Settings.LonScale)-1,  ...
                   numel(Settings.LatScale)-2,  ...
                   numel(Settings.HeightScale));
                 
Results.V    = NaN(numel(Settings.TimeScale),   ...
                   numel(Settings.LonScale)-2,  ...
                   numel(Settings.LatScale)-1,  ...
                   numel(Settings.HeightScale));              


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% repeatedly-used internal variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[xi,yi,zi] = meshgrid(Settings.LonScale,   ...
                      Settings.LatScale,   ...
                      Settings.HeightScale);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% process
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

textprogressbar('Computing MLS winds ')
for iDay=1:1:numel(Settings.TimeScale)
  textprogressbar(iDay./numel(Settings.TimeScale).*100)
  
  %get GPH data for the day
  Data = get_mls(Settings.TimeScale(iDay), ...
                 Settings.Mls.DataDir,          ...
                 {'GPH'},{'GPH'});
  if numel(Data.Lat) == 0; continue; end %no data found
               
               
  %grid it
  zz = bin2matN(3,Data.Lon,Data.Lat,Data.Alt, ...
                  Data.GPH,                   ...
                  xi,yi,zi);

  %deal with beyond-edge bins
  zz = zz(:,1:end-1,:);
  zz = zz(1:end-1,:,:);
                
  %compute u and v
  CalcVars.LonScale  = Settings.LonScale(1:end-1);
  CalcVars.LatScale  = Settings.LatScale(1:end-1);
  CalcVars.GPH       = zz;
  [u,v,u_lat,v_lon] = compute_geostrophic_wind(CalcVars);
  clear CalcVars zz
  

  %store!
  Results.U(iDay,:,:,:) = permute(u,[2,1,3]);
  Results.V(iDay,:,:,:) = permute(v,[2,1,3]);
  if ~isfield(Results,'u_lat'); Results.u_lat = u_lat; end
  if ~isfield(Results,'v_lon'); Results.v_lon = v_lon; end  
  clear u v u_lon v_lat

  


end; clear iDay
textprogressbar(100);textprogressbar('!')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  

Settings.LonScale  = Settings.LonScale(1:end-1);
Settings.LatScale  = Settings.LatScale(1:end-1);

save(Settings.OutFile,'Settings','Results')