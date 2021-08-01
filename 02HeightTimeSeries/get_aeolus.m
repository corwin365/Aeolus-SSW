function Aeolus = get_aeolus(Date,DataDir,InVars,OutVars)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%load and return Aeolus data in standard format for gridding
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/13
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%create an array of empty variables, in case nothing is found to return
Aeolus.Lat  = [];
Aeolus.Lon  = [];
Aeolus.Lat  = [];
Aeolus.Time = [];
for iVar=1:1:numel(InVars)
  Aeolus.(OutVars{iVar}) = [];
end


%ok, let's get going

%load the day's data
[yy,mm,dd] = datevec(Date);
FileName = [DataDir,'/',sprintf('%04d',yy),sprintf('%02d',mm),sprintf('%02d',dd),'_aeolus_gridded_uv.mat'];
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


%pull out the requested variables, plus geolocation
Aeolus.Lat  = Data.lat;
Aeolus.Lon  = Data.lon;
Aeolus.Alt  = Data.alt;
Aeolus.Time = datenum(2000,1,1,12,0,0).*ones(size(Aeolus.Lon));

for iVar=1:1:numel(InVars)
  Aeolus.(OutVars{iVar}) = Data.(InVars{iVar});
end



end

