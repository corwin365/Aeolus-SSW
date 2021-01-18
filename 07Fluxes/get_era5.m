function Era5 = get_era5(Date,DataDir,InVars,OutVars)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load and return ERA5 data in standard format for gridding
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/13
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%create an array of empty variables, in case nothing is found to return
Era5.Lat  = [];
Era5.Lon  = [];
Era5.Lat  = [];
Era5.Time = [];
for iVar=1:1:numel(InVars)
  Era5.(OutVars{iVar}) = [];
end


%ok, let's get going

%load ERA5 data
try  Data = rCDF(era5_path(Date,DataDir,1)); catch; return; end

%produce height axis
Data.Z = p2h(ecmwf_prs_v2([],137));

%convert time to Matlab time
Data.time = datenum(1900,1,1,Data.time,0,0);

%mash the geolocation points around into the data grid
sz = size(Data.t);
Lon = repmat(              Data.longitude,1,sz(2),sz(3),sz(4));
Lat = repmat(permute(Data.latitude,[2,1]),sz(1),1,sz(3),sz(4));
Z   = repmat(permute(     Data.Z,[2,3,1]),sz(1),sz(2),1,sz(4));
t   = repmat(permute(Data.time,[2,3,4,1]),sz(1),sz(2),sz(3),1);


%convert longitudes and latitudes to box centre
Lon = Lon + mean(diff(Data.longitude));
Lat = Lat + mean(diff(Data.latitude));

%shift longitudes into -180:180
Lon(Lon > 180) = Lon(Lon > 180)-360;

%pull out the requested variables, plus geolocation
Era5.Lat  = Lat(:);
Era5.Lon  = Lon(:);
Era5.Alt  = Z(:);
Era5.Time = t(:);

for iVar=1:1:numel(InVars)
  Era5.(OutVars{iVar}) = flatten(Data.(InVars{iVar}));
end

end

