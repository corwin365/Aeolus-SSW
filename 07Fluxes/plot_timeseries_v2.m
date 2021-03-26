clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compute eddy:
%    - heat flux  T'v'
%    - momentum flux u'v'
%from Aeolus and MLS data, and (separately) ERA5 output
%
%
%this is a completely clean plotting routine, produced to check the heat
%flux and momentum flux time series as they look weird. it shows that the
%original routine, if a bit messy, is right.
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/03/26
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%files
%%%%%%%%%%%%%%%%%%%%%%
Settings.Files.ThisYear = 'fluxes_c.mat';


%%region and time settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.LonRange   = [-180,180];
Settings.LatRange   = [45,75];
Settings.Levels     = p2h([50,100,150]);
Settings.TimeRange  = datenum(2021,1,[-15,15]);
Settings.CentreDate = datenum(2021,1,5);


%%smoothing and scaling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%time series smoothing
Settings.SmoothDays = 3;

%scale up obs?
Settings.ScaleFactor = 10; %set to one to deactivate

%%line colours
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%colours
cbrew = cbrewer('qual','Set1',9);
Colours.ReA = [0,0,0];
Colours.Obs = cbrew(5,:);
Colours.NoV = [1,1,1].*0.6;%cbrew(5,:);
Colours.Hyb = cbrew(2,:);
clear cbrew


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and prep data for 2020/21
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load data
Data = load(Settings.Files.ThisYear);

%glue the data into one array, to allow single operations
Store = Data.HeatFlux.Obs;
Store = cat(5,Store,Data.HeatFlux.ReA);
Store = cat(5,Store,Data.HeatFlux.Hyb);
Store = cat(5,Store,Data.MomFlux.Obs);
Store = cat(5,Store,Data.MomFlux.Hyb);
Store = cat(5,Store,Data.MomFlux.Hyb);

%geographically and temporally subset
lonidx = inrange(Data.Grid.LonScale, Settings.LonRange);
latidx = inrange(Data.Grid.LatScale, Settings.LatRange);
tidx   = inrange(Data.Grid.TimeScale,Settings.TimeRange);
levidx = []; for iLev=1:1:numel(Settings.Levels); levidx(end+1) = closest(Data.Grid.HeightScale,Settings.Levels(iLev)); end; clear iLev

Store = Store(tidx,:,:,:,:);
Store = Store(:,levidx,:,:,:);
Store = Store(:,:,lonidx,:,:);
Store = Store(:,:,:,latidx,:);

%then regionally average
Store = squeeze(nanmean(Store,[3,4]));

%smooth the data
Store = smoothn(Store,[Settings.SmoothDays,1,1]);

%and separate out the variables again
HF.Obs = Store(:,:,1); MF.Obs = Store(:,:,4);
HF.ReA = Store(:,:,2); MF.ReA = Store(:,:,5);
HF.Hyb = Store(:,:,3); MF.Hyb = Store(:,:,6);

%retain time scale
TimeScale = Data.Grid.TimeScale(tidx) - Settings.CentreDate ;


clear Store lonidx latidx tidx levidx Data


%scale obs
HF.Obs = HF.Obs .* Settings.ScaleFactor;
MF.Obs = MF.Obs .* Settings.ScaleFactor;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot data!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

k = 0;
for iLevel = 1:1:numel(Settings.Levels)
  for iVar=1:1:2;
    
    switch iVar
      case 1; Data = HF;
      case 2; Data = MF;
    end
   
    %prepare panel
    
    k = k+1;subplot(numel(Settings.Levels),2,k)
    cla; hold on
    
    
    %plot data
    plot(TimeScale,Data.Obs(:,iLevel),'color',Colours.Obs)
    plot(TimeScale,Data.ReA(:,iLevel),'color',Colours.ReA)
    plot(TimeScale,Data.Hyb(:,iLevel),'color',Colours.Hyb)    
    
    xlim(Settings.TimeRange-Settings.CentreDate)
    
  end
end
