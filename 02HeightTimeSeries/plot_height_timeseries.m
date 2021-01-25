clearvars

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%plot height-time series of Aeolus, MLS and ERA5 u and T
%
%now also plots MLS CO and O3 - but data for ERA5 equivalent not downloaded
%
%Corwin Wright, c.wright@bath.ac.uk, 2021/01/23
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%vars to plot. Up to two - more will not be plotted
%dynamics plot
Settings.Vars   = {'T','U'};
Settings.Units  = {'Temperature Anomaly [K]','Zonal Wind [ms^{-1}]'};
Settings.YRanges = [0,90; 0,30];

% % % %chem\istry plot
% % % Settings.Vars   = {'O','C'};
% % % Settings.Units  = {'Ozone Anomaly [ppm]','Carbon Monoxide Anomaly [ppm]'};
% % % Settings.YRanges = [0,90;0,90];

%data source?
%only '1' works for CO and O3
Settings.Source = 1; %1 is obs, 2 is model, 3 is difference (obs-model)

%time range
Settings.TimeRange = [datenum(2020,11,1),datenum(2021,2,28)];

%smooth the data?
Settings.SmoothSize = [3,1;
                       3,1]; %time units, height units - both depend on gridding choices

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load files
Data.Mls    = load('zm_data_mls.mat');
Data.Aeolus = load('zm_data_aeolus.mat');
Data.Era5T  = load('zm_data_era5_6090.mat');
Data.Era5W  = load('zm_data_era5_5565.mat');

%bad day in MLS data due to only partial coverage skewing average -
%remove and then take mean of day before and day after
BadDay = find(Data.Mls.Settings.Grid.TimeScale == datenum(2020,1,359));
Data.Mls.Results.Data(:,BadDay,:) = NaN;
Data.Mls.Results.Data(:,BadDay,:) = mean(Data.Mls.Results.Data(:,[-1,1]+BadDay,:),2);
clear BadDay



%pull out each variable
Obs.T.Data = squeeze(Data.Mls.Results.Data(   1,:,:)); Obs.T.Grid = Data.Mls.Settings.Grid;    Obs.T.Range = Data.Mls.Settings.LatRange;    Obs.T.Source = 'MLS';
Obs.O.Data = squeeze(Data.Mls.Results.Data(   2,:,:)); Obs.O.Grid = Data.Mls.Settings.Grid;    Obs.O.Range = Data.Mls.Settings.LatRange;    Obs.O.Source = 'MLS';
Obs.C.Data = squeeze(Data.Mls.Results.Data(   3,:,:)); Obs.C.Grid = Data.Mls.Settings.Grid;    Obs.C.Range = Data.Mls.Settings.LatRange;    Obs.C.Source = 'MLS';
Obs.U.Data = squeeze(Data.Aeolus.Results.Data(1,:,:)); Obs.U.Grid = Data.Aeolus.Settings.Grid; Obs.U.Range = Data.Aeolus.Settings.LatRange; Obs.U.Source = 'Aeolus';
Obs.V.Data = squeeze(Data.Aeolus.Results.Data(2,:,:)); Obs.V.Grid = Data.Aeolus.Settings.Grid; Obs.V.Range = Data.Aeolus.Settings.LatRange; Obs.V.Source = 'Aeolus';
ReA.T.Data = squeeze(Data.Era5T.Results.Data( 3,:,:)); ReA.T.Grid = Data.Era5T.Settings.Grid;  ReA.T.Range = Data.Era5T.Settings.LatRange;  ReA.T.Source = 'ERA5';
ReA.U.Data = squeeze(Data.Era5W.Results.Data( 1,:,:)); ReA.U.Grid = Data.Era5W.Settings.Grid;  ReA.U.Range = Data.Era5W.Settings.LatRange;  ReA.U.Source = 'ERA5';
ReA.V.Data = squeeze(Data.Era5W.Results.Data( 2,:,:)); ReA.V.Grid = Data.Era5W.Settings.Grid;  ReA.V.Range = Data.Era5W.Settings.LatRange;  ReA.V.Source = 'ERA5';

clear Data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% for non-wind data, subtract climatology
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Clim = load('zm_data_mls_clim.mat');
Obs.T.Data = Obs.T.Data - squeeze(Clim.Results.Data(1,:,:));
% Obs.O.Data = Obs.O.Data - squeeze(Clim.Results.Data(2,:,:));
% Obs.C.Data = Obs.C.Data - squeeze(Clim.Results.Data(3,:,:));
clear Clim


Clim = load('zm_data_era5_clim.mat');
ReA.T.Data = ReA.T.Data - squeeze(Clim.Results.Data);
clear Clim

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% interpolate model onto the obs grid, then take diff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Vars = {'U','V','T'};
for iVar=1:1:3;
  
  [xi,yi] = meshgrid(ReA.(Vars{iVar}).Grid.TimeScale, ...
                     ReA.(Vars{iVar}).Grid.HeightScale);  
  [xj,yj] = meshgrid(Obs.(Vars{iVar}).Grid.TimeScale, ...
                     Obs.(Vars{iVar}).Grid.HeightScale);
  ReA.(Vars{iVar}).Data = interp2(xi,yi,ReA.(Vars{iVar}).Data',xj,yj)';
      
  ReA.(Vars{iVar}).Grid = Obs.(Vars{iVar}).Grid;
  
end
clear iVar xi yi xj yj Vars

Dif = Obs;
Dif.T.Data = Obs.T.Data - ReA.T.Data; Dif.T.Source = '(MLS - ERA5)';
Dif.U.Data = Obs.U.Data - ReA.U.Data; Dif.U.Source = '(Aeolus - ERA5)';
Dif.V.Data = Obs.V.Data - ReA.V.Data; Dif.V.Source = '(Aeolus - ERA5)';


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% select data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for iVar = 1:1:numel(Settings.Vars)
  
  switch Settings.Source
    case 1; Vars.(['Var',num2str(iVar)]) = Obs.(Settings.Vars{iVar});
    case 2; Vars.(['Var',num2str(iVar)]) = ReA.(Settings.Vars{iVar});
    case 3; Vars.(['Var',num2str(iVar)]) = Dif.(Settings.Vars{iVar});
  end
end

clear Obs ReA Dif iVar 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% plot data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clf
set(gcf,'color','w')
Letters = 'ab';

for iVar=1:1:2;
  
  %get data
  Var = Vars.(['Var',num2str(iVar)]);

  %colour levels
  if strcmp(Settings.Vars{iVar},'U') |  strcmp(Settings.Vars{iVar},'V')
    ColourLevels = [-30:2.5:30];
    ColourRange  = [-30,30];
    LineLevels   = [-100:5:100];
  elseif strcmp(Settings.Vars{iVar},'T')
    ColourLevels = -25:2.5:25;
    ColourRange  = [-25,25];
    LineLevels   = [-100:10:-30,-20:5:20,30:10:100];
  elseif strcmp(Settings.Vars{iVar},'O')
    Var.Data = Var.Data.*1e6;
    ColourLevels = -1:0.1:1;
    ColourRange  = [-1,1];
    LineLevels   = -10:0.5:10;
  elseif strcmp(Settings.Vars{iVar},'C')
    Var.Data = Var.Data.*1e6;
    ColourLevels = -3:0.25:3;
    ColourRange  = [-3,3];
    LineLevels   = -10:1:10;
  else
    disp('Colour levels not specified'); stop
  end
  
  %scale down ranges if difference plots
  if Settings.Source == 3;
    ColourLevels = round(ColourLevels./4);
    LineLevels   = round(LineLevels./4);
    ColourRange  = round(ColourRange./4);
  end
  
  %create axes
  s = subplot(2,1,iVar);
  axis([Settings.TimeRange, Settings.YRanges(iVar,:)])  
  hold on; grid on
  
  %smooth data
  Bad = find(isnan(Var.Data));
  Var.Data = smoothn(inpaint_nans(Var.Data),Settings.SmoothSize(iVar,:));
  Var.Data(Bad) = NaN; clear Bad
  
  %overinterpolate, for visual appeal
  t = linspace(min(  Var.Grid.TimeScale),max(  Var.Grid.TimeScale),numel(  Var.Grid.TimeScale)*10);
  h = linspace(min(Var.Grid.HeightScale),max(Var.Grid.HeightScale),numel(Var.Grid.HeightScale)*10); 
  [tj,hj] = meshgrid(t,h); 
  [ti,hi] = meshgrid(Var.Grid.TimeScale+[0,diff(Var.Grid.TimeScale)./2],Var.Grid.HeightScale+[0,diff(Var.Grid.HeightScale)./2]);
  v = interp2(ti,hi,Var.Data',tj,hj)';
  Bad = find(isnan(v)); v = smoothn(inpaint_nans(v),[9,9]); v(Bad) = NaN; %[9,9] is below the level of the [10,10] we oversampled the data by above
  clear ti hi tj hj Bad
  
  %plot the data
  ToPlot = v'; ToPlot(ToPlot < min(ColourLevels)) = min(ColourLevels);
  contourf(t,h,ToPlot, ...
           ColourLevels,'edgecolor','none');
  clear ToPlot
  [c,ha] =contour(t,h,v',LineLevels(LineLevels > 0),'edgecolor','k');                   clabel(c,ha);
  [c,ha] =contour(t,h,v',LineLevels(LineLevels < 0),'edgecolor','k','linestyle','--');  clabel(c,ha);  
  [c,ha] =contour(t,h,v',[0,0],'edgecolor','k','linewi',1.5);                           clabel(c,ha);   
         
  %colours       
  caxis(ColourRange)
  if     strcmp(Settings.Vars{iVar},'T'); colormap(s,flipud(cbrewer('div','RdYlBu',1+numel(ColourLevels))))
  elseif strcmp(Settings.Vars{iVar},'C'); colormap(s,flipud(cbrewer('div',  'PRGn',1+numel(ColourLevels))))
  elseif strcmp(Settings.Vars{iVar},'O'); colormap(s,flipud(cbrewer('div',  'BrBG',1+numel(ColourLevels))))
  else                                    colormap(s,flipud(cbrewer('div',  'RdBu',1+numel(ColourLevels))))
  end
  cb = colorbar('westoutside');
  cb.Label.String = ['Zonal Mean ',Settings.Units{iVar}];

  %overlay tropopause and stratopause heights
  TP = load('../06TropopauseFinding/tropopause_60N.mat');
  plot(TP.Time,TP.Height,'linestyle','-.','linewi',2,'color',[0.5,0.25,1])
  SP = load('../06TropopauseFinding/stratopause_60_90N.mat');
  plot(SP.Time,smoothn(SP.Height,[3,1]),'linestyle','-.','linewi',2,'color',[0,0.5,0])
  clear SP TP
  
  %tidy axes
  box on
  plot([1,1].*datenum(2021,1,5),[-999,999],'k:','linewi',2)%zero time  
  set(gca,'tickdir','out')
  ylabel('Altitude [km]')
  set(gca,'xtick',datenum(2021,1,-105:10:105), ...
          'xticklabel',datestr(datenum(2020,1,-105:10:105),'dd/mmm'))
  if iVar==1;set(gca,'xaxislocation','top'); end
  
  %descriptive label
  xlim = get(gca,'xlim'); ylim = get(gca,'ylim');
  if max(Settings.YRanges(iVar,:)) > 30; ypos = 0.05; else ypos = 0.95; end
  text(min(xlim)+0.01*range(xlim),min(ylim)+ypos.*range(ylim), ...
       ['(',Letters(iVar),') ',Var.Source,', ',num2str(Var.Range(1)),'-',num2str(Var.Range(2)),'N mean'])
  clear xlim ylim ypos
  
  

  %second set of axes (pressure and SSW-relative days)
  %done last as this affects all subsequent positioning
  ax1 = gca;
  ax2 = axes('Position',ax1.Position,...
             'XAxisLocation','bottom',...
             'YAxisLocation','right',...
             'Color','none', ...
             'tickdir','out');
  axis([Settings.TimeRange+[-3.25,0], Settings.YRanges(iVar,:)])  %I have no idea what the 3.25 day shift is - plotting bug?!? - but this makes the top and bottom axes align perfectly          
  set(gca,'xtick',datenum(2021,1,5+(-100:10:100)), ...
          'xticklabel',-100:10:100)  
  if iVar==2;set(gca,'xaxislocation','top'); xlabel('Days since major SSW commenced'); end
  grid off
  if max(Settings.YRanges(iVar,:)) < 40; set(gca,'ytick', 0:5:200,'yticklabel',roundsd(h2p( 0:5:200),2))
  else;                                  set(gca,'ytick',0:10:200,'yticklabel',roundsd(h2p(0:10:200),2))
  end  
  ylabel('Pressure [hPa]')

  
  drawnow  
  
end