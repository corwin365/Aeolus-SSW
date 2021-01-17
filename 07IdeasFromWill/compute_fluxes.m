clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compute eddy:
%    - heat flux  T'v'
%    - momentum flux u'v'
%from Aeolus and MLS data, and (separately) ERA5 output
%
%also compute a "hybrid" version avoiding Aeolus Vp, which is very error-y

%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/13
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.InFile  = 'gridded_data.mat';
Settings.OutFile = 'fluxes.mat';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = load(Settings.InFile,'Results'); Data = Data.Results;



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% remove outliers, then fill NaNs in each map including those we removed
%. Not ideal, but we have no choice if we're going
%to take the zonal mean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iDataSet = 1:1:size(Data,1)
  for iDay = 1:1:size(Data,2)
    for iLevel = 1:1:size(Data,3)

      ThisLev = squeeze(Data.Data(iDataSet,iDay,iLevel,:,:));      
      
      %no effect on results!
      Outliers = find(ThisLev > nanmean(ThisLev(:)) + 2.*nanstd(ThisLev(:)));
      ThisLev(Outliers) = NaN;
      
      Data.Data(iDataSet,iDay,iLevel,:,:) = inpaint_nans(ThisLev);

    end
  end
end
clear iDataSet iDay iLevel



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
Obs.Tp = squeeze(Perturbations(find(contains(Data.InstList,   'Mls') & contains(Data.VarList,'T')),:,:,:,:));
Obs.Vp = squeeze(Perturbations(find(contains(Data.InstList,'Aeolus') & contains(Data.VarList,'V')),:,:,:,:));
ReA.Tp = squeeze(Perturbations(find(contains(Data.InstList,  'Era5') & contains(Data.VarList,'T')),:,:,:,:));
ReA.Vp = squeeze(Perturbations(find(contains(Data.InstList,  'Era5') & contains(Data.VarList,'V')),:,:,:,:));

%hence, compute value
HeatFlux.Obs = Obs.Tp .* Obs.Vp;
HeatFlux.ReA = ReA.Tp .* ReA.Vp;
HeatFlux.Hyb = Obs.Tp .* ReA.Vp;
HeatFlux.NoV = Obs.Tp .* ones(size(ReA.Vp)).*nanmean(ReA.Vp);

clear ReA Obs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% compute eddy momentum flux
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%get variables needed
Obs.Up = squeeze(Perturbations(find(contains(Data.InstList,'Aeolus') & contains(Data.VarList,'U')),:,:,:,:));
Obs.Vp = squeeze(Perturbations(find(contains(Data.InstList,'Aeolus') & contains(Data.VarList,'V')),:,:,:,:));
ReA.Up = squeeze(Perturbations(find(contains(Data.InstList,  'Era5') & contains(Data.VarList,'U')),:,:,:,:));
ReA.Vp = squeeze(Perturbations(find(contains(Data.InstList,  'Era5') & contains(Data.VarList,'V')),:,:,:,:));

%hence, compute value
MomFlux.Obs  = Obs.Up .* Obs.Vp;
MomFlux.ReA  = ReA.Up .* ReA.Vp;
MomFlux.Hyb  = Obs.Up .* ReA.Vp;
MomFlux.NoV = Obs.Up .* ones(size(ReA.Vp)).*nanmean(ReA.Vp);
clear ReA Obs

clear Perturbations


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% save outputs and geolocation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Grid = Data.Grid;
save(Settings.OutFile,'MomFlux','HeatFlux','Grid')
