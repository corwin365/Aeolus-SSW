clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%plot surface-coupling figure based on data supplied by 
%Richard Hall
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/03/15
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.Regions  = {'GRE','NWE','TEX'};
Settings.RegNames = {'(b) Greece','(c) NW Europe','(d) Texas'};

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = struct();


%load time series data
%%%%%%%%%%%%%%%%%%%%%%%%

for iRegion=1:1:numel(Settings.Regions)
  
  Data.Snow.( Settings.Regions{iRegion}) = rCDF(['data/DJF_snow_',Settings.Regions{iRegion},'_2021.nc']);
  Data.TwomT.(Settings.Regions{iRegion}) = rCDF(['data/region_',Settings.Regions{iRegion},'_2mT.nc']);

end; clear iRegion

%load height-time data
%%%%%%%%%%%%%%%%%%%%%%%%

Data.PCA = rCDF('data/SSW_2021_PCH.nc');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot data - PCH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, 0.09, 0.05, [0.10,0.15]);

%PCA output
%%%%%%%%%%%%%%%%%%%%%

%prepare data
t = datenum(1979,1,Data.PCA.time);
p = Data.PCA.level; z = p2h(p);
v = squeeze(Data.PCA.z);


%prepare figure
subplot(5,1,[1:2])
hold on

%plot data
contourf(t,z,v,-3:0.25:3,'edgecolor','none');
[c1,h1] = contour(t,z,v,1:3,'color',[1,1,1].*0.4);
clabel(c1,h1);
[c2,h2] = contour(t,z,v,[0,0],'color','k');
clabel(c2,h2);
[c1,h1] = contour(t,z,v,-3:-1,'color',[1,1,1].*0.4,'linestyle','--');
clabel(c1,h1);
clear c1 c2 h1 h2

%overlay tropopause
TP = load('../06TropopauseFinding/tropopause_6090N.mat');
plot(TP.Time,TP.Height,'linestyle','-.','linewi',2,'color',[0,0.5,0])
clear TP

%add SSW date and downward-coupling dates
plot([1,1,].*datenum(2021,1, 5),minmax(z),'k-','linewi',2)
plot([1,1,].*datenum(2021,1,14),minmax(z),'k--','linewi',1)
plot([1,1,].*datenum(2021,1,24),minmax(z),'k--','linewi',1)
plot([1,1,].*datenum(2021,1,39),minmax(z),'k--','linewi',1)



%set colours and limits
colormap(flipud(cbrewer('div','PuOr',25)))
% cb = colorbar; cb.Label.String = 'PCH Anomaly';
caxis([-3,3])
axis([minmax(t) 0 max(z)])

%tidy up, including primary axis labelling
ylabel('Altitude [km]')
box on; grid on
set(gca,'xaxislocation','top','tickdir','out')
set(gca,'xtick',datenum(2021,1,(-20:20:40)+5),'xticklabel',datestr(datenum(2021,1,(-20:20:40)+5),'dd/mmm'))
set(gca,'fontsize',12)

%add second time axis
yyaxis right;
set( gca, 'YTick', [] );
set( gca, 'YColor', 'k' );
ax1 = gca;
ax2 = axes('Position',ax1.Position,...
           'XAxisLocation','bottom',...
           'YAxisLocation','right',...
           'Color','none', ...
           'tickdir','out');
axis([minmax(t) 0 max(z)])
set(gca,'xtick',datenum(2021,1,(-20:20:40)+5),'xticklabel',(-20:20:40));
plevs = reverse([1, 3, 10, 30, 100, 300, 1000]); 
set(gca,'ytick',p2h(plevs),'yticklabel',plevs,'tickdir','both');
ylabel('Pressure [hPa]')
set(gca,'fontsize',12)
text(datenum(2021,1,-26)-5,45,'(a)','fontsize',14,'fontweight','bold')

clear p v z plevs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot data - regional time series
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Colours = cbrewer('qual','Set1',9);

for iRegion=1:1:numel(Settings.Regions)
  
  %create axes
  subplot(5,1,2+iRegion)
  
  
  %% 2m temperature
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %set axes
  xlim(minmax(t))
  yl = [-1,1].*1.4.*max(abs(minmax(squeeze(Data.TwomT.(Settings.Regions{iRegion}).t2m))));
  ylim(yl);
  hold on; box on; grid off;
  
  %plot 2m T time series
  plot(t,squeeze(Data.TwomT.(Settings.Regions{iRegion}).t2m), ...
       'color',[255,51,51]./255,'linewi',2)

  %add SSW date and downward-coupling dates
  plot([1,1,].*datenum(2021,1, 5),yl,'k-','linewi',2)
  plot([1,1,].*datenum(2021,1,14),yl,'k--','linewi',1)
  plot([1,1,].*datenum(2021,1,24),yl,'k--','linewi',1)
  plot([1,1,].*datenum(2021,1,39),yl,'k--','linewi',1)
  
     
  %axes
  if iRegion ~=3; set(gca,'xtick',datenum(2021,1,(-20:20:40)+5),'xticklabel',(-20:20:40));
  else            set(gca,'xtick',datenum(2021,1,(-20:20:40)+5),'xticklabel',datestr(datenum(2021,1,(-20:20:40)+5),'dd/mmm'))
  end
  
  %location label
  text(datenum(2021,1,-25)-5,min(yl)+0.84.*range(yl),Settings.RegNames{iRegion},'fontsize',11)
  
  %tidy up
  set(gca,'tickdir','out')
  ylabel('\Delta T [K]')
  set(gca,'fontsize',12)
  
  
  %% snow fractional coverage
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
  
  
  %hack to disable old ticks on right
  yyaxis right;
  set( gca, 'YTick', [] );
  set( gca, 'YColor', 'k' );

  
  %second set of axes (pressure and SSW-relative days)
  %done last as this affects all subsequent positioning
  ax1 = gca;
  ax2 = axes('Position',ax1.Position,...
             'XAxisLocation','bottom',...
             'YAxisLocation','right',...
             'Color','none', ...
             'tickdir','out');

  %set axes
  hold on
  xlim(minmax(t))
  yl = [0,1.05];
  ylim(yl);
  hold on; box on; grid off;   set(gca,'tickdir','in')     
  ylabel('Snow Cover')  
           
           
  %plot snow time series
  plot(t,squeeze(Data.Snow.(Settings.Regions{iRegion}).snow_cover_extent), ...
       'color',[51,153,255]./255,'linewi',2)  
  
     
  %axes
  set(gca,'xtick',datenum(2021,1,(-20:20:40)+5),'xticklabel',(-20:20:40),'xaxislocation','top')
  xlabel('Days since SSW')
  set(gca,'fontsize',12)
  
  
     
end
  