clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%plot 10hPa GPH on selected dates
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/03/17
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Level = 87; %hPa
DaysToPlot = [datenum(2020,11,16),datenum(2020,12,12),datenum(2021,1,[2,5,20,29]),datenum(2021,2,[4,19])];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and merge data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = load('mls_gph.mat');

zidx = closest(p2h(Level),Data.Settings.Grid.HeightScale);
Data.z = squeeze(Data.Results.Data(1,:,zidx,:,:));
Data.z = permute(Data.z,[3,2,1])./1000;

Data.time = Data.Settings.Grid.TimeScale;
Data.latitude = Data.Settings.Grid.Lat;
Data.longitude = Data.Settings.Grid.Lon;




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot days
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w','position',[263 190 1188 740])
subplot = @(m,n,p) subtightplot (m, n, p, 0.025, 0.1,0.1);


for iPlot=2%1:1:numel(DaysToPlot)
  
  %find day
  tidx = closest(Data.time,DaysToPlot(iPlot));
  Zin = squeeze(Data.z(:,:,tidx)); clear tidx
  Zin(end,:)   = Zin(1,:);  

  %overinterpolate and smooth at levels below the scale of the data
  %as usual, this doesn't affect the meaning (it's the same as using a 
  %different contouring routine), but makes the figures a lot prettier
  lati = 30:1:90; loni = -180:1:180; [lati,loni] = meshgrid(lati,loni);
  zi = interp2(Data.latitude,Data.longitude,Zin,lati,loni);
  zi = inpaint_nans(zi);
  zi = [zi;zi;zi]; 
  zi = smoothn(zi,[19,3]);
  zi = zi(362:1:362*2-2,:);

  
  %remove unplotted regions
  zi(lati < 25) = NaN;
  zi(lati > 82) = NaN;
  
  %produce colour levels
  if     Level == 87; CLevs = linspace(18.4,20.1,15);
  elseif Level == 10; CLevs = linspace(29.6,32.9,15);
  else                CLevs = linspace(prctile(Z(:),[18,82]),31);
  end
  
  
  %and line levels (will actually be put on the edge of the nearest colour
  %level)
  if     Level == 87; LLevs = [18.9,19.5];
  elseif Level == 10; LLevs = [30.5,31.5];
  else                LLevs = prctile(Z(:),[40,60]);
  end
  
  
  
  
  %generate panel
  subplot(2,4,iPlot)
  
  %create projection
  m_proj('stereographic','lat',90,'radius',60,'lon',90)
  hold on

  
  %plot data
  zi2 = zi; zi2(zi2 < min(CLevs)) = min(CLevs);
  m_contourf(loni,lati,zi2,CLevs,'edgecolor','none')

  %put line son edge of the nearest colour level
  LLevs(1) = CLevs(closest(CLevs,LLevs(1)));
  LLevs(2) = CLevs(closest(CLevs,LLevs(2)));
  
  
  %plot contours
  % %   [c,h] = m_contour( Data.longitude,Data.latitude,Z',CLevs(3:4:end),'edgecolor',[1,1,1].*0.7,'linewi',0.25);
  [c,h] = m_contour(loni,lati,zi,[1,1].*LLevs(1),'edgecolor','r','linestyle','-','linewi',2);
  [c,h] = m_contour(loni,lati,zi,[1,1].*LLevs(2),'edgecolor','b','linestyle','-','linewi',2);
  
  %colours
  colormap(cbrewer('div','PuOr',15))
  caxis(minmax(CLevs))
%   colorbar
  
  
  
  %tidy up
  title(datestr(DaysToPlot(iPlot)))
  m_grid('ytick',[],'fontsize',10)
  drawnow

  
  
  
  
  
  
end

