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

Level = 70; %hPa

AddWind = 1; %1 to use wind vectors from Aeolus data

Absolute = 1; %1 to use absolute GPH values, 0 to normalise to region

DaysToPlot = [datenum(2020,11,12),datenum(2020,12,12),datenum(2021,1,[2,5,20,29]),datenum(2021,2,[4,19])];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and merge data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = rCDF('era5_gph/nd2020.nc');
B    = rCDF('era5_gph/jfm2021.nc');

zidx = closest(Level,Data.level);
Data.z = squeeze(Data.z(:,:,zidx,:));
B.z    = squeeze(B.z(   :,:,zidx,:));
clear zidx

Data.time = datenum(1900,1,1,cat(1,Data.time,B.time),0,0);
Data.z    = cat(3,Data.z,B.z);
clear B

if AddWind == 1;
  Wind = load('../08Maps/aeolus_maps.mat');
  zidx = closest(Wind.Settings.HeightScale,17);
  Wind.Results.U = squeeze(Wind.Results.U(:,:,:,zidx));
  Wind.Results.V = squeeze(Wind.Results.V(:,:,:,zidx)).*10;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot days
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, 0.025, 0.1,0.1);


for iPlot=1:1:numel(DaysToPlot)
  
  %find day
  tidx = closest(Data.time,DaysToPlot(iPlot));
  Z = squeeze(Data.z(:,:,tidx)); clear tidx
  
  %remove unplotted regions
  Z(:,Data.latitude < 30) = NaN;
  
  if Absolute ~= 1;
    
    %take anomaly from plot mean
    Z = Z - nanmean(Z,'all');
    
    %scale
    Z = Z./1e4;
    
    %and produce colour levels
    CLevs = -2:0.125:2;
    
  else

    %produce colour levels
    if     Level == 70; CLevs = linspace(16.8,18.9,31).*10000;  
    elseif Level == 10; CLevs = linspace(28,31,31).*10000;  
    else                CLevs = linspace(prctile(Z(:),[18,82]),31);
    end
    
    
    %and line levels
    if     Level == 70; LLevs = [1.73,1.77].*10000.*9.81; 
    elseif Level == 10; LLevs = [2.91,2.98].*100000; 
    else                LLevs = prctile(Z(:),[40,60]);
    end
   
    
  end
  


  %generate panel
  subplot(2,4,iPlot)
  
  %create projection
  m_proj('stereographic','lat',90,'radius',60,'lon',90)
  hold on
  
  %plot data
  Z2 = Z; Z2(Z2 < min(CLevs)) = min(CLevs);
  m_contourf(Data.longitude,Data.latitude,Z2',CLevs,'edgecolor','none')
  
  %plot contours
% %   [c,h] = m_contour( Data.longitude,Data.latitude,Z',CLevs(3:4:end),'edgecolor',[1,1,1].*0.7,'linewi',0.25);
  [c,h] = m_contour( Data.longitude,Data.latitude,Z',[1,1].*LLevs(1),'edgecolor','r','linestyle','-','linewi',2);
  [c,h] = m_contour( Data.longitude,Data.latitude,Z',[1,1].*LLevs(2),'edgecolor','b','linestyle','-','linewi',2);
  
  %colours
  colormap(cbrewer('div','PuOr',15))
  caxis(minmax(CLevs))
  
  
  %add wind?
  if AddWind == 1;

    
    %find wind for this day
    ThisDay = closest(Wind.Settings.TimeScale,DaysToPlot(iPlot));
    U = squeeze(nanmean(Wind.Results.U(ThisDay+[-2:1:2],:,:),1));
    V = squeeze(nanmean(Wind.Results.V(ThisDay+[-2:1:2],:,:),1));   
    

    
    %fill gaps in longitude due to bin edges
    U(end,:) = U(1,:); V(end,:) = V(1,:);
    
    
    xold = Wind.Settings.LonScale; xnew = -20:1:360;
    yold = Wind.Settings.LatScale; ynew =  40:1:75;
    [xold,yold] = meshgrid(xold,yold); [xnew,ynew] = meshgrid(xnew,ynew);
    U = interp2(xold,yold,U',xnew,ynew);   V = interp2(xold,yold,V',xnew,ynew);
    
    %add quiver of wind vectors
    QuivSpace = [5,10];    
    xnewQ = xnew(1:QuivSpace(1):end,1:QuivSpace(2):end);
    ynewQ = ynew(1:QuivSpace(1):end,1:QuivSpace(2):end);
    UQ    = U(   1:QuivSpace(1):end,1:QuivSpace(2):end);
    VQ    = V(   1:QuivSpace(1):end,1:QuivSpace(2):end);
    
    %scale negative U, as previously
    UQ(UQ < 0) = UQ(UQ < 0).*2;
    
    %remove high latitudes (u and v get very bad)
    ynewQ(ynewQ > 75) = NaN;
  
    m_quiver(xnewQ,ynewQ,UQ,VQ,'color','k','linewi',0.33, ...
             'autoscale','on','autoscalefactor',1.3);    
    
    clear ThisDay U V xold yold xnew ynew UQ VQ QuivSpace
  end
  
  
  %tidy up
  title(datestr(DaysToPlot(iPlot)))
  if AddWind ~= 1;  m_coast('color',[1,1,1].*0,'linewi',0.25); end
  m_grid('ytick',[],'fontsize',10)
  drawnow
% stop
  
  
end





