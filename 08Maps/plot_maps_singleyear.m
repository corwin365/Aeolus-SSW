clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot time series of zonal mean Aeolus winds
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/06
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.HeightLevel   = 17; %km
Settings.DaysToPlot    = -22:3:56;%relative to 01/Jan
Settings.DaysToAverage = 5; %must be odd - days centred on date of interest
Settings.Year          = 2021;

%plotting
Settings.Rows = 3;

% % %how much should we scale up v?
% % Settings.VFactor = 10;

% % %quiver spacing
% % Settings.QuivSpace = [5,20]; %degrees lat/lon

% % %quiver scaling (how big the arrows are)
% % Settings.QuivScale = 1;%.25;

%smooth?
Settings.SmoothSize = [3,3]; %degrees lon/lat

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = load('aeolus_maps2.mat');

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

%reduce to single requested year
idx = closest(Years,Settings.Year);
Indices  = Indices( idx,:);
DoYs     = DoYs(    idx,:);
clear idx YearsAll Years



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot the winters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

set(gcf,'color','w')
clf
subplot = @(m,n,p) subtightplot (m, n, p, 0.015,  [0.02 0.01], 0.02);




k= 0;
for iDay=1:1:numel(Settings.DaysToPlot)
  
  
  %create plot
  %%%%%%%%%%%%%%%%%%%%%%%%%%
  k = k+1;
  subplot(Settings.Rows,ceil(numel(Settings.DaysToPlot)./Settings.Rows),k)
  m_proj('stereographic','lat',90,'long',90,'radius',45);
%   m_proj('satellite','lat',70,'long',70,'alt',.6);

  
  %extract data
  %%%%%%%%%%%%%%%%%%%%%%%%%%
  
    
  %get data
  idx = find(DoYs >= Settings.DaysToPlot(iDay) - floor(Settings.DaysToAverage./2) ...
           & DoYs <= Settings.DaysToPlot(iDay) + floor(Settings.DaysToAverage./2));
  idx = Indices(idx);
  
  %pull out DATA for the period and height level
  U = Data.Results.U; V = Data.Results.V;
  zidx = closest(Settings.HeightLevel,Data.Settings.HeightScale);
  U = squeeze(nanmean(U(idx,:,:,zidx),1));
  V = squeeze(nanmean(V(idx,:,:,zidx),1));  
  clear zidx idx
  
% %   %scale up V?
% %   V = V.*Settings.VFactor;
  
  
  %duplicate endpoint, for plotting round the globe
  U(end,:) = U(1,:);   V(end,:) = V(1,:);


  %overinterpolate data to one-degree grid
  xold = Data.Settings.LonScale; xnew = -200:1:180;
  yold = Data.Settings.LatScale; ynew = -82:1:82;
  [xold,yold] = meshgrid(xold,yold); [xnew,ynew] = meshgrid(xnew,ynew);
  U = interp2(xold,yold,U',xnew,ynew);   V = interp2(xold,yold,V',xnew,ynew);
  clear xold yold
  
  %smooth. This requires dealing with NaNs and the spherical Earth
  Bad = find(isnan(U));
  U = [U;U;U];
  U = smoothn(inpaint_nans(U),Settings.SmoothSize);
  U = U(size(xnew,1)+1:2.*size(xnew,1),:);
  U(Bad) = NaN;
  Bad = find(isnan(V));
  V = [V;V;V];
  V = smoothn(inpaint_nans(V),Settings.SmoothSize);
  V = V(size(xnew,1)+1:2.*size(xnew,1),:);
  V(Bad) = NaN;  

  
  %double negative values. colourbar will be modified to compensate
  %this is because the maximum +ve >> maximum -ve
  U(U <0) = U(U<0).*2;   V(V <0) = V(V<0).*2;

  %plot
  m_contourf(xnew,ynew,U,-60:2.5:60,'edgecolor','none')
  m_coast('color',[1,1,1].*0);%.7);
  hold on
  
  
  %put negative values back to normal for the quiver vectors
  U(U <0) = U(U<0)./2;   V(V <0) = V(V<0)./2;  
  
  
  
% % % % %   %add quiver of wind vectors
% % % % %   xnewQ = xnew(1:Settings.QuivSpace(1):end,1:Settings.QuivSpace(2):end);
% % % % %   ynewQ = ynew(1:Settings.QuivSpace(1):end,1:Settings.QuivSpace(2):end);
% % % % %   UQ    = U(   1:Settings.QuivSpace(1):end,1:Settings.QuivSpace(2):end);
% % % % %   VQ    = V(   1:Settings.QuivSpace(1):end,1:Settings.QuivSpace(2):end);
% % % % %   
% % % % %   %remove high latitudes (u and v get very bad)
% % % % %   ynewQ(ynewQ > 75) = NaN;
% % % % %   
% % % % %   m_quiver(xnewQ,ynewQ,UQ,VQ,'color','w','linewi',1, ...
% % % % %            'autoscale','on','autoscalefactor',Settings.QuivScale); 
  
% %   %add some line contours
% %   [c,h] = m_contour(xnew,ynew,U,[-60:10:-10,20:10:60],'edgecolor','k');
% %   clabel(c,h);

  %patch over the pole
  for iLon = -180:1:180;
    m_patch([0,1,1,0,0]+iLon,[80,80,90,90,80],[1,1,1].*0.5,'edgecolor','none')
  end; clear iLon
    
    
  %done! reproject into appropriate space.  
  m_grid('xtick',[-135,-45:45:180],'ytick',[],'fontsize',10,'BackgroundColor', [0.5 0.5 0.5]);
  
  %title
  title(datestr(datenum(Settings.Year,1,Settings.DaysToPlot(iDay))))

  
  %colours
% %   Colours = [8,48,108;9,59,124;30,108,177;97,167,210;74,151,201;223,236,247;255,255,255;255,255,210;255,232,152;254,171,73;253,105,48;223,24,29;134,0,38]./255;
% %   Colours = interp1(linspace(0,1,size(Colours,1)),Colours,linspace(0,1,32));
  Colours = flipud(cbrewer('div','RdBu',31)); Colours(14:17,:) = 1; %this is deliberately asymmetric, as the negatives are double
%   Colours = flipud(cbrewer('div','RdYlBu',31)); 
  colormap(Colours)
  caxis([-1,1].*40)

  drawnow
  
  
  drawnow
  
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% colourbar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

drawnow
cb1 = colorbar('southoutside','position',[0.06 0.05 0.15 0.02]);
cb1.Label.String = ['U [ms^{-1}]'];
ticks = [-40,-30,-20,-10,0,10,20,30,40]; labels = ticks; labels(labels < 0) = labels(labels < 0)./2;
set(cb1,'xtick',ticks,'xticklabel',labels);