clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compute zonal mean stratopause height at 60N, using output from
%find_stratopause_simple
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/24
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.TimeScale = datenum(2019,1,1):1:datenum(2021,12,31); %not all days will be filled - this is fine
Settings.LatRange  = [60,90];
Settings.OutFile   = 'stratopause_6090N.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%create results array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Results = NaN(numel(Settings.TimeScale),1);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%fill results array
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

OldFile = '';
for iDay=1:1:numel(Settings.TimeScale);
  
  %load file, if needed
  [y,~,~] = datevec(Settings.TimeScale(iDay));
  FilePath = [LocalDataDir,'/corwin/era5_stratopause_',num2str(y),'.mat'];
  if strcmp(FilePath,OldFile) ~= 1;
    %do we have this data?
    if ~exist(FilePath,'file'); clear FilePath y; continue; end
    %load data
    Data = load(FilePath);
    OldFile = FilePath;
  end; clear FilePath y
  
  %calculate value for this day
  ThisDay = find(Data.Settings.TimeScale == Settings.TimeScale(iDay));
  if numel(ThisDay) == 0; clear ThisDay; continue; end
  InLatRange = inrange(Data.Results.Lat,Settings.LatRange);
  
  Results(iDay,:) = p2h(nanmean(Data.Results.Stratopause(:,InLatRange,:,ThisDay),'all'));
  clear ThisDay InLatRange
  
  
end; clear iDay OldFile Data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%save
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Time = Settings.TimeScale;
Height = Results;
save(Settings.OutFile,'Time','Height');