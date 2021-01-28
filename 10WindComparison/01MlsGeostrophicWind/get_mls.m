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
FileNames.T   = wildcardsearch(DataDir,['*Temperature*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);
FileNames.O3  = wildcardsearch(DataDir,[         '*O3*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);
FileNames.CO  = wildcardsearch(DataDir,[         '*CO*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);
FileNames.GPH = wildcardsearch(DataDir,[        '*GPH*',sprintf('%04d',yy),'d',sprintf('%03d',dd),'*']);


%temperature is the baseline, always load it.
if numel(FileNames.T) == 0; return; end
Data.T = get_MLS(FileNames.T{1},'Temperature');
if numel(Data.T.L2gpValue) == 0; Data.T = get_MLS(FileNames.T{1},'Temperature_StdProd');end
% if numel(Data.T.L2gpValue) == 0; return; end


%load other variables if requested
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
    
  else
    disp('Dataset not specified in routine')
    stop
  end
      
end


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
  Mls.(OutVars{iVar}) = flatten(Data.(InVars{iVar}).L2gpValue);
end


end

