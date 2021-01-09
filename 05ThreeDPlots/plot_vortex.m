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
Settings.InFile = 'aeolus_data_3d.mat';
Settings.TimeRange = datenum(2021,1,[1,5]); %plot data will be averaged over this range

%data regridding - km from pole
Settings.XGrid = -6000:100:6000;
Settings.YGrid = -6000:100:6000;
Settings.ZGrid = 5:1:25;

%data smoothing
Settings.SmoothSize = [5,5,3];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data, extract and overinterpolate onto a space grid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load data
Data = load(Settings.InFile);

%select and average over time period
InTimeRange = inrange(Data.Settings.TimeScale,Settings.TimeRange);
U = squeeze(nanmean(Data.Results.U(InTimeRange,:,:,:),1));
clear InTimeRange

%fill end bin
U(end,:,:) = U(1,:,:);

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



% % %fill any NaNs
% % for iLevel=1:1:size(z,3); Ui(:,:,iLevel) = inpaint_nans(Ui(:,:,iLevel));end; clear iLevel
Ui(isnan(Ui)) = 0;


%remove low latitudes
Ui(lat < 50) = 0;

clear U I lat lon z ri th



%now, smooth. we want to make sure we do the wraparound right, 
%so duplicate the data in lon first
Ui = [Ui;Ui;Ui];
Ui = smoothn(Ui,Settings.SmoothSize);
Ui = Ui(size(xi,1)+1:size(xi,1)*2,:,:);

%complete 3D coord system
y = repmat(yi,1,1,numel(Settings.ZGrid));
x = repmat(xi,1,1,numel(Settings.ZGrid));
z   = repmat(permute(Settings.ZGrid,[1,3,2]),numel(Settings.YGrid),numel(Settings.XGrid),1);
clear xi yi


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')

for PM=[-1,1]
  
  Levels = PM.*[5,10,15];
  
  if PM == 1;  Alpha = [0.3,0.3,0.3]; else Alpha = [0.6,0.6,0.6]; end
  
  for iLev=1:1:numel(Levels);
    fv = isosurface(x,y,z,Ui,Levels(iLev));
    ThePatch = patch(fv);
    if PM == 1;ThePatch.FaceColor = [153,0,0]./255; else ThePatch.FaceColor = [0,128,255]./255; end
    ThePatch.EdgeColor = 'none';
    ThePatch.FaceAlpha  = Alpha(iLev);
    ThePatch.FaceLighting = 'gouraud';
    drawnow
  end
end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot the land surface underneath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% % %load data
% % [Topo,Map] = topo_etc([-179.9,179.9],[-89.9,89.9],0,0,0,1);
% % Topo.elev = smoothn(Topo.elev,[9,9]);
% % Topo.elev = Topo.elev./3; %to make it easier to see what's happening
% % Topo.elev(:) = 0; %make it flat

%convert coordinate frames
[xi,yi] = meshgrid(-6000:30:6000,-6000:30:6000);
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


xi(lat < 40) = NaN;


%%plot Earth surface over smoothed topography
hMap = surface(xi,yi,tp,Map2,...
  'FaceColor','texturemap','EdgeColor','none','CDataMapping','direct');
set(hMap,'clipping','on')
%set terrain to not reflect light specularly
set(hMap,'DiffuseStrength',1,'SpecularStrength',0)

axis([-6000 6000 -6000 6000 -0.1 max(Settings.ZGrid)])
axis off; grid off; box off
axis square

camlight;camlight;camlight
view([35,61])