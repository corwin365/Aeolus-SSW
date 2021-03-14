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
Settings.Heights    = [32,22,15];
Settings.DataSets   = {'Aeolus','MLS','OpAl','ERA5'}; %first dataset will be used as correlation baseline
Settings.Colours    = {[57,106,177]./255,[218,124,48]./255,[204,37,41]./255,[1,.5,.5]};
Settings.LineStyles = {'-','-','-',':'};
Settings.TimeScale  = datenum(2020,11,1):1:datenum(2021,3,1);
Settings.SmoothSize = 5; %days

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
U(1,3,8) = nanmean(U(1,1,[7,9]),3);

%bad point in MLS due to partial day. mention in paper
U(2,:,54) = nanmean(U(2,:,[53,55]),3);


%smooth?
U = smoothn(U,[1,1,Settings.SmoothSize]);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')
Letters = 'abcd';
subplot = @(m,n,p) subtightplot (m, n, p, 0.1, 0.05, 0.1);


for iLevel=1:1:numel(Settings.Heights)
  
  %create panel
  subplot(numel(Settings.Heights),5,[0,1,2,3]-4+iLevel.*5)
  xlim(minmax(Settings.TimeScale)); hold on

  
  %plot data
  for iDS=[3,4,2,1];%numel(Settings.DataSets)
    
    if iDS ==1 & iLevel < 2; continue; end
    
    plot(Settings.TimeScale,squeeze(U(iDS,iLevel,:)), ...
         'color',Settings.Colours{iDS},'linewi',3, ...
         'linestyle',Settings.LineStyles{iDS})
    hold on
  end
  
  %zero wind line and SSW line
  plot(minmax(Settings.TimeScale),[0,0],'k-')
  plot([1,1].*datenum(2021,1,5),get(gca,'ylim'),'k-')
   
  %labelling
  ylabel('U [ms^{-1}]')
  text(min(get(gca,'xlim'))+0.01.*range(get(gca,'xlim')), ...
       min(get(gca,'ylim'))+0.07.*range(get(gca,'ylim')), ...
       ['(',Letters(iLevel),') ',num2str(Settings.Heights(iLevel)),'km, ', ...
       num2str(Settings.LatRange(1)),'-',num2str(Settings.LatRange(2)),'N'], ...
       'fontsize',16,'fontweight','bold')
  
  %key, with correlations and RMSDs
  for iDS=1:1:numel(Settings.DataSets)
    if iDS ~= 1 & iLevel > 1;
      a = squeeze(U(iDS,iLevel,:)); b = squeeze(U(1,iLevel,:));
      Good = find(~isnan(a+b));
      
      %correlation
      r =  corrcoef(a(Good),b(Good)); r = r(2);
      
      %rmsd
      RMSD = sqrt(mean((a(Good)-b(Good)).^2));
      
      CorrText = ['r = ',sprintf('%1.3f',r),'  RMSD = ',sprintf('%1.2f',RMSD)];
      
      clear a b Good r RMSD
    else CorrText = ''; end
      

    if iLevel == 1
      plot(max(get(gca,'xlim'))+[0.05,0.18].*range(get(gca,'xlim')), ...
           [1,1].*max(get(gca,'ylim'))-0.12.*iDS.*range(get(gca,'ylim')), ...
           '-','color',Settings.Colours{iDS},'linewi',3,'linestyle',Settings.LineStyles{iDS}, ...
           'clipping','off')
      text(max(get(gca,'xlim'))+0.20.*range(get(gca,'xlim')), ...
           max(get(gca,'ylim'))-0.12.*iDS.*range(get(gca,'ylim')), ...
           Settings.DataSets{iDS},'color',Settings.Colours{iDS})
    else
      text(max(get(gca,'xlim'))+0.02.*range(get(gca,'xlim')), ...
           max(get(gca,'ylim'))-0.10.*iDS.*range(get(gca,'ylim')), ...
           CorrText,'color',Settings.Colours{iDS},'fontsize',11)
    end
  end
     

  %tidy
  box on; grid on
  set(gca,'tickdir','out')
  
  %axes. These are a bit complicated
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  TickTimes = (-14*10+5):14:(14*10+5);
  TickDates = datenum(2021,1,TickTimes);
  
  %primary axes
  if iLevel == 1 || iLevel ==  3 ;
    set(gca,'xtick',             TickDates,       ...
            'xticklabel',datestr(TickDates,'dd/mmm'));
          h = gca; h.XAxis.FontSize = 11; 
  else
    set(gca,'xtick',TickDates,'xticklabel',TickTimes-5);
    
  end
  if iLevel == 1; set(gca,'xaxislocation','top'); end

  
  %secondary axes
  ax1 = gca;
  ax2 = axes('Position',ax1.Position,...
             'XAxisLocation','bottom',...
             'YAxisLocation','right',...
             'Color','none', ...
             'tickdir','out');
  axis([minmax(Settings.TimeScale), 0 1]) 
  grid off
  set(gca,'ytick',999)
  
  set(gca,'xtick',TickDates,'xticklabel',TickTimes-5,'xaxislocation','top'); 
  if iLevel == 3 | iLevel == 2; set(gca,'xaxislocation','top'); end
  if iLevel == 1;               set(gca,'xaxislocation','bottom'); end
  if iLevel ~=2 ;xlabel('Days since major SSW commenced'); end

  

% %   if iLevel==1;set(gca,'xaxislocation','top'); end  
% %  
% %   
% %   
% %   %second set of axes (pressure and SSW-relative days)
% %   %done last as this affects all subsequent positioning
% %   set(gca,'xtick',datenum(2021,1,5+(-100:10:100)), ...
% %           'xticklabel',-100:10:100, ...
% %           'ytick',[])  
% %   if iLevel==2;
% %     set(gca,'xaxislocation','top'); 
% %     xlabel('Days since major SSW commenced');
% %   end

     drawnow
     
  
end
