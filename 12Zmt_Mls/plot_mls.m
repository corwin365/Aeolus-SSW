clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot MLS zonal mean temperature to study stratopause height
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/03/15
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Settings.InFile = 'zmt_mls.mat';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% load and prep data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Data = load(Settings.InFile);
Grid = Data.Settings.Grid;
Data = squeeze(Data.Results.Data);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% plot data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')
subplot = @(m,n,p) subtightplot (m, n, p, 0.006, 0.03, 0.03);

for iDay=1:1:numel(Grid.TimeScale)
  
  %prepare panel
  subplot(6,ceil(numel(Grid.TimeScale)./6),iDay)
  hold on
  
  %plot data - shaded
  x = Grid.LatScale; 
  y = Grid.HeightScale;
  v = squeeze(Data(:,iDay,:))';
  v(v < 180) = 180;
  contourf(x,y,v,linspace(180,280,17),'edgecolor','none');
  redyellowblue16; caxis([180 280])
  
  %plot data - shaded
  x = Grid.LatScale; 
  y = Grid.HeightScale;
  v = squeeze(Data(:,iDay,:))';
  [c,h] = contour(x,y,v,0:20:500,'edgecolor',[1,1,1].*0.5,'linewi',0.25);  
  clabel(c,h,'fontsize',8);

  
  
  %axes
  if mod(iDay,ceil(numel(Grid.TimeScale)./6)) > 1; set(gca,'ytick',[]); 
  elseif mod(iDay,ceil(numel(Grid.TimeScale)./6)) == 0; ylabel('Altitude [km]'); set(gca,'yaxislocation','right');
  else ylabel('Altitude [km]'); 
  end
  
  
  if     iDay <= ceil(numel(Grid.TimeScale)./6);    set(gca,'xtick',[20,45,70],'xticklabel',{'20N','45N','70N'},'xaxislocation','top');
  elseif iDay < 60;                                 set(gca,'xtick',0:30:90,'xticklabel',[])      
  else                                              set(gca,'xtick',[20,45,70],'xticklabel',{'20N','45N','70N'},'fontsize',8);
  end

  %date
  text(78,5,datestr(Grid.TimeScale(iDay),'dd/mm/yyyy'),'fontsize',10,'fontweight','bold','horizontalalign','right')

  %finish up
  box on
  axis([0 80 0 100])
  axis square
  set(gca,'tickdir','out')
  grid on
  set(gca,'fontsize',10);
  drawnow
  
end