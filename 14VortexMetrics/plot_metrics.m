clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%plot vortex metrics based on data supplied by Richard Hall
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/03/17
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, 0.2, 0.2,0.2);
subplot(1,1,1)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% aspect ratio
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%get data
%%%%%%%%%%%%%
Data = load('richard/NDJF_2021_aspect_10hPa.mat');
Data.t = datenum(2020,11,1):1:datenum(2021,2,28);

%plot data - aspect ratio
%%%%%%%%%%%%%%%%%%%%%%%%%%

hold on

%shade not-split region
patch([minmax(Data.t),reverse(minmax(Data.t))],[2.4,2.4,1,1],'b','edgecolor','none','facealpha',0.2)

%plot data
plot(Data.t,Data.D,'color','b','linewi',2)
hold on

%tidy up axes
ylabel('Aspect ratio')
datetick('x','dd/mmm','keeplimits')
axis([minmax(Data.t),1,5])
set(gca,'tickdir','out','xaxislocation','top')
set(gca,'xtick',datenum(2021,1,-80:20:80)+5,'xticklabel',datestr(datenum(2021,1,-80:20:80)+5),'xminortick','on' )
grid off






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% displacement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%get data
%%%%%%%%%%%%%
Data = load('richard/NDJF_2021_centlat_10hPa.mat');
Data.t = datenum(2020,11,1):1:datenum(2021,2,28);

%plot data - aspect ratio
%%%%%%%%%%%%%%%%%%%%%%%%%%

%hack to disable ticks on right
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

%shade not-displacement region
patch([minmax(Data.t),reverse(minmax(Data.t))],[66 66 90 90],'r','edgecolor','none','facealpha',0.2)         
         

%plot data
hold on
plot(Data.t,Data.D,'color','r','linewi',2)



%tidy up axes
ylabel('Centroid latitude')
datetick('x','dd/mmm','keeplimits')
grid off
axis([minmax(Data.t),35,90])
set(gca,'tickdir','out')
set(gca,'xtick',datenum(2021,1,-80:20:80)+5,'xticklabel',(-80:20:80),'xminortick','on' )



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% date indices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for Day=-80:20:80
  plot([1,1].*datenum(2021,1,Day+5),[30,90],'color',[1,1,1].*0.6)
end
xlabel('Days since SSW')
