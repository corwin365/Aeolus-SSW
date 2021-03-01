clearvars -except Topo Map

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot 3D plots of the stratospheric polar vortex as observed by Aeolus
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/08
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%data selection
Settings.InFile = 'aeolus_data_3d_2021.mat';
Settings.TimeRange = datenum(2021,1,[-22:3:56]); %plot data will be averaged over this range

%data regridding - km from pole
Settings.XGrid = -6000:50   :6000;
Settings.YGrid = -6000:50   :6000;
Settings.ZGrid =     5: 0.75:22;

%colour limit
Settings.ColourLimit = 10;

%data smoothing - in units of the regridding above
Settings.SmoothSize = [5,5,1];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% make empty plot and space panels appropriately
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, [0.04,0.01],  [0.10,0.03], 0.03);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% map prep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load data
[Topo,Map] = topo_etc([-179.9,179.9],[-89.9,89.9],0,0,1,0);

%grid the topography onto a similar pole-centred grid as the data
[xi,yi] = meshgrid(-6000:20:6000,-6000:20:6000);
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


%remove low latitudes, to speed up plotting times
xi(lat < 49) = NaN;
mapxi = xi; mapyi = yi; clear xi yi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% main plotting loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iDay=1:1:numel(Settings.TimeRange)
  
  
  %create a panel for the plot
  subplot(3,ceil(numel(Settings.TimeRange)./3),iDay)
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% load data, extract and overinterpolate onto a space grid
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %load data
  Data = load(Settings.InFile);
  
  %select time period 
  InTimeRange = find(Data.Settings.TimeScale >= Settings.TimeRange(iDay)-1 ...
                   & Data.Settings.TimeScale <= Settings.TimeRange(iDay)+1);
                   
  %average over time period
  U = squeeze(nanmean(Data.Results.U(InTimeRange,:,:,:),1));
  clear InTimeRange
  
  %fill end bin - otherwise there's a gap at the prime meridian
  U(end,:,:) = U(1,:,:);
  
  %produce output mesh
  [xi,yi] = meshgrid(Settings.XGrid,Settings.YGrid);
  
  %convert mesh to lat and lon
  ri = quadadd(xi,yi);
  th = atan2d(xi,yi);
  [lat,lon] = reckon(89.999,0,km2deg(ri),th); %exactly 90 causes issues
  lon = wrapTo360(lon);
  
  %duplicate across height range
  lat = repmat(lat,1,1,numel(Settings.ZGrid));
  lon = repmat(lon,1,1,numel(Settings.ZGrid));
  z   = repmat(permute(Settings.ZGrid,[1,3,2]),numel(Settings.YGrid),numel(Settings.XGrid),1);
  
  %interpolate Aeolus data to new grid
  I = griddedInterpolant({Data.Settings.LonScale, ...
                          Data.Settings.LatScale, ...
                          Data.Settings.HeightScale},U);
  Ui = I(lon,lat,z);
  
  %interpolate over any NaNs in 2D at each level
  for iLevel=1:1:size(z,3); Ui(:,:,iLevel) = inpaint_nans(Ui(:,:,iLevel));end; clear iLevel
 
  
  %remove low and polar latitudes
  Ui(lat <60 | lat > 80) = 0;
  clear U I lat lon z ri th
  
  
  
  %smooth the data. we want to make sure we do the wraparound right,
  %so duplicate the data in lon first, then put it back as it was
  Ui = [Ui;Ui;Ui];
  Ui = smoothn(Ui,Settings.SmoothSize);
  Ui = Ui(size(xi,1)+1:size(xi,1)*2,:,:);
  
  %complete the 3D coord system
  y = repmat(yi,1,1,numel(Settings.ZGrid));
  x = repmat(xi,1,1,numel(Settings.ZGrid));
  z   = repmat(permute(Settings.ZGrid,[1,3,2]),numel(Settings.YGrid),numel(Settings.XGrid),1);
  clear xi yi
  
  %make the top layer all zeros, so the phase surfaces get closed off
  Ui(:,:,end) = 0;
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% plot
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  
  %plot positive and negative wind surface with a loop
  for PM=[-1,1]
    
    %define the surface
    Levels = PM.*Settings.ColourLimit;
   
    %then plot the surface. The loop is to make it easier if we want to add
    %more than one level.
    for iLev=1:1:numel(Levels);
      fv = isosurface(x,y,z,Ui,Levels(iLev));
      ThePatch = patch(fv);
      if PM == 1;ThePatch.FaceColor = [153,0,0]./255; else ThePatch.FaceColor = [0,128,255]./255; end
      ThePatch.EdgeColor = 'none';
      ThePatch.FaceAlpha  = 1;
      ThePatch.FaceLighting = 'gouraud';
      drawnow
    end
  end
  
  
  
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% plot the land surface underneath
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %%plot Earth surface over smoothed topography
  hMap = surface(mapxi,mapyi,tp,Map2,...
                 'FaceColor','texturemap','EdgeColor','none','CDataMapping','direct');
  set(hMap,'clipping','on')
  %set terrain to not reflect light specularly
  set(hMap,'DiffuseStrength',0.5,'SpecularStrength',0)
  
  axis([-4600 4600 -4600 4600 -0.1 max(Settings.ZGrid).*1.11])
  axis off; grid off; box off
  axis square;  hold on
  
  %plot outer circle
  r2 = 4550; 
  th=-180:1:180; plot3(r2.*cosd(th),r2.*sind(th),ones(size(th)).*0.0,'-','color',[1,1,1].*0)
  
  %plot data latitude limit at low altitude, to show map extends beyond it
  r1 = 3335;
  th=-180:1:180; plot3(r1.*cosd(th),r1.*sind(th),ones(size(th)).*0.6,'-','color',[1,1,1].*0.2)
  
  %plot the barrel over the pole - radius 1100km (i.e. pole to 80N)
  [a,b,c] = cylinder(1100,360);
  h = max(Settings.ZGrid).*1.1;
  c = c*h; 
  surf(a,b,c,'facecolor',[1,1,1].*0.5,'edgecolor','none','facealpha',0.5)
  th = 1:1:360;
  patch(1100.*cosd(th),1110.*sind(th),ones(size(th)).*h,[1,1,1].*0.5,'facealpha',0.4,'edgecolor',[1,1,1].*0.3,'linewi',0.5)
  plot3(1100.*cosd(th),1110.*sind(th),ones(size(th)).*.6,'color',[1,1,1].*0.3,'linewi',1)
  clear a b c h th
  
  %finalise lighting and create title
  camlight;camlight
  view([88,65])
  title(datestr(Settings.TimeRange(iDay)))

  
  %label a couple of longitudes so the reader can orient themselves
  plot3([4300,4700],[0,0],[1,1].*1,'k-','clipping','off'); text(4900,0,0,'90E','fontsize',10);
  plot3([0,0],[-4300,-4700],[1,1].*1,'k-','clipping','off'); text(0,-5300,0,'0E','fontsize',10);


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% colourbar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%manually place a colourbar at the bottom left. This is a bit fiddly as we
%want to make it look very specific
Colours = [153,0,0;153,0,0;255,255,255;255,255,255;255,255,255;0,128,255;0,128,255]./255;
colormap(flipud(Colours))
cb1 = colorbar('southoutside','position',[0.04 0.06 0.1 0.02]);
caxis([0,size(Colours,1)]);
cb1.Label.String = ['U_{HLOS} [ms^{-1}]'];
set(cb1,'xtick',[2,5],'xticklabel',[-1,1].*Settings.ColourLimit);
