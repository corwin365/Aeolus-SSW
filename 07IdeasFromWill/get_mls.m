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


%ok, let's get going


%load MLS data for this day
[yy,~,~] = datevec(Date);
dd = date2doy(Date);
FileName = wildcardsearch(DataDir,['*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);
clear yy dd
if numel(FileName) == 0; clear FileName; return; end

%two versions mixed...
Data = get_MLS(FileName{1},'Temperature');
if numel(Data.L2gpValue) == 0; Data = get_MLS(FileName{1},'Temperature_StdProd');end

Data.T = Data.L2gpValue(:);
[l,p] = meshgrid(Data.Latitude,p2h(Data.Pressure));
Data.Lat  = l;
Data.Z    = p;
Data.Time = repmat(datenum(1993,1,1,0,0,Data.Time),1,numel(Data.Pressure));
clear l p


%pull out the requested variable,s plus geolocation
Mls.Lat  = flatten(repmat( Data.Latitude,1,numel(Data.Pressure))');
Mls.Lon  = flatten(repmat(Data.Longitude,1,numel(Data.Pressure))');
Mls.Alt  = flatten(Data.Z);
Mls.Time = flatten(Data.Time');

for iVar=1:1:numel(InVars)
  Mls.(OutVars{iVar}) = flatten(Data.(InVars{iVar}));
end



end

