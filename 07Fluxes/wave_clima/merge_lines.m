clearvars -except SSWDates

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% merge individual SSW u'v' and u'T' time series into a single file
%
%Corwin Wright, c.wright@bath.ac.uk
%2021/03/14
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load data and append to a single array
for iSSW = 1:1:numel(SSWDates)
  iSSW
  %load file
  Data = load(['fluxes_',num2str(SSWDates(iSSW)),'.mat']);
  
  
  %if first file, create master arrays
  if iSSW==1; Store = Data; Store.SSWs = SSWDates;
  else
    %now store, what we came for
    Store.Grid.TimeScale = cat(5,Store.Grid.TimeScale,Data.Grid.TimeScale);
    Store.HeatFlux.ReA   = cat(5,Store.HeatFlux.ReA,  Data.HeatFlux.ReA);
    Store.MomFlux.ReA    = cat(5,Store.MomFlux.ReA,   Data.MomFlux.ReA);
    
    
  end
  clear Data
end
clear iSSW

save('merged_ssw_clima.mat','Store')