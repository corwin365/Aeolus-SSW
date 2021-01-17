clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot time series of MLS T and ERA5 U, for context
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/06
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.TimeRange   = [-62,62]; %DoY relative to 01/Jan


%files
Settings.MlsData  = 'mls_data_b.mat';
Settings.Era5Data = 'era5_data.mat';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Mls  = load(Settings.MlsData);
Era5 = load(Settings.Era5Data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% split into winters
%this logic relies on the files having EXACTLY THE SAME LAYOUT
%same time axes, same height axis.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = Mls; %arbitrary, could be either as they're the same

%start by splitting into calendar years
[y,~,~] = datevec(Data.Settings.TimeScale);
Years = unique(y);
Days = NaN(numel(Years),366); Indices = Days;
for iPerc=1:1:numel(Years)
  ThisYear = find(y == Years(iPerc));
  Days(   iPerc,1:numel(ThisYear)) = date2doy(Data.Settings.TimeScale(ThisYear));
  Indices(iPerc,1:numel(ThisYear)) = ThisYear;
end; clear iYear ThisYear y


%now, shift the DoYs so that DoYs > 180 are -ve
%we're most interested in 2021, so the leap year in 2020 matters, annoyingly
for iPerc=1:1:numel(Years)
  dd = Days(iPerc,:);
  DaysThisYear = datenum(Years(iPerc)+1,1,1)-datenum(Years(iPerc),1,1);
  dd(dd > 180) = dd(dd > 180)-DaysThisYear;
  Days(iPerc,:) = dd;
end; clear dd iYear DaysThisYear

%finally, rearrange the data into winters...
Winters = NaN(2,numel(Years),366);
for iPerc=2:1:numel(Years)
  PositiveDays = find(Days(iPerc,:)   >  0);
  NegativeDays = find(Days(iPerc-1,:) <= 0);
  
  %INDICES IN THE RAW DATA
  Winters(1,iPerc,1:1:numel(NegativeDays)) = Indices(iPerc-1,NegativeDays);
  Winters(1,iPerc,numel(NegativeDays)+1:1:numel(NegativeDays)+numel(PositiveDays)) = Indices(iPerc,PositiveDays);
  
  %DAY NUMBERS
  Winters(2,iPerc,1:1:numel(NegativeDays)) = Days(iPerc-1,NegativeDays);
  Winters(2,iPerc,numel(NegativeDays)+1:1:numel(NegativeDays)+numel(PositiveDays)) = Days(iPerc,PositiveDays);

  
end
clear iYear Indices Days PositiveDays NegativeDays

%... and split out the indices and day-numbers
Indices  = permute(Winters(1,:,:,:),[2,3,4,1]);
DoYs     = permute(Winters(2,:,:,:),[2,3,4,1]);
YearsAll = ones(size(DoYs)).*Years';
clear Winters

clear Data 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now, line up the DoYs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DaysScale = nanmin(DoYs(:)):1:nanmax(DoYs(:));
Data = NaN(2,numel(Years),numel(DaysScale),numel(Mls.Settings.HeightScale));

for iYear=1:1:numel(Years)
  for iDay=1:1:numel(DaysScale);
  
    ThisDay = find(DoYs == DaysScale(iDay) & YearsAll == Years(iYear));
    if numel(ThisDay) == 0; continue; end
    idx = Indices(ThisDay);
    
    
    Data(1,iYear,iDay,:) = squeeze(nanmean( Mls.Results.T(idx,:,:),2));
    Data(2,iYear,iDay,:) = squeeze(nanmean(Era5.Results.U(idx,:,:),2));
    
  end
end
clear iYear iDay ThisDay idx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot line plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, [0.03,0.1], 0.1, 0.1);

k = 0;
l = 0;

for Level=[20,15,10,5]
  for iSource=1:1:2;

    k=k+1;
    if iSource == 1 && Level == 5; continue; end %no data for MLS in troposphere
    
    subplot(4,2,k)
    
    %what level?
    zidx = closest(Mls.Settings.HeightScale,Level);
    
    %what percentiles?
    Percentiles = 0:2:100;
    NPerc = numel(Percentiles);
    
    %create a colour ramp
    Colours = colorGradient([1,1,1],[1,1,1].*0.5,ceil(NPerc./2)+3);
    Colours = Colours(3:end,:);
    
    %x-scale (overinterpolated)
    xa = min(DaysScale):0.1:max(DaysScale);
    x = [xa,xa(end:-1:1)];
    
    %produce samples
    ThisData = squeeze(Data(iSource,2:end-1,:,zidx));
    ToPlot = NaN(NPerc,size(ThisData,2));
    
    
    
    for iDay=1:1:size(ToPlot,2);
      ToPlot(:,iDay) = prctile(ThisData(1:end-1,iDay),Percentiles);
    end
    
    
    for iPerc=1:1:floor(NPerc./2)
      
      %pull out the two years
      y1 = ToPlot(      iPerc,:);
      y2 = ToPlot(NPerc-iPerc,:);
      
      %overinterpolate  and smooth (but only at the same scale as the 
      %interpolation - i.e. it just makes the line smoother at the subdaily 
      %level, below the level we claim to represent)
      y1 = smoothn(interp1(DaysScale,y1,xa),[11]);
      y2 = smoothn(interp1(DaysScale,y2,xa),[11]);
      
      %create a patch
      patch(x,[y1,y2(end:-1:1)],Colours(iPerc,:),'edgecolor','none');%[1,1,1].*0.7)
      hold on
      
    end
    
    %plot some interesting percentiles5
    for PC=[0,18,50,82,100];
      idx = closest(Percentiles,PC);
      plot(xa,smoothn(interp1(DaysScale,ToPlot(idx,:),xa),[5]),'-','color',[1,1,1].*0.3,'linewi',0.5)
    end
    
    %finally, plot the specific years of interest
    plot(xa,smoothn(interp1(DaysScale,squeeze(Data(iSource,end-1,:,zidx)),xa),[11]),'-','color','r','linewi',2)
%     plot(xa,smoothn(interp1(DaysScale,squeeze(Data(iSource,end-0,:,zidx)),xa),[11]),'-','color','b','linewi',2)

    
    %y-labelling
    if iSource == 2; ylabel('ERA5 U [ms^{-1}]'); set(gca,'yaxislocation','right'); 
    else             ylabel('MLS T [K]')
    end
    
    %ticks and boxes
    box on
    set(gca,'tickdir','out')
    xlim(Settings.TimeRange)
    
    %a-axes
    
    if Level == 20;
      set(gca,'xaxislocation','top'); xlabel('Days since 1st January');
    elseif iSource ==2 && Level > 5
      set(gca,'xticklabel',{})
    elseif iSource ==1 && Level > 10
      set(gca,'xticklabel',{})      
    else
      xlabel('Days since 1st January');
    end
    
    %height level
    if iSource == 2;
      yLimits = get(gca,'YLim');
      text(min(Settings.TimeRange)-0.14.*range(Settings.TimeRange), ...
           min(           yLimits)+0.50.*range(           yLimits), ...
           [num2str(Level),'km'],'fontsize',30, ...
           'horizontalalignment','center')
    end
    
    %label
    Letters = 'abcdefghijklmnopq'; l =l+1;
    yLimits = get(gca,'YLim')+[-1,1];
    text(min(Settings.TimeRange)+0.01.*range(Settings.TimeRange), ...
         min(           yLimits)+0.90.*range(           yLimits), ...
         ['(',Letters(l),')'],'fontsize',18)
       
       
    %month labelling
    if iSource == 2 & Level > 5 | iSource ==1 & Level > 10
      MonthPoints = [-61,-31,0,31,59];
      Names = {'Nov','Dec','Jan','Feb'};
      for iMonth=2:1:numel(MonthPoints)
        plot(MonthPoints([iMonth-1,iMonth])+[1,-1], ...
             min(yLimits)-0.08.*range(yLimits).*[1,1], ...
            'k-','clipping','off')
        plot(MonthPoints([iMonth-1,iMonth])+[1,-1].*5, ...
             min(yLimits)-0.08.*range(yLimits).*[1,1], ...
            'w-','clipping','off')
        plot(MonthPoints(iMonth-1),min(yLimits)-0.08.*range(yLimits),'ks','markerfacecolor','k','clipping','off','markersize',10)
        plot(MonthPoints(iMonth  ),min(yLimits)-0.08.*range(yLimits),'ks','markerfacecolor','k','clipping','off','markersize',10)
        text(mean(MonthPoints([iMonth-1,iMonth])), ...
             min(yLimits)-0.08.*range(yLimits),Names{iMonth-1}, ...
             'horizontalalignment','center')
      end
    end
    ylim(yLimits)


    
    drawnow
    
    
    
  end
end
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% key
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

colormap([Colours;Colours(end:-1:1,:)])

cb = colorbar('southoutside','position',[0.17 0.10 0.2 0.05]);
caxis([0,100]);
cb.Label.String = ['Percentile in 2004/05 -- 2018/19 climatology'];


h_axes = axes('position', cb.Position, 'ylim', cb.Limits, 'color', 'none', 'visible','off');
for PC=[0,18,50,82,100];
  line(PC*[1 1],h_axes.YLim, 'color', [1,1,1].*0.3, 'parent', h_axes);
end
hold on

plot([40,60],max(h_axes.YLim).*1.35.*[1,1],'r-','linewi',2,'clipping','off')
text(6,max(h_axes.YLim).*1.35,'2020/21','color','r')

% % plot([60,75],max(h_axes.YLim).*1.35.*[1,1],'b-','linewi',2,'clipping','off')
% % text(77,max(h_axes.YLim).*1.35,'2020/21','color','b')
