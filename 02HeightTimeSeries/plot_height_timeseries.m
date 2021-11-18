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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%T - temperature
%U - Aeolus U
%V - Aeolus V
%C - MLS carbon monoxide
%O - MLS ozone
%u - MLS U
%v - MLS V
%for the first three, ERA5 equivalents are also available by changing
%Settings.Source to 2, and diffs from ERA5 by setting it to 3.

% % %MLS-only dynamics plot from surface to thermosphere
% % Settings.Vars   = {'T','u'};
% % Settings.Units  = {'Temperature Anomaly [K]','Zonal Wind [ms^{-1}]'};
% % Settings.YRanges = [0,90; 0,90];

%MLS-Aeolus T-U plot from surface to 30km.
Settings.Vars   = {'T','U'};
Settings.Units  = {'Temperature Anomaly [K]','Zonal Wind [ms^{-1}]'};
Settings.YRanges = [0,30; 0,30];

% % %chemistry plot from surface to 90km
% % Settings.Vars   = {'O','C'};
% % Settings.Units  = {'O_3 Anomaly [ppm]','CO Anomaly [ppm]'};
% % Settings.YRanges = [0,90;0,90];

% % %ALL THE WIND
% % Settings.Vars   = {'u','U'};
% % Settings.Units  = {'Zonal Wind [ms^{-1}]','Zonal Wind [ms^{-1}]'};
% % Settings.YRanges = [0,90; 0,30];

% % %ALL THE TEMPERATURE
% % Settings.Vars   = {'T','T'};
% % Settings.Units  = {'Temperature [K]','Temperature [K]'};
% % Settings.YRanges = [0,90; 0,30];

%other settings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%take anomalies for non-U values, or show absolute values?
Settings.Anom = 1;

%data source?
Settings.Source = 1; %1 is obs, 2 is model, 3 is difference (obs-model)

%time range
Settings.TimeRange = [datenum(2020,11,1),datenum(2021,2,28)];

%smooth the data?
Settings.SmoothSize = [1,1;
                       1,1]; %time units, height units - both depend on gridding choices

%oversample the data?
%this is just for visual effect, to make the shapes more sinuous
%it doesn't affect the results as it scales with the smoother above - it's
%just equivalent to a nice-looking contour() function
%settings this value to 1 effectively disables it - it just "resamples" the
%data with the original sampling rate in both dimensions
Settings.OverSampleFactor = 1;                     
                     
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% load data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%load files
Data.MlsT   = load('zm_data_mls_6082.mat');
Data.MlsW   = load('zm_data_mls_5565.mat');
Data.Aeolus = load('zm_data_aeolus.mat');
Data.Era5T  = load('zm_data_era5_6090.mat');
Data.Era5W  = load('zm_data_era5_5565.mat');

%bad day in MLS data due to only partial coverage skewing average -
%remove and then take mean of day before and day after
BadDay = find(Data.MlsT.Settings.Grid.TimeScale == datenum(2020,1,359));
Data.MlsT.Results.Data(:,BadDay,:) = NaN;
Data.MlsT.Results.Data(:,BadDay,:) = mean(Data.MlsT.Results.Data(:,[-1,1]+BadDay,:),2);
Data.MlsW.Results.Data(:,BadDay,:) = NaN;
Data.MlsW.Results.Data(:,BadDay,:) = mean(Data.MlsW.Results.Data(:,[-1,1]+BadDay,:),2);
clear BadDay



%pull out each variable. NOTE CASE SENSITIVITY
Obs.T.Data = squeeze(Data.MlsT.Results.Data(  1,:,:)); Obs.T.Grid = Data.MlsT.Settings.Grid;   Obs.T.Range = Data.MlsT.Settings.LatRange;   Obs.T.Source = 'MLS';
Obs.O.Data = squeeze(Data.MlsT.Results.Data(  2,:,:)); Obs.O.Grid = Data.MlsT.Settings.Grid;   Obs.O.Range = Data.MlsT.Settings.LatRange;   Obs.O.Source = 'MLS';
Obs.C.Data = squeeze(Data.MlsT.Results.Data(  3,:,:)); Obs.C.Grid = Data.MlsT.Settings.Grid;   Obs.C.Range = Data.MlsT.Settings.LatRange;   Obs.C.Source = 'MLS';
Obs.u.Data = squeeze(Data.MlsW.Results.Data(  4,:,:)); Obs.u.Grid = Data.MlsW.Settings.Grid;   Obs.u.Range = Data.MlsW.Settings.LatRange;   Obs.u.Source = 'MLS';
Obs.v.Data = squeeze(Data.MlsW.Results.Data(  5,:,:)); Obs.v.Grid = Data.MlsW.Settings.Grid;   Obs.v.Range = Data.MlsW.Settings.LatRange;   Obs.v.Source = 'MLS';
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
if Settings.Anom == 1;
  Obs.T.Data = Obs.T.Data - squeeze(Clim.Results.Data(1,:,:)); 
  Obs.O.Data = Obs.O.Data - squeeze(Clim.Results.Data(2,:,:));
  Obs.C.Data = Obs.C.Data - squeeze(Clim.Results.Data(3,:,:));
end
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
  
  %scale data if units are weird
  if     strcmp(Settings.Vars{iVar},'O'); Var.Data = Var.Data.*1e6;
  elseif strcmp(Settings.Vars{iVar},'C'); Var.Data = Var.Data.*1e6;
  end
  
  %choose colour range
  InHeightRange = inrange(Var.Grid.HeightScale,Settings.YRanges(iVar,:));
  if Settings.Anom == 1;
    ColourRange  = [-1,1].*ceil(max(abs(prctile(flatten(Var.Data(:,InHeightRange)),[1,99]))));
  else
    ColourRange = prctile(flatten(Var.Data(:,InHeightRange)),[1,99]);
  end
  
  %for long ranges, round off the colourbar to a more sensible multiplier,
  %to make the levels more human-readable
  if     max(ColourRange) > 50; ColourRange = round(ColourRange./20).*20;
  elseif max(ColourRange) > 20; ColourRange = round(ColourRange./10).*10;
  elseif max(ColourRange) > 10; ColourRange = round(ColourRange./5).*5;
  else;                         ColourRange = [-1,1].*3;
  end

  
%   ColourRange = [-1,1].*5
  ColourLevels = linspace(ColourRange(1),ColourRange(2),33);
  %choose line levels. extend line levels out beyond the colour levels, for extrema
  LineLevels   = linspace(ColourRange(1),ColourRange(2),10-1);
  LineLevels = mean(diff(LineLevels)).*(-100:1:100);
  
  %create axes
  s = subplot(2,1,iVar);
  axis([Settings.TimeRange, Settings.YRanges(iVar,:)])  
  hold on; grid on
  
  
  %overinterpolate, for visual appeal
  t = linspace(min(  Var.Grid.TimeScale),max(  Var.Grid.TimeScale),numel(  Var.Grid.TimeScale)*Settings.OverSampleFactor);
  h = linspace(min(Var.Grid.HeightScale),max(Var.Grid.HeightScale),numel(Var.Grid.HeightScale)*Settings.OverSampleFactor); 
  [tj,hj] = meshgrid(t,h); 
  [ti,hi] = meshgrid(Var.Grid.TimeScale+[0,diff(Var.Grid.TimeScale)./2],Var.Grid.HeightScale+[0,diff(Var.Grid.HeightScale)./2]);
  v = interp2(ti,hi,Var.Data',tj,hj)';
  Smoother = Settings.OverSampleFactor.*Settings.SmoothSize(iVar,:);
  if mod(Smoother(1),2) == 0; Smoother(1) = Smoother(1)+1; end
  if mod(Smoother(2),2) == 0; Smoother(2) = Smoother(2)+1; end
  Bad = find(isnan(v)); v = smoothn(inpaint_nans(v),Smoother); v(Bad) = NaN;
  clear ti hi tj hj Bad Smoother Oversample
  
  
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
  TP = load('../06TropopauseFinding/tropopause_6090N.mat');
  plot(TP.Time,TP.Height,'linestyle','-.','linewi',2,'color',[0,0.5,0])
  SP = load('../06TropopauseFinding/stratopause_6090N.mat');
  plot(SP.Time,smoothn(SP.Height,[3,1]),'linestyle','-.','linewi',2,'color',[0.5,0.25,1])
  clear SP TP
  
  %tidy axes
  box on
  plot([1,1].*datenum(2021,1,5),[-999,999],'k:','linewi',2)%zero time  
  set(gca,'tickdir','out')
  ylabel('Altitude [km]')
  set(gca,'xtick',datenum(2021,1,-105:5:105), ...
          'xticklabel',datestr(datenum(2020,1,-105:5:105),'dd/mmm'), ...
          'XMinorTick','on','YMinorTick','on')
  ax = gca; ax.XAxis.FontSize=14;   
  xtickangle(ax,70)
        
  if iVar==1;set(gca,'xaxislocation','top'); end
  
  %descriptive label
  xlim = get(gca,'xlim'); ylim = get(gca,'ylim');
  if max(Settings.YRanges(iVar,:)) > 30; ypos = 0.05;
  elseif ~strcmp(Var.Source,'MLS')       ypos = 0.95;
  else;                                  ypos = 0.05; end
  text(min(xlim)+0.01*range(xlim),min(ylim)+ypos.*range(ylim), ...
       ['(',Letters(iVar),') ',Var.Source,', ',num2str(Var.Range(1)),'-',num2str(Var.Range(2)),'N mean'])
  
  
  %in the 0-90km plots, add a line representing the top of the 30km plots
  if max(ylim) > 30; plot(xlim,[1,1].*30,'k--');end
  clear xlim ylim ypos

  
  %hack to disable ticks on right
  yyaxis right;
  set( gca, 'YTick', [] );
  set( gca, 'YColor', 'k' );

  
  %second set of axes (pressure and SSW-relative days)
  %done last as this affects all subsequent positioning
  ax1 = gca;
  ax2 = axes('Position',ax1.Position,...
             'XAxisLocation','bottom',...
             'YAxisLocation','right',...
             'Color','none', ...
             'tickdir','out');

  axis([Settings.TimeRange+[-3.15,0], h2p(Settings.YRanges(iVar,[2,1]))])  %I have no idea what multi-day shift is - minor plotting bug in the axis matching from label sizing maybe? - but this makes the top and bottom axes align correctly          
  set(gca,'xtick',datenum(2021,1,5+(-105:10:105)), ...
          'xticklabel',-105:10:105)  
  set(gca,'ydir','reverse','yscale','log')  
  if max(Settings.YRanges(:)) > 40; 
    set(gca,'ytick',[0.001,0.01,0.1,1,10,100,1000])
  else
  set(gca,'ytick',[0.001,0.003,0.01,0.03,0.1,0.3,1,3.,10,30,100,300,1000])    
  end
  
  
  if iVar==2;set(gca,'xaxislocation','top'); xlabel('Days since major SSW commenced'); end
  grid off
  ylabel('Pressure [hPa]')

  
  drawnow  
  
end