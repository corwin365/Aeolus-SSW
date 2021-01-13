clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%compute eddy:
%    - heat flux  T'v'
%    - momentum flux u'v'
%from Aeolus and MLS data, and (separately) ERA5 output
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
Settings.LatRange = [45,75];
Settings.Levels   = p2h([50,100,150]);

%time series smoothing
Settings.SmoothDays = 5;

%normalise?
Settings.Normalise = 1;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data, and subset down to region
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

k = 0; clf; set(gcf,'color','w')

for iLevel = 1:1:numel(Settings.Levels)

  %load data
  Data = load(Settings.InFile);
  
  %find region
  zidx   = closest(Data.Grid.HeightScale,Settings.Levels(iLevel));
  latidx = inrange(Data.Grid.LatScale,   Settings.LatRange);
  lonidx = inrange(Data.Grid.LonScale,   Settings.LonRange);
  
  %and subset. merge data to do in one pass
  a = cat(5,Data.HeatFlux.Obs,Data.HeatFlux.ReA,Data.MomFlux.Obs,Data.MomFlux.ReA,Data.HeatFlux.Hyb,Data.MomFlux.Hyb);
  a = a(:,  zidx,:,:,:);
  a = a(:,:,lonidx,:,:);
  a = a(:,:,:,latidx,:);
  a = squeeze(nanmean(a,[2:4]));
  HeatFlux.Obs = a(:,1); HeatFlux.ReA = a(:,2); HeatFlux.Hyb = a(:,5);
  MomFlux.Obs  = a(:,3); MomFlux.ReA  = a(:,4); MomFlux.Hyb  = a(:,6);
  clear zidx latidx lonidx a
    
  %smooth?
  HeatFlux.Obs  = smoothn(inpaint_nans(HeatFlux.Obs),[Settings.SmoothDays]);
  HeatFlux.ReA  = smoothn(inpaint_nans(HeatFlux.ReA),[Settings.SmoothDays]);
  HeatFlux.Hyb  = smoothn(inpaint_nans(HeatFlux.Hyb),[Settings.SmoothDays]);
  
  MomFlux.Obs  = smoothn(inpaint_nans(MomFlux.Obs),[Settings.SmoothDays]);
  MomFlux.ReA  = smoothn(inpaint_nans(MomFlux.ReA),[Settings.SmoothDays]);
  MomFlux.Hyb  = smoothn(inpaint_nans(MomFlux.Hyb),[Settings.SmoothDays]);
  
  
  %normalise?
  if Settings.Normalise == 1;
    
    %retain true range
    HeatFlux.Range.Obs = minmax(HeatFlux.Obs);
    HeatFlux.Range.ReA = minmax(HeatFlux.ReA);
    HeatFlux.Range.Hyb = minmax(HeatFlux.Hyb);
    MomFlux.Range.Obs  = minmax(MomFlux.Obs);
    MomFlux.Range.ReA  = minmax(MomFlux.ReA);
    MomFlux.Range.Hyb  = minmax(MomFlux.Hyb);
    
    %normalise
    HeatFlux.Obs  = (HeatFlux.Obs - nanmean(HeatFlux.Obs))./nanstd(HeatFlux.Obs);
    HeatFlux.ReA  = (HeatFlux.ReA - nanmean(HeatFlux.ReA))./nanstd(HeatFlux.ReA);
    HeatFlux.Hyb  = (HeatFlux.Hyb - nanmean(HeatFlux.Hyb))./nanstd(HeatFlux.Hyb);    
    
    MomFlux.Obs  = (MomFlux.Obs - nanmean(MomFlux.Obs))./nanstd(MomFlux.Obs);
    MomFlux.ReA  = (MomFlux.ReA - nanmean(MomFlux.ReA))./nanstd(MomFlux.ReA);
    MomFlux.Hyb  = (MomFlux.Hyb - nanmean(MomFlux.Hyb))./nanstd(MomFlux.Hyb);
    

    
  end  
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% plot
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  

  k = k+1;
  subplot(numel(Settings.Levels),5,[k,k+1])
  plot(Data.Grid.TimeScale,HeatFlux.Obs,'r-')
  hold on
  plot(Data.Grid.TimeScale,HeatFlux.ReA,'k-')
  plot(Data.Grid.TimeScale,HeatFlux.Hyb,'b-')  
  datetick
  
  r1 = corrcoef(HeatFlux.Obs,HeatFlux.ReA); r1 = r1(2);
  r2 = corrcoef(HeatFlux.Hyb,HeatFlux.ReA); r2 = r2(2);
  
  if Settings.Normalise == 1; ylabel('Z-Score'); ylim([-1,1].*3); end
  xLimits = get(gca,'XLim');yLimits = get(gca,'YLim');
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.90.*range(yLimits),['r_{obs}=',num2str(round(r1.*100)./100)],'horizontalalignment','right','fontsize',10)
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.75.*range(yLimits),['r_{hyb}=',num2str(round(r2.*100)./100)],'horizontalalignment','right','fontsize',10)
  text(min(xLimits)+0.02.*range(xLimits),min(yLimits)+0.90.*range(yLimits),[num2str(h2p(Settings.Levels(iLevel))),'hPa'],'horizontalalignment','left','fontsize',12)
  title(['Eddy Heat Flux    v''T'''])
  drawnow
  
  
  k = k+2;
  subplot(numel(Settings.Levels),5,[k,k+1])
  plot(Data.Grid.TimeScale,MomFlux.Obs,'r-')
  hold on
  plot(Data.Grid.TimeScale,MomFlux.ReA,'k-')
  plot(Data.Grid.TimeScale,MomFlux.Hyb,'b-')
  datetick
  if Settings.Normalise == 1; ylim(yLimits); set(gca,'yticklabel',{}); end
  
  r1 = corrcoef(MomFlux.Obs,MomFlux.ReA); r1 = r1(2);
  r2 = corrcoef(MomFlux.Hyb,MomFlux.ReA); r2 = r2(2);
  xLimits = get(gca,'XLim');yLimits = get(gca,'YLim');
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.90.*range(yLimits),['r_{obs}=',num2str(round(r1.*100)./100)],'horizontalalignment','right','fontsize',10)
  text(min(xLimits)+0.99.*range(xLimits),min(yLimits)+0.75.*range(yLimits),['r_{hyb}=',num2str(round(r2.*100)./100)],'horizontalalignment','right','fontsize',10)
  text(min(xLimits)+0.02.*range(xLimits),min(yLimits)+0.90.*range(yLimits),[num2str(h2p(Settings.Levels(iLevel))),'hPa'],'horizontalalignment','left','fontsize',12)
  title(['Eddy Momentum Flux    u''v'''])

  drawnow
  
  
  %plot range of unnormalised data
  k = k+2;
  if Settings.Normalise == 1;
    
    subplot(numel(Settings.Levels),5,k)
    hold on
    plot([1,1].*1,HeatFlux.Range.Obs,'ro-')
    plot([1,1].*2,HeatFlux.Range.ReA,'ko-')
    plot([1,1].*3,HeatFlux.Range.Hyb,'bo-')
    plot([1,1].*5, MomFlux.Range.Obs,'r^--')
    plot([1,1].*6, MomFlux.Range.ReA,'k^--')
    plot([1,1].*7, MomFlux.Range.Hyb,'b^--')
    set(gca,'xtick',[],'yaxislocation','right')
    
    xlim([0.5 7.5])
    yLimits = get(gca,'YLim'); plot([1,1].*4,yLimits,'k:');
    box on
    text(2,max(yLimits).*1.15,'v''T''','horizontalalignment','center')
    text(6,max(yLimits).*1.15,'u''v''','horizontalalignment','center')
    ylabel('True value')
    
  end

    

  
  
  
end
