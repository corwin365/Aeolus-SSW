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
Settings.HeightLevel = 21; %km
Settings.TimeRange   = -3:1:6;% -15:1:20; %one plot for the range between each pair of numbers
% Settings.MaxLat = 70; %remove areas near pole - projections are wonky


%smooth?
Settings.SmoothSize = [5,3]; %lon/lat units - both depend on gridding choices

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = load('../01Gridding/aeolus_maps.mat');

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
Winters = NaN(2,numel(Years),366);
for iYear=2:1:numel(Years)
  PositiveDays = find(Days(iYear,:)   >  0);
  NegativeDays = find(Days(iYear-1,:) <= 0);
  
  %INDICES IN THE RAW DATA
  Winters(1,iYear,1:1:numel(NegativeDays)) = Indices(iYear-1,NegativeDays);
  Winters(1,iYear,numel(NegativeDays)+1:1:numel(NegativeDays)+numel(PositiveDays)) = Indices(iYear,PositiveDays);
  
  %DAY NUMBERS
  Winters(2,iYear,1:1:numel(NegativeDays)) = Days(iYear-1,NegativeDays);
  Winters(2,iYear,numel(NegativeDays)+1:1:numel(NegativeDays)+numel(PositiveDays)) = Days(iYear,PositiveDays);

  
end
clear iYear Indices Days PositiveDays NegativeDays

%... and split out the indices and day-numbers
Indices  = permute(Winters(1,:,:,:),[2,3,4,1]);
DoYs     = permute(Winters(2,:,:,:),[2,3,4,1]);
YearsAll = ones(size(DoYs)).*Years';
clear Winters




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the winters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set(gcf,'color','w')
clf

k= 0;
for iYear=4%2:1:numel(Years)
  for iPeriod=1:1:numel(Settings.TimeRange)-1
    
    
    %create plot
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    k = k+1;
    subplot(2,(numel(Settings.TimeRange))./2,k)
    
    m_proj('stereographic','lat',90,'long',0,'radius',30);
    
    %extract data
    %%%%%%%%%%%%%%%%%%%%%%%%%%
    
    
    
    %get indices and DOYs for this period
    idx = find(YearsAll == Years(iYear) ...
             & DoYs >= Settings.TimeRange(iPeriod) ...
             & DoYs <  Settings.TimeRange(iPeriod+1));
    idx = Indices(idx);
           
    %pull out DATA for the period and height level
    Var = Data.Results.(Settings.Var);
    zidx = closest(Settings.HeightLevel,Data.Settings.HeightScale);
    Var = squeeze(nanmean(Var(idx,:,:,zidx),1));

    
    %produce grids. remember duplicated endpoint, because maps.
    x = [Data.Settings.LonScale];
    y = Data.Settings.LatScale;
    Var(end,:) = Var(1,:);
    
    %overinteprolate to make it prettier
    [xi,yi] = meshgrid(-0:1:360,min(y):1:max(y));
    zz = interp2(x,y,Var',xi,yi);
    zz = smoothn(zz,[5,5]);
    
    %bottomed-out value fill
    zz(zz < -60) = -60;
    
    %plot it
    m_contourf(xi,yi,zz,-60:5:60,'edgecolor','none')
    hold on
    [c,h] = m_contour(xi,yi,zz,-60:10:60,'edgecolor',[1,1,1,].*0) ;   
    clabel(c,h)
    
    m_coast('color',[1,1,1].*0.5);
    m_grid('xtick',-135:45:135,'ytick',[],'fontsize',8);
    
    %generate title
    First = datenum(Years(iYear),1, Settings.TimeRange(iPeriod));
    Last  = datenum(Years(iYear),1, Settings.TimeRange(iPeriod+1)-1);
    
    title([datestr(First,'dd/mmm/yy')],'fontsize',16)
    
    %colours
    colormap(flipud(cbrewer('div','RdYlBu',48)))
    caxis([-1,1].*30)

    drawnow
    
  
    drawnow
  end
end

%%
%colourbar

cb =colorbar('position',[0.05 0.33 0.02 0.33]);
caxis([-1,1].*30);
cb.Label.String = ['Projected ',Settings.Var,' / ms^{-1}'];


%% master title
sgtitle(['Aeolus projected ',Settings.Var,', ',num2str(Settings.HeightLevel), 'km altitude'],'fontsize',24)