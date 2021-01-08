clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot time series of MLS T and ERA5 U, for context
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/06
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.HeightRange = [0,30]; %km - for the time-height plots
Settings.HeightLevel = 16; %km - for the line plots
Settings.TimeRange   = [-60,60]; %DoY relative to 01/Jan


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

%MLS temperature
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(2,3,1)
cla
zidx = closest(Mls.Settings.HeightScale,Settings.HeightLevel);

%produce a climatology
Clima = prctile(squeeze(Data(1,1:end-2,:,zidx)),[0,2.5,18,50,82,97.5,100],1);
 
%plot climatology and year of interest
x = [DaysScale,DaysScale(end:-1:1)];
y = [Clima(1,:),Clima(7,end:-1:1)];
patch(x,y,[1,1,1].*0.8,'edgecolor','none')
hold on
y = [Clima(3,:),Clima(5,end:-1:1)];
patch(x,y,[1,1,1].*0.5,'edgecolor','none')
plot(DaysScale,Clima(4,:),'k-')
plot(DaysScale,squeeze(Data(1,end,:,zidx)),'r-','linewi',2)
xlim(Settings.TimeRange)
ylabel('MLS T')
box on; set(gca,'tickdir','out','xaxislocation','top'); xlabel('Days since January 1st','fontsize',14)
text(-59,223,[num2str(Settings.HeightLevel),'km'])

%individual years
for iYear=1:1:numel(Years)-2
  plot(DaysScale,squeeze(Data(1,iYear,:,zidx)),'k-','linewi',0.5)
end
  
  


%ERA5 wind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subplot(2,3,4)
cla
zidx = closest(Era5.Settings.HeightScale,Settings.HeightLevel);

%produce a climatology
Clima = prctile(squeeze(Data(2,1:end-2,:,zidx)),[0,2.5,18,50,82,97.5,100],1);
 
%plot climatology and year of interest
x = [DaysScale,DaysScale(end:-1:1)];
y = [Clima(1,:),Clima(7,end:-1:1)];
patch(x,y,[1,1,1].*0.8,'edgecolor','none')
hold on
y = [Clima(3,:),Clima(5,end:-1:1)];
patch(x,y,[1,1,1].*0.5,'edgecolor','none')
plot(DaysScale,Clima(4,:),'k-')
plot(DaysScale,squeeze(Data(2,end,:,zidx)),'r-','linewi',2)

xlim(Settings.TimeRange)
ylabel('ERA5 U')
box on; set(gca,'tickdir','out')
text(-59,27,[num2str(Settings.HeightLevel),'km']); xlabel('Days since January 1st','fontsize',14)

clear Clima x y zidx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot contour plots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%produce a (different) climatology
Clima = nanmean(Data(:,1:end-2,:,:),2);

%plot differences from this climatology
dT = squeeze(Data(1,end,:,:)-Clima(1,:,:,:));
dU = squeeze(Data(2,end,:,:)-Clima(2,:,:,:));

dT(:,Mls.Settings.HeightScale < p2h(261)) = NaN;

%smooth MLS a bit, for visual clarity
Bad = find(isnan(dT));
dT = smoothn(inpaint_nans(dT),[3,3]);
dT(Bad) = NaN;


subplot(2,3,2)
contourf(DaysScale,Mls.Settings.HeightScale,dT',-10:1:10,'edgecolor','none');
shading flat; hold on; grid on
[c,h] = contour(DaysScale,Mls.Settings.HeightScale,dT',[-4,-2,2,4],'edgecolor',[1,1,1].*0.6);
clabel(c,h)
redyellowblue32
caxis([-1,1].*8)
cb = colorbar; cb.Label.String = '\Delta T [K]';
xlim(Settings.TimeRange); ylim([min(Settings.HeightRange),max(Settings.HeightRange)]);
plot([0,0],[min(Settings.HeightRange),max(Settings.HeightRange)],'k--')
box on; set(gca,'tickdir','out','xaxislocation','top'); ylabel('Altitude [km]','fontsize',14); xlabel('Days since January 1st 2019','fontsize',14)


subplot(2,3,5)
contourf(DaysScale,Mls.Settings.HeightScale,dU',-30:2.5:30,'edgecolor','none');
shading flat; hold on;grid on
[c,h] = contour(DaysScale,Mls.Settings.HeightScale,dU',[-10,-5,5,10],'edgecolor',[1,1,1].*0.6);
clabel(c,h)
redyellowblue32
caxis([-1,1].*30)
cb = colorbar; cb.Label.String = '\DeltaU [ms^{-1}]';
xlim(Settings.TimeRange); ylim([min(Settings.HeightRange),max(Settings.HeightRange)]);
plot([0,0],[min(Settings.HeightRange),max(Settings.HeightRange)],'k--')
box on; set(gca,'tickdir','out'); ylabel('Altitude [km]','fontsize',14);; xlabel('Days since January 1st 2019','fontsize',14)

