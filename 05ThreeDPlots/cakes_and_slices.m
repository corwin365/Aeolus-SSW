clearvars -except Topo Map

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot 3D plots of the stratospheric polar vortex as observed by Aeolus
% plots alternating rows of 3d data (cakes) and arrow plots at each height (slices)
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/18
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%data selection
Settings.InFile = 'aeolus_data_3d_2021.mat';
Settings.TimeRange = datenum(2021,1,-6:2:9); %must be an even number of points


%data regridding - km from pole
%this is  presentational - actual gridding handled by the feeder routine
%smaller spacing -> higher-res graphs
Settings.XGrid = -6000:50:6000;
Settings.YGrid = -6000:50:6000;
Settings.ZGrid = 5:0.75:22;

%colour limit
Settings.ColourLimit = 10;

%height level of slice
Settings.SliceHeight = 20; %km

%data smoothing
%this is at the overinterpolated level from the regridding
Settings.SmoothSize = [15,15,1];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% make plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, [0.04,0.01],  [0.10,0.03], 0.03);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% map prep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load data
[Topo,Map] = topo_etc([-179.9,179.9],[-89.9,89.9],0,0,1,0);
% Topo.elev = smoothn(Topo.elev,[5,5]);



%convert coordinate frames
[xi,yi] = meshgrid(-6000:200:6000,-60002:200:6000);
ri = quadadd(xi,yi);
th = atan2d(xi,yi);
[lat,lon] = reckon(89.999,0,km2deg(ri),th); %exactly 90 causes issues

I.a = griddedInterpolant({Map.LonScale,Map.LatScale},double(Map.Map(:,:,1))');
I.b = griddedInterpolant({Map.LonScale,Map.LatScale},double(Map.Map(:,:,2))');
I.c = griddedInterpolant({Map.LonScale,Map.LatScale},double(Map.Map(:,:,3))');
tp  = griddedInterpolant(Topo.lons',Topo.lats',Topo.elev');

clear Map2
Map2(:,:,1) = uint8(I.a(lon,lat));
Map2(:,:,2) = uint8(I.b(lon,lat));
Map2(:,:,3) = uint8(I.c(lon,lat));
tp = tp(lon,lat);


xi(lat < 49) = NaN;
mapxi = xi; mapyi = yi; clear xi yi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% main plotting loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iDay=1:1:numel(Settings.TimeRange)
  

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% load data, extract and overinterpolate onto a space grid
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %load data
  Data = load(Settings.InFile);
  
  %select time period 
  InTimeRange = find(Data.Settings.TimeScale >= Settings.TimeRange(iDay)-1 ...
                   & Data.Settings.TimeScale <= Settings.TimeRange(iDay)+1);
                 
  %special case - one day where coverage leaves large gaps in plot - add a single day to provide sufficient coverage
  if Settings.TimeRange(iDay) == datenum(2020,1,12); InTimeRange = [InTimeRange,max(InTimeRange)+1]; end
           
  %average over time period
  U = squeeze(nanmean(Data.Results.U(InTimeRange,:,:,:),1));
  V = squeeze(nanmean(Data.Results.V(InTimeRange,:,:,:),1));  
  clear InTimeRange
  
  %fill end bin
  U(end,:,:) = U(1,:,:);
  V(end,:,:) = V(1,:,:);
  
  %produce output grid
  [xi,yi] = meshgrid(Settings.XGrid,Settings.YGrid);
  
  %convert to lat and lon
  ri = quadadd(xi,yi);
  th = atan2d(xi,yi);
  [lat,lon] = reckon(89.999,0,km2deg(ri),th); %exactly 90 causes issues
  
  lon = wrapTo360(lon);
  
  %duplicate in z
  lat = repmat(lat,1,1,numel(Settings.ZGrid));
  lon = repmat(lon,1,1,numel(Settings.ZGrid));
  z   = repmat(permute(Settings.ZGrid,[1,3,2]),numel(Settings.YGrid),numel(Settings.XGrid),1);
  
  %interpolate to new grid
  I = griddedInterpolant({Data.Settings.LonScale, ...
                          Data.Settings.LatScale, ...
                          Data.Settings.HeightScale},U);
  Ui = I(lon,lat,z);  
  I = griddedInterpolant({Data.Settings.LonScale, ...
                          Data.Settings.LatScale, ...
                          Data.Settings.HeightScale},V);  
  Vi = I(lon,lat,z);   
  
  %fill any NaNs
  Ui(isnan(Ui)) = 0;
  Vi(isnan(Vi)) = 0;
  
  %remove low latitudes, where data don't go as high
  Ui(lat <60) = 0; 
  Vi(lat <60) = 0; 
  clear U I z ri th V
  
  %now, smooth. we want to make sure we do the wraparound right,
  %so duplicate the data in lon first
  Ui = [Ui;Ui;Ui];
  Ui = smoothn(Ui,Settings.SmoothSize);
  Ui = Ui(size(xi,1)+1:size(xi,1)*2,:,:);
  
  Vi = [Vi;Vi;Vi];
  Vi = smoothn(Vi,Settings.SmoothSize);
  Vi = Vi(size(xi,1)+1:size(xi,1)*2,:,:);  
  
  %complete 3D coord system
  y = repmat(yi,1,1,numel(Settings.ZGrid));
  x = repmat(xi,1,1,numel(Settings.ZGrid));
  z   = repmat(permute(Settings.ZGrid,[1,3,2]),numel(Settings.YGrid),numel(Settings.XGrid),1);
  clear xi yi
  
  %top needs to be zeros to fill shapes
  Ui(:,:,end) = 0;
  Vi(:,:,end) = 0;
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% plot 3D plot and land surface underneath
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  if iDay <= numel(Settings.TimeRange)./2; subplot(4,numel(Settings.TimeRange)./2,iDay)
  else                                     subplot(4,numel(Settings.TimeRange)./2,iDay+numel(Settings.TimeRange)./2)
  end
  
  for PM=[-1,1]
    
    Levels = PM.*Settings.ColourLimit;
    
%     if PM == 1;  Alpha = [0.3,0.3,0.3]; else Alpha = [0.6,0.6,0.6]; end
    Alpha = 1;%0.77;% [0.9];%
    
    for iLev=1:1:numel(Levels);
      fv = isosurface(x,y,z,Ui,Levels(iLev));
      ThePatch = patch(fv);
      if PM == 1;ThePatch.FaceColor = [153,0,0]./255; else ThePatch.FaceColor = [0,128,255]./255; end
      ThePatch.EdgeColor = 'none';
      ThePatch.FaceAlpha  = Alpha(iLev);
      ThePatch.FaceLighting = 'gouraud';
      drawnow
    end; clear iLev fv ThePatch 
  end; clear PM
  
  %%plot Earth surface over smoothed topography
  hMap = surface(mapxi,mapyi,tp,Map2,...
                 'FaceColor','texturemap','EdgeColor','none','CDataMapping','direct');
  set(hMap,'clipping','on')
  %set terrain to not reflect light specularly
  set(hMap,'DiffuseStrength',0.5,'SpecularStrength',0)
  
  axis([-4600 4600 -4600 4600 -0.1 max(Settings.ZGrid)])
  axis off; grid off; box off
  axis square;  hold on
  
  %pole
  plot3([0,0],[90,90],[0,50],'-','color',[1,1,1].*0,'clipping','off')

  %barrel holding data, plus outer circle

  r2 = 4550; 
  r1 = 3335;
  
  %outer circle
  th=-180:1:180; plot3(r2.*cosd(th),r2.*sind(th),ones(size(th)).*0.0,'-','color',[1,1,1].*0)
  
  %data latitude limit at low altitude, to show map extends beyond it
  th=-180:1:180; plot3(r1.*cosd(th),r1.*sind(th),ones(size(th)).*0.5,'-','color',[1,1,1].*0.2)
  
  camlight;camlight
  view([88,65])
  title(datestr(Settings.TimeRange(iDay)))
  
  clear r1 r2 th hMap
  
  %labelling
  plot3([4300,4700],[0,0],[1,1].*1,'k-','clipping','off'); text(4900,0,0,'90E','fontsize',10);
  plot3([0,0],[-4300,-4700],[1,1].*1,'k-','clipping','off'); text(0,-5300,0,'0E','fontsize',10);

%   continue
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% plot horizontal slice
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
  %prepare panel
  if iDay <= numel(Settings.TimeRange)./2; subplot(4,numel(Settings.TimeRange)./2,iDay+numel(Settings.TimeRange)./2)
  else                                     subplot(4,numel(Settings.TimeRange)./2,iDay+numel(Settings.TimeRange))
  end
  
% clf
%   grid off, box off; axis off
  m_proj('stereographic','lat',90,'lon',80,'radius',30)
  
  %choose level
  zidx = closest(Settings.SliceHeight,z(1,1,:));
  xp = lon(:,:,zidx); yp = lat(:,:,zidx); 
  up = Ui(:,:,zidx);  vp = Vi(:,:,zidx);

  %plot coloured data
  m_pcolor(xp,yp,up); shading flat
  axis square
  caxis([-1,1].*30)
  colormap(flipud(cbrewer('div','RdBu',15)))
  hold on
  
  %coast
  m_coast('color',[1,1,1].*0.6);   
  
  %plot arrows
  Spacing = 10;
  m_quiver(xp(1:Spacing:end,1:Spacing:end), ...
           yp(1:Spacing:end,1:Spacing:end), ...
           -up(1:Spacing:end,1:Spacing:end),...
           -vp(1:Spacing:end,1:Spacing:end), ...
           'k-','linewi',1)
  
  %tidy up
  m_grid('ytick',[])


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % %% colourbar
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % 
% % % drawnow
% % % 
% % % Colours = [153,0,0;153,0,0;255,255,255;255,255,255;255,255,255;0,128,255;0,128,255]./255;
% % % colormap(flipud(Colours))
% % % cb1 = colorbar('southoutside','position',[0.04 0.06 0.1 0.02]);
% % % caxis([0,size(Colours,1)]);
% % % cb1.Label.String = ['U_{HLOS} [ms^{-1}]'];
% % % set(cb1,'xtick',[2,5],'xticklabel',[-1,1].*Settings.ColourLimit);
% % % % set(cb1,'xtick',0:1:10)
