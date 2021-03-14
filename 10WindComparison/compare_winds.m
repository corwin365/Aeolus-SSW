clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compare multiple wind dataset's ability to see the SSW
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/26
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.LatRange   = [55,65];
Settings.Heights    = [22,15];
Settings.DataSets   = {'Aeolus','MLS','OpAl','ERA5'}; %first dataset will be used as correlation baseline
Settings.Colours    = {[57,106,177]./255,[218,124,48]./255,[204,37,41]./255,[1,.5,.5]};
Settings.LineStyles = {'-','-','-',':'};
Settings.TimeScale  = datenum(2020,12,1):1:datenum(2021,3,1);
Settings.SmoothSize = 3; %days

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% get data and inteprolate onto common scale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

U = NaN(numel(Settings.DataSets),numel(Settings.Heights),numel(Settings.TimeScale));

for iDS=1:1:numel(Settings.DataSets)
  
  
  %aim of this is to produce a dataset that is averaged over our geographic
  %and and of dimensions (height x time) in variable Uds, with meta t and z
  switch Settings.DataSets{iDS}
    case 'MLS'
      Data = load('01MlsGeostrophicWind/mls_gradient_winds.mat');
      InRange = inrange(Data.Results.u_lat,Settings.LatRange);
      Uds = squeeze(nanmean(Data.Results.U(:,:,InRange,:),[2,3]));
      t = Data.Settings.TimeScale; z = Data.Settings.HeightScale;
    case 'ERA5'
      Data = load('../02HeightTimeSeries/zm_data_era5_5565.mat');
      Uds = squeeze(Data.Results.Data(1,:,:));
      t   = Data.Settings.Grid.TimeScale;  z   = Data.Settings.Grid.HeightScale;
    case 'OpAl'
      Data = load('../02HeightTimeSeries/zm_data_era5_5565.mat');
      Uds = squeeze(Data.Results.Data(4,:,:));
      t   = Data.Settings.Grid.TimeScale;  z   = Data.Settings.Grid.HeightScale;      
    case 'Aeolus'      
      Data = load('../02HeightTimeSeries/zm_data_aeolus.mat');
      Uds = squeeze(Data.Results.Data(1,:,:));
      t   = Data.Settings.Grid.TimeScale;   z   = Data.Settings.Grid.HeightScale;
    otherwise; disp('Dataset not handled by routine'); stop;

  end
  clear Data InRange
  
  %extract, interpolate, store
  for iLevel=1:1:numel(Settings.Heights)
    %we'll interpolate here for future generality, but in practice all the
    %planned datasets have already been daily-gridded anywya so this does
    %nothing to the data
    U(iDS,iLevel,:) = interp1(t,Uds(:,closest(z,Settings.Heights(iLevel))),Settings.TimeScale);
  end
  
  clear iLevel Uds t z
  
  
end; clear iDS

%bad point in aeolus due to partial day. mention in paper.
U(1,1,8) = nanmean(U(1,1,[7,9]),3);

%bad point in MLS due to partial day. mention in paper
U(2,:,54) = nanmean(U(2,:,[53,55]),3);


%smooth?
U = smoothn(U,[1,1,Settings.SmoothSize]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')
Letters = 'ab';

for iLevel=1:1:numel(Settings.Heights)
  
  %create panel
  subplot(numel(Settings.Heights),1,iLevel)
  
  %plot data
  for iDS=1:1:numel(Settings.DataSets)
    
    plot(Settings.TimeScale,squeeze(U(iDS,iLevel,:)), ...
         'color',Settings.Colours{iDS},'linewi',3, ...
         'linestyle',Settings.LineStyles{iDS})
    hold on
  end
  
  %zero wind line and SSW line
  plot(minmax(Settings.TimeScale),[0,0],'k-')
  plot([1,1].*datenum(2021,1,5),get(gca,'ylim'),'k-')
  
  %tidy
  set(gca,'xtick',datenum(2021,1,-105:10:105), ...
          'xticklabel',datestr(datenum(2020,1,-105:10:105),'dd/mmm'))
  set(gca,'tickdir','out')
  xlim(minmax(Settings.TimeScale))
  if iLevel==1;set(gca,'xaxislocation','top'); end  
  
  %labelling
  ylabel('Zonal Mean Zonal Wind [ms^{-1}]')
  text(min(get(gca,'xlim'))+0.01.*range(get(gca,'xlim')), ...
       min(get(gca,'ylim'))+0.06.*range(get(gca,'ylim')), ...
       ['(',Letters(iLevel),') ',num2str(Settings.Heights(iLevel)),'km, ', ...
       num2str(Settings.LatRange(1)),'-',num2str(Settings.LatRange(2)),'N'], ...
       'fontsize',20)
  
  %key, with correlations and RMSDs
  for iDS=1:1:numel(Settings.DataSets)
    if iDS ~= 1;
      a = squeeze(U(iDS,iLevel,:)); b = squeeze(U(1,iLevel,:));
      Good = find(~isnan(a+b));
      
      %correlation
      r =  corrcoef(a(Good),b(Good)); r = r(2);
      
      %rmsd
      RMSD = sqrt(mean((a(Good)-b(Good)).^2));
      
      CorrText = ['r = ',sprintf('%1.3f',r),'  RMSD = ',sprintf('%1.2f',RMSD)];
      
      clear a b Good r RMSD
    else CorrText = ''; end
      
    
    plot(max(get(gca,'xlim'))-[0.58,0.51].*range(get(gca,'xlim')), ...
         [1,1].*max(get(gca,'ylim'))-0.07.*iDS.*range(get(gca,'ylim')), ...
         '-','color',Settings.Colours{iDS},'linewi',3,'linestyle',Settings.LineStyles{iDS})
    text(max(get(gca,'xlim'))-0.5.*range(get(gca,'xlim')), ...
         max(get(gca,'ylim'))-0.07.*iDS.*range(get(gca,'ylim')), ...
         Settings.DataSets{iDS},'color',Settings.Colours{iDS})
    text(max(get(gca,'xlim'))-0.45.*range(get(gca,'xlim')), ...
         max(get(gca,'ylim'))-0.07.*iDS.*range(get(gca,'ylim')), ...
         CorrText,'color',Settings.Colours{iDS})       
  end
     

  %second set of axes (pressure and SSW-relative days)
  %done last as this affects all subsequent positioning
  ax1 = gca;
  ax2 = axes('Position',ax1.Position,...
             'XAxisLocation','bottom',...
             'YAxisLocation','right',...
             'Color','none', ...
             'tickdir','out');
  axis([minmax(Settings.TimeScale), 0 1])  %I have no idea what the 3.25 day shift is - plotting bug?!? - but this makes the top and bottom axes align perfectly          
  set(gca,'xtick',datenum(2021,1,5+(-100:10:100)), ...
          'xticklabel',-100:10:100, ...
          'ytick',[])  
  if iLevel==2;set(gca,'xaxislocation','top'); xlabel('Days since major SSW commenced'); end

     
     
  
end
