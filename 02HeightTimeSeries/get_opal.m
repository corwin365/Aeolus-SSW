function OpAl = get_opal(Date,DataDir,InVars,OutVars)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load and return ECMWF operational analysis data in standard format for gridding
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/28
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%create an array of empty variables, in case nothing is found to return
OpAl.Lat  = [];
OpAl.Lon  = [];
OpAl.Lat  = [];
OpAl.Time = [];
for iVar=1:1:numel(InVars)
  OpAl.(OutVars{iVar}) = [];
end


%ok, let's get going

%load data
[y,~,~] = datevec(Date); dn = date2doy(Date);
FilePath = [DataDir,'/corwin/opal/',sprintf('%04d',y),'/', ...
                     '/','opal_',sprintf('%04d',y),'d',sprintf('%03d',dn),'.nc'];
if ~exist(FilePath,'file'); return; end                   
Data = rCDF(FilePath);                   

%produce height axis
Data.Z = p2h(ecmwf_prs_v2([],137));

%convert heights to box-centres
a = diff(Data.Z); a = [a;a(end)];
Data.Z = Data.Z + a;
clear a

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
OpAl.Lat  = Lat(:);
OpAl.Lon  = Lon(:);
OpAl.Alt  = Z(:);
OpAl.Time = t(:);

for iVar=1:1:numel(InVars)
  OpAl.(OutVars{iVar}) = flatten(Data.(InVars{iVar}));
end

end

