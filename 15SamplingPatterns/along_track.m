clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% figure showing MLS and Aeolus along-track sampling patterns near 60N
%
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/07/31
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%choose a day
Settings.Day = datenum(2021,1,5);

%choose a latitude band
Settings.LatBand = [49,87];



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%the exact variable doesn't matter - we're only using geolocation
Aeolus = get_aeolus(Settings.Day,[LocalDataDir,'Aeolus/NC_FullQC'],{'Zonal_wind_projection'},{'X'});
Mls    = get_mls(   Settings.Day,[LocalDataDir,'/MLS/'],           {'T'},                    {'X'});

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% find a region to plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%select all points in the latitude range
IRA = inrange(Aeolus.Lat,Settings.LatBand);
IRM = inrange(Mls.Lat,   Settings.LatBand);

Aeolus = reduce_struct(Aeolus,IRA);
Mls    = reduce_struct(Mls,   IRM);

%now, find any time discontinuities of > 30 min
%these represent passage out of the region
dtA = diff(Aeolus.Time); dtA = find(dtA > 1./24./2);
dtM = diff(Mls.Time);    dtM = find(dtM > 1./24./2);

%select the data between the second and third of these
JumpA = dtA([1,2]); JumpM = dtM([1,2]);


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% pull out data, and identify if asc or desc node
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Aeolus = reduce_struct(Aeolus,(JumpA(1)+1):JumpA(2));
Mls    = reduce_struct(Mls,   (JumpM(1)+1):JumpM(2));
clear IRA IRM JumpM JumpA dtA dtM

stop

[~,idx] = max(Aeolus.Lat); Aeolus.Node = ones(size(Aeolus.Lat)); Aeolus.Node(idx+1:end) = -1;
[~,idx] = max(   Mls.Lat);    Mls.Node = ones(size(   Mls.Lat));    Mls.Node(idx+1:end) = -1;
% Aeolus.Node = diff(smooth(Aeolus.Lat),15)./abs(diff(smooth(Aeolus.Lat),15));
% Mls.Node    = diff(smooth(   Mls.Lat),15)./abs(diff(smooth(   Mls.Lat),15));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w','position',[347 178 1484 798])
subplot = @(m,n,p) subtightplot (m, n, p, 0.08, 0.1,0.1);

for iPanel=[1,2]
  switch iPanel
    case 2; Data = Aeolus;  Settings.ZRange = [0,30];
    case 1; Data = Mls;     Settings.ZRange = [0,90];
  end
  
  %create subpanel  
  subplot(2,1,iPanel)
  hold on; box on; grid off; set(gca,'tickdir','out')
  
  %prepare axes
  ylim(Settings.ZRange); xlim(Settings.LatBand)
  set(gca,'xminortick','on','yminortick','on')
  
  %shade latitude bands
  for iLat=40:10:90;
    patch(iLat+[0,5,5,0,0],Settings.ZRange([1,1,2,2,1]),[1,1,1].*0.95,'edgecolor',[1,1,1].*0.7)
  end
  
  %plot horizontal lines
  for iZ=0:10:max(Settings.ZRange);
    if iZ == max(Settings.ZRange) | iZ == 0; plot(Settings.LatBand,[1,1].*iZ,'-','color',[1,1,1].*0.0)
    else;                                    plot(Settings.LatBand,[1,1].*iZ,'-','color',[1,1,1].*0.7)
    end
  end
  
  %plot data
  plot(Data.Lat(Data.Node > 0),Data.Alt(Data.Node > 0),'o','markersize',6,'color','r')
  plot(Data.Lat(Data.Node < 0),Data.Alt(Data.Node < 0),'x','markersize',6,'color','b')
  

  
  if iPanel == 2; 
    set(gca,'xaxislocation','top'); 
    set(gca,'xtick',[40:5:90],'xticklabel',{'40^\circN','45^\circN','50^\circN','55^\circN','60^\circN','65^\circN','70^\circN','75^\circN','80^\circN','85^\circN','90^\circN'})
  else
    set(gca,'xtick',[40:5:90],'xticklabel','')
  end
  
  ylabel('Altitude [km]')
  
  if iPanel ==2; text(86.5,28,'(b) Aeolus','horizontalalignment','right','fontsize',20); end
  if iPanel ==1; text(86.55,84,'(a)  MLS','horizontalalignment','right','fontsize',20); end
  
  %plot direction arrows
  z = 0.2.*max(Settings.ZRange);
  arrow([88,z],[89.5,z],'color','r'); plot(90,z,'ro','clipping','off')
  text(88,z+0.06.*max(Settings.ZRange),'Asc','color','r')
  z = 0.1.*max(Settings.ZRange);
  arrow([89.5,z],[88,z],'color','b'); plot(90,z,'bx ','clipping','off')
  text(88,z-0.06.*max(Settings.ZRange),'Desc','color','b')

  
  
  
end