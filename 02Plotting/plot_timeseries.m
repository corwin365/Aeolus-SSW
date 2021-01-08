clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot time series of zonal mean Aeolus winds
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/06
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.Var         = 'U';
Settings.HeightRange = [0,30]; %km
Settings.TimeRange   = [-60,60]; %DoY relative to 01/Jan

%smooth?
Settings.SmoothSize = [3,1]; %time units, height units - both depend on gridding choices

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = load('../01Gridding/aeolus_data.mat');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% split into winters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%start by splitting into calendar years
[y,~,~] = datevec(Data.Settings.TimeScale);
Years = unique(y);
Days = NaN(numel(Years),366); Indices = Days;
for iYear=1:1:numel(Years)
  ThisYear = find(y == Years(iYear));
  Days(   iYear,1:numel(ThisYear)) = date2doy(Data.Settings.TimeScale(ThisYear));
  Indices(iYear,1:numel(ThisYear)) = ThisYear;
end; clear iYear ThisYear y


%now, shift the DoYs so that DoYs > 180 are -ve
%we're most interested in 2021, so the leap year in 2020 matters, annoyingly
for iYear=1:1:numel(Years)
  dd = Days(iYear,:);
  DaysThisYear = datenum(Years(iYear)+1,1,1)-datenum(Years(iYear),1,1);
  dd(dd > 180) = dd(dd > 180)-DaysThisYear;
  Days(iYear,:) = dd;
end; clear dd iYear DaysThisYear

%finally, rearrange the data into winters...
Winters = NaN(numel(Years),366);
for iYear=2:1:numel(Years)
  PositiveDays = find(Days(iYear,:)   >  0);
  NegativeDays = find(Days(iYear-1,:) <= 0);
  
  %INDICES IN THE RAW DATA
  Winters(iYear,1:1:numel(NegativeDays)) = Indices(iYear-1,NegativeDays);
  Winters(iYear,numel(NegativeDays)+1:1:numel(NegativeDays)+numel(PositiveDays)) = Indices(iYear,PositiveDays);
  
end
clear iYear Indices Days PositiveDays NegativeDays

%... and drop empty years/doys
Years = Years(find(nansum(Winters,2) > 0));
Winters = Winters(find(nansum(Winters,2) > 0),:);
Winters = Winters(:,find(nansum(Winters,1) > 0));

%we now have an array Years containing the year numbers
%and an array winters with the original-data indices for all days in the
%dataset from -180 to +186 in this winter
%that was fiddlier than expected.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the winters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set(gcf,'color','w')
clf

for iYear=1:1:numel(Years)
  
  %create plot
  subplot(numel(Years),1,iYear)
  axis([Settings.TimeRange Settings.HeightRange])
  hold on; box on
  ylabel(Years(iYear),'fontsize',24)
  set(gca,'ytick',0:10:50); ylabel('Altitude [km]') %altitude  
  set(gca,'tickdir','out')
  
  %get indices for this year
  ThisYear = Winters(iYear,:); ThisYear = ThisYear(~isnan(ThisYear)); %DAY INDICES
  
  %pull out DATA for the year
  Var = Data.Results.(Settings.Var);
  Var = Var(ThisYear,:,:);
  
  %reshape to include subdaily data
  Var = reshape(permute(Var,[2,1,3]),size(Var,1)*size(Var,2),size(Var,3));

  %produce a time axis
  [dd,hh] = meshgrid(Data.Settings.TimeScale(ThisYear),Data.Settings.HourScale(1:end-1)./24);
  t = dd(:)+hh(:);
  t = t-datenum(Years(iYear),1,1);
  
  %smooth?
  if nanmean(Settings.SmoothSize) ~= 1;
    Bad = find(isnan(Var));
    Var = smoothn(inpaint_nans(Var),Settings.SmoothSize); 
    Var(Bad) = NaN; clear Bad
  end
  
  %plot coloured contours
  contourf(t,Data.Settings.HeightScale,Var',-60:2.5:60,'edgecolor','none');
  shading flat;     hold on
  
  %add line contours
  [c,h] = contour(t,Data.Settings.HeightScale,Var',[-60:10:-20,-15:5:15,20:10:60],'edgecolor',[1,1,1].*0.4);
  clabel(c,h);
  
  %tidy up
  colormap(flipud(cbrewer('div','RdBu',48)))
  caxis([-1,1].*30)
  if iYear==numel(Years); xlabel('Day of Year'); end

  
  %master plot labelling
  if iYear == 1;
    text(min(Settings.TimeRange)+0.01.*range(Settings.TimeRange), ...
         1.1.*range(Settings.HeightRange)-min(Settings.HeightRange), ...
         '\it{Data: @ESA\_Aeolus         Analysis: @CorwinWright + @TPBanyard, @UniofBath}', ...
         'fontsize',10,'color',[1,1,1].*0.3)
  end
  text(min(Settings.TimeRange)+0.01.*range(Settings.TimeRange), ...
       0.99.*range(Settings.HeightRange)-min(Settings.HeightRange), ...
       [num2str(Years(iYear)),', ',num2str(min(Data.Settings.LatRange)),'N-',num2str(max(Data.Settings.LatRange)),'N mean' ], ...
       'fontsize',18,'verticalalignment','top')
  
  %SSW peak indicators
  if Years(iYear) == 2019;
    plot(2,27,'v','color','k','markerfacecolor','k','markersize',10)
    plot([2,2],[27,32],'k-','linewi',5,'clipping','off')
    text(2.3,29,'SSW')
  end   
  if Years(iYear) == 2021
    plot(5,27,'v','color','k','markerfacecolor','k','markersize',10)
    plot([5,5],[27,32],'k-','linewi',5,'clipping','off')
    text(5.3,29,'SSW')
  end
     
     
  %second vertical axss. done last as it affects the above
  ax1 = gca;
  ax2 = axes('Position',ax1.Position,...
             'XAxisLocation','top',...
             'YAxisLocation','right',...
             'Color','none');
  set(gca,'xtick',[],'tickdir','out')
  set(gca,'ytick',0:10:50,'yticklabel',roundsd(h2p(0:10:50),2))
  ylim(Settings.HeightRange)
  ylabel('Pressure [hPa]')
  
  
  drawnow
  
  
  
end

%%
%colourbar

cb =colorbar('position',[0.05 0.33 0.02 0.33]);
caxis([-1,1].*30);
cb.Label.String = ['Projected ',Settings.Var,' / ms^{-1}'];
