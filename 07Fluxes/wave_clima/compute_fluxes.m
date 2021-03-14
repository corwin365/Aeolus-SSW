clearvars -except CENTREDAY SSWDates iSSW

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compute eddy:
%    - heat flux  T'v'
%    - momentum flux u'v'
%from ERA5 output
%
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/03/14
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.InFile  = ['gridded_data_',num2str(CENTREDAY),'.mat'];
Settings.OutFile = ['fluxes_',num2str(CENTREDAY),'.mat'];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = load(Settings.InFile,'Results'); Data = Data.Results;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compute zonal means, and hence find perturbation terms
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ZM = nanmean(Data.Data,4);
Perturbations = Data.Data-repmat(ZM,1,1,1,size(Data.Data,4),1);
clear ZM

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compute eddy heat flux
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%get variables needed
ReA.Tp = squeeze(Perturbations(find(contains(Data.InstList,  'Era5') & contains(Data.VarList,'T')),:,:,:,:));
ReA.Vp = squeeze(Perturbations(find(contains(Data.InstList,  'Era5') & contains(Data.VarList,'V')),:,:,:,:));

%hence, compute value
HeatFlux.ReA = ReA.Tp .* ReA.Vp;

clear ReA

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compute eddy momentum flux
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%get variables needed
ReA.Up = squeeze(Perturbations(find(contains(Data.InstList,  'Era5') & contains(Data.VarList,'U')),:,:,:,:));
ReA.Vp = squeeze(Perturbations(find(contains(Data.InstList,  'Era5') & contains(Data.VarList,'V')),:,:,:,:));

%hence, compute value
MomFlux.ReA  = ReA.Up .* ReA.Vp;
clear ReA

clear Perturbations


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save outputs and geolocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Grid = Data.Grid;
save(Settings.OutFile,'MomFlux','HeatFlux','Grid')
