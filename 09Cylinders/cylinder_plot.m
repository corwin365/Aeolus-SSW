clearvars -except Topo Map

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot vertical cuts through the data domain along a specific meridian
%
%This plotting routine has been crudely modified to do multiple plots instead
%of a single plot. Variable names and logic may therefore not be fully
%transparent. To understand what's happening, look at plot_vortex.m
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/08
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%data selection
Settings.InFile = 'aeolus_data_3d_2021.mat';
Settings.Day = datenum(2021,1,12); %plot data will be averaged over this range

%meridian to plot wings along
Settings.Wings = 0:120:240;

%latitude of cylinder
Settings.Cylinder = 75; %N

%colour levels  and colours
Settings.ColourLevels = -40:5:40;
Settings.Colours      = flipud(cbrewer('div','RdBu',numel(Settings.ColourLevels)));

%height range
Settings.YRange = [0,21];

%bottom altitude to show data?
Settings.MinHeight = 2; %km

%minimum latitude to plot
Settings.MinLat = 0;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% topography
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load topography, and put into 0-360 range
[Topo,~] = topo_etc([-179.9,179.9],[-89.99,89.99],0,0,1,0); 
Topo.lons(Topo.lons < 0) = Topo.lons(Topo.lons < 0)+360;
lon = Topo.lons(1,:); [~,idx] = sort(lon);
Topo.lons = Topo.lons(:,idx);
Topo.lats = Topo.lats(:,idx);
Topo.elev = Topo.elev(:,idx);




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% wings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iWing = 1:1:numel(Settings.Wings)

  cla
  set(gcf,'color','w','position',[680 558 803 420])

  %% load data, extract and overinterpolate onto a space grid
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %load data
  Data = load(Settings.InFile);
  
  %select time period 
  InTimeRange = find(Data.Settings.TimeScale >= Settings.Day-2 ...
                   & Data.Settings.TimeScale <= Settings.Day+2);

  %average over time period
  U = squeeze(nanmean(Data.Results.U(InTimeRange,:,:,:),1));
  clear InTimeRange
  
  %fill end bin
  U(end,:,:) = U(1,:,:);
    
  %overinterpolate the data in 3D
  %must be done in 3D to match the cylinder along the seams
  xi = Data.Settings.LonScale; yi = Data.Settings.LatScale; zi = Data.Settings.HeightScale;
  xo = 0:1:360; yo = -90:1:90; zo = 0:0.1:30; [xo,yo,zo] = meshgrid(xo,yo,zo);
  U = interp3(xi,yi,zi,permute(U,[2,1,3]),xo,yo,zo);
  U = smoothn([U,U,U],[9,9,1]); U = U(:,size(xo,2)+1:size(xo,2)*2,:);
  clear xi yi zi

  %find the meridian of the wing, and prepare plotting variables
  lonidx = closest(squeeze(xo(1,:,1)),Settings.Wings(iWing));
  U  = squeeze(U(:,lonidx,:))'; clear lonidx
  xo  = squeeze(yo(:,1,1)); yo = squeeze(zo(1,1,:));


  
  
  %% plot
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
   
  %fill bottom contour
  U(U < min(Settings.ColourLevels)) = min(Settings.ColourLevels);
  
  %background is going to be transparent
  U(U == 0) = NaN;
  
  
  %remove lowest altitudes
  U(find(yo < Settings.MinHeight),:) = NaN;  
  
  %plot the data 
  contourf(xo,yo,U,Settings.ColourLevels,'edgecolor','none')
  grid on; box on; hold on
  [c,h] = contour(xo,yo,U, 10:10:100,'edgecolor','k','linestyle','--'); clabel(c,h);
  [c,h] = contour(xo,yo,U,     [0,0],'edgecolor','k','linestyle','-'); clabel(c,h); 
  [c,h] = contour(xo,yo,U,-(5:5:100),'edgecolor','k','linestyle',':');  clabel(c,h);

  clear c h
  
  %colours
  caxis([min(Settings.ColourLevels),max(Settings.ColourLevels)])
  colormap(Settings.Colours)
  
  %axis limits
  xlim([Settings.MinLat,Settings.Cylinder]) 
  ylim(Settings.YRange)
  
  %ticks/ different for each wing
  xticks = -90:10:Settings.Cylinder-5;
  xlabels = cell(numel(xticks),1);
  for itick=1:1:numel(xticks); xlabels{itick} = [num2str(xticks(itick)),'N'];end
  set(gca,'xtick',xticks,'xticklabel',xlabels)
  yticks = 0:3:44;
  ylabels = cell(numel(yticks),1);
  for itick=1:1:numel(yticks); ylabels{itick} = [num2str(yticks(itick)),'km'];end
  set(gca,'ytick',yticks,'yticklabel',ylabels)  
  set(gca,'fontsize',14)
  if iWing == 2;  set(gca,'yaxislocation','right','xdir','reverse'); end
  if iWing == 3;  set(gca,'yaxislocation','left'); end
  
  clear xticks xlabels yticks ylabels itick

  %labelling
  if iWing == 1; text(Settings.MinLat,max(Settings.YRange).*1.05,[num2str(Settings.Wings(iWing)),'E'],'fontsize',18,'fontweight','bold','horizontalalignment','left'); end
  if iWing == 2; text(Settings.MinLat,max(Settings.YRange).*1.05,[num2str(Settings.Wings(iWing)),'E'],'fontsize',18,'fontweight','bold','horizontalalignment','left'); end
  if iWing == 3; text(Settings.MinLat,max(Settings.YRange).*1.05,[num2str(Settings.Wings(iWing)),'E'],'fontsize',18,'fontweight','bold','horizontalalignment','left'); end

  %plot topography
  lonidx  = closest(squeeze(Topo.lons(1,:)),Settings.Wings(iWing));
  patch([Topo.lats(:,lonidx);90;-90],[smoothn(squeeze(Topo.elev(:,lonidx)),1);0;0],'k','edgecolor','none')
  clear lonidx
  
  %plot some solid edges - easy edges
  plot([Settings.MinLat,Settings.Cylinder],[1,1].*min(Settings.YRange),'k-','linewi',2)
  plot([1,1,].*Settings.MinLat,Settings.YRange,'k-','linewi',2)
  plot([1,1,].*Settings.Cylinder,Settings.YRange,'k-','linewi',2)
  
  %plot some solid edges - data limits at top
  Top = NaN.*xo;
  for iLat=1:1:numel(xo); 
    try
    Top(iLat) = yo(max(find(isnan(squeeze(U(:,iLat))') ~= 1))); 
    catch; Top(iLat) = max(yo);
    end;
  end
  clear iLat
  Top(Top > max(Settings.YRange)) = max(Settings.YRange);
  plot((-90:0.1:90)-mean(diff(xo))./2,interp1(xo,Top,-90:0.1:90,'nearest'),'k-','linewi',2)
  clear Top xo U yo
  grid off

  %export
  export_fig(['wing',num2str(Settings.Wings(iWing))],'-png','-m2','-a4','-transparent')
  drawnow

  
  
end








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% cylinder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

figure
clf
set(gcf,'color','w')



%% load data, extract and overinterpolate onto a space grid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load data
Data = load(Settings.InFile);

%select time period
InTimeRange = find(Data.Settings.TimeScale >= Settings.Day-2 ...
                 & Data.Settings.TimeScale <= Settings.Day+2);

%average over time period
U = squeeze(nanmean(Data.Results.U(InTimeRange,:,:,:),1));
clear InTimeRange

%fill end bin
U(end,:,:) = U(1,:,:);


%overinterpolate the data in 3D
%must be done in 3D to match the cylinder along the seams
xi = Data.Settings.LonScale; yi = Data.Settings.LatScale; zi = Data.Settings.HeightScale;
xo = 0:1:360; yo = -90:1:90; zo = 0:0.1:30; [xo,yo,zo] = meshgrid(xo,yo,zo);
U = interp3(xi,yi,zi,permute(U,[2,1,3]),xo,yo,zo);
U = smoothn([U,U,U],[9,9,1]); U = U(:,size(xo,2)+1:size(xo,2)*2,:);
clear xi yi zi

%find the latitude of the cylinder meridian of the wing, and prepare plotting variables
latidx = closest(squeeze(yo(:,1,1)),Settings.Cylinder);
U  = squeeze(U(latidx,:,:))'; clear latidx
xo  = squeeze(xo(1,:,1)); yo = squeeze(zo(1,1,:));


% % %double negative u, as in other plots
% % U(U < 0) = U(U < 0).*2;

%fill bottom contour
U(U < min(Settings.ColourLevels)) = min(Settings.ColourLevels);

%we need the cylinder to go to the top
U = inpaint_nans(U);

  
%remove lowest altitudes
U(find(yo < Settings.MinHeight),:) = NaN;


%% plot 
%we need to make the figure, then write it to a file, 
%load it as an image, and warp it
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%make the figure
%%%%%%%%%%%%%%%%%%%%%%%%%%%

%plot the data
contourf(xo,yo,U,Settings.ColourLevels,'edgecolor','none')
grid off; box on; hold on
contour(xo,yo,U, 10:10:100,'edgecolor','k','linestyle','--')
contour(xo,yo,U,     [0,0],'edgecolor','k','linestyle','-')
contour(xo,yo,U,-(5:5:100),'edgecolor','k','linestyle',':')
clear xo yo U

%colour settings
caxis([min(Settings.ColourLevels),max(Settings.ColourLevels)])
colormap(Settings.Colours)


%limits and axes
xlim([0,360])
axis off
ylim(Settings.YRange)

%plot dotted lines where the wings join
for iWing=1:1:numel(Settings.Wings)
  plot([1,1].*Settings.Wings(iWing),Settings.YRange,'k:','linewi',2)
end


%plot topography
latidx  = closest(squeeze(Topo.lats(:,1)),Settings.Cylinder);
patch([Topo.lons(latidx,:),360,0],[smoothn(squeeze(Topo.elev(latidx,:)),1),0,0],'k','edgecolor','none')

%plot edges
plot([0,360],[1,1].*min(Settings.YRange),'k-','linewi',2)
plot([0,360],[1,1].*max(Settings.YRange),'k-','linewi',2)



%export file, then clear panel
export_fig('cylinder_1','-png','-m3','-a4');%,'-transparent')
clf


%load cylinder, warp it and plot it
%%%%%%%%%%%%%%%%%%%%%%%%%%%

Plane = imread('cylinder_1.png');
sz = size(Plane);
[X,Y,Z] = cylinder(sz(1),sz(2));
h = warp(X,Y,Z,fliplr(flipud(Plane)));

%point it in the right direcstions
view([125,5])


%clean up and export
axis off; box off


export_fig('cylinder_2','-png','-m2','-a4','-transparent')

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% colourbar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
axis off; grid off; set(gcf,'color','w')

colormap(Settings.Colours)
caxis([min(Settings.ColourLevels),max(Settings.ColourLevels)]);
cb1 = colorbar('southoutside','position',[0.1 0.2 0.3 0.07]);
cb1.Label.String = ['U [ms^{-1}]'];

export_fig('cb','-png','-m2','-a4','-transparent')



% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % %% map at top
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % 
% % % % % %load data
% % % % % [Topo,Map] = topo_etc([-179.9,179.9],[-89.99,89.99],0,0,1,0);
% % % % % 
% % % % % %convert coordinate frames
% % % % % [xi,yi] = meshgrid(-10000:20:10000,-10000:20:10000);
% % % % % ri = quadadd(xi,yi);
% % % % % th = atan2d(xi,yi);
% % % % % [lat,lon] = reckon(89.999,0,km2deg(ri),th); %exactly 90 causes issues
% % % % % 
% % % % % I.a = griddedInterpolant({Map.LonScale,Map.LatScale},double(Map.Map(:,:,1))');
% % % % % I.b = griddedInterpolant({Map.LonScale,Map.LatScale},double(Map.Map(:,:,2))');
% % % % % I.c = griddedInterpolant({Map.LonScale,Map.LatScale},double(Map.Map(:,:,3))');
% % % % % tp  = griddedInterpolant(Topo.lons',Topo.lats',Topo.elev');
% % % % % 
% % % % % clear Map2
% % % % % Map2(:,:,1) = uint8(I.a(lon,lat));
% % % % % Map2(:,:,2) = uint8(I.b(lon,lat));
% % % % % Map2(:,:,3) = uint8(I.c(lon,lat));
% % % % % tp = smoothn(tp(lon,lat),[7,7]);
% % % % % 
% % % % % ximap = xi;
% % % % % ximap(lat < Settings.Cylinder) = NaN;
% % % % % 
% % % % % 
% % % % % figure
% % % % % set(gcf,'color','w')
% % % % % 
% % % % % %%plot Earth surface over smoothed topography
% % % % % hMap = surface(ximap,yi,tp,Map2,...
% % % % %               'FaceColor','texturemap','EdgeColor','none','CDataMapping','direct');
% % % % % set(hMap,'clipping','on')
% % % % % %set terrain to not reflect light specularly
% % % % % set(hMap,'DiffuseStrength',0.5,'SpecularStrength',0)
% % % % % 
% % % % % axis([-4600 4600 -4600 4600 -0.1 30])
% % % % % axis off; grid off; box off
% % % % % axis square;  hold on
% % % % % view([125.814956330416 53.9732946291764])
% % % % % 
% % % % % %outer circle
% % % % % r2 = nph_haversine([90,0],[Settings.Cylinder,0]);
% % % % % th=-180:1:180; plot3(r2.*cosd(th),r2.*sind(th),ones(size(th)).*0.0,'-','color',[1,1,1].*0,'linewi',2)
% % % % % 
% % % % % export_fig('arctic','-png','-m2','-a4','-transparent')



% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % %% map at bottom
% % % % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % % % 
% % % % % 
% % % % % ximap = xi;
% % % % % ximap(lat < 5) = NaN;
% % % % % 
% % % % % 
% % % % % figure
% % % % % set(gcf,'color','w')
% % % % % 
% % % % % %%plot Earth surface over smoothed topography
% % % % % hMap = surface(ximap,yi,tp./20,Map2,...
% % % % %               'FaceColor','texturemap','EdgeColor','none','CDataMapping','direct');
% % % % % set(hMap,'clipping','on')
% % % % % %set terrain to not reflect light specularly
% % % % % set(hMap,'DiffuseStrength',0.5,'SpecularStrength',0)
% % % % % 
% % % % % axis([-10000 10000 -10000 10000 -0.1 2])
% % % % % axis off; grid off; box off
% % % % % axis square;  hold on
% % % % % view([125.814956330416 53.9732946291764])
% % % % % 
% % % % % %outer circle
% % % % % r2 = nph_haversine([90,0],[5,0]);
% % % % % th=-180:1:180; plot3(r2.*cosd(th),r2.*sind(th),ones(size(th)).*0.0,'-','color',[1,1,1].*0,'linewi',2)
