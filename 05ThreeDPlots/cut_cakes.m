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
Settings.TimeRange = datenum(2021,1,-30:3:23); %plot data will be averaged over this range

%meridian to plot along (opposite meridian will also be shown)
Settings.Meridian = -120; %in range 0-180 degrees

%colour limit
Settings.ColourLimit = 10;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% make plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, [0.04,0.02],  0.02, 0.02);

% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % %% map prep
% % % %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % 
% % % %load data
% % % [Topo,Map] = topo_etc([-179.9,179.9],[-89.9,89.9],0,0,1,0);
% % % % Topo.elev = smoothn(Topo.elev,[5,5]);
% % % 
% % % 
% % % 
% % % %convert coordinate frames
% % % [xi,yi] = meshgrid(-6000:50:6000,-6000:50:6000);
% % % % % [xi,yi] = meshgrid(-6000:50:6000,-6000:50:6000);
% % % ri = quadadd(xi,yi);
% % % th = atan2d(xi,yi);
% % % [lat,lon] = reckon(89.999,0,km2deg(ri),th); %exactly 90 causes issues
% % % 
% % % I.a = griddedInterpolant({Map.LonScale,Map.LatScale},double(Map.Map(:,:,1))');
% % % I.b = griddedInterpolant({Map.LonScale,Map.LatScale},double(Map.Map(:,:,2))');
% % % I.c = griddedInterpolant({Map.LonScale,Map.LatScale},double(Map.Map(:,:,3))');
% % % tp  = griddedInterpolant(Topo.lons',Topo.lats',Topo.elev');
% % % 
% % % clear Map2
% % % Map2(:,:,1) = uint8(I.a(lon,lat));
% % % Map2(:,:,2) = uint8(I.b(lon,lat));
% % % Map2(:,:,3) = uint8(I.c(lon,lat));
% % % tp = tp(lon,lat);
% % % 
% % % 
% % % xi(lat < 49) = NaN;
% % % mapxi = xi; mapyi = yi; clear xi yi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% main plotting loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iDay=1:1:numel(Settings.TimeRange)
  
%   subplot(3,ceil(numel(Settings.TimeRange)./3),iDay)

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
  clear InTimeRange
  
  %fill end bin
  U(end,:,:) = U(1,:,:);
    
  %find the meridian, and stitch it together
  lonidxA = closest(Data.Settings.LonScale,Settings.Meridian);
  lonidxB = lonidxA + round(numel(Data.Settings.LonScale)./2);
  
  UA = squeeze(U(lonidxA,:,:));
  UB = squeeze(U(lonidxB,:,:)); 
  U = cat(1,UA,UB(end:-1:1,:));
  
  Lat      = 1:1:size(U,1);[Data.Settings.LatScale+90,Data.Settings.LatScale+max(Data.Settings.LatScale)+180];

  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %% plot
  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  
  %overinterpolate the data to make it prettier
  x = Lat; y = Data.Settings.HeightScale; [xi,yi] = meshgrid(x,y);
  x = -90:0.5:180; y = 0:0.5:25;          [xo,yo] = meshgrid(x,y);
  u = interp2(xi,yi,U',xo,yo);
  Bad = find(isnan(u));  u = smoothn(inpaint_nans(u),[3,3]); u(Bad) = NaN;

  
  %double u, as in other plots
  u(u < 0) = u(u < 0).*2;

  %fill bottom contour
  u(u < -40) = -40;
  
  %grey background
  patch([-1000,1000,1000,-1000,-1000],[0,0,30,30,0],[1,1,1].*0.9,'edgecolor','none')
  hold on
  
  %plot the data 
  pcolor(xo,yo,u);%,-40:5:40,'edgecolor','none')
  shading flat; hold on; grid on; box on
% %   contour(xo,yo,u,   10:10:100,'edgecolor','k','linestyle','-')
% %   contour(xo,yo,u,       [0,0],'edgecolor','k','linestyle','-','linewi',2)  
% %   contour(xo,yo,u,-(10:10:100),'edgecolor','k','linestyle',':')  
% %   [c,h] = contour(xo,yo,u,   10:10:100,'edgecolor','k','linestyle','-');
% %   clabel(c,h);
  
  colormap(flipud(cbrewer('div','RdBu',31)))
  caxis([-1,1].*40)
  xlim([60,90]+mean(diff(Data.Settings.LatScale)))
  ylim([0 25])
  set(gca,'fontsize',8)
  
  
  %ticks
  plot([90,90]+mean(diff(Data.Settings.LatScale)),[0,25],'k-','linewi',1)
  ticks = 60:10:120; ticklabs = ticks; ticklabs(ticks > 90) = 90-(ticklabs(ticks >90)-90);
  set(gca,'xtick',(60:10:120)+mean(diff(Data.Settings.LatScale)),'xticklabel',ticklabs);
%   text(90+mean(diff(Data.Settings.LatScale)),24,[num2str(Settings.Meridian),'E <-'],'horizontalalignment','right','clipping','off')
%   text(90+mean(diff(Data.Settings.LatScale)),24,['-> ',num2str(Settings.Meridian+180),'E '],'horizontalalignment','left','clipping','off')
    


ylim([-30,25])
stop
  

  drawnow
  
% % %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %   %% plot the land surface underneath
% % %   %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % %   
% % %   
% % %   
% % %   %%plot Earth surface over smoothed topography
% % %   hMap = surface(mapxi,mapyi,tp,Map2,...
% % %     'FaceColor','texturemap','EdgeColor','none','CDataMapping','direct');
% % %   set(hMap,'clipping','on')
% % %   %set terrain to not reflect light specularly
% % %   set(hMap,'DiffuseStrength',0.5,'SpecularStrength',0)
% % %   
% % %   axis([-4600 4600 -4600 4600 -0.1 max(Settings.ZGrid)])
% % %   axis off; grid off; box off
% % %   axis square;  hold on
% % %   
% % %   %pole
% % %   plot3([0,0],[90,90],[0,50],'-','color',[1,1,1].*0,'clipping','off')
% % % 
% % %   %barrel holding data, plus outer circle
% % % 
% % %   r2 = 4550; 
% % %   r1 = 3335;
% % %   
% % %   %outer circle
% % %   th=-180:1:180; plot3(r2.*cosd(th),r2.*sind(th),ones(size(th)).*0.0,'-','color',[1,1,1].*0)
% % %   
% % %   %data latitude limit at low altitude, to show map extends beyond it
% % %   th=-180:1:180; plot3(r1.*cosd(th),r1.*sind(th),ones(size(th)).*0.5,'-','color',[1,1,1].*0.2)
% % %   
% % % % %   %barrel holding data
% % % % %   th=-180:1:180; plot3(r1.*cosd(th),r1.*sind(th),ones(size(th)).*5,'-','color',[1,1,1].*0.2)
% % % % %   th=-180:1:180; plot3(r1.*cosd(th),r1.*sind(th),ones(size(th)).*24,'-','color',[1,1,1].*0.2)
% % % % %   for th=0:90:270; plot3([1,1].*r1.*cosd(th),[1,1].*r1.*sind(th),[5,24],'-','color',[1,1,1].*0.2); end
% % % % %   plot3([-1,1].*r1,[0,0],[1,1].*24,'-','color',[1,1,1].*0.2)
% % % % %   plot3([0,0],[-1,1].*r1,[1,1].*24,'-','color',[1,1,1].*0.2)
% % % % %   plot3([-1,1].*r2,[0,0],[1,1].*01,'-','color',[1,1,1].*0.2)
% % % % %   plot3([0,0],[-1,1].*r2,[1,1].*01,'-','color',[1,1,1].*0.2)
% % %   
% % %   camlight;camlight
% % %   view([88,65])
% % %   title(datestr(Settings.TimeRange(iDay)))
% % %   
% % %   
% % %   
% % %   %labelling
% % %   plot3([4300,4700],[0,0],[1,1].*1,'k-','clipping','off'); text(4900,0,0,'90E','fontsize',10);
% % %   plot3([0,0],[-4300,-4700],[1,1].*1,'k-','clipping','off'); text(0,-5300,0,'0E','fontsize',10);
% % % 
% % %   
% % % % %   %add arrows to the top showing the flow direction
% % % % %   for iX=-5000:500:5000;
% % % % %     for iY=-5000:500:5000;
% % % % %      
% % % % %       plot3(iX,iY,24,'ko')
% % % % %       
% % % % %     end
% % % % %   end
% % % % %   stop
  
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% colourbar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% % % drawnow
% % % 
% % % Colours = [153,0,0;153,0,0;255,255,255;255,255,255;255,255,255;0,128,255;0,128,255]./255;
% % % colormap(flipud(Colours))
% % % cb1 = colorbar('southoutside','position',[0.04 0.06 0.1 0.02]);
% % % caxis([0,size(Colours,1)]);
% % % cb1.Label.String = ['U_{HLOS} [ms^{-1}]'];
% % % set(cb1,'xtick',[2,5],'xticklabel',[-1,1].*Settings.ColourLimit);
% % % % set(cb1,'xtick',0:1:10)
