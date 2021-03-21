function Mls = get_mls(Date,DataDir,InVars,OutVars)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load and return MLS data in standard format for gridding
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/13
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%create an array of empty variables, in case nothing is found to return
Mls.Lat  = [];
Mls.Lon  = [];
Mls.Lat  = [];
Mls.Time = [];
for iVar=1:1:numel(InVars)
  Mls.(OutVars{iVar}) = [];
end


%OK, let's get going
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%find all MLS files for the day
[yy,~,~]      = datevec(Date);
dd            = date2doy(Date);
FileNames.T   = wildcardsearch([DataDir,  '/T/',sprintf('%04d',yy)],['*Temperature*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);
FileNames.O3  = wildcardsearch([DataDir, '/O3/',sprintf('%04d',yy)],[         '*O3*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);
FileNames.CO  = wildcardsearch([DataDir, '/CO/',sprintf('%04d',yy)],[         '*CO*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);
FileNames.GPH = wildcardsearch([DataDir,'/GPH/',sprintf('%04d',yy)],[        '*GPH*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);
clear yy dd

%temperature is the baseline, always load it.
if numel(FileNames.T) == 0; return; end
Data.T = get_MLS(FileNames.T{1},'Temperature');
if numel(Data.T.L2gpValue) == 0; Data.T = get_MLS(FileNames.T{1},'Temperature_StdProd');end
% if numel(Data.T.L2gpValue) == 0; return; end


%load other variables if requested
DoneWind = 0;
for iVar=1:1:numel(InVars)
  
  if strcmp(InVars{iVar},'T')
    continue;
    
    
  elseif strcmp(InVars{iVar},'O3')
    if numel(FileNames.O3) == 0;Data.O3.L2gpValue = Data.T.L2gpValue.*NaN; continue; end
    if ~exist(FileNames.O3{1},'file'); Data.O3.L2gpValue = Data.T.L2gpValue.*NaN; continue; end
    Data.O3 = get_MLS(FileNames.O3{1},'O3');
    Data.O3.L2gpValue(Data.O3.Pressure < 0.001) = NaN;
    Data.O3.L2gpValue(Data.O3.Pressure > 261)   = NaN;

  
  elseif strcmp(InVars{iVar},'GPH')
    if numel(FileNames.GPH) == 0;Data.GPH.L2gpValue = Data.T.L2gpValue.*NaN; continue; end    
    if ~exist(FileNames.GPH{1},'file'); Data.GPH.L2gpValue = Data.T.L2gpValue.*NaN; continue; end    
    Data.GPH = get_MLS(FileNames.GPH{1},'GPH');
    Data.GPH.L2gpValue(Data.GPH.Pressure > 261)   = NaN;

  
  
  elseif strcmp(InVars{iVar},'CO')
    if numel(FileNames.CO) == 0;Data.CO.L2gpValue = Data.T.L2gpValue.*NaN; continue; end
    if ~exist(FileNames.CO{1},'file'); Data.CO.L2gpValue = Data.T.L2gpValue.*NaN; continue; end    
    Data.CO = get_MLS(FileNames.CO{1},'CO');
    Data.CO.L2gpValue = interp1(p2h(Data.CO.Pressure),Data.CO.L2gpValue,p2h(Data.T.Pressure));
    Data.CO.L2gpValue(Data.T.Pressure < 0.001) = NaN;
    Data.CO.L2gpValue(Data.T.Pressure > 215)   = NaN;
    
    
  elseif strcmp(InVars{iVar},'U') | strcmp(InVars{iVar},'V')
    %U and V are calculated together, and this is relatively slow
    %so, if we ask for both, only do it once and save the time
    if DoneWind ==1; continue; end
    
    %Ok. First, get GPH
    if numel(FileNames.GPH) == 0;Data.GPH.L2gpValue = Data.T.L2gpValue.*NaN; continue; end    
    if ~exist(FileNames.GPH{1},'file'); Data.GPH.L2gpValue = Data.T.L2gpValue.*NaN; continue; end    
    Data.GPH = get_MLS(FileNames.GPH{1},'GPH');
    Data.GPH.L2gpValue(Data.GPH.Pressure > 261)   = NaN;    
    
    %now, grid the GPH in 3D
    [xi,yi,zi] = meshgrid(-180:20:180, ...
                           -90: 5: 90, ...
                           1:2:numel(Data.GPH.Pressure));
    [lon,~] = meshgrid(Data.GPH.Longitude,p2h(Data.GPH.Pressure));
    [lat,z] = meshgrid( Data.GPH.Latitude,p2h(Data.GPH.Pressure));  
    zz = bin2matN(3,lon,lat,z,Data.GPH.L2gpValue,xi,yi,zi);
    zz = zz(:,1:end-1,:);
    zz = zz(1:end-1,:,:);
    
    %compute u and v
    CalcVars.LonScale  = -180:20:180-20;
    CalcVars.LatScale  =  -90: 5: 90-5;
    CalcVars.GPH       = zz;
    [u,v,u_lat,v_lon] = compute_geostrophic_wind(CalcVars);

    %interpolate to the measurement locations (including shifting z-values
    %to bin-centre to support interpolation within 3d volumes - lat and lon
    %already shifted)
    zo = [p2h(Data.GPH.Pressure(2:2:end));max(p2h(Data.GPH.Pressure(2:2:end)))+mean(diff(p2h(Data.GPH.Pressure(2:2:end))))];
    I.U = griddedInterpolant({u_lat,CalcVars.LonScale,zo},u);
    I.V = griddedInterpolant({CalcVars.LatScale,v_lon,zo},v);
    clear xi yi zi lon lat z zz CalcVars u v u_lat v_lon zo
    
    [lon,~] = meshgrid(Data.GPH.Longitude,p2h(Data.GPH.Pressure));
    [lat,z] = meshgrid( Data.GPH.Latitude,p2h(Data.GPH.Pressure));
    
    Data.U.L2gpValue = I.U(double(lat),double(lon),z);
    Data.V.L2gpValue = I.V(double(lat),double(lon),z); 
    clear lon lat z I
    DoneWind = 1;
    
    
  else
    disp('Dataset not specified in routine')
    stop
  end
      
end
clear DoneWind


[~,p] = meshgrid(Data.T.Latitude,p2h(Data.T.Pressure));
Z    = p;
Time = repmat(datenum(1993,1,1,0,0,Data.T.Time),1,numel(Data.T.Pressure))';
clear p



%pull out the requested variable,s plus geolocation
Mls.Lat  = flatten(repmat( Data.T.Latitude,1,numel(Data.T.Pressure))');
Mls.Lon  = flatten(repmat(Data.T.Longitude,1,numel(Data.T.Pressure))');
Mls.Alt  = flatten(Z);
Mls.Time = flatten(Time');
clear Z Time 


for iVar=1:1:numel(InVars)
  if isfield(Data,InVars{iVar})
    Mls.(OutVars{iVar}) = flatten(Data.(InVars{iVar}).L2gpValue);
  end
end


end

