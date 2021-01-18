clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compute eddy:
%    - heat flux  T'v'
%    - momentum flux u'v'
%from Aeolus and MLS data, and (separately) ERA5 output
%
%
%the plotting code here has been through many cycles of modification and is
%hard to read - sorry about this, it works but it's just a bit messy
%
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/13
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%data
Settings.InFile  = 'fluxes.mat';

%region to average over
Settings.LonRange = [-180,180];
Settings.LatRange = [55,75];
Settings.Levels   = p2h([50,100,150]);

%time series smoothing
Settings.SmoothDays = 5;

%normalise?
Settings.Normalise = 1;

%colours
cbrew = cbrewer('qual','Set1',9);

Colours.ReA = [0,0,0];
Colours.Obs = cbrew(2,:);
Colours.NoV = cbrew(5,:);
Colours.Hyb = cbrew(1,:);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data, and subset down to region
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

k = 0; l= 0 ;clf; set(gcf,'color','w'); Letters = 'abgcdhefi';
subplot = @(m,n,p) subtightplot (m, n, p, [0.05,0.02], 0.05, 0.05);

for iLevel = 1:1:numel(Settings.Levels)

  %load data
  Data = load(Settings.InFile);
  
  %find region
  zidx   = closest(Data.Grid.HeightScale,Settings.Levels(iLevel));
  latidx = inrange(Data.Grid.LatScale,   Settings.LatRange);
  lonidx = inrange(Data.Grid.LonScale,   Settings.LonRange);
  
  %and subset. merge data to do in one pass
  a = cat(5,Data.HeatFlux.Obs,Data.HeatFlux.ReA,Data.MomFlux.Obs,Data.MomFlux.ReA,Data.HeatFlux.Hyb,Data.MomFlux.Hyb,Data.HeatFlux.NoV,Data.MomFlux.NoV);
  a = a(:,  zidx,:,:,:);
  a = a(:,:,lonidx,:,:);
  a = a(:,:,:,latidx,:);
  a = squeeze(nanmean(a,[2:4]));
  HeatFlux.Obs = a(:,1); HeatFlux.ReA = a(:,2); HeatFlux.Hyb = a(:,5); HeatFlux.NoV = a(:,7);
  MomFlux.Obs  = a(:,3); MomFlux.ReA  = a(:,4); MomFlux.Hyb  = a(:,6); MomFlux.NoV  = a(:,8);
  clear zidx latidx lonidx a
  
  
  %remove outliers
  Vars = {'Obs','ReA','Hyb','NoV'};
  for iVar=1:1:numel(Vars)
    
    %remove outliers (routine uses a 3stdev cutoff)
    [~,rm] = rmoutliers(HeatFlux.(Vars{iVar})); 
    a = HeatFlux.(Vars{iVar}); a(rm) = NaN; HeatFlux.(Vars{iVar}) = a;

    [~,rm] = rmoutliers(MomFlux.(Vars{iVar})); 
    a = MomFlux.(Vars{iVar}); a(rm) = NaN; MomFlux.(Vars{iVar}) = a;    
    
    %smooth?
    HeatFlux.(Vars{iVar}) = smoothn(inpaint_nans(HeatFlux.(Vars{iVar})),[Settings.SmoothDays]);
    MomFlux.( Vars{iVar}) = smoothn(inpaint_nans( MomFlux.(Vars{iVar})),[Settings.SmoothDays]);

    %normalise?
    if Settings.Normalise == 1;
      
      %retain original range
      HeatFlux.Range.(Vars{iVar}) = minmax(HeatFlux.(Vars{iVar}));
      MomFlux.Range.( Vars{iVar}) = minmax(MomFlux.( Vars{iVar}));
      
      %normalise
      HeatFlux.(Vars{iVar}) = (HeatFlux.(Vars{iVar}) - nanmean(HeatFlux.(Vars{iVar})))./nanstd(HeatFlux.(Vars{iVar}));
      MomFlux.( Vars{iVar}) = (MomFlux.( Vars{iVar}) - nanmean(MomFlux.( Vars{iVar})))./nanstd(MomFlux.( Vars{iVar}));
      
    end
  end; clear iVar

  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% plot
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  

  k = k+1;l = l+1;
  subplot(numel(Settings.Levels),5,[k,k+1])
  
  %produce a grid: shade alternate months
  hold on
  for iMonth=10:2:14
    patch(datenum(2020,[0,1,1,0,0]+iMonth,1),[-1,-1,1,1,-1].*3.95,[1,1,1].*0.9,'edgecolor',[1,1,1].*0.8)
  end
  for iY=-4:1:4; plot(datenum(2020,[10,15],1),[1,1].*iY,'-','linewi',0.25,'color',[1,1,1].*0.8); end
  box on; grid off

    

  
  plot(Data.Grid.TimeScale,HeatFlux.ReA,'-','linewi',2,'color',Colours.ReA)
  plot(Data.Grid.TimeScale,HeatFlux.NoV,'-','linewi',2,'color',Colours.NoV)
  plot(Data.Grid.TimeScale,HeatFlux.Obs,'-','linewi',2,'color',Colours.Obs)
  plot(Data.Grid.TimeScale,HeatFlux.Hyb,'-','linewi',2,'color',Colours.Hyb)
 
  datetick
  set(gca,'xtick',datenum(2020,1:1:20,15),'xticklabel',datestr(datenum(2020,1:1:19,15),'mmm'))
  xlim([datenum(2020,[10,15],1)])    
  
  r1 = corrcoef(HeatFlux.Obs,HeatFlux.ReA); r1 = r1(2);
  r2 = corrcoef(HeatFlux.Hyb,HeatFlux.ReA); r2 = r2(2);
  r3 = corrcoef(HeatFlux.NoV,HeatFlux.ReA); r3 = r3(2);
  
  if Settings.Normalise == 1; ylabel('Z-Score'); ylim([-1,1].*4); end
  xLimits = get(gca,'XLim');yLimits = get(gca,'YLim');
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.75.*range(yLimits),['r_{obs}=',sprintf('%1.2f',r1)],'horizontalalignment','right','fontsize',10)
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.90.*range(yLimits),['r_{hyb}=',sprintf('%1.2f',r2)],'horizontalalignment','right','fontsize',10)
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.60.*range(yLimits),['r_{NoV}=',sprintf('%1.2f',r3)],'horizontalalignment','right','fontsize',10)
  text(min(xLimits)+0.02.*range(xLimits),min(yLimits)+0.92.*range(yLimits),['(',Letters(l),') ',num2str(h2p(Settings.Levels(iLevel))),'hPa'],'horizontalalignment','left','fontsize',15)
  text(min(xLimits)+0.02.*range(xLimits),min(yLimits)+0.05.*range(yLimits),['45N - ',num2str(Settings.LatRange(2)),'N'],'horizontalalignment','left','fontsize',12)
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.05.*range(yLimits),['Smoothed ',num2str(Settings.SmoothDays),' days'],'horizontalalignment','right','fontsize',12)
  if iLevel == 1; title(['Eddy Heat Flux    v''T''']); end
  drawnow
  
  
  k = k+2;l = l+1;
  subplot(numel(Settings.Levels),5,[k,k+1])
  
  %produce a grid: shade alternate months
  hold on
  for iMonth=10:2:14
    patch(datenum(2020,[0,1,1,0,0]+iMonth,1),[-1,-1,1,1,-1].*3.95,[1,1,1].*0.9,'edgecolor',[1,1,1].*0.8)
  end
  for iY=-4:1:4; plot(datenum(2020,[10,15],1),[1,1].*iY,'-','linewi',0.25,'color',[1,1,1].*0.8); end
  box on; grid off  
  
  plot(Data.Grid.TimeScale,MomFlux.ReA,'-','linewi',2,'color',Colours.ReA)
  plot(Data.Grid.TimeScale,MomFlux.NoV,'-','linewi',2,'color',Colours.NoV)
  plot(Data.Grid.TimeScale,MomFlux.Obs,'-','linewi',2,'color',Colours.Obs)
  plot(Data.Grid.TimeScale,MomFlux.Hyb,'-','linewi',2,'color',Colours.Hyb)
  datetick
  if Settings.Normalise == 1; ylim(yLimits); set(gca,'yticklabel',{}); end
  set(gca,'xtick',datenum(2020,1:1:20,15),'xticklabel',datestr(datenum(2020,1:1:19,15),'mmm'))
  xlim([datenum(2020,[10,15],1)])  
  
  r1 = corrcoef(MomFlux.Obs,MomFlux.ReA); r1 = r1(2);
  r2 = corrcoef(MomFlux.Hyb,MomFlux.ReA); r2 = r2(2);
  r3 = corrcoef(MomFlux.NoV,MomFlux.ReA); r3 = r3(2);
  
  xLimits = get(gca,'XLim');yLimits = get(gca,'YLim');
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.75.*range(yLimits),['r_{obs}=',sprintf('%1.2f',r1)],'horizontalalignment','right','fontsize',10)
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.90.*range(yLimits),['r_{hyb}=',sprintf('%1.2f',r2)],'horizontalalignment','right','fontsize',10)
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.60.*range(yLimits),['r_{NoV}=',sprintf('%1.2f',r3)],'horizontalalignment','right','fontsize',10)
  text(min(xLimits)+0.02.*range(xLimits),min(yLimits)+0.92.*range(yLimits),['(',Letters(l),') ',num2str(h2p(Settings.Levels(iLevel))),'hPa'],'horizontalalignment','left','fontsize',15)
  text(min(xLimits)+0.02.*range(xLimits),min(yLimits)+0.05.*range(yLimits),['45N - ',num2str(Settings.LatRange(2)),'N'],'horizontalalignment','left','fontsize',12)
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.05.*range(yLimits),['Smoothed ',num2str(Settings.SmoothDays),' days'],'horizontalalignment','right','fontsize',12)
  
  if iLevel == 1; title(['Eddy Momentum Flux    u''v''']); end

  

  drawnow
  
  
  %plot range of unnormalised data
  k = k+2;
  if Settings.Normalise == 1;
    
    subplot(numel(Settings.Levels),5,k)
    hold on
    plot([1,1].*1,HeatFlux.Range.ReA,'o-','linewi',2,'color',Colours.ReA)
    plot([1,1].*2,HeatFlux.Range.Hyb,'o-','linewi',2,'color',Colours.Hyb)
    plot([1,1].*3,HeatFlux.Range.Obs,'o-','linewi',2,'color',Colours.Obs)
    plot([1,1].*4,HeatFlux.Range.NoV,'o-','linewi',2,'color',Colours.NoV)
    plot([1,1].*6, MomFlux.Range.ReA,'^-','linewi',2,'color',Colours.ReA)
    plot([1,1].*7, MomFlux.Range.Hyb,'^-','linewi',2,'color',Colours.Hyb)
    plot([1,1].*8, MomFlux.Range.Obs,'^-','linewi',2,'color',Colours.Obs)
    plot([1,1].*9, MomFlux.Range.NoV,'^-','linewi',2,'color',Colours.NoV)
    set(gca,'xtick',1:1:9,'xticklabel',{'ReA','Hyb','Obs','NoV',' ','ReA','Hyb','Obs','NoV'}, ...
            'yaxislocation','right')
    xtickangle(90)
    
    xlim([0.5 9.5])
    yLimits = get(gca,'YLim'); ylim([-1,1].*max(abs(yLimits)));yLimits = get(gca,'YLim');  plot([1,1].*5,yLimits,'k:','linewi',3);
    box on
    if iLevel == 1; 
      text(2.5,max(yLimits).*1.15,'v''T''','horizontalalignment','center')
      text(7.5,max(yLimits).*1.15,'u''v''','horizontalalignment','center')
    end
    ylabel('Raw Value')
    l = l+1;text(0.55,-max(yLimits).*0.9,['(',Letters(l),') '])
    
  end

    

  
  
  
end
